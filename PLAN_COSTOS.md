# Plan de costos para uso masivo (toda Latinoamérica)

Escrito el 11-nov-2026. Objetivo: que la app siga costando **centavos por usuario activo al mes** aunque la usen muchísimos músicos y todos suban PDF y secuencias. 🔑 = necesita una acción o decisión del dueño.

> Los precios son **de lista y de memoria** (orden de magnitud). Hay que confirmarlos en las páginas de cada proveedor antes de decidir con plata (ítem B-10). Los números de uso son **supuestos** declarados abajo; la Fase 0 sirve para reemplazarlos por números reales.

## 1. La idea en una frase
En esta app los costos grandes no están en la base de datos, están en los **archivos**: se guardan para siempre y se descargan muchas veces. Por eso el plan es: **(1) no pagar por descargas, (2) guardar menos bytes, (3) no guardar dos veces lo mismo, (4) poner topes para que nadie pueda gastarnos la plata**, y recién después tocar Firestore.

## 2. Dónde está hoy cada cosa (revisado en el código)
| Tema | Hoy | Problema a escala |
|---|---|---|
| Archivos | Bucket **público** de Supabase (`repertorio-pdfs`), ruta `usuarios/{uid}/canciones|secuencias/…` | Se paga por descarga (egress) y por GB guardado; el plan gratis (1 GB / 5 GB de descarga, aprox.) se agota enseguida |
| Tamaño de PDF | **Sin límite propio** en la app | Un solo usuario puede subir PDFs enormes |
| Tamaño de audio | Hasta 50 MB por archivo (`SecuenciasService.tamanoMaximoBytes`); se aceptan `wav` | Un WAV de 40 MB por secuencia multiplica el costo ×4 |
| Cuota por cuenta | **No existe** | Una cuenta puede subir sin tope: ataque o abuso = factura |
| Duplicados | **No se detectan**: 1.000 músicos subiendo el mismo PDF guardan 1.000 copias | Muchísimo desperdicio con canciones populares |
| Copias en salas | Ya son referencias (se copia la URL, no el archivo) | Bien: no cambiar |
| Descarga en el celular | Ya se guarda en el dispositivo (Android) y en el navegador (web): cada archivo se baja una vez por dispositivo | Bien. Reduce mucho la descarga repetida |
| Plan Pro | Existe el campo `esPro` y la bandera `kFuncionesProGratisPorAhora = true` | Base lista para poner cuotas distintas gratis/Pro |
| Firestore | 12 escuchas en vivo, 4 con tope de 10 a 200 (DF-08); la presencia se escribe 1 vez al entrar a una sala | Costo bajo, pero las escuchas sin tope pueden crecer sin control |

## 3. Escenario de cálculo (para fijar ideas)
**Supuestos** (cambiarlos con datos reales en la Fase 0):
- 1.000.000 de cuentas, 300.000 activas por mes.
- Cada cuenta sube en promedio 25 PDF de 0,8 MB (20 MB) y 6 secuencias de 9 MB en MP3 (54 MB): **≈ 75 MB** por cuenta → **75 TB** en total. Caso malo (se permiten WAV de ~35 MB): ≈ 230 MB por cuenta → 230 TB.
- Cada cuenta activa baja ≈ 50 MB al mes (archivos de compañeros, dispositivos nuevos): **15 TB/mes**. Caso malo ×3: 45 TB/mes.
- Firestore: ≈ 700 operaciones por show de 6 personas y 4 shows al mes por cuenta.

| Concepto | Hoy (estilo Supabase/Firebase) | Con este plan |
|---|---|---|
| Guardado | 75 TB × ≈ 0,021 USD/GB ≈ **1.600 USD/mes** (caso malo ≈ 4.800) | ≈ 20 MB por cuenta (comprimido, sin duplicados, con cuota) = 20 TB × 0,015 ≈ **300 USD/mes** |
| Descarga | 15 TB × ≈ 0,09 USD/GB ≈ **1.350 USD/mes** (caso malo ≈ 4.000) | **≈ 0** (almacenamiento sin cargo por descarga + caché CDN) |
| Operaciones de archivos | incluidas | ≈ 100–200 USD/mes |
| Firestore | ≈ 300 USD/mes si todo va bien, **varios miles** si hay escuchas sin tope | ≈ 300 USD/mes |
| **Total aproximado** | **≈ 3.300 USD/mes (hasta ≈ 12.000)** | **≈ 750 USD/mes** ≈ 0,0025 USD por activo |

Ejemplo ilustrativo de ingresos: si solo el 3 % de las 300.000 cuentas activas pagara 2 USD al mes, serían 18.000 USD/mes, muy por encima de 750. Lo importante es que **el costo por usuario gratuito sea casi cero** y esté **acotado por cuota**.

## 4. Las seis palancas (de mayor a menor ahorro)
1. **Descargas sin cargo.** Mover los archivos a un almacenamiento que no cobra por descarga (Cloudflare R2, S3 compatible) delante de una CDN. Como el archivo se nombra por su contenido (hash), se puede cachear "para siempre" y casi todas las descargas ni llegan al almacenamiento.
2. **Cuotas y topes.** Tamaño máximo por archivo, cantidad y MB por cuenta (distintos para gratis y Pro), aplicados **en el servidor** (el celular se puede modificar). Es la defensa contra abuso y limita el peor caso.
3. **Archivos más livianos.** Audio a ≈ 128 kbps (AAC/MP3) al subir y sin WAV; un MP3 de 5 minutos pasa de ≈ 9 MB a ≈ 4,5 MB. PDFs con tope de tamaño y aviso.
4. **Sin duplicados (dedupe por hash).** Se calcula SHA-256 en el celular antes de subir; si ya existe, no se sube: la cuenta solo guarda una referencia. Con canciones populares ahorra mucho. Con conteo de referencias para borrar solo cuando nadie lo usa.
5. **Ciclo de vida.** Borrar huérfanos, archivos sin uso en 12 meses (con aviso), salas y pedidos viejos. Lo que no se guarda no se paga.
6. **Firestore ordenado.** Tope a todas las escuchas, no leer colecciones enteras, región cercana (São Paulo) y TTL de pedidos.

Extra opcional: **repartir dentro de la sala por red local** (un celular baja el archivo y se lo pasa a los demás sin internet). Ahorra descarga y sirve de respaldo si se cae la red.

## 5. Plan de trabajo por fases
Orden recomendado: 0 → 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8. Esfuerzo: S ≈ medio día · M ≈ 1–2 días · L ≈ 3+ días.

| Fase | Qué se hace | Esf. | Ahorro / efecto | Depende de | 🔑 |
|---|---|---|---|---|---|
| **0. Medir y proteger** (B-33) | Alertas de presupuesto en Firebase y Supabase; registrar en la app cuántos archivos y MB sube cada cuenta; **tope de tamaño de PDF** (p. ej. 10 MB) y bajar el de audio (p. ej. 30 MB); revisar planes y cuotas reales (B-10) | S–M | Evita sorpresas y el abuso más obvio. Reemplaza los supuestos por números | — | Acceso a las consolas; decidir los topes |
| **1. Cuotas por cuenta** (B-34) | Cantidad y MB máximos por cuenta, gratis vs Pro (usando `esPro`), aplicados en el servidor. Mensajes claros al llegar al tope y cómo liberar espacio | M–L | Acota el peor caso por cuenta | Fase 0; se implementa en el servicio de la Fase 3 | 🔑 Decidir cuotas gratis y Pro |
| **2. Archivos más livianos** (B-35) | Audio: convertir a ≈ 128 kbps al subir (la web ya convierte a MP3 con `conversor_mp3.js`; en Android evaluar una librería de transcodificación o hacerlo en el servidor); rechazar WAV; mostrar el tamaño estimado antes de subir | M | Mitad de los bytes de audio | Fase 0 | 🔑 Aprobar bajar la calidad |
| **3. Almacenamiento nuevo** (B-36) | Cuenta en **Cloudflare**, bucket R2 y un pequeño servicio delante (Worker): subida firmada, chequeo de cuota (Fase 1), nombre por hash y `Cache-Control` inmutable. En la app, un nuevo `storageProvider: 'r2'` que **convive** con `supabase` y `firebase` (ya se distingue por ese campo); los archivos viejos se migran de a poco | L | Descargas ≈ 0; guardado más barato | Fases 0–1 | 🔑 Cuenta de Cloudflare y medio de pago |
| **4. Dedupe por hash** (B-37) | Tabla/colección de archivos por hash con conteo de referencias; la app calcula el hash, pregunta si existe y solo referencia; el borrado de cuenta y de archivos resta referencias (adaptar el borrado actual de "Eliminar mi cuenta"); actualizar términos de uso | L | Guardado ÷ 2 o más con contenido popular | Fase 3 | 🔑 Aprobar términos y revisar derechos de autor |
| **5. Ciclo de vida** (B-38) | Limpieza de huérfanos y de archivos sin uso en 12 meses (con aviso por la app), salas inactivas y pedidos viejos (TTL de Firestore, ver B-23) | M | Lo viejo no sigue costando | Fase 3 | 🔑 Plan Blaze si hacen falta funciones |
| **6. Firestore ordenado** (B-39) | Auditoría de las 12 escuchas (tope y paginación, ver B-16), presencia con frecuencia máxima, revisar lecturas por pantalla y **la región** de la base | M | Evita facturas inesperadas de lectura | — (puede ir en paralelo) | 🔑 Índices; decidir región |
| **7. Reparto en la sala por red local** (B-40) | Nearby Connections (Android): un celular baja, los demás copian por Wi-Fi/Bluetooth | L | Menos descarga y funciona sin internet | Fase 3 | — |
| **8. Planes y cobro** (B-41) | Google Play Billing (15 %) y, para la web, un medio de pago local (por ejemplo Mercado Pago); precios por país (poder adquisitivo) | L | Financia el servicio | Fases 1–3 | 🔑 Precios, cuenta de cobro, impuestos |

## 6. Decisiones que necesito de vos 🔑
1. **Cuotas gratis y Pro** (cantidad de canciones, de secuencias y MB). Propuesta inicial: gratis 100 MB y 30 archivos; Pro 2 GB.
2. **Topes de archivo**: PDF 10 MB y audio 30 MB (¿ok?).
3. **Permitir WAV o no** (propuesta: no; se convierte a ≈ 128 kbps).
4. **Dedupe y derechos de autor**: ¿aceptás guardar una sola copia cuando dos cuentas suben el mismo archivo? (cada cuenta sigue viendo "su" archivo; hace falta decirlo en los términos de uso).
5. **Cuenta de Cloudflare** y medio de pago, y pasar Firebase a **Blaze** (también lo pide B-32).
6. **Región** de Firestore (revisar ahora: no se puede cambiar después).
7. **Si se cobra**: qué se vende, a qué precio y en qué países.

## 7. Riesgos y cómo se cubren
| Riesgo | Cómo se cubre |
|---|---|
| Abuso: alguien sube miles de GB | Cuotas del servidor (Fases 0–1) + alerta y tope de presupuesto + límite de subidas por minuto |
| Perder archivos al migrar | Migración gradual, `supabase` y `r2` conviviendo; no se borra lo viejo hasta verificar |
| Dedupe borra un archivo ajeno | Conteo de referencias y pruebas del borrado de cuenta antes de activarlo |
| Derechos de autor (PDF y audios de terceros) | Términos de uso claros, vía de reclamo y baja; consultar a una persona con conocimiento legal |
| Proveedor único (Cloudflare) cae o cambia precios | Mantener `storageProvider` por archivo para poder mover de a partes; copia de los metadatos |
| Cambiar la calidad del audio molesta | Avisar antes de subir y conservar el original solo si la cuenta es Pro (opcional) |

## 8. Cómo sabemos que funcionó
- Costo total ≤ 0,005 USD por usuario activo al mes (meta ≈ 0,0025).
- Costo de descargas ≈ 0 (más del 95 % de las descargas salen de la CDN).
- Ninguna cuenta supera su cuota (probado con una cuenta de prueba que intente pasarla).
- Aviso de presupuesto configurado y probado.
- Hay un tablero (o una planilla) con MB guardados, descargas y lecturas de Firestore por mes.

## 9. Qué se puede hacer ya, sin esperar decisiones
- **B-39 (parte de auditoría):** contar escuchas y lecturas por pantalla y poner topes que no cambian el comportamiento.
- **B-33 (parte de código):** registrar tamaño y cantidad por cuenta; dejar el tope de PDF configurable.
- Diseñar el servicio de la Fase 3 en papel (rutas, firma, hash, cuotas) para tenerlo listo cuando exista la cuenta de Cloudflare.
- Dejar el flujo de subida en la app detrás de una sola función (`subirArchivo`) para cambiar de proveedor sin tocar las pantallas.

Todo lo demás espera tus decisiones de la sección 6.

## 10. Dedupe de PDF sin cambiar la interfaz (diseño para la Fase 4)
Pregunta del dueño (11-nov-2026): ¿se puede evitar que el mismo PDF se guarde en cada cuenta sin tocar la interfaz? **Sí.** La persona sigue viendo "su" canción, con su título y tonalidad; solo cambia dónde vive el archivo.

**Cómo, con lo que ya hay (Supabase + Firestore, sin plan Blaze):**
1. **Huella.** Antes de subir, la app calcula el SHA-256 de los bytes (hace falta agregar el paquete `crypto`, hoy no está en `pubspec.yaml`).
2. **Ruta compartida.** El archivo va a `compartido/pdf/{huella}.pdf` en vez de `usuarios/{uid}/canciones/…`. Si ya existe (consulta al bucket), **no se sube**.
3. **Enlace por cuenta.** Una tabla en Supabase `archivo_enlaces(huella, uid, bytes, creado)` con clave `(huella, uid)` y políticas RLS por `uid` (la app ya manda el token de Firebase). Sirve para contar quién usa cada archivo.
4. **Metadatos.** El documento de Firestore de la canción sigue igual y suma `pdfHash` y `compartido: true`. `storageProvider` sigue siendo `supabase`.
5. **Borrar.** Si `compartido == true`, "Eliminar" borra solo el enlace de esa cuenta, nunca el archivo (cambio en `eliminarCancion` y en `archivosDeCuenta`, que usa "Eliminar mi cuenta").
6. **Limpieza.** Un trabajo semanal (GitHub Actions con la clave de servicio de Supabase, gratis) borra los archivos de `compartido/` sin enlaces con más de 7 días. También verifica que el nombre coincida con la huella real y descarta los que no.
7. **Políticas del bucket.** En `compartido/`: leer público, subir solo si no existe (sin pisar), y **ningún cliente borra**.

**Limitaciones honestas:**
- Solo detecta archivos **idénticos byte a byte** (el mismo PDF reenviado por WhatsApp, descargado del mismo lugar). Dos exportaciones distintas de la "misma" canción, aunque se vean igual, tienen huellas distintas. El ahorro real depende de cuánto se reenvíen los PDF entre bandas; no se puede medir hasta tener usuarios (por eso conviene dejar el registro de huellas desde ya).
- **Envenenamiento:** alguien podría subir un archivo falso con la huella de uno popular. Se reduce con "no pisar", la verificación semanal y comparar el tamaño al reutilizar; no queda en cero sin un servidor que verifique cada subida (Cloudflare Worker de la Fase 3).
- **Privacidad:** se puede deducir si un archivo exacto ya existe en la plataforma (porque no se sube). Es un riesgo menor; hay que decirlo en la política de privacidad.
- Los PDF ya subidos **no se unifican** (habría que reescribir las URL en Firestore). Por eso conviene activarlo **antes** de tener mucha data.
- La misma técnica sirve para las secuencias de audio, donde el ahorro por archivo es mucho mayor.

**Esfuerzo:** M–L. Código en la app (huella, subir, borrar, cuenta eliminada) + SQL en Supabase + el trabajo semanal. El SQL lo tiene que correr el dueño en Supabase (o se hace con el navegador cuando esté conectado).
