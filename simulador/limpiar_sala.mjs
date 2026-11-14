// Borra los pedidos, el setlist y las secuencias de una sala de PRUEBA.
// Uso: SALA=XXXXXXXX node limpiar_sala.mjs
import { initializeApp, deleteApp } from 'firebase/app';
import { getAuth, signInAnonymously, deleteUser } from 'firebase/auth';
import { collection, deleteDoc, getDocs, getFirestore, terminate } from 'firebase/firestore';

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
const app = initializeApp(config, 'limpiador');
const auth = getAuth(app);
await signInAnonymously(auth);
const db = getFirestore(app);
const borrados = {};
for (const sub of ['pedidos', 'setlist', 'secuencias']) {
  const todos = await getDocs(collection(db, 'salas', sala, sub));
  await Promise.all(todos.docs.map((d) => deleteDoc(d.ref).catch(() => {})));
  borrados[sub] = todos.size;
}
console.log(JSON.stringify({ sala, borrados }));
try { await deleteUser(auth.currentUser); } catch {}
await terminate(db); await deleteApp(app);
process.exit(0);
