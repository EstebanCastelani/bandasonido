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
transposición de acordes, secuencias (pistas de audio) que cada uno sube
a su cuenta y carga en la sala para reproducirlas en el show, y una
versión "Pro" pensada para monetizar más adelante.

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
(~8.200 líneas a oct-2026 — y va a seguir creciendo; no confíes en este
número, correlo de nuevo con `wc -l` si te importa la cifra exacta). Es una
convención explícita del dueño del
proyecto, no un descuido — no dividir en múltiples archivos sin que te lo
pidan. **Única excepción (aprobada por el dueño, oct-2026):**
`frontend/lib/puente_web.dart`, el puente a lo que corre en JS del
navegador (conversor de MP3 y reproductor con tono y tempo). Usa
`dart:js_interop`, que no compila para Android, así que no puede estar en
`main.dart`. `main.dart` lo importa condicionalmente con prefijo
(`import 'main.dart' if (dart.library.js_interop) 'puente_web.dart' as
puente;`): fuera de la web el import apunta a `main.dart` mismo, que define
las mismas funciones en versión "no disponible" (`conversorMp3Disponible =
false`, `reproductorWebDisponible = false`, el resto tira error). Siempre se
llaman como `puente.xxx`. El truco del auto-import evita un segundo archivo
"stub". Si agregás algo al puente, agregá también su versión "no
disponible" en `main.dart` o el build de Android se rompe (verificalo con
`flutter build apk --debug`). La parte JS vive en `frontend/web/` (ver §5
ítems 20 y 21). Antes se llamaba `conversor_mp3_web.dart`. El archivo está organizado en secciones marcadas con comentarios
`// --- NOMBRE DE SECCIÓN ---`. Mapa actual (los números de línea van a
correrse con cada cambio, pero el orden de secciones se mantiene):

```
CONFIGURACIÓN DE FIREBASE          — FirebaseOptions hardcodeado (ver §4)
CONFIGURACIÓN DE SUPABASE          — Solo Storage, temporal (ver §7.1)
MODELOS Y CONSTANTES               — AppConstants.pedidosRapidos (frases default)
IDENTIDADES DE COLOR (PALETAS)     — AppPalette: 5 temas seleccionables
TRANSPOSICIÓN DE CIFRADOS          — ChordTransposer (lógica pura, sin Flutter)
EXTRACCIÓN DE CIFRADO DESDE PDF    — CifradoPdfExtractor (acordes en su columna, ver §9)
SERVICIO DE AUTENTICACIÓN          — AuthService (Google/email/anónimo)
SERVICIO DE USUARIOS Y FRASES      — UsuarioService, MisSalasService, FrasesService
SERVICIO DE COMPAÑEROS DE SALA     — MiembrosSalaService (presencia, ver §5 ítem 19)
SERVICIO DE REPERTORIO PERSONAL    — RepertorioService (PDFs en Storage)
SERVICIO DE SETLIST DE SALA        — SetlistService
SERVICIO DE SECUENCIAS             — SecuenciasService, ReproductorSecuencias, FilaSecuencia
SERVICIO DE BASE DE DATOS          — FirestoreService (pedidos de sala)
APLICACIÓN PRINCIPAL               — SoundCheckProApp (theme, paleta persistida)
PANTALLA DE CARGA Y REDIRECCIÓN    — SplashScreen (decide a dónde navegar)
PANTALLA DE PRESENTACIÓN           — BienvenidaScreen (primera pantalla sin sesión)
PANTALLA DE LOGIN / REGISTRO       — AuthScreen
MENÚ DE INGRESO                    — IngressMenuScreen (home post-login)
SELECTOR DE IDENTIDAD DE COLOR     — PaletaPickerScreen
PANTALLA DE CREACIÓN DE SALA       — CrearSalaScreen
PANTALLA PARA UNIRSE A SALA        — UnirmeSalaScreen
MIS SALAS                          — MisSalasScreen (historial multi-sala, función Pro)
PESTAÑAS VISIBLES DE LA SALA       — PestanaSala, PestanasSalaService, elegirPestanasSala, borrarSesionDeSala
PANTALLA DE PEDIDOS INDIVIDUAL     — RequestScreen (músico/cantante, tabs Pedidos/Setlist/Secuencias)
LISTA DE TEMAS COMPARTIDA          — SetlistTab (widget reusado en RequestScreen y SonidistaPage)
SECUENCIAS DE LA SALA              — SecuenciasTab (pestaña con reproductor, misma reutilización)
ADMINISTRACIÓN DE FRASES           — FrasesAdminScreen ("Mis frases")
MI REPERTORIO                      — MiRepertorioScreen (biblioteca de PDFs)
MIS SECUENCIAS                     — MisSecuenciasScreen (biblioteca de audios)
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
  pedido, nombre, rol, atendido, urgente, respuesta, createdAt
  urgente (bool): activa parpadeo + vibración/sonido en SonidistaPage.

salas/{codigoSala}/setlist/{id}       — lista de temas del show
  titulo, pdfUrl, cifradoTexto, subidoPor, orden, completado, completadoAt,
  estado, transposicion, createdAt
  estado (String): 'pendiente' | 'pausado' | 'tocado'. Reemplaza al binario
  completado/no-completado, pero completado (bool) se sigue escribiendo en
  paralelo (completado = estado=='tocado') para no romper documentos viejos
  que solo conocían ese campo — ver SetlistService.actualizarEstado.
  transposicion (int, semitonos): sincroniza en vivo la transposición del
  cifrado entre todos los que estén viendo el mismo tema en la sala — ver
  CifradoViewerScreen.

usuarios/{uid}/mis_secuencias/{id}   — biblioteca personal de secuencias (audios)
  titulo, audioUrl, storagePath, storageProvider ('supabase'), createdAt
  Sin límite de cantidad. Archivo en el bucket de Supabase, carpeta
  usuarios/{uid}/secuencias/. Solo el dueño lee/escribe.

salas/{codigoSala}/secuencias/{id}    — secuencias cargadas para el show de hoy
  titulo, audioUrl, subidoPor, orden, createdAt, semitonos, tempoPorcentaje,
  volumenPorcentaje
  semitonos (int, -12..12), tempoPorcentaje (int, 50..150) y
  volumenPorcentaje (int, 0..100): ajustes de esa secuencia en la sala,
  sincronizados a todos (faltan en docs viejos → 0, 100 y 100).
  Copia liviana de las elegidas desde mis_secuencias (no se comparte la
  biblioteca entera). El play NO se sincroniza entre dispositivos.

usuarios/{uid}/mis_salas/{codigoSala}  — historial de salas (función Pro)
  rolUsado, nombre, ultimoAcceso, nombreSala (opcional, editable)
  Doc id = el propio código de sala. Ver MisSalasScreen/MisSalasService y
  §5 (ítem "Multi-banda/multi-sala").

salas/{codigoSala}/miembros/{uid}     — presencia de cuentas reales en la sala
  nombre, ultimaConexion
  Doc id = uid del usuario. NO es función Pro y no depende de
  kFuncionesProGratisPorAhora — se registra sola (best-effort) al entrar a
  RequestScreen/SonidistaPage con cuenta registrada. Único propósito: que
  "Buscar en bibliotecas de la sala" sepa en qué usuarios/{uid}/mi_repertorio
  mirar. Ver MiembrosSalaService y §5 ítem 19.
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
7. 5 identidades de color seleccionables (`AppPalette`: Consola, Placa,
   Wash, Luz de trabajo, Camarín — esta última pastel, agregada después),
   persistidas en `SharedPreferences`, aplicadas a **todo** el acento de la
   app vía `context.acento` (no queda ningún `Colors.deepPurple` hardcodeado).
8. Auditoría de seguridad + hardening: PIN de sala de 6 dígitos numéricos a
   8 caracteres alfanuméricos, Firebase Auth anónimo obligatorio para tocar
   una sala, reglas de Firestore/Storage versionadas en el repo
   (`firestore.rules`, `storage.rules`).
9. **Pedidos urgentes**: campo `urgente` (bool), toggle en `RequestScreen`
   al enviar (se resetea solo después de cada envío). En `SonidistaPage` se
   ven con ícono de alerta, texto en rojo y fondo parpadeante
   (`_UrgentBlink`, `AnimationController`).
10. **Notificación al sonidista**: `StreamSubscription` separado del
    `StreamBuilder` de la UI, escucha `DocumentChangeType.added` (ignorando
    el snapshot inicial) y dispara `HapticFeedback.vibrate()` (no-op en la
    mayoría de navegadores web) + un beep corto (`audioplayers`, asset
    `assets/sounds/pedido_nuevo.wav`, generado sintéticamente).
11. **Historial de pedidos atendidos** y **vista agrupada por rol** (con
    color determinístico por remitente) en `SonidistaPage`.
12. **Setlist**: reordenar por drag & drop (`ReorderableListView`, campo
    `orden`), estado intermedio `pausado` (corte técnico) además de
    tocado/pendiente, y exportar/compartir el setlist como texto plano
    (portapapeles o share sheet del sistema, sin depender de Storage).
13. **Multi-banda/multi-sala (función Pro)**: pantalla "Mis salas"
    (`MisSalasScreen`) — historial de salas con acceso directo, renombrar y
    eliminar del historial. Se registra automáticamente al crear/unirse a
    una sala o entrar como sonidista, solo si `AuthService.esUsuarioRegistrado`
    y (`kFuncionesProGratisPorAhora || esPro`) — ver `_registrarSalaSiCorresponde`.
14. **Firebase App Check**: scaffolding para reCAPTCHA v3 en Web
    (`kAppCheckSiteKeyWeb`, `_activarAppCheckSiCorresponde`), **desactivado
    por default** (constante en `null`) hasta generar el site key real — ver
    §7.2.
15. **Migración temporal de Storage a Supabase** (mientras no hay Blaze) —
    ver §7.1, es la sección más larga de este documento.
16. **Fixes del visor de PDF/cifrado en Web** (necesarios recién ahora,
    porque hasta la migración a Supabase nunca hubo un PDF real para
    probar el visor):
    - `web/index.html` necesitaba el script de `pdf.js` que
      `syncfusion_flutter_pdfviewer` requiere para renderizar en Web — sin
      esto, **tanto `SfPdfViewer.network` como `.memory` fallan siempre**
      con el mismo error genérico ("There was an error opening this
      document"), sin importar si el PDF es válido o de dónde viene. Ver
      §9 para el detalle completo de cómo se diagnosticó.
    - `RepertorioService.extraerTextoPdf` necesitaba `layoutText: true` en
      `PdfTextExtractor.extractText()` — sin eso, cada fragmento de texto
      quedaba en su propia línea en vez de reconstruir los renglones
      reales del PDF (afecta solo a **subidas nuevas**; canciones subidas
      antes de este fix mantienen el cifrado mal formateado, hay que
      volver a subirlas si se quiere corregir).
    - Nombres de archivo con espacios/tildes/paréntesis rompían la subida a
      Supabase Storage (`400 InvalidKey`) — `RepertorioService` ahora
      sanitiza el nombre (`_sanitizarNombreArchivo`, solo
      `[A-Za-z0-9._-]`) antes de armar el `storagePath`. Esto es específico
      de Supabase Storage, no aplicaba con Firebase Storage.
17. **Swipe entre canciones y hacia/desde Pedidos**: en `PdfViewerScreen` y
    `CifradoViewerScreen`, swipe izquierda/derecha pasa a la
    canción siguiente/anterior del setlist actual; swipe hacia arriba
    vuelve a la pestaña Pedidos de la sala; swipe hacia abajo estando en
    Pedidos reabre el último visor. `RequestScreen`/`SonidistaPage` pasaron
    de `DefaultTabController` a un `TabController` explícito para poder
    cambiar de pestaña programáticamente. El gesto se detecta con
    `Listener` (eventos de puntero crudos), no `GestureDetector` — así no
    compite por el gesto con el pan/zoom interno de `SfPdfViewer` ni con el
    scroll de las listas de pedidos.
18. **Buscador al agregar canción al setlist**: tanto "Desde mi biblioteca"
    como "Buscar en bibliotecas de la sala" (en el bottom sheet del botón
    "+" de `SetlistTab`) filtran por título o tonalidad. Nota: hubo un
    intento de agregar además un buscador sobre el setlist *ya armado* de
    la sala (filtrar los temas ya agregados), que se implementó y
    después se revirtió a pedido explícito — no volver a agregarlo salvo
    que se pida de nuevo.
19. **"Buscar en bibliotecas de la sala" acotado a la sala, no a toda la
    app — pero incluye la propia biblioteca.** La primera versión de este
    buscador (`RepertorioService.buscarEnTodasLasBibliotecas`) usaba un
    `collectionGroup('mi_repertorio')` que traía canciones de **cualquier
    cuenta registrada de toda la app**, no solo de la sala actual — y además
    nunca funcionó en la práctica, porque ese tipo de consulta necesita un
    índice de "collection group" en Firestore que no se crea automáticamente
    y nunca se creó (no hay `firestore.indexes.json` en el repo). Se
    reemplazó por `MiembrosSalaService` (`salas/{codigoSala}/miembros/{uid}`):
    cada cuenta registrada (no anónima) registra su propia presencia al
    entrar a `RequestScreen`/`SonidistaPage` (`registrarPresencia`,
    best-effort, no rompe el ingreso si falla) — **incluida la del propio
    usuario**, no solo la de sus compañeros. `MiembrosSalaService.
    obtenerPresentes` trae a todos los que pasaron por la sala (uno mismo
    incluido) y `RepertorioService.cancionesDeCompaneros` hace una consulta
    normal (sin índice especial) por cada uno, combinando los resultados del
    lado del cliente con el nombre del dueño (`propietarioNombre`, la propia
    cuenta incluida) mostrado en cada resultado. El filtro por texto se hace
    aparte, en memoria, vía `RepertorioService.filtrarPorTituloYTonalidad` —
    dos campos independientes (título y tonalidad, ambos deben coincidir),
    insensible a mayúsculas/tildes, actualizado en vivo con cada tecla sin
    volver a golpear Firestore. Ese mismo filtro se reutiliza en "Mi
    repertorio" y en "Desde mi biblioteca" (elegir canción propia para el
    setlist), así los tres buscadores de bibliotecas de la app comparten la
    misma lógica y el mismo look de dos campos lado a lado. Si nadie (ni el
    propio usuario) tiene biblioteca todavía en la sala, se muestra un
    mensaje en vez de buscar. Ver reglas para `miembros` en
    `firestore.rules`.
20. **Secuencias (pistas de audio)**: botón "MIS SECUENCIAS" en el menú
    (cuenta registrada) para subir audios sin límite (mp3/wav/m4a/aac/ogg,
    varios a la vez; el título sale del nombre del archivo y se puede
    renombrar). En la sala hay una pestaña nueva "SECUENCIAS" (en
    `RequestScreen` y `SonidistaPage`) donde se eligen con casillas las
    que se usan ese día, se reordenan, se quitan y se reproducen
    (play/pausa, barra de progreso, detener, "Repetir"). El sonidista solo
    reproduce. Una pista a la vez por dispositivo (`ReproductorSecuencias`)
    y la reproducción es local de cada dispositivo, no se sincroniza.
    `SecuenciasTab` usa `AutomaticKeepAliveClientMixin` para que la pista
    siga sonando al cambiar a Pedidos/Setlist (sin eso `TabBarView`
    destruye la pestaña y corta el audio). Los audios van al mismo bucket
    de Supabase que los PDFs: **el bucket tiene que aceptar tipos de audio**
    (ver §7.1). Con esta pestaña `SonidistaPage` pasó a tener 4 pestañas
    (Pedidos/Historial/Setlist/Secuencias), que en un celular no entraban
    (nombres cortados): su `TabBar` es `isScrollable: true`. La de
    `RequestScreen` (3 pestañas) entra sin eso.
    Estado a oct-2026: probado en la sala (aparecer en vivo, play/pausa,
    cortar una al dar play a otra, seguir sonando al cambiar de pestaña,
    reordenar, quitar, vista del sonidista). **No probado todavía**: subir
    audios desde "Mis secuencias" (necesita que el dueño inicie sesión con
    su cuenta; el bucket ya acepta audio).
21. **Tono, tempo y volumen de las secuencias (como Music Speed Changer)**:
    en la pestaña Secuencias de la sala, el botón de ajustes (ícono de
    controles, `_ajustarTonoYTempo` en `SecuenciasTab`) abre un panel con
    tono ±12 semitonos (botones de a uno), tempo 50-150% (deslizador +
    botones de a 1%), volumen 0-100% (deslizador + botones de a 5%) y
    "Restablecer". **Ninguno cambia a los otros**: `aplicarAjustes` solo
    manda al reproductor lo que cambió (antes mandaba tono y tempo juntos).
    Suena en vivo mientras se mueve y se guarda en el doc de la sala
    (`semitonos`/`tempoPorcentaje`/`volumenPorcentaje`,
    `SecuenciasService.actualizarAjustes`; los deslizadores se guardan al
    soltarlos) → **sincronizado a toda la sala** (decisión del dueño): si
    otro integrante lo cambia, la pista que está sonando acá se ajusta sola
    (`ReproductorSecuencias.aplicarAjustes`, llamado desde el
    `StreamBuilder`). La fila muestra "Tono −2 · Tempo 95% · Vol 80%". El
    sonidista ve el resumen pero no puede cambiarlo (igual que la
    transposición del setlist). En "Mis secuencias" no hay ajustes.
    **Fade out**: botón con flecha hacia abajo junto a "detener" mientras
    suena; baja el volumen en `ReproductorSecuencias.duracionFadeOut` (4 s)
    y frena (web: `rwFadeOut`; Android: baja `setVolume` de a pasos).
    **Sin chasquidos (web)**: play/pausa/stop/saltar/cambiar de pista usan
    fundidos de 15-40 ms (`nodoFundido`); un corte en seco de la onda suena
    como "click" en los parlantes.
    **Cómo suena**: el reproductor normal (audioplayers) solo cambia la
    velocidad; separar tono de tempo requiere procesar el audio. En web,
    `ReproductorSecuencias` usa `web/reproductor_secuencias.js`, que
    **reproduce mientras descarga** con un `<audio>` (no baja la pista
    entera): el **tempo** lo hace el navegador (`playbackRate` con
    `preservesPitch`, ya mantiene el tono) y el **tono** lo hace SoundTouch
    en vivo en el **hilo de audio** (`createMediaElementSource` →
    AudioWorklet `web/procesador_tono.js` → `SoundTouch` con solo
    `pitchSemitones`; `web/soundtouch.js` = soundtouchjs 0.3.0 de npm,
    checksum verificado, LGPL-2.1 → `web/soundtouch.LICENSE.txt`; solo se le
    quitó la línea final `sourceMappingURL` para no pedir un `.map`
    inexistente). Cadena: `<audio>` → [procesador de tono] → `nodoVolumen` →
    `nodoFundido` → salida. Con tono original el audio va directo, sin pasar
    por SoundTouch. Detalles que costaron (no deshacer):
    - **AudioWorklet, no ScriptProcessor.** La primera versión procesaba en
      un ScriptProcessor (hilo principal); con el hilo ocupado (Flutter
      dibujando, celular lento, pestaña en segundo plano) el navegador
      metía huecos en el audio. El worklet se carga apenas carga la página
      (`prepararCadena()` al importar el módulo; el contexto queda
      suspendido hasta el primer toque) para no tener que esperarlo con un
      `await` al dar play.
    - **Reserva de 8.192 muestras** (`RESERVA` en procesador_tono.js):
      SoundTouch devuelve audio en tandas de ~5.300 muestras a 48 kHz; con
      4.096 se quedaba sin audio y hacía huecos (simulado en Node: 3 a 8
      huecos en 20 s; con 8.192, ninguno). Agrega ~170 ms de demora al
      sonido con tono, inaudible para una secuencia.
    - **Calidad**: `stretch.setParameters(sampleRate, 0, 0, 8)` (SoundTouch
      calcula sus ventanas para 44,1 kHz por defecto y el contexto suele
      correr a 48 kHz) y búsqueda completa (`quickSeek = false`, ~2,5 ms por
      cada 85 ms de audio en una PC). Si un dispositivo usa más del 35% del
      tiempo procesando, pasa solo a la búsqueda rápida (`busquedaRapida` en
      `rwEstado`, no se avisa en la UI).
    - **Cambiar el tono, o el tempo con tono activo, mientras suena**:
      tocar los parámetros con audio a medio procesar empalma mal (medido:
      "click" de 0,25-0,36 en un tono puro). Se baja el volumen, se vacía
      SoundTouch y el audio vuelve con una rampa de 1.024 muestras apenas
      sale audio procesado (deja ~200 ms de silencio). Mientras se arrastra
      el deslizador de tempo con tono activo queda en silencio hasta
      soltarlo; sin tono el tempo cambia en vivo sin cortes.
    - Para medir sin dejar código de prueba: en una pestaña aparte,
      parchear `AudioNode.prototype.connect` para meter un AudioWorklet
      "grabador" antes de la salida e importar una segunda copia del módulo
      (`import('./reproductor_secuencias.js?prueba=' + Date.now())`), que
      arma su cadena ya con el grabador. Con un tono de 440 Hz se mide el
      salto máximo entre muestras (natural: ~0,021; un "click": >0,1) y la
      frecuencia real.
    Requiere `audio.crossOrigin = 'anonymous'` (Supabase manda CORS): sin
    eso el navegador entrega **silencio** al procesar audio de otro dominio,
    sin dar error. Al cambiar de pista hay que volver a poner el
    `playbackRate` (el navegador lo resetea). El reproductor es **uno solo
    para toda la página** (`ReproductorSecuencias._duenoWeb` decide qué
    pantalla lo controla) y Dart consulta su estado cada 200 ms. Se carga
    como `<script type="module">` en `web/index.html`. Orden al dar play:
    `rwDesbloquear()` → tempo/tono/repetir → `rwCargar(url)`, que ya llama a
    `audio.play()` sin `await` previo, dentro del toque del usuario (los
    navegadores de celular solo dejan iniciar audio así).
    **Historia (para no volver atrás):** la primera versión usaba el
    `PitchShifter` de SoundTouch sobre la pista entera: bajaba los 13 MB y
    decodificaba todo (~120 MB en memoria) antes de sonar → ~1,8 s en una PC
    con buena conexión y bastante más en celular con datos. La versión que
    reproduce mientras descarga empieza a sonar en ~0,6 s en la misma PC.
    **Android** sigue con audioplayers: el tempo funciona
    (`setPlaybackRate`, mantiene el tono) pero el tono no — el panel lo
    muestra deshabilitado con un aviso (decisión del dueño; para tenerlo
    habría que pasar Android a `just_audio`, que sí lo soporta).
    Probado en web (oct-2026): −2 semitonos y 98% aplicados en vivo; un
    cambio escrito por "otro integrante" (+3, 110%) llegó solo al
    reproductor. Con la versión que reproduce mientras descarga: suena a
    los 0,62 s del toque, sale señal con tono original y con −2 semitonos
    (medido con un AnalyserNode), y a 75% avanza a 0,75×. Con el
    procesador en el hilo de audio (medido con un tono de 440 Hz): +1, +2 y
    −1 salen exactos (1,01 / 2,00 / −1,00) y el tempo no se mueve al cambiar
    el tono; tempo 80% y 110% con tono exactos; pausa, play, saltar,
    volumen, detener, cambiar tono y cambiar tempo sin saltos (≤0,024); el
    fade out baja parejo y frena. El cambio de tono no se escuchó (se
    verificó por señal). No se probó en un celular real.
    **Reporte del dueño (oct-2026)**: "sube más de un semitono y cambia el
    tempo" en el celular. No se pudo reproducir; lo más probable es que haya
    sido una secuencia de la sala de prueba que quedó en +3 y 110% por una
    prueba de sincronización. Si vuelve a aparecer, pedir modelo de
    celular y navegador.
22. **Cada usuario elige qué pestañas ver en la sala** (oct-2026): botón
    con ícono de carrusel (`Icons.view_carousel_outlined`) en la barra de
    `RequestScreen` y de `SonidistaPage` → diálogo con casillas
    (`elegirPestanasSala`); tiene que quedar al menos una. Músico/cantante
    elige entre Pedidos, Setlist y Secuencias; el sonidista, entre Pedidos,
    Historial, Setlist y Secuencias (elección separada). Se guarda **en el
    dispositivo** (`SharedPreferences`, claves `pestanas_sala_musico` y
    `pestanas_sala_sonidista`; `PestanasSalaService`), así funciona también
    para invitados sin cuenta; no se sincroniza entre dispositivos ni con
    la cuenta. Detalles de implementación:
    - Las pestañas se arman desde un mapa `PestanaSala → contenido`
      (`_contenidoDePestanas`) filtrado por la elección; al cambiarla se
      vuelve a crear el `TabController` (por eso esas pantallas usan
      `TickerProviderStateMixin`), quedándose en la pestaña que se miraba
      si sigue visible.
    - Con una sola pestaña no se muestra la barra de pestañas. La del
      sonidista solo se desliza (`isScrollable`) con 4.
    - Si Pedidos está oculta, el swipe hacia arriba del visor de PDF/cifrado
      solo vuelve a la sala (`_irAPedidos` busca el índice real de
      Pedidos). El sonidista sigue recibiendo el aviso sonoro de pedidos
      nuevos aunque oculte Pedidos.
    - Ocultar Secuencias saca su pestaña de la pantalla y corta lo que esté
      sonando (el reproductor se libera con la pestaña).
    - **Al salir de la sala ya no se hace `prefs.clear()`**: se borran solo
      las claves de la sesión (`borrarSesionDeSala`: `tipo_login`,
      `sala_id`, `nombre`, `rol`). Antes, salir de una sala borraba también
      la paleta de colores elegida (y hubiera borrado las pestañas).

23. **Pantalla de presentación (`BienvenidaScreen`, oct-2026)**: primera
    pantalla para quien no tiene sesión (la muestra `SplashScreen` y
    también cerrar sesión de cuenta, en vez de ir directo a `AuthScreen`).
    Diseño del dueño (una imagen de referencia): logo de barras de onda con
    degradé celeste→violeta (`_PintorOnda`, dibujado por código), "SOUND
    CHECK **PRO**", subtítulo, tres botones y una tarjeta con las cuatro
    funciones. Botones: "Iniciar sesión" → `AuthScreen`; "Crear cuenta" →
    `AuthScreen(modoRegistroInicial: true)`; "Entrar como invitado" →
    `IngressMenuScreen` (lo mismo que hacía "Continuar sin cuenta", que
    sigue existiendo dentro de `AuthScreen`). Arriba quedan solo modo
    claro/oscuro y paleta (los de la imagen de referencia, más el de
    iniciar sesión, que sobraba).
    - **Es la excepción a "el color sale de `context.acento`"**: esta
      pantalla es siempre oscura y usa colores propios (`_celeste`,
      `_violeta`), porque es la identidad de marca de la imagen.
    - **Fondo**: `assets/images/fondo_bienvenida.jpg` (900×1600; luces
      violetas y celestes, micrófono, consola y guitarra, **sin** textos ni
      botones). Sale de la imagen de referencia del dueño, que trae todo el
      diseño pegado: se le borraron la barra de estado, los íconos, el logo
      y textos, los botones, la tarjeta y la barra de abajo con el filtro
      `delogo` de ffmpeg (rellena cada rectángulo interpolando los bordes),
      y se suavizaron con `gblur` + máscara de bordes suaves las rayas
      horizontales que deja ese relleno sobre las luces de la consola. Zonas
      rellenadas (x,y,ancho,alto): (1,1,898,82), (585,92,300,84),
      (236,100,455,540), (168,668,568,420), (40,1100,830,290),
      (40,1404,830,170). Si hay que rehacerlo con otra imagen, mismo
      método. Si el archivo no está, `Image.asset` falla en silencio y se
      dibuja `_FondoEscenario` (degradé oscuro con luces dibujadas por
      código). `assets/images/` está declarada entera en `pubspec.yaml`:
      cambiar la foto es soltar otra con el mismo nombre, sin tocar código.
      Se muestra con `BoxFit.cover`: en celulares angostos recorta un poco
      los costados (el micrófono queda cortado en el borde izquierdo).
    - La barra de abajo de la imagen de referencia (Inicio, Setlist,
      Pedidos, Repertorio, Ajustes) **no se hizo**: implica reorganizar la
      navegación de toda la app (decisión del dueño: dejarlo para después).
    - Para ver esta pantalla sin cerrar la sesión del navegador de prueba:
      el servidor de desarrollo **no tolera** abrirse desde `127.0.0.1` (se
      cae por la conexión de depuración); en cambio, `flutter build web
      --release` + un servidor estático en `127.0.0.1:<otro puerto>` da un
      origen sin sesión.

24. **Paleta "Escenario" (oct-2026)**: el estilo de `BienvenidaScreen`
    (casi negro, celeste y violeta neón, bordes celestes finos, esquinas
    redondeadas) llevado a toda la app como una paleta más
    (`AppPalette.escenario`, la primera del selector) y **la predeterminada**
    (`AppPalette.porDefecto`: se usa si el usuario nunca eligió una; quien ya
    había elegido otra la conserva). Se aplica desde el tema global
    (`_temaEscenario()`, que `construirTema` devuelve para esta paleta): app
    bars, botones, tarjetas, campos de texto, pestañas, diálogos, bottom
    sheets, snackbars, sliders, chips, checkbox/switch, FAB. No se tocó
    ninguna pantalla una por una. Es **siempre oscura**: el botón de modo
    claro/oscuro no hace nada con esta paleta. Para volver a lo de antes:
    cambiar `porDefecto` a `consola` (o elegir otra en "Color de la app").
    Verificado en web como invitado: menú, crear sala, la sala (pedidos,
    pestañas), el selector de pestañas y el selector de colores. **No se
    revisaron** con este tema las pantallas que piden cuenta (Mis
    secuencias, Mi repertorio, Mis frases, Mis salas) ni el visor de PDF/
    cifrado. Posible siguiente paso (no hecho): el fondo con la foto del
    escenario también detrás de las otras pantallas (no se puso con un
    fondo transparente global porque durante las transiciones de pantalla se
    verían dos a la vez).

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
  refleja exactamente lo que está en producción (última publicación:
  21-oct-2026, con las reglas de `secuencias`/`mis_secuencias`). Si lo
  cambiás, hay que volver a publicarlo o las colecciones nuevas dan
  `permission-denied`.
  **Cómo publicarlo:** el Firebase CLI de la PC del dueño está logueado
  con su cuenta y tiene acceso a `appbandasonido`. El repo **no tiene
  `firebase.json`** (a propósito, para no sumar config); se publica desde
  una carpeta temporal con una copia de `firestore.rules` y un
  `firebase.json` mínimo (`{"firestore": {"rules": "firestore.rules"}}`):
  `firebase deploy --only firestore:rules --project appbandasonido`. Es
  producción: pedir OK al dueño antes de cada publicación. El compilador
  avisa "sub-expressions are not comparable" en los `salaId != null` —
  es preexistente e inofensivo (siempre da true, el `size() > 0` es el
  que filtra). La alternativa sin CLI es Firebase Console → Firestore →
  Reglas, pegando el archivo.
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
  creado (público; hoy sin límite de tamaño propio y con PDF + tipos de
  audio permitidos, ver bullet de Secuencias más abajo), Firebase agregado
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

  -- Agregada el 21-oct-2026: sin SELECT, remove() no borra nada y no da
  -- error (ver bullet "Borrar no borraba el archivo" más abajo).
  create policy "Lectura API solo del dueño"
  on storage.objects for select
  using (
    bucket_id = 'repertorio-pdfs'
    and (storage.foldername(name))[1] = 'usuarios'
    and (storage.foldername(name))[2] = (auth.jwt()->>'sub')
  );
  ```
- **Secuencias (audios) en el mismo bucket**: `SecuenciasService` sube a
  `repertorio-pdfs` bajo `usuarios/{uid}/secuencias/` (las políticas RLS
  por carpeta de usuario ya lo cubren, no hacen falta políticas nuevas).
  Para eso el bucket acepta, en "Allowed MIME types": `application/pdf,
  audio/mpeg, audio/wav, audio/mp4, audio/aac, audio/ogg` (configurado el
  21-oct-2026 desde el dashboard: Storage → `repertorio-pdfs` → Edit
  bucket → Bucket settings). Si se agrega un formato nuevo en
  `SecuenciasService.extensionesPermitidas`, sumar también su MIME acá o
  la subida falla. El bucket no tiene límite de tamaño propio ("Restrict
  file size" apagado), así que rige el límite global del proyecto de
  Supabase: **50 MB por archivo, fijo en el plan gratis** (el dashboard no
  deja cambiarlo; solo Pro lo hace configurable). Un WAV estéreo de 44,1
  kHz supera ese tamaño a partir de ~5 minutos — pasó con el primer tema
  real que se intentó subir (61 MB), y Supabase lo rechazaba con un error
  poco claro. Por eso, **en web**, `MisSecuenciasScreen` convierte
  automáticamente a MP3 en el navegador los archivos que pasan
  `SecuenciasService.tamanoMaximoBytes` (solo esos; lo que entra se sube tal
  cual, decisión del dueño), apuntando a `tamanoObjetivoMp3Bytes` (48 MB):
  usa 320 kbps y baja el bitrate solo si el tema es tan largo que no entra.
  Al terminar muestra qué se convirtió (tamaño antes/después y kbps).
  **Fuera de la web** (Android) no hay conversor: se avisa que el archivo
  es demasiado grande y se sugiere convertirlo o usar la web.
  Piezas: `web/conversor_mp3.js` (`window.convertirAMp3`: decodifica con
  `OfflineAudioContext.decodeAudioData` a 44,1 kHz y elige el bitrate),
  `web/conversor_mp3_worker.js` (codifica en un Web Worker para no congelar
  la UI), `web/lame.min.js` (lamejs 1.2.1 de npm, sin modificar, checksum
  verificado contra el registro; licencia LGPL-3.0 →
  `web/lame.LICENSE.txt`, se mantiene como archivo separado y reemplazable
  para cumplirla) y `lib/puente_web.dart` (ver §2). Probado con el
  WAV real de 58 MB / 5:45: ~40 s en desktop, quedó en 13,2 MB a 320 kbps
  y se reproduce bien. En celulares va a tardar más y usa bastante memoria
  (el audio decodificado de un tema de 6 min ronda los 120 MB). Si se pasa
  a Supabase Pro o a Firebase Storage (Blaze), subir `tamanoMaximoBytes`.
- **Borrar no borraba el archivo en Supabase (resuelto el 21-oct-2026).**
  El bucket tenía solo políticas de INSERT y DELETE; la API de Storage
  necesita también **SELECT** sobre `storage.objects` para poder borrar, y
  sin ella `remove()` no borra nada **y no devuelve error**
  (`eliminarSecuencia`/`eliminarCancion` además lo tragan con un
  `try/catch`). Al eliminar una secuencia o un PDF se borraba el documento
  de Firestore pero el archivo quedaba en el bucket. Se agregó la política
  "Lectura API solo del dueño" (SQL arriba): misma condición de carpeta que
  la de borrado y sin `to authenticated`; el bucket ya era público para leer
  por URL, así que no expone nada nuevo. Verificado: subir y borrar una
  secuencia de prueba → el archivo pasó de responder 200 a 400.
  **Pendiente:** los archivos que quedaron huérfanos por lo borrado antes
  del fix (PDFs y secuencias) siguen en el bucket ocupando espacio. Uno
  conocido: `usuarios/V9830EiBhRMtEjaclGP77pwXmv93/secuencias/1792621013477_bautizados_en_fuego_VOL.mp3`
  (duplicado de una prueba). Para encontrar el resto: comparar los archivos
  de cada carpeta `usuarios/{uid}/` con los `storagePath` de
  `mi_repertorio`/`mis_secuencias`. Borrar archivos es irreversible: que lo
  confirme el dueño.
- **Para revertir cuando se active Blaze**: el plan fue diseñado para que
  la vuelta atrás sea acotada a `RepertorioService` — cambiar
  `subirCancion` para que vuelva a usar `FirebaseStorage.instance` (como
  antes de este parche) y ajustar el branch de `eliminarCancion`. No hace
  falta migrar los documentos de Firestore ya subidos a Supabase: quedan
  con `storageProvider: 'supabase'` y siguen funcionando (el bucket de
  Supabase no se apaga solo), o se migran aparte si en algún momento se
  quiere consolidar todo en un solo backend.

### 7.2 GitHub Pages: dos deploys compitiendo por el mismo sitio

Encontrado en producción: cada push a `main` dispara **dos workflows en
paralelo** — el custom `.github/workflows/deploy.yml` ("Deploy to GitHub
Pages", el que compila Flutter) y uno automático de GitHub llamado
**"pages build and deployment"** (Jekyll, arma el sitio a partir del
contenido crudo del repo). Ambos terminan casi al mismo segundo y publican
al mismo sitio — el que termina último gana. Cuando gana el de Jekyll, la
URL pública muestra el `README.md` renderizado en vez de la app.

Causa: el repo tiene la fuente de GitHub Pages configurada como **"Deploy
from a branch"** en vez de **"GitHub Actions"**. Mientras esté así, GitHub
sigue corriendo su propio build automático sin que el workflow custom
pueda evitarlo.

**Fix (pendiente, acción manual en GitHub, no es código):**
`github.com/EstebanCastelani/bandasonido/settings/pages` → "Build and
deployment" → "Source" → cambiar de "Deploy from a branch" a **"GitHub
Actions"**. Si al entrar a la URL pública aparece el README en vez de la
app, esto es lo primero para revisar.

## 8. Deudas técnicas y pendientes explícitos

**Bloqueantes para "app paga" real:**
- No hay ningún sistema de cobro (Stripe, Play Billing, etc.). `esPro` se
  activa a mano desde la consola de Firebase. Hasta que exista cobro real,
  `kFuncionesProGratisPorAhora = true` en `main.dart` mantiene la función de
  subir PDFs abierta a cualquier cuenta registrada. Para reactivar el gate:
  poner esa constante en `false` y descomentar la condición `esPro == true`
  que ya está dejada comentada en `firestore.rules` y `storage.rules`.

**Bloqueantes para publicar en Play Store:**
- ~~No existe carpeta `android/`~~ Ya existe (`flutter create
  --platforms=android --org com.soundcheckpro .`, corrido para generar un
  APK de instalación directa a pedido del dueño del proyecto). Package id:
  `com.soundcheckpro.appsonido_frontend`. Firmado con el keystore de debug
  por default (no hay keystore de release todavía) — sirve para instalar y
  probar en un celular real, **no** para subir a Play Store así como está.
  - Requirió instalar el Android SDK localmente (no estaba instalado):
    `C:\Android\sdk`, vía `flutter config --android-sdk` +
    `flutter doctor --android-licenses`. Paquetes: platform-tools,
    platforms;android-35, platforms;android-36, build-tools;28.0.3
    (y build-tools;35.0.0 + NDK + CMake que Gradle pidió solo durante el
    primer build).
  - El JDK de esta máquina es Temurin 25, que no es compatible con el
    Gradle 8.14 que trae `flutter create` por default — hubo que subir
    `frontend/android/gradle/wrapper/gradle-wrapper.properties` a
    `gradle-9.1.0-all.zip` para que compile. Si en otra máquina el build
    falla por versión de Gradle/JDK, revisar esto primero.
- **"Continuar con Google" ya está conectado para Android nativo.** Se
  registró una app Android en el proyecto de Firebase (`appbandasonido`)
  con package id `com.soundcheckpro.appsonido_frontend` y el SHA-1 del
  keystore de **debug** (`D9:9B:66:1A:02:8F:2B:A7:3F:FA:E1:0A:75:69:66:2A:
  18:F1:72:67`) — ver huella completa corriendo `keytool -list -v
  -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey
  -storepass android -keypass android` (en esta máquina hace falta agregar
  `-J-Duser.language=en -J-Duser.country=US` porque el `keytool` de
  Temurin 25 tiene un bug de formato con la locale es-AR). El
  `google-services.json` resultante vive en
  `frontend/android/app/google-services.json` — **no está en git**
  (gitignoreado a propósito, como los demás archivos de firma/credenciales
  — ver el bloque correspondiente en `frontend/.gitignore`), así que en
  otra máquina hay que volver a descargarlo desde Firebase Console o
  pedírselo al dueño del proyecto. El plugin `com.google.gms.google-
  services` ya está declarado en `android/settings.gradle.kts` y aplicado
  en `android/app/build.gradle.kts`; sin el `.json` el build de Android
  falla. El código Dart (`AuthService.signInWithGoogle` en main.dart) no
  necesitó cambios — ya usaba `GoogleSignIn()` nativo fuera de `kIsWeb`.
  **Importante:** este SHA-1 es el del keystore de *debug*, que Gradle
  regenera distinto por máquina si no existe `%USERPROFILE%\.android\
  debug.keystore` — si Google Sign-In empieza a fallar con
  `DEVELOPER_ERROR` después de compilar en otra PC, agregar el SHA-1 de
  esa máquina también en Firebase Console (Configuración del proyecto →
  la app Android → Agregar huella digital). Cuando se genere un keystore
  de release (ver punto siguiente), va a hacer falta agregar *ese* SHA-1
  también, o Google Sign-In va a fallar en los builds firmados para Play
  Store aunque funcione en este APK de debug.
- No hay keystore de firma generado ni `key.properties`. El `.gitignore` ya
  tiene las reglas para que esos archivos nunca se suban una vez que
  existan, pero hay que crearlos.
- Comando de build de producción (ya con `android/` existente):
  `flutter build appbundle --release --obfuscate --split-debug-info=build/symbols`
  (guardar `build/symbols` fuera del repo público — hace falta para leer
  crashes reales). El comando usado para el APK de prueba fue
  `flutter build apk --release` (sin `--obfuscate`, sin `.aab`) — no
  confundir uno con otro.

**Deuda de seguridad conocida (ver §6 para el detalle):**
- El modelo de acceso a salas por PIN sigue siendo fuerza-bruteable en
  teoría, solo que ahora mucho más caro.
- Falta restringir la Web API Key por dominio en Google Cloud Console.
- Firebase App Check tiene el scaffolding listo pero **desactivado**
  (`kAppCheckSiteKeyWeb = null` en `main.dart`) — falta generar el site key
  de reCAPTCHA v3 y pegarlo ahí. Play Integrity (Android) todavía no está
  configurado — ya existe `android/` (ver §8, bloqueantes de Play Store),
  pero App Check para Android no se armó, solo el de Web.

**Deuda de infraestructura de deploy (ver §7.2):**
- GitHub Pages está configurado como "Deploy from a branch" en vez de
  "GitHub Actions", lo que hace que compita con el workflow custom de
  Flutter y a veces gane, publicando el README en vez de la app. Pendiente
  que el dueño del proyecto cambie ese setting en GitHub.

**Deuda de infraestructura temporal (ver §7.1):**
- El repertorio personal sube PDFs a Supabase Storage en vez de Firebase
  Storage, mientras no se active Blaze. Ya probado end-to-end (subida real
  funcionando) — es deuda a mediano plazo, no un bloqueante activo.
- Cuando se active Blaze, hay que decidir si se revierte `RepertorioService`
  a Firebase Storage (dejando los archivos ya subidos a Supabase donde
  están) o si se migran esos archivos también — no está resuelto todavía,
  es una decisión pendiente.

**Deuda de código:**
- `main.dart` es un archivo único de ~8.200 líneas y creciendo. Es una decisión
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
  Ver §7.2 si la URL pública muestra el README en vez de la app.
- **`web/index.html` necesita el script de `pdf.js` sí o sí.**
  `syncfusion_flutter_pdfviewer` no renderiza nada en Web sin
  `<script src="//cdnjs.cloudflare.com/ajax/libs/pdf.js/2.11.338/pdf.min.js">`
  + configurar `pdfjsLib.GlobalWorkerOptions.workerSrc` (ver el `<body>` de
  `web/index.html`). Sin esto, `SfPdfViewer.network` y `.memory` fallan
  siempre con el mismo error genérico, sin importar si el PDF es válido —
  costó una sesión entera de debug descubrir que no era un problema de
  Supabase/CORS sino este script faltante. No lo borres.
- **`PdfTextExtractor.extractText()` necesita `layoutText: true`.** Sin ese
  parámetro (default `false`), el texto extraído queda con cada fragmento
  en su propia línea en vez de reconstruir los renglones visuales reales
  del PDF — se nota mucho en el cifrado (una palabra por línea). Ver
  `RepertorioService.extraerTextoPdf`.
- **El cifrado se reconstruye con la posición real de cada acorde, no con
  `extractText`.** `extractText(layoutText: true)` arregla los renglones pero
  pierde la posición horizontal: todos los acordes quedaban pegados a la
  izquierda en vez de sobre la sílaba correspondiente. `CifradoPdfExtractor`
  (main.dart) usa `extractTextLines` — que da la coordenada X de cada letra —
  y ubica cada acorde en la columna de la letra que tiene debajo en el PDF
  (las letras del PDF son de ancho variable, así que se mide contra cada
  carácter, no se copian los espacios). Detalles que costó descubrir: el
  extractor a veces parte un renglón en pedazos con la misma altura (ej. la
  última letra suelta) y hay que juntarlos; una línea cuenta como "de
  acordes" si ≥60% de sus palabras son acordes (`ChordTransposer.
  esLineaDeAcordes`) y se empareja con la línea de letra que sigue si está a
  ≤1,5 renglones. `extractText` queda solo como respaldo si falla.
  **Versionado del cifrado guardado (`cifradoVersion`, ver
  `kVersionCifrado`):** `mi_repertorio` y `setlist` guardan una *copia* del
  texto, así que lo subido con el extractor viejo seguía mostrándose mal
  (acordes pegados a la izquierda). Los documentos sin el campo o con una
  versión menor se consideran viejos: `CifradoViewerScreen` (si recibe
  `pdfUrl`) baja el PDF con `package:http`, lo vuelve a extraer, lo muestra
  y lo guarda vía `alRegenerar` (`SetlistService.actualizarCifrado` /
  `RepertorioService.guardarCifradoRegenerado`), así que la corrección es
  automática la primera vez que se abre cada tema, sin intervención del
  usuario. Subir un PDF, editar a mano el cifrado y el botón "Regenerar
  cifrados desde los PDF" de Mi repertorio (`RepertorioService.
  regenerarCifrados`, pisa también lo editado a mano) dejan el documento en
  la versión actual. `agregarAlSetlist` copia la versión de la canción de
  origen para que lo editado a mano no se pise al abrirlo en la sala. Un PDF
  sin texto seleccionable nunca pisa el cifrado guardado. Si cambia el
  formato del extractor otra vez, subir `kVersionCifrado`.
- **Los cifrados se muestran con una fuente monoespaciada propia
  (`RobotoMono`, `assets/fonts/`), no con `fontFamily: 'monospace'`.** En web
  (CanvasKit) la fuente genérica del sistema no está disponible y cae en una
  proporcional, lo que desalinea los acordes. El visor además achica la letra
  (mín. 9 pt) para que el renglón más largo entre sin partirse, y permite
  desplazar hacia el costado si aun así no entra. La transposición reescribe
  cada acorde en su misma columna (`ChordTransposer._transponerLinea`) para
  que C → C# no corra lo que sigue.
- **Los gestos de swipe (PdfViewerScreen/CifradoViewerScreen) usan
  `Listener`, no `GestureDetector`.** Es deliberado: `GestureDetector`
  compite por el gesto con el pan/zoom interno de `SfPdfViewer` y con el
  scroll de las listas de la app, y en la práctica no recibe los eventos.
  `Listener` opera por debajo de esa capa de arbitraje y sí funciona. Si
  agregás gestos nuevos sobre contenido con scroll/zoom propio, replicá
  este patrón en vez de `GestureDetector`.
  **Trampa de ese enfoque (ya corregida): un pellizco para hacer zoom
  cambiaba de canción.** Con eventos crudos hay que contar los dedos: si se
  guarda solo "dónde bajó el último dedo", al levantar un dedo del pellizco
  el movimiento se mide contra el punto donde había apoyado el *otro* y
  parece un swipe horizontal. `DetectorSwipe` (main.dart) lleva la cuenta de
  punteros activos y descarta el gesto entero si en algún momento hubo más
  de uno; además `PdfViewerScreen` ignora el swipe mientras el PDF tiene zoom
  (`onZoomLevelChanged`), para poder arrastrar la página ampliada sin cambiar
  de tema. Usá `DetectorSwipe` para cualquier swipe nuevo en vez de guardar un
  `Offset?` suelto.
  **Segunda trampa (corregida oct-2026): hacer scroll sacaba del visor.**
  `Listener` ve el arrastre aunque sea un scroll, así que bajar por la letra
  del cifrado (o por un PDF de varias páginas) arrastrando hacia arriba se
  tomaba como "swipe arriba → volver a Pedidos". Regla actual en ambos
  visores: se guarda la posición del scroll al apoyar el dedo
  (`_scrollAlBajar`: los `ScrollController` del cifrado, o
  `PdfViewerController.scrollOffset` del PDF) y, si al levantarlo cambió más
  de 2 px, el gesto fue un scroll y se ignora. Así el swipe solo vale cuando
  no había más para desplazar en esa dirección (al final de la letra, o si
  entra entera). Además el contenido del cifrado ocupa toda la pantalla
  (`SizedBox.expand`): con letra corta el scroll medía solo lo que el texto
  y el swipe no funcionaba sobre el espacio vacío. Verificado con una
  prueba de widget (arrastres reales: en el medio desplaza sin salir, al
  final vuelve a Pedidos, con letra corta vuelve a Pedidos); la prueba se
  borró después (no hay suite de tests). En el PDF solo se verificó que abre
  bien con el controlador nuevo, no el gesto en sí.

## 10. Cómo levantar el proyecto

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

No hace falta nada de backend ni variables de entorno — todo apunta a
Firebase directo con la config hardcodeada en `main.dart`.

**Para una IA con navegador integrado (Claude Code, etc.):**
`.claude/launch.json` tiene la config `appsonido-frontend`, que levanta
`flutter run -d web-server --web-port 5000`. **El dueño quiere que se use
el puerto 5000**, no otro. Detalles que costaron tiempo:
- El web-server no recarga solo al editar `main.dart`: hay que detener y
  volver a levantar el servidor, y recargar la página.
- Al detener el preview a veces queda vivo el proceso `dartvm` ocupando el
  5000 (el siguiente arranque cae en otro puerto o falla con "Solo se
  permite un uso de cada dirección de socket"). Revisar quién escucha en
  el 5000 (`Get-NetTCPConnection -LocalPort 5000`) y cerrar ese `dartvm`.
- La primera carga tarda ~30 s (compilación de debug); si la página se
  abre antes, queda en blanco: esperar y recargar.
- Probar en tamaño celular (375×812): ahí aparecen los problemas reales
  de espacio (ej. las pestañas del sonidista). Después de cambiar el
  tamaño de la ventana, Flutter a veces dibuja mal hasta recargar.
- Cuidado al cambiar de pestaña: un clic durante la animación cae en la
  pestaña anterior (así se mandaron pedidos de prueba sin querer).

**Probar sin cuenta registrada:** "Continuar sin cuenta" alcanza para
crear/unirse a una sala y ver Pedidos/Setlist/Secuencias. Todo lo que
depende de cuenta real (Mi repertorio, Mis secuencias, Mis frases, Mis
salas) necesita que el dueño inicie sesión — una IA no debe tipear
contraseñas. Para cargar datos de prueba en una sala sin cuenta se puede
usar la REST API como invitado anónimo (es lo mismo que hace la app):
`POST identitytoolkit.googleapis.com/v1/accounts:signUp?key=<apiKey>` con
`{"returnSecureToken": true}` → `idToken`, y con ese token escribir en
`firestore.googleapis.com/v1/projects/appbandasonido/databases/(default)/documents/salas/<PIN>/...`.
Como audio de prueba sirve el asset de la app
(`http://localhost:5000/assets/assets/sounds/pedido_nuevo.wav`). **Borrar
los datos de prueba al terminar** — la base es la de producción.
