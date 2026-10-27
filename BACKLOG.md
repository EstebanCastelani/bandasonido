# Backlog del producto

Fuente única de pendientes (reúne los planes de `AUDITORIA_USABILIDAD.md`, `AUDITORIA_TESTING.md` y `AUDITORIA_CALIDAD_ESTANDARES.md`). Prioridad: **P1** en el uso en vivo / riesgo alto · **P2** importante · **P3** mejora. Esfuerzo: S ≈ medio día · M ≈ 1–2 días · L ≈ 3+ días. 🔑 = necesita una acción o decisión del dueño (cuentas, claves, permisos). Se prioriza por la regla de la clase: primero lo que daña el uso real, después lo demás.

## En curso
_(vacío — elegir 3–5 ítems al comenzar cada sprint, ver `PROCESO.md`)_

## Pendientes

| ID | Prioridad | Ítem | Esf. | Origen | Bloqueo |
|---|---|---|---|---|---|
| B-01 | P1 | Activar **App Check** (clave reCAPTCHA) y exigirlo tras un período en modo monitor | M | Calidad E3 · Q3 | 🔑 clave y cuenta de Firebase |
| B-02 | P1 | Publicar la validación de pedidos en las reglas de Firestore (propuesta en `OPERACION.md` §6) **después** de probarla con el emulador | M | Calidad E3 · Q3 | B-10 |
| B-03 | P1 | Medir la **latencia pedido→panel** y la carga con red 4G simulada; fijar el presupuesto | M | Calidad E4 · Q7 | — |
| B-04 | P1 | Aviso de "sin conexión" también en el **panel del sonidista** | S | Calidad E1 · Q1 | — |
| B-05 | P1 | Probar con **dos sonidistas** a la vez (atender/borrar/deshacer el mismo pedido) | M | Testing E5 · DF-05 | — |
| B-06 | P1 | Decidir **D-03**: validar que la sala exista al unirse (reglas + migrar salas existentes) | M | Testing · DF-04 | 🔑 decisión |
| B-07 | P2 | Publicar el primer tag `v1.1.0` y **ensayar el rollback** (`OPERACION.md` §2) | S | Calidad E2 · Q4 | tras el próximo despliegue en verde |
| B-08 | P2 | Pruebas de **reglas de seguridad** con el emulador de Firebase | M | Testing E4 · T9 | — |
| B-09 | P2 | Pruebas de **pantallas** con Firebase simulado (formularios, deshacer, salir) | L | Testing E3 · T13 | — |
| B-10 | P2 | Inventario de planes y cuotas de Firebase y Supabase (¿se pausa por inactividad?) | S | Calidad E1 · Q2 | 🔑 acceso a las consolas |
| B-11 | P2 | Android: activar el trabajo de CI (secreto + variable) y crear el **keystore** de release | M | Calidad E2 · Q5 | 🔑 |
| B-12 | P2 | Protección de la rama `main` (PR + CI obligatoria) | S | Calidad E7 · Q10 | 🔑 administración del repo |
| B-13 | P2 | Usabilidad E0: línea base (tiempos reales, éxito, SUS con 5 personas) | M | Usabilidad E0 | — |
| B-14 | P2 | Usabilidad E2: ingreso más rápido (nombre/rol precargados, chips de rol, Enter) | M | Usabilidad E2 · H8 | — |
| B-15 | P2 | Usabilidad E4: estados vacíos con guía y carga con indicador propio en `index.html` | S–M | Usabilidad E4 · H9 | — |
| B-16 | P2 | Tope y paginación del **Historial** y de otras listas en vivo (requiere un índice nuevo en Firestore) | M | Calidad E4 · DF-08 | 🔑 índice |
| B-17 | P2 | Accesibilidad: contraste de las 6 paletas, escala de texto 150 %, lector de pantalla | M | Usabilidad E6 | — |
| B-18 | P3 | Actualizar dependencias mayores **una por una** (Firebase 5→7, Syncfusion 28→35, `file_picker`, `google_sign_in`…) | L | Calidad E3 · `OPERACION.md` §4 | prueba en celular |
| B-19 | P3 | Copiar `pdf.js` (y opcionalmente CanvasKit) al proyecto para no depender de CDN externos | S–M | Calidad E1 · Q2 | 🔑 aprobar la descarga |
| B-20 | P3 | Dividir `main.dart` por dominio (propuesta en `AUDITORIA_CALIDAD_ESTANDARES.md` §5) | L | Calidad E5 · Q8 | 🔑 aprobar (hoy la regla es "todo en `main.dart`") |
| B-21 | P3 | Exportar/importar repertorio y setlist en formatos abiertos (ChordPro, JSON/CSV) | M | Calidad E6 · Q13 | 🔑 decidir formato |
| B-22 | P3 | Ayuda y primera vez guiada; guía de estilo de textos (voseo/neutro, mayúsculas) | M | Usabilidad E5 | 🔑 decidir registro |
| B-23 | P3 | Conservación de pedidos por 24 h (limpieza automática en el servidor) | M | Testing · D-08 | plan Blaze 🔑 |
| B-26 | P2 (Play Store) | Archivos de usuarios en bucket **público** de Supabase: decidir si pasan a privados con enlaces firmados | M | `PLAY_STORE.md` §7 | 🔑 decisión |
| B-27 | P1 (Play Store) | Repetir la prueba en celular real en **otros modelos** (en el Redmi ya se probó todo, incluidos subir un PDF y un audio, abrir PDFs y cifrados, corte de red y login con Google) | S | `PLAY_STORE.md` §1 | 🔑 otro dispositivo |
| B-28 | P2 (Play Store) | Ícono propio (512 × 512), imagen destacada, capturas y descripciones de la ficha | M | `PLAY_STORE.md` §5 | 🔑 diseño |
| B-32 | P1 (uso en vivo) | **Notificaciones push (FCM)** para que el sonidista reciba el aviso de un pedido con la app en segundo plano o la pantalla apagada. Requiere pasar el proyecto `appbandasonido` al **plan Blaze** (Cloud Functions) y una función que se dispare al crear un pedido. Decisión del dueño (27-oct-2026): se hace cuando se pague Blaze. Alternativa gratis evaluada: servicio de primer plano de Android (más batería, menos confiable con pantalla bloqueada) | M | `CONTEXTO_PARA_IA.md` ítem 40 | 🔑 plan Blaze |
| B-24 | P3 | DF-06: ortografía de acordes según la tonalidad (`Eb` en vez de `D#`) | S | `DEFECTOS.md` | — |

## Hecho (resumen)
- Usabilidad Etapas 1 y 3 (validaciones en línea, errores entendibles, deshacer, confirmación de salida, textos ≥ 14 px, tooltips).
- Testing Etapas 0, 1 y 2: requisitos, defectos, 100 pruebas, CI con control previo; corregidos DF-01, 02, 03, 05, 07.
- Calidad (estándares) Etapas 0–7 en lo que no depende de terceros: ver `AUDITORIA_CALIDAD_ESTANDARES.md` §6.

## Retrospectivas
_(copiar la plantilla de `PROCESO.md` §3 al cerrar cada sprint)_
