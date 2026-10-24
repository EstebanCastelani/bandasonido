# Requisitos verificables — Sound Check Pro

Documento de la **Etapa 0** del plan de testing (`AUDITORIA_TESTING.md`): qué debe hacer el sistema, con un criterio de aceptación que se pueda comprobar. Cada requisito se vincula con los casos de prueba (CP-xx) de la auditoría y, cuando existe, con las pruebas automáticas de `frontend/test/`.

Estado de cada requisito: **Definido** (hay criterio claro) · **Decisión pendiente** (hay una pregunta del negocio sin responder; ver sección 2).

## 1. Requisitos

### Salas y acceso
| ID | Requisito | Criterio de aceptación | Casos | Estado |
|---|---|---|---|---|
| RQ-01 | Crear una sala | Con nombre y rol (ambos obligatorios) se genera un código de 8 caracteres de los alfabetos `2-9` y `A-Z` sin `0/1/O/I/L`, y la persona entra a la sala; el título muestra "Nombre (Rol)". Si falta un dato se marca debajo del campo y no se entra. | CP-01, CP-02 · `generarCodigoSala` | Definido |
| RQ-02 | Unirse a una sala | Exige código de **exactamente 8 caracteres**, nombre y rol; cada error se muestra bajo su campo; Enter envía el formulario. | CP-03 | Definido |
| RQ-03 | Unirse a una sala que no existe | **Ver decisión D-03.** | CP-04 | Decisión pendiente |
| RQ-04 | Rol de sonido entra al panel del sonidista | **Ver decisión D-04.** Hoy: si el rol escrito contiene una palabra clave de sonido, la persona entra directo al panel (sin pasar por la pantalla de pedidos). | CP-05, CP-06, CP-07 · `esRolSonidista` | Decisión pendiente |
| RQ-17 | Salir de la sala | Pide confirmación; "Cancelar" permanece en la sala; "Salir" vuelve al menú principal y borra los datos de la sala guardados en el dispositivo. | CP-15 | Definido |

### Pedidos
| ID | Requisito | Criterio de aceptación | Casos | Estado |
|---|---|---|---|---|
| RQ-09 | Enviar pedidos | Un pedido rápido, uno personalizado o uno urgente se envía con un toque/Enter, aparece en "Mis últimos pedidos" y llega al panel del sonidista con nombre y rol, en tiempo real. El urgente se distingue por ícono y color. | CP-08, CP-09, CP-34 | Definido (tiempo máximo en RQ-19) |
| RQ-10 | Atender pedidos (sonidista) | Puede marcar atendido (pasa a Historial), responder en privado (se ve bajo el pedido del músico), agrupar por rol, borrar un pedido con **Deshacer** y "Borrar todo" con confirmación. | CP-10, CP-11, CP-14 | Definido; el comportamiento de Deshacer en conflicto: **D-07** |
| RQ-07 | Deshacer sin pisar cambios ajenos | **Ver decisión D-07.** | CP-12 | Decisión pendiente |
| RQ-08 | Cuántos pedidos se conservan y se muestran | **Ver decisión D-08.** | CP-35 | Decisión pendiente |

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
| RQ-05 | Notación latina (Do-Re-Mi) | **Ver decisión D-05.** | CP-23 | Decisión pendiente |
| RQ-15 | Secuencias | Se suben pistas de audio; si pesan más de 50 MB y se sube desde la web, se convierten a MP3; se cargan a la sala; se reproducen con tono ±12 semitonos, tempo 50–150 % y volumen 0–100 %, y esos ajustes se sincronizan con toda la sala. | CP-27, CP-29 | Definido |
| RQ-06 | Cambios simultáneos de tono/tempo/volumen | **Ver decisión D-06.** | CP-28 | Decisión pendiente |

### Transversales
| ID | Requisito | Criterio de aceptación | Casos | Estado |
|---|---|---|---|---|
| RQ-16 | Seguridad de datos | Un invitado no accede a frases, repertorio ni secuencias de otra cuenta; nadie puede marcarse `esPro`; cada usuario solo lee su propio perfil; no se pueden borrar perfiles. | CP-30…CP-32 | Definido (sin pruebas aún: Etapa 4) |
| RQ-18 | Errores comprensibles | Ningún mensaje al usuario contiene códigos o nombres técnicos; indica qué pasó y qué hacer; los ingresos ofrecen **Reintentar**. | · `mensajeError` | Definido |
| RQ-19 | Desempeño | A fijar en la Etapa 6 (presupuesto de carga, latencia pedido→panel, lecturas por sesión). Sugerencia inicial: carga interactiva < 4 s en 4G; pedido visible en el panel < 2 s. | CP-33…CP-35 | Decisión pendiente |

## 2. Decisiones del negocio

Cada decisión tiene una **propuesta** con su razonamiento. Hasta que el dueño del producto las confirme, quedan como *propuesta*; las pruebas relacionadas están marcadas con `skip` en `frontend/test/logica_pura_test.dart` y no cambian el comportamiento de la app.

| ID | Pregunta | Propuesta | Por qué | Costo aproximado |
|---|---|---|---|---|
| D-03 | ¿Qué pasa si alguien se une a una sala que no existe? | Al **crear** una sala se guarda un documento `salas/{código}` con la fecha; al **unirse** se comprueba que exista y, si no, se avisa "Esa sala no existe. Revisá el código." | Evita entrar a una sala vacía por un error de tipeo. Hoy la sala no es un documento propio, por lo que no puede validarse. | M (reglas de Firestore + creación + validación) |
| D-04 | ¿Qué palabras identifican a un rol de sonido? ¿"Músico y sonidista" entra al panel? | Lista explícita de palabras **completas** (sonidista, sonido, técnico/ingeniero/operador de sonido o de audio, FOH, monitorista, sound, audio engineer). Si el rol también nombra a otra función ("músico y sonidista"), **preguntar**: "¿Entrar como sonidista?". Sacar la coincidencia por fragmentos ("de som"). | Corrige el falso positivo "Vocalista de Somos Mil" y los falsos negativos "FOH"/"Ingeniero de audio" sin quitar libertad al texto. | S |
| D-05 | ¿Se soporta Do-Re-Mi? ¿Qué hacer con acordes no reconocidos? | **Sí:** transponer Do, Re, Mi, Fa, Sol, La, Si (con `#`/`b`, `m` y sufijos) conservando la notación del texto original. Si **ningún** acorde se pudo transponer, mostrar el aviso "No se encontraron acordes para transponer". | Es la notación habitual en el público objetivo; hoy falla en silencio. | M |
| D-06 | Si dos personas cambian el tono a la vez, ¿qué pasa? | **Gana el último en escribir** (comportamiento actual) y se muestra quién hizo el último cambio. | Es simple, predecible y suficiente para una banda; evita bloqueos. | S |
| D-07 | Si un pedido se borró y otro sonidista ya lo había cambiado, ¿"Deshacer" qué restaura? | Antes de borrar, **leer el documento actual** (no la copia de la pantalla) y restaurar esa versión; si el pedido ya fue recreado por otro, no sobrescribir. Si el pedido ya no existe al intentar atenderlo, avisar "Ese pedido ya no existe". | Evita revertir cambios ajenos y errores sin mensaje. | S |
| D-08 | ¿Cuántos pedidos se conservan/muestran? | Mostrar los **últimos 200** de la sala y conservar 24 h (limpieza automática o manual con "Borrar todo"). | Acota las lecturas por dispositivo (hoy no hay tope). | M |

## 3. Definición de "hecho" (para cualquier cambio)

Un cambio está **hecho** cuando:
1. `flutter analyze --no-fatal-infos` termina sin errores ni warnings.
2. `flutter test` pasa (los casos `skip` deben seguir documentando un defecto abierto en `DEFECTOS.md`).
3. Si cambia o agrega una regla de negocio, hay al menos una prueba nueva (o un caso manual en `AUDITORIA_TESTING.md` §4.2) con su requisito RQ-xx.
4. Si agrega textos, están en los 5 idiomas (`lib/l10n/app_XX.arb`).
5. Se probó a mano el flujo afectado en un navegador y el resultado quedó anotado en el mensaje del commit o en el documento correspondiente.
6. `CONTEXTO_PARA_IA.md` refleja el cambio si afecta a la arquitectura o a una decisión.

La CI (`.github/workflows/deploy.yml`) hace cumplir los puntos 1 y 2 antes de publicar.
