# Backlog del producto

Fuente única de pendientes (reúne los planes de `AUDITORIA_USABILIDAD.md`, `AUDITORIA_TESTING.md` y `AUDITORIA_CALIDAD_ESTANDARES.md`). Prioridad: **P1** en el uso en vivo / riesgo alto · **P2** importante · **P3** mejora. Esfuerzo: S ≈ medio día · M ≈ 1–2 días · L ≈ 3+ días. 🔑 = necesita una acción o decisión del dueño (cuentas, claves, permisos). Se prioriza por la regla de la clase: primero lo que daña el uso real, después lo demás.

## En curso
_(vacío — elegir 3–5 ítems al comenzar cada sprint, ver `PROCESO.md`)_

## Pendientes

| ID | Prioridad | Ítem | Esf. | Origen | Bloqueo |
|---|---|---|---|---|---|
| B-01 | P1 | Activar **App Check** (clave reCAPTCHA) y exigirlo tras un período en modo monitor | M | Calidad E3 · Q3 | 🔑 clave y cuenta de Firebase |
| B-02 | P1 | Publicar la validación de pedidos en las reglas de Firestore: la propuesta ya está en `firestore.rules.propuesta` y probada con el emulador (`rules-tests/`). Falta ponerle tope en la app a la respuesta, el nombre y el rol (hoy sin límite) y publicar | S | Calidad E3 · Q3 | 🔑 publicar reglas |
| B-03 | P1 | Medir la **latencia pedido→panel** y la carga con red 4G simulada; fijar el presupuesto | M | Calidad E4 · Q7 | — |
| B-04 | P1 | Aviso de "sin conexión" también en el **panel del sonidista** | S | Calidad E1 · Q1 | — |
| B-05 | P1 | Probar con **dos sonidistas** a la vez (atender/borrar/deshacer el mismo pedido) | M | Testing E5 · DF-05 | — |
| B-06 | P1 | Decidir **D-03**: validar que la sala exista al unirse (reglas + migrar salas existentes) | M | Testing · DF-04 | 🔑 decisión |
| B-07 | P2 | Publicar el primer tag `v1.1.0` y **ensayar el rollback** (`OPERACION.md` §2) | S | Calidad E2 · Q4 | tras el próximo despliegue en verde |
| B-08 | P2 | Correr las **pruebas de reglas** (`rules-tests/`, 51, ya hechas) en la CI (hace falta Java y `firebase-tools`) | S | Testing E4 · T9 | — |
| B-09 | P2 | Pruebas de **pantallas** con Firebase simulado (formularios, deshacer, salir) | L | Testing E3 · T13 | — |
| B-10 | P2 | Inventario de planes y cuotas de Firebase y Supabase (¿se pausa por inactividad?) | S | Calidad E1 · Q2 | 🔑 acceso a las consolas |
| B-11 | P2 | Android: activar el trabajo de CI (secreto + variable) y crear el **keystore** de release | M | Calidad E2 · Q5 | 🔑 |
| B-12 | P2 | Protección de la rama `main` (PR + CI obligatoria) | S | Calidad E7 · Q10 | 🔑 administración del repo |
| B-13 | P2 | Usabilidad E0: línea base (tiempos reales, éxito, SUS con 5 personas) | M | Usabilidad E0 | — |
| B-14 | P2 | Usabilidad E2: ingreso más rápido (nombre/rol precargados, chips de rol, Enter) | M | Usabilidad E2 · H8 | — |
| B-16 | P2 | Tope y paginación del **Historial** y de otras listas en vivo (requiere un índice nuevo en Firestore) | M | Calidad E4 · DF-08 | 🔑 índice |
| B-17 | P2 | Accesibilidad: contraste de las 6 paletas, escala de texto 150 %, lector de pantalla | M | Usabilidad E6 | — |
| B-18 | P3 | Actualizar dependencias mayores **una por una** (Firebase 5→7, Syncfusion 28→35, `file_picker`, `google_sign_in`…) | L | Calidad E3 · `OPERACION.md` §4 | prueba en celular |
| B-19 | P3 | Copiar `pdf.js` (y opcionalmente CanvasKit) al proyecto para no depender de CDN externos | S–M | Calidad E1 · Q2 | 🔑 aprobar la descarga |
| B-20 | P3 | Dividir `main.dart` por dominio (propuesta en `AUDITORIA_CALIDAD_ESTANDARES.md` §5) | L | Calidad E5 · Q8 | 🔑 aprobar (hoy la regla es "todo en `main.dart`") |
| B-21 | P3 | Exportar/importar **el setlist** (y CSV): el repertorio ya se exporta/importa en ChordPro y JSON (rama `desarrollo`) | S | Calidad E6 · Q13 | — |
| B-22 | P3 | Guía de estilo de textos (voseo/neutro, mayúsculas); la primera vez guiada y la ayuda ya están (rama `desarrollo`) | S | Usabilidad E5 | 🔑 decidir registro |
| B-23 | P3 | Conservación de pedidos por 24 h (limpieza automática en el servidor) | M | Testing · D-08 | plan Blaze 🔑 |
| B-26 | P2 (Play Store) | Archivos de usuarios en bucket **público** de Supabase: decidir si pasan a privados con enlaces firmados | M | `PLAY_STORE.md` §7 | 🔑 decisión |
| B-27 | P1 (Play Store) | Repetir la prueba en celular real en **otros modelos** (en el Redmi ya se probó todo, incluidos subir un PDF y un audio, abrir PDFs y cifrados, corte de red y login con Google) | S | `PLAY_STORE.md` §1 | 🔑 otro dispositivo |
| B-28 | P2 (Play Store) | Ícono propio (512 × 512), imagen destacada, capturas y descripciones de la ficha | M | `PLAY_STORE.md` §5 | 🔑 diseño |
| B-32 | P1 (uso en vivo) | **Notificaciones push (FCM)** para que el sonidista reciba el aviso de un pedido con la app en segundo plano o la pantalla apagada. Dos caminos: (a) plan **Blaze** + una Cloud Function que se dispare al crear un pedido (decisión del dueño del 27-oct-2026: cuando se pague Blaze); (b) **sin Blaze**, con el servidor de Cloudflare ya escrito (`worker/`): cada sonidista registra su token de FCM en D1 por sala, la app de quien manda el pedido llama a `/notificar` con su token de Firebase y el Worker envía por FCM v1 con una cuenta de servicio guardada como secreto. En los dos hace falta `firebase_messaging` en la app, el permiso de notificaciones de Android 13 y un canal de notificación; ninguno se puede probar sin las cuentas del dueño (12-nov-2026: no se escribió código). Alternativa gratis evaluada: servicio de primer plano de Android (más batería, menos confiable con pantalla bloqueada) | M | `CONTEXTO_PARA_IA.md` ítem 40 | 🔑 plan Blaze o cuenta de Cloudflare + cuenta de servicio |
| B-33 | P1 (costos) | **Costos, Fase 0** (parcial: topes y tamaño por archivo hechos en la rama `desarrollo`): faltan las alertas de presupuesto y confirmar planes y cuotas reales | S–M | `PLAN_COSTOS.md` §5 | 🔑 consolas y topes |
| B-34 | P1 (costos) | **Costos, Fase 1**: cuotas por cuenta (gratis / Pro con `esPro`) aplicadas en el servidor | M–L | `PLAN_COSTOS.md` §5 | 🔑 definir cuotas |
| B-35 | P2 (costos) | **Costos, Fase 2**: audio a ≈ 128 kbps al subir. Hecho en la web (MP3 ≤ 192 kbps) y en Android (AAC 128 kbps, rama `desarrollo`, probado en un celular). Falta: oír la calidad, WAV de 24 bits, mostrar el tamaño estimado antes de subir, y decidir si se comprime también lo ya subido | S | `PLAN_COSTOS.md` §5 | 🔑 aprobar calidad |
| B-36 | P1 (costos) | **Costos, Fase 3** (código y pruebas hechos en `worker/` y `ArchivosR2`; falta desplegar y compilar con `R2_WORKER_URL`): almacenamiento sin cargo por descarga; convive con Supabase por `storageProvider` | L | `PLAN_COSTOS.md` §5 | 🔑 cuenta de Cloudflare |
| B-37 | P2 (costos) | **Costos, Fase 4** (código y pruebas hechos en `worker/` y la app; falta desplegar R2 y D1): dedupe por hash con conteo de referencias; faltan los términos de uso | L | `PLAN_COSTOS.md` §5 | 🔑 términos y derechos de autor |
| B-38 | P2 (costos) | **Costos, Fase 5**: ciclo de vida (huérfanos, archivos sin uso, salas y pedidos viejos) | M | `PLAN_COSTOS.md` §5 | plan Blaze 🔑 |
| B-39 | P2 (costos) | **Costos, Fase 6**: auditar y poner tope a las escuchas de Firestore, presencia, región (ver B-16) | M | `PLAN_COSTOS.md` §5 | 🔑 región |
| B-40 | P3 (costos) | **Costos, Fase 7**: reparto de archivos dentro de la sala por red local (Nearby, Android) | L | `PLAN_COSTOS.md` §5 | — |
| B-41 | P2 (costos) | **Costos, Fase 8**: planes y cobro (Google Play Billing y medio de pago local, precios por país) | L | `PLAN_COSTOS.md` §5 | 🔑 precios y cobro |
| B-42 | P3 (producto) | **Bibliotecas de grupo por invitación** (banda o iglesia): comparten canciones entre integrantes, sin buscador público; límite de integrantes, invitaciones que vencen, botón de denuncia. Antes: términos de uso y proceso de retiro | L | Conversación del 12-nov-2026 | 🔑 revisión legal |
| B-43 | P3 (producto) | **Biblioteca abierta solo con contenido autorizado** (canciones propias, de dominio público o cedidas por escrito); validador de acordes con sugerencias; cifrado guardado como texto | L | Conversación del 12-nov-2026 | 🔑 abogado y acuerdos con autores |
| B-44 | P1 (producto) | **App para iPhone**: carpeta `frontend/ios` generada (bundle `com.soundcheckpro.app`) y compilación de prueba en GitHub (`ios.yml`, sin firmar), todavía sin correr. Falta 🔑: cuenta de Apple Developer (99 USD/año), registrar la app iOS en Firebase (`GoogleService-Info.plist` y `FirebaseOptions` de iOS: hoy se usa el de la web), URL scheme de Google Sign-In, y firmar/subir a TestFlight (Codemagic o una Mac). Sin tono ni compresor de audio en iOS (son de Android), sin "Compartir hacia la app" (haría falta una Share Extension) y el audio se limita a 30 MB | L | Pedido del 13-nov-2026 | 🔑 cuenta Apple |
| B-24 | P3 | DF-06: ortografía de acordes según la tonalidad (`Eb` en vez de `D#`) | S | `DEFECTOS.md` | — |

## Hecho (resumen)
- Usabilidad Etapas 1 y 3 (validaciones en línea, errores entendibles, deshacer, confirmación de salida, textos ≥ 14 px, tooltips).
- Testing Etapas 0, 1 y 2: requisitos, defectos, 100 pruebas, CI con control previo; corregidos DF-01, 02, 03, 05, 07.
- Calidad (estándares) Etapas 0–7 en lo que no depende de terceros: ver `AUDITORIA_CALIDAD_ESTANDARES.md` §6.
- Rama `desarrollo` (nov-2026, sin publicar): recibir PDF/cifrados desde otras apps en Android, compartir sala con QR, revisor de acordes, importar/exportar canciones, desplazamiento automático y pedal Bluetooth, primera vez guiada y estados vacíos con ayuda (B-15), web instalable, registro de fallas con Crashlytics, cambio de tono de las secuencias en Android (probado en celular; falta confirmarlo de oído), pruebas de reglas con el emulador. Detalle en `CHANGELOG.md` y `CONTEXTO_PARA_IA.md` ítem 50.

## Retrospectivas
_(copiar la plantilla de `PROCESO.md` §3 al cerrar cada sprint)_
