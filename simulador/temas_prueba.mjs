// Crea o cambia temas de PRUEBA en el setlist de una sala (para probar notas de sonido).
// Uso: SALA=XXXXXXXX node temas_prueba.mjs crear | tocar <n>
import { initializeApp, deleteApp } from 'firebase/app';
import { getAuth, signInAnonymously, deleteUser } from 'firebase/auth';
import { addDoc, collection, doc, getDocs, getFirestore, orderBy, query, serverTimestamp, terminate, updateDoc } from 'firebase/firestore';

const config = {
  apiKey: 'AIzaSyBmIF6Eq5Av-fgDSLIlEdRvAoWdKqth-rM',
  authDomain: 'appbandasonido.firebaseapp.com',
  projectId: 'appbandasonido',
  storageBucket: 'appbandasonido.firebasestorage.app',
  messagingSenderId: '784903375488',
  appId: '1:784903375488:web:6db920dbfb9ebbc6eef465',
};
const sala = process.env.SALA;
const [cmd, n] = process.argv.slice(2);
if (!sala || !cmd) { console.error('Uso: SALA=XXXXXXXX node temas_prueba.mjs crear | tocar <n>'); process.exit(1); }
const app = initializeApp(config, 'temas');
const auth = getAuth(app);
await signInAnonymously(auth);
const db = getFirestore(app);
const col = collection(db, 'salas', sala, 'setlist');
if (cmd === 'crear') {
  const temas = [['Tema A', ''], ['Tema B', 'Subir la guitarra en el solo'], ['Tema C', 'Delay en la voz en el estribillo']];
  for (const [i, [titulo, nota]] of temas.entries()) {
    await addDoc(col, { titulo, pdfUrl: '', subidoPor: 'Prueba', orden: i, cifradoTexto: '', completado: false, createdAt: serverTimestamp(), ...(nota ? { notaSonido: nota } : {}) });
  }
  console.log('creados', temas.length);
} else if (cmd === 'tocar') {
  const snap = await getDocs(query(col, orderBy('orden')));
  const d = snap.docs[Number(n)];
  await updateDoc(d.ref, { estado: 'tocado', completado: true });
  console.log('tocado', d.data().titulo);
}
try { await deleteUser(auth.currentUser); } catch {}
await terminate(db); await deleteApp(app);
process.exit(0);
