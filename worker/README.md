# Servidor de archivos (Cloudflare Worker + R2)

Parte de `PLAN_COSTOS.md` (Fase 3). La app sube, borra y baja PDF y secuencias por acá en vez de hablar directo con Supabase. Ventajas: **descargar desde R2 no cuesta ancho de banda**, las claves de Cloudflare no viven en la app y los **topes de tamaño y de espacio por cuenta** los aplica el servidor (los de la app se pueden saltear).

Estado (11-nov-2026): código y pruebas listos; **todavía no está desplegado**. Mientras la app no tenga `R2_WORKER_URL`, sigue usando Supabase como siempre.

## Qué hace
| Método | Ruta | Quién | Reglas |
|---|---|---|---|
| `GET`/`HEAD` | `/o/usuarios/{uid}/{canciones\|secuencias}/{archivo}` | cualquiera | Sirve con `Range` (para adelantar un audio) y caché de un año (`immutable`) |
| `PUT` | igual | la cuenta dueña de `{uid}` (token de Firebase, **no invitados**) | PDF ≤ 5 MB (debe empezar con `%PDF-`) en `canciones`; audio ≤ 30 MB en `secuencias`; **500 MB por cuenta** en total |
| `DELETE` | igual | la cuenta dueña | Idempotente (borrar algo que no existe devuelve 204) |

Respuestas de error que entiende la app: `413` (archivo grande, con `x-bytes` y `x-maximo`), `507` (sin espacio, con `x-usado` y `x-cuota`), `401` (token), `403` (carpeta ajena o invitado), `415` (tipo no permitido).

Los topes están en `src/index.js` (`CARPETAS`, `CUOTA_BYTES`) y **deben coincidir** con `kMaxBytesPdf`, `kMaxBytesAudio` y `kCuotaBytesPorUsuario` de `frontend/lib/main.dart`.

## Probar (sin cuenta de Cloudflare)
```bash
cd worker
node --test
```
Usa un R2 de mentira y claves RSA generadas en la prueba. No hace falta instalar nada.

## Desplegar 🔑 (lo tenés que hacer vos)
1. Cuenta en Cloudflare (el plan gratis incluye 10 GB de R2 y no cobra descargas; pide una tarjeta para activar R2).
2. Panel → **R2 → Crear bucket** con el nombre `sound-check-pro-archivos` (o cambialo en `wrangler.toml`).
3. En esta carpeta: `npx wrangler login` y `npx wrangler deploy`. Te da una dirección tipo `https://sound-check-pro-archivos.TU-USUARIO.workers.dev`.
4. En `wrangler.toml` revisá `FIREBASE_PROJECT_ID` y `ORIGENES_PERMITIDOS` (los sitios desde donde se sube: la web publicada y `localhost`).
5. Compilá la app con la dirección del paso 3:
   - Web: agregar `--dart-define=R2_WORKER_URL=https://...` al `flutter build web` de `.github/workflows/deploy.yml`.
   - Android: `flutter build apk --release --dart-define=R2_WORKER_URL=https://...`
6. Los archivos nuevos van a R2 (`storageProvider: 'cloudflare_r2'`). Los viejos siguen en Supabase y se abren igual; migrarlos es opcional.

## Pendiente
- Un límite de pedidos por minuto (hoy solo lo frena el tope de espacio por cuenta). Cloudflare ofrece reglas de límite de tasa en el panel.
- Dominio propio para el servidor (en vez de `workers.dev`).
- Migrar a R2 los archivos que ya están en Supabase.
