// Manda unos pedidos de ejemplo a una sala de PRUEBA (para sacar capturas).
// Uso: SALA=XXXXXXXX node pedidos_prueba.mjs
import { initializeApp, deleteApp } from 'firebase/app';
import { getAuth, signInAnonymously, deleteUser } from 'firebase/auth';
import { addDoc, collection, getFirestore, serverTimestamp, terminate } from 'firebase/firestore';

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
const app = initializeApp(config, 'pedidos');
const auth = getAuth(app);
await signInAnonymously(auth);
const db = getFirestore(app);
const col = collection(db, 'salas', sala, 'pedidos');
const ejemplos = [
  ['Ana', 'Cantante', 'Más voz', false],
  ['Luis', 'Guitarrista', 'Menos retorno', false],
  ['Caro', 'Tecladista', 'Hay acople', true],
  ['Marcos', 'Baterista', 'Más click', false],
];
for (const [nombre, rol, pedido, urgente] of ejemplos) {
  await addDoc(col, { sala_id: sala, nombre, rol, pedido, atendido: false, urgente, respuesta: '', createdAt: serverTimestamp() });
}
console.log('enviados', ejemplos.length);
try { await deleteUser(auth.currentUser); } catch {}
await terminate(db); await deleteApp(app);
process.exit(0);
