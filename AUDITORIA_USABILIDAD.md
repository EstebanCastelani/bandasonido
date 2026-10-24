# Auditoría de usabilidad e interacción — Sound Check Pro

Base teórica: *Calidad de uso — ISO 9241 / IxD (CyS clase 4, 2026)*.
Fecha de la auditoría: 24-oct-2026. Código auditado: `frontend/lib/main.dart` en el commit `12944d4` (web publicada), más las pruebas en navegador de esa misma versión.

> Alcance y límites: es una **auditoría de experto** (inspección de código + recorrido en navegador de escritorio). No hubo pruebas con usuarios reales, ni en celular, ni en Android; los tiempos KLM son estimaciones con los tiempos estándar de la clase. La diapositiva de las heurísticas de Nielsen es una imagen dentro del PDF, así que usé la lista estándar de las 10 heurísticas.

---

## 1. Reglas y criterios extraídos de la clase

### 1.1 Diseño centrado en el humano (ISO 13407 → ISO 9241-210)
- El foco pasó de "usuario" a **persona**: también cuentan quienes se ven afectados por el uso sin ser usuarios finales (en esta app: el sonidista que recibe los pedidos, el resto de la banda en la sala).
- La ISO 9241-210 amplió el foco **de la usabilidad a la experiencia de usuario**. La UX surge de la unión de: necesidades del usuario + tecnología + objetivos del negocio.
- Objetivos del enfoque: efectividad, eficiencia, bienestar, satisfacción, **accesibilidad y sostenibilidad**; y evitar efectos adversos en salud, seguridad y rendimiento.
- Principios de proceso: (1) entender explícitamente usuarios, tareas y ambientes; (2) involucrar usuarios durante el diseño; (3) diseño **impulsado y refinado por evaluación centrada en el usuario**; (4) proceso **iterativo**; (5) contemplar la **experiencia completa**; (6) equipo multidisciplinario.
- "Lo que no se puede medir, no se puede mejorar" (Drucker): la usabilidad es un atributo medible.

### 1.2 Definición de usabilidad (ISO 9241-11)
"La **efectividad**, la **eficiencia** y la **satisfacción** con la cual usuarios específicos logran metas específicas en un ambiente particular."
- **Efectividad:** exactitud y completitud con que se logra la meta.
- **Eficiencia:** recursos consumidos (tiempo, esfuerzo) respecto de la exactitud y completitud.
- **Satisfacción:** comodidad y aceptabilidad para usuarios y personas afectadas.
- La norma dice *qué* tener en cuenta, no *cómo* diseñar ni cómo evaluar.

### 1.3 Diseño de interacción (IxD): las 4 dimensiones
1. **Palabras:** sencillas de entender y que permitan la interacción.
2. **Representaciones visuales:** cada gráfico/icono con fundamento, **no como decoración** (se vincula con las heurísticas de Nielsen).
3. **Espacio:** con qué interactúa la persona en el mundo real (mouse, teclado, pantalla táctil, el dedo).
4. **Tiempo:** cuánto dura la interacción con palabras, visuales y espacio.
- El IxD define cómo responde la interfaz a las acciones y establece flujos y puntos de contacto.

### 1.4 Leyes y modelos cuantitativos
- **Ley de Fitts:** el tiempo para alcanzar un objetivo crece con la distancia y decrece con el tamaño del objetivo → controles importantes, **grandes y cerca** del punto de partida.
- **KLM-GOMS:** costo en segundos de operaciones físicas y mentales. Tiempos de la clase: tecla 0,2 s · cambio mouse↔teclado 0,4 s · apuntar 1,1 s · preparación mental 1,35 s · respuesta del sistema (variable). Ejemplo de la clase: partir un formulario en una parte esencial + otra opcional bajó de 122 s a 52 s. "Siempre alguien paga el tiempo del usuario."
- **Ley de Hick-Hyman:** más opciones → mayor tiempo de decisión.
- **Técnicas de observación:** mapas de calor (clic, scroll, mouse, mirada) y eye-tracking para ver dónde mira/toca la gente.

### 1.5 Heurísticas de Nielsen (lista estándar, referidas en la 2.ª dimensión)
1 Visibilidad del estado · 2 Coincidencia con el mundo real · 3 Control y libertad del usuario · 4 Consistencia y estándares · 5 Prevención de errores · 6 Reconocer antes que recordar · 7 Flexibilidad y eficiencia · 8 Diseño estético y minimalista · 9 Ayudar a reconocer y recuperarse de errores · 10 Ayuda y documentación.

---

## 2. Auditoría del proyecto

Contexto de uso que condiciona todo: el **músico en el escenario** (manos ocupadas, luz baja, mirada de reojo, segundos para pedir "más volumen") y el **sonidista** (mesa, muchas cosas a la vez). Efectividad aquí = que el pedido llegue y se entienda; eficiencia = pocos toques y rápido; satisfacción = confianza de que "me escucharon".

### 2.1 Lo que ya está bien (conservar)
- Pedido rápido de **1 toque** con botones grandes (Fitts) y confirmación visible ("Enviado") + lista "Mis últimos pedidos" (heurística 1).
- Vocabulario del dominio (pedido, consola, retorno, setlist) (heurística 2, dimensión Palabras).
- **Restauración de sesión**: al reabrir la app vuelve a la sala sin escribir nada (KLM mínimo para el usuario recurrente).
- Urgente con icono **y** color (no solo color), parpadeo lento (0,7 s por mitad de ciclo, bajo el umbral de riesgo).
- "Borrar todo" pide confirmación; mensajes de "necesitás iniciar sesión" claros para invitados.
- Entrada directa del sonidista a su panel (reduce pasos y errores de rol).
- 5 idiomas sin mezclas de idioma en pantalla, verificado en navegador.

### 2.2 Hallazgos (ordenados por severidad)

Severidad: **A** = alta (puede hacer fallar la tarea o causar daño), **M** = media, **B** = baja.

| # | Hallazgo (evidencia) | Regla de la clase | Sev. |
|---|---|---|---|
| H1 | **Validaciones mudas.** Si falta el nombre/PIN/rol, el botón "Empezar"/"Unirme" no hace nada y no explica por qué (`main.dart` ~4325, 4535, 9091). Como invitado, el usuario cree que la app se colgó. | Nielsen 1, 5, 9 · Efectividad | **A** |
| H2 | **Errores técnicos crudos al usuario.** `errorAlIngresar(e)`, `errorAlIngresarAlPanel(e)`, `error('${snapshot.error}')` muestran la excepción tal cual (se vio: `[firebase_auth/channel-error] dev.flutter.pigeon…`). Sin salida ni "Reintentar" (~4403, 4613, 9129, 5473, 6283, 7277). | Nielsen 9 · Palabras | **A** |
| H3 | **Borrado sin confirmar ni deshacer** en el panel del sonidista: el ícono de basura está pegado al de "atendido" y borra al primer toque (`d.reference.delete()`, ~9599). Tres íconos de 48 px contiguos (responder / atendido / borrar). | Nielsen 3, 5 · Fitts (objetivos juntos, error costoso) | **A** |
| H4 | **Salir de la sala con un toque.** El ícono de la esquina superior izquierda ejecuta `_cerrarSesion` sin confirmar (`~5235`). En el escenario un toque accidental saca al músico de la sala. Además está rotulado "Cerrar Sesión" y usa el ícono *logout*, pero en realidad **sale de la sala**; el menú principal usa "Cerrar sesión" para la **cuenta**: dos acciones distintas con el mismo nombre. | Nielsen 3, 4 · Palabras | **A** |
| H5 | **Texto minúsculo en el control principal.** Los botones de pedido rápido usan `fontSize: 9` (~5206); también la etiqueta "SALA: XXXX" (9), "MIS ÚLTIMOS PEDIDOS" (9) y mensajes de error (10). 28 usos de fuente ≤ 12. Para alguien de reojo, con luz baja y a distancia de brazo, es ilegible. | Nielsen 8 · Espacio · Accesibilidad (ISO 9241-210) | **A** |
| H6 | **Frases "+" y "−" sin significado.** Entre los 14 pedidos rápidos hay botones que dicen solo "+" y "−" (`AppConstants.pedidosRapidos`, ~321): no está claro *qué* se pide subir/bajar. | Palabras · Nielsen 2, 6 | M |
| H7 | **Íconos sin texto ni tooltip.** al menos 8 de los 42 `IconButton` no tienen `tooltip` (recuento aproximado por inspección; líneas 4449, 6551, 7349, 7876, 7916, 8060, 9599, 9707), incluidos "atendido" y "borrar" del sonidista. Solo hay **1** uso de `Semantics` en 10 000 líneas → lector de pantalla y accesibilidad casi nulos. | 2.ª dimensión (ícono con fundamento) · Nielsen 6 · Accesibilidad | M |
| H8 | **Rol de texto libre = recordar en vez de reconocer.** Tras el cambio reciente, un usuario nuevo debe escribir su rol sin sugerencias; el campo ya no ofrece "Músico / Cantante / Sonidista" y sólo da un ejemplo en la etiqueta. Cada ingreso repite nombre y rol aunque ya estén guardados (los controladores arrancan vacíos). | Nielsen 6, 7 · KLM (ver 2.3) · Hick | M |
| H9 | **Pantalla en blanco al cargar (web).** `index.html` no tiene indicador de carga; el título provisional es `appsonido_frontend`; además carga `pdf.js` desde un CDN externo de forma bloqueante antes de arrancar la app. En las pruebas se vio la pantalla en blanco/negra varios segundos (en el servidor de desarrollo; la carga en producción no se midió). | Nielsen 1 · Tiempo | M |
| H10 | **Consistencia de redacción.** Mayúsculas mezcladas ("Tu Nombre", "Tu PIN de Sala", "Unirse a Sala" vs "Mis frases", "Escribí tu rol"); voseo ("Escribí", "Elegí", "Tocá", "Necesitás") mezclado con textos neutros; "Cerrar Sesión" con S mayúscula en el menú. | Nielsen 4 · Palabras | B |
| H11 | **Sin ayuda ni primera vez guiada.** No hay ayuda, tutorial ni explicación de qué es el PIN, quién es "sonidista" ni cómo se une la banda; solo la franja de 4 características en la bienvenida. | Nielsen 10 · Experiencia completa | M |
| H12 | **Cero medición.** No hay analítica, registro de tareas ni de errores (no se encontró `analytics`/`crashlytics`). No se puede saber cuánto tarda un pedido ni dónde se traban los usuarios. | "Lo que no se mide no se mejora" · Efectividad/Eficiencia/Satisfacción | **A** (para el proceso) |
| H13 | **Accesibilidad de color/escala sin auditar.** Hay 6 paletas × 2 modos; no se verificó contraste (WCAG 4.5:1) ni escalado de texto del sistema (Flutter respeta por defecto el tamaño de texto del sistema; falta comprobar que no haya desbordes a 150–200 %). Las paletas claras con acento ámbar/rosa son candidatas a fallar. | ISO 9241-210 (accesibilidad) · Nielsen 8 | M |
| H14 | **Hick en el panel del sonidista:** la barra superior reúne 4 acciones solo con ícono (borrar todo, agrupar por rol, pantalla encendida, elegir pestañas), más 4 pestañas; y los 14 pedidos rápidos van todos al mismo nivel, sin agrupar ni ordenar por uso. | Hick-Hyman · Nielsen 8 | B–M |
| H15 | **Alcance de pulgar (Fitts).** Salir (arriba-izquierda) y menú (arriba-derecha) están en las esquinas superiores, lejos del pulgar en celular; lo frecuente (pedido, enviar) está abajo, bien. No se pudo comprobar en celular real. | Fitts · Espacio | B |

### 2.3 Costo de las tareas (KLM, tiempos de la clase)
Supuestos: celular (sin cambio mouse↔teclado), nombre de 5 letras, rol de 8, PIN de 8 caracteres.

| Tarea | Pasos | Estimado hoy | Con mejoras propuestas |
|---|---|---|---|
| Músico recurrente envía un pedido rápido (app ya en la sala) | M + P + K | **≈ 2,7 s** | ≈ 2,7 s (ya es óptimo) |
| Crear sala (primera vez) | M, P+K "Crear", P+K nombre + 5 K, P+K rol + 8 K, P+K "Empezar" (+2 M de lectura) | **≈ 9 a 12 s** | ≈ 4 a 6 s (nombre y rol precargados o con chips) |
| Unirse a sala | lo anterior + P+K PIN + 8 K | **≈ 12 a 15 s** | ≈ 7 a 9 s (PIN por enlace/QR o precarga) |
| Sonidista responde un pedido | P+K responder, M, ~15 K, P+K enviar | ≈ 7 s | ≈ 3 s con respuestas rápidas |
| Sonidista marca un pedido como atendido | P+K | ≈ 1,3 s | igual, pero con deshacer (H3) |

Lectura: el costo está en el **ingreso**, no en el uso. Pasar el rol de "1 toque" (casillas) a "campo de texto" sumó ≈ 3 s por ingreso; es aceptable si se compensa con precarga (H8).

### 2.4 Resumen por criterio ISO 9241-11
- **Efectividad:** riesgo por H1, H2, H3, H4 (acciones que fallan en silencio o se hacen sin querer).
- **Eficiencia:** ingreso lento (2.3) y falta de atajos/precarga (H8); el flujo de uso recurrente ya es muy bueno.
- **Satisfacción:** legibilidad (H5), errores técnicos (H2) y falta de ayuda (H11).
- **Accesibilidad/sostenibilidad:** H5, H7, H13; (sostenibilidad: la pantalla siempre encendida se activa a pedido, bien; no se midió consumo).

---

## 3. Plan de trabajo por etapas

Orden pensado por riesgo y retorno: primero **medir y evitar daños**, después **ahorrar tiempo**, luego **pulir** y por último **validar** con personas. Cada etapa termina con un criterio de aceptación verificable. Esfuerzo: S ≈ medio día · M ≈ 1–2 días · L ≈ 3+ días.

### Etapa 0 — Línea base y medición (M)  *(H12; principio "iterativo, impulsado por evaluación")*
1. Definir las tareas críticas y sus metas: *T1* enviar un pedido (meta ≤ 3 s), *T2* crear/unirse a una sala (meta ≤ 8 s), *T3* sonidista atiende un pedido (≤ 3 s), *T4* cambiar idioma (≤ 10 s).
2. Instrumentar eventos mínimos (Firebase Analytics o contadores propios): tiempo de ingreso, intentos fallidos de "Empezar", pedidos enviados, errores mostrados, salidas de sala.
3. Sumar un mapa de calor para la versión web (p. ej. Microsoft Clarity) para ver dónde se toca.
4. Armar un protocolo de prueba con 5 personas (2 músicos, 1 cantante, 2 sonidistas), con el cuestionario **SUS** y registro de errores. Guardar los resultados como línea base.
- **Aceptación:** existe un tablero/planilla con los 4 tiempos reales, tasa de éxito y SUS de la versión actual.

### Etapa 1 — Errores, avisos y seguridad de acciones (M)  *(H1, H2, H3, H4; Nielsen 3, 5, 9)*
1. **Validaciones visibles:** campos obligatorios con `errorText` inline ("Escribí tu nombre"), botón deshabilitado hasta completar, foco al primer campo faltante, PIN con contador 0/8.
2. **Mensajes de error humanos:** traducir códigos comunes (sin red, sin permiso, sala inexistente) a frases en los 5 idiomas, con botón **Reintentar**; el detalle técnico queda solo en el log.
3. **Borrar pedido con deshacer:** reemplazar el borrado inmediato por *SnackBar* "Pedido eliminado · Deshacer" (o deslizar para borrar), y separar visualmente "atendido" de "borrar" (más distancia, color solo en el borrado).
4. **Salir de la sala con confirmación** y renombrar: "Salir de la sala" (≠ "Cerrar sesión de la cuenta"); usar íconos distintos (puerta vs. perfil).
- **Aceptación:** en las pruebas no queda ninguna acción que falle sin mensaje; nadie sale o borra por accidente sin poder revertirlo.

### Etapa 2 — Eficiencia del ingreso (Fitts, KLM, Hick) (M)  *(H8, H14, H15)*
1. **Precargar** nombre y rol con lo guardado en `SharedPreferences` (`nombre`, `rol`); un toque en "Empezar" si no cambió.
2. **Chips de rol sugeridos** (Sonidista, Músico, Cantante…) **más** campo libre, para recuperar el 1 toque sin perder la libertad; los traducidos por idioma.
3. Teclado: `textInputAction` + Enter para pasar de campo y enviar; autofocus en el primer campo; capitalización y autocorrección apropiadas.
4. Unirse por **enlace o QR** que traiga el PIN (saca ≈ 3 s y los errores de tipeo).
5. **Hick en pedidos rápidos:** agrupar por categoría (Volumen · Instrumentos · Mesa) o mostrar primero los más usados (orden por frecuencia por usuario).
6. Respuestas rápidas del sonidista ("Listo", "Ya lo bajo", "Un momento") para responder en 1 toque.
- **Aceptación:** T2 ≤ 8 s en la medición de la Etapa 0 repetida; T3 ≤ 3 s.

### Etapa 3 — Legibilidad y tamaño de los controles (Espacio) (S–M)  *(H5, H6, H7, H13 parte)*
1. Subir **toda** fuente de control a ≥ 14 px (los botones de pedido a ≥ 16 px) y objetivos táctiles a ≥ 48×48 dp con separación ≥ 8 dp; revisar `fontSize ≤ 12` (28 casos).
2. Reemplazar "+" y "−" por frases completas ("Subir el volumen", "Bajar el volumen") y definir su alcance ("de qué").
3. Añadir `tooltip`/`Semantics` a los 8 `IconButton` sin él y etiquetas de texto en las acciones del panel del sonidista (al menos en pantallas anchas).
4. Probar el **tamaño de texto del sistema** a 130–200 % y corregir desbordes (Flutter ya lo respeta por defecto).
- **Aceptación:** ningún control con texto < 14 px (secundarios ≥ 12); 100 % de íconos con etiqueta accesible; sin cortes de texto a 150 %.

### Etapa 4 — Carga y estados del sistema (Tiempo) (S–M)  *(H9; Nielsen 1)*
1. `index.html`: indicador de carga propio (logo + barra), título definitivo "Sound Check Pro", y cargar `pdf.js` de forma diferida (`defer`) y solo cuando se abre un PDF.
2. Indicador de **conexión** (en línea / sin red / reconectando) visible en la sala; marcar los pedidos "enviando…" hasta que lleguen.
3. Estados vacíos con guía ("Todavía no hay pedidos. Cuando alguien pida algo, aparece acá").
4. Medir el tiempo de carga en producción (red 4G simulada) y fijar un presupuesto (p. ej. interactivo < 4 s).
- **Aceptación:** nunca hay pantalla en blanco sin indicador; la caída de red se ve en < 2 s.

### Etapa 5 — Lenguaje, consistencia y ayuda (Palabras) (M)  *(H10, H11; Nielsen 4, 10)*
1. **Guía de estilo de textos:** capitalización tipo oración, un solo registro (decidir entre voseo o neutro), un término por concepto (sala/sesión/cuenta), glosario (pedido, consola, setlist, secuencia).
2. Revisar los 5 idiomas con hablantes nativos, prestando atención a la jerga de audio (retorno, pista, secuencia).
3. **Primera vez guiada** de 3 pasos (qué es el PIN, cómo pedir, cómo ve el sonidista) con opción de omitir, y un ícono "?" en el menú con ayuda corta.
- **Aceptación:** una persona nueva completa T1 y T2 sin ayuda externa en la prueba de usuarios; auditoría de textos sin incoherencias.

### Etapa 6 — Accesibilidad y paletas (S–M)  *(H13; ISO 9241-210: accesibilidad)*
1. Auditar contraste de cada paleta en claro y oscuro (texto sobre fondo y sobre acento; objetivo 4,5:1 texto, 3:1 componentes) y ajustar los tokens que no cumplan.
2. No depender solo del color (estado de pedido: ícono + texto), revisar el parpadeo de urgentes con la opción "reducir movimiento" del sistema.
3. Navegación por teclado y orden de foco en web; lectores de pantalla (TalkBack / VoiceOver) en los flujos T1–T3.
- **Aceptación:** reporte de contraste 100 % aprobado; flujos T1–T3 utilizables con lector de pantalla.

### Etapa 7 — Validación y mejora iterativa (M, recurrente)  *(principios 3, 4 y 5 de la ISO 9241-210)*
1. Repetir el protocolo de la Etapa 0 con la versión mejorada (mismas tareas, mismas métricas, personas nuevas).
2. Comparar contra la línea base: tiempo por tarea, tasa de éxito, errores, SUS (meta: subir ≥ 10 puntos).
3. Prueba **en el lugar real** (ensayo con banda y sonidista): luz baja, manos ocupadas, ruido.
4. Backlog priorizado de la ronda siguiente y registro de decisiones en `CONTEXTO_PARA_IA.md`.
- **Aceptación:** informe comparativo y lista de mejoras de la próxima iteración.

### Resumen del plan
| Etapa | Foco | Hallazgos | Esfuerzo | Depende de |
|---|---|---|---|---|
| 0 | Medición y línea base | H12 | M | — |
| 1 | Errores y acciones seguras | H1–H4 | M | — (puede ir en paralelo a 0) |
| 2 | Eficiencia del ingreso | H8, H14, H15 | M | 0 (para medir el efecto) |
| 3 | Legibilidad y controles | H5–H7 | S–M | — |
| 4 | Carga y estado del sistema | H9 | S–M | — |
| 5 | Lenguaje y ayuda | H10, H11 | M | — |
| 6 | Accesibilidad y paletas | H13 | S–M | 3 |
| 7 | Validación iterativa | todos | M | 0–6 |

Recomendación de arranque: **Etapa 1 + Etapa 3** (son las de mayor severidad y menor esfuerzo, y no cambian el diseño visual) en paralelo con la **Etapa 0**, para tener la línea base antes de tocar el flujo de ingreso en la Etapa 2.

---

## 4. Estado de implementación (actualizado 24-oct-2026)

| Etapa | Estado |
|---|---|
| 0 Medición | Pendiente |
| 1 Errores y acciones seguras | **Hecha** (H1–H4): validaciones en línea, errores humanos con Reintentar, borrar con Deshacer, salir de la sala con confirmación. Verificada en web con invitado. Falta el mensaje de error de red (no se pudo provocar) |
| 2 Eficiencia del ingreso | Pendiente |
| 3 Legibilidad y controles | **Parcial** (H5, H6, H7): controles ≥ 14 px, "+"/"−" renombrados, tooltips agregados. Faltan: prueba a 150–200 % de escala y objetivos táctiles ≥ 48 dp en celular real; las copias antiguas de "Mis frases" conservan "+" y "−" |
| 4 Carga y estado | Pendiente |
| 5 Lenguaje y ayuda | Pendiente |
| 6 Accesibilidad y paletas | Pendiente |
| 7 Validación iterativa | Pendiente |

Hallazgo nuevo durante la implementación: la lista de pedidos rápidos repite "Volumen retorno" (primera y tercera fila).
