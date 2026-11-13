# Servidor de archivos (Cloudflare Worker + R2 + D1)

Parte de `PLAN_COSTOS.md` (Fases 3 y 4). La app sube, borra y baja PDF y secuencias por acá en vez de hablar directo con Supabase. Ventajas:
- **Descargar desde R2 no cuesta ancho de banda.**
- Las claves de Cloudflare no viven en la app.
- Los **topes de tamaño y de espacio por cuenta** los aplica el servidor (los de la app se pueden saltear).
- **De cada archivo idéntico se guarda una sola copia** (identificado por su huella SHA-256), sin que la gente vea nada distinto. Cada cuenta sigue viendo "su" canción.

Estado (13-nov-2026): **desplegado** en `https://sound-check-pro-archivos.sound-check-pro-archivos.workers.dev` (bucket R2 y base D1 `sound-check-pro-archivos` creados; `schema.sql` cargado). Probado con una subida real desde el celular (AAC de 5,3 MB), descarga con `Range`, caché de un año y borrado (R2 y D1 vuelven a 0). Mientras la app no se compile con `R2_WORKER_URL`, sigue usando Supabase como siempre.

## Cómo funciona
- Las copias viven en R2 con la clave `blob/{huella}`. La **huella la calcula el servidor** al recibir el archivo: nadie puede declarar una huella que no es.
- La base D1 (`schema.sql`) anota qué cuentas usan cada copia (`enlaces`). La copia se borra recién cuando ya no la usa ninguna cuenta.
- **Subir sin volver a subir:** antes de subir, la app calcula la huella y pide `POST /vincular/iniciar`. Si esa copia ya existe, el servidor pide la huella de 4 trozos al azar del archivo; solo quien tiene el archivo puede responder. Con la prueba correcta (`/vincular/confirmar`) se enlaza la cuenta a la copia existente, sin subir nada. Si la copia no existe (404) o algo falla, la app sube el archivo normalmente.
- Cada cuenta paga en su cuota el tamaño completo de sus archivos, aunque comparta la copia con otras.
- Las lecturas son públicas (`/b/{huella}` y la ruta de la cuenta), como el bucket público de antes, con `Range` para adelantar un audio y caché de un año.

## Qué hace
| Método | Ruta | Quién | Reglas |
|---|---|---|---|
| `GET`/`HEAD` | `/b/{huella}` o `/o/usuarios/{uid}/{canciones\|secuencias}/{archivo}` | cualquiera | Sirve con `Range` y caché de un año (`immutable`) |
| `PUT` | `/o/usuarios/{uid}/{canciones\|secuencias}/{archivo}` | la cuenta dueña (token de Firebase, **no invitados**) | PDF ≤ 5 MB (debe empezar con `%PDF-`) en `canciones`; audio ≤ 30 MB en `secuencias`; **500 MB por cuenta**. Responde `{url, sha256, bytes, deduplicado}` |
| `DELETE` | igual | la cuenta dueña | Quita su enlace; idempotente (204) |
| `POST` | `/vincular/iniciar` y `/vincular/confirmar` | la cuenta dueña | Enlaza una copia que ya existe con una prueba de posesión de un solo uso (vence a los 2 minutos) |

Respuestas de error que entiende la app: `413` (archivo grande, con `x-bytes` y `x-maximo`), `507` (sin espacio, con `x-usado` y `x-cuota`), `401` (token), `403` (carpeta ajena, invitado o prueba incorrecta), `415` (tipo no permitido), `404` (la copia no existe).

Los topes están en `src/index.js` (`CARPETAS`, `CUOTA_BYTES`) y **deben coincidir** con `kMaxBytesPdf`, `kMaxBytesAudio` y `kCuotaBytesPorUsuario` de `frontend/lib/main.dart`.

## Probar (sin cuenta de Cloudflare)
```bash
cd worker
node --test
```
Usa un R2 de mentira, una base SQLite en memoria con el mismo `schema.sql` y claves RSA generadas en la prueba. No hace falta instalar nada (Node 22 o más nuevo).

## Desplegar 🔑 (lo tenés que hacer vos)
1. Cuenta en Cloudflare y **R2 activado** (el plan gratis incluye 10 GB y no cobra descargas; pide medio de pago para activarlo).
2. Panel → **R2 → Crear bucket** con el nombre `sound-check-pro-archivos` (o cambialo en `wrangler.toml`).
3. Panel → **Storage y bases de datos → D1 → Crear base** con el nombre `sound-check-pro-archivos`. En su consola SQL pegá el contenido de `schema.sql` y ejecutalo. Copiá el **id de la base** a `wrangler.toml` (`database_id`).
4. Subir el servidor: `npx wrangler login` y `npx wrangler deploy` en esta carpeta, o crear el Worker en el panel pegando `src/index.js` y enlazando el bucket (`BUCKET`) y la base (`DB`) más las variables de `wrangler.toml`. Te da una dirección tipo `https://sound-check-pro-archivos.TU-USUARIO.workers.dev`.
5. En `wrangler.toml` revisá `FIREBASE_PROJECT_ID` y `ORIGENES_PERMITIDOS` (los sitios desde donde se sube: la web publicada y `localhost`).
6. Compilá la app con la dirección del paso 4:
   - Web: agregar `--dart-define=R2_WORKER_URL=https://...` al `flutter build web` de `.github/workflows/deploy.yml`.
   - Android: `flutter build apk --release --dart-define=R2_WORKER_URL=https://...`
7. Los archivos nuevos van a R2 (`storageProvider: 'cloudflare_r2'`). Los viejos siguen en Supabase y se abren igual; migrarlos es opcional (no se unifican con los nuevos).

## Pendiente
- Un límite de pedidos por minuto (hoy solo lo frena el tope de espacio por cuenta). Cloudflare ofrece reglas de límite de tasa en el panel.
- Dominio propio para el servidor (en vez de `workers.dev`) y, a escala, servir las lecturas directo desde R2 con caché.
- Migrar a R2 los archivos que ya están en Supabase.
- Un trabajo que limpie copias huérfanas por si una carrera entre un borrado y una subida dejó una sin enlaces (hoy solo hay un chequeo al subir).
