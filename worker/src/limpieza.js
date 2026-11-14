// Limpieza de cuentas de invitado (anónimas) que no volvieron en mucho tiempo.
// Corre sola desde un cron del Worker (ver wrangler.toml). Usa una cuenta de
// servicio de Firebase guardada como secreto (GOOGLE_SERVICE_ACCOUNT).
//
// Nunca toca cuentas con mail o Google: una cuenta es "de invitado" solo si no
// tiene ningún proveedor de acceso. Mientras BORRAR_ANONIMOS no sea "true" solo
// lista a quién borraría (modo de prueba).

export const DIAS_INACTIVO = 90;
const DIA_MS = 24 * 60 * 60 * 1000;

const aBase64url = (bytes) =>
  btoa(String.fromCharCode(...new Uint8Array(bytes))).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
const textoABase64url = (t) => aBase64url(new TextEncoder().encode(t));

/** Pasa la clave privada PEM (PKCS8) a bytes. */
function pemABytes(pem) {
  const cuerpo = pem.replace(/-----[A-Z ]+-----/g, '').replace(/\s+/g, '');
  return Uint8Array.from(atob(cuerpo), (c) => c.charCodeAt(0));
}

/** Pide a Google un token de acceso con la cuenta de servicio (JWT firmado con RS256). */
export async function tokenDeServicio(cuenta, { ahora = Date.now, buscar = fetch } = {}) {
  const emitido = Math.floor(ahora() / 1000);
  const cabecera = textoABase64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const carga = textoABase64url(
    JSON.stringify({
      iss: cuenta.client_email,
      scope: 'https://www.googleapis.com/auth/identitytoolkit',
      aud: 'https://oauth2.googleapis.com/token',
      iat: emitido,
      exp: emitido + 3600,
    }),
  );
  const clave = await crypto.subtle.importKey(
    'pkcs8',
    pemABytes(cuenta.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const firma = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', clave, new TextEncoder().encode(`${cabecera}.${carga}`));
  const r = await buscar('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: `${cabecera}.${carga}.${aBase64url(firma)}`,
    }),
  });
  if (!r.ok) throw new Error(`token de servicio: ${r.status}`);
  return (await r.json()).access_token;
}

/** Todas las cuentas del proyecto (de a 1000). */
export async function listarCuentas(proyecto, token, buscar = fetch) {
  const todas = [];
  let pagina = '';
  do {
    const url =
      `https://identitytoolkit.googleapis.com/v1/projects/${proyecto}/accounts:batchGet?maxResults=1000` +
      (pagina ? `&nextPageToken=${encodeURIComponent(pagina)}` : '');
    const r = await buscar(url, { headers: { Authorization: `Bearer ${token}` } });
    if (!r.ok) throw new Error(`listar cuentas: ${r.status}`);
    const j = await r.json();
    todas.push(...(j.users ?? []));
    pagina = j.nextPageToken ?? '';
  } while (pagina);
  return todas;
}

/**
 * Ids de las cuentas de invitado sin actividad hace [dias] días o más. Una
 * cuenta de invitado no tiene proveedor de acceso; si no hay fecha de último
 * acceso se usa la de creación, y sin ninguna fecha no se toca.
 */
export function anonimasInactivas(cuentas, ahoraMs, dias = DIAS_INACTIVO) {
  const limite = ahoraMs - dias * DIA_MS;
  return cuentas
    .filter((c) => !c.providerUserInfo || c.providerUserInfo.length === 0)
    .filter((c) => {
      const ultimo = Number(c.lastLoginAt || c.createdAt);
      return Number.isFinite(ultimo) && ultimo > 0 && ultimo < limite;
    })
    .map((c) => c.localId);
}

/** Borra cuentas por id (de a 1000). */
export async function borrarCuentas(proyecto, token, ids, buscar = fetch) {
  let borradas = 0;
  for (let i = 0; i < ids.length; i += 1000) {
    const lote = ids.slice(i, i + 1000);
    const r = await buscar(`https://identitytoolkit.googleapis.com/v1/projects/${proyecto}/accounts:batchDelete`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ localIds: lote, force: true }),
    });
    if (!r.ok) throw new Error(`borrar cuentas: ${r.status}`);
    borradas += lote.length;
  }
  return borradas;
}

/**
 * Una pasada completa. Devuelve qué hizo, para el registro del Worker.
 * Sin la cuenta de servicio no hace nada.
 */
export async function limpiarInvitados(env, { ahora = Date.now, buscar = fetch } = {}) {
  if (!env.GOOGLE_SERVICE_ACCOUNT) return { omitido: 'sin GOOGLE_SERVICE_ACCOUNT' };
  const cuenta = JSON.parse(env.GOOGLE_SERVICE_ACCOUNT);
  const proyecto = env.FIREBASE_PROJECT_ID;
  const dias = Number(env.DIAS_INACTIVO_INVITADO) || DIAS_INACTIVO;
  const token = await tokenDeServicio(cuenta, { ahora, buscar });
  const cuentas = await listarCuentas(proyecto, token, buscar);
  const ids = anonimasInactivas(cuentas, ahora(), dias);
  const real = env.BORRAR_ANONIMOS === 'true';
  let borradas = 0;
  if (real && ids.length > 0) {
    // Por si acaso tuvieran archivos: se sueltan sus enlaces (y las copias que
    // ya nadie usa) antes de borrar la cuenta.
    for (const uid of ids) {
      const filas = await env.DB.prepare('SELECT DISTINCT hash FROM enlaces WHERE uid = ?').bind(uid).all();
      await env.DB.prepare('DELETE FROM enlaces WHERE uid = ?').bind(uid).run();
      for (const { hash } of filas.results ?? []) {
        const r = await env.DB.prepare('SELECT COUNT(*) AS n FROM enlaces WHERE hash = ?').bind(hash).first();
        if ((r?.n ?? 0) === 0) {
          await env.DB.prepare('DELETE FROM blobs WHERE hash = ?').bind(hash).run();
          await env.BUCKET.delete(`blob/${hash}`);
        }
      }
    }
    borradas = await borrarCuentas(proyecto, token, ids, buscar);
  }
  return { cuentas: cuentas.length, candidatas: ids.length, borradas, modo: real ? 'borrar' : 'solo listar' };
}
