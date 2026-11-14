// Simulador de carga: N "celulares" en la misma sala, contra el Firebase REAL.
// Cada dispositivo escucha lo MISMO que la app real:
//   - el músico (dispositivos 1..N-1): solo sus pedidos (where nombre, últimos 10), el setlist
//     y un "vigilante de conexión";
//   - el sonidista (dispositivo 0): todos los pedidos (últimos 200) y el setlist.
// Cuenta las lecturas (cada documento que Firestore entrega a un escucha cuenta como 1) y mide
// tiempos. Ver README.md.
// Variables: DISPOSITIVOS, SEGUNDOS, INTERVALO_MS, RAFAGA, CORTE_S, VIGILANTE (pedido|presencia).
import { initializeApp, deleteApp } from 'firebase/app';
import { getAuth, signInAnonymously, deleteUser } from 'firebase/auth';
import {
  addDoc, collection, deleteDoc, disableNetwork, doc, enableNetwork, getDocs, getFirestore,
  limit, onSnapshot, orderBy, query, serverTimestamp, setDoc, terminate, updateDoc, where,
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
// Segundos que 3 dispositivos (el 4, 5 y 6) pasan sin internet a un tercio de la prueba (0 = sin cortes).
const CORTE_S = Number(process.env.CORTE_S ?? 0);
// 'pedido' = el vigilante de conexión de antes (escucha el último pedido de la sala);
// 'presencia' = el de ahora (escucha el documento de presencia propio).
const VIGILANTE = process.env.VIGILANTE ?? 'presencia';

// Tope de seguridad: la cuota gratuita de Firebase es de 50.000 lecturas por día.
const pedidos = N * Math.ceil((SEGUNDOS * 1000) / INTERVALO) + N * RAFAGA;
const porPedido = 2 + 2 + (VIGILANTE === 'pedido' ? (N - 1) * 2 : 0);
const lecturas = pedidos * porPedido + Math.ceil(SEGUNDOS / 5) * 3 * N;
if (lecturas > 20000) {
  console.error(`Abortado: se estiman ${lecturas} lecturas (tope 20.000). Bajá DISPOSITIVOS o SEGUNDOS, o subí INTERVALO_MS.`);
  process.exit(1);
}

// SALA=XXXXXXXX: se une a una sala que ya existe (con celulares reales) y el
// dispositivo 0 atiende TODOS los pedidos, también los de los celulares.
const SALA_REAL = process.env.SALA ?? '';
const codigo = SALA_REAL || ('SIM' + Math.random().toString(36).slice(2, 7).toUpperCase().padEnd(5, 'X'));
const dormir = (ms) => new Promise((r) => setTimeout(r, ms));
const pct = (a, p) => (a.length ? [...a].sort((x, y) => x - y)[Math.min(a.length - 1, Math.floor((a.length * p) / 100))] : null);
const maximo = (a) => (a.length ? Math.max(...a) : 0);

const m = {
  conexion: [], escritura: [], alSonidista: [], vueltaAlAutor: [], setlist: [], trasCorte: [], reconexion: [],
  enviados: 0, fallidos: 0, errores: {},
  lecturas: { sonidista: 0, propios: 0, vigilante: 0, setlist: 0 },
  reales: {},
};
const anotarError = (e) => {
  const c = e?.code ?? e?.message ?? String(e);
  m.errores[c] = (m.errores[c] ?? 0) + 1;
};

const dispositivos = [];
async function crear(i) {
  const t0 = Date.now();
  const app = initializeApp(config, 'sim' + i);
  const auth = getAuth(app);
  await signInAnonymously(auth);
  const d = { i, app, auth, db: getFirestore(app), cierres: [], recibidos: new Set(), vueltas: new Set() };
  m.conexion.push(Date.now() - t0);
  dispositivos.push(d);
}

const RE = /^SIM (\d+) (\d+) (\d+)( OFF)?$/;

function escuchar(d) {
  const salaCol = (sub) => collection(d.db, 'salas', codigo, sub);
  if (d.i === 0) {
    d.cierres.push(onSnapshot(query(salaCol('pedidos'), orderBy('createdAt', 'desc'), limit(SALA_REAL ? 600 : 200)), (snap) => {
      for (const c of snap.docChanges()) {
        m.lecturas.sonidista++;
        if (c.type !== 'added' || c.doc.metadata.hasPendingWrites) continue;
        const x = RE.exec(c.doc.data().pedido ?? '');
        if (!x && SALA_REAL && !d.recibidos.has(c.doc.id)) {
          // Pedido de un celular real: se cuenta por autor y se atiende igual.
          d.recibidos.add(c.doc.id);
          const autor = c.doc.data().nombre ?? '?';
          m.reales[autor] = (m.reales[autor] ?? 0) + 1;
          const ref0 = c.doc.ref;
          dormir(300 + Math.random() * 500)
            .then(() => updateDoc(ref0, { visto: true }))
            .then(() => (Math.random() < 0.5 ? updateDoc(ref0, { respuesta: 'ok', atendido: true }) : null))
            .catch(anotarError);
          continue;
        }
        if (!x || d.recibidos.has(c.doc.id)) continue;
        d.recibidos.add(c.doc.id);
        (x[4] ? m.trasCorte : m.alSonidista).push(Date.now() - Number(x[3]));
        const ref = c.doc.ref;
        dormir(300 + Math.random() * 500)
          .then(() => updateDoc(ref, { visto: true }))
          .then(() => (Math.random() < 0.5 ? updateDoc(ref, { respuesta: 'ok', atendido: true }) : null))
          .catch(anotarError);
      }
    }, anotarError));
  } else {
    d.cierres.push(onSnapshot(query(salaCol('pedidos'), where('nombre', '==', 'Sim ' + d.i), orderBy('createdAt', 'desc'), limit(10)), (snap) => {
      for (const c of snap.docChanges()) {
        m.lecturas.propios++;
        const data = c.doc.data();
        const x = RE.exec(data.pedido ?? '');
        if (c.type === 'modified' && x && data.visto && !d.vueltas.has(c.doc.id) && !c.doc.metadata.hasPendingWrites) {
          d.vueltas.add(c.doc.id);
          m.vueltaAlAutor.push(Date.now() - Number(x[3]));
        }
      }
    }, anotarError));
    const objetivo = VIGILANTE === 'pedido'
      ? query(salaCol('pedidos'), limit(1))
      : doc(d.db, 'salas', codigo, 'miembros', d.auth.currentUser.uid);
    d.cierres.push(onSnapshot(objetivo, { includeMetadataChanges: true }, (s) => {
      if (s.metadata.fromCache) return;
      m.lecturas.vigilante += VIGILANTE === 'pedido' ? s.docChanges().length : (s.exists() ? 1 : 0);
    }, anotarError));
  }
  let primera = true;
  d.cierres.push(onSnapshot(salaCol('setlist'), (snap) => {
    const inicial = primera;
    primera = false;
    m.lecturas.setlist += snap.docChanges().length;
    if (inicial) return;
    for (const c of snap.docChanges()) {
      if (c.type === 'removed') continue;
      const t = c.doc.data().sim_t0;
      if (typeof t === 'number' && !c.doc.metadata.hasPendingWrites && c.doc.data().sim_de !== d.i) m.setlist.push(Date.now() - t);
    }
  }, anotarError));
}

async function mandar(d, secuencia) {
  const t0 = Date.now();
  try {
    await addDoc(collection(d.db, 'salas', codigo, 'pedidos'), {
      sala_id: codigo, nombre: 'Sim ' + d.i, rol: 'Prueba',
      pedido: `SIM ${d.i} ${secuencia} ${t0}${d.sinRed ? ' OFF' : ''}`,
      atendido: false, urgente: secuencia % 7 === 0, respuesta: '', createdAt: serverTimestamp(),
    });
    m.escritura.push(Date.now() - t0);
    m.enviados++;
  } catch (e) {
    m.fallidos++;
    anotarError(e);
  }
}

async function limpiar() {
  try {
    for (const sub of (process.env.NOLIMPIAR ? [] : SALA_REAL ? ['pedidos'] : ['pedidos', 'setlist'])) {
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
console.log(`Sala ${codigo}: ${N} dispositivos, ${SEGUNDOS} s, un pedido cada ${INTERVALO} ms, ráfaga ${RAFAGA}, cortes ${CORTE_S} s, vigilante "${VIGILANTE}".`);
try {
  await Promise.all(Array.from({ length: N }, (_, i) => crear(i)));
  dispositivos.sort((a, b) => a.i - b.i);
  dispositivos.forEach(escuchar);
  if (!SALA_REAL) {
    await setDoc(doc(dispositivos[0].db, 'salas', codigo, 'setlist', 'tema1'), {
      titulo: 'Tema de prueba', orden: 0, transposicion: 0, sim_t0: Date.now(), sim_de: 0,
    });
  }
  await dormir(1500);

  const fin = Date.now() + SEGUNDOS * 1000;
  const musicos = dispositivos.slice(1);
  const envios = musicos.map(async (d) => {
    let s = 0;
    await dormir(Math.random() * INTERVALO);
    while (Date.now() < fin) {
      mandar(d, ++s);
      await dormir(INTERVALO * (0.7 + Math.random() * 0.6));
    }
  });
  const cambiosTono = (SALA_REAL ? [] : musicos.slice(0, 3)).map(async (d) => {
    while (Date.now() < fin) {
      await dormir(5000 * (0.8 + Math.random() * 0.4));
      updateDoc(doc(d.db, 'salas', codigo, 'setlist', 'tema1'), {
        transposicion: Math.round(Math.random() * 4 - 2), sim_t0: Date.now(), sim_de: d.i,
      }).catch(anotarError);
    }
  });
  const cortes = CORTE_S > 0 && N > 6 ? dispositivos.slice(4, 7).map(async (d) => {
    await dormir((SEGUNDOS * 1000) / 3);
    d.sinRed = true;
    await disableNetwork(d.db);
    await dormir(CORTE_S * 1000);
    const t = Date.now();
    await enableNetwork(d.db);
    m.reconexion.push(Date.now() - t);
    d.sinRed = false;
  }) : [];
  await Promise.all([...envios, ...cambiosTono, ...cortes]);

  console.log('Ráfaga: todos los músicos mandan pedidos a la vez...');
  await Promise.all(musicos.map(async (d) => {
    await Promise.all(Array.from({ length: RAFAGA }, (_, k) => mandar(d, 1000 + k)));
  }));
  await dormir(8000);
} finally {
  await limpiar();
}

const total = Object.values(m.lecturas).reduce((a, b) => a + b, 0);
const llegados = m.alSonidista.length + m.trasCorte.length;
const informe = {
  fecha: new Date().toISOString(), dispositivos: N, segundos: SEGUNDOS, intervaloMs: INTERVALO,
  rafaga: RAFAGA, corteDeRedS: CORTE_S, vigilante: VIGILANTE,
  duracionTotalS: Math.round((Date.now() - inicio) / 1000),
  pedidosEnviados: m.enviados, pedidosFallidos: m.fallidos, pedidosLlegadosAlSonidista: llegados,
  porcentajeEntregado: m.enviados ? Math.round((llegados / m.enviados) * 1000) / 10 : null,
  conexionMs: { p50: pct(m.conexion, 50), max: maximo(m.conexion) },
  escrituraMs: { p50: pct(m.escritura, 50), p95: pct(m.escritura, 95), max: maximo(m.escritura) },
  llegadaAlSonidistaMs: { p50: pct(m.alSonidista, 50), p95: pct(m.alSonidista, 95), p99: pct(m.alSonidista, 99), max: maximo(m.alSonidista) },
  vueltaAlAutorMs: { n: m.vueltaAlAutor.length, p50: pct(m.vueltaAlAutor, 50), p95: pct(m.vueltaAlAutor, 95), max: maximo(m.vueltaAlAutor) },
  cambioDeTonoMs: { n: m.setlist.length, p50: pct(m.setlist, 50), p95: pct(m.setlist, 95), max: maximo(m.setlist) },
  conCorteDeRed: { pedidos: m.trasCorte.length, reconexionMaxMs: maximo(m.reconexion), llegadaMs: { p50: pct(m.trasCorte, 50), max: maximo(m.trasCorte) } },
  lecturas: { ...m.lecturas, total, porPedido: m.enviados ? Math.round((total / m.enviados) * 10) / 10 : null },
  celularesReales: m.reales,
  errores: m.errores,
};
writeFileSync(new URL('./informe.json', import.meta.url), JSON.stringify(informe, null, 2));
console.log(JSON.stringify(informe, null, 2));
process.exit(0);
