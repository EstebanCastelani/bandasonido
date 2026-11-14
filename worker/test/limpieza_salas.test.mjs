// Pruebas de la limpieza de salas abandonadas con un Firestore de mentira.
// Se corren con: cd worker && node --test
import assert from 'node:assert/strict';
import { generateKeyPairSync } from 'node:crypto';
import { describe, test } from 'node:test';

import { limpiarSalas } from '../src/limpieza.js';
import { borrarSala, listarSalas, salasAbandonadas, ultimaActividad } from '../src/limpieza_salas.js';

const DIA = 24 * 60 * 60 * 1000;
const AHORA = Date.UTC(2026, 10, 13, 12, 0, 0);
const iso = (diasAtras) => new Date(AHORA - diasAtras * DIA).toISOString();
const P = 'appbandasonido';
const RAIZ = `projects/${P}/databases/(default)/documents`;

/** salas = { CODIGO: { pedidos: [{id, createdAt?, update}], ... } } */
function firestore(salas) {
  const borrados = [];
  const buscar = async (url, o = {}) => {
    const u = String(url);
    const json = (x) => new Response(JSON.stringify(x));
    if (u.includes('oauth2')) return json({ access_token: 't' });
    if (u.includes(':batchWrite')) {
      for (const w of JSON.parse(o.body).writes) {
        borrados.push(w.delete);
        const [, sala, sub, id] = w.delete.split('/documents/')[1].split('/');
        salas[sala][sub] = salas[sala][sub].filter((d) => d.id !== id);
      }
      return json({});
    }
    if (u.includes(':runQuery')) {
      const sala = decodeURIComponent(u.split('/salas/')[1].split(':')[0]);
      const q = JSON.parse(o.body).structuredQuery;
      const sub = q.from[0].collectionId;
      let docs = [...(salas[sala]?.[sub] ?? [])];
      const campo = q.orderBy?.[0]?.field.fieldPath;
      if (campo) docs = docs.filter((d) => d[campo]).sort((a, b) => Date.parse(b[campo]) - Date.parse(a[campo]));
      docs = docs.slice(0, q.limit);
      if (docs.length === 0) return json([{ readTime: 'x' }]);
      return json(docs.map((d) => ({ document: { name: `${RAIZ}/salas/${sala}/${sub}/${d.id}`, fields: d[campo] ? { [campo]: { timestampValue: d[campo] } } : {}, updateTime: d.update } })));
    }
    const m = u.match(/documents\/salas\/([^/?]+)\/([^/?]+)\?/);
    if (m) {
      const docs = (salas[m[1]]?.[m[2]] ?? []).slice(0, 300);
      return json({ documents: docs.map((d) => ({ name: `${RAIZ}/salas/${m[1]}/${m[2]}/${d.id}` })) });
    }
    if (u.includes('documents/salas?')) {
      return json({ documents: Object.keys(salas).map((c) => ({ name: `${RAIZ}/salas/${c}` })) });
    }
    return new Response('?', { status: 404 });
  };
  return { buscar, borrados };
}

const mundo = () => ({
  VIEJA001: { pedidos: [{ id: 'a', createdAt: iso(300), update: iso(300) }], setlist: [{ id: 's', createdAt: iso(250), update: iso(250) }], secuencias: [], miembros: [] },
  ACTIVA01: { pedidos: [{ id: 'a', createdAt: iso(300), update: iso(300) }, { id: 'b', createdAt: iso(5), update: iso(5) }], setlist: [], secuencias: [], miembros: [] },
  SOLOMIEM: { pedidos: [{ id: 'a', createdAt: iso(400), update: iso(400) }], setlist: [], secuencias: [], miembros: [{ id: 'u', ultimaConexion: iso(20), update: iso(20) }] },
  SINFECHA: { pedidos: [{ id: 'a', update: iso(10) }], setlist: [], secuencias: [], miembros: [] },
  VIEJASIN: { pedidos: [{ id: 'a', update: iso(400) }], setlist: [], secuencias: [], miembros: [] },
  VACIA000: { pedidos: [], setlist: [], secuencias: [], miembros: [] },
});

describe('salas abandonadas', () => {
  test('listarSalas devuelve los códigos', async () => {
    assert.deepEqual((await listarSalas(P, 't', firestore(mundo()).buscar)).sort().slice(0, 2), ['ACTIVA01', 'SINFECHA']);
  });

  test('última actividad: lo más nuevo entre subcolecciones', async () => {
    const f = firestore(mundo());
    assert.equal(await ultimaActividad(P, 't', 'VIEJA001', f.buscar), Date.parse(iso(250)));
    assert.equal(await ultimaActividad(P, 't', 'SOLOMIEM', f.buscar), Date.parse(iso(20)));
  });

  test('sin fecha propia cuenta la de modificación; sala vacía no se puede medir', async () => {
    const f = firestore(mundo());
    assert.equal(await ultimaActividad(P, 't', 'SINFECHA', f.buscar), Date.parse(iso(10)));
    assert.equal(await ultimaActividad(P, 't', 'VACIA000', f.buscar), null);
  });

  test('solo las de 180 días o más; las vacías o sin datos no se tocan', async () => {
    const f = firestore(mundo());
    assert.deepEqual((await salasAbandonadas(P, 't', AHORA, 180, f.buscar)).sort(), ['VIEJA001', 'VIEJASIN']);
  });

  test('borrarSala vacía todas las subcolecciones', async () => {
    const m = mundo();
    const f = firestore(m);
    assert.equal(await borrarSala(P, 't', 'VIEJA001', f.buscar), 2);
    assert.deepEqual(m.VIEJA001.pedidos, []);
    assert.deepEqual(m.VIEJA001.setlist, []);
  });
});

describe('limpiarSalas', () => {
  const { privateKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });
  const env = (extra = {}) => ({
    FIREBASE_PROJECT_ID: P,
    GOOGLE_SERVICE_ACCOUNT: JSON.stringify({ client_email: 'x@y', private_key: privateKey.export({ type: 'pkcs8', format: 'pem' }) }),
    ...extra,
  });

  test('sin cuenta de servicio no hace nada', async () => {
    assert.ok((await limpiarSalas({ FIREBASE_PROJECT_ID: P })).omitido);
  });

  test('modo de prueba: lista y no borra', async () => {
    const f = firestore(mundo());
    const r = await limpiarSalas(env(), { ahora: () => AHORA, buscar: f.buscar });
    assert.equal(r.candidatas, 2);
    assert.equal(r.modo, 'solo listar');
    assert.equal(f.borrados.length, 0);
  });

  test('modo real: borra solo las abandonadas', async () => {
    const m = mundo();
    const f = firestore(m);
    const r = await limpiarSalas(env({ BORRAR_SALAS: 'true' }), { ahora: () => AHORA, buscar: f.buscar });
    assert.deepEqual(r.salas.sort(), ['VIEJA001', 'VIEJASIN']);
    assert.equal(m.ACTIVA01.pedidos.length, 2);
    assert.equal(m.SOLOMIEM.pedidos.length, 1);
    assert.equal(m.VIEJASIN.pedidos.length, 0);
  });
});
