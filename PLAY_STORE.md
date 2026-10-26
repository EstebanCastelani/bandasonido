# Publicar Sound Check Pro en Google Play

Guía paso a paso. 🔑 = lo tenés que hacer vos (cuentas, claves, decisiones). Estado verificado el 25-oct-2026.

## 0. Estado actual

| Tema | Estado |
|---|---|
| Build de release | ✔ `flutter build apk --release` compila (APK de 68 MB, versión `1.1.0`, código `2`, `minSdk 24`, `targetSdk 36`) |
| Permiso de internet | ✔ **Corregido hoy**: el manifiesto principal no lo declaraba (Flutter solo lo agrega en debug/profile), por lo que una versión de tienda no habría podido conectarse a Firebase ni a Supabase |
| Nombre visible | ✔ **Corregido hoy**: era `appsonido_frontend`, ahora "Sound Check Pro" |
| Firma de release | ◐ El build ya lee `android/key.properties` (ejemplo en `android/key.properties.example`). **Sin ese archivo se firma con la clave de depuración y ese archivo NO sirve para Play Store** (verificado: el APK actual figura firmado por "Android Debug") |
| Probado en un celular real | ◐ **Probado el 25-oct-2026** en un Redmi 25078RA3EY (Android 15, 720 × 1600): menú, secuencias (carga y reproducción), crear sala, pedidos, **corte de red con aviso y reenvío**, panel del sonidista, "Borrar todo", cierre y **login con Google** (confirmado por vos). Falta: subir un archivo, PDFs y cifrados, y otros modelos de celular |
| Identificador de la app | ◐ `com.soundcheckpro.appsonido_frontend` (ver §2) |
| Política de privacidad | ✘ Hay un borrador en `docs/politica-de-privacidad-borrador.html` (ver §6) |
| Eliminar cuenta dentro de la app | ◐ **Implementada** (menú → "Eliminar mi cuenta"). Reglas publicadas, borrado probado y enlace web publicado (ver §7) |
| Ícono propio, capturas, descripción | ◐ **Ícono de la app hecho** (barras de sonido). Para la ficha de Play falta el ícono de 512 × 512 (`frontend/assets/icon/icon.png` está en 1024 × 1024: se reduce), la imagen destacada, las capturas y las descripciones 🔑 |

## 1. Primero: probar en un celular real 🔑
Antes de gastar tiempo en la tienda, comprobá que la app anda en Android:
> **Ya se hizo una primera ronda en un celular real** (ver §0). Esta sección sirve para repetirla con otros modelos y para lo que falta.

1. En el celular: activá **Opciones de desarrollador → Depuración USB** y conectalo.
2. En la carpeta `frontend`: `flutter devices` (tiene que aparecer) y luego `flutter run --release`.
3. Probá como invitado y con cuenta: crear y unirse a una sala, enviar pedidos, el panel del sonidista, cifrados y PDF, secuencias (subir un audio, reproducir, cambiar tono/tempo/volumen), login con Google, cambio de idioma y de paleta, y qué pasa al cortar el wifi (debe aparecer el aviso "Sin conexión").
4. Anotá lo que falle en `DEFECTOS.md` (formato DF-xx).

## 2. Decidir el identificador de la app 🔑
El *applicationId* **no se puede cambiar una vez publicada** y tiene que coincidir con la app Android registrada en Firebase.
- **Si lo dejás** (`com.soundcheckpro.appsonido_frontend`): no cambia nada. Solo se ve en la dirección de la ficha de Play (`…/details?id=com.soundcheckpro.appsonido_frontend`), no en el celular.
- **Si lo cambiás** (por ejemplo `com.soundcheckpro.app`), hacelo **antes** del primer envío:
  1. Firebase → ⚙️ Configuración del proyecto → *Tus apps* → **Agregar app → Android** con el nuevo nombre de paquete (y la huella SHA-1 del §3).
  2. Descargá el nuevo `google-services.json` a `frontend/android/app/` (no se sube a Git).
  3. En `android/app/build.gradle.kts` cambiá `namespace` y `applicationId`; mové `MainActivity.kt` a la carpeta del nuevo paquete y corregí su línea `package`.
  4. `flutter clean` y `flutter build apk --release`. Avisame y lo hago yo con el nombre que elijas.

## 3. Crear la clave de firma (keystore) 🔑
1. Abrí una terminal y ejecutá (guardá el archivo **fuera del repositorio**, p. ej. `C:\claves\sound-check-pro\`):
   ```bash
   keytool -genkey -v -keystore C:\claves\sound-check-pro\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
   Te pide contraseñas y datos de identificación. **Anotá las contraseñas y hacé una copia del `.jks` en dos lugares** (si lo perdés tendrás que pedirle a Google un reseteo de la clave de subida).
2. Copiá `frontend/android/key.properties.example` como `frontend/android/key.properties` y completá las contraseñas, el alias (`upload`) y la ruta al `.jks`. Ese archivo está en `.gitignore`: no lo subas.
3. Sacá la huella SHA-1 de la clave: `keytool -list -v -keystore C:\claves\sound-check-pro\upload-keystore.jks -alias upload`.
4. **Registrá la SHA-1 en Firebase** (⚙️ → *Tus apps* → app Android → *Agregar huella digital*). **Sin esto, "Continuar con Google" deja de funcionar en la versión de la tienda.**
5. Recomendado: usar **Play App Signing** (se activa solo al crear la app en Play Console). Google guarda la clave que firma lo que reciben los usuarios y vos solo conservás la clave de subida. Después de tu primera subida, en Play Console → *Integridad de la app* aparece la **SHA-1 de la clave de firma de la app**: agregala también en Firebase.

## 4. Generar el paquete para la tienda
1. Subí el número de compilación en `frontend/pubspec.yaml` (`version: 1.1.0+3`: el número después del `+` **tiene que ser mayor en cada envío**). Mantené `kVersionApp` en `main.dart` igual a la parte `X.Y.Z`.
2. `cd frontend` y `flutter build appbundle --release`.
3. El archivo queda en `frontend/build/app/outputs/bundle/release/app-release.aab`. Comprobá que **no** esté firmado con "Android Debug": con `key.properties` bien cargado, está firmado con tu clave de subida.

## 5. Cuenta y ficha de Play Console 🔑
1. Creá la cuenta en `play.google.com/console` (pago único de aproximadamente 25 USD y verificación de identidad).
2. **Crear app** → nombre "Sound Check Pro", idioma predeterminado español, tipo *App*, gratuita.
3. Las cuentas personales nuevas suelen tener que hacer una **prueba cerrada con un mínimo de testers durante unos 14 días** antes de poder publicar en producción: verificá el requisito vigente en el panel.
4. Material de la ficha: ícono de 512 × 512, imagen destacada de 1024 × 500, al menos dos capturas de pantalla de celular, descripción corta (80 caracteres) y larga. Categoría sugerida: *Música y audio*.
5. Datos de contacto (correo) y la URL de la **política de privacidad** (ver §6).
6. Completá los formularios: **Seguridad de los datos**, **Clasificación de contenido**, **Público objetivo** y **Anuncios** (la app no tiene).

### Formulario "Seguridad de los datos" (lo que recopila la app)
| Dato | ¿Se recopila? | Para qué | ¿Se comparte con terceros? |
|---|---|---|---|
| Nombre | Sí (el que escribe la persona) | Funcionalidad de la app | Procesado por Firebase (Google) |
| Correo electrónico | Solo con cuenta | Autenticación | Firebase / Google Sign-In |
| Contenido del usuario (pedidos, frases, setlist, PDFs, audios) | Sí | Funcionalidad de la app | Firebase y **Supabase** (los archivos en un bucket público por enlace) |
| ID de usuario (también el anónimo de invitados) | Sí | Autenticación | Firebase |
| Ubicación, contactos, fotos, publicidad, analítica | **No** | — | — |
Cifrado en tránsito: sí (HTTPS). Eliminación: ver §7.

## 6. Política de privacidad 🔑
Hay un borrador en `docs/politica-de-privacidad-borrador.html` basado en los datos que de verdad guarda la app. Hay que:
1. Reemplazar los textos entre corchetes (`[TU NOMBRE O RAZÓN SOCIAL]`, `[TU CORREO DE CONTACTO]`).
2. Hacerla revisar por una persona con conocimiento legal (menciona la ley argentina 25.326; no es asesoramiento).
3. Copiarla a `frontend/web/privacidad.html` y publicar: quedará en `https://estebancastelani.github.io/bandasonido/privacidad.html`, que es la URL que pide Play. (No la dejé en `web/` para no publicar una página con datos incompletos.)

## 7. Bloqueantes de política que hay que resolver antes
1. **Eliminar la cuenta desde la app.** Play exige una opción **dentro de la app** y un **enlace web** para pedir la eliminación. La opción dentro de la app ya existe (menú de la cuenta → "Eliminar mi cuenta"). Pendientes 🔑: (a) ~~publicar `firestore.rules`~~ **hecho el 25-oct-2026**, (b) ~~probarlo con una cuenta de prueba~~ **probado por el dueño el 25-oct-2026: funciona**, (c) ~~enlace web~~ **publicado**: `https://estebancastelani.github.io/bandasonido/eliminar-cuenta.html` (pegar esa URL en Play Console → Seguridad de los datos).
2. **Archivos en un bucket público.** Los PDFs y audios que suben los usuarios quedan en un bucket de Supabase accesible por enlace (la ruta no es adivinable, pero no está protegida). La política de privacidad y el formulario de datos tienen que decirlo con claridad; si preferís que sean privados hay que pasar a enlaces firmados (ítem B-26).
3. **App Check en Android.** Si activás la exigencia de App Check en Firestore, hay que registrar antes un proveedor para Android (Play Integrity) o la app dejaría de funcionar (ver `OPERACION.md` §6).

## 8. Lista final antes de enviar
- [ ] Probada en celular real (§1)
- [ ] Identificador decidido y Firebase actualizado (§2)
- [ ] `key.properties` creado, SHA-1 registrada en Firebase, copia de seguridad del `.jks` (§3)
- [ ] `.aab` generado y firmado con tu clave (§4)
- [ ] Política de privacidad publicada y enlazada (§6)
- [ ] Eliminación de cuenta implementada y enlace de pedido de borrado (§7)
- [ ] Ficha completa: ícono, capturas, descripciones, formularios (§5)
- [ ] Prueba cerrada hecha, si Play la exige para tu cuenta
- [ ] `CHANGELOG.md` actualizado y tag de la versión (`OPERACION.md` §1)
