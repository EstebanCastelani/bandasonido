# Requisitos verificables — Sound Check Pro

Documento de la **Etapa 0** del plan de testing (`AUDITORIA_TESTING.md`): qué debe hacer el sistema, con un criterio de aceptación que se pueda comprobar. Cada requisito se vincula con los casos de prueba (CP-xx) de la auditoría y, cuando existe, con las pruebas automáticas de `frontend/test/`.

Estado de cada requisito: **Definido** (hay criterio claro) · **Decisión pendiente** (hay una pregunta del negocio sin responder; ver sección 2).

## 1. Requisitos

### Salas y acceso
| ID | Requisito | Criterio de aceptación | Casos | Estado |
|---|---|---|---|---|
| RQ-01 | Crear una sala | Con nombre y rol (ambos obligatorios) se genera un código de 8 caracteres de los alfabetos `2-9` y `A-Z` sin `0/1/O/I/L`, y la persona entra a la sala; el título muestra "Nombre (Rol)". Si falta un dato se marca debajo del campo y no se entra. | CP-01, CP-02 · `generarCodigoSala` | Definido |
| RQ-02 | Unirse a una sala | Exige código de **exactamente 8 caracteres**, nombre y rol; cada error se muestra bajo su campo; Enter envía el formulario. Un enlace `…/bandasonido/?sala=CÓDIGO` abre "Unirme a sala" con el código cargado, y al crear una sala se puede compartir ese enlace. | CP-03 | Definido |
| RQ-03 | Unirse a una sala que no existe | **Ver decisión D-03.** | CP-04 | Decisión pendiente (D-03 no aplicada) |
| RQ-04 | Rol de sonido entra al panel del sonidista | **Ver decisión D-04.** Hoy: si el rol escrito contiene una palabra clave de sonido, la persona entra directo al panel (sin pasar por la pantalla de pedidos). | CP-05, CP-06, CP-07 · `esRolSonidista` | Definido (D-04); un rol mixto ("músico y sonidista") elige a dónde entrar |
| RQ-17 | Salir de la sala | Pide confirmación; "Cancelar" permanece en la sala; "Salir" vuelve al menú principal y borra los datos de la sala guardados en el dispositivo. | CP-15 | Definido |

### Pedidos
| ID | Requisito | Criterio de aceptación | Casos | Estado |
|---|---|---|---|---|
| RQ-09 | Enviar pedidos | Un pedido rápido, uno personalizado o uno urgente se envía con un toque/Enter, aparece en "Mis últimos pedidos" y llega al panel del sonidista con nombre y rol, en tiempo real. El urgente se distingue por ícono y color. | CP-08, CP-09, CP-34 | Definido (tiempo máximo en RQ-19) |
| RQ-10 | Atender pedidos (sonidista) | Puede marcar atendido (pasa a Historial), responder en privado (se ve bajo el pedido del músico), agrupar por rol, borrar un pedido con **Deshacer** y "Borrar todo" con confirmación. | CP-10, CP-11, CP-14 | Definido; el comportamiento de Deshacer en conflicto: **D-07** |
| RQ-07 | Deshacer sin pisar cambios ajenos | **Ver decisión D-07.** | CP-12 | Definido (D-07) |
| RQ-08 | Cuántos pedidos se conservan y se muestran | **Ver decisión D-08.** | CP-35 | Parcial (D-08) |

### Idioma y apariencia
| ID | Requisito | Criterio de aceptación | Casos | Estado |
|---|---|---|---|---|
| RQ-11 | Idioma | Idiomas: es, en, pt, fr, it. Sin elección manual se usa el idioma del dispositivo (mismo idioma, sin importar la región); si no está soportado, **español**. La elección manual se guarda y se respeta; un idioma guardado que ya no existe vuelve a seguir al dispositivo. Los textos de una pantalla no se mezclan entre idiomas. | CP-16…CP-19 · `IdiomasApp.resolver`, `rolParaMostrar` | Definido |
| RQ-12 | Paletas y modo claro/oscuro | El modo claro/oscuro es independiente de la paleta, se guarda y solo cambia con el botón sol/luna; "Escenario" tiene versión clara; una clave de paleta desconocida usa la paleta por defecto. | CP-20 · `AppPalette.porClave` | Definido |

### Setlist, cifrado y secuencias
| ID | Requisito | Criterio de aceptación | Casos | Estado |
|---|---|---|---|---|
| RQ-13 | Setlist | Los temas tienen estado `pendiente`, `pausado` o `tocado`; se pueden agregar desde la biblioteca propia o buscando en las de la sala; se puede exportar/compartir. | (sin casos aún) | Definido |
| RQ-14 | Transposición de cifrado | Transponer ±N semitonos cambia solo los acordes, conserva sufijos y bajos (`A7/C#`), respeta bemoles/sostenidos de entrada, `±12` deja el texto igual, ir y volver devuelve el original. Notación latina: **ver D-05.** | CP-22…CP-26 · `ChordTransposer` | Definido (D-05 para Do-Re-Mi) |
| RQ-05 | Notación latina (Do-Re-Mi) | **Ver decisión D-05.** | CP-23 | Definido (D-05) |
| RQ-15 | Secuencias | Se suben pistas de audio; si pesan más de 50 MB y se sube desde la web, se convierten a MP3; se cargan a la sala; se reproducen con tono ±12 semitonos, tempo 50–150 % y volumen 0–100 %, y esos ajustes se sincronizan con toda la sala. | CP-27, CP-29 | Definido |
| RQ-06 | Cambios simultáneos de tono/tempo/volumen | **Ver decisión D-06.** | CP-28 | Definido (D-06): gana el último y se muestra quién ajustó |

### Transversales
| ID | Requisito | Criterio de aceptación | Casos | Estado |
|---|---|---|---|---|
| RQ-16 | Seguridad de datos | Un invitado no accede a frases, repertorio ni secuencias de otra cuenta; nadie puede marcarse `esPro`; cada usuario solo lee su propio perfil; no se pueden borrar perfiles. | CP-30…CP-32 | Definido (sin pruebas aún: Etapa 4) |
| RQ-18 | Errores comprensibles | Ningún mensaje al usuario contiene códigos o nombres técnicos; indica qué pasó y qué hacer; los ingresos ofrecen **Reintentar**. | · `mensajeError` | Definido |
| RQ-19 | Desempeño | A fijar en la Etapa 6 (presupuesto de carga, latencia pedido→panel, lecturas por sesión). Sugerencia inicial: carga interactiva < 4 s en 4G; pedido visible en el panel < 2 s. | CP-33…CP-35 | Decisión pendiente |

### Calidad del producto (atributos no funcionales)
Surgen de `AUDITORIA_CALIDAD_ESTANDARES.md`. Las medidas objetivo de la columna "Criterio" son **propuestas** hasta que el dueño del producto las valide (ver §3 de esa auditoría).

| ID | Requisito | Criterio de aceptación | Casos / pruebas | Estado |
|---|---|---|---|---|
| RQ-20 | Envío fiable de pedidos (disponibilidad) | "Enviado" se muestra **solo** cuando el servidor confirmó. Si en 4 s no hay confirmación se avisa que el pedido quedó en cola y se enviará al volver la red; si falla se ofrece "Reintentar". Si se pierde la conexión con datos ya recibidos se muestra un aviso fijo "Sin conexión". | `esperarEnvio`, `mostrarAvisoSinConexion` (pruebas); falta probar con la red realmente cortada | Definido; **sin verificar con red cortada** |
| RQ-21 | Límites de entrada | Un pedido escrito a mano admite hasta 200 caracteres; el panel del sonidista muestra hasta 200 pedidos por lista. Las reglas de Firestore todavía no validan el tamaño (pendiente, ver `OPERACION.md` §6) | `kMaxCaracteresPedido`, `kMaximoPedidosVisibles` | Parcial |
| RQ-22 | Arranque independiente del visor de PDF | Si el CDN de pdf.js no responde, la app arranca igual y solo los PDFs no abren | Revisión de `index.html` (no hay prueba automática) | Definido |
| RQ-23 | Versionado y vuelta atrás | La versión de `pubspec.yaml` coincide con `kVersionApp` y se ve en Configuración; cada versión publicada tiene un tag `vX.Y.Z` y una entrada en `CHANGELOG.md`; se puede volver a un tag en ≤ 15 min (`OPERACION.md` §2) | Prueba de versión; rollback **sin ensayar** | Parcial (falta el primer tag y ensayar el rollback) |
| RQ-24 | Atributos con criterio medible | Cada atributo (disponibilidad, rendimiento, escalabilidad, seguridad, desplegabilidad, modificabilidad, interoperabilidad, testeabilidad, usabilidad) tiene un escenario con medida en la §3 de la auditoría de calidad | — | Propuesto; pendiente de validar |
| RQ-25 | Seguridad frente a abuso | App Check exigido y reglas que validan forma y tamaño de los pedidos | Pruebas de reglas (pendientes) | **Pendiente** (🔑 clave de App Check, ver `BACKLOG.md` B-01/B-02) |
| RQ-26 | Calidad del código | El código propio está formateado de forma uniforme (verificado en la CI), `flutter analyze` sin errores ni warnings, y el repositorio contiene solo el producto | CI | Definido |
| RQ-27 | Disponibilidad en vivo (Android) | Las secuencias de la sala se guardan en el celular apenas aparecen en la lista: tocar "play" empieza a sonar en ≤ 1 s y sigue sonando si se corta la red. En web no aplica | Prueba en celular + pruebas unitarias de la caché | Definido |
| RQ-28 | Privacidad (Google Play) | Una persona con cuenta puede **eliminar su cuenta y sus datos desde la app** (perfil, frases, repertorio, secuencias y sus archivos, historial de salas y cuenta de acceso), previa reconfirmación de identidad y confirmación final | Pruebas unitarias de la lógica + prueba manual con una cuenta de prueba | Definido |
| RQ-29 | Adaptación a pantallas | La app se puede usar en celulares chicos y grandes, en vertical y horizontal, con letra grande del sistema y en tablets: nada se corta ni se vuelve inalcanzable, y en pantallas anchas el contenido se centra | Prueba en celular real simulando tamaños (`wm size/density`, `font_scale`, rotación) | Definido |
| RQ-30 | Uso en vivo | (a) El sonidista configura cómo le avisa un pedido (sonido, volumen, vibración, destello rojo en urgentes); (b) responde con un toque a respuestas rápidas y el músico ve si su pedido fue enviado, visto o atendido; (c) modo show: pantalla oscura que ignora los toques y no deja salir con "atrás" hasta mantener apretado el candado; (d) los PDF del setlist de la sala se guardan en el celular y se abren sin red, con aviso "Sin conexión: X de Y temas listos"; los cifrados (texto) quedan guardados por Firestore | Prueba en celular real + pruebas unitarias | Implementado |
| RQ-31 | Paridad Android / web | Las funciones de uso en vivo existen en las dos versiones; lo que ayuda sin conexión (setlist y cifrados, PDF del setlist y secuencias de la sala guardados en el dispositivo) también anda en el navegador. Quedan solo diferencias que impone la plataforma (vibración, botón "atrás") | Prueba en el navegador y en el celular | Implementado |

## 2. Decisiones del negocio

Cada decisión tiene una **propuesta** con su razonamiento. Estado al 24-oct-2026: el dueño del producto pidió corregir todo lo necesario, así que se aplicaron **D-04, D-05, D-06 y D-07 tal como estaban propuestas, y D-08 en parte**. **D-03 no se aplicó** (ver la tabla).

| ID | Pregunta | Propuesta | Por qué | Costo aproximado |
|---|---|---|---|---|
| D-03 **(NO aplicada)** | ¿Qué pasa si alguien se une a una sala que no existe? | Al **crear** una sala se guarda un documento `salas/{código}` con la fecha; al **unirse** se comprueba que exista y, si no, se avisa "Esa sala no existe. Revisá el código." | Evita entrar a una sala vacía por un error de tipeo. Hoy la sala no es un documento propio, por lo que no puede validarse. | M (reglas de Firestore + creación + validación). **No se hizo:** exige cambiar y publicar las reglas de producción y migrar las salas ya existentes (no tienen ese documento y nadie podría unirse a ellas). Requiere autorización explícita |
| D-04 **(aplicada)** | ¿Qué palabras identifican a un rol de sonido? ¿"Músico y sonidista" entra al panel? | Lista explícita de palabras **completas** (sonidista, sonido, técnico/ingeniero/operador de sonido o de audio, FOH, monitorista, sound, audio engineer). Si el rol también nombra a otra función ("músico y sonidista"), **preguntar**: "¿Entrar como sonidista?". Sacar la coincidencia por fragmentos ("de som"). | Corrige el falso positivo "Vocalista de Somos Mil" y los falsos negativos "FOH"/"Ingeniero de audio" sin quitar libertad al texto. | S |
| D-05 **(aplicada)** | ¿Se soporta Do-Re-Mi? ¿Qué hacer con acordes no reconocidos? | **Sí:** transponer Do, Re, Mi, Fa, Sol, La, Si (con `#`/`b`, `m` y sufijos) conservando la notación del texto original. Si **ningún** acorde se pudo transponer, mostrar el aviso "No se encontraron acordes para transponer". | Es la notación habitual en el público objetivo; hoy falla en silencio. | M |
| D-06 **(aplicada)** | Si dos personas cambian el tono a la vez, ¿qué pasa? | **Gana el último en escribir** (comportamiento actual) y se muestra quién hizo el último cambio. | Es simple, predecible y suficiente para una banda; evita bloqueos. | S |
| D-07 **(aplicada)** | Si un pedido se borró y otro sonidista ya lo había cambiado, ¿"Deshacer" qué restaura? | Antes de borrar, **leer el documento actual** (no la copia de la pantalla) y restaurar esa versión; si el pedido ya fue recreado por otro, no sobrescribir. Si el pedido ya no existe al intentar atenderlo, avisar "Ese pedido ya no existe". | Evita revertir cambios ajenos y errores sin mensaje. | S |
| D-08 **(parcial)** | ¿Cuántos pedidos se conservan/muestran? | Mostrar los **últimos 200** de la sala y conservar 24 h (limpieza automática o manual con "Borrar todo"). | Acota las lecturas por dispositivo (hoy no hay tope). | M. **Hecho:** tope de 200 en las dos listas en vivo del panel del sonidista. **No hecho:** la conservación de 24 h (necesita una tarea en el servidor) ni el tope del Historial (la consulta de atendidos no tiene orden y agregarlo exige un índice nuevo en Firestore) |

## 3. Definición de "hecho" (para cualquier cambio)

Un cambio está **hecho** cuando:
1. `flutter analyze --no-fatal-infos` termina sin errores ni warnings.
2. `flutter test` pasa (los casos `skip` deben seguir documentando un defecto abierto en `DEFECTOS.md`).
3. Si cambia o agrega una regla de negocio, hay al menos una prueba nueva (o un caso manual en `AUDITORIA_TESTING.md` §4.2) con su requisito RQ-xx.
4. Si agrega textos, están en los 5 idiomas (`lib/l10n/app_XX.arb`).
5. Se probó a mano el flujo afectado en un navegador y el resultado quedó anotado en el mensaje del commit o en el documento correspondiente.
6. `CONTEXTO_PARA_IA.md` refleja el cambio si afecta a la arquitectura o a una decisión.

La CI (`.github/workflows/deploy.yml`) hace cumplir los puntos 1 y 2 antes de publicar.
