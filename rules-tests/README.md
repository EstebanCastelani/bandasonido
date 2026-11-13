# Pruebas de las reglas de Firestore

Prueban `../firestore.rules` (las reglas publicadas) y `../firestore.rules.propuesta` (con validación de los pedidos, **todavía sin publicar**) contra el emulador de Firestore. No tocan la base real ni necesitan cuenta de Firebase: el proyecto es `demo-soundcheck`.

## Cómo correrlas

Hace falta Node, Java y `firebase-tools` (`npm i -g firebase-tools`). La primera vez el comando baja el emulador (≈ 60 MB).

```bash
cd rules-tests
npm install
npm test
```

Son 51 pruebas (~5 s): la misma batería de acceso para las dos reglas (sala, presencia, perfil, repertorio, colecciones cerradas, "Deshacer" un pedido) más un bloque propio de cada una: las reglas actuales documentan lo que **hoy no se limita** (pedido de 5000 caracteres, campos de más, cambiar el texto de un pedido) y la propuesta comprueba que sí se rechaza.

## Qué hace la propuesta

Solo cambia el bloque `salas/{salaId}/pedidos/{pedidoId}`:

- **Crear**: solo los campos que escribe la app (`sala_id`, `nombre`, `rol`, `pedido`, `atendido`, `urgente`, `respuesta`, `createdAt` y `visto`, que entra porque "Deshacer" vuelve a crear el pedido completo); `nombre`, `rol` y `pedido` obligatorios y de tipo texto; `pedido` de 1 a 300 caracteres; `nombre` y `rol` de hasta 100; `respuesta` de hasta 1000.
- **Actualizar**: solo `atendido`, `respuesta` y `visto`; no se puede cambiar el texto ni el autor del pedido.
- Leer y borrar quedan igual (hace falta sesión).

> La propuesta que estaba en `OPERACION.md` §6 tenía la lista de campos sin `visto` y habría roto "Deshacer" en un pedido ya visto por el sonidista. Estas pruebas lo atraparon antes de publicar nada.

## Antes de publicar la propuesta

1. En la app, el pedido escrito a mano ya se limita a 200 caracteres, pero **la respuesta del sonidista, el nombre y el rol no tienen tope en la pantalla**: con la propuesta publicada, una respuesta de más de 1000 caracteres o un nombre de más de 100 daría "sin permiso". Hay que ponerles el mismo tope en la app (`maxLength`) antes de publicar.
2. Publicar es decisión del dueño: copiar `firestore.rules.propuesta` sobre `firestore.rules` y `firebase deploy --only firestore:rules` (ver `OPERACION.md` §6). Para volver atrás, restaurar `firestore.rules` desde Git y publicar de nuevo.
3. Las reglas de `storage.rules` no se prueban acá.
