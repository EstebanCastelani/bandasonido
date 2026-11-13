// Pruebas del servidor de archivos, sin Cloudflare: un R2 de mentira (un Map),
// una base D1 de mentira (SQLite en memoria de Node, con el mismo schema.sql) y
// claves RSA generadas acá que firman los tokens de Firebase.
// Se corren con: cd worker && node --test
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { DatabaseSync } from 'node:sqlite';
import { before, beforeEach, describe, test } from 'node:test';

import {
  CARPETAS,
  CUOTA_BYTES,
  CUOTA_PRO_BYTES,
  crearManejador,
  esProEnFirestore,
  olvidarClaves,
  parseBlob,
  parseRuta,
  trozosAlAzar,
  usoDeUsuario,
  verificarToken,
} from '../src/index.js';

const PROYECTO = 'appbandasonido';
const ORIGEN = 'https://estebancastelani.github.io';
const AHORA = Date.UTC(2026, 10, 11, 12, 0, 0);

const b64 = (bytes) =>
  Buffer.from(bytes).toString('base64').replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
const sha = (bytes) => createHash('sha256').update(bytes).digest('hex');

let par;
let jwks;

async function firmar(datos, { kid = 'k1', clave = par.privateKey } = {}) {
  const h = b64(new TextEncoder().encode(JSON.stringify({ alg: 'RS256', kid, typ: 'JWT' })));
  const p = b64(new TextEncoder().encode(JSON.stringify(datos)));
  const f = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', clave, new TextEncoder().encode(`${h}.${p}`));
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
function crearBucket() {
  const objetos = new Map();
  return {
    objetos,
    async head(clave) {
      const o = objetos.get(clave);
      return o ? { size: o.bytes.byteLength } : null;
    },
    async get(clave, opciones = {}) {
      const o = objetos.get(clave);
      if (!o) return null;
      let datos = o.bytes;
      if (opciones.range) datos = datos.slice(opciones.range.offset, opciones.range.offset + opciones.range.length);
      return { body: datos, httpMetadata: { contentType: o.tipo }, httpEtag: '"x"' };
    },
    async put(clave, bytes, opciones) {
      objetos.set(clave, { bytes: new Uint8Array(bytes), tipo: opciones.httpMetadata.contentType });
    },
    async delete(clave) {
      objetos.delete(clave);
    },
  };
}

/** D1 de mentira: la misma interfaz (prepare/bind/first/all/run/batch) sobre SQLite en memoria. */
function crearD1() {
  const db = new DatabaseSync(':memory:');
  db.exec(readFileSync(new URL('../schema.sql', import.meta.url), 'utf8'));
  const prepare = (sql) => {
    const s = db.prepare(sql);
    let args = [];
    const o = {
      bind(...a) {
        args = a;
        return o;
      },
      async first() {
        return s.get(...args) ?? null;
      },
      async all() {
        return { results: s.all(...args) };
      },
      async run() {
        s.run(...args);
        return { success: true };
      },
    };
    return o;
  };
  return {
    prepare,
    async batch(lista) {
      db.exec('BEGIN');
      try {
        for (const x of lista) await x.run();
        db.exec('COMMIT');
      } catch (e) {
        db.exec('ROLLBACK');
        throw e;
      }
    },
    sql: db,
  };
}

const pdf = (n = 100, relleno = 0) =>
  new Uint8Array([...Buffer.from('%PDF-1.4\n'), ...new Uint8Array(n).fill(relleno)]);
const mp3 = (n = 100) => new Uint8Array([0xff, 0xfb, 0x90, 0, ...new Uint8Array(n)]);

let manejar;
let env;

before(async () => {
  par = await crypto.subtle.generateKey(
    { name: 'RSASSA-PKCS1-v1_5', modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: 'SHA-256' },
    true,
    ['sign', 'verify'],
  );
  jwks = { keys: [{ ...(await crypto.subtle.exportKey('jwk', par.publicKey)), kid: 'k1', alg: 'RS256' }] };
});

let reloj;
let cuentasPro;
let consultasPro;

beforeEach(() => {
  olvidarClaves();
  reloj = AHORA;
  env = { BUCKET: crearBucket(), DB: crearD1() };
  cuentasPro = new Set();
  consultasPro = 0;
  manejar = crearManejador({
    esPro: async (sesion) => {
      consultasPro++;
      if (sesion.uid === 'falla') throw new Error('sin red');
      return cuentasPro.has(sesion.uid);
    },
    proyecto: PROYECTO,
    origenes: [ORIGEN],
    ahora: () => reloj,
    azar: () => 0.3,
    buscarJwks: async () => jwks,
  });
});

async function pedir(metodo, ruta, { token, tipo, cuerpo, headers = {} } = {}) {
  const h = { ...headers };
  if (token) h.Authorization = `Bearer ${token}`;
  if (tipo) h['Content-Type'] = tipo;
  const r = new Request(`https://archivos.test${ruta}`, { method: metodo, headers: h, body: cuerpo });
  return manejar(r, env);
}

const ruta = (uid, archivo = '1_a.pdf', carpeta = 'canciones') => `usuarios/${uid}/${carpeta}/${archivo}`;
const subir = async (uid, bytes, archivo, carpeta = 'canciones', tipo = 'application/pdf') =>
  pedir('PUT', `/o/${ruta(uid, archivo, carpeta)}`, { token: await firmar(datosToken(uid)), tipo, cuerpo: bytes });
const enlaces = () => env.DB.sql.prepare('SELECT uid, clave, hash FROM enlaces ORDER BY uid, clave').all();
const copias = () => [...env.BUCKET.objetos.keys()];

/** Siembra una cuenta con un archivo de [bytes] bytes (para probar la cuota). */
function sembrar(uid, clave, bytes) {
  const hash = sha(`${uid}${clave}`);
  env.DB.sql.prepare('INSERT INTO blobs (hash, bytes, tipo, creado) VALUES (?, ?, ?, ?)').run(hash, bytes, 'application/pdf', 1);
  env.DB.sql.prepare('INSERT INTO enlaces (uid, clave, hash, bytes, creado) VALUES (?, ?, ?, ?, ?)').run(uid, clave, hash, bytes, 1);
}

describe('rutas', () => {
  test('parseRuta acepta usuarios/{uid}/{carpeta}/{archivo}', () => {
    assert.deepEqual(parseRuta('/o/usuarios/u1/canciones/a%20b.pdf'), {
      uid: 'u1',
      carpeta: 'canciones',
      archivo: 'a b.pdf',
      clave: 'usuarios/u1/canciones/a b.pdf',
    });
  });
  test('parseRuta rechaza rutas raras', () => {
    for (const p of [
      '/o/usuarios/u1/otra/a.pdf',
      '/o/usuarios/u1/canciones',
      '/o/usuarios/u1/canciones/a/b.pdf',
      '/x/usuarios/u1/canciones/a.pdf',
      '/o/usuarios/u1/canciones/..',
      '/o/usuarios/../canciones/a.pdf',
      '/o/usuarios/u1/canciones/%2F',
    ]) {
      assert.equal(parseRuta(p), null, p);
    }
  });
  test('parseBlob solo acepta una huella de 64 caracteres hexadecimales', () => {
    const h = sha('x');
    assert.equal(parseBlob(`/b/${h}`), h);
    for (const p of ['/b/abc', `/b/${h}0`, `/b/${h.toUpperCase()}`, `/c/${h}`]) assert.equal(parseBlob(p), null, p);
  });
  test('trozosAlAzar pide trozos dentro del archivo, incluso si es muy chico', () => {
    for (const tamano of [1, 10, 64, 65, 5000]) {
      const t = trozosAlAzar(tamano, () => 0.99);
      assert.ok(t.length >= 1 && t.length <= 4);
      for (const [desde, largo] of t) {
        assert.ok(desde >= 0 && largo >= 1 && desde + largo <= tamano, `${tamano}: ${desde}+${largo}`);
      }
    }
  });
});

describe('verificarToken', () => {
  const opc = () => ({ proyecto: PROYECTO, buscarJwks: async () => jwks, ahora: () => AHORA });

  test('acepta un token válido y marca a los anónimos', async () => {
    assert.deepEqual(await verificarToken(await firmar(datosToken('u1')), opc()), {
      uid: 'u1',
      anonimo: false,
      email: '',
      emailVerificado: false,
    });
    const anon = await firmar(datosToken('u1', { firebase: { sign_in_provider: 'anonymous' } }));
    assert.equal((await verificarToken(anon, opc())).anonimo, true);
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

describe('PUT: subir', () => {
  test('guarda el PDF con su huella (calculada por el servidor) y lo enlaza a la cuenta', async () => {
    const bytes = pdf(100);
    const r = await subir('u1', bytes, '1_a.pdf');
    assert.equal(r.status, 201);
    const j = await r.json();
    assert.equal(j.sha256, sha(bytes));
    assert.equal(j.deduplicado, false);
    assert.equal(j.url, `https://archivos.test/b/${sha(bytes)}`);
    assert.deepEqual(copias(), [`blob/${sha(bytes)}`]);
    assert.deepEqual(enlaces().map((e) => [e.uid, e.clave]), [['u1', 'usuarios/u1/canciones/1_a.pdf']]);
  });
  test('un MP3 va a secuencias', async () => {
    assert.equal((await subir('u1', mp3(), '1_a.mp3', 'secuencias', 'audio/mpeg')).status, 201);
  });
  test('el mismo archivo de dos cuentas se guarda UNA vez', async () => {
    const bytes = pdf(500, 7);
    const a = await (await subir('u1', bytes, '1_a.pdf')).json();
    const b = await (await subir('u2', bytes, '9_otro.pdf')).json();
    assert.equal(a.deduplicado, false);
    assert.equal(b.deduplicado, true);
    assert.equal(copias().length, 1);
    assert.equal(enlaces().length, 2);
  });
  test('cada cuenta paga su cuota completa aunque comparta la copia', async () => {
    const bytes = pdf(500, 7);
    await subir('u1', bytes, '1_a.pdf');
    await subir('u2', bytes, '1_a.pdf');
    assert.equal(await usoDeUsuario(env.DB, 'u1'), bytes.length);
    assert.equal(await usoDeUsuario(env.DB, 'u2'), bytes.length);
  });
  test('reemplazar un archivo por otro distinto libera la copia vieja si nadie más la usa', async () => {
    const a = pdf(100, 1);
    const b = pdf(100, 2);
    await subir('u1', a, '1_a.pdf');
    await subir('u1', b, '1_a.pdf');
    assert.deepEqual(copias(), [`blob/${sha(b)}`]);
    assert.equal(enlaces().length, 1);
  });
  test('reemplazar no cuenta dos veces en la cuota', async () => {
    sembrar('u1', 'usuarios/u1/canciones/1_a.pdf', CUOTA_BYTES - 10);
    assert.equal((await subir('u1', pdf(100), '1_a.pdf')).status, 201);
  });
  test('sin token: 401; vencido: 401', async () => {
    assert.equal((await pedir('PUT', `/o/${ruta('u1')}`, { tipo: 'application/pdf', cuerpo: pdf() })).status, 401);
    const viejo = await firmar(datosToken('u1', { exp: AHORA / 1000 - 5 }));
    const r = await pedir('PUT', `/o/${ruta('u1')}`, { token: viejo, tipo: 'application/pdf', cuerpo: pdf() });
    assert.equal(r.status, 401);
  });
  test('carpeta de otra cuenta: 403; invitado: 403', async () => {
    const token = await firmar(datosToken('u2'));
    assert.equal((await pedir('PUT', `/o/${ruta('u1')}`, { token, tipo: 'application/pdf', cuerpo: pdf() })).status, 403);
    const anon = await firmar(datosToken('u1', { firebase: { sign_in_provider: 'anonymous' } }));
    assert.equal((await pedir('PUT', `/o/${ruta('u1')}`, { token: anon, tipo: 'application/pdf', cuerpo: pdf() })).status, 403);
  });
  test('tipo no permitido, PDF falso o vacío', async () => {
    const t = await firmar(datosToken('u1'));
    const p = (tipo, cuerpo) => pedir('PUT', `/o/${ruta('u1')}`, { token: t, tipo, cuerpo });
    assert.equal((await p('text/html', pdf())).status, 415);
    assert.equal((await p('audio/mpeg', mp3())).status, 415);
    assert.equal((await p('application/pdf', new Uint8Array(50))).status, 415);
    assert.equal((await p('application/pdf', new Uint8Array(0))).status, 400);
  });
  test('PDF de más de 5 MB: 413 con los tamaños', async () => {
    const grande = new Uint8Array(CARPETAS.canciones.maximo + 1);
    grande.set(Buffer.from('%PDF-'));
    const r = await subir('u1', grande, '1_a.pdf');
    assert.equal(r.status, 413);
    assert.equal(r.headers.get('x-maximo'), String(CARPETAS.canciones.maximo));
    assert.equal(r.headers.get('x-bytes'), String(grande.byteLength));
  });
  test('sin espacio: 507 con uso y cuota; el espacio de otra cuenta no cuenta', async () => {
    sembrar('u1', 'usuarios/u1/secuencias/viejo.mp3', CUOTA_BYTES - 50);
    sembrar('u2', 'usuarios/u2/secuencias/enorme.mp3', CUOTA_BYTES);
    const r = await subir('u1', pdf(100), '1_a.pdf');
    assert.equal(r.status, 507);
    assert.equal(r.headers.get('x-usado'), String(CUOTA_BYTES - 50));
    assert.equal(r.headers.get('x-cuota'), String(CUOTA_BYTES));
    assert.equal((await subir('u3', pdf(100), '1_a.pdf')).status, 201);
  });

  test('Pro tiene más espacio: pasa el normal y para en el de Pro', async () => {
    cuentasPro.add('p1');
    sembrar('p1', 'usuarios/p1/secuencias/viejo.mp3', CUOTA_BYTES - 50);
    assert.equal((await subir('p1', pdf(100), '1_a.pdf')).status, 201);
    sembrar('p1', 'usuarios/p1/secuencias/enorme.mp3', CUOTA_PRO_BYTES - CUOTA_BYTES);
    const r = await subir('p1', pdf(100), '2_b.pdf');
    assert.equal(r.status, 507);
    assert.equal(r.headers.get('x-cuota'), String(CUOTA_PRO_BYTES));
  });
  test('sin Pro, o si no se puede comprobar, vale el espacio normal', async () => {
    sembrar('falla', 'usuarios/falla/secuencias/viejo.mp3', CUOTA_BYTES - 50);
    const r = await subir('falla', pdf(100), '1_a.pdf');
    assert.equal(r.status, 507);
    assert.equal(r.headers.get('x-cuota'), String(CUOTA_BYTES));
  });
  test('solo se consulta si es Pro cuando no entra en el espacio normal, y se recuerda', async () => {
    assert.equal((await subir('u1', pdf(100), '1_a.pdf')).status, 201);
    assert.equal(consultasPro, 0);
    sembrar('u2', 'usuarios/u2/secuencias/viejo.mp3', CUOTA_BYTES - 50);
    await subir('u2', pdf(100), '1_a.pdf');
    await subir('u2', pdf(100), '2_b.pdf');
    assert.equal(consultasPro, 1);
  });
});

describe('esProEnFirestore', () => {
  const sesion = { uid: 'u1', email: 'Ana@Mail.com', emailVerificado: true };
  const respuestas = (mapa) => async (url) => {
    const clave = Object.keys(mapa).find((k) => url.endsWith(k));
    const r = clave ? mapa[clave] : null;
    return { status: r === null ? 404 : r.status ?? 200, ok: r === null ? false : (r.status ?? 200) < 400, json: async () => r?.cuerpo };
  };
  test('esPro en el perfil', async () => {
    const f = respuestas({ '/usuarios/u1': { cuerpo: { fields: { esPro: { booleanValue: true } } } } });
    assert.equal(await esProEnFirestore(PROYECTO, sesion, 't', f), true);
  });
  test('mail en pro_gratis (en minúsculas) con el mail verificado', async () => {
    const f = respuestas({ '/usuarios/u1': { cuerpo: { fields: { esPro: { booleanValue: false } } } }, '/pro_gratis/ana%40mail.com': { cuerpo: {} } });
    assert.equal(await esProEnFirestore(PROYECTO, sesion, 't', f), true);
    assert.equal(await esProEnFirestore(PROYECTO, { ...sesion, emailVerificado: false }, 't', f), false);
  });
  test('ninguno de los dos: no es Pro; un error de Firestore se propaga', async () => {
    assert.equal(await esProEnFirestore(PROYECTO, sesion, 't', respuestas({})), false);
    await assert.rejects(esProEnFirestore(PROYECTO, sesion, 't', respuestas({ '/usuarios/u1': { status: 500 } })));
  });
});

describe('DELETE', () => {
  test('quita el enlace; la copia se conserva mientras la use otra cuenta', async () => {
    const bytes = pdf(300, 5);
    await subir('u1', bytes, '1_a.pdf');
    await subir('u2', bytes, '2_a.pdf');
    const r = await pedir('DELETE', `/o/${ruta('u1')}`, { token: await firmar(datosToken('u1')) });
    assert.equal(r.status, 204);
    assert.equal(enlaces().length, 1);
    assert.deepEqual(copias(), [`blob/${sha(bytes)}`]);
  });
  test('la copia se borra cuando ya no la usa nadie; borrar dos veces es igual', async () => {
    const bytes = pdf(300, 5);
    await subir('u1', bytes, '1_a.pdf');
    const t = await firmar(datosToken('u1'));
    assert.equal((await pedir('DELETE', `/o/${ruta('u1')}`, { token: t })).status, 204);
    assert.deepEqual(copias(), []);
    assert.equal(env.DB.sql.prepare('SELECT COUNT(*) AS n FROM blobs').get().n, 0);
    assert.equal((await pedir('DELETE', `/o/${ruta('u1')}`, { token: t })).status, 204);
  });
  test('no borra lo de otra cuenta (403) ni sin token (401)', async () => {
    await subir('u1', pdf(100), '1_a.pdf');
    assert.equal((await pedir('DELETE', `/o/${ruta('u1')}`, { token: await firmar(datosToken('u2')) })).status, 403);
    assert.equal((await pedir('DELETE', `/o/${ruta('u1')}`)).status, 401);
    assert.equal(enlaces().length, 1);
  });
});

describe('vincular una copia que ya existe', () => {
  const prueba = (bytes, rangos) => rangos.map(([desde, largo]) => sha(bytes.slice(desde, desde + largo)));
  const iniciar = async (uid, huella, clave) =>
    pedir('POST', '/vincular/iniciar', {
      token: await firmar(datosToken(uid)),
      tipo: 'application/json',
      cuerpo: JSON.stringify({ sha256: huella, ruta: clave }),
    });
  const confirmar = async (uid, id, respuestas) =>
    pedir('POST', '/vincular/confirmar', {
      token: await firmar(datosToken(uid)),
      tipo: 'application/json',
      cuerpo: JSON.stringify({ id, respuestas }),
    });

  test('si la copia no existe, 404: hay que subirla', async () => {
    const r = await iniciar('u2', sha('nada'), ruta('u2'));
    assert.equal(r.status, 404);
  });
  test('quien tiene el archivo se enlaza sin subirlo y la copia no se duplica', async () => {
    const bytes = pdf(2000, 9);
    await subir('u1', bytes, '1_a.pdf');
    const d = await (await iniciar('u2', sha(bytes), ruta('u2', '5_b.pdf'))).json();
    const r = await confirmar('u2', d.id, prueba(bytes, d.rangos));
    assert.equal(r.status, 201);
    const j = await r.json();
    assert.equal(j.deduplicado, true);
    assert.equal(j.url, `https://archivos.test/b/${sha(bytes)}`);
    assert.equal(copias().length, 1);
    assert.deepEqual(enlaces().map((e) => e.uid), ['u1', 'u2']);
  });
  test('sin el archivo no se puede: una prueba equivocada da 403 y no enlaza', async () => {
    const bytes = pdf(2000, 9);
    await subir('u1', bytes, '1_a.pdf');
    const d = await (await iniciar('u2', sha(bytes), ruta('u2'))).json();
    const r = await confirmar('u2', d.id, d.rangos.map(() => sha('adivinado')));
    assert.equal(r.status, 403);
    assert.equal(enlaces().length, 1);
  });
  test('el desafío se usa una sola vez y no sirve para otra cuenta ni vencido', async () => {
    const bytes = pdf(2000, 9);
    await subir('u1', bytes, '1_a.pdf');
    const d = await (await iniciar('u2', sha(bytes), ruta('u2'))).json();
    assert.equal((await confirmar('u3', d.id, prueba(bytes, d.rangos))).status, 403);
    assert.equal((await confirmar('u2', d.id, prueba(bytes, d.rangos))).status, 201);
    assert.equal((await confirmar('u2', d.id, prueba(bytes, d.rangos))).status, 403);
    const d2 = await (await iniciar('u2', sha(bytes), ruta('u2', 'otro.pdf'))).json();
    reloj += 3 * 60 * 1000;
    assert.equal((await confirmar('u2', d2.id, prueba(bytes, d2.rangos))).status, 403);
  });
  test('no se puede enlazar en la carpeta de otra cuenta ni con una huella inventada', async () => {
    const bytes = pdf(2000, 9);
    await subir('u1', bytes, '1_a.pdf');
    assert.equal((await iniciar('u2', sha(bytes), ruta('u1', 'robado.pdf'))).status, 403);
    assert.equal((await iniciar('u2', 'zzz', ruta('u2'))).status, 403);
  });
  test('un PDF no se enlaza como secuencia (415) y la cuota también rige (507)', async () => {
    const bytes = pdf(2000, 9);
    await subir('u1', bytes, '1_a.pdf');
    const d = await (await iniciar('u2', sha(bytes), ruta('u2', 'x.mp3', 'secuencias'))).json();
    assert.equal((await confirmar('u2', d.id, prueba(bytes, d.rangos))).status, 415);
    sembrar('u2', 'usuarios/u2/secuencias/lleno.mp3', CUOTA_BYTES);
    const d2 = await (await iniciar('u2', sha(bytes), ruta('u2', 'y.pdf'))).json();
    assert.equal((await confirmar('u2', d2.id, prueba(bytes, d2.rangos))).status, 507);
  });
  test('sin token: 401; invitado: 403; método equivocado: 405', async () => {
    assert.equal((await pedir('POST', '/vincular/iniciar', { tipo: 'application/json', cuerpo: '{}' })).status, 401);
    const anon = await firmar(datosToken('u1', { firebase: { sign_in_provider: 'anonymous' } }));
    assert.equal((await pedir('POST', '/vincular/iniciar', { token: anon, tipo: 'application/json', cuerpo: '{}' })).status, 403);
    assert.equal((await pedir('GET', '/vincular/iniciar')).status, 404);
  });
});

describe('GET, HEAD y CORS', () => {
  const audio = new Uint8Array([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
  const prepararAudio = async () => {
    const todo = new Uint8Array([0xff, 0xfb, 0x90, 0, ...audio]);
    await subir('u1', todo, '1_a.mp3', 'secuencias', 'audio/mpeg');
    return sha(todo);
  };

  test('/b/{huella} se lee sin token, con caché larga y CORS abierto', async () => {
    const h = await prepararAudio();
    const r = await pedir('GET', `/b/${h}`);
    assert.equal(r.status, 200);
    assert.equal(r.headers.get('Content-Type'), 'audio/mpeg');
    assert.equal(r.headers.get('Content-Length'), '14');
    assert.match(r.headers.get('Cache-Control'), /immutable/);
    assert.equal(r.headers.get('Access-Control-Allow-Origin'), '*');
  });
  test('la ruta lógica de la cuenta también devuelve su archivo', async () => {
    await prepararAudio();
    const r = await pedir('GET', `/o/${ruta('u1', '1_a.mp3', 'secuencias')}`);
    assert.equal(r.status, 200);
    assert.equal((await pedir('GET', `/o/${ruta('u1', 'no.mp3', 'secuencias')}`)).status, 404);
  });
  test('rango: 206 con Content-Range', async () => {
    const h = await prepararAudio();
    const r = await pedir('GET', `/b/${h}`, { headers: { Range: 'bytes=2-5' } });
    assert.equal(r.status, 206);
    assert.equal(r.headers.get('Content-Range'), 'bytes 2-5/14');
    assert.equal(r.headers.get('Content-Length'), '4');
  });
  test('HEAD sin cuerpo, 404 si no existe y 405 en otros métodos', async () => {
    const h = await prepararAudio();
    const head = await pedir('HEAD', `/b/${h}`);
    assert.equal(head.status, 200);
    assert.equal(await head.text(), '');
    assert.equal((await pedir('GET', `/b/${sha('no existe')}`)).status, 404);
    assert.equal((await pedir('POST', `/o/${ruta('u1')}`)).status, 405);
    assert.equal((await pedir('PUT', `/b/${h}`)).status, 405);
  });
  test('OPTIONS responde a los sitios permitidos; uno no permitido no recibe CORS de escritura', async () => {
    const o = await pedir('OPTIONS', `/o/${ruta('u1')}`, { headers: { Origin: ORIGEN } });
    assert.equal(o.status, 204);
    assert.equal(o.headers.get('Access-Control-Allow-Origin'), ORIGEN);
    assert.match(o.headers.get('Access-Control-Allow-Methods'), /POST/);
    const t = await firmar(datosToken('u1'));
    const r = await pedir('PUT', `/o/${ruta('u1')}`, {
      token: t,
      tipo: 'application/pdf',
      cuerpo: pdf(),
      headers: { Origin: 'https://malo.example' },
    });
    assert.equal(r.status, 201);
    assert.equal(r.headers.get('Access-Control-Allow-Origin'), null);
  });
});
