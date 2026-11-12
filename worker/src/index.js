// Servidor de archivos de Sound Check Pro (Cloudflare Worker + R2 + D1).
//
// La app sube, borra y baja PDF y secuencias de audio por acá, en vez de hablar
// directo con el almacenamiento: así las claves de Cloudflare no viven en la
// app, los topes de tamaño y de espacio por cuenta los aplica el servidor (los
// de la app se pueden saltear) y de cada archivo idéntico se guarda UNA sola
// copia. Ver PLAN_COSTOS.md (secciones 10 y 11) y worker/README.md.
//
//   PUT    /o/usuarios/{uid}/{canciones|secuencias}/{archivo}  token: sube (guarda por huella)
//   DELETE /o/usuarios/{uid}/{canciones|secuencias}/{archivo}  token: quita el enlace
//   GET    /o/usuarios/{uid}/{canciones|secuencias}/{archivo}  público: lo que enlaza esa ruta
//   GET    /b/{huella}                                          público: la copia por su huella
//   POST   /vincular/iniciar    token: pide enlazar una copia que ya existe
//   POST   /vincular/confirmar  token: prueba que tiene el archivo y se enlaza
//
// Una copia se guarda en R2 con la clave blob/{huella}; D1 sabe qué cuentas la
// usan y se borra recién cuando ya no la usa nadie. Descargar no cuesta ancho
// de banda en R2 y, como el nombre es la huella, se puede cachear para siempre.

const MB = 1024 * 1024;

/** Qué se acepta en cada carpeta. Mismos topes que la app (kMaxBytesPdf y kMaxBytesAudio). */
export const CARPETAS = {
  canciones: { tipos: ['application/pdf'], maximo: 5 * MB },
  secuencias: {
    tipos: [
      'audio/mpeg',
      'audio/mp3',
      'audio/wav',
      'audio/x-wav',
      'audio/mp4',
      'audio/x-m4a',
      'audio/aac',
      'audio/ogg',
    ],
    maximo: 30 * MB,
  },
};

/** Espacio total por cuenta (mismo valor que kCuotaBytesPorUsuario en la app). */
export const CUOTA_BYTES = 500 * MB;

/** Cuántos trozos del archivo se piden como prueba, y de cuántos bytes cada uno. */
const TROZOS = 4;
const LARGO_TROZO = 64;
const VIDA_DESAFIO_MS = 2 * 60 * 1000;

const JWKS_URL =
  'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com';

/** Separa /o/usuarios/{uid}/{carpeta}/{archivo}; null si la ruta no tiene esa forma. */
export function parseRuta(pathname) {
  const partes = pathname.split('/').filter((p, i) => !(i === 0 && p === ''));
  if (partes.length !== 5 || partes[0] !== 'o' || partes[1] !== 'usuarios') {
    return null;
  }
  let uid, carpeta, archivo;
  try {
    [uid, carpeta, archivo] = partes.slice(2).map(decodeURIComponent);
  } catch {
    return null;
  }
  if (!uid || !(carpeta in CARPETAS) || !archivo) return null;
  if ([uid, archivo].some((p) => p.includes('/') || p === '.' || p === '..')) {
    return null;
  }
  return { uid, carpeta, archivo, clave: `usuarios/${uid}/${carpeta}/${archivo}` };
}

/** La huella de /b/{huella}, o null. */
export function parseBlob(pathname) {
  const m = /^\/b\/([0-9a-f]{64})$/.exec(pathname);
  return m ? m[1] : null;
}

export async function huellaDe(buffer) {
  const d = await crypto.subtle.digest('SHA-256', buffer);
  return [...new Uint8Array(d)].map((b) => b.toString(16).padStart(2, '0')).join('');
}

/** Trozos al azar [desde, largo] que la app tiene que poder devolver hasheados. */
export function trozosAlAzar(tamano, azar = Math.random) {
  const cantidad = Math.max(1, Math.min(TROZOS, Math.ceil(tamano / LARGO_TROZO)));
  const trozos = [];
  for (let i = 0; i < cantidad; i++) {
    const largo = Math.min(LARGO_TROZO, tamano);
    const desde = Math.floor(azar() * (tamano - largo + 1));
    trozos.push([desde, largo]);
  }
  return trozos;
}

function base64url(texto) {
  const b = texto.replace(/-/g, '+').replace(/_/g, '/');
  const bin = atob(b + '='.repeat((4 - (b.length % 4)) % 4));
  return Uint8Array.from(bin, (c) => c.charCodeAt(0));
}

let cacheJwks = { claves: null, hasta: 0 };

async function claveDe(kid, { buscarJwks, ahora }) {
  if (!cacheJwks.claves || ahora() > cacheJwks.hasta || !cacheJwks.claves.find((k) => k.kid === kid)) {
    const jwks = await buscarJwks();
    cacheJwks = { claves: jwks.keys, hasta: ahora() + 60 * 60 * 1000 };
  }
  return cacheJwks.claves.find((k) => k.kid === kid) ?? null;
}

/** Vacía la caché de claves públicas (para las pruebas). */
export function olvidarClaves() {
  cacheJwks = { claves: null, hasta: 0 };
}

/**
 * Verifica un ID token de Firebase (RS256, firmado por Google) y devuelve
 * { uid, anonimo }. Lanza si la firma, el proyecto o la fecha no valen.
 */
export async function verificarToken(token, { proyecto, buscarJwks, ahora }) {
  const partes = (token ?? '').split('.');
  if (partes.length !== 3) throw new Error('token mal formado');
  const [h, p, f] = partes;
  const cabecera = JSON.parse(new TextDecoder().decode(base64url(h)));
  const datos = JSON.parse(new TextDecoder().decode(base64url(p)));
  if (cabecera.alg !== 'RS256' || !cabecera.kid) throw new Error('algoritmo no válido');

  const jwk = await claveDe(cabecera.kid, { buscarJwks, ahora });
  if (!jwk) throw new Error('clave desconocida');
  const clave = await crypto.subtle.importKey(
    'jwk',
    jwk,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['verify'],
  );
  const valida = await crypto.subtle.verify(
    'RSASSA-PKCS1-v1_5',
    clave,
    base64url(f),
    new TextEncoder().encode(`${h}.${p}`),
  );
  if (!valida) throw new Error('firma no válida');

  const ahoraS = Math.floor(ahora() / 1000);
  if (datos.aud !== proyecto) throw new Error('proyecto no válido');
  if (datos.iss !== `https://securetoken.google.com/${proyecto}`) throw new Error('emisor no válido');
  if (!(datos.exp > ahoraS)) throw new Error('token vencido');
  if (datos.iat > ahoraS + 60) throw new Error('token del futuro');
  if (!datos.sub) throw new Error('sin usuario');
  return { uid: datos.sub, anonimo: datos.firebase?.sign_in_provider === 'anonymous' };
}

/** Bytes que ocupa una cuenta: la suma de sus enlaces, sin contar [excepto]. */
export async function usoDeUsuario(db, uid, excepto = '') {
  const r = await db
    .prepare('SELECT COALESCE(SUM(bytes), 0) AS total FROM enlaces WHERE uid = ? AND clave <> ?')
    .bind(uid, excepto)
    .first();
  return r?.total ?? 0;
}

const claveBlob = (huella) => `blob/${huella}`;

/** Borra la copia si ya no la usa ninguna cuenta. */
async function soltarHuerfano(env, huella) {
  const r = await env.DB.prepare('SELECT COUNT(*) AS n FROM enlaces WHERE hash = ?').bind(huella).first();
  if ((r?.n ?? 0) === 0) {
    await env.DB.prepare('DELETE FROM blobs WHERE hash = ?').bind(huella).run();
    await env.BUCKET.delete(claveBlob(huella));
  }
}

function respuestaJson(estado, cuerpo, extra = {}, cors = {}) {
  return new Response(JSON.stringify(cuerpo), {
    status: estado,
    headers: { 'Content-Type': 'application/json', ...cors, ...extra },
  });
}

function parseRango(cabecera, tamano) {
  const m = /^bytes=(\d*)-(\d*)$/.exec(cabecera ?? '');
  if (!m || (m[1] === '' && m[2] === '')) return null;
  let inicio, fin;
  if (m[1] === '') {
    inicio = Math.max(0, tamano - Number(m[2]));
    fin = tamano - 1;
  } else {
    inicio = Number(m[1]);
    fin = m[2] === '' ? tamano - 1 : Math.min(Number(m[2]), tamano - 1);
  }
  if (inicio > fin || inicio >= tamano) return null;
  return { offset: inicio, length: fin - inicio + 1 };
}

/**
 * Arma el manejador de pedidos. [proyecto] es el id del proyecto de Firebase;
 * [origenes] los sitios que pueden subir y borrar desde un navegador.
 */
export function crearManejador({
  proyecto,
  origenes = [],
  cuota = CUOTA_BYTES,
  ahora = () => Date.now(),
  azar = Math.random,
  buscarJwks = () => fetch(JWKS_URL).then((r) => r.json()),
}) {
  return async function manejar(request, env) {
    const origen = request.headers.get('Origin');
    const permitido = origen && origenes.includes(origen);
    const corsLectura = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Expose-Headers': 'Content-Length, Content-Range, Accept-Ranges, ETag',
    };
    const corsEscritura = permitido
      ? {
          'Access-Control-Allow-Origin': origen,
          'Access-Control-Expose-Headers': 'x-bytes, x-maximo, x-usado, x-cuota',
          Vary: 'Origin',
        }
      : {};

    const url = new URL(request.url);
    const ruta = parseRuta(url.pathname);
    const huellaUrl = parseBlob(url.pathname);
    const esVincular = url.pathname === '/vincular/iniciar' || url.pathname === '/vincular/confirmar';

    if (request.method === 'OPTIONS') {
      return new Response(null, {
        status: 204,
        headers: {
          ...(permitido ? corsEscritura : corsLectura),
          'Access-Control-Allow-Methods': 'GET, HEAD, PUT, POST, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Authorization, Content-Type, Range',
          'Access-Control-Max-Age': '86400',
        },
      });
    }
    if (!ruta && !huellaUrl && !esVincular) {
      return respuestaJson(404, { error: 'ruta' }, {}, corsLectura);
    }

    // --- Lectura: pública ---
    if (request.method === 'GET' || request.method === 'HEAD') {
      let huella = huellaUrl;
      if (!huella && ruta) {
        const e = await env.DB.prepare('SELECT hash FROM enlaces WHERE uid = ? AND clave = ?')
          .bind(ruta.uid, ruta.clave)
          .first();
        huella = e?.hash ?? null;
      }
      if (!huella) return respuestaJson(404, { error: 'no existe' }, {}, corsLectura);
      const cabecera = await env.BUCKET.head(claveBlob(huella));
      if (!cabecera) return respuestaJson(404, { error: 'no existe' }, {}, corsLectura);
      const rango = parseRango(request.headers.get('Range'), cabecera.size);
      const objeto = await env.BUCKET.get(claveBlob(huella), rango ? { range: rango } : {});
      if (!objeto) return respuestaJson(404, { error: 'no existe' }, {}, corsLectura);
      const headers = {
        ...corsLectura,
        'Content-Type': objeto.httpMetadata?.contentType ?? 'application/octet-stream',
        'Accept-Ranges': 'bytes',
        'Cache-Control': 'public, max-age=31536000, immutable',
        ETag: objeto.httpEtag ?? '',
      };
      if (rango) {
        headers['Content-Range'] = `bytes ${rango.offset}-${rango.offset + rango.length - 1}/${cabecera.size}`;
        headers['Content-Length'] = String(rango.length);
      } else {
        headers['Content-Length'] = String(cabecera.size);
      }
      return new Response(request.method === 'HEAD' ? null : objeto.body, {
        status: rango ? 206 : 200,
        headers,
      });
    }

    // --- Escritura: hace falta una cuenta registrada ---
    const metodoOk = esVincular
      ? request.method === 'POST'
      : request.method === 'PUT' || request.method === 'DELETE';
    if (!metodoOk || huellaUrl) {
      return respuestaJson(405, { error: 'método' }, {}, corsEscritura);
    }
    const auth = request.headers.get('Authorization') ?? '';
    if (!auth.startsWith('Bearer ')) {
      return respuestaJson(401, { error: 'falta el token' }, {}, corsEscritura);
    }
    let sesion;
    try {
      sesion = await verificarToken(auth.slice(7), { proyecto, buscarJwks, ahora });
    } catch (e) {
      return respuestaJson(401, { error: `token: ${e.message}` }, {}, corsEscritura);
    }
    if (sesion.anonimo) {
      return respuestaJson(403, { error: 'hace falta una cuenta registrada' }, {}, corsEscritura);
    }

    // --- Enlazar una copia que ya existe, sin volver a subirla ---
    if (esVincular) {
      let cuerpo;
      try {
        cuerpo = await request.json();
      } catch {
        return respuestaJson(400, { error: 'cuerpo no válido' }, {}, corsEscritura);
      }
      if (url.pathname === '/vincular/iniciar') {
        const destino = parseRuta(`/o/${cuerpo?.ruta ?? ''}`);
        const huella = String(cuerpo?.sha256 ?? '');
        if (!destino || destino.uid !== sesion.uid || !/^[0-9a-f]{64}$/.test(huella)) {
          return respuestaJson(403, { error: 'ruta o huella no válidas' }, {}, corsEscritura);
        }
        const blob = await env.DB.prepare('SELECT bytes FROM blobs WHERE hash = ?').bind(huella).first();
        if (!blob) return respuestaJson(404, { existe: false }, {}, corsEscritura);
        const trozos = trozosAlAzar(blob.bytes, azar);
        const id = [...crypto.getRandomValues(new Uint8Array(12))].map((b) => b.toString(16).padStart(2, '0')).join('');
        await env.DB.prepare('INSERT INTO desafios (id, uid, clave, hash, rangos, vence) VALUES (?, ?, ?, ?, ?, ?)')
          .bind(id, sesion.uid, destino.clave, huella, JSON.stringify(trozos), ahora() + VIDA_DESAFIO_MS)
          .run();
        return respuestaJson(200, { id, rangos: trozos }, {}, corsEscritura);
      }

      // /vincular/confirmar
      const d = await env.DB.prepare('SELECT * FROM desafios WHERE id = ?').bind(String(cuerpo?.id ?? '')).first();
      if (!d || d.uid !== sesion.uid || d.vence < ahora()) {
        return respuestaJson(403, { error: 'desafío vencido o ajeno' }, {}, corsEscritura);
      }
      await env.DB.prepare('DELETE FROM desafios WHERE id = ?').bind(d.id).run(); // se usa una sola vez
      const respuestas = Array.isArray(cuerpo?.respuestas) ? cuerpo.respuestas : [];
      const trozos = JSON.parse(d.rangos);
      if (respuestas.length !== trozos.length) {
        return respuestaJson(403, { error: 'prueba incompleta' }, {}, corsEscritura);
      }
      for (let i = 0; i < trozos.length; i++) {
        const [desde, largo] = trozos[i];
        const objeto = await env.BUCKET.get(claveBlob(d.hash), { range: { offset: desde, length: largo } });
        if (!objeto) return respuestaJson(404, { existe: false }, {}, corsEscritura);
        const esperada = await huellaDe(await new Response(objeto.body).arrayBuffer());
        if (esperada !== respuestas[i]) {
          return respuestaJson(403, { error: 'la prueba no coincide' }, {}, corsEscritura);
        }
      }
      const blob = await env.DB.prepare('SELECT bytes, tipo FROM blobs WHERE hash = ?').bind(d.hash).first();
      if (!blob) return respuestaJson(404, { existe: false }, {}, corsEscritura);
      const carpeta = d.clave.split('/')[2];
      if (!CARPETAS[carpeta].tipos.includes(blob.tipo)) {
        return respuestaJson(415, { error: `tipo no permitido: ${blob.tipo}` }, {}, corsEscritura);
      }
      const usado = await usoDeUsuario(env.DB, sesion.uid, d.clave);
      if (usado + blob.bytes > cuota) {
        return respuestaJson(
          507,
          { error: 'sin espacio en la cuenta' },
          { 'x-usado': String(usado), 'x-cuota': String(cuota) },
          corsEscritura,
        );
      }
      const previo = await env.DB.prepare('SELECT hash FROM enlaces WHERE uid = ? AND clave = ?').bind(sesion.uid, d.clave).first();
      await env.DB.prepare('INSERT OR REPLACE INTO enlaces (uid, clave, hash, bytes, creado) VALUES (?, ?, ?, ?, ?)')
        .bind(sesion.uid, d.clave, d.hash, blob.bytes, ahora())
        .run();
      if (previo && previo.hash !== d.hash) await soltarHuerfano(env, previo.hash);
      return respuestaJson(
        201,
        { url: `${url.origin}/b/${d.hash}`, sha256: d.hash, bytes: blob.bytes, deduplicado: true },
        {},
        corsEscritura,
      );
    }

    // --- PUT y DELETE sobre una ruta de la cuenta ---
    if (sesion.uid !== ruta.uid) {
      return respuestaJson(403, { error: 'esa carpeta es de otra cuenta' }, {}, corsEscritura);
    }

    if (request.method === 'DELETE') {
      const e = await env.DB.prepare('SELECT hash FROM enlaces WHERE uid = ? AND clave = ?').bind(ruta.uid, ruta.clave).first();
      if (e) {
        await env.DB.prepare('DELETE FROM enlaces WHERE uid = ? AND clave = ?').bind(ruta.uid, ruta.clave).run();
        await soltarHuerfano(env, e.hash);
      }
      return new Response(null, { status: 204, headers: corsEscritura });
    }

    // PUT
    const regla = CARPETAS[ruta.carpeta];
    const tipo = (request.headers.get('Content-Type') ?? '').split(';')[0].trim().toLowerCase();
    if (!regla.tipos.includes(tipo)) {
      return respuestaJson(415, { error: `tipo no permitido: ${tipo}` }, {}, corsEscritura);
    }
    const declarado = Number(request.headers.get('Content-Length') ?? 0);
    if (declarado > regla.maximo) {
      return respuestaJson(
        413,
        { error: 'archivo demasiado grande' },
        { 'x-bytes': String(declarado), 'x-maximo': String(regla.maximo) },
        corsEscritura,
      );
    }
    // El tamaño que cuenta es el real, no el declarado.
    const bytes = await request.arrayBuffer();
    if (bytes.byteLength > regla.maximo) {
      return respuestaJson(
        413,
        { error: 'archivo demasiado grande' },
        { 'x-bytes': String(bytes.byteLength), 'x-maximo': String(regla.maximo) },
        corsEscritura,
      );
    }
    if (bytes.byteLength === 0) {
      return respuestaJson(400, { error: 'archivo vacío' }, {}, corsEscritura);
    }
    if (tipo === 'application/pdf') {
      const inicio = new TextDecoder().decode(new Uint8Array(bytes, 0, Math.min(5, bytes.byteLength)));
      if (inicio !== '%PDF-') {
        return respuestaJson(415, { error: 'no parece un PDF' }, {}, corsEscritura);
      }
    }

    const usado = await usoDeUsuario(env.DB, ruta.uid, ruta.clave);
    if (usado + bytes.byteLength > cuota) {
      return respuestaJson(
        507,
        { error: 'sin espacio en la cuenta' },
        { 'x-usado': String(usado), 'x-cuota': String(cuota) },
        corsEscritura,
      );
    }

    // La huella la calcula el servidor: nadie puede declarar una que no es.
    const huella = await huellaDe(bytes);
    const yaEstaba = !!(await env.BUCKET.head(claveBlob(huella)));
    if (!yaEstaba) {
      await env.BUCKET.put(claveBlob(huella), bytes, { httpMetadata: { contentType: tipo } });
    }
    const previo = await env.DB.prepare('SELECT hash FROM enlaces WHERE uid = ? AND clave = ?').bind(ruta.uid, ruta.clave).first();
    await env.DB.batch([
      env.DB.prepare('INSERT OR IGNORE INTO blobs (hash, bytes, tipo, creado) VALUES (?, ?, ?, ?)').bind(huella, bytes.byteLength, tipo, ahora()),
      env.DB.prepare('INSERT OR REPLACE INTO enlaces (uid, clave, hash, bytes, creado) VALUES (?, ?, ?, ?, ?)').bind(ruta.uid, ruta.clave, huella, bytes.byteLength, ahora()),
    ]);
    // Si otra cuenta borró la copia justo ahora, se vuelve a guardar.
    if (!(await env.BUCKET.head(claveBlob(huella)))) {
      await env.BUCKET.put(claveBlob(huella), bytes, { httpMetadata: { contentType: tipo } });
    }
    if (previo && previo.hash !== huella) await soltarHuerfano(env, previo.hash);
    return respuestaJson(
      201,
      { url: `${url.origin}/b/${huella}`, sha256: huella, bytes: bytes.byteLength, deduplicado: yaEstaba },
      {},
      corsEscritura,
    );
  };
}

/** Punto de entrada de Cloudflare: lee la configuración de wrangler.toml. */
export default {
  fetch(request, env) {
    const manejar = crearManejador({
      proyecto: env.FIREBASE_PROJECT_ID,
      origenes: (env.ORIGENES_PERMITIDOS ?? '').split(',').map((s) => s.trim()).filter(Boolean),
    });
    return manejar(request, env);
  },
};
