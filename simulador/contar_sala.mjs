// Cuenta los pedidos de una sala por autor y por estado (para verificar una prueba).
// Uso: SALA=XXXXXXXX node contar_sala.mjs
import { initializeApp, deleteApp } from 'firebase/app';
import { getAuth, signInAnonymously, deleteUser } from 'firebase/auth';
import { collection, getDocs, getFirestore, query, terminate } from 'firebase/firestore';

const config = {
  apiKey: 'AIzaSyBmIF6Eq5Av-fgDSLIlEdRvAoWdKqth-rM',
  authDomain: 'appbandasonido.firebaseapp.com',
  projectId: 'appbandasonido',
  storageBucket: 'appbandasonido.firebasestorage.app',
  messagingSenderId: '784903375488',
  appId: '1:784903375488:web:6db920dbfb9ebbc6eef465',
};
const sala = process.env.SALA;
if (!sala) { console.error('Falta SALA'); process.exit(1); }
const app = initializeApp(config, 'contador');
const auth = getAuth(app);
await signInAnonymously(auth);
const db = getFirestore(app);
const snap = await getDocs(query(collection(db, 'salas', sala, 'pedidos')));
const por = {};
for (const d of snap.docs) {
  const x = d.data();
  const a = (x.nombre ?? '?').startsWith('Sim ') ? 'Sim (virtuales)' : x.nombre ?? '?';
  por[a] ??= { total: 0, visto: 0, atendido: 0 };
  por[a].total++;
  if (x.visto) por[a].visto++;
  if (x.atendido) por[a].atendido++;
}
const pref = process.env.PREFIJO;
const lista = pref ? snap.docs.map((d) => d.data().pedido).filter((t) => (t ?? '').startsWith(pref)).sort() : undefined;
console.log(JSON.stringify({ sala, totalPedidos: snap.size, porAutor: por, ...(lista ? { coincidencias: lista } : {}) }, null, 2));
try { await deleteUser(auth.currentUser); } catch {}
await terminate(db); await deleteApp(app);
process.exit(0);
