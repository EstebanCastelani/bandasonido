// Simulador de carga: N "celulares" en la misma sala, contra el Firebase REAL.
// Cada uno entra como invitado, escucha pedidos y setlist en vivo (como la app)
// y manda pedidos. Un "sonidista" (el dispositivo 0) los marca como vistos y los
// atiende. Mide cuánto tarda cada pedido en llegar a los demás.
// Ver README.md. Variables: DISPOSITIVOS, SEGUNDOS, INTERVALO_MS, RAFAGA.
import { initializeApp, deleteApp } from 'firebase/app';
import { getAuth, signInAnonymously, deleteUser } from 'firebase/auth';
import {
  addDoc, collection, deleteDoc, doc, getDocs, getFirestore, limit, onSnapshot,
  orderBy, query, serverTimestamp, setDoc, terminate, updateDoc,
} from 'firebase/firestore';
import { writeFileSync } from 'node:fs';

// Misma configuración pública que usa la app (frontend/lib/main.dart).
const config = {
  apiKey: 'AIzaSyBmIF6Eq5Av-fgDSLIlEdRvAoWdKqth-rM',
  authDomain: 'appbandasonido.firebaseapp.com',
  projectId: 'appbandasonido',
  storageBucket: 'appbandasonido.firebasestorage.app',
  messagingSenderId: '784903375488',
  appId: '1:784903375488:web:6db920dbfb9ebbc6eef465',
};

const N = Number(process.env.DISPOSITIVOS ?? 10);
const SEGUNDOS = Number(process.env.SEGUNDOS ?? 60);
const INTERVALO = Number(process.env.INTERVALO_MS ?? 4000);
const RAFAGA = Number(process.env.RAFAGA ?? 5);

// Tope de seguridad: la cuota gratuita de Firebase es de 50.000 lecturas por día.
const escrituras = N * Math.ceil((SEGUNDOS * 1000) / INTERVALO) + N * RAFAGA + Math.ceil(SEGUNDOS / 5) * 3;
const lecturas = escrituras * N;
if (lecturas > 20000) {
  console.error(`Abortado: se estiman ${lecturas} lecturas (tope 20.000). Bajá DISPOSITIVOS, SEGUNDOS o subí INTERVALO_MS.`);
  process.exit(1);
}

const codigo = 'SIM' + Math.random().toString(36).slice(2, 7).toUpperCase().padEnd(5, 'X');
const dormir = (ms) => new Promise((r) => setTimeout(r, ms));
const pct = (a, p) => (a.length ? [...a].sort((x, y) => x - y)[Math.min(a.length - 1, Math.floor((a.length * p) / 100))] : null);

const metricas = {
  conexion: [], escrituraPedido: [], llegadaPedido: [], llegadaSetlist: [],
  enviados: 0, fallidos: 0, errores: {}, recibidos: 0, esperados: 0,
};
const anotarError = (e) => {
  const c = e?.code ?? e?.message ?? String(e);
  metricas.errores[c] = (metricas.errores[c] ?? 0) + 1;
};

const dispositivos = [];
async function crear(i) {
  const t0 = Date.now();
  const app = initializeApp(config, 'sim' + i);
  const auth = getAuth(app);
  await signInAnonymously(auth);
  const db = getFirestore(app);
  const d = { i, app, auth, db, vistos: new Set(), cierres: [] };
  metricas.conexion.push(Date.now() - t0);
  dispositivos.push(d);
  return d;
}

function escuchar(d) {
  const pedidos = query(collection(d.db, 'salas', codigo, 'pedidos'), orderBy('createdAt', 'desc'), limit(200));
  d.cierres.push(onSnapshot(pedidos, (snap) => {
    for (const c of snap.docChanges()) {
      if (c.type !== 'added') continue;
      const dato = c.doc.data();
      const m = /^SIM (\d+) (\d+) (\d+)$/.exec(dato.pedido ?? '');
      // Solo lo que llegó del servidor y lo mandó otro dispositivo.
      if (!m || c.doc.metadata.hasPendingWrites || Number(m[1]) === d.i) continue;
      if (d.vistos.has(c.doc.id)) continue;
      d.vistos.add(c.doc.id);
      metricas.recibidos++;
      metricas.llegadaPedido.push(Date.now() - Number(m[3]));
      // El sonidista los marca como vistos y los atiende.
      if (d.i === 0) {
        const ref = c.doc.ref;
        dormir(300 + Math.random() * 500)
          .then(() => updateDoc(ref, { visto: true }))
          .then(() => (Math.random() < 0.5 ? updateDoc(ref, { respuesta: 'ok', atendido: true }) : null))
          .catch(anotarError);
      }
    }
  }, anotarError));
  const setlist = collection(d.db, 'salas', codigo, 'setlist');
  let primera = true;
  d.cierres.push(onSnapshot(setlist, (snap) => {
    const inicial = primera;
    primera = false;
    // El primer aviso trae lo que ya existía: no es un cambio en vivo.
    if (inicial) return;
    for (const c of snap.docChanges()) {
      if (c.type === 'removed') continue; // el borrado de la limpieza no es una llegada
      const t = c.doc.data().sim_t0;
      if (typeof t === 'number' && !c.doc.metadata.hasPendingWrites && c.doc.data().sim_de !== d.i) {
        metricas.llegadaSetlist.push(Date.now() - t);
      }
    }
  }, anotarError));
}

async function mandar(d, secuencia) {
  const t0 = Date.now();
  try {
    await addDoc(collection(d.db, 'salas', codigo, 'pedidos'), {
      sala_id: codigo, nombre: 'Sim ' + d.i, rol: 'Prueba',
      pedido: `SIM ${d.i} ${secuencia} ${t0}`,
      atendido: false, urgente: secuencia % 7 === 0, respuesta: '', createdAt: serverTimestamp(),
    });
    metricas.escrituraPedido.push(Date.now() - t0);
    metricas.enviados++;
    metricas.esperados += N - 1;
  } catch (e) {
    metricas.fallidos++;
    anotarError(e);
  }
}

async function limpiar() {
  try {
    for (const sub of ['pedidos', 'setlist']) {
      const todos = await getDocs(collection(dispositivos[0].db, 'salas', codigo, sub));
      await Promise.all(todos.docs.map((x) => deleteDoc(x.ref).catch(() => {})));
    }
  } catch (e) { console.error('Limpieza parcial:', e?.code ?? e); }
  for (const d of dispositivos) {
    d.cierres.forEach((c) => { try { c(); } catch {} });
    try { await deleteUser(d.auth.currentUser); } catch {}
    try { await terminate(d.db); await deleteApp(d.app); } catch {}
  }
}

const inicio = Date.now();
console.log(`Sala de prueba ${codigo}: ${N} dispositivos, ${SEGUNDOS} s, un pedido cada ${INTERVALO} ms por dispositivo, ráfaga de ${RAFAGA}.`);
try {
  // 1. Entran todos a la vez.
  await Promise.all(Array.from({ length: N }, (_, i) => crear(i)));
  dispositivos.sort((a, b) => a.i - b.i);
  dispositivos.forEach(escuchar);
  await setDoc(doc(dispositivos[0].db, 'salas', codigo, 'setlist', 'tema1'), {
    titulo: 'Tema de prueba', orden: 0, transposicion: 0, sim_t0: Date.now(), sim_de: 0,
  });
  console.log(`Conectados en ${Math.round(Math.max(...metricas.conexion))} ms (el más lento).`);
  await dormir(1500);

  // 2. Ritmo normal: cada dispositivo manda pedidos; 3 cambian el tono del setlist.
  const fin = Date.now() + SEGUNDOS * 1000;
  const tareas = dispositivos.map(async (d) => {
    let s = 0;
    await dormir(Math.random() * INTERVALO);
    while (Date.now() < fin) {
      mandar(d, ++s);
      await dormir(INTERVALO * (0.7 + Math.random() * 0.6));
    }
  });
  const cambiosTono = dispositivos.slice(1, 4).map(async (d) => {
    while (Date.now() < fin) {
      await dormir(5000 * (0.8 + Math.random() * 0.4));
      updateDoc(doc(d.db, 'salas', codigo, 'setlist', 'tema1'), {
        transposicion: Math.round(Math.random() * 4 - 2), sim_t0: Date.now(), sim_de: d.i,
      }).catch(anotarError);
    }
  });
  await Promise.all([...tareas, ...cambiosTono]);

  // 3. Ráfaga: todos mandan varios pedidos a la vez (un corte de sonido, por ejemplo).
  console.log('Ráfaga: todos mandan pedidos a la vez...');
  await Promise.all(dispositivos.map(async (d) => {
    await Promise.all(Array.from({ length: RAFAGA }, (_, k) => mandar(d, 1000 + k)));
  }));
  await dormir(8000);
} finally {
  await limpiar();
}

const informe = {
  fecha: new Date().toISOString(), dispositivos: N, segundos: SEGUNDOS, intervaloMs: INTERVALO, rafaga: RAFAGA,
  duracionTotalS: Math.round((Date.now() - inicio) / 1000),
  conexionMs: { p50: pct(metricas.conexion, 50), max: Math.max(...metricas.conexion) },
  escrituraPedidoMs: { p50: pct(metricas.escrituraPedido, 50), p95: pct(metricas.escrituraPedido, 95), max: Math.max(0, ...metricas.escrituraPedido) },
  llegadaPedidoMs: { p50: pct(metricas.llegadaPedido, 50), p95: pct(metricas.llegadaPedido, 95), p99: pct(metricas.llegadaPedido, 99), max: Math.max(0, ...metricas.llegadaPedido) },
  llegadaSetlistMs: { p50: pct(metricas.llegadaSetlist, 50), p95: pct(metricas.llegadaSetlist, 95), max: Math.max(0, ...metricas.llegadaSetlist) },
  pedidosEnviados: metricas.enviados, pedidosFallidos: metricas.fallidos,
  entregasEsperadas: metricas.esperados, entregasRecibidas: metricas.recibidos,
  porcentajeEntregado: metricas.esperados ? Math.round((metricas.recibidos / metricas.esperados) * 1000) / 10 : null,
  errores: metricas.errores,
};
writeFileSync(new URL('./informe.json', import.meta.url), JSON.stringify(informe, null, 2));
console.log(JSON.stringify(informe, null, 2));
process.exit(0);
