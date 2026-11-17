# Respuestas sugeridas para los formularios de Play Console

Borrador del 16-nov-2026, basado en lo que hace la app **hoy** (modo lanzamiento: todo gratis, sin cobro, sin anuncios). **Cada respuesta es una declaración tuya ante Google:** leé cada pregunta, comprobá que sea cierta y corregí lo que haga falta. Si más adelante cambia la app (cobro, anuncios, nuevos datos), hay que actualizar estos formularios.

Dónde está cada uno: panel de la app → *Contenido de la app* (o "Política y programas → Contenido de la app").

---

## 1. Política de privacidad
- URL: `https://sound-check-pro-web.sound-check-pro-archivos.workers.dev/privacidad`

## 2. Acceso a la app
- **Opción:** "Todas o algunas funciones están restringidas" (parte de la app pide cuenta).
- **Instrucciones para el revisor** (texto sugerido):
  > No hace falta cuenta para probar lo principal: en la pantalla de inicio tocar "Entrar como invitado", después "Crear nueva sala" (o "Unirme a sala" con un código), poner un nombre y un rol, y se pueden enviar pedidos, ver el setlist y las secuencias. Las funciones de cuenta (Mi repertorio, Mis secuencias, Mis frases, Mis salas) requieren registrarse con correo y contraseña o con Google; el registro es libre y no necesita aprobación. Durante el lanzamiento todas las funciones están abiertas.
- **No hay credenciales de prueba:** si Google las pide, hace falta crear una cuenta de prueba a mano (yo no puedo crearla ni escribir contraseñas).

## 3. Anuncios
- **¿Contiene anuncios?** No.

## 4. Clasificación del contenido (cuestionario IARC)
- **Categoría:** Utilidad / Productividad / Comunicación (no es un juego).
- Violencia, sangre, contenido sexual, lenguaje soez, sustancias controladas, juegos de azar: **No** a todo.
- **¿Los usuarios pueden interactuar o intercambiar contenido entre ellos?** **Sí.** Mandan pedidos de texto y comparten setlist, PDF y audios dentro de una sala (con el código). No hay chat abierto ni perfiles públicos.
- **¿Comparte la ubicación del usuario?** No.
- **¿Permite compras digitales?** No (hoy). Cuando se active el cobro de Pro, hay que volver a contestar.
- **Resultado esperado:** apta para todo público, con el aviso de "interacción entre usuarios".

## 5. Público objetivo y contenido
- **Grupos de edad:** 13-15, 16-17 y 18 o más. **No marcar "menores de 13"**: la política de privacidad dice que la app no es para menores de 13 y marcarlo activaría la política de Familias, con requisitos mucho más estrictos.
- **¿Atrae a niños?** No (es una herramienta para músicos y sonidistas).

## 6. Seguridad de los datos
**¿Recopila o comparte datos?** Sí.
**¿Está cifrado en tránsito?** Sí (HTTPS).
**¿Pueden pedir que se eliminen?** Sí: dentro de la app (menú → Configuración → Eliminar mi cuenta) y por la web: `https://sound-check-pro-web.sound-check-pro-archivos.workers.dev/eliminar-cuenta`.

| Categoría de Play | Dato | ¿Se recopila? | Opcional | Para qué | ¿Compartido con terceros? |
|---|---|---|---|---|---|
| Información personal | Nombre | Sí (el que escribe la persona en la sala) | No (para usar una sala) | Funcionalidad de la app | No |
| Información personal | Correo electrónico | Sí, **solo con cuenta** | Sí | Administración de la cuenta | No |
| Información personal | ID de usuario (también el anónimo de invitados) | Sí | No | Funcionalidad, administración de la cuenta | No |
| Archivos y documentos | PDF de partituras | Sí, si los sube | Sí | Funcionalidad de la app | No |
| Audio | Archivos de música (secuencias) | Sí, si los sube | Sí | Funcionalidad de la app | No |
| Actividad en la app | Otro contenido generado por el usuario (pedidos, setlist, notas, frases) | Sí | No | Funcionalidad de la app | No |
| Información y rendimiento de la app | Registros de fallos y diagnósticos | Sí, solo en la app instalada | No | Análisis | No |
| Dispositivo u otros ID | Identificador de instalación (Crashlytics) | Sí, solo en la app instalada | No | Análisis | No |

**Sobre "compartido":** Google (Firebase) y Cloudflare **procesan los datos por cuenta de la app** (proveedores de servicio). Según la guía de Google eso **no cuenta como "compartir"**. Si tenés dudas, releé la definición en el formulario.

**No se recopilan:** ubicación, contactos, fotos y videos, micrófono, mensajes, salud, finanzas, historial web ni identificador de publicidad. **La cámara** solo se usa para escanear el QR, sin guardar ni enviar imágenes (no es "recopilar").

## 7. Otras declaraciones (todas "No")
- **ID de publicidad:** no la usa.
- **Aplicación gubernamental, de noticias, de salud o de seguimiento de contactos de COVID-19:** No.
- **Funciones financieras:** No.
- **Aplicaciones de VPN o de accesibilidad:** No.
- **Permisos sensibles:** ninguno (solo internet, estado de red, vibración y cámara).

## 8. Datos de la ficha principal
- **Nombre:** Sound Check Pro · **Categoría:** Música y audio · **Etiquetas:** música, banda, sonido en vivo, setlist, cifrados, iglesia.
- **Descripción corta y larga:** ver `docs/ficha-play-store.md` (español e inglés).
- **Correo de contacto de la ficha** (público): el que elijas.
- **Sitio web (opcional):** `https://sound-check-pro-web.sound-check-pro-archivos.workers.dev`
- **Gráficos:** ícono `frontend/web/icons/Icon-512.png` (512×512), imagen destacada `docs/play-store/grafico-destacado-1024x500.png` y capturas de `docs/play-store/capturas/`.

## 9. Lo que NO se puede contestar desde acá
- **Estado de comerciante** (declarado como no comerciante mientras sea gratis; cambiar al activar el cobro).
- **Impuestos y datos de cobro:** solo hacen falta cuando se cobre.
- **Prueba cerrada:** conseguir testers y esperar los días que pida Google.
