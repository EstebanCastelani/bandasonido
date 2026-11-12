// Servidor de archivos de Sound Check Pro (Cloudflare Worker + R2).
//
// La app sube, borra y baja PDF y secuencias de audio por acá, en vez de hablar
// directo con el almacenamiento: así las claves de Cloudflare no viven en la
// app, y los topes de tamaño y de espacio por cuenta los aplica el servidor
// (los de la app se pueden saltear). Ver PLAN_COSTOS.md y worker/README.md.
//
//   GET    /o/usuarios/{uid}/{canciones|secuencias}/{archivo}   público
//   PUT    /o/usuarios/{uid}/{canciones|secuencias}/{archivo}   token de Firebase
//   DELETE /o/usuarios/{uid}/{canciones|secuencias}/{archivo}   token de Firebase
//
// Descargar no cuesta ancho de banda en R2, y como cada archivo tiene un
// nombre único (lleva la hora de subida) se puede cachear para siempre.

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

/** Bytes que ya ocupa una cuenta (suma de todos sus objetos). */
export async function usoDeUsuario(bucket, uid) {
  let total = 0;
  let cursor;
  do {
    const r = await bucket.list({ prefix: `usuarios/${uid}/`, cursor });
    for (const o of r.objects) total += o.size;
    cursor = r.truncated ? r.cursor : undefined;
  } while (cursor);
  return total;
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

    if (request.method === 'OPTIONS') {
      return new Response(null, {
        status: 204,
        headers: {
          ...(permitido ? corsEscritura : corsLectura),
          'Access-Control-Allow-Methods': 'GET, HEAD, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Authorization, Content-Type, Range',
          'Access-Control-Max-Age': '86400',
        },
      });
    }
    if (!ruta) return respuestaJson(404, { error: 'ruta' }, {}, corsLectura);

    // --- Lectura: pública ---
    if (request.method === 'GET' || request.method === 'HEAD') {
      const cabecera = await env.BUCKET.head(ruta.clave);
      if (!cabecera) return respuestaJson(404, { error: 'no existe' }, {}, corsLectura);
      const rango = parseRango(request.headers.get('Range'), cabecera.size);
      const objeto = await env.BUCKET.get(ruta.clave, rango ? { range: rango } : {});
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

    // --- Escritura: hace falta ser la persona dueña de la carpeta ---
    if (request.method !== 'PUT' && request.method !== 'DELETE') {
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
    if (sesion.uid !== ruta.uid) {
      return respuestaJson(403, { error: 'esa carpeta es de otra cuenta' }, {}, corsEscritura);
    }

    if (request.method === 'DELETE') {
      await env.BUCKET.delete(ruta.clave);
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

    const previo = await env.BUCKET.head(ruta.clave);
    const usado = (await usoDeUsuario(env.BUCKET, ruta.uid)) - (previo?.size ?? 0);
    if (usado + bytes.byteLength > cuota) {
      return respuestaJson(
        507,
        { error: 'sin espacio en la cuenta' },
        { 'x-usado': String(usado), 'x-cuota': String(cuota) },
        corsEscritura,
      );
    }

    await env.BUCKET.put(ruta.clave, bytes, { httpMetadata: { contentType: tipo } });
    return respuestaJson(201, { ruta: ruta.clave, bytes: bytes.byteLength }, {}, corsEscritura);
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
