# Defectos conocidos

Registro vivo de defectos (parte de la Etapa 7 del plan de testing, adelantado para respaldar las pruebas marcadas `skip`). Formato por defecto: **ID · severidad · estado · cómo reproducir · esperado · obtenido · prueba · decisión relacionada**.

Estados: **Abierto** · **Esperando decisión** · **En curso** · **Corregido** (con commit).

## Abiertos

### DF-04 · Media · Esperando decisión (D-03, no aplicada)
Unirse con un código de 8 caracteres inexistente entra a una sala vacía sin aviso.
- **Reproducir:** Unirme a sala → código `ZZZZZZZZ` + nombre + rol.
- **Esperado (propuesto):** aviso "Esa sala no existe. Revisá el código." y no entrar.
- **Obtenido:** entra a la sala vacía.
- **Por qué sigue abierto:** la corrección propuesta cambia las reglas de Firestore de producción y deja sin acceso a las salas ya creadas (no tienen el documento `salas/{código}`); necesita autorización y una migración.
- **Prueba:** pendiente (Etapa 3, requiere servicios simulados).

### DF-06 · Baja · Abierto
La transposición escribe sostenidos aunque el texto original no tenga alteraciones: `C G Am F` +3 → `D# A# Cm G#` (un músico espera `Eb Bb Cm Ab`).
- **Prueba:** pendiente (depende de la lógica de tonalidad).

### DF-08 · Media · Parcial
Las consultas en tiempo real de la sala (`snapshots()`) no tenían límite. **Hecho:** las dos listas de pedidos del panel del sonidista tienen tope de 200 (`kMaximoPedidosVisibles`). **Falta:** el Historial (consulta de atendidos) y la conservación por tiempo; otros `snapshots()` de la app (12 en total) siguen sin límite.
- **Decisión relacionada:** D-08.
- **Prueba:** hay una que fija el valor del tope; falta medir lecturas (Etapa 6).

## Corregidos

### DF-01 · Corregido (24-oct-2026, D-04)
"Vocalista de Somos Mil" ya no entra al panel del sonidista: la detección usa palabras completas (la palabra "som" no coincide con "Somos"). Pruebas: `esRolSonidista / esRolSonidoAmbiguo`. Verificado también en el navegador (entra a pedidos).

### DF-02 · Corregido (24-oct-2026, D-04)
"Ingeniero de audio", "Operador de audio", "FOH", "Monitorista" (y equivalentes en pt/fr/de/it) entran al panel. Un rol que mezcla función musical y de sonido ("Músico y sonidista") **pregunta** a dónde entrar. Verificado en el navegador (diálogo, "Cancelar" y "Pantalla de pedidos"; la opción "Panel del sonidista" comparte el mismo código que la entrada directa, que ya estaba verificada).

### DF-03 · Corregido (24-oct-2026, D-05)
La transposición soporta Do-Re-Mi-Fa-Sol-La-Si (con `#`/`b`, menores, séptimas y bajos) conservando la notación; en líneas de acordes exige al menos dos elementos para no confundir palabras como "Si" o "Sol". Si el texto no tiene acordes se muestra "No se encontraron acordes para transponer." (**el aviso no se verificó en el navegador**, solo `hayAcordes` con pruebas).

### DF-05 · Corregido (24-oct-2026, D-07)
(Riesgo identificado por inspección de código; nunca se reprodujo.) Borrar relee el pedido antes de eliminarlo y guarda la versión más reciente; "Deshacer" no pisa si ya fue recreado; atender o borrar un pedido que ya no existe avisa "Ese pedido ya no existe." en vez de fallar en silencio. Verificado en el navegador el camino normal (borrar y deshacer); **el caso con dos sonidistas simultáneos sigue sin probarse** (Etapa 5).

### DF-07 · Corregido (24-oct-2026)
La lista de pedidos rápidos ya no repite "Volumen retorno". Pruebas: `Pedidos rápidos`. (Las cuentas que ya copiaron sus frases conservan la lista anterior.)

### DF-09 · Corregido (25-oct-2026)
En un celular, el PIN de la sala se partía en dos líneas ("Y53XUK6" / "W") en "Configurar sala" porque el ícono de compartir le sacaba ancho. Ahora el PIN va en una sola línea y se achica si hace falta. Verificado en un celular real.

### DF-10 · Corregido (25-oct-2026)
En un celular, el título de la sala del músico quedaba en "QA…" (la "pastilla" con el código ocupaba el ancho) y el del panel del sonidista en "Conso…" (sin PIN visible). Ahora la sala muestra "Nombre (Rol)" con "SALA: CÓDIGO" debajo (tocable para copiar), y el panel muestra "Consola" con el PIN debajo. Verificado en un celular real.

### DF-11 · Corregido (25-oct-2026)
En Android, una secuencia larga tardaba entre 1 y 13 segundos en empezar a sonar al tocar "play" (según la red y si el servidor estaba "frío"). Ahora las pistas de la sala se bajan al celular apenas aparecen en la lista (RQ-27) y suenan desde el archivo local. **Medido en un celular real (Redmi, Android 15, de toque a audio):** 0,9 s la primera pista, 0,23 s la segunda y 0,2 s una pista **con wifi y datos apagados**. Se conservan hasta 12 pistas (las de la sala actual nunca se borran) y las descargas a medias de más de un día se limpian. Limitación: una pista nueva se escucha por red hasta que termina de bajar.

### DF-12 · Corregido (25-oct-2026)
En "Mis salas", borrar una entrada no pedía confirmación. Ahora aparece el aviso "Sala quitada del historial" con **Deshacer** (5 idiomas).

### DF-13 · Corregido (25-oct-2026)
Con pantalla angosta o letra grande del sistema (probado con 320 dp de ancho y letra al 130 %), los nombres de las pestañas de la sala ("PEDIDOS", "SECUENCIAS") quedaban cortados. Ahora la barra de pestañas se desliza cuando los nombres no entran (función `pestanasApretadas`).

### DF-14 · Corregido (25-oct-2026)
Con el celular en horizontal, en la pestaña Pedidos las frases rápidas quedaban reducidas a una tira de unos 50 px, casi inutilizable. Ahora, con poca altura, las frases van a la izquierda y el campo de texto y el historial a la derecha.

### DF-15 · Corregido (25-oct-2026)
En una tablet (800 × 1280 dp) las pantallas de ingreso y los formularios estiraban botones y campos de borde a borde. Ahora los formularios se centran con ancho máximo de 480 dp y el resto del contenido con 840 dp (`kAnchoMaximoFormulario`, `kAnchoMaximoContenido`).
