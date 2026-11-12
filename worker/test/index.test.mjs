// Pruebas del servidor de archivos, sin Cloudflare: un R2 de mentira (un Map)
// y claves RSA generadas acá firman los tokens de Firebase.
// Se corren con: cd worker && node --test test/
import assert from 'node:assert/strict';
import { before, beforeEach, describe, test } from 'node:test';

import {
  CARPETAS,
  CUOTA_BYTES,
  crearManejador,
  olvidarClaves,
  parseRuta,
  usoDeUsuario,
  verificarToken,
} from '../src/index.js';

const PROYECTO = 'appbandasonido';
const ORIGEN = 'https://estebancastelani.github.io';
const AHORA = Date.UTC(2026, 10, 11, 12, 0, 0);

const b64 = (bytes) =>
  Buffer.from(bytes).toString('base64').replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');

let par;
let jwks;

async function firmar(datos, { kid = 'k1', clave = par.privateKey } = {}) {
  const h = b64(new TextEncoder().encode(JSON.stringify({ alg: 'RS256', kid, typ: 'JWT' })));
  const p = b64(new TextEncoder().encode(JSON.stringify(datos)));
  const f = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    clave,
    new TextEncoder().encode(`${h}.${p}`),
  );
  return `${h}.${p}.${b64(new Uint8Array(f))}`;
}

const datosToken = (uid, extra = {}) => ({
  aud: PROYECTO,
  iss: `https://securetoken.google.com/${PROYECTO}`,
  sub: uid,
  iat: AHORA / 1000 - 10,
  exp: AHORA / 1000 + 3000,
  firebase: { sign_in_provider: 'google.com' },
  ...extra,
});

/** R2 de mentira con la parte de la API que usa el servidor. */
function crearBucket(inicial = {}) {
  const objetos = new Map(Object.entries(inicial).map(([k, v]) => [k, { bytes: v, tipo: 'application/pdf' }]));
  return {
    objetos,
    async head(clave) {
      const o = objetos.get(clave);
      return o ? { size: o.bytes.byteLength ?? o.bytes } : null;
    },
    async get(clave, opciones = {}) {
      const o = objetos.get(clave);
      if (!o) return null;
      let datos = o.bytes;
      if (opciones.range) {
        datos = datos.slice(opciones.range.offset, opciones.range.offset + opciones.range.length);
      }
      return { body: datos, httpMetadata: { contentType: o.tipo }, httpEtag: '"x"' };
    },
    async put(clave, bytes, opciones) {
      objetos.set(clave, { bytes: new Uint8Array(bytes), tipo: opciones.httpMetadata.contentType });
    },
    async delete(clave) {
      objetos.delete(clave);
    },
    async list({ prefix }) {
      const objs = [...objetos.entries()]
        .filter(([k]) => k.startsWith(prefix))
        .map(([key, o]) => ({ key, size: o.bytes.byteLength ?? o.bytes }));
      return { objects: objs, truncated: false };
    },
  };
}

const pdf = (n = 100) => new Uint8Array([...Buffer.from('%PDF-1.4\n'), ...new Uint8Array(n)]);
const mp3 = (n = 100) => new Uint8Array([0xff, 0xfb, 0x90, 0, ...new Uint8Array(n)]);

let manejar;

before(async () => {
  par = await crypto.subtle.generateKey(
    { name: 'RSASSA-PKCS1-v1_5', modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: 'SHA-256' },
    true,
    ['sign', 'verify'],
  );
  jwks = { keys: [{ ...(await crypto.subtle.exportKey('jwk', par.publicKey)), kid: 'k1', alg: 'RS256' }] };
});

beforeEach(() => {
  olvidarClaves();
  manejar = crearManejador({
    proyecto: PROYECTO,
    origenes: [ORIGEN],
    ahora: () => AHORA,
    buscarJwks: async () => jwks,
  });
});

async function pedir(metodo, ruta, { token, tipo, cuerpo, bucket = crearBucket(), headers = {} } = {}) {
  const h = { ...headers };
  if (token) h.Authorization = `Bearer ${token}`;
  if (tipo) h['Content-Type'] = tipo;
  const r = new Request(`https://archivos.test${ruta}`, { method: metodo, headers: h, body: cuerpo });
  return { r: await manejar(r, { BUCKET: bucket }), bucket };
}

describe('parseRuta', () => {
  test('acepta usuarios/{uid}/{carpeta}/{archivo}', () => {
    assert.deepEqual(parseRuta('/o/usuarios/u1/canciones/a%20b.pdf'), {
      uid: 'u1',
      carpeta: 'canciones',
      archivo: 'a b.pdf',
      clave: 'usuarios/u1/canciones/a b.pdf',
    });
  });
  test('rechaza rutas raras', () => {
    for (const p of [
      '/o/usuarios/u1/otra/a.pdf',
      '/o/usuarios/u1/canciones',
      '/o/usuarios/u1/canciones/a/b.pdf',
      '/x/usuarios/u1/canciones/a.pdf',
      '/o/usuarios/u1/canciones/..',
      '/o/usuarios/%2e%2e/canciones/a.pdf'.replace('%2e%2e', '..'),
      '/o/usuarios/u1/canciones/%2F',
    ]) {
      assert.equal(parseRuta(p), null, p);
    }
  });
});

describe('verificarToken', () => {
  const opc = () => ({ proyecto: PROYECTO, buscarJwks: async () => jwks, ahora: () => AHORA });

  test('acepta un token válido', async () => {
    const t = await firmar(datosToken('u1'));
    assert.deepEqual(await verificarToken(t, opc()), { uid: 'u1', anonimo: false });
  });
  test('marca a los anónimos', async () => {
    const t = await firmar(datosToken('u1', { firebase: { sign_in_provider: 'anonymous' } }));
    assert.equal((await verificarToken(t, opc())).anonimo, true);
  });
  test('rechaza vencido, de otro proyecto, firma ajena y mal formado', async () => {
    await assert.rejects(verificarToken(await firmar(datosToken('u1', { exp: AHORA / 1000 - 1 })), opc()), /vencido/);
    await assert.rejects(verificarToken(await firmar(datosToken('u1', { aud: 'otro' })), opc()), /proyecto/);
    const otra = await crypto.subtle.generateKey(
      { name: 'RSASSA-PKCS1-v1_5', modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: 'SHA-256' },
      false,
      ['sign'],
    );
    await assert.rejects(verificarToken(await firmar(datosToken('u1'), { clave: otra.privateKey }), opc()), /firma/);
    await assert.rejects(verificarToken(await firmar(datosToken('u1'), { kid: 'zzz' }), opc()), /clave/);
    await assert.rejects(verificarToken('abc', opc()), /mal formado/);
  });
});

describe('PUT', () => {
  const ruta = '/o/usuarios/u1/canciones/1_a.pdf';

  test('sube un PDF de su carpeta', async () => {
    const token = await firmar(datosToken('u1'));
    const { r, bucket } = await pedir('PUT', ruta, { token, tipo: 'application/pdf', cuerpo: pdf() });
    assert.equal(r.status, 201);
    assert.ok(bucket.objetos.has('usuarios/u1/canciones/1_a.pdf'));
  });
  test('sube un MP3 a secuencias', async () => {
    const token = await firmar(datosToken('u1'));
    const { r } = await pedir('PUT', '/o/usuarios/u1/secuencias/1_a.mp3', { token, tipo: 'audio/mpeg', cuerpo: mp3() });
    assert.equal(r.status, 201);
  });
  test('sin token: 401; token vencido: 401', async () => {
    assert.equal((await pedir('PUT', ruta, { tipo: 'application/pdf', cuerpo: pdf() })).r.status, 401);
    const viejo = await firmar(datosToken('u1', { exp: AHORA / 1000 - 5 }));
    assert.equal((await pedir('PUT', ruta, { token: viejo, tipo: 'application/pdf', cuerpo: pdf() })).r.status, 401);
  });
  test('carpeta de otra cuenta: 403', async () => {
    const token = await firmar(datosToken('u2'));
    assert.equal((await pedir('PUT', ruta, { token, tipo: 'application/pdf', cuerpo: pdf() })).r.status, 403);
  });
  test('invitado anónimo: 403', async () => {
    const token = await firmar(datosToken('u1', { firebase: { sign_in_provider: 'anonymous' } }));
    assert.equal((await pedir('PUT', ruta, { token, tipo: 'application/pdf', cuerpo: pdf() })).r.status, 403);
  });
  test('tipo no permitido o PDF falso: 415', async () => {
    const token = await firmar(datosToken('u1'));
    assert.equal((await pedir('PUT', ruta, { token, tipo: 'text/html', cuerpo: pdf() })).r.status, 415);
    assert.equal((await pedir('PUT', ruta, { token, tipo: 'audio/mpeg', cuerpo: mp3() })).r.status, 415);
    assert.equal(
      (await pedir('PUT', ruta, { token, tipo: 'application/pdf', cuerpo: new Uint8Array(50) })).r.status,
      415,
    );
  });
  test('archivo vacío: 400', async () => {
    const token = await firmar(datosToken('u1'));
    assert.equal((await pedir('PUT', ruta, { token, tipo: 'application/pdf', cuerpo: new Uint8Array(0) })).r.status, 400);
  });
  test('PDF de más de 5 MB: 413 con los tamaños', async () => {
    const token = await firmar(datosToken('u1'));
    const grande = new Uint8Array(CARPETAS.canciones.maximo + 1);
    grande.set(Buffer.from('%PDF-'));
    const { r } = await pedir('PUT', ruta, { token, tipo: 'application/pdf', cuerpo: grande });
    assert.equal(r.status, 413);
    assert.equal(r.headers.get('x-maximo'), String(CARPETAS.canciones.maximo));
    assert.equal(r.headers.get('x-bytes'), String(grande.byteLength));
  });
  test('sin espacio en la cuenta: 507 con uso y cuota', async () => {
    const token = await firmar(datosToken('u1'));
    const bucket = crearBucket({ 'usuarios/u1/secuencias/viejo.mp3': CUOTA_BYTES - 50 });
    const { r } = await pedir('PUT', ruta, { token, tipo: 'application/pdf', cuerpo: pdf(100), bucket });
    assert.equal(r.status, 507);
    assert.equal(r.headers.get('x-usado'), String(CUOTA_BYTES - 50));
    assert.equal(r.headers.get('x-cuota'), String(CUOTA_BYTES));
  });
  test('reemplazar un archivo no cuenta dos veces', async () => {
    const token = await firmar(datosToken('u1'));
    const bucket = crearBucket({ 'usuarios/u1/canciones/1_a.pdf': CUOTA_BYTES - 10 });
    const { r } = await pedir('PUT', ruta, { token, tipo: 'application/pdf', cuerpo: pdf(100), bucket });
    assert.equal(r.status, 201);
  });
  test('el espacio de otra cuenta no cuenta', async () => {
    const token = await firmar(datosToken('u1'));
    const bucket = crearBucket({ 'usuarios/u2/secuencias/x.mp3': CUOTA_BYTES });
    const { r } = await pedir('PUT', ruta, { token, tipo: 'application/pdf', cuerpo: pdf(), bucket });
    assert.equal(r.status, 201);
    assert.equal(await usoDeUsuario(bucket, 'u2'), CUOTA_BYTES);
  });
});

describe('DELETE', () => {
  const ruta = '/o/usuarios/u1/canciones/1_a.pdf';
  test('borra su archivo (204) y es idempotente', async () => {
    const token = await firmar(datosToken('u1'));
    const bucket = crearBucket({ 'usuarios/u1/canciones/1_a.pdf': 10 });
    assert.equal((await pedir('DELETE', ruta, { token, bucket })).r.status, 204);
    assert.equal(bucket.objetos.size, 0);
    assert.equal((await pedir('DELETE', ruta, { token, bucket })).r.status, 204);
  });
  test('no borra lo de otra cuenta (403) ni sin token (401)', async () => {
    const bucket = crearBucket({ 'usuarios/u1/canciones/1_a.pdf': 10 });
    const otro = await firmar(datosToken('u2'));
    assert.equal((await pedir('DELETE', ruta, { token: otro, bucket })).r.status, 403);
    assert.equal((await pedir('DELETE', ruta, { bucket })).r.status, 401);
    assert.equal(bucket.objetos.size, 1);
  });
});

describe('GET, HEAD y CORS', () => {
  const ruta = '/o/usuarios/u1/secuencias/1_a.mp3';
  const bucketConAudio = () => {
    const b = crearBucket();
    b.objetos.set('usuarios/u1/secuencias/1_a.mp3', { bytes: new Uint8Array([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]), tipo: 'audio/mpeg' });
    return b;
  };

  test('lee sin token, con caché larga y CORS abierto', async () => {
    const { r } = await pedir('GET', ruta, { bucket: bucketConAudio() });
    assert.equal(r.status, 200);
    assert.equal(r.headers.get('Content-Type'), 'audio/mpeg');
    assert.equal(r.headers.get('Content-Length'), '10');
    assert.match(r.headers.get('Cache-Control'), /immutable/);
    assert.equal(r.headers.get('Access-Control-Allow-Origin'), '*');
  });
  test('rango: 206 con Content-Range', async () => {
    const { r } = await pedir('GET', ruta, { bucket: bucketConAudio(), headers: { Range: 'bytes=2-5' } });
    assert.equal(r.status, 206);
    assert.equal(r.headers.get('Content-Range'), 'bytes 2-5/10');
    assert.equal(r.headers.get('Content-Length'), '4');
  });
  test('HEAD sin cuerpo y 404 si no existe', async () => {
    const h = await pedir('HEAD', ruta, { bucket: bucketConAudio() });
    assert.equal(h.r.status, 200);
    assert.equal(await h.r.text(), '');
    assert.equal((await pedir('GET', '/o/usuarios/u1/secuencias/no.mp3')).r.status, 404);
  });
  test('OPTIONS responde a los sitios permitidos', async () => {
    const { r } = await pedir('OPTIONS', ruta, { headers: { Origin: ORIGEN } });
    assert.equal(r.status, 204);
    assert.equal(r.headers.get('Access-Control-Allow-Origin'), ORIGEN);
    assert.match(r.headers.get('Access-Control-Allow-Methods'), /PUT/);
  });
  test('un sitio no permitido no recibe CORS de escritura', async () => {
    const token = await firmar(datosToken('u1'));
    const { r } = await pedir('PUT', '/o/usuarios/u1/canciones/1_a.pdf', {
      token,
      tipo: 'application/pdf',
      cuerpo: pdf(),
      headers: { Origin: 'https://malo.example' },
    });
    assert.equal(r.status, 201);
    assert.equal(r.headers.get('Access-Control-Allow-Origin'), null);
  });
  test('otros métodos: 405', async () => {
    assert.equal((await pedir('POST', '/o/usuarios/u1/canciones/1_a.pdf')).r.status, 405);
  });
});
