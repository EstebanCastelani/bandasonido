# Auditoría de testing y calidad — Sound Check Pro

Base teórica: *¿Cómo sabemos que un software tiene calidad? — Testing (Calidad y Servicio al Cliente, UNPAZ 2026)*.
Fecha: 24-oct-2026 · Código auditado: `frontend/lib/main.dart` en el commit `0e77b71` (web publicada).

> Alcance y límites: auditoría de experto con **evidencia ejecutada** (corrí `flutter test` y un probe temporal sobre la lógica pura, que ya borré; mide casos reales, no teóricos) más inspección de código y de la configuración de CI. No hay pruebas en celular real ni en Android. La *plantilla de caso de prueba* del PDF es una imagen y no se puede leer; uso el formato estándar (sección 4.1). Complementa a `AUDITORIA_USABILIDAD.md` (la usabilidad ya está auditada allí).

---

## 1. Reglas y criterios extraídos de la clase

### 1.1 Conceptos básicos
- **Testing:** evaluar el software **ejecutando pruebas** para verificar que cumple los requisitos y detectar defectos o comportamientos inesperados.
- **Tester:** quien ejecuta las pruebas y/o analiza resultados, y **documenta y reporta los defectos**.
- **Manual vs. automatizado:** manual = una persona ejecuta y analiza; automatizado = una herramienta o script ejecuta y genera resultados para analizar.
- **QC (Quality Control):** controla la calidad **del producto** (testing para detectar errores y verificar lo esperado).
- **QA (Quality Assurance):** asegura la calidad **del proceso**; busca **prevenir** errores y mejorar cómo se desarrolla.

### 1.2 ¿Cómo sabemos que un software tiene calidad? (características que muestra la clase)
1. **Adecuación funcional:** cumple correctamente las funciones que pide el negocio (ejemplos: no se puede comprar sin stock; un cupón se usa una vez por cliente; el 20 % aplica solo a productos seleccionados).
2. **Usabilidad:** ¿se puede usar de manera fácil y comprensible?
3. **Eficiencia de desempeño:** ¿responde con la velocidad y los recursos adecuados?

### 1.3 El camino del test (6 pasos)
1. Entender qué necesita el negocio (no se puede probar algo si no se sabe qué debería hacer).
2. Analizar los requerimientos (qué debe hacer el sistema, con precisión: ej. "envío gratis si el total supera $50.000").
3. **Pensar las casuísticas** (combinar reglas: ¿un producto de $60.000 con 20 % de descuento queda sobre el umbral de $50.000?).
4. Diseñar los casos de prueba.
5. Ejecutar la prueba.
6. Comparar **resultado esperado vs. obtenido**.

### 1.4 Casuísticas: lo que enseñan los ejemplos
- Las reglas **se cruzan** (descuento × envío gratis): hay que decidir cuál rige y probar el borde.
- **Concurrencia / condición de carrera:** dos clientes quieren la última unidad a la vez → ¿cuándo se descuenta el stock?, ¿hasta dónde puede llegar el segundo?, ¿qué pasa si ambos aprietan "Comprar" casi al mismo tiempo?
- Cada pregunta sin respuesta clara es un **requisito que falta definir**, no un detalle de implementación.

### 1.5 Plan de pruebas y caso de prueba
- **Plan de pruebas:** organiza cómo se aborda el testing: qué partes se prueban (catálogo, carrito, descuentos, stock, checkout, pagos), qué situaciones se contemplan, qué se necesita para testear y qué resultados se esperan. Ejemplo de la clase: plan del *Carrito* = agregar, modificar cantidad, eliminar, verificar total, verificar descuento.
- **Caso de prueba:** documento donde se plasma el comportamiento del sistema (**resultado obtenido**) y cuál debería ser el **resultado esperado**.

---

## 2. Qué hay hoy en el proyecto (evidencia)

| Aspecto | Estado | Evidencia |
|---|---|---|
| Pruebas automatizadas | **Rotas / inexistentes** | Único test: `frontend/test/widget_test.dart`, la plantilla del contador de Flutter. `flutter test` → `Error: Couldn't find constructor 'MyApp'` (la app se llama `SoundCheckProApp`). **0 pruebas pasan.** |
| Integración continua | Solo compila y publica | `.github/workflows/deploy.yml`: `pub get` → `build web` → deploy. No corre `flutter analyze` ni `flutter test`. Cada push a `main` se publica sin ningún control. |
| Análisis estático | Existe, no se exige | `flutter_lints`; `flutter analyze` da 68 avisos informativos y 0 errores, pero nada lo verifica en CI. |
| Requisitos y criterios de aceptación | No están escritos de forma verificable | `CONTEXTO_PARA_IA.md` documenta decisiones y funciones, no requisitos con identificador ni resultados esperados. |
| Casos de prueba / plan de pruebas | No existen | Las pruebas hechas hasta ahora fueron manuales y ad hoc (registradas en conversación, no repetibles). |
| Registro de defectos | No existe | No hay plantilla ni lista de bugs conocidos (solo menciones sueltas en `CONTEXTO_PARA_IA.md`). |
| Pruebas de reglas de seguridad | No existen | `firestore.rules` y `storage.rules` sin pruebas con emulador. |
| Medición de desempeño | No existe | `main.dart.js` pesa **5,2 MB**; `build/web` 39 MB (con assets). Sin presupuesto ni mediciones. |

**QC (producto):** hoy es solo manual y ocasional. **QA (proceso):** se trabaja directo sobre `main` con despliegue automático sin barreras: un error de compilación se detiene en el build, pero un error de comportamiento llega a producción.

Dato favorable: la lógica pura **sí se puede probar sin refactorizar**. El probe importó `main.dart` desde `flutter test` y ejecutó funciones reales sin problema.

---

## 3. Hallazgos

Severidad: **A** alta · **M** media · **B** baja. Los marcados ✔ están **confirmados ejecutando código**.

| # | Hallazgo | Característica / regla | Sev. |
|---|---|---|---|
| T1 ✔ | **El único test está roto y `flutter test` falla.** No hay red de seguridad: cualquier cambio puede romper algo sin que nadie se entere. | QC | **A** |
| T2 | **CI sin analizar ni testear.** Todo push a `main` se publica. Es el punto donde QA (prevenir) debería actuar. | QA | **A** |
| T3 ✔ | **Falso positivo en la detección del sonidista.** `esRolSonidista('Vocalista de Somos Mil')` → `true` (por la palabra clave "de som"): un cantante que escribe su banda entra al panel del sonidista. Otros casos que dan `true`: "Ayudante de sonido", "Músico y sonidista" (¿deseado? no está definido). | Adecuación funcional | **A** |
| T4 ✔ | **Falsos negativos:** "Ingeniero de audio", "Operador de audio", "Monitorista" y "FOH" dan `false` aunque son roles de sonido reales. | Adecuación funcional | M |
| T5 ✔ | **La transposición ignora la notación latina.** `[Do]a [Re]b [Mi]c` +2 devuelve el texto **sin cambios** y sin aviso. En Latinoamérica es una notación muy usada. | Adecuación funcional | **A** |
| T6 ✔ | **Ortografía de notas sin criterio tonal.** `C G Am F` +3 → `D# A# Cm G#` (un músico espera `Eb Bb Cm Ab`). No es incorrecto, pero se lee raro. | Adecuación funcional / usabilidad | B |
| T7 | **"Deshacer" puede pisar cambios ajenos.** Al borrar un pedido se guarda la copia que tenía la pantalla (`data`) y "Deshacer" hace `ref.set(data)`: si otro sonidista lo marcó atendido justo antes, el deshacer **revierte** ese cambio. Y si dos sonidistas actúan sobre el mismo pedido a la vez, `update` sobre un documento ya borrado lanza una excepción sin mensaje. (Riesgo por inspección de código; no reproducido.) | Casuística de concurrencia | M |
| T8 | **Unirse con un PIN inexistente "funciona".** La sala no es un documento propio; el sistema no puede saber si el código existe, así que un error de tipeo de 8 caracteres entra a una sala vacía sin aviso. Requisito sin definir. | Casuística / requisito | M |
| T9 | **Reglas de seguridad sin pruebas.** Matriz esperada (invitado ≠ frases/biblioteca, `esPro` no escribible, perfil propio) solo se verificó leyendo las reglas. | Adecuación funcional (seguridad) | M |
| T10 | **Concurrencia de secuencias sin probar:** dos personas cambiando tono/tempo/volumen de la misma pista a la vez (hoy gana el último en escribir). | Casuística | M |
| T11 | **Consultas sin límite.** 12 `snapshots()` y 2 `limit()`: la lista de pedidos de una sala (stream) crece sin tope y cada dispositivo la descarga completa. | Eficiencia de desempeño | M |
| T12 | **Desempeño sin medir.** No hay presupuesto de carga (5,2 MB de JS), latencia pedido→panel ni consumo de lecturas. | Eficiencia de desempeño | M |
| T13 | **Código muy acoplado:** ~10 000 líneas en un archivo, servicios con acceso estático a Firebase. La lógica pura se prueba bien (probado); lo que toca Firebase (formularios, pedidos) exige introducir costuras (fakes) para automatizar. | Testabilidad | M |
| T14 | **Sin proceso de defectos ni definición de "hecho".** No hay plantilla de reporte, ni checklist previo a publicar. | QA | M |

### Lo que ya funciona (evidencia de esta sesión)
- Sin errores en: generación de código de sala (2 000 códigos: todos distintos, 8 caracteres, sin 0/1/O/I/L), resolución de idioma (`ja`→es, `pt-BR`→pt, `en-GB`→en, lista vacía→es), mensajes de error amigables, traducción de roles guardados, paleta por defecto, transposición con bemoles/sostenidos/bajos (`[G/B]`, `[A7/C#]`), idempotencia a ±12 semitonos.
- Recorrido manual en producción de crear/unirse, pedidos (rápido, personalizado, urgente), panel del sonidista, respuesta privada, historial, borrar todo, cinco idiomas y modo claro/oscuro (ver `AUDITORIA_USABILIDAD.md` y notas del proyecto).

---

## 4. Plan de pruebas (qué se prueba y cómo)

### 4.1 Plantilla de caso de prueba (la que se usará)
| Campo | Contenido |
|---|---|
| ID / Módulo | CP-xx · Acceso, Pedidos, Idioma, Cifrado, Secuencias, Seguridad, Desempeño |
| Requisito | RQ-xx que cubre |
| Precondiciones | Estado inicial, datos, rol, dispositivo/navegador |
| Pasos | Acciones numeradas |
| Resultado esperado | Qué debería pasar |
| Resultado obtenido | Qué pasó (fecha, versión) |
| Estado | Pasó · Falló · Bloqueado · No probado |
| Defecto asociado | DF-xx si falló |

### 4.2 Casos de prueba iniciales (con resultado actual)

**Acceso y salas**
| ID | Caso | Esperado | Obtenido (24-oct) | Estado |
|---|---|---|---|---|
| CP-01 | Crear sala con nombre y rol válidos | Entra; título "Nombre (Rol)" | Entra con título correcto (web) | Pasó |
| CP-02 | Crear sala con campos vacíos | Errores bajo cada campo; no entra | Errores en línea; no entra | Pasó |
| CP-03 | Unirse con PIN de 7 caracteres | "El código tiene 8 caracteres." | Igual | Pasó |
| CP-04 | Unirse con PIN de 8 caracteres que no existe | A definir (RQ-03): avisar o crear | Entra a sala vacía sin aviso | **Falló / por definir** (T8) |
| CP-05 | Rol "Sonido" | Panel del sonidista | Panel | Pasó |
| CP-06 | Rol "Vocalista de Somos Mil" | **No** entra al panel | Entra al panel | **Falló** (T3) |
| CP-07 | Roles "Ingeniero de audio", "FOH", "Monitorista" | A definir (RQ-04) | Pantalla de pedidos | Por definir (T4) |

**Pedidos**
| ID | Caso | Esperado | Obtenido | Estado |
|---|---|---|---|---|
| CP-08 | Pedido rápido | Llega al sonidista con nombre y rol | Llega | Pasó |
| CP-09 | Pedido urgente | Resaltado en el panel | Resaltado con ícono rojo | Pasó |
| CP-10 | Marcar atendido | Pasa a Historial | Pasa | Pasó |
| CP-11 | Borrar + Deshacer | El pedido vuelve igual | Vuelve | Pasó |
| CP-12 | Sonidista A borra mientras B ya lo marcó atendido, y A deshace | Debe respetar el estado más reciente (a definir) | No probado; por código revierte `atendido` | **No probado (T7)** |
| CP-13 | "Borrar todo" mientras un músico envía | Ningún pedido nuevo se pierde sin aviso | No probado | No probado |
| CP-14 | Respuesta privada | Se ve bajo el pedido del músico | Se ve | Pasó |
| CP-15 | Salir de la sala: Cancelar / Salir | Cancelar permanece; Salir vuelve al menú | Igual | Pasó |

**Idioma y apariencia**
| ID | Caso | Esperado | Obtenido | Estado |
|---|---|---|---|---|
| CP-16 | Dispositivo en japonés | App en español | Español (resolver) | Pasó |
| CP-17 | Dispositivo en pt-BR / en-GB | Portugués / inglés | Igual (resolver) | Pasó |
| CP-18 | Elegir italiano y recargar | Persiste | Persiste | Pasó |
| CP-19 | Idioma guardado ya eliminado (ej. `ja`) | Vuelve al idioma del dispositivo | Por código sí; no ejecutado | No probado |
| CP-20 | Cambiar de paleta con modo oscuro activo | Sigue oscuro | Sigue oscuro | Pasó |
| CP-21 | Texto del sistema al 150 % | Sin desbordes ni textos cortados | No probado | No probado |

**Cifrado / transposición**
| ID | Caso | Esperado | Obtenido | Estado |
|---|---|---|---|---|
| CP-22 | `[C]Hola [G/B]mundo [Am7]hoy` +2 | `[D]… [A/C#]… [Bm7]…` | Igual | Pasó |
| CP-23 | `[Do]a [Re]b [Mi]c` +2 | `[Re]… [Mi]… [Fa#]…` (a definir RQ-05) | Sin cambios | **Falló** (T5) |
| CP-24 | +12 y −12 semitonos | Texto idéntico | Idéntico | Pasó |
| CP-25 | Bemoles se conservan (`[Db]a [Ebm]b` +3) | `[E]a [Gbm]b` | Igual | Pasó |
| CP-26 | `C G Am F` +3 | `Eb Bb Cm Ab` (preferible) | `D# A# Cm G#` | Observación (T6) |

**Secuencias**
| ID | Caso | Esperado | Obtenido | Estado |
|---|---|---|---|---|
| CP-27 | Archivo > 50 MB (web) | Se convierte a MP3 antes de subir | Verificado en sesiones anteriores | Pasó (histórico) |
| CP-28 | Dos usuarios cambian tono a la vez | Resultado definido y consistente (RQ-06) | No probado | No probado (T10) |
| CP-29 | Límites ±12 semitonos, tempo 50–150 %, volumen 0–100 % | Botones se detienen en el borde | No automatizado | No probado |

**Seguridad (reglas)**
| ID | Caso | Esperado | Obtenido | Estado |
|---|---|---|---|---|
| CP-30 | Invitado lee/escribe `usuarios/{uid}/frases` | Denegado | No ejecutado | No probado (T9) |
| CP-31 | Cliente escribe `esPro = true` en su perfil | Denegado | No ejecutado | No probado |
| CP-32 | Usuario A lee el perfil de B | Denegado | No ejecutado | No probado |

**Desempeño**
| ID | Caso | Esperado (a fijar) | Obtenido | Estado |
|---|---|---|---|---|
| CP-33 | Carga inicial web en 4G | < 4 s hasta interactiva | No medido (JS: 5,2 MB) | No probado (T12) |
| CP-34 | Pedido enviado → visible en el panel | < 2 s | Percibido ≈ 1–3 s; no medido | No probado |
| CP-35 | Sala con 500 pedidos | Sin degradación | No probado (stream sin límite) | No probado (T11) |

Resumen de los 35 casos: **18 pasaron · 3 fallaron (CP-04, CP-06, CP-23) · 1 por definir (CP-07) · 1 observación (CP-26) · 12 no probados**. (Los 18 que pasaron incluyen el histórico CP-27, que no se repitió hoy.)

### 4.3 Casuísticas para definir con el negocio (preguntas "¿qué debería pasar?")
| # | Pregunta | Por qué importa |
|---|---|---|
| RQ-03 | ¿Qué pasa si alguien se une a una sala que no existe? ¿Se avisa, se crea, se valida con la lista de salas del sonidista? | CP-04, T8 |
| RQ-04 | ¿Qué palabras identifican a un rol de sonido? ¿"Músico y sonidista" entra al panel? ¿Se ofrece elegir entre pantalla de pedidos y panel? | CP-06/07, T3, T4 |
| RQ-05 | ¿Se soporta notación latina (Do-Re-Mi) y qué hacer con acordes no reconocidos (avisar o ignorar)? | CP-23, T5 |
| RQ-06 | Si dos personas cambian el tono a la vez, ¿gana el último, se bloquea o se avisa? | CP-28, T10 |
| RQ-07 | Si un pedido se borró y otro sonidista ya lo había atendido, ¿"Deshacer" qué estado restaura? | CP-12, T7 |
| RQ-08 | ¿Hasta cuántos pedidos y cuánto tiempo se conservan en una sala? | T11, CP-35 |

---

## 5. Plan de trabajo por etapas

Criterio de orden: primero la **red de seguridad** (barata y de mayor impacto), después **corregir lo que ya se sabe que falla**, luego **ampliar la cobertura** hacia lo difícil (concurrencia, reglas, desempeño). Esfuerzo: S ≈ medio día · M ≈ 1–2 días · L ≈ 3+ días.

### Etapa 0 — Requisitos y decisiones del negocio (S)  *(pasos 1–2 del camino del test)*
1. Escribir la lista de requisitos verificables (RQ-01…) a partir de `CONTEXTO_PARA_IA.md`, cada uno con criterio de aceptación.
2. Resolver las casuísticas RQ-03 a RQ-08 de la sección 4.3 y dejar la decisión escrita.
- **Aceptación:** documento de requisitos y decisiones; cada caso CP tiene su RQ.

### Etapa 1 — Red de seguridad mínima (S)  *(T1, T2; QA)*
1. **Reparar** `widget_test.dart` (reemplazar el test del contador por una prueba de arranque real o borrarlo).
2. Agregar al workflow un job `test` previo al build: `flutter pub get` → `flutter analyze` (falla con errores) → `flutter test`; el deploy depende de que pase.
3. Definir qué es "hecho": analyze sin errores, tests en verde, checklist manual corto.
- **Aceptación:** un commit que rompe un test **no se publica**.

### Etapa 2 — Pruebas unitarias de la lógica pura y corrección de defectos (M)  *(T3–T6; CP-05…CP-07, CP-22…CP-26)*
1. Convertir el probe usado en esta auditoría en pruebas permanentes: `esRolSonidista`, `ChordTransposer`, `generarCodigoSala`, `IdiomasApp.resolver`, `mensajeError`, `rolParaMostrar`, `AppPalette.porClave`, estados del setlist y límites de tono/tempo/volumen (valores frontera: −13, −12, 0, +12, +13; 49, 50, 150, 151 %).
2. Escribir **primero** el test que falla y luego corregir (T3: reemplazar la heurística "de som" por reglas explícitas y una lista acordada; T5: soportar Do-Re-Mi o avisar; T6: ortografía según tonalidad).
3. Pruebas de **tablas de casos** (entrada → salida) en lugar de muchas pruebas sueltas, para sumar roles/acordes nuevos sin esfuerzo.
- **Aceptación:** ≥ 40 casos unitarios en verde; T3 y T5 cerrados.

### Etapa 3 — Pruebas de widgets y flujos con servicios simulados (L)  *(T13; CP-01…CP-03, CP-08…CP-11, CP-15)*
1. Introducir **costuras mínimas** para Firebase (interfaces o `fake_cloud_firestore` / `firebase_auth_mocks`) sin reescribir la app.
2. Pruebas de widget: validaciones en línea de Crear/Unirme/Acceso sonidista, diálogo de salida (cancelar/confirmar), borrar + deshacer, entrada directa al panel por rol.
3. Una prueba de integración de "camino feliz": crear sala → enviar pedido → verlo en el panel.
- **Aceptación:** los flujos CP-01…CP-15 corren sin red y en menos de 2 minutos.

### Etapa 4 — Pruebas de reglas de seguridad con emulador (M)  *(T9; CP-30…CP-32)*
1. Tests con el emulador de Firestore/Storage y `@firebase/rules-unit-testing`: matriz usuario anónimo / cuenta real / dueño / otro usuario × cada colección.
2. Incluir los "no se debe poder": `esPro`, perfiles ajenos, escritura de biblioteca por invitados, borrado de perfil.
3. Ejecutarlas en CI cuando cambie `firestore.rules` o `storage.rules`.
- **Aceptación:** matriz completa en verde; una regla modificada sin querer rompe el build.

### Etapa 5 — Casuísticas de concurrencia (M)  *(T7, T10; CP-12, CP-13, CP-28)*
1. Con el emulador, simular **dos clientes** simultáneos: dos sonidistas sobre el mismo pedido (atender vs. borrar vs. deshacer), "Borrar todo" mientras entra un pedido, dos cambios de tono a la vez.
2. Aplicar la decisión de RQ-06/RQ-07 (p. ej. transacciones o comparar versión antes de restaurar) y mostrar un mensaje claro si la acción ya no es posible.
3. Manejar el error de `update` sobre un documento borrado (hoy sin mensaje).
- **Aceptación:** cada casuística tiene un resultado definido, probado y sin excepciones silenciosas.

### Etapa 6 — Eficiencia de desempeño (M)  *(T11, T12; CP-33…CP-35)*
1. Fijar un **presupuesto** (carga interactiva en 4G, tamaño de JS, latencia pedido→panel) y medirlo con Lighthouse/DevTools; guardar la línea base.
2. Limitar y paginar las consultas (p. ej. últimos N pedidos, `limit` en listas), medir lecturas por sesión.
3. Prueba de carga ligera: sala con cientos de pedidos y varios clientes.
- **Aceptación:** métricas registradas y dentro del presupuesto; las listas no crecen sin tope.

### Etapa 7 — Regresión manual guiada y gestión de defectos (S, recurrente)  *(T14; QA)*
1. Checklist de humo de 10–15 casos (los de la sección 4.2 marcados "Pasó") para ejecutar antes de cada publicación, en navegador de escritorio, celular y Android.
2. Plantilla de **reporte de defecto** (ID, pasos, esperado, obtenido, severidad, capturas) y una lista viva `DEFECTOS.md`.
3. Revisión periódica: casos "no probados" → programar o descartar.
- **Aceptación:** cada release tiene una corrida registrada; los defectos tienen dueño y estado.

### Resumen
| Etapa | Foco | Hallazgos | Esfuerzo | Depende de |
|---|---|---|---|---|
| 0 | Requisitos y decisiones | T3, T4, T8, T10 | S | — |
| 1 | Red de seguridad en CI | T1, T2 | S | — |
| 2 | Unitarias + corregir T3/T5/T6 | T3–T6 | M | 0 (decisiones), 1 |
| 3 | Widgets y flujos simulados | T13 | L | 1 |
| 4 | Reglas de seguridad | T9 | M | 1 |
| 5 | Concurrencia | T7, T10 | M | 0, 3–4 |
| 6 | Desempeño | T11, T12 | M | 1 |
| 7 | Regresión y defectos | T14 | S, recurrente | 1 |

**Recomendación de arranque:** Etapas **0 y 1** (medio día cada una, sin riesgo) y enseguida la **2**, porque ya hay dos defectos confirmados (T3 y T5) que se pueden corregir con tests primero.

---

## 6. Estado de implementación (actualizado 24-oct-2026)

| Etapa | Estado |
|---|---|
| 0 Requisitos y decisiones | **Hecha con una salvedad.** `REQUISITOS.md` define 19 requisitos con criterio de aceptación y la definición de "hecho". Las 6 decisiones del negocio (D-03…D-08) están escritas **como propuesta, pendientes de confirmación del dueño del producto**. Defectos confirmados registrados en `DEFECTOS.md` (DF-01…DF-08) |
| 1 Red de seguridad en CI | **Hecha.** `widget_test.dart` (roto) reemplazado por `frontend/test/logica_pura_test.dart`: **43 pruebas pasan y 6 están en `skip`** documentando defectos abiertos (verificado con `flutter test --run-skipped`: las 6 fallan, o sea que son reales). `.github/workflows/deploy.yml` ahora tiene `test` (`flutter analyze --no-fatal-infos` + `flutter test`) → `build` → `deploy`; en pull requests solo corre `test`. YAML validado con el parser de Dart; **la ejecución real en GitHub se verifica con el primer push** |
| 2 Unitarias + corregir defectos | Parcial: la base de pruebas existe; faltan corregir DF-01/02/03 (esperan D-04 y D-05) y ampliar casos (límites de tono/tempo, estados del setlist) |
| 3–7 | Pendientes |
