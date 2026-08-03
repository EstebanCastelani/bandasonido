# AppSonido (Sound Check Pro)

App multiplataforma para comunicacion en tiempo real entre musicos/cantantes y sonidista durante un show.

## Como funciona

- El sonidista o un musico crea una sala, que genera un PIN de 6 digitos.
- El resto de la banda se une a esa sala con el PIN y su nombre.
- Musicos y cantantes mandan pedidos rapidos predefinidos (o texto libre) al sonidista.
- El sonidista ve todos los pedidos de la sala en tiempo real, puede marcarlos como atendidos, responder en privado o borrarlos.

## Estructura

- `frontend`: Flutter (Android, iOS, Web). Toda la app vive en `frontend/lib/main.dart`.
- Persistencia y tiempo real: Firebase Firestore (proyecto `appbandasonido`), sin backend propio.

## Requisitos

- Flutter 3.22+ y Dart 3.4+

## Ejecutar

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

Para movil:

```bash
flutter run -d android
```

## Seguridad de Firestore

Las reglas (`salas/{salaId}/pedidos/{pedidoId}`) exigen conocer el `salaId` (el PIN) para leer o escribir, y bloquean cualquier otra coleccion. Como el PIN es corto (6 digitos) y no hay rate limiting, es fuerza-bruteable; no depender de esto para datos sensibles.
