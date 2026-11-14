// Pruebas de la limpieza de invitados, sin Google ni Cloudflare: fetch de mentira,
// un R2 de mentira (Map) y una D1 de mentira (SQLite en memoria con schema.sql).
// Se corren con: cd worker && node --test
import assert from 'node:assert/strict';
import { createVerify, generateKeyPairSync } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { DatabaseSync } from 'node:sqlite';
import { describe, test } from 'node:test';

import { anonimasInactivas, borrarCuentas, limpiarInvitados, tokenDeServicio } from '../src/limpieza.js';

const DIA = 24 * 60 * 60 * 1000;
const AHORA = Date.UTC(2026, 10, 13, 12, 0, 0);
const hace = (dias) => String(AHORA - dias * DIA);
const GOOGLE = [{ providerId: 'google.com' }];

const cuentas = [
  { localId: 'viejaAnon', createdAt: hace(200), lastLoginAt: hace(100) },
  { localId: 'recienteAnon', createdAt: hace(200), lastLoginAt: hace(10) },
  { localId: 'justo89', createdAt: hace(300), lastLoginAt: hace(89) },
  { localId: 'sinAcceso', createdAt: hace(120) },
  { localId: 'viejaGoogle', createdAt: hace(500), lastLoginAt: hace(400), providerUserInfo: GOOGLE },
  { localId: 'viejaMail', createdAt: hace(500), lastLoginAt: hace(400), providerUserInfo: [{ providerId: 'password' }] },
  { localId: 'sinFechas' },
];

const { privateKey, publicKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });
const cuentaServicio = {
  client_email: 'limpieza@appbandasonido.iam.gserviceaccount.com',
  private_key: privateKey.export({ type: 'pkcs8', format: 'pem' }),
};

function d1() {
  const db = new DatabaseSync(':memory:');
  db.exec(readFileSync(new URL('../schema.sql', import.meta.url), 'utf8'));
  const prep = (sql) => ({
    bind: (...a) => ({
      run: async () => (db.prepare(sql).run(...a), {}),
      first: async () => db.prepare(sql).get(...a) ?? null,
      all: async () => ({ results: db.prepare(sql).all(...a) }),
    }),
  });
  return { db, prepare: prep };
}

/** Google de mentira: lista [cuentas] y anota lo que le piden borrar. */
function google(lista) {
  const pedidos = { borrados: [], token: 0, listados: 0 };
  const buscar = async (url, opciones = {}) => {
    const u = String(url);
    if (u.includes('oauth2.googleapis.com/token')) {
      pedidos.token++;
      pedidos.assertion = new URLSearchParams(opciones.body).get('assertion');
      return new Response(JSON.stringify({ access_token: 'tok' }));
    }
    if (u.includes('accounts:batchGet')) {
      pedidos.listados++;
      return new Response(JSON.stringify({ users: lista }));
    }
    if (u.includes('accounts:batchDelete')) {
      pedidos.borrados.push(...JSON.parse(opciones.body).localIds);
      return new Response('{}');
    }
    return new Response('?', { status: 404 });
  };
  return { buscar, pedidos };
}

describe('anonimasInactivas', () => {
  test('solo invitados con 90 días o más sin entrar', () => {
    assert.deepEqual(anonimasInactivas(cuentas, AHORA, 90), ['viejaAnon', 'sinAcceso']);
  });
  test('nunca incluye cuentas con Google o mail', () => {
    const ids = anonimasInactivas(cuentas, AHORA, 1);
    assert.ok(!ids.includes('viejaGoogle') && !ids.includes('viejaMail'));
  });
  test('sin fechas no se toca', () => {
    assert.ok(!anonimasInactivas(cuentas, AHORA, 1).includes('sinFechas'));
  });
});

describe('tokenDeServicio', () => {
  test('firma el JWT con la clave de la cuenta de servicio', async () => {
    const g = google([]);
    assert.equal(await tokenDeServicio(cuentaServicio, { ahora: () => AHORA, buscar: g.buscar }), 'tok');
    const [cab, carga, firma] = g.pedidos.assertion.split('.');
    const v = createVerify('RSA-SHA256').update(`${cab}.${carga}`);
    assert.ok(v.verify(publicKey, Buffer.from(firma, 'base64url')));
    const c = JSON.parse(Buffer.from(carga, 'base64url').toString());
    assert.equal(c.iss, cuentaServicio.client_email);
    assert.equal(c.exp - c.iat, 3600);
  });
});

describe('borrarCuentas', () => {
  test('manda de a 1000', async () => {
    let lotes = 0;
    const buscar = async (_u, o) => {
      lotes++;
      assert.ok(JSON.parse(o.body).localIds.length <= 1000);
      return new Response('{}');
    };
    const ids = Array.from({ length: 2500 }, (_, i) => `u${i}`);
    assert.equal(await borrarCuentas('p', 't', ids, buscar), 2500);
    assert.equal(lotes, 3);
  });
});

describe('limpiarInvitados', () => {
  const entorno = (extra = {}) => {
    const base = d1();
    const bucket = new Map([['blob/h1', 'x'], ['blob/h2', 'y']]);
    base.db.prepare("INSERT INTO blobs VALUES ('h1', 1, 'application/pdf', 0), ('h2', 1, 'application/pdf', 0)").run();
    base.db.prepare("INSERT INTO enlaces VALUES ('viejaAnon','usuarios/viejaAnon/canciones/a','h1',1,0), ('viejaGoogle','usuarios/viejaGoogle/canciones/b','h2',1,0)").run();
    return {
      env: {
        FIREBASE_PROJECT_ID: 'appbandasonido',
        GOOGLE_SERVICE_ACCOUNT: JSON.stringify(cuentaServicio),
        DB: base,
        BUCKET: { delete: async (k) => bucket.delete(k) },
        ...extra,
      },
      base,
      bucket,
    };
  };

  test('sin la cuenta de servicio no hace nada', async () => {
    const r = await limpiarInvitados({ FIREBASE_PROJECT_ID: 'p' });
    assert.ok(r.omitido);
  });

  test('en modo de prueba solo lista: no borra nada', async () => {
    const { env } = entorno({ BORRAR_ANONIMOS: 'false' });
    const g = google(cuentas);
    const r = await limpiarInvitados(env, { ahora: () => AHORA, buscar: g.buscar });
    assert.deepEqual(g.pedidos.borrados, []);
    assert.equal(r.modo, 'solo listar');
    assert.equal(r.candidatas, 2);
    assert.equal(r.borradas, 0);
  });

  test('en modo real borra solo los invitados viejos y suelta sus archivos', async () => {
    const { env, base, bucket } = entorno({ BORRAR_ANONIMOS: 'true' });
    const g = google(cuentas);
    const r = await limpiarInvitados(env, { ahora: () => AHORA, buscar: g.buscar });
    assert.deepEqual(g.pedidos.borrados.sort(), ['sinAcceso', 'viejaAnon']);
    assert.equal(r.borradas, 2);
    assert.ok(!bucket.has('blob/h1'), 'la copia sin dueño se borra');
    assert.ok(bucket.has('blob/h2'), 'la de la cuenta con Google se conserva');
    assert.equal(base.db.prepare('SELECT COUNT(*) n FROM enlaces').get().n, 1);
  });

  test('respeta DIAS_INACTIVO_INVITADO', async () => {
    const { env } = entorno({ DIAS_INACTIVO_INVITADO: '5' });
    const r = await limpiarInvitados(env, { ahora: () => AHORA, buscar: google(cuentas).buscar });
    assert.equal(r.candidatas, 4);
  });
});
