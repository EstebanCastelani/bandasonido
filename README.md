# AppSonido (Sound Check Pro)

App multiplataforma para bandas en vivo: comunicación en tiempo real entre músicos/cantantes y el sonidista, setlist compartido del show, biblioteca de partituras/cifrados y secuencias (pistas de audio).

> **Si sos una IA (o una persona nueva en el proyecto), leé primero [`CONTEXTO_PARA_IA.md`](CONTEXTO_PARA_IA.md).** Tiene la arquitectura, el modelo de datos, el estado de la infraestructura, las decisiones de diseño y lo que está pendiente. Este README es solo un resumen.

## Cómo funciona

- Alguien crea una sala, que genera un PIN de 8 caracteres alfanuméricos. El resto se une con el PIN y su nombre (sin cuenta, como invitado, o con cuenta registrada).
- La sala tiene pestañas:
  - **Pedidos**: músicos y cantantes mandan pedidos rápidos (o texto libre, opcionalmente urgentes) al sonidista, que los ve en tiempo real, los marca como atendidos, responde o borra.
  - **Setlist**: lista de temas del show con PDFs/cifrados, transposición de acordes y estado de cada tema.
  - **Secuencias**: las pistas de audio que se van a usar ese día, con reproductor.
- Con cuenta registrada: frases propias, "Mi repertorio" (PDFs), "Mis secuencias" (audios) y "Mis salas".

## Estructura

- `frontend`: Flutter (Web desplegada en GitHub Pages; Android en pruebas). Toda la app vive en `frontend/lib/main.dart`.
- Firebase Firestore + Auth (proyecto `appbandasonido`), sin backend propio. Archivos (PDFs y audios) en Supabase Storage, temporalmente.
- `firestore.rules` / `storage.rules`: reglas de seguridad versionadas en el repo.

## Ejecutar

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

## Seguridad

El acceso a una sala es "conocer el PIN alcanza" (con sesión de Firebase, aunque sea anónima). Ver `CONTEXTO_PARA_IA.md` §6 para el detalle y los trade-offs.

## Documentación de calidad y operación

- [`REQUISITOS.md`](REQUISITOS.md) · [`DEFECTOS.md`](DEFECTOS.md) · [`BACKLOG.md`](BACKLOG.md) — qué debe hacer la app, defectos conocidos y pendientes.
- [`OPERACION.md`](OPERACION.md) — publicar, volver a una versión anterior, dependencias externas y qué hacer si algo se cae.
- [`PROCESO.md`](PROCESO.md) · [`CHANGELOG.md`](CHANGELOG.md) — cómo se trabaja y qué cambió en cada versión.
- Auditorías: [usabilidad](AUDITORIA_USABILIDAD.md), [testing](AUDITORIA_TESTING.md), [calidad y estándares](AUDITORIA_CALIDAD_ESTANDARES.md).
