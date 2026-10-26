# Cambios por versión

Formato: [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/). La versión se escribe en `frontend/pubspec.yaml` (`version: X.Y.Z+N`) y en `kVersionApp` de `frontend/lib/main.dart` (una prueba verifica que coincidan); cada versión publicada lleva un tag `vX.Y.Z` en Git. Para volver a una versión anterior ver `OPERACION.md`.

## [Sin publicar]

### Agregado
- Ícono propio de la app (barras de sonido, degradé cian a violeta) para Android (adaptable), web y favicon. Se regenera con `tool/icono.ps1` y `dart run flutter_launcher_icons`.
- Android: las secuencias de la sala se guardan en el celular apenas aparecen en la lista. Empiezan a sonar casi al instante al tocar "play" (0,2 a 0,9 s medidos, antes 1 a 13 s) y siguen sonando sin conexión. Guarda hasta 12 pistas.

### Agregado
- **Eliminar mi cuenta** (menú de la cuenta): borra el perfil, las frases, el repertorio y las secuencias con sus archivos, el historial de salas y la cuenta de acceso, tras volver a confirmar la identidad (contraseña o Google) y una confirmación final. Reglas publicadas y borrado probado. Página web de pedido de eliminación: `eliminar-cuenta.html`.

### Corregido
- Pantallas: las pestañas de la sala se deslizan en pantallas angostas o con letra grande; en horizontal las frases rápidas ya no quedan aplastadas; en tablets los formularios y el contenido se centran con ancho máximo (DF-13, DF-14, DF-15).
- "Mis salas": al quitar una sala aparece un aviso con "Deshacer".
- Código: `flutter analyze` queda sin avisos (se reemplazó `withOpacity` en desuso y se agregaron controles de pantalla activa antes de navegar).
- Android: el manifiesto principal no declaraba el permiso de internet, por lo que una versión de release no podía conectarse a Firebase ni a Supabase.
- Android: el nombre visible de la app era `appsonido_frontend`; ahora es "Sound Check Pro".

- Celulares: el PIN de la sala ya no se parte en dos líneas al crearla; el título de la sala muestra nombre, rol y código completos, y el del panel del sonidista muestra "Consola" y el PIN en dos líneas.

### Cambiado
- Android: la firma de release se lee de `android/key.properties` (si no existe, se usa la clave de depuración solo para pruebas). Ver `PLAY_STORE.md`.

## [1.1.0] — 2026-10-24
Primera versión con número propio: reúne todo lo hecho desde el lanzamiento inicial (la versión `1.0.0+1` nunca se había actualizado).

### Agregado
- Idiomas: español, inglés, portugués, francés e italiano; detección automática del idioma del dispositivo (español si no está soportado) y selector manual.
- Pantalla de bienvenida y estilo "Escenario" (con versión clara); modo claro/oscuro independiente de la paleta.
- Menú hamburguesa con Mis frases, Mi repertorio, Mis secuencias, Configuración (Colores e Idioma) y Cerrar sesión.
- El rol se escribe a mano al crear o unirse a una sala; un rol de sonido entra directo al panel del sonidista (con pregunta si el rol mezcla funciones).
- Transposición de cifrado en notación latina (Do-Re-Mi) y aviso cuando no hay acordes.
- Secuencias: tono, tempo y volumen sincronizados con la sala; se muestra quién hizo el último ajuste.
- Validaciones en línea, mensajes de error entendibles con "Reintentar", "Deshacer" al borrar un pedido y confirmación al salir de la sala.
- Aviso de falta de conexión en la sala y confirmación real del envío de pedidos ("Enviado" solo cuando llegó).
- Enlace para unirse a una sala (`?sala=CÓDIGO`) y botón para compartirlo al crearla.
- Versión visible en Configuración.

### Cambiado
- Tope de 200 pedidos visibles en el panel del sonidista y de 200 caracteres por pedido escrito a mano.
- Textos más grandes en los controles (≥ 14 px).
- Syncfusion PDF actualizado a 28.x (requisito de `flutter_localizations`).
- pdf.js ya no bloquea el arranque de la app.
- El despliegue pasa primero por formato, análisis y pruebas; no se publica si algo falla.

### Corregido
- DF-01…DF-03, DF-05 y DF-07 (ver `DEFECTOS.md`).

## [1.0.0] — lanzamiento inicial
