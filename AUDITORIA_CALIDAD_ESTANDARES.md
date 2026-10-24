# Auditoría de calidad: atributos, normas y estándares — Sound Check Pro

Base teórica: *Atributos, normas y estándares de calidad de software (CyS clase 1, 2026)*.
Fecha: 24-oct-2026 · Código auditado: `main` en el commit `bfcaee6` más las correcciones locales posteriores.

> Alcance y límites: auditoría de experto por inspección de código, configuración del repositorio y pruebas hechas en esta serie de sesiones. **No es una evaluación formal** (ni de ISO ni de CMMI) y no se midió en producción: donde digo "no medido" es literal. La clase trata el contexto de comercio electrónico; adapté los ejemplos al uso real de la app (una banda en vivo y un sonidista). Una de las diapositivas ("Calidad de procesos para el desarrollo de software para empresas de hasta 25 empleados") no nombra la norma en el texto; la identifico como ISO/IEC 29110, y esa identificación es mía. Complementa a `AUDITORIA_USABILIDAD.md` (atributo *usabilidad*) y `AUDITORIA_TESTING.md` (atributo *testeabilidad*).

---

## 1. Reglas y criterios extraídos de la clase

### 1.1 Calidad, atributo y escenario
- **Calidad de software:** grado en que satisface los **requisitos especificados** y/o las **necesidades y expectativas** del usuario/cliente.
- **Atributo de calidad:** una **propiedad medible** del sistema que indica qué tan bien satisface a cada parte interesada; siempre lleva un **criterio de éxito**.
- **Escenario de un atributo:** *fuente* (usuario, otro software) → *estímulo* (ej. ejecuta un comando) → *artefacto* (el software) → *ambiente* (en qué condiciones) → *respuesta* → **medida de la respuesta** (velocidad, calidad de lo devuelto…). La medida es lo que permite decir si se cumple.

### 1.2 Los nueve atributos (ISO 25000)
| Atributo | Qué indica | Elementos que menciona la clase |
|---|---|---|
| **Desplegabilidad** | Complejidad de llevar el software a producción | Instalación y activación · desactivación · desinstalación · **actualización**. Hoy se hace principalmente desde la nube |
| **Disponibilidad** | Qué tan listo está el sistema cuando alguien lo pide; accesibilidad y utilización por usuarios autorizados cuando lo requieren | Continuidad operacional en un período; que la información se pueda recuperar sin pérdida ni bloqueo |
| **Escalabilidad** | Capacidad de soportar cargas crecientes | Cantidad y simultaneidad de usuarios, de datos y de transacciones; **vertical** (más potencia a un procesador) y **horizontal** (más procesadores iguales); escalable si el rendimiento crece proporcionalmente |
| **Interoperabilidad** | Capacidad de intercambiar datos con otros sistemas | Una **API** permite que dos sistemas se comuniquen |
| **Modificabilidad** | Costo de hacer cambios | Costo, **velocidad** y recursos necesarios |
| **Rendimiento** | Hacer lo esperado **en el tiempo que el usuario espera** | |
| **Seguridad** | Proteger datos de accesos no autorizados y permitir el acceso a quien corresponde | |
| **Testeabilidad** | Facilidad para hacer pruebas | Ejemplo Apolo 13: un prototipo idéntico de la nave permitió probar cada acción antes de hacerla en la real |
| **Usabilidad** | Facilidad de uso (efectividad, eficiencia y satisfacción — ISO 9241-11) | |

### 1.3 Normas y estándares
- **Norma:** regla que **se debe seguir**; documento público consensuado por las partes interesadas y aprobado por un organismo de normalización reconocido. **Estándar/atributo:** referencia, modelo o patrón de carácter **opcional o deseado**.
- **ISO** (Organización Internacional de Normalización) elabora normas técnicas; **IEC** se especializa en tecnologías eléctricas, electrónicas y digitales. "ISO/IEC" = norma conjunta (ej. 27001, 12207: ciclo de vida del software).

### 1.4 Tres dimensiones de la calidad de un producto software
| Dimensión | Qué mira | Normas/modelos |
|---|---|---|
| **Calidad de los procesos** | Cómo se organizan y despliegan las tareas del equipo | ISO 33000 · **CMMI** · **Agile** |
| **Calidad del producto** | La constitución y estructura del producto | ISO 25000 (SQuaRE) |
| **Calidad en el uso** | Que el cliente pueda usarlo de forma eficiente y satisfactoria | ISO 25000 / ISO 9241 + IxD |

### 1.5 Calidad de procesos
- **ISO 33000:** marco coherente para *evaluar* procesos de desarrollo de software.
- **CMMI:** modelo para mejorar y evaluar procesos; mide el **nivel de madurez** (1 a 5); **desde el nivel 3 es certificable**.
- **Modelo de madurez:** mapa evolutivo para medir, diagnosticar y mejorar. Idea clave: **no se busca el nivel 5 de la noche a la mañana**; evita gastar en automatizaciones complejas (nivel 5) cuando los procesos internos siguen caóticos y sin documentar (nivel 1).
- **Agile / Scrum:** pasos incrementales e iterativos, colaboración y mejora continuas; ciclo planificar-ejecutar-evaluar. Scrum: **ceremonias** (daily, retrospectiva, review), **artefactos** (backlog del sprint, backlog del producto, sprint) y **roles** (Scrum Master, Product Owner, stakeholders).

### 1.6 Otras normas ISO que menciona
ISO 9001 (gestión de calidad) · ISO 27000/27001 (seguridad de la información) · ISO 20000 (calidad de servicios) · ISO 28000 (cadena de suministro) · norma para desarrollo de software en empresas de hasta 25 empleados (ISO/IEC 29110, ver nota de alcance).

---

## 2. Auditoría

### 2.1 Calidad del producto — atributo por atributo
Semáforo: 🟢 cumple · 🟡 parcial · 🔴 débil · ⚪ no medido.

| Atributo | Estado | Evidencia |
|---|---|---|
| **Desplegabilidad** | 🟡 | ✔ Web: despliegue automático a GitHub Pages con control previo (`flutter analyze` + `flutter test`), actualización inmediata para todos. ✘ La versión es `1.0.0+1` desde el inicio, **0 tags** ni releases, la versión **no se ve en la app**; ✘ **Android no se compila en CI**; ✘ el release de Android está firmado con la clave de *debug* (`signingConfig = debug`), no es publicable; ✘ `google-services.json` está (correctamente) fuera del repo pero no hay guía para reproducir el build |
| **Disponibilidad** | 🔴 para el contexto "en vivo" | La app depende de Firebase (Firestore/Auth), Supabase (audios y PDFs), GitHub Pages y **cdnjs** (pdf.js, cargado de forma bloqueante en `index.html`); sin indicador de conexión. **Verificado en el código:** `_enviarMensaje` llama a `enviarPedido` **sin esperar el resultado ni capturar errores** y muestra "Enviado" de inmediato (400 ms), así que la confirmación aparece aunque el envío falle. El SDK de Firestore encola las escrituras mientras la app sigue abierta, pero con mal wifi de escenario la persona no sabe si el pedido llegó, y si cierra o recarga la pestaña antes de reconectar (en web la persistencia sin red viene desactivada y no se activa) el pedido se pierde. No hay plan por caída de proveedor ni se sabe el plan/cuota de cada servicio (los proyectos gratuitos de algunos proveedores se pausan por inactividad: **verificar**) |
| **Escalabilidad** | 🟡 | ✔ El escalamiento horizontal lo delega a servicios administrados. ✘ 12 `snapshots()` y 2 `limit()`; las listas en vivo crecen sin tope (corregido en parte: tope de 200 en dos listas del sonidista); ✘ cada integrante descarga el audio completo (hasta 50 MB) y no hay caché ni medición de lecturas/costo |
| **Interoperabilidad** | 🟡 | ✔ Importa PDF y audio (MP3/WAV/M4A), inicia sesión con Google, comparte el setlist como texto. ✘ Sin formatos abiertos de intercambio (ChordPro, JSON/CSV de repertorio y setlist), sin API ni integración con mesas/DAW. Depende de la estrategia: **no es urgente** |
| **Modificabilidad** | 🟡 | ✔ Textos en ARB (5 idiomas), colores por *tokens* de paleta, documentación de arquitectura excelente (`CONTEXTO_PARA_IA.md`), ahora hay pruebas. ✘ Un solo archivo de **10 294 líneas** con ~65 clases; ✘ el formato es inconsistente (zonas con líneas en blanco intercaladas): en esta serie de sesiones **al menos cinco ediciones automáticas fallaron** por eso; ✘ **112 de los 193 archivos versionados (58 %)** son documentación de herramientas de IA (`frontend/.agents/`), ruido que no es parte del producto |
| **Rendimiento** | ⚪ | Sin mediciones. Datos sueltos: `main.dart.js` = 5,2 MB; la primera carga mostró varios segundos de pantalla en blanco en desarrollo; la latencia pedido→panel se percibió de 1 a 3 s (sin medir) |
| **Seguridad** | 🟡 | ✔ Modelo "conocer el PIN alcanza" documentado como decisión consciente (§6 de `CONTEXTO_PARA_IA.md`), reglas de Firestore/Storage versionadas, claves de cliente públicas por diseño (Firebase y Supabase *anon*) protegidas por reglas/RLS, `google-services.json` y *keystores* fuera de Git, PIN de 8 caracteres sobre 31 símbolos (≈ 8,5 × 10¹¹ combinaciones). ✘ **App Check está desactivado** (`kAppCheckSiteKeyWeb = null`) y no hay límite de tasa: quien conozca o adivine un PIN puede inundar la sala de pedidos; ✘ las reglas no validan la forma ni el tamaño de un pedido; ✘ reglas sin pruebas con emulador; ✘ sin revisión de dependencias desactualizadas |
| **Testeabilidad** | 🟡 (mejoró) | Ver `AUDITORIA_TESTING.md`: ahora 82 pruebas unitarias y control en CI; faltan costuras para probar pantallas con Firebase |
| **Usabilidad** | 🟡 (mejoró) | Ver `AUDITORIA_USABILIDAD.md`: Etapas 1 y 3 hechas; pendientes medición, ingreso más rápido, carga, ayuda y accesibilidad |

### 2.2 Calidad de los procesos (ISO 33000 / CMMI / Agile)
| Aspecto | Evidencia | Valoración |
|---|---|---|
| Control de configuración | Git, 43 commits con mensajes descriptivos, todos en `main`, un solo autor | 🟡 Todo directo a `main`: sin ramas, sin *pull requests*, sin revisión de pares |
| Requisitos y trazabilidad | `REQUISITOS.md` con RQ-xx y casos CP-xx (nuevo), `DEFECTOS.md` | 🟢 Reciente; mantenerlo vivo |
| Aseguramiento de calidad (QA) | CI con análisis + pruebas antes de publicar; definición de "hecho" escrita | 🟡 Existe el control mínimo; no cubre reglas, concurrencia ni desempeño |
| Gestión de versiones | `1.0.0+1`, 0 tags, sin *changelog* | 🔴 |
| Planificación (Agile) | Los planes viven en tres documentos de auditoría; no hay un backlog único ni prioridad compartida; no hay revisiones con usuarios ni retrospectivas | 🟡 |
| Gestión del conocimiento | `CONTEXTO_PARA_IA.md` detallado y actualizado en cada cambio | 🟢 Fortaleza |
| Ruido del repositorio | 58 % de los archivos son material de herramientas de IA | 🟡 |

**Madurez estimada (informal, no es una evaluación CMMI):** entre el nivel **1 (inicial)** y el **2 (gestionado)** y en ascenso: ya hay requisitos escritos, control de versiones y un control de calidad automático, pero faltan planificación estable, revisión y gestión de versiones. Consistente con la lección de la clase: **el objetivo útil es consolidar el nivel 2**, no buscar el 5 ni certificar (el nivel 3 recién es certificable).

### 2.3 Normas aplicables a este proyecto
| Norma | ¿Aplica? | Cómo |
|---|---|---|
| ISO/IEC 25000 (SQuaRE) / 25010 | **Sí, como marco** | Es la base de los atributos de §2.1 |
| ISO 9241-11 y -210 | **Sí** | Ya usada en la auditoría de usabilidad |
| ISO/IEC 29110 (empresas muy pequeñas) | **Sí, recomendable** | Perfil básico: gestión del proyecto + implementación, pensado para equipos de hasta 25 personas |
| ISO/IEC 27001 (seguridad de la información) | Parcial | Tomar controles puntuales (gestión de claves, control de acceso, copias, dependencias); no certificar |
| ISO 33000 / CMMI | Como guía | Autoevaluación; sin certificación |
| ISO 9001, 20000, 28000 | No | Gestión general / servicios de TI / cadena de suministro: fuera de alcance |

### 2.4 Hallazgos

| # | Hallazgo | Atributo / norma | Sev. |
|---|---|---|---|
| Q1 | **"Enviado" se muestra antes de saber si el pedido llegó** (el envío no se espera ni se capturan errores) y no hay indicador de conexión ni persistencia sin red: con mal wifi un pedido puede perderse sin que nadie lo note. | Disponibilidad | **A** |
| Q2 | **Dependencias externas sin plan:** Firebase, Supabase, GitHub Pages y cdnjs (pdf.js bloqueante) sin inventario de planes/cuotas ni qué hacer si caen. | Disponibilidad | M |
| Q3 | **App Check desactivado y sin límite de tasa** ni validación de forma en las reglas: un PIN conocido permite inundar la sala. | Seguridad | **A** |
| Q4 | **Sin versionado ni releases:** `1.0.0+1`, 0 tags, versión no visible; no se puede decir qué versión corre ni volver a una anterior de forma controlada. | Desplegabilidad / procesos | M |
| Q5 | **Android no se compila en CI y su release usa clave de *debug*;** no hay guía para reproducir el build (falta `google-services.json`). | Desplegabilidad | M |
| Q6 | **Escalabilidad no medida:** sin métricas de lecturas ni de descarga de audio; listas en vivo con tope solo en dos casos. | Escalabilidad / rendimiento | M |
| Q7 | **Rendimiento sin presupuesto ni medición** (5,2 MB de JS, carga inicial, latencia pedido→panel). | Rendimiento | M |
| Q8 | **Modificabilidad: 10 294 líneas en un archivo y formato inconsistente** (cinco ediciones automáticas fallaron). Un formateador uniformaría el archivo. | Modificabilidad | M |
| Q9 | **Ruido en el repo:** 112 de 193 archivos versionados (`frontend/.agents/`) no son del producto. | Modificabilidad | B |
| Q10 | **Trabajo directo en `main`** sin ramas, revisión ni *pull requests*; el control de CI mitiga pero no reemplaza una revisión. | Procesos (CMMI nivel 2) | M |
| Q11 | **Sin backlog único, cadencia ni retrospectiva:** los planes están dispersos en tres documentos. | Procesos (Agile) | B |
| Q12 | **Los atributos no tienen criterio de éxito definido** (la regla central de la clase): ninguno tiene escenario con medida. Ver §3. | Todos | **A** (para el proceso) |
| Q13 | **Sin formatos abiertos de intercambio** para repertorio y setlist. | Interoperabilidad | B |

---

## 3. Escenarios de atributos con criterio de éxito (propuesta a validar)

Formato de la clase: fuente → estímulo → artefacto → ambiente → respuesta → **medida**. Los valores son **propuestas** para que el dueño del producto los ajuste; hoy ninguno está medido.

| Atributo | Fuente → Estímulo | Artefacto · Ambiente | Respuesta esperada | **Medida / criterio de éxito** |
|---|---|---|---|---|
| Disponibilidad | Músico → toca un pedido rápido | App web/móvil · mala conexión del escenario (pérdida de red de hasta 30 s) | El pedido queda en cola, el músico ve "enviando…", se entrega al volver la red | **0 pedidos perdidos** ni duplicados; el estado se ve en < 2 s; reconexión automática |
| Disponibilidad | Sonidista → abre el panel | Panel · Firebase caído | Mensaje claro y reintento; la app no queda en blanco | Mensaje en < 3 s; la app se recupera sola al volver el servicio |
| Rendimiento | Músico → envía un pedido | Pedido → panel del sonidista · red 4G/wifi | El pedido aparece en el panel | **p95 ≤ 2 s** |
| Rendimiento | Persona nueva → abre la app | Web · 4G, sin caché | La app es interactiva | **≤ 4 s** hasta poder tocar "Crear sala" |
| Escalabilidad | 15 integrantes + 1 sonidista | Sala en vivo · 200 pedidos acumulados | Todos ven los pedidos sin degradación | Lecturas por sesión de 1 hora **≤ X** (fijar con la primera medición); tiempo de respuesta sin cambios |
| Seguridad | Persona ajena → conoce un PIN y envía 500 pedidos en 10 s | Reglas + App Check | El sistema rechaza el exceso | Solicitudes sin App Check válido = 0 aceptadas (tras activarlo); pedidos > 500 caracteres rechazados por las reglas |
| Seguridad | Invitado → intenta leer la biblioteca de otra cuenta | Reglas de Firestore | Acceso denegado | 100 % de los casos de la matriz de reglas denegados (prueba automática) |
| Desplegabilidad | Desarrollador → publica un cambio | Pipeline · rama `main` | Se publica con control previo y queda registrada la versión | De commit a producción **≤ 10 min**; versión visible en la app; vuelta atrás **≤ 15 min** |
| Modificabilidad | Desarrollador → agrega una frase rápida o un idioma | Código | Cambio localizado y probado | Cambio en **≤ 3 archivos**; pruebas en verde; ≤ 1 h de trabajo |
| Interoperabilidad | Banda → exporta su setlist | App | Archivo en formato abierto que otro programa abre | Exporta e importa ChordPro/JSON sin pérdida de acordes ni orden |
| Testeabilidad | Desarrollador → corre las pruebas | Proyecto · CI | Resultado confiable y rápido | Suite **< 2 min**; cobertura de la lógica pura ≥ 80 % |
| Usabilidad | Músico nuevo → envía su primer pedido | App | Lo logra sin ayuda | Éxito ≥ 90 % y ≤ 15 s (ver `AUDITORIA_USABILIDAD.md`) |

---

## 4. Plan de trabajo por etapas

Criterio de orden: primero **definir qué es "bueno" (medible)**, después lo que más daña **en el uso en vivo** (disponibilidad y seguridad), luego versionado y despliegue, y por último modificabilidad e interoperabilidad. Esfuerzo: S ≈ medio día · M ≈ 1–2 días · L ≈ 3+ días. Algunas tareas requieren **acciones tuyas** (claves, planes de servicios) y las marco con 🔑.

### Etapa 0 — Definir los atributos y su criterio de éxito (S)  *(Q12)*
1. Validar o ajustar la tabla de la §3 con el dueño del producto; fijar las prioridades del contexto "en vivo": **1.º disponibilidad, 2.º rendimiento, 3.º seguridad, 4.º usabilidad**.
2. Guardar los escenarios como requisitos no funcionales (RQ-20…) en `REQUISITOS.md`.
- **Aceptación:** cada atributo tiene al menos un escenario con medida y un dueño.

### Etapa 1 — Disponibilidad en uso en vivo (M)  *(Q1, Q2)*
1. **Esperar la confirmación del envío** y mostrar "Enviado" solo cuando llegó (o "Enviando…" / "No se pudo enviar · Reintentar"); indicador de conexión visible en la sala (en línea / sin red / reconectando).
2. Cola de reenvío y persistencia sin red de Firestore para que un pedido no se pierda con cortes breves.
3. Servir `pdf.js` desde la propia app (no desde cdnjs) o cargarlo de forma diferida y con tolerancia a falla.
4. 🔑 Inventario de dependencias (Firebase, Supabase, GitHub Pages): plan, cuotas, pausas por inactividad, qué pasa si caen, y un breve *runbook* de caída.
- **Aceptación:** prueba con red cortada 30 s sin pérdida de pedidos; inventario y runbook escritos.

### Etapa 2 — Desplegabilidad y versionado (M)  *(Q4, Q5)*
1. Versión en `pubspec.yaml` actualizada por release y **visible en la app** (Configuración); etiquetas Git `vX.Y.Z` y `CHANGELOG.md`.
2. Procedimiento de vuelta atrás (volver a publicar un tag) probado una vez.
3. Compilar **Android en CI** como artefacto de prueba (sin firmar); documentar el build local y cómo conseguir `google-services.json`.
4. 🔑 Definir el *keystore* de release (fuera del repo, secreto de GitHub) y reemplazar la firma de debug cuando se vaya a publicar.
- **Aceptación:** cada despliegue tiene versión y tag; se puede volver a una versión anterior en ≤ 15 min.

### Etapa 3 — Seguridad (M–L)  *(Q3; ISO 27001 como guía)*
1. 🔑 Activar **Firebase App Check** (clave reCAPTCHA v3 para web) primero en modo *monitor* y luego exigirlo.
2. **Validación de forma y tamaño en las reglas** (pedido: campos permitidos, máximo de caracteres, tipos); límite de frecuencia por usuario cuando sea viable.
3. Pruebas de reglas con emulador (ver Etapa 4 de `AUDITORIA_TESTING.md`) incluyendo el escenario de inundación.
4. Revisión periódica de dependencias (`flutter pub outdated`, Dependabot) y política de rotación de claves.
- **Aceptación:** los escenarios de seguridad de la §3 pasan; sin dependencias con vulnerabilidades conocidas.

### Etapa 4 — Rendimiento y escalabilidad (M)  *(Q6, Q7)*
1. Medir la línea base (carga, latencia pedido→panel, lecturas por sesión) y fijar el presupuesto de la §3.
2. Reducir lo grande: carga diferida de PDF/Syncfusion (`deferred`), revisar el peso de imágenes y fuentes (el build web pesa 39 MB en total).
3. Topes y paginación en las demás listas en vivo; caché de audios ya descargados; estimar costo por 1 000 sesiones.
- **Aceptación:** p95 ≤ 2 s y carga ≤ 4 s medidos; lecturas por sesión dentro del límite acordado.

### Etapa 5 — Modificabilidad (M–L)  *(Q8, Q9)*
1. Aplicar `dart format` a todo el proyecto y exigirlo en CI: elimina el formato inconsistente que rompió las ediciones automáticas.
2. Sacar `frontend/.agents/` del repositorio (o ignorarlo) para que el repo contenga solo el producto.
3. 🔑 Proponer, **para que lo apruebes** (hoy la convención del proyecto es "todo en `main.dart`"), una división gradual por dominio (acceso, pedidos, sonidista, setlist, secuencias, tema); medir líneas por archivo y archivos tocados por cambio.
- **Aceptación:** formato uniforme verificado por CI; repo sin material ajeno; decisión escrita sobre la estructura.

### Etapa 6 — Interoperabilidad (M, opcional)  *(Q13)*
1. Exportar/importar repertorio y setlist en **ChordPro** y **JSON/CSV**.
2. Compartir una sala por enlace (con el PIN) para evitar tipeo.
- **Aceptación:** ida y vuelta sin pérdida en el escenario de la §3.

### Etapa 7 — Proceso: calidad en el trabajo diario (S–M, continuo)  *(Q10, Q11; CMMI nivel 2, Agile, ISO/IEC 29110)*
1. **Ramas + pull requests** con CI obligatoria y plantilla de PR que incluya la definición de "hecho".
2. **Backlog único** (issues de GitHub o `BACKLOG.md`) con prioridad; iteraciones cortas con *review* (¿lo probó alguien de la banda?) y *retrospectiva* de 15 minutos al cerrar cada una.
3. Autoevaluación de madurez cada trimestre (checklist del nivel 2 de CMMI y del perfil básico de ISO/IEC 29110) registrada en un documento.
- **Aceptación:** ningún cambio llega a `main` sin PR verde; backlog vigente; autoevaluación registrada.

### Resumen
| Etapa | Foco | Hallazgos | Esfuerzo | Depende de |
|---|---|---|---|---|
| 0 | Escenarios y criterios de éxito | Q12 | S | — |
| 1 | Disponibilidad en vivo | Q1, Q2 | M | 0 |
| 2 | Desplegabilidad y versionado | Q4, Q5 | M | — |
| 3 | Seguridad | Q3 | M–L | 0 |
| 4 | Rendimiento y escalabilidad | Q6, Q7 | M | 0 |
| 5 | Modificabilidad | Q8, Q9 | M–L | — |
| 6 | Interoperabilidad | Q13 | M | — |
| 7 | Procesos | Q10, Q11 | S–M, continuo | — |

**Recomendación de arranque:** Etapa **0** (medio día) y a continuación **1** (disponibilidad) y **3** (seguridad), que son lo que más pesa en el uso en vivo; la **7** puede empezar ya, sin costo. El uso de `dart format` (Etapa 5, punto 1) es una ganancia rápida e independiente.

---

## 5. Propuesta de estructura del código (Etapa 5, requiere tu aprobación)

Hoy la regla del proyecto es "todo el código Dart en `frontend/lib/main.dart`". Tras aplicar el formato (10 414 → 9 103 líneas) sigue siendo **un archivo de más de 9 000 líneas con unas 65 clases**. **No lo dividí** porque es una excepción a esa regla y mover clases entre archivos toca casi todo el proyecto; si la apruebas, propongo hacerlo de a un dominio por vez (cada paso con las pruebas en verde), empezando por lo que no depende de Firebase (más fácil de probar):

| Archivo propuesto | Contenido actual (líneas aprox. antes del formato) | Tamaño aprox. | Orden |
|---|---|---|---|
| `utilidades.dart` | roles, `esRolSonidista`, `mensajeError`, `esperarEnvio`, enlaces, constantes | ~250 | 1.º (puro, ya tiene pruebas) |
| `tema.dart` | `AppPalette`, `construirTema`, temas "Escenario", `context.acento` | ~500 | 2.º |
| `cifrado.dart` | `ChordTransposer`, `CifradoPdfExtractor` | ~400 | 3.º (puro) |
| `servicios/*.dart` | `AuthService`, `UsuarioService`, `MisSalasService`, `FrasesService`, `RepertorioService`, `SetlistService`, `SecuenciasService`, `FirestoreService` | ~1 250 | 4.º (agrega costuras para pruebas) |
| `reproductor_secuencias.dart` | `ReproductorSecuencias`, `FilaSecuencia` | ~380 | 5.º |
| `pantallas/acceso/*.dart` | Splash, Bienvenida, Auth, menú principal, selectores, Crear/Unirme, Mis salas | ~2 400 | 6.º |
| `pantallas/sala/*.dart` | `RequestScreen`, `SetlistTab`, `SecuenciasTab` | ~2 400 | 7.º |
| `pantallas/biblioteca/*.dart` | Mis frases, Mi repertorio, Mis secuencias | ~1 200 | 8.º |
| `pantallas/visores/*.dart` | Visor de cifrado y de PDF | ~700 | 9.º |
| `pantallas/sonidista/*.dart` | Acceso y panel del sonidista | ~900 | 10.º |

Beneficios medibles (Etapa 5): menos líneas por archivo (meta ≤ 800), pruebas más fáciles de aislar y ediciones automáticas que ya no dependen del formato. Costos: un diff enorme por cada movimiento y la necesidad de revisar importaciones; por eso se hace gradual y con la CI como red de seguridad.

---

## 6. Estado de implementación (24-oct-2026)

| Etapa | Estado |
|---|---|
| 0 Escenarios y criterio de éxito | **Hecha como propuesta:** los escenarios de la §3 pasaron a `REQUISITOS.md` (RQ-20…RQ-26); sus valores objetivo **esperan tu validación** |
| 1 Disponibilidad en vivo | **Parcial.** Hecho: "Enviado" solo cuando el servidor confirma (con aviso de pedido en cola y "Reintentar"), banner fijo "Sin conexión" en la sala del músico, pdf.js no bloquea el arranque, inventario de dependencias y *runbook* (`OPERACION.md`). **Falta:** verificar con la red realmente cortada, el aviso en el panel del sonidista (B-04) y revisar planes/cuotas de Firebase y Supabase 🔑 (B-10). Descubierto: la app carga CanvasKit y Firebase JS desde `www.gstatic.com` y tipografías desde `fonts.gstatic.com` en tiempo de ejecución |
| 2 Desplegabilidad y versionado | **Parcial.** Hecho: versión `1.1.0` visible en Configuración (y verificada por una prueba contra `pubspec.yaml`), `CHANGELOG.md`, rollback por *tag* en el flujo de Actions, trabajo de Android **apagado por defecto**. **Falta:** publicar el primer tag y ensayar el rollback (B-07); activar el build de Android y crear el *keystore* 🔑 (B-11) |
| 3 Seguridad | **Parcial.** Hecho: tope de 200 caracteres por pedido, Dependabot, revisión de dependencias (Firebase 2 versiones mayores atrás), propuesta de reglas con validación en `OPERACION.md` §6. **No hecho:** App Check 🔑 (B-01), publicar las reglas (B-02, requiere emulador) |
| 4 Rendimiento y escalabilidad | **Parcial.** Línea base local medida (`OPERACION.md` §7: primer pintado 728 ms, `main.dart.js` 5,1 MB). **Falta:** medir con 4G, latencia pedido→panel y lecturas por sesión (B-03), topes del Historial (B-16) |
| 5 Modificabilidad | **Parcial.** Hecho: código formateado de forma uniforme y exigido por la CI (de 71 a 22 avisos de análisis; 81 correcciones automáticas), `frontend/.agents/` fuera del repositorio (193 → 81 archivos versionados; sigue en tu disco). **No hecho:** dividir `main.dart` (propuesta en §5, espera tu aprobación) |
| 6 Interoperabilidad | **Parcial.** Hecho: enlace `?sala=CÓDIGO` y botón de compartir al crear una sala. **No hecho:** exportar/importar en ChordPro/JSON/CSV (B-21, falta decidir el formato) |
| 7 Procesos | **Parcial.** Hecho: `PROCESO.md` (flujo con ramas y PR, cadencia, retrospectiva, autoevaluación de madurez), `BACKLOG.md` único, plantilla de pull request. **No hecho:** protección de la rama 🔑 (B-12) y la primera retrospectiva |
