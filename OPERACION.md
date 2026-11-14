# Operación de Sound Check Pro

Guía para publicar, volver atrás, entender de qué depende la app y qué hacer si algo se cae. Surge de `AUDITORIA_CALIDAD_ESTANDARES.md` (atributos de desplegabilidad, disponibilidad y seguridad). Marca 🔑 lo que **solo puede hacer el dueño** (cuentas, claves, planes).

## 1. Publicar una versión (web)

1. Subir el número en `frontend/pubspec.yaml` (`version: X.Y.Z+N`) **y** en `kVersionApp` de `frontend/lib/main.dart` (una prueba falla si no coinciden); anotar los cambios en `CHANGELOG.md`.
2. Unir el cambio a `main` (idealmente con un *pull request*, ver `PROCESO.md`). Al hacer *push*, GitHub Actions ejecuta `Check formatting` → `Analyze` → `Test` → `Build web` → `Deploy`. **Si alguno falla no se publica nada.**
3. Cuando el despliegue termina en verde, etiquetar la versión publicada:
   ```bash
   git tag -a vX.Y.Z -m "Versión X.Y.Z"
   git push origin vX.Y.Z
   ```
4. Verificar en https://estebancastelani.github.io/bandasonido/ (recargar con Ctrl+F5) y en Configuración que figure la versión nueva.
5. **Web en Cloudflare** (la dirección que usan los enlaces y el QR de invitación, `kUrlWeb`; no se publica sola): `cd frontend && flutter build web --release --dart-define=R2_WORKER_URL=https://sound-check-pro-archivos.sound-check-pro-archivos.workers.dev` y después `cd web-hosting && npx wrangler deploy`. Dirección: https://sound-check-pro-web.sound-check-pro-archivos.workers.dev (debe estar en los dominios autorizados de Firebase y en `ORIGENES_PERMITIDOS` del Worker).

## 2. Volver a una versión anterior (rollback)

Objetivo: **≤ 15 minutos**. Cada versión publicada tiene un tag `vX.Y.Z`.
1. GitHub → *Actions* → *Test and deploy to GitHub Pages* → *Run workflow*.
2. En **ref** escribir el tag al que se quiere volver (ej. `v1.1.0`) y ejecutar.
3. El flujo prueba, construye y publica ese tag. Verificar la versión en Configuración.
4. Después, corregir el problema en `main` y publicar una versión nueva (no reescribir el historial).

> Nota: este procedimiento está escrito pero **todavía no se ensayó**: probarlo una vez apenas exista el primer tag (ver `BACKLOG.md`). Si la versión anterior no es compatible con datos ya escritos en Firestore, hay que revisar `CHANGELOG.md` antes.

## 3. Android

- El build de Android **no se hace en la CI por defecto**. Existe un trabajo `android` apagado: para activarlo 🔑 crear en GitHub (Settings → Secrets and variables → Actions) el secreto `GOOGLE_SERVICES_JSON` (contenido de `frontend/android/app/google-services.json`, descargable desde la consola de Firebase) y la variable `ANDROID_BUILD=true`. Genera un APK de **depuración** como artefacto.
- Build local: copiar `google-services.json` a `frontend/android/app/` (está en `.gitignore` a propósito) y ejecutar `flutter build apk --debug` desde `frontend/`.
- **Archivos en Cloudflare:** todas las compilaciones (web en `deploy.yml`, Android a mano) llevan `--dart-define=R2_WORKER_URL=https://sound-check-pro-archivos.sound-check-pro-archivos.workers.dev`. Sin esa opción la app sube a Supabase. Para el APK/AAB de publicación agregarla también.
- **Publicar en Play Store:** ver `PLAY_STORE.md`. El build de release ya lee la firma desde `android/key.properties` (ejemplo en `android/key.properties.example`; el archivo y el `.jks` están en `.gitignore`). **Sin `key.properties` el build se firma con la clave de depuración y no sirve para la tienda.** El 25-oct-2026 se verificó que `flutter build apk --release` compila (versión 1.1.0, código 2).
- El manifiesto de Android no declaraba el permiso `INTERNET` (Flutter solo lo agrega en debug/profile): se agregó el 25-oct-2026; sin él una versión de tienda no podía conectarse.

## 4. Dependencias de las que depende la app

| Servicio | Para qué | Se usa desde | Si cae | A verificar 🔑 |
|---|---|---|---|---|
| Firebase (proyecto `appbandasonido`) — Firestore y Auth | Salas, pedidos, setlist, cuentas | SDK en la app | La app no puede enviar ni recibir pedidos; ahora avisa "sin conexión" y los pedidos esperan en cola mientras la app sigue abierta | Plan (Spark/Blaze), cuotas, alertas de presupuesto |
| Supabase (proyecto `aecmjdwfttcomcumcbwh`) — Storage | PDFs de repertorio y audios de secuencias | API HTTP con clave *anon* + reglas RLS | No se abren partituras ni se reproducen secuencias; el resto funciona | Plan y **si pausa el proyecto por inactividad** (suele ocurrir en planes gratuitos), cuotas de almacenamiento y ancho de banda |
| GitHub Pages | Alojar la versión web | Navegador | La web no carga (la app instalada en Android sigue) | — |
| `www.gstatic.com` (CanvasKit y Firebase JS) | Motor gráfico (≈ 7 MB de WebAssembly) y SDK web de Firebase, cargados **al ejecutar** la app | Navegador | La web no arranca | Opcional: servir CanvasKit propio con `flutter build web --no-web-resources-cdn` (más peso en Pages, una dependencia menos) |
| `fonts.gstatic.com` | Tipografías de respaldo (Roboto) | Navegador | Se usa otra tipografía | — |
| `cdnjs.cloudflare.com` | pdf.js (visor de PDF) | Navegador | **Solo** dejan de abrir los PDFs; desde `1.1.0` ya no bloquea el arranque | Opcional: copiar `pdf.min.js` y `pdf.worker.min.js` (2.11.338, licencia Apache-2.0) a `frontend/web/` para no depender del CDN |
| reCAPTCHA / App Check | (pendiente) proteger contra abuso | Navegador | — | Ver §6 |

### Dependencias de Dart (revisión del 24-oct-2026)
`flutter pub outdated`: Firebase está **dos versiones mayores atrás** (`cloud_firestore` 5.6 → 7.1, `firebase_auth` 5.7 → 7.0, `firebase_core` 3.15 → 5.1, `firebase_storage` 12 → 14), `syncfusion_flutter_pdf(viewer)` 28.2 → 35.1, `file_picker` 8 → 13, `google_sign_in` 6 → 7, `share_plus` 10 → 13. **No se actualizaron** (son cambios mayores que pueden romper la app y requieren pruebas en celular); Dependabot (`.github/dependabot.yml`) abre un PR por mes y la CI lo valida. Actualizar de a una dependencia por vez.

## 5. Si algo se cae (runbook)

| Síntoma | Qué mirar primero | Qué hacer |
|---|---|---|
| La web muestra una pantalla en blanco | GitHub → Actions (¿el último despliegue falló?); consola del navegador (F12) | Si fue el último despliegue: *rollback* (§2). Si es `www.gstatic.com`: esperar o ver §4 |
| "Sin conexión" aunque haya internet | Estado de Firebase (status.firebase.google.com) | Esperar; los pedidos quedan en cola mientras la app siga abierta. No cerrar la pestaña |
| Los pedidos no llegan al sonidista | ¿Reglas publicadas? ¿cuota excedida en la consola de Firebase? | Revisar `firestore.rules` y la consola; avisar por otro canal (WhatsApp) mientras tanto |
| No se abren PDFs / audios | Consola del navegador; panel de Supabase (¿proyecto pausado?) | Reactivar el proyecto de Supabase 🔑; si es cdnjs, ver §4 |
| Un cambio recién publicado rompió algo | `CHANGELOG.md` y el último commit | *Rollback* (§2) y abrir un defecto en `DEFECTOS.md` |

Plan B para un show: tener el setlist impreso/PDF y un canal alternativo con el sonidista.

## 6. Seguridad pendiente (requiere decisiones tuyas)

0. **Reglas de Firestore (publicadas el 25-oct-2026)**: `firestore.rules` permite que el dueño con cuenta real borre su propio perfil (para "Eliminar mi cuenta"). Para publicar cambios futuros: desde la raíz del repo, `firebase deploy --only firestore:rules` (usa `firebase.json` y `.firebaserc` de la raíz; proyecto `appbandasonido`). Para volver atrás, restaurar la versión anterior del archivo desde Git y publicar de nuevo.

1. **Activar Firebase App Check** 🔑. Hoy `kAppCheckSiteKeyWeb = null` en `main.dart`, o sea que App Check **no está activo** y cualquiera que conozca un PIN puede enviar pedidos sin pasar por la app. Pasos: crear una clave reCAPTCHA v3 (o Enterprise) para el dominio `estebancastelani.github.io`, registrarla en Firebase → App Check, ponerla en `kAppCheckSiteKeyWeb`, y recién después de comprobar el tráfico en modo *monitor* pasar a *exigir*.
2. **Validar la forma y el tamaño de los pedidos en las reglas.** La app ya limita a 200 caracteres lo que se escribe a mano, pero las reglas todavía aceptan cualquier texto. La propuesta ya está escrita y **probada con el emulador** en `firestore.rules.propuesta` (**NO publicada**; `firestore.rules` no se tocó). Corrige un error de la propuesta anterior de este documento, que habría roto "Deshacer" en un pedido ya visto (faltaba `visto` en la lista de campos). Antes de publicarla hay que ponerle tope en la app a la respuesta del sonidista, al nombre y al rol (hoy no lo tienen y la propuesta los limita a 1000, 100 y 100 caracteres); ver `rules-tests/README.md`.
3. **Pruebas de reglas con el emulador** (Etapa 4 de `AUDITORIA_TESTING.md`): **hechas** (12-nov-2026) en `rules-tests/`, 51 pruebas sobre las reglas publicadas y la propuesta (`cd rules-tests && npm test`). Falta correrlas en la CI.
4. **Unirse solo a salas que existen** (decisión D-03 de `REQUISITOS.md`): requiere reglas nuevas y migrar las salas actuales.
5. Rotar y documentar las claves cuando alguien deje de tener acceso; las claves de Firebase web y Supabase *anon* son públicas por diseño y se protegen con reglas/RLS.

## 7. Medidas de rendimiento (línea base del 24-oct-2026)

Medidas **locales** (build de producción servido desde `localhost`, sin limitar la red, navegador de escritorio). Son el mejor caso posible, no representan un celular con 4G:

| Medida | Valor |
|---|---|
| `main.dart.js` | 5,1 MB (1,48 MB comprimido con gzip) |
| `build/web` completo | 39 MB (casi todo son variantes de CanvasKit que el navegador **no descarga**: baja una sola, ≈ 7 MB, desde `www.gstatic.com`) |
| Recursos propios cargados en el arranque | 10 archivos, ≈ 5,4 MB sin comprimir (más 7 recursos externos: pdf.js, CanvasKit ×2, Firebase JS ×2 y tipografías ×2, que el navegador no deja medir por ser de otro origen) |
| Primer pintado (`first-contentful-paint`) | 728 ms |
| Imagen de bienvenida lista | 841 ms |
| `DOMContentLoaded` / `load` | 22 ms / 430 ms |

Pendiente: repetir con la red del escenario o 4G simulado y con la web publicada (con compresión de Pages), y medir la latencia pedido→panel (meta: p95 ≤ 2 s) y las lecturas de Firestore por sesión.
