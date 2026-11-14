# Reglas de R8 para el build de release (ver build.gradle.kts).
# Flutter, Firebase y Google Sign-In traen sus propias reglas; acá solo lo que
# es propio de la app.

# Canales de plataforma de MainActivity (se llaman desde Dart por nombre).
-keep class com.soundcheckpro.app.** { *; }

# Conserva los números de línea para que los errores de Crashlytics se
# puedan leer (el mapeo lo sube el plugin de Crashlytics).
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
