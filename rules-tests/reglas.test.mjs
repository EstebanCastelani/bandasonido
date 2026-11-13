// Pruebas de las reglas de Firestore con el emulador (ver README.md).
//
// Corren dos veces la misma batería de acceso: contra `firestore.rules` (las
// reglas publicadas) y contra `firestore.rules.propuesta` (con validación de la
// forma y el tamaño de los pedidos, todavía sin publicar). Las pruebas que
// solo valen para una de las dos están en su propio bloque.
import { after, before, describe, it } from 'node:test';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  setDoc,
  serverTimestamp,
  updateDoc,
} from 'firebase/firestore';

const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');
const SALA = 'ABCD2345';

/** Un pedido como lo crea la app (`PedidosService.enviarPedido`). */
const pedidoValido = (cambios = {}) => ({
  sala_id: SALA,
  nombre: 'Ana',
  rol: 'Vocalista',
  pedido: 'Más voz en mi retorno',
  atendido: false,
  urgente: false,
  respuesta: '',
  createdAt: serverTimestamp(),
  ...cambios,
});

const sesion = {
  anonima: ['anon1', { firebase: { sign_in_provider: 'anonymous' } }],
  real: ['u1', { firebase: { sign_in_provider: 'password' } }],
  otra: ['u2', { firebase: { sign_in_provider: 'password' } }],
};

function personas(entorno) {
  return {
    anonimo: entorno.authenticatedContext(...sesion.anonima).firestore(),
    usuario: entorno.authenticatedContext(...sesion.real).firestore(),
    otro: entorno.authenticatedContext(...sesion.otra).firestore(),
    sinSesion: entorno.unauthenticatedContext().firestore(),
  };
}

/** Crea un documento saltando las reglas (para preparar la prueba). */
async function sembrar(entorno, ruta, datos) {
  await entorno.withSecurityRulesDisabled(async (contexto) => {
    await setDoc(doc(contexto.firestore(), ruta), datos);
  });
}

const juegos = [
  { nombre: 'reglas publicadas (firestore.rules)', archivo: 'firestore.rules', proyecto: 'demo-actual', propuesta: false },
  { nombre: 'propuesta (firestore.rules.propuesta)', archivo: 'firestore.rules.propuesta', proyecto: 'demo-propuesta', propuesta: true },
];

for (const juego of juegos) {
  describe(juego.nombre, () => {
    let entorno;
    let p;

    before(async () => {
      entorno = await initializeTestEnvironment({
        projectId: juego.proyecto,
        firestore: { rules: readFileSync(join(raiz, juego.archivo), 'utf8') },
      });
    });
    after(async () => {
      await entorno.cleanup();
    });
    // Cada prueba arranca sin datos.
    const limpiar = async () => {
      await entorno.clearFirestore();
      p = personas(entorno);
    };

    describe('sala: pedidos, setlist y secuencias', () => {
      it('sin sesión no se puede leer ni escribir', async () => {
        await limpiar();
        await assertFails(getDoc(doc(p.sinSesion, `salas/${SALA}/pedidos/x`)));
        await assertFails(setDoc(doc(p.sinSesion, `salas/${SALA}/pedidos/x`), pedidoValido()));
        await assertFails(getDoc(doc(p.sinSesion, `salas/${SALA}/setlist/x`)));
        await assertFails(setDoc(doc(p.sinSesion, `salas/${SALA}/secuencias/x`), { titulo: 'a' }));
      });

      it('un invitado anónimo puede mandar y leer pedidos', async () => {
        await limpiar();
        await assertSucceeds(setDoc(doc(p.anonimo, `salas/${SALA}/pedidos/x`), pedidoValido()));
        await assertSucceeds(getDoc(doc(p.anonimo, `salas/${SALA}/pedidos/x`)));
      });

      it('un invitado anónimo puede usar el setlist y las secuencias de la sala', async () => {
        await limpiar();
        await assertSucceeds(setDoc(doc(p.anonimo, `salas/${SALA}/setlist/t1`), { titulo: 'Tema', orden: 0 }));
        await assertSucceeds(updateDoc(doc(p.anonimo, `salas/${SALA}/setlist/t1`), { estado: 'tocado' }));
        await assertSucceeds(setDoc(doc(p.anonimo, `salas/${SALA}/secuencias/s1`), { titulo: 'Pista' }));
      });

      it('atender, responder y marcar como visto un pedido', async () => {
        await limpiar();
        await sembrar(entorno, `salas/${SALA}/pedidos/x`, { ...pedidoValido(), createdAt: new Date() });
        const ref = doc(p.usuario, `salas/${SALA}/pedidos/x`);
        await assertSucceeds(updateDoc(ref, { visto: true }));
        await assertSucceeds(updateDoc(ref, { respuesta: 'Listo, subí el volumen' }));
        await assertSucceeds(updateDoc(ref, { atendido: true }));
      });

      it('Deshacer: borrar un pedido ya visto y volver a crearlo completo', async () => {
        await limpiar();
        const original = { ...pedidoValido(), createdAt: new Date(), visto: true, respuesta: 'ok' };
        await sembrar(entorno, `salas/${SALA}/pedidos/x`, original);
        const ref = doc(p.usuario, `salas/${SALA}/pedidos/x`);
        const antes = (await assertSucceeds(getDoc(ref))).data();
        await assertSucceeds(deleteDoc(ref));
        await assertSucceeds(setDoc(ref, antes));
      });

      it('borrar un pedido', async () => {
        await limpiar();
        await sembrar(entorno, `salas/${SALA}/pedidos/x`, { ...pedidoValido(), createdAt: new Date() });
        await assertSucceeds(deleteDoc(doc(p.anonimo, `salas/${SALA}/pedidos/x`)));
      });
    });

    describe('miembros de la sala (presencia)', () => {
      it('un usuario real registra su propia presencia', async () => {
        await limpiar();
        await assertSucceeds(setDoc(doc(p.usuario, `salas/${SALA}/miembros/u1`), { nombre: 'Ana' }));
      });
      it('no se puede registrar la presencia de otro', async () => {
        await limpiar();
        await assertFails(setDoc(doc(p.otro, `salas/${SALA}/miembros/u1`), { nombre: 'Ana' }));
      });
      it('un anónimo no puede registrar presencia, pero sí leerla', async () => {
        await limpiar();
        await assertFails(setDoc(doc(p.anonimo, `salas/${SALA}/miembros/anon1`), { nombre: 'X' }));
        await sembrar(entorno, `salas/${SALA}/miembros/u1`, { nombre: 'Ana' });
        await assertSucceeds(getDoc(doc(p.anonimo, `salas/${SALA}/miembros/u1`)));
      });
    });

    describe('perfil de usuario', () => {
      it('solo se lee el propio perfil', async () => {
        await limpiar();
        await sembrar(entorno, 'usuarios/u1', { nombre: 'Ana', esPro: false });
        await assertSucceeds(getDoc(doc(p.usuario, 'usuarios/u1')));
        await assertFails(getDoc(doc(p.otro, 'usuarios/u1')));
        await assertFails(getDoc(doc(p.anonimo, 'usuarios/u1')));
      });
      it('nace con esPro en false: nadie se otorga la versión paga', async () => {
        await limpiar();
        await assertSucceeds(setDoc(doc(p.usuario, 'usuarios/u1'), { nombre: 'Ana', esPro: false }));
        await assertFails(setDoc(doc(p.otro, 'usuarios/u2'), { nombre: 'Beto', esPro: true }));
      });
      it('un anónimo no puede crear perfil', async () => {
        await limpiar();
        await assertFails(setDoc(doc(p.anonimo, 'usuarios/anon1'), { nombre: 'X', esPro: false }));
      });
      it('al actualizar el perfil no se puede cambiar esPro', async () => {
        await limpiar();
        await sembrar(entorno, 'usuarios/u1', { nombre: 'Ana', esPro: false });
        const ref = doc(p.usuario, 'usuarios/u1');
        await assertSucceeds(updateDoc(ref, { nombre: 'Ana María' }));
        await assertFails(updateDoc(ref, { esPro: true }));
      });
      it('el dueño borra su perfil; otro no', async () => {
        await limpiar();
        await sembrar(entorno, 'usuarios/u1', { nombre: 'Ana', esPro: false });
        await assertFails(deleteDoc(doc(p.otro, 'usuarios/u1')));
        await assertSucceeds(deleteDoc(doc(p.usuario, 'usuarios/u1')));
      });
    });

    describe('datos del usuario (frases, repertorio, secuencias, salas)', () => {
      for (const coleccion of ['frases', 'mis_secuencias', 'mis_salas']) {
        it(`${coleccion}: solo el dueño con cuenta real`, async () => {
          await limpiar();
          await sembrar(entorno, `usuarios/u1/${coleccion}/a`, { texto: 'x' });
          await assertSucceeds(getDoc(doc(p.usuario, `usuarios/u1/${coleccion}/a`)));
          await assertSucceeds(setDoc(doc(p.usuario, `usuarios/u1/${coleccion}/b`), { texto: 'y' }));
          await assertFails(getDoc(doc(p.otro, `usuarios/u1/${coleccion}/a`)));
          await assertFails(setDoc(doc(p.otro, `usuarios/u1/${coleccion}/c`), { texto: 'z' }));
          await assertFails(getDoc(doc(p.anonimo, `usuarios/u1/${coleccion}/a`)));
        });
      }

      it('mi_repertorio: lo lee cualquier sesión, lo escribe solo el dueño real', async () => {
        await limpiar();
        await sembrar(entorno, 'usuarios/u1/mi_repertorio/c1', { titulo: 'Tema' });
        await assertSucceeds(getDoc(doc(p.anonimo, 'usuarios/u1/mi_repertorio/c1')));
        await assertSucceeds(getDoc(doc(p.otro, 'usuarios/u1/mi_repertorio/c1')));
        await assertFails(getDoc(doc(p.sinSesion, 'usuarios/u1/mi_repertorio/c1')));
        await assertSucceeds(setDoc(doc(p.usuario, 'usuarios/u1/mi_repertorio/c2'), { titulo: 'Otro' }));
        await assertFails(setDoc(doc(p.otro, 'usuarios/u1/mi_repertorio/c3'), { titulo: 'Ajeno' }));
        await assertFails(setDoc(doc(p.anonimo, 'usuarios/u1/mi_repertorio/c4'), { titulo: 'Anon' }));
      });
    });

    describe('Pro gratis por mail y administradores', () => {
      const conMail = (mail, verificado = true, uid = 'u1') =>
        entorno
          .authenticatedContext(uid, {
            email: mail,
            email_verified: verificado,
            firebase: { sign_in_provider: 'google.com' },
          })
          .firestore();
      const admin = () => conMail('dueno@mail.com', true, 'adm1');

      async function conAdmin() {
        await limpiar();
        await sembrar(entorno, 'admins/adm1', { creado: true });
        await sembrar(entorno, 'pro_gratis/ana@mail.com', { email: 'ana@mail.com' });
      }

      it('el administrador agrega, lista y quita mails', async () => {
        await conAdmin();
        await assertSucceeds(setDoc(doc(admin(), 'pro_gratis/beto@mail.com'), { email: 'beto@mail.com' }));
        await assertSucceeds(getDocs(collection(admin(), 'pro_gratis')));
        await assertSucceeds(deleteDoc(doc(admin(), 'pro_gratis/beto@mail.com')));
      });
      it('una persona lee solo el documento de su propio mail', async () => {
        await conAdmin();
        await assertSucceeds(getDoc(doc(conMail('Ana@Mail.com'), 'pro_gratis/ana@mail.com')));

        await assertFails(getDoc(doc(conMail('otra@mail.com', true, 'u9'), 'pro_gratis/ana@mail.com')));
      });
      it('con el mail sin verificar no se lee ni el propio', async () => {
        await conAdmin();
        await assertFails(getDoc(doc(conMail('ana@mail.com', false), 'pro_gratis/ana@mail.com')));
      });
      it('nadie que no sea administrador lista ni escribe', async () => {
        await conAdmin();
        const ana = conMail('ana@mail.com');
        await assertFails(getDocs(collection(ana, 'pro_gratis')));
        await assertFails(setDoc(doc(ana, 'pro_gratis/ana2@mail.com'), { email: 'x' }));
        await assertFails(deleteDoc(doc(ana, 'pro_gratis/ana@mail.com')));
        await assertFails(getDoc(doc(p.anonimo, 'pro_gratis/ana@mail.com')));
        await assertFails(getDoc(doc(p.sinSesion, 'pro_gratis/ana@mail.com')));
      });
      it('admins: cada cuenta ve solo su propio documento y nadie escribe', async () => {
        await conAdmin();
        await assertSucceeds(getDoc(doc(admin(), 'admins/adm1')));
        await assertFails(getDoc(doc(conMail('ana@mail.com'), 'admins/adm1')));
        await assertFails(setDoc(doc(conMail('ana@mail.com'), 'admins/u1'), { creado: true }));
        await assertFails(setDoc(doc(admin(), 'admins/adm2'), { creado: true }));
        await assertFails(getDocs(collection(admin(), 'admins')));
      });
    });

    describe('tono: solo con Pro', () => {
      const ctx = (uid, extra = {}, proveedor = 'google.com') =>
        entorno
          .authenticatedContext(uid, { firebase: { sign_in_provider: proveedor }, ...extra })
          .firestore();
      const gratis = () => ctx('free1', { email: 'gratis@mail.com', email_verified: true });
      const proPerfil = () => ctx('pro1', { email: 'pro@mail.com', email_verified: true });
      const proLista = () => ctx('pro2', { email: 'Lista@Mail.com', email_verified: true });
      const proListaSinVerificar = () => ctx('pro3', { email: 'lista@mail.com', email_verified: false });
      const setlist = `salas/${SALA}/setlist/t1`;
      const secuencia = `salas/${SALA}/secuencias/s1`;

      async function preparar() {
        await limpiar();
        await sembrar(entorno, 'usuarios/pro1', { esPro: true, nombre: 'Pro' });
        await sembrar(entorno, 'usuarios/free1', { esPro: false, nombre: 'Gratis' });
        await sembrar(entorno, 'pro_gratis/lista@mail.com', { email: 'lista@mail.com' });
        await sembrar(entorno, setlist, { titulo: 'Tema', orden: 0, transposicion: 0, estado: 'pendiente' });
        await sembrar(entorno, secuencia, { titulo: 'Pista', semitonos: 0, tempoPorcentaje: 100, volumenPorcentaje: 100 });
      }

      it('con Pro (perfil o lista) se cambia el tono del cifrado', async () => {
        await preparar();
        await assertSucceeds(updateDoc(doc(proPerfil(), setlist), { transposicion: 2 }));
        await assertSucceeds(updateDoc(doc(proLista(), setlist), { transposicion: -1 }));
      });
      it('sin Pro, con perfil gratis, anónimo o mail sin verificar, no se cambia', async () => {
        await preparar();
        await assertFails(updateDoc(doc(gratis(), setlist), { transposicion: 2 }));
        await assertFails(updateDoc(doc(p.anonimo, setlist), { transposicion: 2 }));
        await assertFails(updateDoc(doc(proListaSinVerificar(), setlist), { transposicion: 2 }));
        await assertFails(updateDoc(doc(ctx('sinperfil', { email: 'x@mail.com', email_verified: true }), setlist), { transposicion: 2 }));
      });
      it('un gratuito sí cambia lo demás del setlist y puede escribir 0 al crear', async () => {
        await preparar();
        await assertSucceeds(updateDoc(doc(gratis(), setlist), { estado: 'tocado' }));
        await assertSucceeds(setDoc(doc(gratis(), `salas/${SALA}/setlist/t2`), { titulo: 'Otro', orden: 1 }));
        await assertSucceeds(setDoc(doc(gratis(), `salas/${SALA}/setlist/t3`), { titulo: 'Otro', orden: 2, transposicion: 0 }));
      });
      it('crear un tema ya transpuesto también pide Pro', async () => {
        await preparar();
        await assertFails(setDoc(doc(gratis(), `salas/${SALA}/setlist/t4`), { titulo: 'X', orden: 3, transposicion: 3 }));
        await assertSucceeds(setDoc(doc(proPerfil(), `salas/${SALA}/setlist/t4`), { titulo: 'X', orden: 3, transposicion: 3 }));
      });
      it('secuencias: el tono pide Pro, el tempo y el volumen no', async () => {
        await preparar();
        await assertFails(updateDoc(doc(gratis(), secuencia), { semitonos: 2, tempoPorcentaje: 100, volumenPorcentaje: 100 }));
        // La app manda siempre los tres campos: con el tono igual, no cuenta como cambio de tono.
        await assertSucceeds(updateDoc(doc(gratis(), secuencia), { semitonos: 0, tempoPorcentaje: 120, volumenPorcentaje: 80 }));
        await assertSucceeds(updateDoc(doc(proPerfil(), secuencia), { semitonos: 2, tempoPorcentaje: 100, volumenPorcentaje: 100 }));
      });
      it('quien no tiene Pro puede borrar temas y leer como siempre', async () => {
        await preparar();
        await assertSucceeds(getDoc(doc(gratis(), setlist)));
        await assertSucceeds(deleteDoc(doc(gratis(), setlist)));
      });
    });

    describe('lo que no está listado', () => {
      it('cualquier otra colección está cerrada', async () => {
        await limpiar();
        await assertFails(getDoc(doc(p.usuario, 'cualquiera/a')));
        await assertFails(setDoc(doc(p.usuario, 'cualquiera/a'), { x: 1 }));
        await assertFails(setDoc(doc(p.usuario, `salas/${SALA}`), { x: 1 }));
      });
    });

    if (!juego.propuesta) {
      describe('límites que hoy NO existen (por eso la propuesta)', () => {
        it('acepta un pedido de 5000 caracteres', async () => {
          await limpiar();
          await assertSucceeds(
            setDoc(doc(p.anonimo, `salas/${SALA}/pedidos/x`), pedidoValido({ pedido: 'a'.repeat(5000) })),
          );
        });
        it('acepta campos que la app no usa', async () => {
          await limpiar();
          await assertSucceeds(
            setDoc(doc(p.anonimo, `salas/${SALA}/pedidos/x`), pedidoValido({ basura: 'x'.repeat(100) })),
          );
        });
        it('permite cambiar el texto de un pedido ya mandado', async () => {
          await limpiar();
          await sembrar(entorno, `salas/${SALA}/pedidos/x`, { ...pedidoValido(), createdAt: new Date() });
          await assertSucceeds(updateDoc(doc(p.anonimo, `salas/${SALA}/pedidos/x`), { pedido: 'otro texto' }));
        });
      });
    } else {
      describe('validación de pedidos (propuesta)', () => {
        const ruta = `salas/${SALA}/pedidos/x`;

        it('acepta el pedido que manda la app, con y sin urgencia', async () => {
          await limpiar();
          await assertSucceeds(setDoc(doc(p.anonimo, ruta), pedidoValido()));
          await assertSucceeds(setDoc(doc(p.anonimo, `${ruta}2`), pedidoValido({ urgente: true })));
        });
        it('acepta el pedido escrito a mano de 200 caracteres', async () => {
          await limpiar();
          await assertSucceeds(setDoc(doc(p.anonimo, ruta), pedidoValido({ pedido: 'a'.repeat(200) })));
        });
        it('rechaza un pedido vacío o de más de 300 caracteres', async () => {
          await limpiar();
          await assertFails(setDoc(doc(p.anonimo, ruta), pedidoValido({ pedido: '' })));
          await assertFails(setDoc(doc(p.anonimo, ruta), pedidoValido({ pedido: 'a'.repeat(301) })));
        });
        it('rechaza campos que la app no usa', async () => {
          await limpiar();
          await assertFails(setDoc(doc(p.anonimo, ruta), pedidoValido({ basura: 'x' })));
        });
        it('rechaza tipos equivocados', async () => {
          await limpiar();
          await assertFails(setDoc(doc(p.anonimo, ruta), pedidoValido({ pedido: 123 })));
          await assertFails(setDoc(doc(p.anonimo, ruta), pedidoValido({ urgente: 'si' })));
          await assertFails(setDoc(doc(p.anonimo, ruta), pedidoValido({ nombre: ['Ana'] })));
        });
        it('rechaza nombre o rol demasiado largos', async () => {
          await limpiar();
          await assertFails(setDoc(doc(p.anonimo, ruta), pedidoValido({ nombre: 'a'.repeat(101) })));
          await assertFails(setDoc(doc(p.anonimo, ruta), pedidoValido({ rol: 'a'.repeat(101) })));
        });
        it('exige nombre, rol y pedido', async () => {
          await limpiar();
          const sinNombre = pedidoValido();
          delete sinNombre.nombre;
          await assertFails(setDoc(doc(p.anonimo, ruta), sinNombre));
        });
        it('no deja cambiar el texto ni el autor de un pedido', async () => {
          await limpiar();
          await sembrar(entorno, ruta, { ...pedidoValido(), createdAt: new Date() });
          const ref = doc(p.anonimo, ruta);
          await assertFails(updateDoc(ref, { pedido: 'otro texto' }));
          await assertFails(updateDoc(ref, { nombre: 'Otro' }));
          await assertFails(updateDoc(ref, { basura: 1 }));
        });
        it('limita la respuesta a 1000 caracteres', async () => {
          await limpiar();
          await sembrar(entorno, ruta, { ...pedidoValido(), createdAt: new Date() });
          const ref = doc(p.usuario, ruta);
          await assertSucceeds(updateDoc(ref, { respuesta: 'a'.repeat(1000) }));
          await assertFails(updateDoc(ref, { respuesta: 'a'.repeat(1001) }));
        });
        it('sigue exigiendo sesión', async () => {
          await limpiar();
          await assertFails(setDoc(doc(p.sinSesion, ruta), pedidoValido()));
        });
      });
    }
  });
}
