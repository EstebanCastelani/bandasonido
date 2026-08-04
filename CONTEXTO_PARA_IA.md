# Contexto para IA — Sound Check Pro / AppSonido

> Leé esto antes de tocar el proyecto. Está escrito para que una IA (o una
> persona) que nunca vio este repo pueda seguir trabajando sin repetir
> decisiones ya tomadas ni redescubrir por qué las cosas están como están.

## 1. Qué es esta app

**Sound Check Pro** (nombre visible en la UI; el repo se llama
`bandasonido`/`AppSonido` por razones históricas) es una app para bandas en
vivo. Objetivo: que un músico o cantante en el escenario pueda pedirle algo
al sonidista ("subime el retorno", "más voz") sin señas, y que el sonidista
vea esos pedidos en tiempo real desde su propio celular/tablet. Se fue
ampliando hacia una herramienta de banda más completa: setlist compartido
del show, biblioteca personal de partituras/cifrados en PDF con
transposición de acordes, y una versión "Pro" pensada para monetizar más
adelante.

**Objetivo final / visión:** app multiplataforma (hoy solo Web desplegada,
pensada para llegar a Android/iOS) que reemplaza la comunicación gestual en
un show por una app simple, rápida de usar con el show en curso (pantalla
siempre encendida, botones grandes, poco texto), con una capa opcional
paga para quien quiera manejar su repertorio de partituras.

## 2. Arquitectura: por qué es como es

**Todo Flutter + Firebase, sin backend propio.** Hubo un backend Spring
Boot + WebSocket + H2 al principio del proyecto (ver el primer commit del
repo) que se **borró por completo** cuando se detectó que el frontend real
nunca lo usaba — la app ya estaba construida directo contra Firebase
Firestore/Auth. No reintroducir un backend salvo que haya una razón de peso
y se documente acá por qué.

**Todo el código Dart vive en un solo archivo:** `frontend/lib/main.dart`
(~4.760 líneas a esta fecha). Es una convención explícita del dueño del
proyecto, no un descuido — no dividir en múltiples archivos sin que te lo
pidan. El archivo está organizado en secciones marcadas con comentarios
`// --- NOMBRE DE SECCIÓN ---`. Mapa actual (los números de línea van a
correrse con cada cambio, pero el orden de secciones se mantiene):

```
CONFIGURACIÓN DE FIREBASE          — FirebaseOptions hardcodeado (ver §4)
CONFIGURACIÓN DE SUPABASE          — Solo Storage, temporal (ver §7.1)
MODELOS Y CONSTANTES               — AppConstants.pedidosRapidos (frases default)
IDENTIDADES DE COLOR (PALETAS)     — AppPalette: 4 temas seleccionables
TRANSPOSICIÓN DE CIFRADOS          — ChordTransposer (lógica pura, sin Flutter)
SERVICIO DE AUTENTICACIÓN          — AuthService (Google/email/anónimo)
SERVICIO DE USUARIOS Y FRASES      — UsuarioService, FrasesService
SERVICIO DE REPERTORIO PERSONAL    — RepertorioService (PDFs en Storage)
SERVICIO DE SETLIST DE SALA        — SetlistService
SERVICIO DE BASE DE DATOS          — FirestoreService (pedidos de sala)
APLICACIÓN PRINCIPAL               — SoundCheckProApp (theme, paleta persistida)
PANTALLA DE CARGA Y REDIRECCIÓN    — SplashScreen (decide a dónde navegar)
PANTALLA DE LOGIN / REGISTRO       — AuthScreen
MENÚ DE INGRESO                    — IngressMenuScreen (home post-login)
SELECTOR DE IDENTIDAD DE COLOR     — PaletaPickerScreen
PANTALLA DE CREACIÓN DE SALA       — CrearSalaScreen
PANTALLA PARA UNIRSE A SALA        — UnirmeSalaScreen
PANTALLA DE PEDIDOS INDIVIDUAL     — RequestScreen (músico/cantante, tabs Pedidos/Setlist)
LISTA DE TEMAS COMPARTIDA          — SetlistTab (widget reusado en RequestScreen y SonidistaPage)
ADMINISTRACIÓN DE FRASES           — FrasesAdminScreen ("Mis frases")
MI REPERTORIO                      — MiRepertorioScreen (biblioteca de PDFs)
VISOR DE CIFRADO                   — CifradoViewerScreen (texto + transposición)
VISOR DE PDF                       — PdfViewerScreen (Syncfusion)
ACCESO SONIDISTA                   — SonidistaPinScreen
PANEL DE CONTROL DEL SONIDISTA     — SonidistaPage (StatefulWidget, tabs Pedidos/Setlist)
```

Para encontrar algo rápido: `grep -n "^// --- "` sobre el archivo te da
este mismo mapa actualizado.

## 3. Modelo de datos (Firestore)

```
usuarios/{uid}                        — perfil de cuenta real (no de invitado anónimo)
  nombre, rol (texto libre), email, esPro (bool), createdAt

usuarios/{uid}/frases/{fraseId}       — frases predefinidas propias del usuario
  texto, orden, createdAt

usuarios/{uid}/mi_repertorio/{id}     — biblioteca personal de partituras
  titulo, tonalidad, pdfUrl, storagePath, storageProvider, cifradoTexto, createdAt
  storageProvider: 'supabase' | 'firebase' (falta en docs viejos → tratar
  como 'firebase'). Ver §7.1 — migración temporal a Supabase Storage.

salas/{codigoSala}/pedidos/{id}       — pedidos en vivo de una sala
  pedido, nombre, rol, atendido, respuesta, createdAt

salas/{codigoSala}/setlist/{id}       — lista de temas del show
  titulo, pdfUrl, cifradoTexto, subidoPor, orden, completado, completadoAt, createdAt
```

`salas/{codigoSala}` en sí **no tiene un documento propio** — el código de
sala es solo un string que actúa como namespace de las subcolecciones. No
hay noción de "quién creó la sala" ni "quién es miembro"; es deliberadamente
simple (ver §6, modelo de seguridad).

**Firebase Storage:** `usuarios/{uid}/canciones/{archivo}.pdf` — los PDFs
de la biblioteca personal. Ver §7, todavía no está aprovisionado.

## 4. Autenticación — los tres niveles

Esto es la parte más fácil de romper si no se entiende bien:

1. **Sin sesión.** No debería pasar en la práctica: cualquier pantalla que
   toca una sala llama `AuthService.asegurarSesion()` antes de leer/escribir.
2. **Anónima.** Se crea sola, sin pedirle nada al usuario, apenas alguien
   crea/se une a una sala o entra como sonidista. Habilita las reglas de
   Firestore que exigen `request.auth != null` en `pedidos`/`setlist` sin
   forzar registro a los invitados. **Un usuario anónimo NO debe poder usar
   frases propias, repertorio personal, ni Pro** — eso se controla con
   `AuthService.esUsuarioRegistrado` (`currentUser != null &&
   !currentUser.isAnonymous`) en la UI, y con
   `request.auth.token.firebase.sign_in_provider != 'anonymous'` en las
   reglas de Firestore/Storage. Si agregás una función nueva que dependa de
   cuenta real, replicá este patrón en ambos lados (UI y reglas) — la UI
   sola no alcanza, cualquiera puede llamar al SDK directo.
3. **Registrada (email/contraseña o Google).** Habilita frases propias,
   repertorio, y es el único tipo de cuenta que puede tener `esPro: true`.

`esPro` **nunca lo puede escribir el propio cliente** — las reglas de
Firestore lo fuerzan a `false` en la creación y prohíben cambiarlo en
`update`. Hoy se activa a mano desde la consola de Firebase. Mientras no
haya cobro real, `kFuncionesProGratisPorAhora = true` (constante en
`main.dart`) libera la función de subir PDFs para cualquier cuenta
registrada sin chequear `esPro` — ver §8 para cómo revertir esto.

## 5. Funcionalidades implementadas (orden cronológico real)

1. Registro/login con email+contraseña y Google, recuperación de
   contraseña, primera pantalla de la app.
2. Frases predefinidas por usuario (antes eran una lista global fija).
3. Biblioteca personal de PDFs (subida vía `file_picker`, Storage + Firestore).
4. Setlist compartido de sala: agregar canciones desde la biblioteca propia
   o buscando en las de todos (`collectionGroup` sobre `mi_repertorio`),
   visor de PDF (Syncfusion), tachar/marcar temas tocados con indicador de
   "próximo tema", todo en tiempo real vía `StreamBuilder`.
5. Extracción best-effort de texto del PDF al subirlo + transposición de
   acordes por semitonos sobre ese texto (`ChordTransposer`), sin tocar el
   PDF original. Soporta formato `[C]texto` (ChordPro) y líneas de acordes
   sueltas.
6. `wakelock_plus`: pantalla siempre encendida mientras se está en una sala
   (activado a nivel de `RequestScreen`/`SonidistaPage`, **no** en las
   pantallas hijas de PDF/cifrado — ver nota de diseño en §9).
7. 4 identidades de color seleccionables (`AppPalette`), persistidas en
   `SharedPreferences`, aplicadas a **todo** el acento de la app vía
   `context.acento` (no queda ningún `Colors.deepPurple` hardcodeado).
8. Auditoría de seguridad + hardening: PIN de sala de 6 dígitos numéricos a
   8 caracteres alfanuméricos, Firebase Auth anónimo obligatorio para tocar
   una sala, reglas de Firestore/Storage versionadas en el repo
   (`firestore.rules`, `storage.rules`).

## 6. Modelo de seguridad de las salas — trade-off consciente, no bug

`salas/{codigoSala}/pedidos` y `.../setlist` se leen/escriben con
**"conocer el código alcanza"** (`request.auth != null && salaId.size() >
0`). No hay concepto de "membresía" real de sala. Esto es intencional: la
banda no quiere que cada invitado tenga que crear una cuenta para un
ensayo. El PIN de 8 caracteres alfanuméricos (~1,1 billón de combinaciones)
+ exigir Firebase Auth (aunque sea anónimo) subieron mucho el costo de un
ataque de fuerza bruta comparado con el PIN numérico de 6 dígitos original,
pero **no es "seguro" en el sentido estricto** — sigue siendo "el código es
la llave". Si en algún momento hace falta cerrar esto del todo, las
opciones evaluadas fueron (de más simple a más robusta): PIN más largo aún
→ exigir vínculo real de membresía por sala → Firebase App Check
(reCAPTCHA web + Play Integrity Android) para bloquear tráfico que no venga
de la app real.

## 7. Estado de Firebase / infraestructura

- **Plan:** Spark (gratis) al momento de escribir esto. El dueño del
  proyecto estaba en proceso de activar **Blaze** (pago por uso) — revisar
  si ya se completó antes de asumir que Storage funciona.
- **Firebase Storage no está aprovisionado todavía** (requiere Blaze desde
  feb-2026). Hasta que se active, la subida de PDFs en `MiRepertorioScreen`
  va a fallar en producción aunque el código esté listo.
- **`storage.rules`** está escrito y versionado en el repo, pero **nunca
  se publicó** en la consola porque Storage no existe todavía. Publicarlo
  apenas se active Blaze (Firebase Console → Storage → Reglas, pegar el
  contenido del archivo).
- **`firestore.rules`** sí está publicado y vigente — el archivo en el repo
  refleja exactamente lo que está en producción a la fecha de este commit.
- Proveedores de Firebase Auth habilitados: Email/contraseña, Google,
  Anónimo (con limpieza automática de cuentas anónimas >30 días activada).
- Dominio autorizado para Auth: `estebancastelani.github.io` (además de los
  default de Firebase).
- La **Web API Key** de Firebase (`main.dart`, sección "Configuración de
  Firebase") está hardcodeada — esto es normal y esperado para apps
  Firebase, no es un secreto (la seguridad real la dan las reglas de
  Firestore/Storage, no ocultar esta key). Pendiente: restringirla por
  dominio (`https://estebancastelani.github.io/*`) en Google Cloud Console
  → Credenciales, para que nadie más pueda consumir la cuota del proyecto
  con ella. No se hizo porque requiere acceso a Google Cloud Console que no
  siempre está disponible en sesión.

### 7.1 Migración temporal de Storage a Supabase (mientras no hay Blaze)

Mientras Firebase Storage no está aprovisionado (bullet de arriba),
`RepertorioService` (sección "SERVICIO DE REPERTORIO PERSONAL" en
`main.dart`) sube los PDFs a **Supabase Storage** en vez de Firebase
Storage. Es un parche deliberadamente acotado: **Firestore y Auth siguen
100% en Firebase**, Supabase solo se usa para guardar archivos.

- **Config del cliente**: sección nueva `// --- CONFIGURACIÓN DE SUPABASE
  ---` en `main.dart`, justo después de la config de Firebase. Constantes
  `kSupabaseUrl`, `kSupabaseAnonKey` (hardcodeada, mismo criterio que la Web
  API Key de Firebase: no es secreta, la seguridad la dan las políticas del
  bucket) y `kSupabaseRepertorioBucket = 'repertorio-pdfs'`. Se inicializa
  en `main()` con `_inicializarSupabase()`, en un `try/catch` separado del
  de Firebase para que un fallo acá no tumbe el resto de la app.
- **Sin sesión de Supabase Auth propia**: se le pasa a `Supabase.initialize`
  un `accessToken: () => FirebaseAuth.instance.currentUser?.getIdToken()`,
  o sea que cada request a Supabase viaja con el ID token de Firebase. Para
  que las políticas RLS puedan usar ese token (identificar al dueño real
  del archivo) hace falta que el proyecto de Supabase tenga **Firebase
  configurado como Third-Party Auth provider** — es un paso de dashboard,
  no de código (Authentication → Sign In / Providers → Third-Party Auth →
  Firebase, Project ID `appbandasonido`).
- **Modelo de acceso que replica `storage.rules`**: bucket **público** para
  lectura (igual que `allow read: if true` — necesario para que un
  invitado sin cuenta pueda ver un PDF que otro músico compartió en el
  setlist de sala) + políticas RLS que restringen `insert`/`delete` a
  `usuarios/{uid}/...` solo si el `uid` del path coincide con
  `auth.jwt()->>'sub'` y el sign-in provider no es `anonymous`.
- **Gotcha real que costó una sesión entera de debug — las políticas NO
  llevan `to authenticated`.** Firebase como Third-Party Auth provider
  verifica la firma del JWT, pero **no** le asigna solo el rol `authenticated`
  de Postgres al request (el propio dashboard de Supabase lo avisa en letra
  chica: *"you'll need to add custom code to set the authenticated role to
  all your present and future users"*). Una política con `to authenticated`
  contra un JWT de Firebase **siempre** rechaza con `403 — new row violates
  row-level security policy`, aunque el token sea válido y los claims
  matcheen perfecto (se verificó con curl, con el JWT real decodificado, y
  con una política de test sin condiciones — las tres pruebas fallaron
  igual mientras existió el `to authenticated`). La solución que quedó
  andando: sacar `to authenticated` de la política (queda aplicable a
  cualquier rol) y dejar que la seguridad la dé pura y exclusivamente el
  `with check`/`using` sobre `auth.jwt()` — si no hay JWT válido,
  `auth.jwt()->>'sub'` da `NULL` y la condición de path nunca matchea, así
  que sigue siendo seguro sin depender del mapeo de rol de Postgres.
- **Campo `storageProvider`** en `usuarios/{uid}/mi_repertorio/{id}`:
  `'supabase'` para lo subido por este parche, `'firebase'` (o el campo
  ausente, en docs viejos) para lo que ya estaba en Firebase Storage.
  `eliminarCancion` lee este campo antes de borrar el archivo, para pegarle
  al backend correcto. Permite convivir con archivos de ambos providers sin
  migrar nada.
- **Estado del lado de Supabase, a la fecha de este commit: configurado y
  probado end-to-end, subida de PDF funcionando.** Bucket `repertorio-pdfs`
  creado (público, límite 25 MB, solo `application/pdf`), Firebase agregado
  como Third-Party Auth provider, y las políticas RLS de `insert`/`delete`
  sobre `storage.objects` corridas — **sin `to authenticated`** (ver el
  gotcha de arriba). El SQL real que quedó aplicado:

  ```sql
  create policy "Subida solo del dueño con cuenta real"
  on storage.objects for insert
  with check (
    bucket_id = 'repertorio-pdfs'
    and (storage.foldername(name))[1] = 'usuarios'
    and (storage.foldername(name))[2] = (auth.jwt()->>'sub')
    and coalesce(auth.jwt() -> 'firebase' ->> 'sign_in_provider', 'anonymous') <> 'anonymous'
  );

  create policy "Borrado solo del dueño"
  on storage.objects for delete
  using (
    bucket_id = 'repertorio-pdfs'
    and (storage.foldername(name))[1] = 'usuarios'
    and (storage.foldername(name))[2] = (auth.jwt()->>'sub')
  );
  ```
- **Para revertir cuando se active Blaze**: el plan fue diseñado para que
  la vuelta atrás sea acotada a `RepertorioService` — cambiar
  `subirCancion` para que vuelva a usar `FirebaseStorage.instance` (como
  antes de este parche) y ajustar el branch de `eliminarCancion`. No hace
  falta migrar los documentos de Firestore ya subidos a Supabase: quedan
  con `storageProvider: 'supabase'` y siguen funcionando (el bucket de
  Supabase no se apaga solo), o se migran aparte si en algún momento se
  quiere consolidar todo en un solo backend.

## 8. Deudas técnicas y pendientes explícitos

**Bloqueantes para "app paga" real:**
- No hay ningún sistema de cobro (Stripe, Play Billing, etc.). `esPro` se
  activa a mano desde la consola de Firebase. Hasta que exista cobro real,
  `kFuncionesProGratisPorAhora = true` en `main.dart` mantiene la función de
  subir PDFs abierta a cualquier cuenta registrada. Para reactivar el gate:
  poner esa constante en `false` y descomentar la condición `esPro == true`
  que ya está dejada comentada en `firestore.rules` y `storage.rules`.

**Bloqueantes para publicar en Play Store:**
- No existe carpeta `android/` (nunca se corrió
  `flutter create --platforms=android .`). Sin eso no hay nada para
  compilar como `.aab`.
- No hay keystore de firma generado ni `key.properties`. El `.gitignore` ya
  tiene las reglas para que esos archivos nunca se suban una vez que
  existan, pero hay que crearlos.
- Comando de build de producción, una vez que exista `android/`:
  `flutter build appbundle --release --obfuscate --split-debug-info=build/symbols`
  (guardar `build/symbols` fuera del repo público — hace falta para leer
  crashes reales).

**Deuda de seguridad conocida (ver §6 para el detalle):**
- El modelo de acceso a salas por PIN sigue siendo fuerza-bruteable en
  teoría, solo que ahora mucho más caro.
- Falta restringir la Web API Key por dominio en Google Cloud Console.
- No hay Firebase App Check.

**Deuda de infraestructura temporal (ver §7.1):**
- El repertorio personal sube PDFs a Supabase Storage en vez de Firebase
  Storage, mientras no se active Blaze. Ya probado end-to-end (subida real
  funcionando) — es deuda a mediano plazo, no un bloqueante activo.
- Cuando se active Blaze, hay que decidir si se revierte `RepertorioService`
  a Firebase Storage (dejando los archivos ya subidos a Supabase donde
  están) o si se migran esos archivos también — no está resuelto todavía,
  es una decisión pendiente.

**Deuda de código:**
- `main.dart` es un archivo único de ~4.760 líneas. Es una decisión
  consciente del dueño del proyecto (ver §2), no lo dividas sin que te lo
  pidan explícitamente.
- Sin tests automatizados. `frontend/test/widget_test.dart` es el
  boilerplate default de Flutter (busca una clase `MyApp` que no existe) y
  falla — nadie lo arregló porque no hay suite de tests real todavía.
- `debugPrint` se usa en varios lugares para loguear excepciones; corre
  también en release (Flutter no lo tree-shakea solo). No filtra datos
  sensibles hoy, pero si agregás un log nuevo, no loguees objetos de
  usuario completos ni credenciales — envolver en `if (kDebugMode)` si el
  log es puramente de desarrollo.
- Dependencias con versiones fijadas por `^` bastante atrás de las últimas
  disponibles (confirmado con `flutter pub outdated` en su momento) —
  nadie las actualizó todavía, riesgo normal de mantenimiento.

**Sobre cambios sin commitear:** a esta altura del proyecto se acumularon
varias sesiones de trabajo (hardening de seguridad, features de
comunicación en vivo/setlist/multi-sala, App Check, esta migración a
Supabase) sin que se pidiera commitear nada — no es un descuido, es la
instrucción explícita del dueño del proyecto: **nunca commitear sin que lo
pida.** No confíes en una lista fija acá (queda vieja enseguida); corré
`git status`/`git diff` para ver el estado real antes de asumir qué está
commiteado y qué no.

## 9. Decisiones de diseño no obvias (para no deshacerlas por error)

- **Wakelock a nivel de sala, no de pantalla de PDF.** Si lo activás/
  desactivás en `PdfViewerScreen`/`CifradoViewerScreen` además de en
  `RequestScreen`/`SonidistaPage`, un `dispose()` de la pantalla hija va a
  apagar la pantalla siempre encendida aunque la pantalla de sala (que la
  sigue queriendo prendida) siga montada debajo — `wakelock_plus` no lleva
  conteo de referencias.
- **Transposición de acordes trabaja sobre texto, nunca sobre el PDF.** No
  existe (ni se planeó) reconocimiento de partituras escaneadas. Si el PDF
  subido es una foto, el campo de cifrado queda vacío y no hay
  transposición salvo que el usuario tipee el cifrado a mano.
- **El color de acento de toda la app sale de `context.acento`**
  (`Theme.of(context).colorScheme.primary`), nunca de `Colors.deepPurple`
  directo. Si agregás un widget nuevo con color de marca, usá
  `context.acento` para que respete la paleta elegida por el usuario.
- **Los colores semánticos (verde = tocado, rojo = eliminar) son fijos**,
  no cambian con la paleta — son estado, no identidad visual.
- Deploy es automático: push a `main` con cambios en `frontend/**` dispara
  `.github/workflows/deploy.yml`, que compila con
  `--base-href /bandasonido/` (tiene que coincidir con el nombre del repo
  en GitHub Pages) y publica en `https://estebancastelani.github.io/bandasonido/`.

## 10. Cómo levantar el proyecto

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

No hace falta nada de backend ni variables de entorno — todo apunta a
Firebase directo con la config hardcodeada en `main.dart`.
