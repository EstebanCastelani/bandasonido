import 'dart:async';

import 'dart:io' show Directory, File;

import 'dart:math';

import 'package:audioplayers/audioplayers.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:file_picker/file_picker.dart';

import 'package:firebase_app_check/firebase_app_check.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:firebase_core/firebase_core.dart';

import 'package:firebase_storage/firebase_storage.dart';

import 'package:flutter/foundation.dart' show kIsWeb, listEquals;

import 'package:flutter_localizations/flutter_localizations.dart';

// Textos traducidos (los genera Flutter desde lib/l10n/*.arb; ver l10n.yaml).
import 'l10n/app_localizations.dart';

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:google_sign_in/google_sign_in.dart';

import 'package:http/http.dart' as http;

import 'package:share_plus/share_plus.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import 'package:syncfusion_flutter_pdf/pdf.dart' as sf_pdf;

import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'package:wakelock_plus/wakelock_plus.dart';

// Lo que corre en JS del navegador (conversor de MP3, reproductor con tono y
// tempo): en web es puente_web.dart; fuera de la web apunta a este mismo
// archivo, que define las versiones "no disponible" (ver SERVICIO DE SECUENCIAS).
import 'main.dart' if (dart.library.js_interop) 'puente_web.dart' as puente;

// --- CONFIGURACIÓN DE FIREBASE ---

const FirebaseOptions firebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSyBmIF6Eq5Av-fgDSLIlEdRvAoWdKqth-rM',
  authDomain: 'appbandasonido.firebaseapp.com',
  projectId: 'appbandasonido',
  storageBucket: 'appbandasonido.firebasestorage.app',
  messagingSenderId: '784903375488',
  appId: '1:784903375488:web:6db920dbfb9ebbc6eef465',
);

// --- CONFIGURACIÓN DE SUPABASE (SOLO STORAGE, MIENTRAS FIREBASE STORAGE ---

// --- NO ESTÁ APROVISIONADO — VER RepertorioService) ---

/// Igual que la config de Firebase de arriba: no es un secreto crítico,

/// la key "anon" está pensada para ir en el cliente. La seguridad real la

/// dan las políticas RLS del bucket en Supabase, no ocultar esta key.

const String kSupabaseUrl = 'https://aecmjdwfttcomcumcbwh.supabase.co';

const String kSupabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFlY21qZHdmdHRjb21jdW1jYndoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODU3OTk5NDcsImV4cCI6MjEwMTM3NTk0N30.ahjRL6QX8pa0Ca8BJ9hrLKC6M2LBBQV8pSPE5_3_guY';

/// Nombre del bucket de Storage en Supabase donde viven los PDFs del

/// repertorio personal, mientras Firebase Storage no está aprovisionado

/// (requiere plan Blaze). Ver RepertorioService para el detalle.

const String kSupabaseRepertorioBucket = 'repertorio-pdfs';

/// Acceso corto al cliente de Supabase, mismo patrón que se usa en la

/// mayoría de las apps Flutter+Supabase.

SupabaseClient get supabase => Supabase.instance.client;

/// Inicializa Supabase pasando el ID token de Firebase Auth como

/// accessToken en cada request (Third-Party Auth: Firebase, configurado en

/// el dashboard de Supabase). Así las políticas RLS del bucket pueden

/// identificar al dueño real del archivo sin necesitar una sesión de

/// Supabase Auth separada — Auth sigue siendo 100% Firebase.

Future<void> _inicializarSupabase() async {
  await Supabase.initialize(
    url: kSupabaseUrl,
    publishableKey: kSupabaseAnonKey,
    accessToken: () async {
      return FirebaseAuth.instance.currentUser?.getIdToken();
    },
  );
}

/// Site key de reCAPTCHA v3 para Firebase App Check en Web. Se genera en

/// Firebase Console → App Check → registrar la app web → proveedor

/// reCAPTCHA v3 (requiere asociar el dominio estebancastelani.github.io en

/// https://www.google.com/recaptcha/admin primero). Mientras quede en null,

/// App Check no se activa — no rompe nada, es un opt-in explícito. Además,

/// activar App Check acá NO alcanza para bloquear tráfico falso: hay que

/// habilitar "Enforce" por producto (Firestore/Storage) en Firebase Console

/// → App Check, y eso sí puede cortar acceso real si algo está mal

/// configurado, así que no se activa solo.

const String? kAppCheckSiteKeyWeb = null;

Future<void> _activarAppCheckSiCorresponde() async {
  if (!kIsWeb || kAppCheckSiteKeyWeb == null) return;

  try {
    await FirebaseAppCheck.instance.activate(
      webProvider: ReCaptchaV3Provider(kAppCheckSiteKeyWeb!),
    );
  } catch (e) {
    debugPrint("Error activando Firebase App Check: $e");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(options: firebaseOptions);

    await _activarAppCheckSiCorresponde();
  } catch (e) {
    debugPrint("Error inicializando Firebase: $e");
  }

  try {
    await _inicializarSupabase();
  } catch (e) {
    debugPrint("Error inicializando Supabase: $e");
  }

  runApp(const SoundCheckProApp());
}

// --- MODELOS Y CONSTANTES ---

enum UserRole { musico, cantante }

extension UserRoleTexto on UserRole {
  /// Texto GUARDADO (prefs/Firestore) y que lee rolesDesdeEtiqueta: siempre
  /// en español, sea cual sea el idioma de la app, para que lo que ya está
  /// guardado siga funcionando. Para mostrarlo usar [nombre].
  String get etiqueta => switch (this) {
        UserRole.musico => 'Músico',
        UserRole.cantante => 'Cantante',
      };

  /// Texto para MOSTRAR, en el idioma de la app.
  String nombre(AppLocalizations l) => switch (this) {
        UserRole.musico => l.rolMusico,
        UserRole.cantante => l.rolCantante,
      };
}

/// Un rol guardado ("Músico y Cantante", "Sonidista", o uno escrito a mano
/// como "guitarrista") traducido al idioma de la app para mostrarlo. Lo que
/// no reconoce lo devuelve igual: es un texto que escribió la persona.
String rolParaMostrar(AppLocalizations l, String guardado) {
  final t = guardado.toLowerCase().replaceAll('ú', 'u').trim();
  if (t == 'sonidista') return l.rolSonidista;
  if (t == 'otro') return l.rolOtro;
  final roles = {
    if (t.contains('musico')) UserRole.musico,
    if (t.contains('cantante')) UserRole.cantante,
  };
  // Solo se traduce si el texto es exactamente lo que armaría etiquetaRoles.
  if (roles.isNotEmpty &&
      etiquetaRoles(roles).toLowerCase().replaceAll('ú', 'u') == t) {
    return textoRoles(l, roles);
  }
  return guardado;
}

/// Tope de pedidos que se muestran por sala (D-08 de REQUISITOS.md).
const int kMaximoPedidosVisibles = 200;

/// Palabras COMPLETAS que indican un rol de sonido: sonidista, sonido, FOH,
/// monitorista, audio, sound (sound engineer), som (portugués), fónico
/// (italiano), Tontechniker (alemán), "du son" (francés) y "del suono"
/// (italiano). Se busca por palabra entera para que "Somos Mil" no cuente.
final RegExp _palabrasSonido = RegExp(
  r'\b(?:sonidista|sonido|foh|monitorista|sound|audio|som|fonico|tontechniker|du son|del suono)\b',
);

/// Funciones musicales: si el rol nombra alguna junto con una de sonido
/// ("músico y sonidista") es ambiguo y se le pregunta a la persona.
final RegExp _palabrasMusica = RegExp(
  r'\b(?:musico|cantante|vocalista|corista|guitarrista|bajista|baterista|tecladista|pianista|percusionista|violinista|saxofonista|trompetista|director|musician|singer|guitarist|bassist|drummer|keyboardist|pianist|vocalist|musicien|chanteur|musicista)\b',
);

String _normalizarRol(String rol) {
  const de = 'áàäâéèëêíìïîóòöôúùüûñç';
  const a = 'aaaaeeeeiiiioooouuuunc';
  final t = StringBuffer();
  for (final c in rol.toLowerCase().trim().split('')) {
    final i = de.indexOf(c);
    t.write(i >= 0 ? a[i] : c);
  }
  return t.toString();
}

/// true si el rol escrito es SOLO de sonido (sonidista, técnico de sonido,
/// FOH, sound engineer...): esa persona entra directo al panel del sonidista.
bool esRolSonidista(String rol) {
  final t = _normalizarRol(rol);
  return _palabrasSonido.hasMatch(t) && !_palabrasMusica.hasMatch(t);
}

/// true si el rol menciona sonido Y otra función ("Músico y sonidista"):
/// hay que preguntar a dónde quiere entrar.
bool esRolSonidoAmbiguo(String rol) {
  final t = _normalizarRol(rol);
  return _palabrasSonido.hasMatch(t) && _palabrasMusica.hasMatch(t);
}

/// A dónde entra la persona según su rol: true = panel del sonidista, false =
/// pantalla de pedidos, null = canceló el diálogo (se queda donde está).
Future<bool?> decidirEntradaSonidista(BuildContext context, String rol) async {
  if (esRolSonidista(rol)) return true;
  if (!esRolSonidoAmbiguo(rol)) return false;
  final l = context.l10n;
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.entrarComoSonidistaPregunta),
      content: Text(l.entrarComoSonidistaDetalle),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: Text(l.cancelar)),
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.pantallaDePedidos)),
        TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.panelDelSonidista)),
      ],
    ),
  );
}

/// Nombre estable (16 caracteres hexadecimales) del archivo local de una pista,
/// calculado desde su URL. Dos hashes de 32 bits distintos para que sea casi
/// imposible que dos pistas distintas compartan archivo.
String claveCache(String url) {
  var a = 0x811c9dc5;
  var b = 0x01000193;
  for (final c in url.codeUnits) {
    a ^= c;
    a = (a + (a << 1) + (a << 4) + (a << 7) + (a << 8) + (a << 24)) &
        0xFFFFFFFF;
    b = ((b * 31) + c) & 0xFFFFFFFF;
  }
  return a.toRadixString(16).padLeft(8, '0') +
      b.toRadixString(16).padLeft(8, '0');
}

/// Qué archivos de la caché de pistas conviene borrar: las descargas a medias
/// (.part) con más de [parcialViejo], y las pistas que sobran por encima de
/// [maximo] (se borran primero las más viejas; las de [conservar] nunca).
List<String> archivosParaBorrar(
  List<({String nombre, DateTime fecha})> existentes,
  Set<String> conservar, {
  int maximo = 12,
  Duration parcialViejo = const Duration(days: 1),
  DateTime? ahora,
}) {
  final ahoraReal = ahora ?? DateTime.now();
  final borrar = <String>[];
  final pistas = <({String nombre, DateTime fecha})>[];
  for (final e in existentes) {
    if (e.nombre.endsWith('.part')) {
      if (ahoraReal.difference(e.fecha) > parcialViejo) borrar.add(e.nombre);
    } else {
      pistas.add(e);
    }
  }
  final protegidas = pistas.where((e) => conservar.contains(e.nombre)).length;
  var lugar = maximo - protegidas;
  final otras = pistas.where((e) => !conservar.contains(e.nombre)).toList()
    ..sort((x, y) => y.fecha.compareTo(x.fecha));
  for (final e in otras) {
    if (lugar > 0) {
      lugar--;
    } else {
      borrar.add(e.nombre);
    }
  }
  return borrar;
}

/// Texto entendible para un error técnico (excepción de Firebase, red...):
/// al usuario no se le muestra el código interno, solo qué pasó y qué hacer.
String mensajeError(AppLocalizations l, Object? e) {
  final t = '$e'.toLowerCase();
  if (t.contains('permission-denied') ||
      t.contains('insufficient permissions')) {
    return l.errorSinPermiso;
  }
  if (t.contains('network') ||
      t.contains('channel-error') ||
      t.contains('unavailable') ||
      t.contains('timeout') ||
      t.contains('socketexception') ||
      t.contains('failed host lookup')) {
    return l.errorSinConexion;
  }
  return l.errorGenerico;
}

/// Pregunta si de verdad quiere salir de la sala (un toque suelto en el
/// escenario no debería sacar a nadie). true = salir.
Future<bool> confirmarSalidaSala(BuildContext context) async {
  final l = context.l10n;
  final salir = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.salirDeLaSalaPregunta),
      content: Text(l.salirDeLaSalaDetalle),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancelar)),
        TextButton(
            onPressed: () => Navigator.pop(ctx, true), child: Text(l.salir)),
      ],
    ),
  );
  return salir ?? false;
}

/// Versión de la app que se muestra en Configuración. Tiene que coincidir
/// con `version:` de pubspec.yaml (lo verifica una prueba).
const String kVersionApp = '1.1.0';

/// Dirección pública de la versión web (para armar el enlace de una sala).
const String kUrlWeb = 'https://estebancastelani.github.io/bandasonido/';

/// Largo máximo de un pedido escrito a mano (también se debería exigir en las reglas).
const int kMaxCaracteresPedido = 200;

/// Cómo terminó el intento de enviar un pedido.
enum ResultadoEnvio { enviado, pendiente, fallo }

/// Espera la confirmación de un envío hasta [espera]. Sin red, Firestore deja
/// el envío en cola (no falla ni termina): ahí se devuelve [pendiente] para
/// avisar a la persona en vez de mostrarle un "Enviado" que todavía no es cierto.
Future<ResultadoEnvio> esperarEnvio(Future<void> envio,
    {Duration espera = const Duration(seconds: 4)}) async {
  try {
    await envio.timeout(espera);
    return ResultadoEnvio.enviado;
  } on TimeoutException {
    return ResultadoEnvio.pendiente;
  } catch (_) {
    return ResultadoEnvio.fallo;
  }
}

/// Hay que avisar "sin conexión" solo si alguna vez llegaron datos reales del
/// servidor y ahora lo que se ve viene de la memoria (la primera carga también
/// puede venir del caché y no es una caída).
bool mostrarAvisoSinConexion(
        {required bool vioServidor, required bool desdeCache}) =>
    vioServidor && desdeCache;

/// Código de sala de un enlace del tipo `.../?sala=ABCD2345` (null si no hay o no es válido).
String? codigoDeSalaDesdeUri(Uri uri) {
  final codigo = uri.queryParameters['sala']?.trim().toUpperCase();
  if (codigo == null || !RegExp(r'^[A-Z0-9]{8}$').hasMatch(codigo)) return null;
  return codigo;
}

/// Enlace para unirse a una sala desde el navegador.
String enlaceDeSala(String codigo) => '$kUrlWeb?sala=$codigo';

/// Entra al panel del sonidista de la sala [codigo] (lo mismo que "Acceso
/// sonidista"), y lo deja guardado para volver a abrirlo al reabrir la app.
Future<void> entrarComoSonidista(BuildContext context, String codigo) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('tipo_login', 'sonidista');
  await prefs.setString('sala_id', codigo);
  await _registrarSalaSiCorresponde(codigoSala: codigo, rolUsado: 'Sonidista');
  if (!context.mounted) return;
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => SonidistaPage(codigoSala: codigo)),
    (route) => false,
  );
}

/// Roles unidos para MOSTRAR ("Músico y Cantante" en el idioma de la app).
String textoRoles(AppLocalizations l, Set<UserRole> roles) {
  final nombres = [
    for (final r in UserRole.values)
      if (roles.contains(r)) r.nombre(l)
  ];
  if (nombres.isEmpty) return UserRole.musico.nombre(l);
  if (nombres.length == 1) return nombres.first;
  return l.rolesYUltimo(
      nombres.sublist(0, nombres.length - 1).join(', '), nombres.last);
}

/// Una persona puede tener varios roles a la vez (ej: canta y toca). Se
/// guardan en prefs/Firestore como un único texto legible ("Músico y
/// Cantante", siempre en español); para mostrarlo ver rolParaMostrar.
String etiquetaRoles(Set<UserRole> roles) {
  final nombres = [
    for (final r in UserRole.values)
      if (roles.contains(r)) r.etiqueta
  ];
  if (nombres.isEmpty) return UserRole.musico.etiqueta;
  if (nombres.length == 1) return nombres.first;
  return '${nombres.sublist(0, nombres.length - 1).join(', ')} y ${nombres.last}';
}

Set<UserRole> rolesDesdeEtiqueta(String? texto) {
  final t = (texto ?? '').toLowerCase().replaceAll('ú', 'u');
  final roles = {
    if (t.contains('musico')) UserRole.musico,
    if (t.contains('cantante')) UserRole.cantante,
  };
  return roles.isEmpty ? {UserRole.musico} : roles;
}

class AppConstants {
  /// Frases rápidas por defecto, en el idioma de la app. Quien envía el pedido
  /// manda este texto tal cual: el sonidista lo ve en el idioma de quien lo
  /// envió.
  static List<String> pedidosRapidos(AppLocalizations l) => [
        l.fraseVolumenRetorno,
        l.fraseVolumenAl2,
        l.fraseVolumenAl3,
        l.fraseVolumenAl4,
        l.fraseVolumenGuitarra,
        l.fraseVolumenTeclado,
        l.fraseVolumenTalkback,
        l.fraseVolumenPista,
        l.fraseVolumenClick,
        l.fraseVolumenCoordinador,
        l.fraseVolumenGeneral,
        l.fraseMasVolumen,
        l.fraseMenosVolumen,
        l.fraseListo,
      ];
}

/// Genera un código de sala de 8 caracteres alfanuméricos (excluye 0/O/1/I/L
/// para que no se confundan al leerlos en voz alta o escribirlos a mano).
/// 32^8 ≈ 1,1 billones de combinaciones, contra las 900.000 del PIN
/// numérico de 6 dígitos anterior.
String generarCodigoSala() {
  const alfabeto = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
  final random = Random.secure();
  return List.generate(8, (_) => alfabeto[random.nextInt(alfabeto.length)])
      .join();
}

// --- IDENTIDADES DE COLOR (PALETAS) ---

/// Una identidad visual completa de la app: acento y fondos para modo claro
/// y oscuro. Cada una está tomada de algo que existe en un escenario real
/// (la consola, el ámbar del VU, el wash de luces, la luz de trabajo).
class AppPalette {
  final String key;
  final String nombre;
  final String tag;
  final Color accentDark;
  final Color accentLight;
  final Color bgDark;
  final Color bgLight;
  final Color surfaceDark;
  final Color surfaceLight;

  const AppPalette({
    required this.key,
    required this.nombre,
    required this.tag,
    required this.accentDark,
    required this.accentLight,
    required this.bgDark,
    required this.bgLight,
    required this.surfaceDark,
    required this.surfaceLight,
  });

  static const consola = AppPalette(
    key: 'consola',
    nombre: 'Consola',
    tag: 'Violeta, refinado',
    accentDark: Color(0xFF7C5CFA),
    accentLight: Color(0xFF6C4FD4),
    bgDark: Color(0xFF15121C),
    bgLight: Color(0xFFFAF9FD),
    surfaceDark: Color(0xFF1E1A29),
    surfaceLight: Color(0xFFFFFFFF),
  );

  static const placa = AppPalette(
    key: 'placa',
    nombre: 'Placa',
    tag: 'Grafito + ámbar VU',
    accentDark: Color(0xFFE8A33D),
    accentLight: Color(0xFFC8862A),
    bgDark: Color(0xFF17140F),
    bgLight: Color(0xFFFAF7F0),
    surfaceDark: Color(0xFF211D16),
    surfaceLight: Color(0xFFFFFFFF),
  );

  static const wash = AppPalette(
    key: 'wash',
    nombre: 'Wash',
    tag: 'Teal de luz de escenario',
    accentDark: Color(0xFF1FBFB0),
    accentLight: Color(0xFF12928A),
    bgDark: Color(0xFF0C1618),
    bgLight: Color(0xFFF5FBFA),
    surfaceDark: Color(0xFF122326),
    surfaceLight: Color(0xFFFFFFFF),
  );

  static const worklight = AppPalette(
    key: 'worklight',
    nombre: 'Luz de trabajo',
    tag: 'Máximo contraste',
    accentDark: Color(0xFFFF4B6E),
    accentLight: Color(0xFFE22D53),
    bgDark: Color(0xFF0A0A0B),
    bgLight: Color(0xFFFFFFFF),
    surfaceDark: Color(0xFF141416),
    surfaceLight: Color(0xFFF7F7F8),
  );

  static const camarin = AppPalette(
    key: 'camarin',
    nombre: 'Camarín',
    tag: 'Rosa pastel, suave',
    accentDark: Color(0xFFFF9FC1),
    accentLight: Color(0xFFD9668F),
    bgDark: Color(0xFF1C1216),
    bgLight: Color(0xFFFDF6F8),
    surfaceDark: Color(0xFF261A1F),
    surfaceLight: Color(0xFFFFFFFF),
  );

  /// Estilo de la pantalla de presentación llevado a toda la app: fondo casi
  /// negro, celeste y violeta neón. Es siempre oscuro (ver
  /// _temaEscenario): el modo claro usa los mismos colores.
  static const escenario = AppPalette(
    key: 'escenario',
    nombre: 'Escenario',
    tag: 'Neón celeste y violeta',
    accentDark: Color(0xFF22D3EE),
    accentLight: Color(0xFF0891B2),
    bgDark: Color(0xFF07060F),
    bgLight: Color(0xFFF3F6FC),
    surfaceDark: Color(0xFF0F0D1F),
    surfaceLight: Color(0xFFFFFFFF),
  );

  /// Nombre y descripción para MOSTRAR, en el idioma de la app (los campos
  /// [nombre] y [tag] son la referencia en español).
  String nombreMostrar(AppLocalizations l) => switch (key) {
        'escenario' => l.paletaEscenarioNombre,
        'consola' => l.paletaConsolaNombre,
        'placa' => l.paletaPlacaNombre,
        'wash' => l.paletaWashNombre,
        'worklight' => l.paletaLuzDeTrabajoNombre,
        'camarin' => l.paletaCamarinNombre,
        _ => nombre,
      };

  String tagMostrar(AppLocalizations l) => switch (key) {
        'escenario' => l.paletaEscenarioTag,
        'consola' => l.paletaConsolaTag,
        'placa' => l.paletaPlacaTag,
        'wash' => l.paletaWashTag,
        'worklight' => l.paletaLuzDeTrabajoTag,
        'camarin' => l.paletaCamarinTag,
        _ => tag,
      };

  static const List<AppPalette> todas = [
    escenario,
    consola,
    placa,
    wash,
    worklight,
    camarin
  ];

  /// La que se usa si el usuario nunca eligió una.
  static const porDefecto = escenario;

  static AppPalette porClave(String? clave) {
    return todas.firstWhere((p) => p.key == clave, orElse: () => porDefecto);
  }
}

/// Tema neón de "Escenario": mismo lenguaje visual que BienvenidaScreen
/// (bordes celestes finos, esquinas redondeadas, fondo muy oscuro).
ThemeData _temaEscenario() {
  const celeste = BienvenidaScreen._celeste;
  const violeta = BienvenidaScreen._violeta;
  const fondo = BienvenidaScreen._fondo;
  const superficie = Color(0xFF0F0D1F);
  const bordeSutil = Color(0x3322D3EE);
  final esquinas =
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));

  final esquema = ColorScheme.fromSeed(
    seedColor: celeste,
    brightness: Brightness.dark,
  ).copyWith(
    primary: const Color(0xFF14C8DC),
    onPrimary: Colors.white,
    secondary: violeta,
    onSecondary: Colors.white,
    tertiary: violeta,
    surface: superficie,
    onSurface: Colors.white,
    surfaceContainerLowest: fondo,
    surfaceContainerLow: const Color(0xFF0C0A18),
    surfaceContainer: superficie,
    surfaceContainerHigh: const Color(0xFF15132A),
    surfaceContainerHighest: const Color(0xFF1B1933),
    outline: const Color(0x8022D3EE),
    outlineVariant: const Color(0x3322D3EE),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: esquema,
    scaffoldBackgroundColor: fondo,
    canvasColor: fondo,
    dividerColor: Colors.white12,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0B0A18),
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: Border(bottom: BorderSide(color: bordeSutil)),
    ),
    cardTheme: CardThemeData(
      color: superficie,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: bordeSutil),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF14C8DC),
        foregroundColor: Colors.white,
        shape: esquinas,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xCC07060F),
        side: const BorderSide(color: Color(0xB322D3EE), width: 1.3),
        shape: esquinas,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: celeste),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: Colors.white),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: const Color(0xFF14C8DC),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF0C0A18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0x6622D3EE)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0x6622D3EE)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: celeste, width: 1.6),
      ),
      labelStyle: const TextStyle(color: Color(0xCCFFFFFF)),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: celeste,
      unselectedLabelColor: Color(0xB3FFFFFF),
      indicatorColor: celeste,
      dividerColor: bordeSutil,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: superficie,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: bordeSutil),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: superficie,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        side: BorderSide(color: bordeSutil),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF1B1933),
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: celeste,
      thumbColor: celeste,
      inactiveTrackColor: Color(0x3322D3EE),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF15132A),
      selectedColor: const Color(0x3322D3EE),
      side: const BorderSide(color: bordeSutil),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    listTileTheme: const ListTileThemeData(iconColor: celeste),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (estados) => estados.contains(WidgetState.selected)
            ? const Color(0xFF14C8DC)
            : null,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (estados) =>
            estados.contains(WidgetState.selected) ? Colors.white : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (estados) => estados.contains(WidgetState.selected)
            ? const Color(0xFF14C8DC)
            : null,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: celeste),
  );
}

/// Versión clara de "Escenario": mismas formas (bordes celestes finos,
/// esquinas redondeadas) sobre fondo claro, con el celeste oscurecido para
/// que tenga contraste y el violeta como secundario.
ThemeData _temaEscenarioClaro() {
  const celeste = Color(0xFF0891B2);
  const violeta = Color(0xFF7C3AED);
  const fondo = Color(0xFFF3F6FC);
  const superficie = Colors.white;
  const texto = Color(0xFF0B1220);
  const bordeSutil = Color(0x4D0891B2);
  final esquinas =
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));

  final esquema = ColorScheme.fromSeed(
    seedColor: celeste,
    brightness: Brightness.light,
  ).copyWith(
    primary: celeste,
    onPrimary: Colors.white,
    secondary: violeta,
    onSecondary: Colors.white,
    tertiary: violeta,
    surface: superficie,
    onSurface: texto,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: const Color(0xFFF8FAFE),
    surfaceContainer: const Color(0xFFEEF2FA),
    surfaceContainerHigh: const Color(0xFFE6ECF7),
    surfaceContainerHighest: const Color(0xFFDDE5F3),
    outline: const Color(0x990891B2),
    outlineVariant: bordeSutil,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: esquema,
    scaffoldBackgroundColor: fondo,
    canvasColor: fondo,
    dividerColor: Colors.black12,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: texto,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: Border(bottom: BorderSide(color: bordeSutil)),
    ),
    cardTheme: CardThemeData(
      color: superficie,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: bordeSutil),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: celeste,
        foregroundColor: Colors.white,
        shape: esquinas,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: texto,
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xB30891B2), width: 1.3),
        shape: esquinas,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: celeste),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: texto),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: celeste,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0x800891B2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0x800891B2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: celeste, width: 1.6),
      ),
      labelStyle: const TextStyle(color: Color(0xCC0B1220)),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: celeste,
      unselectedLabelColor: Color(0x990B1220),
      indicatorColor: celeste,
      dividerColor: bordeSutil,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: superficie,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: bordeSutil),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: superficie,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        side: BorderSide(color: bordeSutil),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF1B2540),
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: celeste,
      thumbColor: celeste,
      inactiveTrackColor: Color(0x330891B2),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFEEF2FA),
      selectedColor: const Color(0x330891B2),
      side: const BorderSide(color: bordeSutil),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    listTileTheme: const ListTileThemeData(iconColor: celeste),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (estados) => estados.contains(WidgetState.selected) ? celeste : null,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (estados) =>
            estados.contains(WidgetState.selected) ? Colors.white : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (estados) => estados.contains(WidgetState.selected) ? celeste : null,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: celeste),
  );
}

/// Construye el ThemeData de Material 3 para una paleta y un brillo dados.
ThemeData construirTema(AppPalette paleta, Brightness brightness) {
  if (paleta.key == AppPalette.escenario.key) {
    return brightness == Brightness.dark
        ? _temaEscenario()
        : _temaEscenarioClaro();
  }
  final esOscuro = brightness == Brightness.dark;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorSchemeSeed: esOscuro ? paleta.accentDark : paleta.accentLight,
    scaffoldBackgroundColor: esOscuro ? paleta.bgDark : paleta.bgLight,
    appBarTheme: AppBarTheme(
      backgroundColor: esOscuro ? paleta.surfaceDark : paleta.surfaceLight,
      foregroundColor: esOscuro ? Colors.white : Colors.black87,
      elevation: 0,
    ),
  );
}

/// Acceso rápido al color de acento actual desde cualquier widget.
extension AppColorX on BuildContext {
  Color get acento => Theme.of(this).colorScheme.primary;
}

// --- IDIOMAS ---

/// Idiomas de la app, cada uno con su nombre en su propio idioma (para
/// elegirlo aunque no se entienda el idioma actual). El primero es la
/// plantilla (lib/l10n/app_es.arb); el orden es el de la lista de elegir.
class IdiomasApp {
  static const List<(Locale, String)> todos = [
    (Locale('es'), 'Español'),
    (Locale('en'), 'English'),
    (Locale('pt'), 'Português'),
    (Locale('fr'), 'Français'),
    (Locale('it'), 'Italiano'),
  ];

  /// Si el idioma del dispositivo no está entre los de la app, se usa español.
  static const Locale respaldo = Locale('es');

  /// Elige el idioma de la app para el idioma del dispositivo (o el que haya
  /// pedido el sistema): el mismo idioma si existe, si no el español.
  static Locale resolver(List<Locale>? pedidos, Iterable<Locale> soportados) {
    for (final pedido in pedidos ?? const <Locale>[]) {
      for (final s in soportados) {
        if (s.languageCode == pedido.languageCode) return s;
      }
    }
    return respaldo;
  }
}

/// Las traducciones del idioma actual, para el código que no tiene un
/// BuildContext a mano (por ejemplo los mensajes de error de AuthService).
/// MaterialApp.builder la actualiza en cada cambio de idioma. En widgets
/// usar siempre `context.l10n`: así se redibujan solos al cambiar el idioma.
class L10n {
  static late AppLocalizations t;
}

extension L10nContexto on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Detecta swipes de UN solo dedo a partir de eventos crudos de puntero (se
/// usa con Listener, no GestureDetector — ver notas de diseño en
/// CONTEXTO_PARA_IA.md). Si en algún momento del gesto hubo más de un dedo
/// apoyado (ej. un pellizco para hacer zoom) el gesto entero se descarta:
/// sin esto, al levantar un dedo el movimiento se medía contra el punto donde
/// había apoyado el otro y se interpretaba como un swipe, cambiando de tema.
class DetectorSwipe {
  final Set<int> _punteros = {};
  Offset? _inicio;
  bool _variosDedos = false;

  void alBajar(PointerDownEvent evento) {
    _punteros.add(evento.pointer);
    if (_punteros.length > 1) {
      _variosDedos = true;
      _inicio = null;
    } else {
      _variosDedos = false;
      _inicio = evento.position;
    }
  }

  /// Devuelve cuánto se movió el dedo si fue un swipe de un solo dedo, o
  /// null si el gesto no vale (varios dedos, o no hubo un inicio).
  Offset? alSubir(PointerUpEvent evento) {
    _punteros.remove(evento.pointer);
    final inicio = _inicio;
    if (_variosDedos) {
      if (_punteros.isEmpty) _variosDedos = false;
      return null;
    }
    _inicio = null;
    if (inicio == null) return null;
    return evento.position - inicio;
  }

  void alCancelar(PointerCancelEvent evento) {
    _punteros.remove(evento.pointer);
    _inicio = null;
    if (_punteros.isEmpty) _variosDedos = false;
  }
}

/// Mientras no haya cobro real implementado, las funciones Pro (subir
/// partituras a la biblioteca personal) quedan liberadas para cualquier
/// usuario logueado, para poder probarlas. Volver a `false` cuando se
/// active el cobro.
const bool kFuncionesProGratisPorAhora = true;

// --- TRANSPOSICIÓN DE CIFRADOS (ACORDES EN TEXTO) ---

/// Transpone acordes en un texto plano ±semitonos. Soporta dos formatos:
/// - Acordes entre corchetes intercalados con la letra: "Ama[C]zing gra[G]ce".
/// - Líneas dedicadas a acordes (sueltos, separados por espacios) arriba de
///   la letra, como se ven en la mayoría de los cifrados de banda.
/// No modifica el PDF original: opera sobre un texto aparte que el usuario
/// carga o que se intenta extraer automáticamente del PDF al subirlo.
class ChordTransposer {
  static const List<String> _sostenidos = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];

  static const List<String> _bemoles = [
    'C',
    'Db',
    'D',
    'Eb',
    'E',
    'F',
    'Gb',
    'G',
    'Ab',
    'A',
    'Bb',
    'B',
  ];

  static final RegExp _tokenAcorde = RegExp(
    r'^([A-G])(#|b)?((?:maj|min|dim|aug|sus|add|m)?[0-9⁰¹²³⁴⁵⁶⁷⁸⁹]*(?:[#b][0-9]+)?\+?)?(?:/([A-G])(#|b)?)?$',
  );

  static final RegExp _entreCorchetes = RegExp(r'\[([^\]]+)\]');

  // Notación latina (Do Re Mi Fa Sol La Si): se transpone conservando esa notación.
  static const List<String> _latinosSostenidos = [
    'Do',
    'Do#',
    'Re',
    'Re#',
    'Mi',
    'Fa',
    'Fa#',
    'Sol',
    'Sol#',
    'La',
    'La#',
    'Si',
  ];
  static const List<String> _latinosBemoles = [
    'Do',
    'Reb',
    'Re',
    'Mib',
    'Mi',
    'Fa',
    'Solb',
    'Sol',
    'Lab',
    'La',
    'Sib',
    'Si',
  ];
  static final RegExp _tokenLatino = RegExp(
    r'^(Do|Re|Mi|Fa|Sol|La|Si)(#|b)?((?:maj|min|dim|aug|sus|add|m)?[0-9⁰¹²³⁴⁵⁶⁷⁸⁹]*(?:[#b][0-9]+)?\+?)?(?:/(Do|Re|Mi|Fa|Sol|La|Si)(#|b)?)?$',
  );

  static String transponerTexto(String texto, int semitonos) {
    if (semitonos == 0) return texto;
    return texto
        .split('\n')
        .map((linea) => _transponerLinea(linea, semitonos))
        .join('\n');
  }

  static String _transponerLinea(String linea, int semitonos) {
    if (_entreCorchetes.hasMatch(linea)) {
      return linea.replaceAllMapped(_entreCorchetes, (m) {
        final adentro = m.group(1)!;
        return '[${_transponerToken(adentro, semitonos) ?? adentro}]';
      });
    }

    if (!_esLineaDeAcordes(linea)) return linea;

    // Cada acorde se vuelve a escribir en la misma columna donde estaba, así
    // que si "C" pasa a "C#" (o "Bb" a "B") no se corre lo que viene después
    // ni se desalinea respecto de la sílaba que tiene abajo. Solo se empuja
    // el acorde siguiente cuando no queda lugar (siempre queda 1 espacio).
    final salida = StringBuffer();
    for (final m in RegExp(r'\S+').allMatches(linea)) {
      final original = m.group(0)!;
      final nuevo = _transponerToken(original, semitonos) ?? original;
      while (salida.length < m.start) {
        salida.write(' ');
      }
      if (salida.length > 0 && salida.length >= m.start) {
        final texto = salida.toString();
        if (!texto.endsWith(' ')) salida.write(' ');
      }
      salida.write(nuevo);
    }
    return salida.toString();
  }

  /// True si la línea es solo de acordes (ej. "C#m   A   E/G#").
  static bool esLineaDeAcordes(String linea) => _esLineaDeAcordes(linea);

  static bool _esLineaDeAcordes(String linea) {
    final palabras =
        linea.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (palabras.isEmpty) return false;
    // "Si", "Mi", "La" o "Sol" solos son palabras comunes: la notación latina
    // solo cuenta como acorde en una línea con al menos dos elementos.
    final acordes = palabras
        .where((w) =>
            _tokenAcorde.hasMatch(w) ||
            (palabras.length >= 2 && _tokenLatino.hasMatch(w)))
        .length;
    return acordes / palabras.length >= 0.6;
  }

  /// true si el texto tiene al menos un acorde que se pueda transponer
  /// (entre corchetes o en una línea de acordes).
  static bool hayAcordes(String texto) {
    for (final linea in texto.split('\n')) {
      if (_entreCorchetes.hasMatch(linea)) {
        if (_entreCorchetes
            .allMatches(linea)
            .any((m) => _transponerToken(m.group(1)!, 1) != null)) {
          return true;
        }
      } else if (_esLineaDeAcordes(linea)) {
        return true;
      }
    }
    return false;
  }

  static String? _transponerToken(String token, int semitonos) {
    final match = _tokenAcorde.firstMatch(token);
    if (match != null) {
      final raiz = match.group(1)!;
      final alteracion = match.group(2) ?? '';
      final sufijo = match.group(3) ?? '';
      final bajoRaiz = match.group(4);
      final bajoAlteracion = match.group(5) ?? '';
      var resultado = _transponerNota(raiz + alteracion, semitonos) + sufijo;
      if (bajoRaiz != null) {
        resultado +=
            '/${_transponerNota(bajoRaiz + bajoAlteracion, semitonos)}';
      }
      return resultado;
    }
    final latino = _tokenLatino.firstMatch(token);
    if (latino == null) return null;
    final sufijo = latino.group(3) ?? '';
    var resultado = _transponerNotaLatina(
            (latino.group(1)!) + (latino.group(2) ?? ''), semitonos) +
        sufijo;
    final bajo = latino.group(4);
    if (bajo != null) {
      resultado +=
          '/${_transponerNotaLatina(bajo + (latino.group(5) ?? ''), semitonos)}';
    }
    return resultado;
  }

  static String _transponerNotaLatina(String nota, int semitonos) {
    final tabla = nota.endsWith('b') ? _latinosBemoles : _latinosSostenidos;
    final indice = tabla.indexOf(nota);
    if (indice == -1) return nota;
    var nuevo = (indice + semitonos) % 12;
    if (nuevo < 0) nuevo += 12;
    return tabla[nuevo];
  }

  static String _transponerNota(String nota, int semitonos) {
    final usaBemoles = nota.contains('b');
    final tablaOrigen = usaBemoles ? _bemoles : _sostenidos;
    final indice = tablaOrigen.indexOf(nota);
    if (indice == -1) return nota;

    var nuevoIndice = (indice + semitonos) % 12;
    if (nuevoIndice < 0) nuevoIndice += 12;

    final tablaDestino = usaBemoles ? _bemoles : _sostenidos;
    return tablaDestino[nuevoIndice];
  }
}

// --- EXTRACCIÓN DE CIFRADO DESDE PDF (CON LA POSICIÓN DE LOS ACORDES) ---

/// Versión del formato del cifrado guardado (campo 'cifradoVersion' en
/// mi_repertorio y en setlist). 2 = armado con la posición real de los
/// acordes (CifradoPdfExtractor). Los documentos sin el campo vienen del
/// extractor viejo y CifradoViewerScreen los vuelve a extraer del PDF al
/// abrirlos. Si algún día cambia el formato otra vez, subir este número.
const int kVersionCifrado = 2;

/// Un carácter del PDF con su posición horizontal original.
class _GlifoPdf {
  final String texto;
  final double x0;
  final double x1;
  const _GlifoPdf(this.texto, this.x0, this.x1);
}

/// Una línea del PDF ya reconstruida como texto, guardando para cada
/// carácter la coordenada X que tenía en la página.
class _LineaPdf {
  final double top;
  final String texto;
  final List<double> xs;
  final bool esAcordes;
  const _LineaPdf(this.top, this.texto, this.xs, this.esAcordes);

  double get x0 => xs.first;
}

/// Convierte el PDF en texto monoespaciado conservando el layout: cada acorde
/// queda en la columna de la sílaba que tiene debajo en el PDF original (las
/// letras del PDF son de ancho variable, por eso no alcanza con copiar los
/// espacios: se mide la posición real de cada acorde contra cada letra).
class CifradoPdfExtractor {
  /// Devuelve el texto del cifrado, o '' si el PDF no tiene texto
  /// seleccionable (ej. un escaneo o una foto).
  static String extraer(sf_pdf.PdfDocument documento) {
    final extractor = sf_pdf.PdfTextExtractor(documento);
    final paginas = <String>[];
    for (var i = 0; i < documento.pages.count; i++) {
      final lineasPdf =
          extractor.extractTextLines(startPageIndex: i, endPageIndex: i);
      final texto = _armarPagina(lineasPdf);
      if (texto.trim().isNotEmpty) paginas.add(texto);
    }
    return paginas.join('\n\n').trim();
  }

  static String _armarPagina(List<sf_pdf.TextLine> lineasPdf) {
    // Ancho promedio de un carácter, para convertir distancias en columnas.
    var sumaAnchos = 0.0;
    var cantidad = 0;
    for (final l in lineasPdf) {
      for (final p in l.wordCollection) {
        for (final g in p.glyphs) {
          final ancho = g.bounds.width;
          if (g.text.isNotEmpty && ancho > 0) {
            sumaAnchos += ancho;
            cantidad++;
          }
        }
      }
    }
    if (cantidad == 0) return '';
    final cw = sumaAnchos / cantidad;

    // El extractor a veces parte un mismo renglón en varios pedazos (misma
    // altura, ej. la última letra suelta): se juntan antes de armar la línea.
    final ordenadas = [...lineasPdf]
      ..sort((a, b) => a.bounds.top.compareTo(b.bounds.top));
    final grupos = <List<sf_pdf.TextLine>>[];
    for (final l in ordenadas) {
      if (grupos.isNotEmpty &&
          (l.bounds.top - grupos.last.first.bounds.top).abs() < 2.0) {
        grupos.last.add(l);
      } else {
        grupos.add([l]);
      }
    }

    final lineas = <_LineaPdf>[];
    for (final grupo in grupos) {
      final linea = _armarLinea(grupo, cw);
      if (linea != null) lineas.add(linea);
    }
    if (lineas.isEmpty) return '';
    lineas.sort((a, b) => a.top.compareTo(b.top));

    final margen = lineas.map((l) => l.x0).reduce(min);
    int columna(double x) => max(0, ((x - margen) / cw).round());

    // Separación normal entre renglones, para detectar renglones en blanco.
    final saltos = <double>[];
    for (var i = 1; i < lineas.length; i++) {
      final d = lineas[i].top - lineas[i - 1].top;
      if (d > 0.5) saltos.add(d);
    }
    saltos.sort();
    final paso = saltos.isEmpty ? 15.0 : saltos[saltos.length ~/ 2];

    final salida = <String>[];
    var i = 0;
    while (i < lineas.length) {
      final actual = lineas[i];

      if (i > 0) {
        final blancos = ((actual.top - lineas[i - 1].top) / paso).round() - 1;
        for (var b = 0; b < min(blancos, 3); b++) {
          salida.add('');
        }
      }

      final siguiente = i + 1 < lineas.length ? lineas[i + 1] : null;
      final hayLetraDebajo = actual.esAcordes &&
          siguiente != null &&
          !siguiente.esAcordes &&
          siguiente.texto.trim().isNotEmpty &&
          (siguiente.top - actual.top) <= paso * 1.5;

      if (hayLetraDebajo) {
        _acordesSobreLetra(actual, siguiente, cw, columna, salida);
        i += 2;
        continue;
      }

      if (actual.esAcordes) {
        salida.add(_ubicarFichas(actual, (x) => columna(x), 0).trimRight());
      } else {
        salida.add((' ' * columna(actual.x0)) + actual.texto);
      }
      i++;
    }

    return salida.join('\n').trimRight();
  }

  /// Escribe la línea de acordes y la de letra de abajo de modo que cada
  /// acorde caiga sobre la misma sílaba que en el PDF.
  static void _acordesSobreLetra(
    _LineaPdf acordes,
    _LineaPdf letra,
    double cw,
    int Function(double) columna,
    List<String> salida,
  ) {
    final sangria = columna(letra.x0);
    final finLetraX = letra.xs.last + cw;

    int columnaSobreLetra(double x) {
      if (x >= finLetraX) {
        return sangria + letra.texto.length + ((x - finLetraX) / cw).round();
      }
      var mejor = 0;
      var menorDistancia = double.infinity;
      for (var j = 0; j < letra.xs.length; j++) {
        final d = (letra.xs[j] - x).abs();
        if (d < menorDistancia) {
          menorDistancia = d;
          mejor = j;
        }
      }
      // Un acorde a la izquierda del primer carácter queda antes de la letra.
      if (x < letra.xs.first - cw / 2) {
        return sangria - ((letra.xs.first - x) / cw).round();
      }
      return sangria + mejor;
    }

    // Si algún acorde cae a la izquierda del margen, se corre todo a la derecha.
    var minimo = 0;
    for (final m in RegExp(r'\S+').allMatches(acordes.texto)) {
      minimo = min(minimo, columnaSobreLetra(acordes.xs[m.start]));
    }
    final corrimiento = -minimo;

    salida.add(
        _ubicarFichas(acordes, (x) => columnaSobreLetra(x) + corrimiento, 0)
            .trimRight());
    salida.add((' ' * (sangria + corrimiento)) + letra.texto);
  }

  /// Arma una línea poniendo cada "ficha" (acorde o palabra) en su columna,
  /// siempre con al menos un espacio entre una y otra.
  static String _ubicarFichas(
      _LineaPdf linea, int Function(double) columnaDe, int base) {
    final sb = StringBuffer();
    for (final m in RegExp(r'\S+').allMatches(linea.texto)) {
      final col = base + columnaDe(linea.xs[m.start]);
      while (sb.length < col) {
        sb.write(' ');
      }
      if (sb.length > 0 && !sb.toString().endsWith(' ')) sb.write(' ');
      sb.write(m.group(0));
    }
    return sb.toString();
  }

  static _LineaPdf? _armarLinea(List<sf_pdf.TextLine> pedazos, double cw) {
    final glifos = <_GlifoPdf>[];
    for (final l in pedazos) {
      for (final p in l.wordCollection) {
        for (final g in p.glyphs) {
          if (g.text.isEmpty) continue;
          glifos.add(_GlifoPdf(g.text, g.bounds.left, g.bounds.right));
        }
      }
    }
    if (glifos.isEmpty) return null;
    glifos.sort((a, b) => a.x0.compareTo(b.x0));

    final sb = StringBuffer();
    final xs = <double>[];
    double? finAnterior;
    for (final g in glifos) {
      if (finAnterior != null) {
        // Hueco que el PDF deja sin dibujar ningún carácter (típico entre
        // acordes): se rellena con espacios proporcionales a su ancho.
        final hueco = g.x0 - finAnterior;
        if (hueco > cw * 0.9) {
          final extra = (hueco / cw).round();
          for (var k = 0; k < extra; k++) {
            sb.write(' ');
            xs.add(finAnterior + k * cw);
          }
        }
      }
      for (var k = 0; k < g.texto.length; k++) {
        sb.write(g.texto[k]);
        xs.add(g.x0 + (g.x1 - g.x0) * k / g.texto.length);
      }
      finAnterior = g.x1;
    }

    // Sin espacios sobrantes al principio ni al final (el PDF suele dejar uno).
    final completo = sb.toString();
    final recortado = completo.trim();
    if (recortado.isEmpty) return null;
    final inicio = completo.length - completo.trimLeft().length;
    final xsRecortados = xs.sublist(inicio, inicio + recortado.length);

    return _LineaPdf(
      pedazos.first.bounds.top,
      recortado,
      xsRecortados,
      ChordTransposer.esLineaDeAcordes(recortado),
    );
  }
}

// --- SERVICIO DE AUTENTICACIÓN ---

class AuthService {
  static FirebaseAuth get _auth => FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;

  /// True solo para cuentas reales (email/contraseña o Google). Los
  /// invitados que entran a una sala quedan autenticados de forma anónima
  /// para que las reglas de Firestore puedan exigir "estar autenticado"
  /// sin pedirles cuenta — pero eso NO los debe habilitar para funciones
  /// de cuenta real como frases propias, repertorio o Pro.
  static bool get esUsuarioRegistrado =>
      currentUser != null && !currentUser!.isAnonymous;

  static Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Garantiza que haya alguna sesión de Firebase Auth activa (anónima si
  /// hace falta) antes de leer/escribir datos de una sala. No pisa una
  /// sesión real ya iniciada.
  static Future<void> asegurarSesion() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  /// Inicia sesión con Google. En web usa popup; en mobile usa el SDK nativo.
  static Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      return _auth.signInWithPopup(provider);
    }

    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw Exception(L10n.t.inicioDeSesionConGoogle);
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  static Future<UserCredential> registerWithEmail(
      String email, String password) {
    return _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
  }

  static Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);
  }

  static Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  static Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) {
      await GoogleSignIn().signOut();
    }
  }

  /// Traduce los codigos de error mas comunes de Firebase Auth a mensajes legibles.
  static String mensajeError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return L10n.t.elEmailNoEsValido;
        case 'user-disabled':
          return L10n.t.estaCuentaFueDeshabilitada;
        case 'user-not-found':
          return L10n.t.noExisteUnaCuentaCon;
        case 'wrong-password':
        case 'invalid-credential':
          return L10n.t.emailOContrasenaIncorrectos;
        case 'email-already-in-use':
          return L10n.t.yaExisteUnaCuentaCon;
        case 'weak-password':
          return L10n.t.laContrasenaDebeTenerAl;
        default:
          return error.message ?? L10n.t.errorDeAutenticacion;
      }
    }
    return error.toString();
  }
}

// --- SERVICIO DE USUARIOS Y FRASES PREDEFINIDAS ---

class UsuarioService {
  static DocumentReference<Map<String, dynamic>> _ref(String uid) =>
      FirebaseFirestore.instance.collection('usuarios').doc(uid);

  static Future<void> guardarPerfil({
    required String uid,
    required String nombre,
    required String rol,
    String? email,
  }) async {
    await _ref(uid).set({
      'nombre': nombre,
      'rol': rol,
      'email': email,
      'esPro': false,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<Map<String, dynamic>?> obtenerPerfil(String uid) async {
    final snap = await _ref(uid).get();
    return snap.data();
  }

  /// Stream reactivo de si el usuario tiene la versión Pro (habilita subir
  /// PDFs a su repertorio). El campo esPro nunca lo puede escribir el propio
  /// usuario: lo protegen las reglas de Firestore, y hoy se activa a mano
  /// desde la consola hasta que haya cobro real integrado.
  static Stream<bool> streamEsPro(String uid) {
    return _ref(uid).snapshots().map((snap) => snap.data()?['esPro'] == true);
  }
}

/// Historial de salas de una cuenta Pro (usuarios/{uid}/mis_salas/{codigoSala}).
/// Guarda una referencia liviana (no los pedidos/setlist en sí, esos siguen
/// viviendo en salas/{codigoSala}) para que un músico que toca en varias
/// bandas pueda volver a entrar sin memorizar el código. Función Pro: solo
/// se escribe cuando kFuncionesProGratisPorAhora o esPro==true (ver llamadas
/// en CrearSalaScreen, UnirmeSalaScreen y SonidistaPinScreen).
class MisSalasService {
  static CollectionReference<Map<String, dynamic>> _ref(String uid) =>
      FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('mis_salas');

  static Stream<QuerySnapshot<Map<String, dynamic>>> streamMisSalas(
      String uid) {
    return _ref(uid).orderBy('ultimoAcceso', descending: true).snapshots();
  }

  /// El id del documento es el propio código de sala: entrar de nuevo a la
  /// misma sala actualiza la referencia existente en vez de duplicarla.
  static Future<void> registrarAcceso({
    required String uid,
    required String codigoSala,
    required String rolUsado,
    String nombre = '',
  }) async {
    await _ref(uid).doc(codigoSala).set({
      'rolUsado': rolUsado,
      'nombre': nombre,
      'ultimoAcceso': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> renombrar(
      String uid, String codigoSala, String nombreSala) async {
    await _ref(uid).doc(codigoSala).update({'nombreSala': nombreSala});
  }

  static Future<void> quitar(String uid, String codigoSala) async {
    await _ref(uid).doc(codigoSala).delete();
  }
}

/// Registra el acceso a una sala en el historial de la cuenta (mis_salas) si
/// el usuario tiene cuenta real y la función Pro está habilitada (o gratis
/// por ahora vía kFuncionesProGratisPorAhora). No hace nada para invitados
/// anónimos ni cuentas sin Pro. Se llama desde CrearSalaScreen,
/// UnirmeSalaScreen y SonidistaPinScreen al entrar a una sala.
Future<void> _registrarSalaSiCorresponde({
  required String codigoSala,
  required String rolUsado,
  String nombre = '',
}) async {
  if (!AuthService.esUsuarioRegistrado) return;
  final uid = AuthService.currentUser!.uid;
  final esPro = kFuncionesProGratisPorAhora ||
      await UsuarioService.streamEsPro(uid).first;
  if (!esPro) return;
  await MisSalasService.registrarAcceso(
    uid: uid,
    codigoSala: codigoSala,
    rolUsado: rolUsado,
    nombre: nombre,
  );
}

/// Frases predefinidas propias de cada usuario, en usuarios/{uid}/frases.
/// Los invitados (sin cuenta) usan AppConstants.pedidosRapidos directamente
/// y nunca tocan Firestore para esto.
class FrasesService {
  static CollectionReference<Map<String, dynamic>> _ref(String uid) =>
      FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('frases');

  static Stream<QuerySnapshot<Map<String, dynamic>>> streamFrases(String uid) {
    return _ref(uid).orderBy('orden').snapshots();
  }

  static Future<void> agregarFrase(String uid, String texto, int orden) async {
    await _ref(uid).add({
      'texto': texto,
      'orden': orden,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> editarFrase(String uid, String id, String texto) async {
    await _ref(uid).doc(id).update({'texto': texto});
  }

  static Future<void> eliminarFrase(String uid, String id) async {
    await _ref(uid).doc(id).delete();
  }

  /// Copia el set base (AppConstants.pedidosRapidos) a la colección personal
  /// del usuario, en el idioma que tenga la app en ese momento. Se llama una
  /// sola vez, al registrarse.
  static Future<void> copiarFrasesBaseParaUsuario(String uid) async {
    final frases = AppConstants.pedidosRapidos(L10n.t);
    final batch = FirebaseFirestore.instance.batch();
    for (var i = 0; i < frases.length; i++) {
      final doc = _ref(uid).doc();
      batch.set(doc, {
        'texto': frases[i],
        'orden': i,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}

// --- SERVICIO DE COMPAÑEROS DE SALA (PRESENCIA PARA BUSCAR BIBLIOTECAS) ---

/// salas/{codigoSala} no tiene documento propio ni noción de membresía (ver
/// CONTEXTO_PARA_IA.md §6) — es solo un código compartido. Esta colección es
/// la única forma de saber "quién más anduvo por esta sala con una cuenta
/// real", para que el buscador de RepertorioService sepa en qué
/// usuarios/{uid}/mi_repertorio mirar al armar el setlist. Los invitados
/// anónimos no se registran acá: no tienen biblioteca, no aportan nada al
/// buscador.
class MiembrosSalaService {
  static CollectionReference<Map<String, dynamic>> _ref(String codigoSala) =>
      FirebaseFirestore.instance
          .collection('salas')
          .doc(codigoSala)
          .collection('miembros');

  /// Se llama al entrar a RequestScreen/SonidistaPage. No hace nada para
  /// invitados anónimos ni si falla (falta de red, etc.) — es best-effort,
  /// no debe romper el ingreso a la sala.
  static Future<void> registrarPresencia(String codigoSala) async {
    if (!AuthService.esUsuarioRegistrado) return;
    final user = AuthService.currentUser!;
    final perfil = await UsuarioService.obtenerPerfil(user.uid);
    final nombrePerfil = (perfil?['nombre'] as String?)?.trim();
    final nombre = (nombrePerfil != null && nombrePerfil.isNotEmpty)
        ? nombrePerfil
        : (user.email ?? 'Sin nombre');
    await _ref(codigoSala).doc(user.uid).set({
      'nombre': nombre,
      'ultimaConexion': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Todas las cuentas reales que pasaron por esta sala, incluido el propio
  /// usuario (su presencia también queda registrada acá por
  /// registrarPresencia) — así el buscador de bibliotecas de la sala incluye
  /// la propia biblioteca junto a la de los compañeros.
  static Future<List<Map<String, dynamic>>> obtenerPresentes(
      String codigoSala) async {
    final snap = await _ref(codigoSala).get();
    return snap.docs.map((d) => {...d.data(), 'uid': d.id}).toList();
  }
}

// --- SERVICIO DE REPERTORIO PERSONAL (BIBLIOTECA DE PARTITURAS) ---

/// Biblioteca de canciones/partituras propia de cada usuario.
/// PDFs en Storage: usuarios/{uid}/canciones/{archivo}.pdf — hoy en el
/// bucket de Supabase (kSupabaseRepertorioBucket), TEMPORALMENTE, mientras
/// Firebase Storage no está aprovisionado (falta activar el plan Blaze; ver
/// CONTEXTO_PARA_IA.md). El documento de metadatos guarda 'storageProvider'
/// ('supabase' o 'firebase') para saber con qué backend borrar el archivo.
/// Cuando se active Blaze, volver a Firebase acá adentro es cambiar
/// subirCancion (y el branch de eliminarCancion) — no hace falta migrar
/// los documentos viejos, conviven los dos providers por su campo.
/// Metadatos en Firestore: usuarios/{uid}/mi_repertorio/{cancionId}
class RepertorioService {
  static CollectionReference<Map<String, dynamic>> _ref(String uid) =>
      FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('mi_repertorio');

  static Stream<QuerySnapshot<Map<String, dynamic>>> streamRepertorio(
      String uid) {
    return _ref(uid).orderBy('createdAt', descending: true).snapshots();
  }

  /// Ordena alfabéticamente por título, ignorando mayúsculas/minúsculas.
  /// Firestore no puede hacer esto solo (ordena por código de carácter, así
  /// que un título en minúscula quedaría después de todos los que empiezan
  /// con mayúscula) — se ordena acá, del lado del cliente.
  static List<QueryDocumentSnapshot<Map<String, dynamic>>> ordenarPorTitulo(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final ordenados = [...docs];
    ordenados.sort((a, b) => (a.data()['titulo'] as String? ?? '')
        .toLowerCase()
        .compareTo((b.data()['titulo'] as String? ?? '').toLowerCase()));
    return ordenados;
  }

  /// Supabase Storage rechaza keys con espacios, tildes, paréntesis, etc.
  /// (statusCode 400, error InvalidKey). Se sanitiza el nombre de archivo
  /// original antes de armar el storagePath — no afecta el 'titulo' que
  /// se muestra en la UI, solo el nombre interno del objeto en el bucket.
  static String _sanitizarNombreArchivo(String nombre) {
    return nombre.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }

  /// Intenta extraer el texto embebido del PDF (best-effort). Si el PDF es
  /// un escaneo/foto no va a tener texto seleccionable y devuelve ''.
  static String extraerTextoPdf(Uint8List bytes) {
    sf_pdf.PdfDocument? documento;
    try {
      documento = sf_pdf.PdfDocument(inputBytes: bytes);
      try {
        // Reconstruye el layout con la posición real de cada acorde.
        final conPosiciones = CifradoPdfExtractor.extraer(documento);
        if (conPosiciones.isNotEmpty) return conPosiciones;
      } catch (e) {
        debugPrint(
            'No se pudo reconstruir el layout del PDF, uso extracción simple: $e');
      }
      // Respaldo: extracción simple (los acordes pueden quedar desalineados).
      return sf_pdf.PdfTextExtractor(documento)
          .extractText(layoutText: true)
          .trim();
    } catch (e) {
      debugPrint('No se pudo extraer texto del PDF: $e');
      return '';
    } finally {
      documento?.dispose();
    }
  }

  /// Vuelve a extraer el cifrado de cada PDF de la biblioteca con la posición
  /// real de los acordes (ver CifradoPdfExtractor) y reemplaza el texto
  /// guardado. Sirve para las canciones subidas antes de que existiera ese
  /// extractor, que quedaron con los acordes pegados a la izquierda. Las
  /// canciones cuyo PDF no tiene texto seleccionable conservan el cifrado que
  /// ya tenían. [alAvanzar] recibe (hechas, total).
  static Future<({int actualizadas, int sinTexto, int fallidas})>
      regenerarCifrados(
    String uid, {
    void Function(int hechas, int total)? alAvanzar,
  }) async {
    final snap = await _ref(uid).get();
    var actualizadas = 0;
    var sinTexto = 0;
    var fallidas = 0;
    var hechas = 0;

    for (final doc in snap.docs) {
      try {
        final data = doc.data();
        final storagePath = data['storagePath'] as String? ?? '';
        final proveedor = data['storageProvider'] as String? ?? 'firebase';
        if (storagePath.isEmpty) {
          fallidas++;
        } else {
          final Uint8List? bytes = proveedor == 'supabase'
              ? await supabase.storage
                  .from(kSupabaseRepertorioBucket)
                  .download(storagePath)
              : await FirebaseStorage.instance.ref(storagePath).getData();
          if (bytes == null) {
            fallidas++;
          } else {
            final texto = extraerTextoPdf(bytes);
            if (texto.isEmpty) {
              sinTexto++;
            } else {
              await _ref(uid).doc(doc.id).update(
                  {'cifradoTexto': texto, 'cifradoVersion': kVersionCifrado});
              actualizadas++;
            }
          }
        }
      } catch (e) {
        debugPrint('No se pudo regenerar el cifrado de ${doc.id}: $e');
        fallidas++;
      }
      hechas++;
      alAvanzar?.call(hechas, snap.docs.length);
    }

    return (actualizadas: actualizadas, sinTexto: sinTexto, fallidas: fallidas);
  }

  /// Sube el PDF a Supabase Storage (bucket público, ver kSupabaseRepertorioBucket
  /// y CONTEXTO_PARA_IA.md para el porqué) y crea el documento de metadatos
  /// en Firestore. Devuelve el mapa con los datos guardados (incluye pdfUrl).
  static Future<Map<String, dynamic>> subirCancion({
    required String uid,
    required String titulo,
    required String tonalidad,
    required String nombreArchivo,
    required Uint8List bytes,
    String cifradoTexto = '',
  }) async {
    final nombreUnico =
        '${DateTime.now().millisecondsSinceEpoch}_${_sanitizarNombreArchivo(nombreArchivo)}';
    final storagePath = 'usuarios/$uid/canciones/$nombreUnico';

    await supabase.storage.from(kSupabaseRepertorioBucket).uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(contentType: 'application/pdf'),
        );
    final pdfUrl = supabase.storage
        .from(kSupabaseRepertorioBucket)
        .getPublicUrl(storagePath);

    final data = {
      'titulo': titulo,
      'tonalidad': tonalidad,
      'pdfUrl': pdfUrl,
      'storagePath': storagePath,
      'storageProvider': 'supabase',
      'cifradoTexto': cifradoTexto,
      'cifradoVersion': kVersionCifrado,
      'createdAt': FieldValue.serverTimestamp(),
    };
    final doc = await _ref(uid).add(data);
    return {...data, 'id': doc.id};
  }

  static Future<void> editarCancion({
    required String uid,
    required String cancionId,
    required String titulo,
    required String tonalidad,
    String cifradoTexto = '',
  }) async {
    // Al guardar a mano se marca como versión actual: el texto es el que el
    // usuario quiere y no se debe pisar re-extrayendo del PDF.
    await _ref(uid).doc(cancionId).update({
      'titulo': titulo,
      'tonalidad': tonalidad,
      'cifradoTexto': cifradoTexto,
      'cifradoVersion': kVersionCifrado,
    });
  }

  /// Guarda el cifrado re-extraído del PDF (lo llama CifradoViewerScreen).
  static Future<void> guardarCifradoRegenerado(
      String uid, String cancionId, String texto) async {
    await _ref(uid)
        .doc(cancionId)
        .update({'cifradoTexto': texto, 'cifradoVersion': kVersionCifrado});
  }

  /// Borra el archivo del backend de Storage que corresponda (lee
  /// 'storageProvider' del propio documento, ya que la firma del método no
  /// cambió para no tocar el call site en MiRepertorioScreen) y el
  /// documento de metadatos.
  static Future<void> eliminarCancion({
    required String uid,
    required String cancionId,
    String? storagePath,
  }) async {
    if (storagePath != null && storagePath.isNotEmpty) {
      try {
        final doc = await _ref(uid).doc(cancionId).get();
        final storageProvider =
            doc.data()?['storageProvider'] as String? ?? 'firebase';
        if (storageProvider == 'supabase') {
          await supabase.storage
              .from(kSupabaseRepertorioBucket)
              .remove([storagePath]);
        } else {
          await FirebaseStorage.instance.ref(storagePath).delete();
        }
      } catch (e) {
        debugPrint('No se pudo borrar el archivo de Storage: $e');
      }
    }
    await _ref(uid).doc(cancionId).delete();
  }

  /// Trae TODAS las canciones de las bibliotecas de los compañeros de sala
  /// (ver MiembrosSalaService) de una sola vez — no en toda la app.
  /// Firestore no soporta "uid in [...]" combinado con full-text search, así
  /// que se hace una consulta por compañero (colección normal, sin falta de
  /// índice de collection group) y se combina del lado del cliente. El
  /// filtro por texto se hace aparte, en memoria, para poder sugerir en vivo
  /// mientras el usuario escribe sin volver a golpear Firestore por letra.
  static Future<List<Map<String, dynamic>>> cancionesDeCompaneros(
    List<Map<String, dynamic>> companeros,
  ) async {
    final resultados = <Map<String, dynamic>>[];
    for (final companero in companeros) {
      final uid = companero['uid'] as String;
      final nombreCompanero = companero['nombre'] as String? ?? '';
      final snap = await _ref(uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      resultados.addAll(snap.docs.map((d) =>
          {...d.data(), 'id': d.id, 'propietarioNombre': nombreCompanero}));
    }
    return resultados;
  }

  /// Quita tildes/diéresis y pasa a minúsculas, para que buscar "glorioso
  /// dia" encuentre "Glorioso día" sin que el usuario tenga que tipear la
  /// tilde. Alcanza con los caracteres acentuados del español.
  static String _normalizar(String texto) {
    const conTilde = 'áéíóúüñ';
    const sinTilde = 'aeiouun';
    var resultado = texto.toLowerCase();
    for (var i = 0; i < conTilde.length; i++) {
      resultado = resultado.replaceAll(conTilde[i], sinTilde[i]);
    }
    return resultado;
  }

  /// Filtro en memoria por título Y tonalidad (campos independientes, ambos
  /// deben coincidir), usado para sugerencias en vivo. Ignora mayúsculas/
  /// minúsculas y tildes (ver _normalizar).
  static List<Map<String, dynamic>> filtrarPorTituloYTonalidad(
    List<Map<String, dynamic>> canciones, {
    required String titulo,
    required String tonalidad,
  }) {
    final tituloQuery = _normalizar(titulo.trim());
    final tonalidadQuery = _normalizar(tonalidad.trim());
    if (tituloQuery.isEmpty && tonalidadQuery.isEmpty) return canciones;
    return canciones.where((c) {
      final coincideTitulo = tituloQuery.isEmpty ||
          _normalizar(c['titulo'] as String? ?? '').contains(tituloQuery);
      final coincideTonalidad = tonalidadQuery.isEmpty ||
          _normalizar(c['tonalidad'] as String? ?? '').contains(tonalidadQuery);
      return coincideTitulo && coincideTonalidad;
    }).toList();
  }
}

// --- SERVICIO DE SETLIST DE SALA (LISTA DE TEMAS DEL DÍA) ---

class SetlistService {
  static CollectionReference<Map<String, dynamic>> _ref(String codigoSala) =>
      FirebaseFirestore.instance
          .collection('salas')
          .doc(codigoSala)
          .collection('setlist');

  static Stream<QuerySnapshot<Map<String, dynamic>>> streamSetlist(
      String codigoSala) {
    return _ref(codigoSala).orderBy('orden').snapshots();
  }

  static Future<void> agregarAlSetlist({
    required String codigoSala,
    required String titulo,
    required String pdfUrl,
    required String subidoPor,
    required int orden,
    String cifradoTexto = '',
    int? cifradoVersion,
  }) async {
    await _ref(codigoSala).add({
      'titulo': titulo,
      'pdfUrl': pdfUrl,
      'subidoPor': subidoPor,
      'orden': orden,
      'cifradoTexto': cifradoTexto,
      // Se copia la versión de la canción de origen: si es vieja (sin
      // campo), el visor re-extrae del PDF la primera vez que se abre.
      if (cifradoVersion != null) 'cifradoVersion': cifradoVersion,
      'completado': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Guarda el cifrado re-extraído del PDF (lo llama CifradoViewerScreen).
  static Future<void> actualizarCifrado(
      String codigoSala, String itemId, String texto) async {
    await _ref(codigoSala)
        .doc(itemId)
        .update({'cifradoTexto': texto, 'cifradoVersion': kVersionCifrado});
  }

  static Future<void> eliminarDelSetlist(
      String codigoSala, String itemId) async {
    await _ref(codigoSala).doc(itemId).delete();
  }

  /// Actualiza el estado de un tema: 'pendiente', 'pausado' (corte técnico)
  /// o 'tocado'. Mantiene 'completado' (bool) en sync para no romper
  /// documentos/lecturas viejas que solo conocían ese campo binario.
  static Future<void> actualizarEstado(
      String codigoSala, String itemId, String estado) async {
    await _ref(codigoSala).doc(itemId).update({
      'estado': estado,
      'completado': estado == 'tocado',
      'completadoAt': estado == 'tocado'
          ? FieldValue.serverTimestamp()
          : FieldValue.delete(),
    });
  }

  /// Actualiza la transposición (en semitonos) de un tema, para que se
  /// sincronice en vivo a todos los que estén viendo el cifrado de esa
  /// canción en la sala.
  static Future<void> actualizarTransposicion(
      String codigoSala, String itemId, int semitonos) async {
    await _ref(codigoSala).doc(itemId).update({'transposicion': semitonos});
  }

  /// Reescribe el campo 'orden' de todos los temas según su posición en
  /// [idsEnOrden] (ej. después de un drag & drop en vivo).
  static Future<void> reordenarSetlist(
      String codigoSala, List<String> idsEnOrden) async {
    final batch = FirebaseFirestore.instance.batch();
    for (var i = 0; i < idsEnOrden.length; i++) {
      batch.update(_ref(codigoSala).doc(idsEnOrden[i]), {'orden': i});
    }
    await batch.commit();
  }
}

// --- SERVICIO DE SECUENCIAS (PISTAS DE AUDIO: BIBLIOTECA Y SALA) ---

/// Secuencias = pistas de audio (backing tracks, clicks, loops) que cada
/// usuario guarda en su cuenta, sin límite de cantidad, y que después carga
/// en la sala para el show del día. Mismo esquema que el repertorio de PDFs:
/// archivo en el bucket de Supabase (kSupabaseRepertorioBucket, carpeta
/// usuarios/{uid}/secuencias/ — las políticas RLS por carpeta de usuario ya
/// la cubren) y metadatos en Firestore:
///   usuarios/{uid}/mis_secuencias/{id} — biblioteca personal
///   salas/{codigoSala}/secuencias/{id} — las elegidas para el show (copia
///     liviana: título + URL pública, igual que el setlist con los PDFs)
class SecuenciasService {
  static const extensionesPermitidas = ['mp3', 'wav', 'm4a', 'aac', 'ogg'];

  /// Límite fijo por archivo del plan gratis de Supabase Storage (no se
  /// puede subir sin pasar a Pro). Un WAV de más de ~5 minutos ya lo supera.
  static const tamanoMaximoBytes = 50 * 1024 * 1024;

  static String formatearMb(int bytes) =>
      '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

  /// Los archivos que pasan tamanoMaximoBytes se convierten a MP3 en el
  /// navegador antes de subirlos (web/conversor_mp3.js, solo en web). Se
  /// apunta un poco por debajo del límite para no rozarlo.
  static const tamanoObjetivoMp3Bytes = 48 * 1024 * 1024;

  static CollectionReference<Map<String, dynamic>> _refUsuario(String uid) =>
      FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('mis_secuencias');

  static CollectionReference<Map<String, dynamic>> _refSala(
          String codigoSala) =>
      FirebaseFirestore.instance
          .collection('salas')
          .doc(codigoSala)
          .collection('secuencias');

  static Stream<QuerySnapshot<Map<String, dynamic>>> streamMisSecuencias(
      String uid) {
    return _refUsuario(uid).orderBy('createdAt', descending: true).snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> streamSecuenciasSala(
      String codigoSala) {
    return _refSala(codigoSala).orderBy('orden').snapshots();
  }

  static String _contentType(String nombreArchivo) {
    switch (nombreArchivo.split('.').last.toLowerCase()) {
      case 'wav':
        return 'audio/wav';
      case 'm4a':
        return 'audio/mp4';
      case 'aac':
        return 'audio/aac';
      case 'ogg':
        return 'audio/ogg';
      default:
        return 'audio/mpeg';
    }
  }

  static Future<void> subirSecuencia({
    required String uid,
    required String titulo,
    required String nombreArchivo,
    required Uint8List bytes,
  }) async {
    final nombreUnico =
        '${DateTime.now().millisecondsSinceEpoch}_${RepertorioService._sanitizarNombreArchivo(nombreArchivo)}';
    final storagePath = 'usuarios/$uid/secuencias/$nombreUnico';

    await supabase.storage.from(kSupabaseRepertorioBucket).uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(contentType: _contentType(nombreArchivo)),
        );
    final audioUrl = supabase.storage
        .from(kSupabaseRepertorioBucket)
        .getPublicUrl(storagePath);

    await _refUsuario(uid).add({
      'titulo': titulo,
      'audioUrl': audioUrl,
      'storagePath': storagePath,
      'storageProvider': 'supabase',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> renombrarSecuencia(
      String uid, String id, String titulo) async {
    await _refUsuario(uid).doc(id).update({'titulo': titulo});
  }

  /// Borra el archivo (best-effort) y el documento. Las copias que ya estén
  /// cargadas en alguna sala quedan apuntando a un audio que ya no existe;
  /// se ven en la lista pero no suenan, igual que un PDF borrado del setlist.
  static Future<void> eliminarSecuencia(
      String uid, String id, String? storagePath) async {
    if (storagePath != null && storagePath.isNotEmpty) {
      try {
        await supabase.storage
            .from(kSupabaseRepertorioBucket)
            .remove([storagePath]);
      } catch (e) {
        debugPrint('No se pudo borrar el audio de Storage: $e');
      }
    }
    await _refUsuario(uid).doc(id).delete();
  }

  /// Carga varias secuencias de la biblioteca a la sala de una sola vez, al
  /// final de la lista (ordenInicial = cantidad que ya había).
  static Future<void> agregarASala({
    required String codigoSala,
    required List<Map<String, dynamic>> secuencias,
    required String subidoPor,
    required int ordenInicial,
  }) async {
    final batch = FirebaseFirestore.instance.batch();
    for (var i = 0; i < secuencias.length; i++) {
      batch.set(_refSala(codigoSala).doc(), {
        'titulo': secuencias[i]['titulo'] as String? ?? '',
        'audioUrl': secuencias[i]['audioUrl'] as String? ?? '',
        'subidoPor': subidoPor,
        'orden': ordenInicial + i,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  static Future<void> quitarDeSala(String codigoSala, String id) async {
    await _refSala(codigoSala).doc(id).delete();
  }

  static Future<void> reordenarSala(
      String codigoSala, List<String> idsEnOrden) async {
    final batch = FirebaseFirestore.instance.batch();
    for (var i = 0; i < idsEnOrden.length; i++) {
      batch.update(_refSala(codigoSala).doc(idsEnOrden[i]), {'orden': i});
    }
    await batch.commit();
  }

  /// Tono (semitonos), tempo y volumen (porcentajes, 100 = como se subió) de
  /// una secuencia de la sala. Se guardan en el documento para que a todos
  /// les suene igual.
  static Future<void> actualizarAjustes(
    String codigoSala,
    String id, {
    required int semitonos,
    required int tempoPorcentaje,
    required int volumenPorcentaje,
    String? ajustadoPor,
  }) async {
    await _refSala(codigoSala).doc(id).update({
      'semitonos': semitonos,
      'tempoPorcentaje': tempoPorcentaje,
      'volumenPorcentaje': volumenPorcentaje,
      // Gana el último en escribir (D-06): se muestra quién fue.
      if (ajustadoPor != null && ajustadoPor.isNotEmpty)
        'ajustadoPor': ajustadoPor,
    });
  }
}

/// Versiones "no disponible" de lo que hay en puente_web.dart, para fuera
/// de la web: el import condicional `puente` apunta a este archivo cuando no
/// hay dart:js_interop. Se usan siempre con el prefijo `puente.`, nunca
/// directo.
const bool conversorMp3Disponible = false;

Future<({Uint8List bytes, int kbps})> convertirAMp3(
  Uint8List bytes,
  int limiteBytes,
  void Function(double progreso) alAvanzar,
) =>
    throw UnsupportedError(
        'La conversión a MP3 solo está disponible en la versión web.');

const bool reproductorWebDisponible = false;

Never _soloWeb() => throw UnsupportedError(
    'El reproductor con tono y tempo solo está disponible en la versión web.');
void rwDesbloquear() => _soloWeb();
Future<double> rwCargar(String url) => _soloWeb();
void rwReproducir() => _soloWeb();
void rwPausar() => _soloWeb();
void rwDetener() => _soloWeb();
void rwIrA(double segundos) => _soloWeb();
void rwTempo(double valor) => _soloWeb();
void rwSemitonos(int valor) => _soloWeb();
void rwRepetir(bool valor) => _soloWeb();
void rwVolumen(double valor) => _soloWeb();
void rwFadeOut(double segundos) => _soloWeb();
({double posicion, double duracion, bool sonando, bool termino}) rwEstado() =>
    _soloWeb();

/// Reproductor compartido por la pestaña Secuencias de la sala y por "Mis
/// secuencias": una sola pista a la vez (dar play a otra corta la anterior).
/// Cada dispositivo reproduce por su cuenta — no se sincroniza el play entre
/// los integrantes de la sala; quien maneja las secuencias en el show es el
/// que las dispara.
///
/// Tono y tempo independientes (como Music Speed Changer): en web se usa el
/// reproductor de web/reproductor_secuencias.js (reproduce mientras baja;
/// tempo del navegador, tono con SoundTouch), que es único para toda la
/// página; fuera de la web, audioplayers, que solo cambia el tempo
/// (soportaTono = false).
class ReproductorSecuencias extends ChangeNotifier {
  static bool get soportaTono => puente.reproductorWebDisponible;

  /// En web hay un solo reproductor JS para toda la página: el último que
  /// cargó una pista es el "dueño"; si otro toma el control, este queda
  /// detenido en vez de seguir creyendo que suena.
  static ReproductorSecuencias? _duenoWeb;

  final bool _web = puente.reproductorWebDisponible;
  AudioPlayer? _player;
  final List<StreamSubscription> _subs = [];
  Timer? _sondeo;

  // ---- Caché local de pistas (solo fuera de la web) ----
  // Las pistas de la sala se bajan al celular apenas aparecen en la lista:
  // suenan al instante al tocar play y siguen sonando si se corta la red.
  final Map<String, Future<void>> _descargas = {};
  final Set<String> _enCache = {};
  Directory? _dirCache;
  bool _cacheLimpia = false;

  /// Una pista más grande que esto no se guarda (el límite de subida es 50 MB).
  static const _maxBytesCache = 120 * 1024 * 1024;

  String? idActual;
  PlayerState estado = PlayerState.stopped;
  Duration posicion = Duration.zero;
  Duration duracion = Duration.zero;
  bool repetir = false;
  bool cargando = false;
  double tempo = 1.0;
  int semitonos = 0;

  /// 0 a 1.
  double volumen = 1.0;

  /// Mientras baja el volumen con "Fade" (después se detiene sola).
  bool enFadeOut = false;
  Timer? _fadeNativo;

  /// Duración del fade out para terminar una pista en vivo.
  static const duracionFadeOut = Duration(seconds: 4);

  ReproductorSecuencias() {
    if (_web) return;
    final player = AudioPlayer();
    _player = player;
    _subs.add(player.onPlayerStateChanged.listen((s) {
      estado = s;
      if (s == PlayerState.completed) posicion = Duration.zero;
      notifyListeners();
    }));
    _subs.add(player.onPositionChanged.listen((p) {
      posicion = p;
      notifyListeners();
    }));
    _subs.add(player.onDurationChanged.listen((d) {
      duracion = d;
      notifyListeners();
    }));
  }

  bool estaSonando(String id) =>
      idActual == id && estado == PlayerState.playing;

  /// ¿Esta pista ya está guardada en el celular (suena sin red)?
  bool estaEnCache(String url) => _enCache.contains(url);

  Future<Directory> _carpetaCache() async {
    final d =
        _dirCache ??= Directory('${Directory.systemTemp.path}/sc_secuencias');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  Future<File> _archivoDe(String url) async =>
      File('${(await _carpetaCache()).path}/${claveCache(url)}.audio');

  /// Ruta del archivo local de [url] si ya está completo (null en web o si falta).
  Future<String?> _rutaEnCache(String url) async {
    if (_web) return null;
    try {
      final f = await _archivoDe(url);
      if (await f.exists() && await f.length() > 0) return f.path;
    } catch (_) {}
    return null;
  }

  /// Baja las pistas de [urls] de a una (si todavía no están) para que suenen
  /// sin esperar la red. Es seguro llamarla muchas veces con la misma lista.
  Future<void> precargar(List<String> urls) async {
    if (_web) return;
    var bajo = false;
    for (final url in urls) {
      if (url.isEmpty) continue;
      final antes = _enCache.contains(url);
      await (_descargas[url] ??= _descargar(url));
      if (!antes && _enCache.contains(url)) bajo = true;
    }
    if (bajo || !_cacheLimpia) {
      _cacheLimpia = true;
      await _limpiarCache(urls.toSet());
    }
  }

  Future<void> _descargar(String url) async {
    File? parcial;
    try {
      final destino = await _archivoDe(url);
      if (await destino.exists() && await destino.length() > 0) {
        if (_enCache.add(url)) notifyListeners();
        return;
      }
      parcial = File('${destino.path}.part');
      final cliente = http.Client();
      try {
        final respuesta =
            await cliente.send(http.Request('GET', Uri.parse(url)));
        final largo = respuesta.contentLength;
        if (respuesta.statusCode != 200 ||
            (largo != null && largo > _maxBytesCache)) {
          return;
        }
        await respuesta.stream.pipe(parcial.openWrite());
        await parcial.rename(destino.path);
        parcial = null;
        _enCache.add(url);
        notifyListeners();
      } finally {
        cliente.close();
      }
    } catch (e) {
      debugPrint('No se pudo guardar la pista en el celular: $e');
    } finally {
      _descargas.remove(url);
      try {
        if (parcial != null && await parcial.exists()) await parcial.delete();
      } catch (_) {}
    }
  }

  Future<void> _limpiarCache(Set<String> urlsActuales) async {
    try {
      final dir = await _carpetaCache();
      final existentes = <({String nombre, DateTime fecha})>[];
      await for (final e in dir.list()) {
        if (e is File) {
          existentes.add(
              (nombre: e.uri.pathSegments.last, fecha: await e.lastModified()));
        }
      }
      final conservar =
          urlsActuales.map((u) => '${claveCache(u)}.audio').toSet();
      for (final nombre in archivosParaBorrar(existentes, conservar)) {
        try {
          await File('${dir.path}/$nombre').delete();
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('No se pudo limpiar la caché de pistas: $e');
    }
  }

  /// En web la posición se consulta al reproductor JS mientras suena.
  void _empezarSondeo() {
    _sondeo?.cancel();
    _sondeo = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (_duenoWeb != this) {
        _sondeo?.cancel();
        estado = PlayerState.stopped;
        posicion = Duration.zero;
        notifyListeners();
        return;
      }
      final e = puente.rwEstado();
      posicion = Duration(milliseconds: (e.posicion * 1000).round());
      if (e.termino) {
        _sondeo?.cancel();
        estado = PlayerState.completed;
        posicion = Duration.zero;
        enFadeOut = false;
      }
      notifyListeners();
    });
  }

  /// Corta un fade out en curso fuera de la web (en web lo cancela el propio
  /// reproductor JS al dar play/pausa) y deja el volumen como estaba.
  void _cancelarFadeNativo() {
    _fadeNativo?.cancel();
    _fadeNativo = null;
    if (!_web && enFadeOut) _player!.setVolume(volumen);
    enFadeOut = false;
  }

  /// Play/pausa sobre la pista [id]. Si es otra distinta a la actual, corta
  /// la anterior y arranca la nueva desde el principio, con [tempo] (1 =
  /// normal), [semitonos] y [volumen] (0 a 1).
  Future<void> alternar(
    String id,
    String url, {
    double tempo = 1.0,
    int semitonos = 0,
    double volumen = 1.0,
  }) async {
    // Antes de cualquier await: los navegadores de celular solo dejan
    // arrancar audio dentro del toque del usuario.
    if (_web) puente.rwDesbloquear();
    _cancelarFadeNativo();
    enFadeOut = false;
    if (idActual == id && (!_web || _duenoWeb == this)) {
      if (estado == PlayerState.playing) {
        if (_web) {
          puente.rwPausar();
          _sondeo?.cancel();
          estado = PlayerState.paused;
          notifyListeners();
        } else {
          await _player!.pause();
        }
      } else {
        if (_web) {
          puente.rwReproducir();
          estado = PlayerState.playing;
          _empezarSondeo();
          notifyListeners();
        } else {
          await _player!.resume();
        }
      }
      return;
    }
    idActual = id;
    posicion = Duration.zero;
    duracion = Duration.zero;
    this.tempo = tempo;
    this.semitonos = semitonos;
    this.volumen = volumen;
    cargando = true;
    notifyListeners();
    try {
      if (_web) {
        _duenoWeb = this;
        _sondeo?.cancel();
        // Ajustes antes de cargar: rwCargar ya arranca a sonar apenas hay
        // datos (sin esperar a bajar la pista entera).
        puente.rwTempo(this.tempo);
        puente.rwSemitonos(this.semitonos);
        puente.rwVolumen(this.volumen);
        puente.rwRepetir(repetir);
        final segundos = await puente.rwCargar(url);
        // Se pidió otra pista (o la tomó otra pantalla) mientras cargaba.
        if (segundos < 0 || idActual != id || _duenoWeb != this) return;
        duracion = Duration(milliseconds: (segundos * 1000).round());
        estado = PlayerState.playing;
        _empezarSondeo();
      } else {
        await _player!.stop();
        await _player!
            .setReleaseMode(repetir ? ReleaseMode.loop : ReleaseMode.stop);
        await _player!.setVolume(this.volumen);
        // Si la pista ya está en el celular suena de ahí (al instante y sin red).
        final local = await _rutaEnCache(url);
        await _player!
            .play(local != null ? DeviceFileSource(local) : UrlSource(url));
        await _player!.setPlaybackRate(this.tempo);
      }
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  /// Aplica tono, tempo y volumen a la pista [id] si es la que está cargada
  /// (si no, se toman la próxima vez que se le dé play). Se llama al mover
  /// los controles y cuando llega el cambio de otro integrante de la sala.
  Future<void> aplicarAjustes(
    String id, {
    required double tempo,
    required int semitonos,
    required double volumen,
  }) async {
    if (idActual != id) return;
    if (this.tempo == tempo &&
        this.semitonos == semitonos &&
        this.volumen == volumen) {
      return;
    }
    final cambioTempo = this.tempo != tempo;
    final cambioTono = this.semitonos != semitonos;
    final cambioVolumen = this.volumen != volumen;
    this.tempo = tempo;
    this.semitonos = semitonos;
    this.volumen = volumen;
    // Cada ajuste se aplica solo si cambió: mover el tono no toca el tempo
    // ni el volumen, y viceversa.
    if (_web) {
      if (_duenoWeb == this) {
        if (cambioTempo) puente.rwTempo(tempo);
        if (cambioTono) puente.rwSemitonos(semitonos);
        if (cambioVolumen) puente.rwVolumen(volumen);
      }
    } else {
      if (cambioTempo) await _player!.setPlaybackRate(tempo);
      if (cambioVolumen && !enFadeOut) await _player!.setVolume(volumen);
    }
    notifyListeners();
  }

  /// Baja el volumen hasta silencio en [duracionFadeOut] y frena, para
  /// terminar una pista en vivo sin cortarla en seco.
  Future<void> fadeOut() async {
    if (estado != PlayerState.playing || enFadeOut) return;
    enFadeOut = true;
    notifyListeners();
    if (_web) {
      if (_duenoWeb == this) {
        puente.rwFadeOut(duracionFadeOut.inMilliseconds / 1000);
      }
      return;
    }
    const pasos = 40;
    var paso = 0;
    _fadeNativo = Timer.periodic(duracionFadeOut ~/ pasos, (t) async {
      paso++;
      await _player!.setVolume(volumen * (1 - paso / pasos));
      if (paso >= pasos) {
        t.cancel();
        _fadeNativo = null;
        await _player!.stop();
        await _player!.setVolume(volumen);
        enFadeOut = false;
        posicion = Duration.zero;
        notifyListeners();
      }
    });
  }

  Future<void> detener() async {
    _cancelarFadeNativo();
    if (_web) {
      if (_duenoWeb == this) puente.rwDetener();
      _sondeo?.cancel();
      estado = PlayerState.stopped;
    } else {
      await _player!.stop();
    }
    posicion = Duration.zero;
    notifyListeners();
  }

  Future<void> irA(Duration destino) async {
    if (_web) {
      if (_duenoWeb == this) puente.rwIrA(destino.inMilliseconds / 1000);
      posicion = destino;
      notifyListeners();
    } else {
      await _player!.seek(destino);
    }
  }

  Future<void> alternarRepetir() async {
    repetir = !repetir;
    if (_web) {
      if (_duenoWeb == this) puente.rwRepetir(repetir);
    } else {
      await _player!
          .setReleaseMode(repetir ? ReleaseMode.loop : ReleaseMode.stop);
    }
    notifyListeners();
  }

  static String formatear(Duration d) {
    final minutos = d.inMinutes;
    final segundos = d.inSeconds % 60;
    return '$minutos:${segundos.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _sondeo?.cancel();
    _fadeNativo?.cancel();
    if (_web && _duenoWeb == this) {
      puente.rwDetener();
      _duenoWeb = null;
    }
    for (final s in _subs) {
      s.cancel();
    }
    _player?.dispose();
    super.dispose();
  }
}

/// Fila de una secuencia con play/pausa y, si es la que está sonando, barra
/// de progreso con tiempo. La usan la pestaña de la sala y "Mis secuencias".
class FilaSecuencia extends StatelessWidget {
  final ReproductorSecuencias reproductor;
  final String id;
  final String titulo;
  final String audioUrl;
  final String? subtitulo;
  final Widget? acciones;

  /// Con qué tempo (1 = normal), tono y volumen (0 a 1) arranca la pista al
  /// darle play.
  final double tempo;
  final int semitonos;
  final double volumen;

  const FilaSecuencia({
    super.key,
    required this.reproductor,
    required this.id,
    required this.titulo,
    required this.audioUrl,
    this.subtitulo,
    this.acciones,
    this.tempo = 1.0,
    this.semitonos = 0,
    this.volumen = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: reproductor,
      builder: (context, _) {
        final esActual = reproductor.idActual == id;
        final sonando = reproductor.estaSonando(id);
        final maxMs = reproductor.duracion.inMilliseconds.toDouble();
        final posMs = reproductor.posicion.inMilliseconds
            .toDouble()
            .clamp(0.0, maxMs > 0 ? maxMs : 0.0);
        return Container(
          color: esActual ? context.acento.withOpacity(0.08) : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: IconButton.filledTonal(
                  iconSize: 32,
                  icon: (esActual && reproductor.cargando)
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(sonando ? Icons.pause : Icons.play_arrow),
                  tooltip:
                      sonando ? context.l10n.pausar : context.l10n.reproducir,
                  onPressed: audioUrl.isEmpty
                      ? null
                      : () => reproductor
                              .alternar(id, audioUrl,
                                  tempo: tempo,
                                  semitonos: semitonos,
                                  volumen: volumen)
                              .catchError((e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        context.l10n.noSePudoReproducir(e)),
                                    backgroundColor: Colors.redAccent),
                              );
                            }
                          }),
                ),
                title: Text(titulo,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: subtitulo == null
                    ? null
                    : Text(subtitulo!, style: const TextStyle(fontSize: 12)),
                trailing: acciones,
              ),
              if (esActual &&
                  maxMs > 0 &&
                  reproductor.estado != PlayerState.stopped &&
                  reproductor.estado != PlayerState.completed)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Text(
                          ReproductorSecuencias.formatear(reproductor.posicion),
                          style: const TextStyle(fontSize: 12)),
                      Expanded(
                        child: Slider(
                          value: posMs,
                          max: maxMs,
                          onChanged: (v) => reproductor
                              .irA(Duration(milliseconds: v.round())),
                        ),
                      ),
                      Text(
                          ReproductorSecuencias.formatear(reproductor.duracion),
                          style: const TextStyle(fontSize: 12)),
                      IconButton(
                        icon: Icon(Icons.trending_down,
                            color:
                                reproductor.enFadeOut ? context.acento : null),
                        tooltip: reproductor.enFadeOut
                            ? context.l10n.bajandoElVolumen
                            : context.l10n.fadeOutS(ReproductorSecuencias
                                .duracionFadeOut.inSeconds),
                        onPressed: sonando && !reproductor.enFadeOut
                            ? reproductor.fadeOut
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.stop),
                        tooltip: context.l10n.detener,
                        onPressed: reproductor.detener,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// --- SERVICIO DE BASE DE DATOS ---

class FirestoreService {
  static CollectionReference<Map<String, dynamic>> _pedidosRef(String codigo) {
    return FirebaseFirestore.instance
        .collection('salas')
        .doc(codigo)
        .collection('pedidos');
  }

  static Future<void> enviarPedido({
    required String codigo,
    required String nombre,
    required String rol,
    required String pedido,
    bool urgente = false,
  }) async {
    await _pedidosRef(codigo).add({
      'sala_id': codigo, // Ajustado para coincidir con tu índice de Firebase

      'nombre': nombre,

      'rol': rol,

      'pedido': pedido,

      'atendido': false,

      'urgente': urgente,

      'respuesta': '', // Campo nuevo inicializado vacío

      'createdAt':
          FieldValue.serverTimestamp(), // Cambiado 'creadoEn' por 'createdAt'
    });
  }

  static Future<void> responderPedido(
      String codigoSala, String pedidoId, String textoRespuesta) async {
    try {
      await _pedidosRef(codigoSala).doc(pedidoId).update({
        'respuesta': textoRespuesta,
      });
    } catch (e) {
      debugPrint("Error al responder pedido: $e");
    }
  }

  static Future<void> eliminarPedidoIndividual(
      String codigoSala, String pedidoId) async {
    try {
      await _pedidosRef(codigoSala).doc(pedidoId).delete();
    } catch (e) {
      debugPrint("Error al eliminar pedido: $e");
    }
  }

  static Future<void> borrarTodo(String codigo) async {
    final snapshots = await _pedidosRef(codigo).get();

    final batch = FirebaseFirestore.instance.batch();

    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}

// --- APLICACIÓN PRINCIPAL ---

class SoundCheckProApp extends StatefulWidget {
  const SoundCheckProApp({super.key});

  @override
  State<SoundCheckProApp> createState() => _SoundCheckProAppState();

  static _SoundCheckProAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_SoundCheckProAppState>()!;
}

class _SoundCheckProAppState extends State<SoundCheckProApp> {
  /// Oscuro por defecto (la paleta por defecto, Escenario, es oscura). El
  /// modo elegido se guarda en 'modo_oscuro' y NO cambia al cambiar de
  /// paleta: solo cambia si el usuario toca el botón claro/oscuro.
  ThemeMode _themeMode = ThemeMode.dark;

  AppPalette _paleta = AppPalette.porDefecto;

  /// Idioma elegido a mano. null = automático: el del dispositivo (ver
  /// IdiomasApp.resolver). Se guarda en 'idioma_app'.
  Locale? _idioma;

  @override
  void initState() {
    super.initState();

    _cargarPaletaGuardada();

    _cargarIdiomaGuardado();
  }

  Future<void> _cargarIdiomaGuardado() async {
    final prefs = await SharedPreferences.getInstance();
    final codigo = prefs.getString('idioma_app');
    final elegido = IdiomasApp.todos
        .where((i) => i.$1.languageCode == codigo)
        .map((i) => i.$1)
        .firstOrNull;
    if (elegido != null && mounted) setState(() => _idioma = elegido);
  }

  /// Cambia el idioma de toda la app al instante. null = automático.
  Future<void> setIdioma(Locale? idioma) async {
    setState(() => _idioma = idioma);
    final prefs = await SharedPreferences.getInstance();
    if (idioma == null) {
      await prefs.remove('idioma_app');
    } else {
      await prefs.setString('idioma_app', idioma.languageCode);
    }
  }

  /// null si el idioma es automático.
  Locale? get idiomaElegido => _idioma;

  Future<void> _cargarPaletaGuardada() async {
    final prefs = await SharedPreferences.getInstance();

    final clave = prefs.getString('paleta_app');

    final oscuro = prefs.getBool('modo_oscuro');

    if (mounted) {
      setState(() {
        if (clave != null) _paleta = AppPalette.porClave(clave);

        if (oscuro != null) {
          _themeMode = oscuro ? ThemeMode.dark : ThemeMode.light;
        }
      });
    }
  }

  Future<void> toggleTheme() async {
    final nuevo =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;

    setState(() => _themeMode = nuevo);

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('modo_oscuro', nuevo == ThemeMode.dark);
  }

  Future<void> setPaleta(AppPalette paleta) async {
    setState(() => _paleta = paleta);

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('paleta_app', paleta.key);
  }

  AppPalette get paletaActual => _paleta;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'Sound Check Pro',

      theme: construirTema(_paleta, Brightness.light),

      darkTheme: construirTema(_paleta, Brightness.dark),

      themeMode: _themeMode,

      // Idiomas: los textos salen de lib/l10n/*.arb. Con _idioma == null se
      // sigue el del dispositivo y, si no es uno de los de la app, inglés.
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: _idioma,
      localeListResolutionCallback: IdiomasApp.resolver,
      onGenerateTitle: (context) => context.l10n.nombreApp,
      builder: (context, child) {
        L10n.t = AppLocalizations.of(context);
        return child ?? const SizedBox.shrink();
      },

      home: const SplashScreen(),
    );
  }
}

// --- PANTALLA DE CARGA Y REDIRECCIÓN INICIAL ---

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    _evaluarRutaInicial();
  }

  Future<void> _evaluarRutaInicial() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final tipoLogin = prefs.getString('tipo_login');

      final salaId = prefs.getString('sala_id');

      if (!mounted) return;

      if (salaId != null && tipoLogin != null && salaId.isNotEmpty) {
        await AuthService.asegurarSesion();

        if (!mounted) return;

        if (tipoLogin == 'sonidista') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => SonidistaPage(codigoSala: salaId)),
          );

          return;
        } else {
          final nombre = prefs.getString('nombre') ?? 'Músico';

          final rolStr = prefs.getString('rol') ?? 'Músico';

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => RequestScreen(
                userName: nombre,
                rol: rolStr,
                codigoSala: salaId,
              ),
            ),
          );

          return;
        }
      }
    } catch (e) {
      debugPrint("Error leyendo sesión guardada: $e");
    }

    final destino = AuthService.esUsuarioRegistrado
        ? const IngressMenuScreen()
        : const BienvenidaScreen();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destino),
    );
    // Enlace del tipo .../?sala=ABCD2345: lleva directo a "Unirme a sala" con el código cargado.
    final codigoEnlace = codigoDeSalaDesdeUri(Uri.base);
    if (codigoEnlace != null && mounted) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => UnirmeSalaScreen(codigoInicial: codigoEnlace)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: context.acento),
      ),
    );
  }
}

// --- PANTALLA DE PRESENTACIÓN (BIENVENIDA) ---

/// Primera pantalla para quien no tiene sesión: logo, tres accesos y las
/// funciones principales. Siempre oscura, con colores propios (no sigue la
/// paleta elegida ni el modo claro/oscuro: es la identidad de la marca).
///
/// El fondo es la foto assets/images/fondo_bienvenida.jpg (micrófono,
/// consola, guitarra; sin textos ni botones). Si el archivo no está, se
/// dibuja un fondo oscuro con luces de escenario.
class BienvenidaScreen extends StatelessWidget {
  const BienvenidaScreen({super.key});

  static const _celeste = Color(0xFF22D3EE);
  static const _violeta = Color(0xFFA855F7);
  static const _fondo = Color(0xFF07060F);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _fondo,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/fondo_bienvenida.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) => const _FondoEscenario(),
            ),
            // Oscurece apenas arriba y abajo (el centro de la foto ya es
            // oscuro y liso) para que se lean los textos y la tarjeta.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x33000000),
                    Color(0x00000000),
                    Color(0x00000000),
                    Color(0x99000000)
                  ],
                  stops: [0, 0.25, 0.7, 1],
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.wb_sunny_outlined,
                                        color: Colors.white),
                                    tooltip: context.l10n.modoClaroOscuroParaEl,
                                    onPressed: () =>
                                        SoundCheckProApp.of(context)
                                            .toggleTheme(),
                                  ),
                                  const MenuHamburguesa(
                                      colorIcono: Colors.white),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const _LogoOnda(),
                              const SizedBox(height: 20),
                              const Text(
                                'SOUND',
                                style: TextStyle(
                                  fontSize: 44,
                                  height: 1.0,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                  shadows: [
                                    Shadow(
                                        color: Color(0x8022D3EE),
                                        blurRadius: 18)
                                  ],
                                ),
                              ),
                              const Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                        text: 'CHECK ',
                                        style: TextStyle(color: Colors.white)),
                                    TextSpan(
                                        text: 'PRO',
                                        style: TextStyle(color: _celeste)),
                                  ],
                                ),
                                style: TextStyle(
                                  fontSize: 44,
                                  height: 1.05,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                  shadows: [
                                    Shadow(
                                        color: Color(0x8022D3EE),
                                        blurRadius: 18)
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                context.l10n.comunicacionEnVivoEntreMusicos,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 17,
                                    height: 1.35,
                                    color: Colors.white),
                              ),
                              const SizedBox(height: 32),
                              _BotonBienvenida(
                                texto: context.l10n.iniciarSesion,
                                icono: Icons.monitor_heart_outlined,
                                estilo: _EstiloBoton.principal,
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const AuthScreen()),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _BotonBienvenida(
                                texto: context.l10n.crearCuenta,
                                icono: Icons.person_outline,
                                estilo: _EstiloBoton.celeste,
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const AuthScreen(
                                          modoRegistroInicial: true)),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _BotonBienvenida(
                                texto: context.l10n.entrarComoInvitado,
                                icono: Icons.groups_outlined,
                                estilo: _EstiloBoton.violeta,
                                onPressed: () => Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const IngressMenuScreen()),
                                  (route) => false,
                                ),
                              ),
                              const SizedBox(height: 26),
                              const _FuncionesDestacadas(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fondo de respaldo: oscuro con luces de escenario violeta y celeste.
class _FondoEscenario extends StatelessWidget {
  const _FondoEscenario();

  @override
  Widget build(BuildContext context) {
    Widget luz(Alignment alineacion, Color color, double radio) => Align(
          alignment: alineacion,
          child: Container(
            width: radio * 2,
            height: radio * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                  colors: [color.withOpacity(0.55), color.withOpacity(0)]),
            ),
          ),
        );
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF14102B), Color(0xFF0A0818), Color(0xFF05040C)],
            ),
          ),
        ),
        luz(const Alignment(-0.9, -0.95), BienvenidaScreen._violeta, 150),
        luz(const Alignment(-0.45, -0.8), BienvenidaScreen._celeste, 110),
        luz(const Alignment(0.55, -0.9), BienvenidaScreen._celeste, 130),
        luz(const Alignment(1.0, -0.55), BienvenidaScreen._violeta, 120),
        luz(const Alignment(-1.0, 0.25), BienvenidaScreen._celeste, 140),
        luz(const Alignment(1.0, 0.35), BienvenidaScreen._violeta, 150),
      ],
    );
  }
}

/// Logo: barras verticales de onda de sonido con degradé celeste → violeta.
class _LogoOnda extends StatelessWidget {
  const _LogoOnda();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 190,
      height: 120,
      child: CustomPaint(painter: _PintorOnda()),
    );
  }
}

class _PintorOnda extends CustomPainter {
  const _PintorOnda();

  // Alto de cada barra (0 a 1), de izquierda a derecha, como en el diseño.
  static const _alturas = [0.28, 0.55, 0.78, 1.0, 0.78, 0.55, 0.28];

  @override
  void paint(Canvas canvas, Size size) {
    final ancho = size.width / (_alturas.length * 2 - 1);
    final degrade = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        BienvenidaScreen._celeste,
        Color(0xFF6366F1),
        BienvenidaScreen._violeta
      ],
    ).createShader(Offset.zero & size);
    final pincel = Paint()..shader = degrade;
    final brillo = Paint()
      ..shader = degrade
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    for (var i = 0; i < _alturas.length; i++) {
      final alto = size.height * _alturas[i];
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(i * ancho * 2, (size.height - alto) / 2, ancho, alto),
        Radius.circular(ancho / 2),
      );
      canvas.drawRRect(rect, brillo);
      canvas.drawRRect(rect, pincel);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum _EstiloBoton { principal, celeste, violeta }

class _BotonBienvenida extends StatelessWidget {
  final String texto;
  final IconData icono;
  final _EstiloBoton estilo;
  final VoidCallback onPressed;

  const _BotonBienvenida({
    required this.texto,
    required this.icono,
    required this.estilo,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final principal = estilo == _EstiloBoton.principal;
    final color = estilo == _EstiloBoton.violeta
        ? BienvenidaScreen._violeta
        : BienvenidaScreen._celeste;
    return Semantics(
      button: true,
      label: texto,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Ink(
            height: 62,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: principal ? null : const Color(0xCC07060F),
              gradient: principal
                  ? const LinearGradient(
                      colors: [Color(0xFF22D3EE), Color(0xFF06B6D4)])
                  : null,
              border: Border.all(
                  color: principal
                      ? const Color(0xFFA5F3FC)
                      : color.withOpacity(0.7),
                  width: 1.3),
              boxShadow: [
                BoxShadow(
                    color: color.withOpacity(principal ? 0.55 : 0.25),
                    blurRadius: principal ? 22 : 14)
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: principal ? null : const Color(0x33FFFFFF),
                    border: principal
                        ? Border.all(color: Colors.white, width: 1.5)
                        : null,
                  ),
                  child: Icon(icono,
                      color: principal ? Colors.white : color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    texto,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta con las cuatro funciones principales de la app.
class _FuncionesDestacadas extends StatelessWidget {
  const _FuncionesDestacadas();

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        Icons.bolt,
        BienvenidaScreen._celeste,
        context.l10n.tiempoReal,
        context.l10n.sincronizacionInstantanea
      ),
      (
        Icons.notifications_none,
        BienvenidaScreen._violeta,
        context.l10n.urgente,
        context.l10n.alertasVisualesYSonoras
      ),
      (
        Icons.groups_outlined,
        BienvenidaScreen._celeste,
        context.l10n.multiSala,
        context.l10n.manejaVariasBandasYShows
      ),
      (
        Icons.music_note_outlined,
        BienvenidaScreen._violeta,
        context.l10n.setlistEnVivo,
        context.l10n.listaDeTemasCompartida
      ),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xB307060F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x3322D3EE)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                VerticalDivider(
                    color: Colors.white.withOpacity(0.12),
                    width: 1,
                    thickness: 1),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    children: [
                      Icon(items[i].$1, color: items[i].$2, size: 34),
                      const SizedBox(height: 8),
                      Text(
                        items[i].$3,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      // Se achica si no entra, en vez de partir una palabra
                      // ("Sincronizació/n") en pantallas angostas.
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          items[i].$4,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 12,
                              height: 1.3,
                              color: Color(0xCCFFFFFF)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// --- PANTALLA DE LOGIN / REGISTRO ---

class AuthScreen extends StatefulWidget {
  /// Abre el formulario ya en modo "Crear cuenta" (botón de la pantalla de
  /// presentación).
  final bool modoRegistroInicial;

  const AuthScreen({super.key, this.modoRegistroInicial = false});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  @override
  void initState() {
    super.initState();
    _modoRegistro = widget.modoRegistroInicial;
  }

  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();

  final _rolController = TextEditingController();

  final _emailController = TextEditingController();

  final _passwordController = TextEditingController();

  bool _modoRegistro = false;

  bool _procesando = false;

  Future<void> _irAIngreso() async {
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const IngressMenuScreen()),
      (route) => false,
    );
  }

  void _mostrarError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(AuthService.mensajeError(error)),
          backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _enviarFormulario() async {
    if (_procesando) return;

    if (_modoRegistro && !(_formKey.currentState?.validate() ?? false)) return;

    if (!_modoRegistro &&
        (_emailController.text.trim().isEmpty ||
            _passwordController.text.isEmpty)) {
      _mostrarError(Exception(context.l10n.completaEmailYContrasena));

      return;
    }

    setState(() => _procesando = true);

    try {
      if (_modoRegistro) {
        final credential = await AuthService.registerWithEmail(
          _emailController.text,
          _passwordController.text,
        );

        final uid = credential.user?.uid;

        if (uid != null) {
          await UsuarioService.guardarPerfil(
            uid: uid,
            nombre: _nombreController.text.trim(),
            rol: _rolController.text.trim(),
            email: credential.user?.email,
          );

          await FrasesService.copiarFrasesBaseParaUsuario(uid);
        }
      } else {
        await AuthService.signInWithEmail(
            _emailController.text, _passwordController.text);
      }

      await _irAIngreso();
    } catch (e) {
      if (mounted) _mostrarError(e);
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _continuarConGoogle() async {
    if (_procesando) return;

    setState(() => _procesando = true);

    try {
      final credential = await AuthService.signInWithGoogle();

      final user = credential.user;

      if (user != null) {
        final perfil = await UsuarioService.obtenerPerfil(user.uid);

        if (perfil == null && mounted) {
          await _completarPerfilGoogle(user);
        }
      }

      await _irAIngreso();
    } catch (e) {
      if (mounted) _mostrarError(e);
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _completarPerfilGoogle(User user) async {
    final nombreController =
        TextEditingController(text: user.displayName ?? '');

    final rolController = TextEditingController();

    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.completaTuPerfil),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nombreController,
                decoration: InputDecoration(labelText: context.l10n.tuNombre),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? context.l10n.requerido
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: rolController,
                decoration: InputDecoration(
                    labelText: context.l10n.tuRolEjSonidistaGuitarrista),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? context.l10n.requerido
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) return;

              await UsuarioService.guardarPerfil(
                uid: user.uid,
                nombre: nombreController.text.trim(),
                rol: rolController.text.trim(),
                email: user.email,
              );

              await FrasesService.copiarFrasesBaseParaUsuario(user.uid);

              if (context.mounted) Navigator.pop(context);
            },
            child: Text(context.l10n.guardar),
          ),
        ],
      ),
    );
  }

  Future<void> _olvideMiContrasena() async {
    final controller = TextEditingController(text: _emailController.text);

    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.recuperarContrasena),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
              labelText: context.l10n.tuEmail,
              border: const OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.cancelar)),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(context.l10n.enviarEmail),
          ),
        ],
      ),
    );

    if (email == null || email.isEmpty) return;

    try {
      await AuthService.sendPasswordResetEmail(email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.teEnviamosUnEmailPara)),
      );
    } catch (e) {
      _mostrarError(e);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();

    _rolController.dispose();

    _emailController.dispose();

    _passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sound Check Pro')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.settings_input_component,
                    size: 64, color: context.acento),
                const SizedBox(height: 16),
                Text(
                  _modoRegistro
                      ? context.l10n.crearCuenta
                      : context.l10n.iniciarSesion,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                if (_modoRegistro) ...[
                  TextFormField(
                    controller: _nombreController,
                    decoration: InputDecoration(
                        labelText: context.l10n.tuNombre,
                        border: const OutlineInputBorder()),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? context.l10n.requerido
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _rolController,
                    decoration: InputDecoration(
                      labelText: context.l10n.tuRolEjSonidistaGuitarrista2,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? context.l10n.requerido
                        : null,
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                      labelText: context.l10n.email,
                      border: const OutlineInputBorder()),
                  validator: (v) => (v == null || !v.contains('@'))
                      ? context.l10n.emailInvalido
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                      labelText: context.l10n.contrasena,
                      border: const OutlineInputBorder()),
                  validator: (v) => (v == null || v.length < 6)
                      ? context.l10n.minimo6Caracteres
                      : null,
                ),
                if (!_modoRegistro)
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: _procesando ? null : _olvideMiContrasena,
                      child: Text(context.l10n.olvidasteTuContrasena),
                    ),
                  ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _procesando ? null : _enviarFormulario,
                  style:
                      FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
                  child: _procesando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(_modoRegistro
                          ? context.l10n.registrarme
                          : context.l10n.iniciarSesion2),
                ),
                TextButton(
                  onPressed: _procesando
                      ? null
                      : () => setState(() => _modoRegistro = !_modoRegistro),
                  child: Text(_modoRegistro
                      ? context.l10n.yaTenesCuentaIniciarSesion
                      : context.l10n.noTenesCuentaRegistrarme),
                ),
                const SizedBox(height: 8),
                const Row(children: [
                  Expanded(child: Divider()),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('O')),
                  Expanded(child: Divider())
                ]),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _procesando ? null : _continuarConGoogle,
                  icon: const Icon(Icons.g_mobiledata, size: 28),
                  label: Text(context.l10n.continuarConGoogle),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16)),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: _procesando ? null : _irAIngreso,
                  child: Text(context.l10n.continuarSinCuenta,
                      style: const TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- MENÚ DE INGRESO ---

class IngressMenuScreen extends StatelessWidget {
  const IngressMenuScreen({super.key});

  Future<void> _cerrarSesionCuenta(BuildContext context) async {
    await AuthService.signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const BienvenidaScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    final user = AuthService.currentUser;

    final registrado = AuthService.esUsuarioRegistrado;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(isLight ? Icons.wb_sunny : Icons.nightlight_round),
          tooltip: context.l10n.modoClaroOscuroParaEl,
          onPressed: () => SoundCheckProApp.of(context).toggleTheme(),
        ),
        actions: [
          if (!registrado)
            IconButton(
              icon: const Icon(Icons.login),
              tooltip: context.l10n.iniciarSesion,
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AuthScreen())),
            ),
          MenuHamburguesa(
            conCuenta: registrado,
            alSalir: () => _cerrarSesionCuenta(context),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(minHeight: constraints.maxHeight - 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.settings_input_component,
                      size: 80, color: context.acento),
                  const SizedBox(height: 24),
                  const Text(
                    'SOUND CHECK PRO',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2),
                  ),
                  if (registrado) ...[
                    const SizedBox(height: 8),
                    Text(
                      context.l10n
                          .sesion(user!.email ?? user.displayName ?? user.uid),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                  const SizedBox(height: 48),
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(context.l10n.crearNuevaSala),
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CrearSalaScreen())),
                    style: FilledButton.styleFrom(
                        padding: const EdgeInsets.all(16)),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.login),
                    label: Text(context.l10n.unirmeASala),
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const UnirmeSalaScreen())),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16)),
                  ),
                  const SizedBox(height: 12),
                  if (registrado) ...[
                    OutlinedButton.icon(
                      icon: const Icon(Icons.history),
                      label: Text(context.l10n.misSalas),
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MisSalasScreen())),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16)),
                    ),
                  ],
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.tune),
                    label: Text(context.l10n.accesoSonidista),
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SonidistaPinScreen())),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- SELECTOR DE IDENTIDAD DE COLOR ---

/// Menú hamburguesa de la barra superior. Con cuenta registrada: Mis frases,
/// Mi repertorio, Mis secuencias, Configuración y Cerrar sesión (en ese
/// orden). Sin cuenta: solo Configuración.
class MenuHamburguesa extends StatelessWidget {
  final Color? colorIcono;
  final bool conCuenta;
  final VoidCallback? alSalir;

  const MenuHamburguesa(
      {super.key, this.colorIcono, this.conCuenta = false, this.alSalir});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.menu, color: colorIcono),
      onSelected: (valor) {
        Widget? pantalla = switch (valor) {
          'frases' => const FrasesAdminScreen(),
          'repertorio' => const MiRepertorioScreen(),
          'secuencias' => const MisSecuenciasScreen(),
          'colores' => const PaletaPickerScreen(),
          'idioma' => const IdiomaPickerScreen(),
          _ => null,
        };
        if (pantalla != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));
        } else if (valor == 'salir') {
          alSalir?.call();
        }
      },
      itemBuilder: (context) => [
        if (conCuenta) ...[
          PopupMenuItem(value: 'frases', child: Text(context.l10n.misFrases2)),
          PopupMenuItem(
              value: 'repertorio', child: Text(context.l10n.miRepertorio2)),
          PopupMenuItem(
              value: 'secuencias', child: Text(context.l10n.misSecuencias2)),
        ],
        const _ItemConfiguracion(),
        if (conCuenta)
          PopupMenuItem(value: 'salir', child: Text(context.l10n.cerrarSesion)),
      ],
    );
  }
}

/// "Configuración" dentro del menú hamburguesa: al tocarla se despliegan
/// debajo "Colores" e "Idioma" (con animación y una flecha que indica si
/// está abierta). Al elegir una, el menú se cierra devolviendo 'colores' o
/// 'idioma' (lo resuelve MenuHamburguesa.onSelected).
class _ItemConfiguracion extends PopupMenuEntry<String> {
  const _ItemConfiguracion();

  @override
  double get height => kMinInteractiveDimension;

  @override
  bool represents(String? value) => false;

  @override
  State<_ItemConfiguracion> createState() => _ItemConfiguracionState();
}

class _ItemConfiguracionState extends State<_ItemConfiguracion> {
  bool _abierto = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final color = Theme.of(context).colorScheme.primary;
    Widget opcion(String valor, String texto) => InkWell(
          onTap: () => Navigator.pop(context, valor),
          child: Container(
            height: kMinInteractiveDimension,
            alignment: AlignmentDirectional.centerStart,
            padding: const EdgeInsetsDirectional.only(start: 28, end: 12),
            decoration: BoxDecoration(
              border: BorderDirectional(
                  start: BorderSide(
                      color: color.withValues(alpha: 0.5), width: 2)),
            ),
            child: Text(texto),
          ),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _abierto = !_abierto),
          child: Container(
            height: kMinInteractiveDimension,
            padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
            child: Row(
              children: [
                Expanded(child: Text(l.configuracion)),
                AnimatedRotation(
                  turns: _abierto ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down, color: color),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _abierto
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    opcion('colores', l.colores),
                    opcion('idioma', l.idioma),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                          start: 28, top: 8, bottom: 8, end: 12),
                      child: Text(
                        l.versionApp(kVersionApp),
                        style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class PaletaPickerScreen extends StatelessWidget {
  const PaletaPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final actual = SoundCheckProApp.of(context).paletaActual;

    final esOscuro = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.colorDeLaApp)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            context.l10n.elegiLaIdentidadVisualDe,
            style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          for (final paleta in AppPalette.todas) ...[
            _PaletaCard(
              paleta: paleta,
              seleccionada: paleta.key == actual.key,
              oscuro: esOscuro,
              onTap: () => SoundCheckProApp.of(context).setPaleta(paleta),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

// --- SELECTOR DE IDIOMA ---

/// Elegir el idioma de la app a mano. Mientras no se elija ninguno se usa el
/// del dispositivo (o español si no es uno de los de la app) y es el que
/// aparece marcado. Cada idioma aparece con su nombre en su propio idioma, así
/// se puede encontrar el propio aunque la app esté en otro. Se guarda en este
/// dispositivo (ver _SoundCheckProAppState.setIdioma).
class IdiomaPickerScreen extends StatelessWidget {
  const IdiomaPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final app = SoundCheckProApp.of(context);
    // El elegido a mano o, si nunca se eligió, el que está en uso.
    final elegido = app.idiomaElegido ?? Localizations.localeOf(context);
    final acento = context.acento;

    Widget opcion(
        {required String titulo,
        String? detalle,
        required bool seleccionada,
        required VoidCallback onTap}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: seleccionada
                    ? acento
                    : Theme.of(context).colorScheme.outlineVariant,
                width: seleccionada ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      if (detalle != null)
                        Text(
                          detalle,
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
                Icon(
                  seleccionada
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: seleccionada
                      ? acento
                      : Theme.of(context).colorScheme.outlineVariant,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.idioma)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(l.idiomaDescripcion),
          ),
          for (final (locale, nombre) in IdiomasApp.todos)
            opcion(
              titulo: nombre,
              seleccionada: elegido.languageCode == locale.languageCode,
              onTap: () => app.setIdioma(locale),
            ),
        ],
      ),
    );
  }
}

class _PaletaCard extends StatelessWidget {
  final AppPalette paleta;

  final bool seleccionada;

  final bool oscuro;

  final VoidCallback onTap;

  const _PaletaCard({
    required this.paleta,
    required this.seleccionada,
    required this.oscuro,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final acento = oscuro ? paleta.accentDark : paleta.accentLight;

    final fondo = oscuro ? paleta.bgDark : paleta.bgLight;

    final superficie = oscuro ? paleta.surfaceDark : paleta.surfaceLight;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: seleccionada
                ? acento
                : Theme.of(context).colorScheme.outlineVariant,
            width: seleccionada ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Row(
              children: [fondo, superficie, acento].map((c) {
                return Container(
                  width: 20,
                  height: 32,
                  margin: const EdgeInsets.only(right: 3),
                  decoration: BoxDecoration(
                      color: c, borderRadius: BorderRadius.circular(4)),
                );
              }).toList(),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(paleta.nombreMostrar(context.l10n),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(paleta.tagMostrar(context.l10n),
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(
              seleccionada ? Icons.check_circle : Icons.radio_button_unchecked,
              color: seleccionada
                  ? acento
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
          ],
        ),
      ),
    );
  }
}

// --- PANTALLA DE CREACIÓN DE SALA ---

class CrearSalaScreen extends StatefulWidget {
  const CrearSalaScreen({super.key});

  @override
  State<CrearSalaScreen> createState() => _CrearSalaScreenState();
}

class _CrearSalaScreenState extends State<CrearSalaScreen> {
  final _nameController = TextEditingController();

  final String _pin = generarCodigoSala();

  final _rolController = TextEditingController();

  /// En true desde el primer intento de continuar: recién ahí se marcan los campos que faltan.
  bool _intentado = false;

  bool _procesando = false;

  Future<void> _crearYEntrar() async {
    final nombre = _nameController.text.trim();

    setState(() => _intentado = true);

    if (nombre.isEmpty || _rolController.text.trim().isEmpty || _procesando) {
      return;
    }

    setState(() => _procesando = true);

    try {
      await AuthService.asegurarSesion();

      final comoSonidista =
          await decidirEntradaSonidista(context, _rolController.text);

      if (comoSonidista == null) {
        if (mounted) setState(() => _procesando = false);

        return;
      }

      if (comoSonidista) {
        await entrarComoSonidista(context, _pin);

        return;
      }

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('tipo_login', 'usuario');

      await prefs.setString('sala_id', _pin);

      await prefs.setString('nombre', nombre);

      await prefs.setString('rol', _rolController.text.trim());

      await _registrarSalaSiCorresponde(
        codigoSala: _pin,
        rolUsado: _rolController.text.trim(),
        nombre: nombre,
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => RequestScreen(
            userName: nombre,
            rol: _rolController.text.trim(),
            codigoSala: _pin,
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      setState(() => _procesando = false);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(context.l10n.errorAlIngresar(mensajeError(context.l10n, e))),
        action: SnackBarAction(
            label: context.l10n.reintentar, onPressed: _crearYEntrar),
      ));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();

    _rolController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.configurarSala)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Card(
              child: ListTile(
                title:
                    Text(context.l10n.tuPinDeSala, textAlign: TextAlign.center),
                subtitle: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(_pin,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: context.acento)),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.share),
                      tooltip: context.l10n.compartirEnlaceSala,
                      onPressed: () => Share.share(
                          context.l10n.enlaceSalaTexto(enlaceDeSala(_pin))),
                    ),
                    IconButton(
                        icon: const Icon(Icons.copy),
                        tooltip: context.l10n.copiar,
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _pin));

                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(context.l10n.pinCopiado)));
                        }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              onChanged: (_) {
                if (_intentado) setState(() {});
              },
              decoration: InputDecoration(
                labelText: context.l10n.tuNombre2,
                errorText: _intentado && _nameController.text.trim().isEmpty
                    ? context.l10n.escribiTuNombre
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _rolController,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onChanged: (_) {
                if (_intentado) setState(() {});
              },
              onSubmitted: (_) => _crearYEntrar(),
              decoration: InputDecoration(
                labelText: context.l10n.tuRolEjSonidistaGuitarrista,
                errorText: _intentado && _rolController.text.trim().isEmpty
                    ? context.l10n.escribiTuRol
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _procesando ? null : _crearYEntrar,
                child: _procesando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(context.l10n.empezar),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- PANTALLA PARA UNIRSE A SALA ---

class UnirmeSalaScreen extends StatefulWidget {
  final String? codigoInicial;

  const UnirmeSalaScreen({super.key, this.codigoInicial});

  @override
  State<UnirmeSalaScreen> createState() => _UnirmeSalaScreenState();
}

class _UnirmeSalaScreenState extends State<UnirmeSalaScreen> {
  final _nameController = TextEditingController();

  late final _pinController =
      TextEditingController(text: widget.codigoInicial ?? '');

  final _rolController = TextEditingController();

  /// En true desde el primer intento de continuar: recién ahí se marcan los campos que faltan.
  bool _intentado = false;

  bool _procesando = false;

  Future<void> _unirmeASala() async {
    final pin = _pinController.text.trim().toUpperCase();

    final nombre = _nameController.text.trim();

    setState(() => _intentado = true);

    if (nombre.isEmpty ||
        pin.length != 8 ||
        _rolController.text.trim().isEmpty ||
        _procesando) {
      return;
    }

    setState(() => _procesando = true);

    try {
      await AuthService.asegurarSesion();

      final comoSonidista =
          await decidirEntradaSonidista(context, _rolController.text);

      if (comoSonidista == null) {
        if (mounted) setState(() => _procesando = false);

        return;
      }

      if (comoSonidista) {
        await entrarComoSonidista(context, pin);

        return;
      }

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('tipo_login', 'usuario');

      await prefs.setString('sala_id', pin);

      await prefs.setString('nombre', nombre);

      await prefs.setString('rol', _rolController.text.trim());

      await _registrarSalaSiCorresponde(
        codigoSala: pin,
        rolUsado: _rolController.text.trim(),
        nombre: nombre,
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => RequestScreen(
            userName: nombre,
            rol: _rolController.text.trim(),
            codigoSala: pin,
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      setState(() => _procesando = false);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(context.l10n.errorAlIngresar(mensajeError(context.l10n, e))),
        action: SnackBarAction(
            label: context.l10n.reintentar, onPressed: _unirmeASala),
      ));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();

    _rolController.dispose();

    _pinController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.unirseASala)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _pinController,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.next,
              onChanged: (_) {
                if (_intentado) setState(() {});
              },
              decoration: InputDecoration(
                labelText: context.l10n.codigoDeSala8Caracteres,
                errorText: _intentado && _pinController.text.trim().length != 8
                    ? context.l10n.pinDe8Caracteres
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              onChanged: (_) {
                if (_intentado) setState(() {});
              },
              decoration: InputDecoration(
                labelText: context.l10n.tuNombre2,
                errorText: _intentado && _nameController.text.trim().isEmpty
                    ? context.l10n.escribiTuNombre
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _rolController,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onChanged: (_) {
                if (_intentado) setState(() {});
              },
              onSubmitted: (_) => _unirmeASala(),
              decoration: InputDecoration(
                labelText: context.l10n.tuRolEjSonidistaGuitarrista,
                errorText: _intentado && _rolController.text.trim().isEmpty
                    ? context.l10n.escribiTuRol
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _procesando ? null : _unirmeASala,
                child: _procesando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(context.l10n.unirme),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- MIS SALAS (HISTORIAL MULTI-BANDA / MULTI-SALA, CUENTAS PRO) ---

class MisSalasScreen extends StatelessWidget {
  const MisSalasScreen({super.key});

  Future<void> _entrar(BuildContext context, String uid, String codigoSala,
      String rol, String nombre) async {
    await AuthService.asegurarSesion();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sala_id', codigoSala);
    if (rol == 'Sonidista') {
      await prefs.setString('tipo_login', 'sonidista');
    } else {
      await prefs.setString('tipo_login', 'usuario');
      await prefs.setString('nombre', nombre);
      await prefs.setString('rol', rol);
    }
    await MisSalasService.registrarAcceso(
        uid: uid, codigoSala: codigoSala, rolUsado: rol, nombre: nombre);
    if (!context.mounted) return;
    if (rol == 'Sonidista') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (_) => SonidistaPage(codigoSala: codigoSala)),
        (route) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => RequestScreen(
            userName: nombre,
            rol: rol,
            codigoSala: codigoSala,
          ),
        ),
        (route) => false,
      );
    }
  }

  Future<void> _renombrar(BuildContext context, String uid, String codigoSala,
      String nombreActual) async {
    final controller = TextEditingController(text: nombreActual);
    final nuevo = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.nombreParaEstaSala),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
              hintText: context.l10n.ejBandaXEnsayoJueves,
              border: const OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.cancelar)),
          TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text(context.l10n.guardar)),
        ],
      ),
    );
    if (nuevo == null || nuevo.isEmpty) return;
    await MisSalasService.renombrar(uid, codigoSala, nuevo);
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.misSalas2)),
      body: (user == null || user.isAnonymous)
          ? Center(child: Text(context.l10n.necesitasIniciarSesionParaTener))
          : StreamBuilder<bool>(
              stream: UsuarioService.streamEsPro(user.uid),
              builder: (context, proSnapshot) {
                final esPro =
                    kFuncionesProGratisPorAhora || proSnapshot.data == true;
                if (!esPro) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.workspace_premium,
                              color: context.acento, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            context.l10n.guardarUnHistorialDeVarias,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: MisSalasService.streamMisSalas(user.uid),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return Center(
                          child: Text(context.l10n.todaviaNoEntrasteANinguna));
                    }
                    return ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final doc = docs[i];
                        final data = doc.data();
                        final codigoSala = doc.id;
                        final rol = data['rolUsado'] as String? ?? 'Músico';
                        final nombre = data['nombre'] as String? ?? '';
                        final nombreSala = data['nombreSala'] as String?;
                        final tieneNombre =
                            nombreSala != null && nombreSala.isNotEmpty;
                        return ListTile(
                          leading: Icon(
                              rol == 'Sonidista'
                                  ? Icons.tune
                                  : Icons.mic_external_on,
                              color: context.acento),
                          title: Text(tieneNombre ? nombreSala : codigoSala),
                          subtitle: Text(tieneNombre
                              ? '$codigoSala · ${rolParaMostrar(context.l10n, rol)}'
                              : rolParaMostrar(context.l10n, rol)),
                          onTap: () => _entrar(
                              context, user.uid, codigoSala, rol, nombre),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                tooltip: context.l10n.renombrar,
                                onPressed: () => _renombrar(context, user.uid,
                                    codigoSala, nombreSala ?? ''),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 18, color: Colors.red),
                                tooltip: context.l10n.quitarDelHistorial,
                                onPressed: () => MisSalasService.quitar(
                                    user.uid, codigoSala),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}

// --- PESTAÑAS VISIBLES DE LA SALA ---

/// Pestañas que puede tener la pantalla de sala. Cada usuario elige cuáles
/// ver (botón de la barra de arriba), por separado para la pantalla de
/// músico/cantante (RequestScreen) y la del sonidista (SonidistaPage).
enum PestanaSala {
  pedidos,
  historial,
  setlist,
  secuencias;

  /// Texto en el selector, en el idioma de la app.
  String nombre(AppLocalizations l) => switch (this) {
        PestanaSala.pedidos => l.pestanaPedidos,
        PestanaSala.historial => l.pestanaHistorial,
        PestanaSala.setlist => l.pestanaSetlist,
        PestanaSala.secuencias => l.pestanaSecuencias,
      };

  /// Texto de la pestaña (mayúsculas donde el idioma las tiene).
  String etiqueta(AppLocalizations l) => nombre(l).toUpperCase();
}

/// Guarda en el dispositivo qué pestañas quiere ver el usuario (como la
/// paleta de colores: funciona también para invitados sin cuenta). No se
/// borra al salir de la sala (ver borrarSesionDeSala).
class PestanasSalaService {
  static String _clave(String pantalla) => 'pestanas_sala_$pantalla';

  /// Las pestañas elegidas, en el orden de [todas]. Si nunca se eligió nada
  /// (o lo guardado ya no sirve), todas.
  static Future<List<PestanaSala>> cargar(
      String pantalla, List<PestanaSala> todas) async {
    final prefs = await SharedPreferences.getInstance();
    final guardadas = prefs.getStringList(_clave(pantalla));
    if (guardadas == null) return todas;
    final elegidas = todas.where((p) => guardadas.contains(p.name)).toList();
    return elegidas.isEmpty ? todas : elegidas;
  }

  static Future<void> guardar(
      String pantalla, List<PestanaSala> elegidas) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _clave(pantalla), elegidas.map((p) => p.name).toList());
  }
}

/// Diálogo con casillas para elegir qué pestañas ver (al menos una).
/// Devuelve la elección, o null si se canceló.
Future<List<PestanaSala>?> elegirPestanasSala(
  BuildContext context, {
  required List<PestanaSala> todas,
  required List<PestanaSala> visibles,
}) {
  final elegidas = {...visibles};
  return showDialog<List<PestanaSala>>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialog) => AlertDialog(
        title: Text(context.l10n.queQueresVerEnLa),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final p in todas)
              CheckboxListTile(
                value: elegidas.contains(p),
                title: Text(p.nombre(context.l10n)),
                // La última que queda no se puede destildar.
                onChanged: elegidas.length == 1 && elegidas.contains(p)
                    ? null
                    : (v) => setDialog(
                        () => v == true ? elegidas.add(p) : elegidas.remove(p)),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                context.l10n.seGuardaEnEsteDispositivo,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.cancelar)),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, todas.where(elegidas.contains).toList()),
            child: Text(context.l10n.guardar),
          ),
        ],
      ),
    ),
  );
}

/// Al salir de una sala se borra solo la sesión de la sala, no el resto de
/// lo guardado en el dispositivo (paleta de colores, pestañas elegidas).
/// Antes se hacía prefs.clear(), que también borraba eso.
Future<void> borrarSesionDeSala() async {
  final prefs = await SharedPreferences.getInstance();
  for (final clave in ['tipo_login', 'sala_id', 'nombre', 'rol']) {
    await prefs.remove(clave);
  }
}

// --- PANTALLA DE PEDIDOS INDIVIDUAL (MÚSICO/CANTANTE) ---

class RequestScreen extends StatefulWidget {
  final String userName;

  final String rol;

  final String codigoSala;

  const RequestScreen(
      {super.key,
      required this.userName,
      required this.rol,
      required this.codigoSala});

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen>
    with TickerProviderStateMixin {
  final _customPedidoController = TextEditingController();

  bool _pantallaEncendida = true;

  bool _esUrgente = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _conexionSub;
  ScaffoldMessengerState? _messenger;
  bool _vioServidor = false;
  bool _avisoSinConexion = false;

  /// Se vuelve a crear cuando el usuario cambia las pestañas visibles (por
  /// eso TickerProviderStateMixin y no SingleTicker...).
  late TabController _tabController;

  static const _todasLasPestanas = [
    PestanaSala.pedidos,
    PestanaSala.setlist,
    PestanaSala.secuencias
  ];

  List<PestanaSala> _pestanas = _todasLasPestanas;

  /// Último visor de PDF/cifrado abierto desde el setlist, para poder

  /// volver a él con un swipe hacia abajo desde la pestaña de Pedidos.

  Widget? _ultimoVisor;

  Offset? _inicioArrastrePedidos;

  @override
  void initState() {
    super.initState();

    WakelockPlus.enable();
    _vigilarConexion();

    MiembrosSalaService.registrarPresencia(widget.codigoSala).catchError(
        (e) => debugPrint('No se pudo registrar presencia en la sala: $e'));

    _tabController = TabController(length: _pestanas.length, vsync: this);

    PestanasSalaService.cargar('musico', _todasLasPestanas).then((elegidas) {
      if (mounted) _aplicarPestanas(elegidas);
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();

    _customPedidoController.dispose();
    _conexionSub?.cancel();
    _messenger?.hideCurrentMaterialBanner();

    _tabController.dispose();

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.of(context);
  }

  /// Escucha si hay conexión con Firestore y muestra un aviso fijo cuando se
  /// pierde: así nadie cree que un pedido llegó cuando no hay red.
  void _vigilarConexion() {
    _conexionSub = FirebaseFirestore.instance
        .collection('salas')
        .doc(widget.codigoSala)
        .collection('pedidos')
        .limit(1)
        .snapshots(includeMetadataChanges: true)
        .listen((s) {
      final desdeCache = s.metadata.isFromCache;
      if (!desdeCache) _vioServidor = true;
      final sin = mostrarAvisoSinConexion(
          vioServidor: _vioServidor, desdeCache: desdeCache);
      if (sin == _avisoSinConexion || !mounted) return;
      _avisoSinConexion = sin;
      final messenger = ScaffoldMessenger.of(context);
      if (sin) {
        messenger.showMaterialBanner(MaterialBanner(
          content: Text(context.l10n.sinConexionAviso),
          leading: const Icon(Icons.wifi_off),
          actions: [
            TextButton(
                onPressed: messenger.hideCurrentMaterialBanner,
                child: Text(context.l10n.entendido))
          ],
        ));
      } else {
        messenger.hideCurrentMaterialBanner();
      }
    }, onError: (_) {});
  }

  /// Cambia las pestañas visibles quedándose, si sigue visible, en la que
  /// se estaba mirando.
  void _aplicarPestanas(List<PestanaSala> nuevas) {
    if (listEquals(nuevas, _pestanas)) return;
    final actual = _pestanas[_tabController.index];
    final indice = nuevas.indexOf(actual);
    _tabController.dispose();
    setState(() {
      _pestanas = nuevas;
      _tabController = TabController(
          length: nuevas.length,
          vsync: this,
          initialIndex: indice < 0 ? 0 : indice);
    });
  }

  Future<void> _elegirPestanas() async {
    final elegidas = await elegirPestanasSala(context,
        todas: _todasLasPestanas, visibles: _pestanas);
    if (elegidas == null || !mounted) return;
    await PestanasSalaService.guardar('musico', elegidas);
    _aplicarPestanas(elegidas);
  }

  /// Swipe hacia arriba en el visor de PDF/cifrado: vuelve a la sala y, si
  /// el usuario tiene la pestaña de Pedidos visible, la muestra.
  void _irAPedidos(Widget visorActual) {
    _ultimoVisor = visorActual;

    Navigator.pop(context);

    final pedidos = _pestanas.indexOf(PestanaSala.pedidos);

    if (pedidos >= 0) _tabController.animateTo(pedidos);
  }

  /// Swipe hacia abajo sobre la pestaña de Pedidos vuelve al último

  /// PDF/cifrado que se estaba viendo. Se usa Listener (no GestureDetector)

  /// para no competir por el gesto con el scroll de las listas internas.

  void _manejarSwipeAbajoEnPedidos(PointerUpEvent evento) {
    if (_inicioArrastrePedidos == null || _ultimoVisor == null) return;

    final delta = evento.position - _inicioArrastrePedidos!;

    _inicioArrastrePedidos = null;

    if (delta.dy > 80 && delta.dy.abs() > delta.dx.abs()) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => _ultimoVisor!));
    }
  }

  void _togglePantallaEncendida() {
    setState(() => _pantallaEncendida = !_pantallaEncendida);

    if (_pantallaEncendida) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    await borrarSesionDeSala();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const IngressMenuScreen()),
      (route) => false,
    );
  }

  Future<void> _enviarMensaje(String texto, {bool? urgenteForzado}) async {
    final limpio = texto.trim();
    if (limpio.isEmpty) return;
    final urgente = urgenteForzado ?? _esUrgente;
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    if (_esUrgente) setState(() => _esUrgente = false);
    // "Enviado" solo cuando de verdad llegó (o se avisa que quedó en cola / falló).
    final resultado = await esperarEnvio(FirestoreService.enviarPedido(
      codigo: widget.codigoSala,
      nombre: widget.userName,
      rol: widget.rol,
      pedido: limpio,
      urgente: urgente,
    ));
    if (!mounted) return;
    messenger.hideCurrentSnackBar();
    switch (resultado) {
      case ResultadoEnvio.enviado:
        messenger.showSnackBar(SnackBar(
          content: Text(urgente ? l.urgenteEnviado(limpio) : l.enviado(limpio)),
          duration: const Duration(milliseconds: 600),
          backgroundColor: urgente ? Colors.redAccent : null,
        ));
      case ResultadoEnvio.pendiente:
        messenger.showSnackBar(SnackBar(
          content: Text(l.pedidoPendienteSinConexion),
          duration: const Duration(seconds: 6),
          backgroundColor: Colors.orange.shade800,
        ));
      case ResultadoEnvio.fallo:
        messenger.showSnackBar(SnackBar(
          content: Text(l.noSePudoEnviarPedido),
          duration: const Duration(seconds: 8),
          backgroundColor: Colors.redAccent,
          action: SnackBarAction(
              label: l.reintentar,
              onPressed: () => _enviarMensaje(limpio, urgenteForzado: urgente)),
        ));
    }
  }

  Widget _construirGridFrases(List<String> pedidosRapidos) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.8,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6),
      itemCount: pedidosRapidos.length,
      itemBuilder: (context, i) {
        final pedido = pedidosRapidos[i];

        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            backgroundColor: context.acento.withOpacity(0.05),
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: BorderSide(color: context.acento.withOpacity(0.2))),
          ),
          onPressed: () => _enviarMensaje(pedido),
          child: Text(pedido,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Clipboard.setData(ClipboardData(text: widget.codigoSala));
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.l10n.codigoDeSalaCopiado)));
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.userName} (${rolParaMostrar(context.l10n, widget.rol)})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.sala(widget.codigoSala),
                    maxLines: 1,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: context.acento),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.copy, size: 12, color: context.acento),
                ],
              ),
            ],
          ),
        ),
        centerTitle: true,

        leading: IconButton(
          icon: const Icon(Icons.exit_to_app),
          tooltip: context.l10n.salirDeLaSala,
          onPressed: () async {
            if (await confirmarSalidaSala(context) && context.mounted) {
              _cerrarSesion(context);
            }
          },
        ),

        actions: [
          IconButton(
            icon: Icon(
                _pantallaEncendida ? Icons.lightbulb : Icons.lightbulb_outline),
            tooltip: _pantallaEncendida
                ? context.l10n.pantallaSiempreEncendidaActivado
                : context.l10n.pantallaSiempreEncendidaDesactivado,
            onPressed: _togglePantallaEncendida,
          ),
          IconButton(
            icon: const Icon(Icons.view_carousel_outlined),
            tooltip: context.l10n.elegirQueVerEnLa,
            onPressed: _elegirPestanas,
          ),
        ],

        // Con una sola pestaña elegida no hace falta la barra.
        bottom: _pestanas.length < 2
            ? null
            : TabBar(
                controller: _tabController,
                tabs: [
                  for (final p in _pestanas) Tab(text: p.etiqueta(context.l10n))
                ],
              ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _contenidoDePestanas({
          PestanaSala.pedidos: Listener(
            onPointerDown: (e) => _inicioArrastrePedidos = e.position,
            onPointerUp: _manejarSwipeAbajoEnPedidos,
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Builder(builder: (context) {
                    final user = AuthService.currentUser;

                    if (user == null || user.isAnonymous) {
                      return _construirGridFrases(
                          AppConstants.pedidosRapidos(context.l10n));
                    }

                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FrasesService.streamFrases(user.uid),
                      builder: (context, snapshot) {
                        final docs = snapshot.data?.docs;

                        final pedidosRapidos = (docs == null || docs.isEmpty)
                            ? AppConstants.pedidosRapidos(context.l10n)
                            : docs
                                .map((d) => d.data()['texto'] as String)
                                .toList();

                        return _construirGridFrases(pedidosRapidos);
                      },
                    );
                  }),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customPedidoController,
                          style: const TextStyle(fontSize: 14),
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(
                                kMaxCaracteresPedido)
                          ],
                          textInputAction: TextInputAction.send,
                          onSubmitted: (t) {
                            _enviarMensaje(t);

                            _customPedidoController.clear();
                          },
                          decoration: InputDecoration(
                            hintText: context.l10n.escribirPedidoPersonalizado,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(Icons.priority_high,
                            color: _esUrgente ? Colors.redAccent : Colors.grey),
                        tooltip: _esUrgente
                            ? context.l10n.pedidoUrgenteActivado
                            : context.l10n.marcarElProximoPedidoComo,
                        onPressed: () =>
                            setState(() => _esUrgente = !_esUrgente),
                      ),
                      const SizedBox(width: 4),
                      IconButton.filled(
                        icon: const Icon(Icons.send, size: 18),
                        style: _esUrgente
                            ? IconButton.styleFrom(
                                backgroundColor: Colors.redAccent)
                            : null,
                        onPressed: () {
                          _enviarMensaje(_customPedidoController.text);

                          _customPedidoController.clear();
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(thickness: 1, height: 1),
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(context.l10n.misUltimosPedidos,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            letterSpacing: 1.1))),
                Expanded(
                  flex: 2,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('salas')
                        .doc(widget.codigoSala)
                        .collection('pedidos')
                        .where('nombre', isEqualTo: widget.userName)
                        .orderBy('createdAt', descending: true)
                        .limit(10)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                            child: Text(
                                context.l10n.error(
                                    mensajeError(context.l10n, snapshot.error)),
                                style: const TextStyle(fontSize: 14)));
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs;

                      if (docs.isEmpty) {
                        return Center(
                            child: Text(context.l10n.sinPedidosPropios,
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 14)));
                      }

                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, i) {
                          final doc = docs[i];

                          final data = doc.data() as Map<String, dynamic>;

                          final isAtendido = data['atendido'] ?? false;

                          final esUrgente = data['urgente'] ?? false;

                          final respuestaTecnico = data['respuesta'] ?? '';

                          return GestureDetector(
                            onLongPress: () async {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(context.l10n
                                      .eliminandoPedido(data['pedido'])),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );

                              await FirestoreService.eliminarPedidoIndividual(
                                  widget.codigoSala, doc.id);
                            },
                            child: ListTile(
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              leading: Icon(
                                isAtendido
                                    ? Icons.check_circle
                                    : (esUrgente
                                        ? Icons.priority_high
                                        : Icons.access_time_filled),
                                color: isAtendido
                                    ? Colors.green
                                    : (esUrgente
                                        ? Colors.redAccent
                                        : Colors.orange),
                                size: 16,
                              ),
                              title: Text(
                                "${data['pedido']}",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: esUrgente && !isAtendido
                                      ? FontWeight.bold
                                      : null,
                                  decoration: isAtendido
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              subtitle: respuestaTecnico.isNotEmpty
                                  ? Text(
                                      context.l10n.consola(respuestaTecnico),
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: context.acento),
                                    )
                                  : null,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          PestanaSala.setlist: SetlistTab(
            codigoSala: widget.codigoSala,
            nombreUsuario: widget.userName,
            onIrAPedidos: _irAPedidos,
          ),
          PestanaSala.secuencias: SecuenciasTab(
            codigoSala: widget.codigoSala,
            nombreUsuario: widget.userName,
          ),
        }),
      ),
    );
  }

  /// El contenido de las pestañas elegidas, en orden.
  List<Widget> _contenidoDePestanas(Map<PestanaSala, Widget> contenido) =>
      [for (final p in _pestanas) contenido[p]!];
}

// --- LISTA DE TEMAS COMPARTIDA (SETLIST DE SALA) ---

class SetlistTab extends StatelessWidget {
  final String codigoSala;

  final String nombreUsuario;

  /// Swipe hacia arriba en el visor de PDF/cifrado llama esto para volver

  /// a la pestaña de Pedidos de la pantalla que contiene este SetlistTab

  /// (RequestScreen o SonidistaPage). Recibe el widget del visor actual

  /// para poder reabrirlo con un swipe hacia abajo desde Pedidos.

  final void Function(Widget visorActual)? onIrAPedidos;

  /// El sonidista puede ver el setlist y marcar temas como tocados/pausados,
  /// pero no reordenar, borrar, ni cambiar el tono (transposición) — eso
  /// queda a criterio de los músicos/cantantes que arman el repertorio.
  final bool esSonidista;

  const SetlistTab({
    super.key,
    required this.codigoSala,
    required this.nombreUsuario,
    this.onIrAPedidos,
    this.esSonidista = false,
  });

  Future<void> _agregarCancion(BuildContext context) async {
    final opcion = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.library_music, color: context.acento),
              title: Text(context.l10n.desdeMiBiblioteca),
              onTap: () => Navigator.pop(context, 'biblioteca'),
            ),
            ListTile(
              leading: Icon(Icons.search, color: context.acento),
              title: Text(context.l10n.buscarEnBibliotecasDeLa),
              onTap: () => Navigator.pop(context, 'buscar'),
            ),
          ],
        ),
      ),
    );

    if (opcion == null || !context.mounted) return;

    if (opcion == 'biblioteca') {
      await _elegirDesdeBiblioteca(context);
    } else {
      await _buscarEntreCompaneros(context);
    }
  }

  Future<void> _elegirDesdeBiblioteca(BuildContext context) async {
    final user = AuthService.currentUser;

    if (user == null || user.isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.necesitasIniciarSesionParaUsar)),
      );

      return;
    }

    final seleccion = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final controllerTitulo = TextEditingController();

        final controllerTonalidad = TextEditingController();

        return StatefulBuilder(
          builder: (context, setModalState) => DraggableScrollableSheet(
            expand: false,
            builder: (context, scrollController) =>
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: RepertorioService.streamRepertorio(user.uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs =
                    RepertorioService.ordenarPorTitulo(snapshot.data!.docs);

                if (docs.isEmpty) {
                  return Center(
                      child: Text(context.l10n.tuBibliotecaEstaVacia));
                }

                final canciones =
                    docs.map((d) => {...d.data(), 'id': d.id}).toList();

                final docsFiltrados =
                    RepertorioService.filtrarPorTituloYTonalidad(
                  canciones,
                  titulo: controllerTitulo.text,
                  tonalidad: controllerTonalidad.text,
                );

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controllerTitulo,
                              autofocus: true,
                              onChanged: (_) => setModalState(() {}),
                              decoration: InputDecoration(
                                hintText: context.l10n.titulo,
                                isDense: true,
                                prefixIcon: const Icon(Icons.search, size: 20),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: controllerTonalidad,
                              onChanged: (_) => setModalState(() {}),
                              decoration: InputDecoration(
                                hintText: context.l10n.tonalidad,
                                isDense: true,
                                prefixIcon:
                                    const Icon(Icons.music_note, size: 20),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: docsFiltrados.isEmpty
                          ? Center(child: Text(context.l10n.sinResultados))
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: docsFiltrados.length,
                              itemBuilder: (context, i) {
                                final data = docsFiltrados[i];

                                return ListTile(
                                  leading: Icon(Icons.picture_as_pdf,
                                      color: context.acento),
                                  title: Text(data['titulo'] as String? ?? ''),
                                  subtitle:
                                      Text(data['tonalidad'] as String? ?? ''),
                                  onTap: () => Navigator.pop(context, data),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );

    if (seleccion == null || !context.mounted) return;

    await _confirmarAgregar(
      context,
      seleccion['titulo'] as String? ?? '',
      seleccion['pdfUrl'] as String? ?? '',
      cifradoTexto: seleccion['cifradoTexto'] as String? ?? '',
      cifradoVersion: seleccion['cifradoVersion'] as int?,
    );
  }

  /// Trae de una sola vez todas las canciones de todos los que pasaron por
  /// esta sala (compañeros + la propia biblioteca, o null si nadie tiene
  /// biblioteca todavía) para poder filtrarlas en memoria mientras el
  /// usuario escribe, sin golpear Firestore por letra.
  Future<List<Map<String, dynamic>>?> _cargarCancionesDeCompaneros() async {
    final presentes = await MiembrosSalaService.obtenerPresentes(codigoSala);
    if (presentes.isEmpty) return null;
    return RepertorioService.cancionesDeCompaneros(presentes);
  }

  Future<void> _buscarEntreCompaneros(BuildContext context) async {
    final controllerTitulo = TextEditingController();
    final controllerTonalidad = TextEditingController();

    final seleccion = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FutureBuilder<List<Map<String, dynamic>>?>(
          future: _cargarCancionesDeCompaneros(),
          builder: (context, snapshot) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controllerTitulo,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: context.l10n.titulo,
                              prefixIcon: const Icon(Icons.search),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: controllerTonalidad,
                            decoration: InputDecoration(
                              hintText: context.l10n.tonalidad,
                              prefixIcon: const Icon(Icons.music_note),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator()),
                    if (snapshot.connectionState != ConnectionState.waiting &&
                        snapshot.hasError)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          context.l10n.noSePudoBuscarIntenta,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    if (snapshot.connectionState != ConnectionState.waiting &&
                        !snapshot.hasError &&
                        snapshot.data == null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(context.l10n.todaviaNoHayBibliotecasPara),
                      ),
                    if (snapshot.connectionState != ConnectionState.waiting &&
                        !snapshot.hasError &&
                        snapshot.data != null)
                      ListenableBuilder(
                        listenable: Listenable.merge(
                            [controllerTitulo, controllerTonalidad]),
                        builder: (context, _) {
                          final sugerencias =
                              RepertorioService.filtrarPorTituloYTonalidad(
                            snapshot.data!,
                            titulo: controllerTitulo.text,
                            tonalidad: controllerTonalidad.text,
                          );

                          if (sugerencias.isEmpty) {
                            return Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(context.l10n.sinResultados));
                          }

                          return Flexible(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: sugerencias.length,
                              itemBuilder: (context, i) {
                                final data = sugerencias[i];

                                final tonalidad =
                                    data['tonalidad'] as String? ?? '';

                                final propietario =
                                    data['propietarioNombre'] as String? ?? '';

                                return ListTile(
                                  leading: Icon(Icons.picture_as_pdf,
                                      color: context.acento),
                                  title: Text(data['titulo'] as String? ?? ''),
                                  subtitle: Text(
                                    [
                                      tonalidad,
                                      if (propietario.isNotEmpty)
                                        context.l10n.de(propietario)
                                    ].where((s) => s.isNotEmpty).join(' · '),
                                  ),
                                  onTap: () => Navigator.pop(context, data),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (seleccion == null || !context.mounted) return;

    await _confirmarAgregar(
      context,
      seleccion['titulo'] as String? ?? '',
      seleccion['pdfUrl'] as String? ?? '',
      cifradoTexto: seleccion['cifradoTexto'] as String? ?? '',
      cifradoVersion: seleccion['cifradoVersion'] as int?,
    );
  }

  /// Arma un resumen en texto plano del setlist (orden, título, estado) y

  /// deja elegir entre copiarlo al portapapeles o compartirlo con el share

  /// sheet del sistema/navegador. No depende de Firebase Storage.

  Future<void> _exportarSetlist(BuildContext context) async {
    final snapshot = await SetlistService.streamSetlist(codigoSala).first;

    if (!context.mounted) return;

    final docs = snapshot.docs;

    if (docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.elSetlistEstaVacioNo)),
      );

      return;
    }

    final buffer = StringBuffer(context.l10n.setlistSala(codigoSala));

    for (var i = 0; i < docs.length; i++) {
      final data = docs[i].data();

      final titulo = data['titulo'] as String? ?? '';

      final estado = (data['estado'] as String?) ??
          ((data['completado'] as bool? ?? false) ? 'tocado' : 'pendiente');

      final marca =
          estado == 'tocado' ? '[X]' : (estado == 'pausado' ? '[~]' : '[ ]');

      buffer.writeln('${i + 1}. $marca $titulo');
    }

    final texto = buffer.toString();

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.exportarSetlist),
        content: SingleChildScrollView(child: SelectableText(texto)),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: texto));

              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                      content: Text(context.l10n.copiadoAlPortapapeles),
                      duration: const Duration(seconds: 1)),
                );
              }
            },
            child: Text(context.l10n.copiar),
          ),
          TextButton(
            onPressed: () => Share.share(texto,
                subject: context.l10n.setlistSala2(codigoSala)),
            child: Text(context.l10n.compartir),
          ),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.l10n.cerrar)),
        ],
      ),
    );
  }

  Future<void> _confirmarAgregar(
      BuildContext context, String titulo, String pdfUrl,
      {String cifradoTexto = '', int? cifradoVersion}) async {
    if (titulo.isEmpty || pdfUrl.isEmpty) return;

    final actual = await SetlistService.streamSetlist(codigoSala).first;

    await SetlistService.agregarAlSetlist(
      codigoSala: codigoSala,
      titulo: titulo,
      pdfUrl: pdfUrl,
      subidoPor: nombreUsuario,
      orden: actual.docs.length,
      cifradoTexto: cifradoTexto,
      cifradoVersion: cifradoVersion,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(context.l10n.agregado(titulo)),
            duration: const Duration(seconds: 1)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: SetlistService.streamSetlist(codigoSala),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text(context.l10n
                    .error(mensajeError(context.l10n, snapshot.error))));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(child: Text(context.l10n.todaviaNoHayTemasEn));
          }

          final setlistItems = docs.map((d) {
            final m = d.data();

            return {
              'id': d.id,
              'titulo': m['titulo'] as String? ?? '',
              'pdfUrl': m['pdfUrl'] as String? ?? '',
              'cifradoTexto': m['cifradoTexto'] as String? ?? '',
              'cifradoVersion': m['cifradoVersion'] as int?,
            };
          }).toList();

          String estadoDe(Map<String, dynamic> data) {
            return (data['estado'] as String?) ??
                ((data['completado'] as bool? ?? false)
                    ? 'tocado'
                    : 'pendiente');
          }

          final primerPendienteIndex =
              docs.indexWhere((d) => estadoDe(d.data()) == 'pendiente');

          Widget construirItem(BuildContext context, int i) {
            final doc = docs[i];

            final data = doc.data();

            final titulo = data['titulo'] as String? ?? '';

            final subidoPor = data['subidoPor'] as String? ?? '';

            final pdfUrl = data['pdfUrl'] as String? ?? '';

            final cifradoTexto = data['cifradoTexto'] as String? ?? '';

            final estado = estadoDe(data);

            final completado = estado == 'tocado';

            final pausado = estado == 'pausado';

            final esProximo =
                estado == 'pendiente' && i == primerPendienteIndex;

            const coloresEstado = {
              'pendiente': null,
              'pausado': Colors.orange,
              'tocado': Colors.green,
            };

            const iconosEstado = {
              'pendiente': Icons.check_circle_outline,
              'pausado': Icons.pause_circle_filled,
              'tocado': Icons.check_circle,
            };

            return ListTile(
              key: ValueKey(doc.id),
              tileColor: esProximo
                  ? context.acento.withOpacity(0.06)
                  : (pausado ? Colors.orange.withOpacity(0.08) : null),
              leading: PopupMenuButton<String>(
                tooltip: context.l10n.cambiarEstadoDelTema,
                icon: Icon(iconosEstado[estado],
                    color: coloresEstado[estado] ??
                        context.acento.withOpacity(0.5)),
                onSelected: (nuevoEstado) => SetlistService.actualizarEstado(
                    codigoSala, doc.id, nuevoEstado),
                itemBuilder: (context) => [
                  PopupMenuItem(
                      value: 'pendiente', child: Text(context.l10n.pendiente)),
                  PopupMenuItem(
                      value: 'pausado',
                      child: Text(context.l10n.pausadoCorteTecnico)),
                  PopupMenuItem(
                      value: 'tocado', child: Text(context.l10n.tocado)),
                ],
              ),
              title: Row(
                children: [
                  Flexible(
                    child: Text(
                      titulo,
                      style: TextStyle(
                        decoration:
                            completado ? TextDecoration.lineThrough : null,
                        fontStyle: pausado ? FontStyle.italic : null,
                        color: completado
                            ? Colors.grey
                            : (pausado ? Colors.orange.shade800 : null),
                      ),
                    ),
                  ),
                  if (esProximo || pausado) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: pausado ? Colors.orange : context.acento,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        pausado ? context.l10n.pausado : context.l10n.proximo,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
              subtitle: Text(
                context.l10n.subidoPor(subidoPor),
                style: TextStyle(color: completado ? Colors.grey : null),
              ),
              onTap: pdfUrl.isEmpty
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PdfViewerScreen(
                            titulo: titulo,
                            pdfUrl: pdfUrl,
                            setlistItems: setlistItems,
                            indiceEnSetlist: i,
                            codigoSala: codigoSala,
                            onIrAPedidos: onIrAPedidos,
                          ),
                        ),
                      ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (cifradoTexto.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.music_note, color: context.acento),
                      tooltip: context.l10n.verCifradoTransponer,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CifradoViewerScreen(
                            titulo: titulo,
                            cifradoOriginal: cifradoTexto,
                            codigoSala: codigoSala,
                            itemId: doc.id,
                            setlistItems: setlistItems,
                            indiceEnSetlist: i,
                            onIrAPedidos: onIrAPedidos,
                            puedeTransponer: !esSonidista,
                            pdfUrl: pdfUrl,
                            versionCifrado: data['cifradoVersion'] as int?,
                            alRegenerar: (texto) =>
                                SetlistService.actualizarCifrado(
                                    codigoSala, doc.id, texto),
                          ),
                        ),
                      ),
                    ),
                  if (!esSonidista)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: context.l10n.eliminar,
                      onPressed: () =>
                          SetlistService.eliminarDelSetlist(codigoSala, doc.id),
                    ),
                ],
              ),
            );
          }

          if (esSonidista) {
            return ListView.builder(
                itemCount: docs.length, itemBuilder: construirItem);
          }

          return ReorderableListView.builder(
            itemCount: docs.length,
            onReorder: (oldIndex, newIndex) {
              final idsEnOrden = docs.map((d) => d.id).toList();

              final ajustado = newIndex > oldIndex ? newIndex - 1 : newIndex;

              final id = idsEnOrden.removeAt(oldIndex);

              idsEnOrden.insert(ajustado, id);

              SetlistService.reordenarSetlist(codigoSala, idsEnOrden);
            },
            itemBuilder: construirItem,
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'exportar_setlist_$codigoSala',
            onPressed: () => _exportarSetlist(context),
            tooltip: context.l10n.exportarCompartirSetlist,
            child: const Icon(Icons.ios_share),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'agregar_cancion_$codigoSala',
            onPressed: () => _agregarCancion(context),
            tooltip: context.l10n.agregarCancion,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

// --- SECUENCIAS DE LA SALA (PISTAS DEL SHOW) ---

/// Pestaña "Secuencias" de RequestScreen/SonidistaPage: las pistas que la
/// banda cargó para el show de hoy (desde "Mis secuencias" de cada uno), con
/// reproductor. Mantiene su estado vivo (AutomaticKeepAliveClientMixin) para
/// que la pista siga sonando al pasar a Pedidos o Setlist — TabBarView
/// destruye las pestañas que no se ven si no se le pide lo contrario.
class SecuenciasTab extends StatefulWidget {
  final String codigoSala;
  final String nombreUsuario;

  /// Igual que en SetlistTab: el sonidista puede reproducir, pero no cargar,
  /// quitar ni reordenar — eso lo arman los músicos.
  final bool esSonidista;

  const SecuenciasTab({
    super.key,
    required this.codigoSala,
    required this.nombreUsuario,
    this.esSonidista = false,
  });

  @override
  State<SecuenciasTab> createState() => _SecuenciasTabState();
}

class _SecuenciasTabState extends State<SecuenciasTab>
    with AutomaticKeepAliveClientMixin {
  final _reproductor = ReproductorSecuencias();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _reproductor.dispose();
    super.dispose();
  }

  /// Lista de "Mis secuencias" con casillas para elegir varias de una vez.
  /// Las que ya están cargadas en la sala (misma URL) aparecen tildadas y
  /// deshabilitadas, para no duplicarlas.
  Future<void> _cargarDesdeMisSecuencias(
      Set<String> urlsEnSala, int cantidadEnSala) async {
    final user = AuthService.currentUser;
    if (user == null || user.isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.necesitasIniciarSesionParaUsar2)),
      );
      return;
    }
    final elegidas = <String, Map<String, dynamic>>{};
    final busqueda = TextEditingController();

    final confirmar = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          builder: (context, scrollController) =>
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: SecuenciasService.streamMisSecuencias(user.uid),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs =
                  RepertorioService.ordenarPorTitulo(snapshot.data!.docs);
              if (docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      context.l10n.noTenesSecuenciasTodaviaSubilas,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              final secuencias = RepertorioService.filtrarPorTituloYTonalidad(
                docs.map((d) => {...d.data(), 'id': d.id}).toList(),
                titulo: busqueda.text,
                tonalidad: '',
              );
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: TextField(
                      controller: busqueda,
                      onChanged: (_) => setModalState(() {}),
                      decoration: InputDecoration(
                        hintText: context.l10n.buscarSecuencia,
                        isDense: true,
                        prefixIcon: const Icon(Icons.search, size: 20),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: secuencias.length,
                      itemBuilder: (context, i) {
                        final data = secuencias[i];
                        final id = data['id'] as String;
                        final yaCargada = urlsEnSala.contains(data['audioUrl']);
                        return CheckboxListTile(
                          value: yaCargada || elegidas.containsKey(id),
                          onChanged: yaCargada
                              ? null
                              : (v) => setModalState(() => v == true
                                  ? elegidas[id] = data
                                  : elegidas.remove(id)),
                          secondary:
                              Icon(Icons.graphic_eq, color: context.acento),
                          title: Text(data['titulo'] as String? ?? ''),
                          subtitle: yaCargada
                              ? Text(context.l10n.yaEstaEnLaSala)
                              : null,
                        );
                      },
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.playlist_add),
                          label: Text(elegidas.isEmpty
                              ? context.l10n.elegiLasSecuenciasDeHoy
                              : context.l10n.cargarALaSala(elegidas.length)),
                          onPressed: elegidas.isEmpty
                              ? null
                              : () => Navigator.pop(context, true),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    busqueda.dispose();
    if (confirmar != true || elegidas.isEmpty) return;

    try {
      await SecuenciasService.agregarASala(
        codigoSala: widget.codigoSala,
        secuencias: elegidas.values.toList(),
        subidoPor: widget.nombreUsuario,
        ordenInicial: cantidadEnSala,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(context.l10n.noSePudieronCargar(e)),
              backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _quitar(String id, String titulo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.quitarDeLaSala),
        content: Text(context.l10n.quitarDeLasSecuenciasDe(titulo)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.cancelar)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.quitar,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (_reproductor.idActual == id) await _reproductor.detener();
    await SecuenciasService.quitarDeSala(widget.codigoSala, id);
  }

  static String _textoSemitonos(AppLocalizations l, int semitonos) {
    if (semitonos == 0) return l.tonoOriginal;
    return l.semitonosConSigno(semitonos > 0 ? '+' : '−', semitonos.abs());
  }

  /// "Tono +2 · Tempo 95% · Vol 80%", o null si la secuencia está como se
  /// subió.
  static String? _resumenAjustes(AppLocalizations l, int semitonos,
      int tempoPorcentaje, int volumenPorcentaje) {
    final partes = [
      if (semitonos != 0)
        l.ajusteTono('${semitonos > 0 ? '+' : '−'}${semitonos.abs()}'),
      if (tempoPorcentaje != 100) l.ajusteTempo(tempoPorcentaje),
      if (volumenPorcentaje != 100) l.ajusteVolumen(volumenPorcentaje),
    ];
    return partes.isEmpty ? null : partes.join(' · ');
  }

  /// Tono (±12 semitonos), tempo (50-150%) y volumen (0-100%) de una
  /// secuencia, como Music Speed Changer: ninguno cambia a los otros. Suena
  /// en vivo mientras se mueve y se guarda en la sala para todos (los
  /// deslizadores, al soltarlos).
  Future<void> _ajustarTonoYTempo(
    String id,
    String titulo,
    int semitonosIniciales,
    int tempoInicial,
    int volumenInicial,
  ) async {
    var semitonos = semitonosIniciales;
    var tempo = tempoInicial;
    var volumen = volumenInicial;

    void guardar() {
      SecuenciasService.actualizarAjustes(
        widget.codigoSala,
        id,
        semitonos: semitonos,
        tempoPorcentaje: tempo,
        volumenPorcentaje: volumen,
        ajustadoPor: widget.nombreUsuario,
      ).catchError((e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(context.l10n.noSePudoGuardarEl(e)),
                backgroundColor: Colors.redAccent),
          );
        }
      });
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) {
          void cambiar(
              {int? nuevoTono,
              int? nuevoTempo,
              int? nuevoVolumen,
              bool guardarYa = true}) {
            setSheet(() {
              if (nuevoTono != null) semitonos = nuevoTono;
              if (nuevoTempo != null) tempo = nuevoTempo;
              if (nuevoVolumen != null) volumen = nuevoVolumen;
            });
            _reproductor.aplicarAjustes(id,
                tempo: tempo / 100,
                semitonos: semitonos,
                volumen: volumen / 100);
            if (guardarYa) guardar();
          }

          final soportaTono = ReproductorSecuencias.soportaTono;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(titulo,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.seGuardaParaTodaLa,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  Text(context.l10n.tono,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        iconSize: 32,
                        icon: const Icon(Icons.remove),
                        tooltip: context.l10n.bajarUnSemitono,
                        onPressed: soportaTono && semitonos > -12
                            ? () => cambiar(nuevoTono: semitonos - 1)
                            : null,
                      ),
                      SizedBox(
                        width: 160,
                        child: Text(
                          _textoSemitonos(context.l10n, semitonos),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton.filledTonal(
                        iconSize: 32,
                        icon: const Icon(Icons.add),
                        tooltip: context.l10n.subirUnSemitono,
                        onPressed: soportaTono && semitonos < 12
                            ? () => cambiar(nuevoTono: semitonos + 1)
                            : null,
                      ),
                    ],
                  ),
                  if (!soportaTono)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        context.l10n.elCambioDeTonoPor,
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(context.l10n.tempo,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1)),
                      ),
                      Text('$tempo%',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        tooltip: context.l10n.masLento1,
                        onPressed: tempo > 50
                            ? () => cambiar(nuevoTempo: tempo - 1)
                            : null,
                      ),
                      Expanded(
                        child: Slider(
                          value: tempo.toDouble(),
                          min: 50,
                          max: 150,
                          divisions: 100,
                          label: '$tempo%',
                          onChanged: (v) =>
                              cambiar(nuevoTempo: v.round(), guardarYa: false),
                          onChangeEnd: (_) => guardar(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        tooltip: context.l10n.masRapido1,
                        onPressed: tempo < 150
                            ? () => cambiar(nuevoTempo: tempo + 1)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(context.l10n.volumen,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1)),
                      ),
                      Text('$volumen%',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.volume_down),
                        tooltip: context.l10n.bajar5,
                        onPressed: volumen > 0
                            ? () => cambiar(nuevoVolumen: max(0, volumen - 5))
                            : null,
                      ),
                      Expanded(
                        child: Slider(
                          value: volumen.toDouble(),
                          min: 0,
                          max: 100,
                          divisions: 100,
                          label: '$volumen%',
                          onChanged: (v) => cambiar(
                              nuevoVolumen: v.round(), guardarYa: false),
                          onChangeEnd: (_) => guardar(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up),
                        tooltip: context.l10n.subir5,
                        onPressed: volumen < 100
                            ? () => cambiar(nuevoVolumen: min(100, volumen + 5))
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.restart_alt),
                    label: Text(context.l10n.restablecerComoSeSubio),
                    onPressed: semitonos == 0 && tempo == 100 && volumen == 100
                        ? null
                        : () => cambiar(
                            nuevoTono: 0, nuevoTempo: 100, nuevoVolumen: 100),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: SecuenciasService.streamSecuenciasSala(widget.codigoSala),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                  context.l10n.noSePudieronCargarLas('${snapshot.error}'),
                  textAlign: TextAlign.center),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        final urlsEnSala =
            docs.map((d) => d.data()['audioUrl'] as String? ?? '').toSet();
        scheduleMicrotask(() => _reproductor
            .precargar(urlsEnSala.where((u) => u.isNotEmpty).toList()));

        Widget fila(QueryDocumentSnapshot<Map<String, dynamic>> doc, int i) {
          final data = doc.data();
          final titulo = data['titulo'] as String? ?? '';
          final semitonos = (data['semitonos'] as num?)?.toInt() ?? 0;
          final tempoPorcentaje =
              (data['tempoPorcentaje'] as num?)?.toInt() ?? 100;
          final volumenPorcentaje =
              (data['volumenPorcentaje'] as num?)?.toInt() ?? 100;
          // Si otro integrante cambió tono, tempo o volumen de la pista que
          // está cargada acá, se aplica en vivo (fuera del build).
          if (_reproductor.idActual == doc.id) {
            scheduleMicrotask(() => _reproductor.aplicarAjustes(
                  doc.id,
                  tempo: tempoPorcentaje / 100,
                  semitonos: semitonos,
                  volumen: volumenPorcentaje / 100,
                ));
          }
          final ajustes = _resumenAjustes(
              context.l10n, semitonos, tempoPorcentaje, volumenPorcentaje);
          return FilaSecuencia(
            key: ValueKey(doc.id),
            reproductor: _reproductor,
            id: doc.id,
            titulo: '${i + 1}. $titulo',
            audioUrl: data['audioUrl'] as String? ?? '',
            subtitulo: [
              context.l10n.cargadaPor(data['subidoPor'] ?? '—'),
              if (ajustes != null) ajustes,
              if (ajustes != null &&
                  (data['ajustadoPor'] as String? ?? '').isNotEmpty)
                context.l10n.ajustadoPor(data['ajustadoPor'] as String),
            ].join(' · '),
            tempo: tempoPorcentaje / 100,
            semitonos: semitonos,
            volumen: volumenPorcentaje / 100,
            acciones: widget.esSonidista
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.tune,
                            color: ajustes != null ? context.acento : null),
                        tooltip: context.l10n.tonoTempoYVolumen,
                        onPressed: () => _ajustarTonoYTempo(doc.id, titulo,
                            semitonos, tempoPorcentaje, volumenPorcentaje),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Colors.red),
                        tooltip: context.l10n.quitarDeLaSala,
                        onPressed: () => _quitar(doc.id, titulo),
                      ),
                      ReorderableDragStartListener(
                          index: i, child: const Icon(Icons.drag_handle)),
                    ],
                  ),
          );
        }

        return Scaffold(
          body: Column(
            children: [
              ListenableBuilder(
                listenable: _reproductor,
                builder: (context, _) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          docs.isEmpty
                              ? ''
                              : context.l10n.secuenciasParaHoy(docs.length),
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                      FilterChip(
                        avatar: const Icon(Icons.repeat, size: 18),
                        label: Text(context.l10n.repetir),
                        selected: _reproductor.repetir,
                        onSelected: (_) => _reproductor.alternarRepetir(),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: docs.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.graphic_eq,
                                  size: 64,
                                  color: context.acento.withOpacity(0.5)),
                              const SizedBox(height: 12),
                              Text(
                                widget.esSonidista
                                    ? context
                                        .l10n.todaviaNoHaySecuenciasCargadas
                                    : context
                                        .l10n.todaviaNoHaySecuenciasCargadas2,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : widget.esSonidista
                        ? ListView.separated(
                            padding: const EdgeInsets.only(bottom: 88),
                            itemCount: docs.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, i) => fila(docs[i], i),
                          )
                        : ReorderableListView.builder(
                            padding: const EdgeInsets.only(bottom: 88),
                            buildDefaultDragHandles: false,
                            itemCount: docs.length,
                            itemBuilder: (context, i) => fila(docs[i], i),
                            onReorder: (viejo, nuevo) {
                              final ids = docs.map((d) => d.id).toList();
                              if (nuevo > viejo) nuevo--;
                              ids.insert(nuevo, ids.removeAt(viejo));
                              SecuenciasService.reordenarSala(
                                  widget.codigoSala, ids);
                            },
                          ),
              ),
            ],
          ),
          floatingActionButton: widget.esSonidista
              ? null
              : FloatingActionButton(
                  heroTag: 'agregar_secuencias',
                  tooltip: context.l10n.cargarSecuenciasDeHoy,
                  onPressed: () =>
                      _cargarDesdeMisSecuencias(urlsEnSala, docs.length),
                  child: const Icon(Icons.add),
                ),
        );
      },
    );
  }
}

// --- ADMINISTRACIÓN DE FRASES PREDEFINIDAS ---

class FrasesAdminScreen extends StatelessWidget {
  const FrasesAdminScreen({super.key});

  Future<void> _agregarFrase(
      BuildContext context, String uid, int siguienteOrden) async {
    final controller = TextEditingController();

    final texto = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.nuevaFrase),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
              labelText: context.l10n.textoDeLaFrase,
              border: const OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.cancelar)),
          TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text(context.l10n.agregar)),
        ],
      ),
    );

    if (texto == null || texto.isEmpty) return;

    await FrasesService.agregarFrase(uid, texto, siguienteOrden);
  }

  Future<void> _editarFrase(
      BuildContext context, String uid, String id, String textoActual) async {
    final controller = TextEditingController(text: textoActual);

    final texto = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.editarFrase),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.cancelar)),
          TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text(context.l10n.guardar)),
        ],
      ),
    );

    if (texto == null || texto.isEmpty || texto == textoActual) return;

    await FrasesService.editarFrase(uid, id, texto);
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.misFrases2)),
      body: (user == null || user.isAnonymous)
          ? Center(child: Text(context.l10n.necesitasIniciarSesionParaEditar))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FrasesService.streamFrases(user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child: Text(context.l10n
                          .error(mensajeError(context.l10n, snapshot.error))));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(context.l10n.todaviaNoTenesFrasesPropias),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () =>
                              FrasesService.copiarFrasesBaseParaUsuario(
                                  user.uid),
                          child: Text(context.l10n.cargarFrasesPorDefecto),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final doc = docs[i];

                    final texto = doc.data()['texto'] as String? ?? '';

                    return ListTile(
                      title: Text(texto),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () =>
                                _editarFrase(context, user.uid, doc.id, texto),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: context.l10n.eliminar,
                            onPressed: () =>
                                FrasesService.eliminarFrase(user.uid, doc.id),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: (user == null || user.isAnonymous)
          ? null
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FrasesService.streamFrases(user.uid),
              builder: (context, snapshot) {
                final siguienteOrden = snapshot.data?.docs.length ?? 0;

                return FloatingActionButton(
                  onPressed: () =>
                      _agregarFrase(context, user.uid, siguienteOrden),
                  child: const Icon(Icons.add),
                );
              },
            ),
    );
  }
}

// --- MI REPERTORIO (BIBLIOTECA PERSONAL DE PARTITURAS) ---

class MiRepertorioScreen extends StatefulWidget {
  const MiRepertorioScreen({super.key});

  @override
  State<MiRepertorioScreen> createState() => _MiRepertorioScreenState();
}

class _MiRepertorioScreenState extends State<MiRepertorioScreen> {
  bool _subiendo = false;

  final _busquedaTituloController = TextEditingController();

  final _busquedaTonalidadController = TextEditingController();

  @override
  void dispose() {
    _busquedaTituloController.dispose();

    _busquedaTonalidadController.dispose();

    super.dispose();
  }

  Future<void> _mostrarUpsellPro(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.funcionPro),
        content: Text(context.l10n.subirTusPropiasPartiturasCifrados),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.entendido)),
        ],
      ),
    );
  }

  Future<void> _subirNuevaCancion(String uid) async {
    final esPro = kFuncionesProGratisPorAhora ||
        await UsuarioService.streamEsPro(uid).first;

    if (!esPro) {
      if (mounted) await _mostrarUpsellPro(context);

      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result == null || result.files.single.bytes == null) return;

    final archivo = result.files.single;

    if (!mounted) return;

    final cifradoExtraido = RepertorioService.extraerTextoPdf(archivo.bytes!);

    if (!mounted) return;

    final datos =
        await _pedirDatosCancion(context, cifradoInicial: cifradoExtraido);

    if (datos == null) return;

    setState(() => _subiendo = true);

    try {
      await RepertorioService.subirCancion(
        uid: uid,
        titulo: datos.$1,
        tonalidad: datos.$2,
        nombreArchivo: archivo.name,
        bytes: archivo.bytes!,
        cifradoTexto: datos.$3,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(context.l10n.errorAlSubir(e)),
              backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  Future<(String, String, String)?> _pedirDatosCancion(
    BuildContext context, {
    String? tituloInicial,
    String? tonalidadInicial,
    String? cifradoInicial,
  }) async {
    final tituloController = TextEditingController(text: tituloInicial ?? '');

    final tonalidadController =
        TextEditingController(text: tonalidadInicial ?? '');

    final cifradoController = TextEditingController(text: cifradoInicial ?? '');

    final formKey = GlobalKey<FormState>();

    return showDialog<(String, String, String)>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tituloInicial == null
            ? context.l10n.nuevaCancion
            : context.l10n.editarCancion),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: tituloController,
                    autofocus: true,
                    decoration: InputDecoration(
                        labelText: context.l10n.titulo2,
                        border: const OutlineInputBorder()),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? context.l10n.requerido
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: tonalidadController,
                    decoration: InputDecoration(
                        labelText: context.l10n.tonalidadOpcional,
                        border: const OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: cifradoController,
                    maxLines: 8,
                    style:
                        const TextStyle(fontFamily: 'RobotoMono', fontSize: 12),
                    decoration: InputDecoration(
                      labelText: context.l10n.cifradoEnTextoOpcionalPara,
                      hintText: context.l10n.pegaLosAcordesAcaEj,
                      border: const OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.cancelar)),
          TextButton(
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) return;

              Navigator.pop(context, (
                tituloController.text.trim(),
                tonalidadController.text.trim(),
                cifradoController.text.trim()
              ));
            },
            child: Text(context.l10n.guardar),
          ),
        ],
      ),
    );
  }

  Future<void> _editarCancion(String uid, String id, String tituloActual,
      String tonalidadActual, String cifradoActual) async {
    final datos = await _pedirDatosCancion(
      context,
      tituloInicial: tituloActual,
      tonalidadInicial: tonalidadActual,
      cifradoInicial: cifradoActual,
    );

    if (datos == null) return;

    await RepertorioService.editarCancion(
        uid: uid,
        cancionId: id,
        titulo: datos.$1,
        tonalidad: datos.$2,
        cifradoTexto: datos.$3);
  }

  Future<void> _regenerarCifrados(String uid) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.regenerarCifrados),
        content: Text(
          context.l10n.seVaAVolverA,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.cancelar)),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.regenerar)),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    final progreso = ValueNotifier<String>(context.l10n.preparando);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: progreso,
                  builder: (context, texto, _) => Text(texto),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final resultado = await RepertorioService.regenerarCifrados(
      uid,
      alAvanzar: (hechas, total) =>
          progreso.value = context.l10n.procesandoDe(hechas, total),
    );
    progreso.dispose();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    final partes = <String>[context.l10n.actualizadas(resultado.actualizadas)];
    if (resultado.sinTexto > 0) {
      partes.add(context.l10n.sinTextoEnElPdf(resultado.sinTexto));
    }
    if (resultado.fallidas > 0) {
      partes.add(context.l10n.conError(resultado.fallidas));
    }
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.cifrados(partes.join(', ')))));
  }

  Future<void> _confirmarEliminar(
      String uid, String id, String? storagePath) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(context.l10n.eliminarCancion),
        content: Text(context.l10n.seBorraDeTuBiblioteca),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(context.l10n.cancelar)),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(context.l10n.eliminar)),
        ],
      ),
    );

    if (confirm == true) {
      await RepertorioService.eliminarCancion(
          uid: uid, cancionId: id, storagePath: storagePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.miRepertorio2),
        actions: [
          if (user != null && !user.isAnonymous)
            IconButton(
              icon: const Icon(Icons.auto_fix_high),
              tooltip: context.l10n.regenerarCifradosDesdeLosPdf,
              onPressed: () => _regenerarCifrados(user.uid),
            ),
        ],
      ),
      body: (user == null || user.isAnonymous)
          ? Center(child: Text(context.l10n.necesitasIniciarSesionParaTener2))
          : Column(
              children: [
                StreamBuilder<bool>(
                  stream: UsuarioService.streamEsPro(user.uid),
                  builder: (context, snapshot) {
                    if (kFuncionesProGratisPorAhora || snapshot.data == true) {
                      return const SizedBox.shrink();
                    }

                    return Container(
                      width: double.infinity,
                      color: context.acento.withOpacity(0.08),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Icon(Icons.workspace_premium,
                              color: context.acento, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.l10n.subirTusPropiasPartiturasEs,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _mostrarUpsellPro(context),
                            child: Text(context.l10n.masInfo,
                                style: const TextStyle(fontSize: 14)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _busquedaTituloController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: context.l10n.titulo,
                            isDense: true,
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: _busquedaTituloController.text.isEmpty
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    tooltip: context.l10n.borrarBusqueda,
                                    onPressed: () => setState(() =>
                                        _busquedaTituloController.clear()),
                                  ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _busquedaTonalidadController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: context.l10n.tonalidad,
                            isDense: true,
                            prefixIcon: const Icon(Icons.music_note, size: 20),
                            suffixIcon: _busquedaTonalidadController
                                    .text.isEmpty
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    tooltip: context.l10n.borrarBusqueda,
                                    onPressed: () => setState(() =>
                                        _busquedaTonalidadController.clear()),
                                  ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: RepertorioService.streamRepertorio(user.uid),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                            child: Text(context.l10n.error(
                                mensajeError(context.l10n, snapshot.error))));
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final todasLasCanciones =
                          RepertorioService.ordenarPorTitulo(
                                  snapshot.data!.docs)
                              .map((d) => {...d.data(), 'id': d.id})
                              .toList();

                      final docs = RepertorioService.filtrarPorTituloYTonalidad(
                        todasLasCanciones,
                        titulo: _busquedaTituloController.text,
                        tonalidad: _busquedaTonalidadController.text,
                      );

                      if (docs.isEmpty) {
                        return Center(
                          child: Text(
                            todasLasCanciones.isEmpty
                                ? context.l10n.todaviaNoSubisteNingunaCancion
                                : context.l10n.sinResultados,
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final data = docs[i];

                          final id = data['id'] as String;

                          final titulo = data['titulo'] as String? ?? '';

                          final tonalidad = data['tonalidad'] as String? ?? '';

                          final pdfUrl = data['pdfUrl'] as String? ?? '';

                          final cifradoTexto =
                              data['cifradoTexto'] as String? ?? '';

                          return ListTile(
                            leading: Icon(Icons.picture_as_pdf,
                                color: context.acento),
                            title: Text(titulo),
                            subtitle: tonalidad.isNotEmpty
                                ? Text(context.l10n.tonalidad2(tonalidad))
                                : null,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => PdfViewerScreen(
                                      titulo: titulo, pdfUrl: pdfUrl)),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (cifradoTexto.isNotEmpty)
                                  IconButton(
                                    icon: Icon(Icons.music_note,
                                        color: context.acento),
                                    tooltip: context.l10n.verCifradoTransponer,
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CifradoViewerScreen(
                                          titulo: titulo,
                                          cifradoOriginal: cifradoTexto,
                                          pdfUrl: pdfUrl,
                                          versionCifrado:
                                              data['cifradoVersion'] as int?,
                                          alRegenerar: (texto) =>
                                              RepertorioService
                                                  .guardarCifradoRegenerado(
                                                      user.uid, id, texto),
                                        ),
                                      ),
                                    ),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blue),
                                  onPressed: () => _editarCancion(user.uid, id,
                                      titulo, tonalidad, cifradoTexto),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  tooltip: context.l10n.eliminar,
                                  onPressed: () => _confirmarEliminar(user.uid,
                                      id, data['storagePath'] as String?),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: (user == null || user.isAnonymous || _subiendo)
          ? (_subiendo
              ? const FloatingActionButton(
                  onPressed: null,
                  child: CircularProgressIndicator(color: Colors.white))
              : null)
          : FloatingActionButton(
              onPressed: () => _subirNuevaCancion(user.uid),
              child: const Icon(Icons.upload_file),
            ),
    );
  }
}

// --- MIS SECUENCIAS (BIBLIOTECA PERSONAL DE PISTAS DE AUDIO) ---

class MisSecuenciasScreen extends StatefulWidget {
  const MisSecuenciasScreen({super.key});

  @override
  State<MisSecuenciasScreen> createState() => _MisSecuenciasScreenState();
}

class _MisSecuenciasScreenState extends State<MisSecuenciasScreen> {
  final _reproductor = ReproductorSecuencias();
  final _busquedaController = TextEditingController();
  bool _subiendo = false;
  String _progresoSubida = '';

  @override
  void dispose() {
    _reproductor.dispose();
    _busquedaController.dispose();
    super.dispose();
  }

  /// Permite elegir varios audios a la vez; el título de cada uno sale del
  /// nombre del archivo (se puede renombrar después).
  Future<void> _subirSecuencias(String uid) async {
    final esPro = kFuncionesProGratisPorAhora ||
        await UsuarioService.streamEsPro(uid).first;
    if (!esPro) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.funcionPro),
          content: Text(context.l10n.subirTusPropiasSecuenciasEs),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.l10n.entendido))
          ],
        ),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: SecuenciasService.extensionesPermitidas,
      allowMultiple: true,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    // Supabase gratis rechaza los archivos de más de 50 MB con un error poco
    // claro. En web se convierten a MP3 antes de subirlos; fuera de la web
    // (sin conversor) se avisa acá y se sigue con los demás.
    const limite = SecuenciasService.tamanoMaximoBytes;
    var aSubir = result.files;
    if (!puente.conversorMp3Disponible) {
      final grandes = result.files.where((a) => a.size > limite).toList();
      aSubir = result.files.where((a) => a.size <= limite).toList();
      if (grandes.isNotEmpty) {
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(grandes.length == 1
                ? context.l10n.archivoDemasiadoGrande
                : context.l10n.archivosDemasiadoGrandes),
            content: Text(
              context.l10n.elMaximoPorArchivoEs(
                  grandes
                      .map((a) =>
                          '• ${a.name} (${SecuenciasService.formatearMb(a.size)})')
                      .join('\n'),
                  SecuenciasService.formatearMb(limite)),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.l10n.entendido))
            ],
          ),
        );
      }
    }
    if (aSubir.isEmpty) return;

    setState(() => _subiendo = true);
    final errores = <String>[];
    final convertidos = <String>[];
    try {
      for (var i = 0; i < aSubir.length; i++) {
        final archivo = aSubir[i];
        if (archivo.bytes == null) continue;
        final contador =
            aSubir.length > 1 ? ' (${i + 1}/${aSubir.length})' : '';
        final punto = archivo.name.lastIndexOf('.');
        final titulo =
            punto > 0 ? archivo.name.substring(0, punto) : archivo.name;
        var nombreArchivo = archivo.name;
        var bytes = archivo.bytes!;
        try {
          if (bytes.length > limite) {
            setState(() =>
                _progresoSubida = context.l10n.convirtiendoAMp3(contador));
            final mp3 = await puente.convertirAMp3(
              bytes,
              SecuenciasService.tamanoObjetivoMp3Bytes,
              (p) {
                if (mounted) {
                  setState(() => _progresoSubida = context.l10n
                      .convirtiendoAMp32((p * 100).round(), contador));
                }
              },
            );
            bytes = mp3.bytes;
            nombreArchivo = '$titulo.mp3';
            convertidos.add(
                '$titulo (${SecuenciasService.formatearMb(archivo.size)} → '
                '${SecuenciasService.formatearMb(bytes.length)}, ${mp3.kbps} kbps)');
          }
          setState(() => _progresoSubida = context.l10n.subiendo(contador));
          await SecuenciasService.subirSecuencia(
            uid: uid,
            titulo: titulo,
            nombreArchivo: nombreArchivo,
            bytes: bytes,
          );
        } catch (e) {
          debugPrint('No se pudo subir ${archivo.name}: $e');
          errores.add('${archivo.name}: $e');
        }
      }
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
    if (!mounted) return;
    if (convertidos.isNotEmpty || errores.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(errores.isEmpty
              ? context.l10n.secuenciasSubidas
              : context.l10n.algunasSecuenciasNoSeSubieron),
          content: SingleChildScrollView(
            child: Text([
              if (convertidos.isNotEmpty)
                context.l10n.seConvirtieronAMp3Porque(
                    SecuenciasService.formatearMb(limite),
                    convertidos.map((c) => '• $c').join('\n')),
              if (errores.isNotEmpty)
                context.l10n
                    .noSePudieronSubir(errores.map((e) => '• $e').join('\n')),
            ].join('\n\n')),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.l10n.entendido))
          ],
        ),
      );
    }
  }

  Future<void> _renombrar(String uid, String id, String tituloActual) async {
    final controller = TextEditingController(text: tituloActual);
    final nuevo = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.renombrarSecuencia),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: context.l10n.titulo2),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.cancelar)),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text(context.l10n.guardar)),
        ],
      ),
    );
    if (nuevo == null || nuevo.trim().isEmpty) return;
    await SecuenciasService.renombrarSecuencia(uid, id, nuevo.trim());
  }

  Future<void> _confirmarEliminar(
      String uid, String id, String titulo, String? storagePath) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.eliminarSecuencia),
        content: Text(context.l10n.eliminarDeTuBiblioteca(titulo)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.cancelar)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.eliminar,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (_reproductor.idActual == id) await _reproductor.detener();
    await SecuenciasService.eliminarSecuencia(uid, id, storagePath);
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.misSecuencias2)),
      body: (user == null || user.isAnonymous)
          ? Center(child: Text(context.l10n.necesitasIniciarSesionParaTener3))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _busquedaController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: context.l10n.buscarSecuencia,
                      isDense: true,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: SecuenciasService.streamMisSecuencias(user.uid),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                            child: Text(context.l10n
                                .errorAlCargar('${snapshot.error}')));
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = RepertorioService.ordenarPorTitulo(
                          snapshot.data!.docs);
                      if (docs.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              context.l10n.todaviaNoSubisteSecuenciasToca,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      final secuencias =
                          docs.map((d) => {...d.data(), 'id': d.id}).toList();
                      final filtradas =
                          RepertorioService.filtrarPorTituloYTonalidad(
                        secuencias,
                        titulo: _busquedaController.text,
                        tonalidad: '',
                      );
                      if (filtradas.isEmpty) {
                        return Center(child: Text(context.l10n.sinResultados));
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: filtradas.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final data = filtradas[i];
                          final id = data['id'] as String;
                          final titulo = data['titulo'] as String? ?? '';
                          return FilaSecuencia(
                            reproductor: _reproductor,
                            id: id,
                            titulo: titulo,
                            audioUrl: data['audioUrl'] as String? ?? '',
                            acciones: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  tooltip: context.l10n.renombrar,
                                  onPressed: () =>
                                      _renombrar(user.uid, id, titulo),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  tooltip: context.l10n.eliminar,
                                  onPressed: () => _confirmarEliminar(
                                      user.uid,
                                      id,
                                      titulo,
                                      data['storagePath'] as String?),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: (user == null || user.isAnonymous)
          ? null
          : FloatingActionButton.extended(
              onPressed: _subiendo ? null : () => _subirSecuencias(user.uid),
              icon: _subiendo
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.upload_file),
              label: Text(
                  _subiendo ? _progresoSubida : context.l10n.subirSecuencias),
            ),
    );
  }
}

// --- VISOR DE CIFRADO (TEXTO CON ACORDES TRANSPONIBLES) ---

class CifradoViewerScreen extends StatefulWidget {
  final String titulo;

  final String cifradoOriginal;

  /// Si codigoSala e itemId vienen los dos, la transposición se sincroniza

  /// en vivo con todos los que estén viendo el mismo tema en esa sala

  /// (vía salas/{codigoSala}/setlist/{itemId}.transposicion). Si vienen

  /// null (ej. abierto desde Mi Repertorio, fuera de una sala), la

  /// transposición queda local a esta pantalla, como era antes.

  final String? codigoSala;

  final String? itemId;

  /// Lista ordenada de temas del setlist actual e índice de este tema en

  /// esa lista, para pasar al siguiente/anterior con un swipe horizontal.

  /// Igual que en PdfViewerScreen, quedan null fuera de un setlist de sala.

  final List<Map<String, dynamic>>? setlistItems;

  final int? indiceEnSetlist;

  /// Swipe hacia arriba: volver a la pestaña de Pedidos de la sala.

  final void Function(Widget visorActual)? onIrAPedidos;

  /// El sonidista puede ver el cifrado en el tono que esté sincronizado,
  /// pero no cambiarlo — eso queda a criterio de los músicos/cantantes.
  final bool puedeTransponer;

  /// Si el cifrado guardado viene del extractor viejo (versionCifrado nula o
  /// menor a kVersionCifrado) se vuelve a extraer del PDF al abrir el visor,
  /// con la posición real de los acordes, y se pide guardarlo con
  /// [alRegenerar] para que la próxima vez ya esté bien. Sin [pdfUrl] se
  /// muestra el texto guardado tal cual.
  final String? pdfUrl;

  final int? versionCifrado;

  final Future<void> Function(String texto)? alRegenerar;

  const CifradoViewerScreen({
    super.key,
    required this.titulo,
    required this.cifradoOriginal,
    this.codigoSala,
    this.itemId,
    this.setlistItems,
    this.indiceEnSetlist,
    this.onIrAPedidos,
    this.puedeTransponer = true,
    this.pdfUrl,
    this.versionCifrado,
    this.alRegenerar,
  });

  bool get sincronizada => codigoSala != null && itemId != null;

  @override
  State<CifradoViewerScreen> createState() => _CifradoViewerScreenState();
}

class _CifradoViewerScreenState extends State<CifradoViewerScreen> {
  /// Cifrado re-extraído del PDF (ver CifradoViewerScreen.pdfUrl); mientras
  /// es null o no llegó, se muestra el texto guardado.
  String? _cifradoRegenerado;

  @override
  void initState() {
    super.initState();

    _regenerarSiHaceFalta();
  }

  Future<void> _regenerarSiHaceFalta() async {
    final url = widget.pdfUrl;

    if (url == null || url.isEmpty) return;

    if ((widget.versionCifrado ?? 1) >= kVersionCifrado) return;

    try {
      final respuesta = await http.get(Uri.parse(url));

      if (respuesta.statusCode != 200) return;

      final texto = RepertorioService.extraerTextoPdf(respuesta.bodyBytes);

      // Un PDF sin texto seleccionable (escaneo/foto) no pisa lo guardado.
      if (texto.isEmpty) return;

      if (mounted) setState(() => _cifradoRegenerado = texto);

      await widget.alRegenerar?.call(texto);
    } catch (e) {
      debugPrint('No se pudo regenerar el cifrado desde el PDF: $e');
    }
  }

  int _semitonosLocal = 0;

  /// Solo tiene sentido cuando widget.sincronizada es true: permite que

  /// esta pantalla puntual deje de seguir/escribir la transposición

  /// compartida de la sala sin afectar a los demás (ej. para mirar la

  /// canción en otro tono un momento sin descuadrar al resto de la banda).

  bool _sincronizado = true;

  void _toggleSincronizado(int semitonosActuales) {
    setState(() {
      _sincronizado = !_sincronizado;

      if (!_sincronizado) _semitonosLocal = semitonosActuales;
    });
  }

  void _cambiarSemitonos(int nuevo) {
    if (widget.sincronizada && _sincronizado) {
      SetlistService.actualizarTransposicion(
          widget.codigoSala!, widget.itemId!, nuevo);
    } else {
      setState(() => _semitonosLocal = nuevo);
    }
  }

  final _swipe = DetectorSwipe();

  final _scrollVertical = ScrollController();

  final _scrollHorizontal = ScrollController();

  /// Posición del scroll cuando se apoyó el dedo: si al levantarlo cambió,
  /// el gesto fue para desplazarse por la letra, no un swipe (sin esto,
  /// bajar por la letra arrastrando hacia arriba volvía a Pedidos).
  Offset _scrollAlBajar = Offset.zero;

  Offset get _posicionScroll => Offset(
        _scrollHorizontal.hasClients ? _scrollHorizontal.offset : 0,
        _scrollVertical.hasClients ? _scrollVertical.offset : 0,
      );

  @override
  void dispose() {
    _scrollVertical.dispose();
    _scrollHorizontal.dispose();
    super.dispose();
  }

  void _navegarAIndice(int indice) {
    final item = widget.setlistItems![indice];

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CifradoViewerScreen(
          titulo: item['titulo'] as String,
          cifradoOriginal: item['cifradoTexto'] as String? ?? '',
          codigoSala: widget.codigoSala,
          itemId: item['id'] as String?,
          setlistItems: widget.setlistItems,
          indiceEnSetlist: indice,
          onIrAPedidos: widget.onIrAPedidos,
          puedeTransponer: widget.puedeTransponer,
          pdfUrl: item['pdfUrl'] as String?,
          versionCifrado: item['cifradoVersion'] as int?,
          alRegenerar: widget.sincronizada && item['id'] != null
              ? (texto) => SetlistService.actualizarCifrado(
                  widget.codigoSala!, item['id'] as String, texto)
              : null,
        ),
      ),
    );
  }

  void _manejarSwipe(PointerUpEvent evento) {
    final delta = _swipe.alSubir(evento);

    if (delta == null) return;

    // Si la letra se desplazó, el usuario estaba haciendo scroll. El swipe
    // vale solo cuando no había más para desplazar en esa dirección.
    if ((_posicionScroll - _scrollAlBajar).distance > 2) return;

    const umbral = 80.0;

    if (delta.dx.abs() > delta.dy.abs()) {
      if (delta.dx.abs() < umbral ||
          widget.setlistItems == null ||
          widget.indiceEnSetlist == null) {
        return;
      }

      final nuevoIndice = widget.indiceEnSetlist! + (delta.dx < 0 ? 1 : -1);

      if (nuevoIndice < 0 || nuevoIndice >= widget.setlistItems!.length) return;

      _navegarAIndice(nuevoIndice);
    } else {
      if (delta.dy >= 0 || delta.dy.abs() < umbral) return;

      widget.onIrAPedidos?.call(widget);
    }
  }

  Widget _construirVisor(BuildContext context, int semitonos) {
    final texto = ChordTransposer.transponerTexto(
        _cifradoRegenerado ?? widget.cifradoOriginal, semitonos);

    final etiquetaSemitonos =
        semitonos == 0 ? '0' : (semitonos > 0 ? '+$semitonos' : '$semitonos');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titulo, overflow: TextOverflow.ellipsis),
        actions: [
          if (widget.puedeTransponer)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              tooltip: context.l10n.bajarUnSemitono,
              onPressed: () => _cambiarSemitonos(semitonos - 1),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Center(
              child: Text(etiquetaSemitonos,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
          if (widget.puedeTransponer) ...[
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: context.l10n.subirUnSemitono,
              onPressed: () => _cambiarSemitonos(semitonos + 1),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: context.l10n.restablecerTonoOriginal,
              onPressed: semitonos == 0 ? null : () => _cambiarSemitonos(0),
            ),
            if (widget.sincronizada)
              IconButton(
                icon: Icon(_sincronizado ? Icons.sync : Icons.sync_disabled),
                color: _sincronizado ? Colors.green : Colors.red,
                tooltip: _sincronizado
                    ? context.l10n.sincronizadoConTodaLaSala
                    : context.l10n.desincronizadoCambiosSoloLocalesToca,
                onPressed: () => _toggleSincronizado(semitonos),
              ),
          ],
        ],
      ),
      body: Listener(
        onPointerDown: (evento) {
          _swipe.alBajar(evento);
          _scrollAlBajar = _posicionScroll;
        },

        onPointerUp: _manejarSwipe,

        onPointerCancel: _swipe.alCancelar,

        // Los acordes quedan alineados con la letra solo si ninguna línea se
        // parte en dos: se achica la letra para que entre el renglón más
        // largo (Roboto Mono mide 0,6 veces su tamaño de ancho por carácter)
        // y, si aun así no entra, se puede desplazar hacia el costado.
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columnas =
                texto.split('\n').fold<int>(0, (m, l) => max(m, l.length));

            final disponible = constraints.maxWidth - 32;

            final tamano = columnas == 0
                ? 14.0
                : (disponible / (columnas * 0.6)).clamp(9.0, 14.0);

            // Ocupa toda la pantalla aunque la letra sea corta: si no, el
            // scroll medía solo lo que el texto y el swipe no funcionaba
            // sobre el espacio vacío de abajo.
            return SizedBox.expand(
              child: SingleChildScrollView(
                controller: _scrollVertical,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.puedeTransponer &&
                        !ChordTransposer.hayAcordes(texto))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          context.l10n.noHayAcordesParaTransponer,
                          style: TextStyle(
                              color: context.acento,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    SingleChildScrollView(
                      controller: _scrollHorizontal,
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        texto,
                        style: TextStyle(
                            fontFamily: 'RobotoMono',
                            fontSize: tamano,
                            height: 1.6),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.sincronizada || !_sincronizado) {
      return _construirVisor(context, _semitonosLocal);
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('salas')
          .doc(widget.codigoSala)
          .collection('setlist')
          .doc(widget.itemId)
          .snapshots(),
      builder: (context, snapshot) {
        final semitonos = snapshot.data?.data()?['transposicion'] as int? ?? 0;

        return _construirVisor(context, semitonos);
      },
    );
  }
}

// --- VISOR DE PDF ---

class PdfViewerScreen extends StatefulWidget {
  final String titulo;

  final String pdfUrl;

  /// Lista ordenada de temas del setlist actual ([{id, titulo, pdfUrl,

  /// cifradoTexto}]) e índice de este tema en esa lista, para poder pasar

  /// al siguiente/anterior con un swipe horizontal. Quedan null si se

  /// abrió fuera de un setlist de sala (ej. desde Mi Repertorio).

  final List<Map<String, dynamic>>? setlistItems;

  final int? indiceEnSetlist;

  final String? codigoSala;

  /// Swipe hacia arriba: volver a la pestaña de Pedidos de la sala.

  final void Function(Widget visorActual)? onIrAPedidos;

  const PdfViewerScreen({
    super.key,
    required this.titulo,
    required this.pdfUrl,
    this.setlistItems,
    this.indiceEnSetlist,
    this.codigoSala,
    this.onIrAPedidos,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? _error;

  final _swipe = DetectorSwipe();

  /// Nivel de zoom actual del PDF. Con zoom, un dedo que arrastra sirve para
  /// moverse por la página, no para cambiar de tema.
  double _zoom = 1.0;

  final _pdfController = PdfViewerController();

  /// Posición del scroll del PDF cuando se apoyó el dedo: si al levantarlo
  /// cambió, el gesto fue para pasar de página, no un swipe (sin esto,
  /// bajar por un PDF de varias páginas volvía a Pedidos).
  Offset _scrollAlBajar = Offset.zero;

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  void _navegarAIndice(int indice) {
    final item = widget.setlistItems![indice];

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(
          titulo: item['titulo'] as String,
          pdfUrl: item['pdfUrl'] as String,
          setlistItems: widget.setlistItems,
          indiceEnSetlist: indice,
          codigoSala: widget.codigoSala,
          onIrAPedidos: widget.onIrAPedidos,
        ),
      ),
    );
  }

  /// Detecta el swipe con Listener (no GestureDetector) para que no

  /// compita por el gesto con el pan/zoom interno de SfPdfViewer.

  void _manejarSwipe(PointerUpEvent evento) {
    final delta = _swipe.alSubir(evento);

    if (delta == null || _zoom > 1.05) return;

    // Si el PDF se desplazó, el usuario estaba haciendo scroll. El swipe
    // vale solo cuando no había más para desplazar en esa dirección.
    if ((_pdfController.scrollOffset - _scrollAlBajar).distance > 2) return;

    const umbral = 80.0;

    if (delta.dx.abs() > delta.dy.abs()) {
      if (delta.dx.abs() < umbral ||
          widget.setlistItems == null ||
          widget.indiceEnSetlist == null) {
        return;
      }

      final nuevoIndice = widget.indiceEnSetlist! + (delta.dx < 0 ? 1 : -1);

      if (nuevoIndice < 0 || nuevoIndice >= widget.setlistItems!.length) return;

      _navegarAIndice(nuevoIndice);
    } else {
      if (delta.dy >= 0 || delta.dy.abs() < umbral) return;

      widget.onIrAPedidos?.call(widget);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.titulo, overflow: TextOverflow.ellipsis),
      ),
      body: Listener(
        onPointerDown: (evento) {
          _swipe.alBajar(evento);
          _scrollAlBajar = _pdfController.scrollOffset;
        },
        onPointerUp: _manejarSwipe,
        onPointerCancel: _swipe.alCancelar,
        child: _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.redAccent, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        context.l10n.noSePudoCargarEl('$_error'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              )
            : SfPdfViewer.network(
                widget.pdfUrl,
                controller: _pdfController,
                onZoomLevelChanged: (details) => _zoom = details.newZoomLevel,
                onDocumentLoadFailed: (details) {
                  setState(() => _error = details.description);
                },
              ),
      ),
    );
  }
}

// --- ACCESO SONIDISTA ---

class SonidistaPinScreen extends StatefulWidget {
  const SonidistaPinScreen({super.key});

  @override
  State<SonidistaPinScreen> createState() => _SonidistaPinScreenState();
}

class _SonidistaPinScreenState extends State<SonidistaPinScreen> {
  final _pinController = TextEditingController();

  bool _intentado = false;

  bool _procesando = false;

  Future<void> _ingresarComoSonidista() async {
    final pin = _pinController.text.trim().toUpperCase();

    setState(() => _intentado = true);

    if (pin.isEmpty || _procesando) return;

    setState(() => _procesando = true);

    try {
      await AuthService.asegurarSesion();

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('tipo_login', 'sonidista');

      await prefs.setString('sala_id', pin);

      await _registrarSalaSiCorresponde(codigoSala: pin, rolUsado: 'Sonidista');

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => SonidistaPage(codigoSala: pin)),
        (route) => false,
      );
    } catch (e) {
      setState(() => _procesando = false);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            context.l10n.errorAlIngresarAlPanel(mensajeError(context.l10n, e))),
        action: SnackBarAction(
            label: context.l10n.reintentar, onPressed: _ingresarComoSonidista),
      ));
    }
  }

  @override
  void dispose() {
    _pinController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.accesoSonidista2)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _pinController,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              onChanged: (_) {
                if (_intentado) setState(() {});
              },
              onSubmitted: (_) => _ingresarComoSonidista(),
              decoration: InputDecoration(
                labelText: context.l10n.pinDeSalaOCrear,
                errorText: _intentado && _pinController.text.trim().isEmpty
                    ? context.l10n.escribiElPin
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _procesando ? null : _ingresarComoSonidista,
                child: _procesando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(context.l10n.accederAlPanel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- PANEL DE CONTROL DEL SONIDISTA ---

/// Envuelve un pedido urgente sin atender con un fondo rojo que
/// parpadea, para que se note aunque el sonidista no esté mirando
/// la pantalla en el momento exacto en que llegó.
class _UrgentBlink extends StatefulWidget {
  final Widget child;

  const _UrgentBlink({required this.child});

  @override
  State<_UrgentBlink> createState() => _UrgentBlinkState();
}

class _UrgentBlinkState extends State<_UrgentBlink>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) => Container(
        color: Colors.redAccent.withOpacity(0.08 + _controller.value * 0.22),
        child: child,
      ),
    );
  }
}

class SonidistaPage extends StatefulWidget {
  final String codigoSala;

  const SonidistaPage({super.key, required this.codigoSala});

  @override
  State<SonidistaPage> createState() => _SonidistaPageState();
}

class _SonidistaPageState extends State<SonidistaPage>
    with TickerProviderStateMixin {
  bool _pantallaEncendida = true;

  bool _agruparPorRol = false;

  final AudioPlayer _alertaPlayer = AudioPlayer();

  StreamSubscription<QuerySnapshot>? _pedidosSub;

  bool _primerSnapshotPedidos = true;

  /// Se vuelve a crear cuando el usuario cambia las pestañas visibles (por
  /// eso TickerProviderStateMixin y no SingleTicker...).
  late TabController _tabController;

  static const _todasLasPestanas = [
    PestanaSala.pedidos,
    PestanaSala.historial,
    PestanaSala.setlist,
    PestanaSala.secuencias,
  ];

  List<PestanaSala> _pestanas = _todasLasPestanas;

  /// Último visor de PDF/cifrado abierto desde el setlist, para poder

  /// volver a él con un swipe hacia abajo desde la pestaña de Pedidos.

  Widget? _ultimoVisor;

  Offset? _inicioArrastrePedidos;

  @override
  void initState() {
    super.initState();

    WakelockPlus.enable();

    MiembrosSalaService.registrarPresencia(widget.codigoSala).catchError(
        (e) => debugPrint('No se pudo registrar presencia en la sala: $e'));

    _escucharPedidosNuevos();

    _tabController = TabController(length: _pestanas.length, vsync: this);

    PestanasSalaService.cargar('sonidista', _todasLasPestanas).then((elegidas) {
      if (mounted) _aplicarPestanas(elegidas);
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();

    _pedidosSub?.cancel();

    _alertaPlayer.dispose();

    _tabController.dispose();

    super.dispose();
  }

  /// Cambia las pestañas visibles quedándose, si sigue visible, en la que
  /// se estaba mirando. El aviso sonoro de pedidos nuevos sigue andando
  /// aunque la pestaña de Pedidos esté oculta.
  void _aplicarPestanas(List<PestanaSala> nuevas) {
    if (listEquals(nuevas, _pestanas)) return;
    final actual = _pestanas[_tabController.index];
    final indice = nuevas.indexOf(actual);
    _tabController.dispose();
    setState(() {
      _pestanas = nuevas;
      _tabController = TabController(
          length: nuevas.length,
          vsync: this,
          initialIndex: indice < 0 ? 0 : indice);
    });
  }

  Future<void> _elegirPestanas() async {
    final elegidas = await elegirPestanasSala(context,
        todas: _todasLasPestanas, visibles: _pestanas);
    if (elegidas == null || !mounted) return;
    await PestanasSalaService.guardar('sonidista', elegidas);
    _aplicarPestanas(elegidas);
  }

  /// Swipe hacia arriba en el visor de PDF/cifrado: vuelve a la sala y, si
  /// la pestaña de Pedidos está visible, la muestra.
  void _irAPedidos(Widget visorActual) {
    _ultimoVisor = visorActual;

    Navigator.pop(context);

    final pedidos = _pestanas.indexOf(PestanaSala.pedidos);

    if (pedidos >= 0) _tabController.animateTo(pedidos);
  }

  void _manejarSwipeAbajoEnPedidos(PointerUpEvent evento) {
    if (_inicioArrastrePedidos == null || _ultimoVisor == null) return;

    final delta = evento.position - _inicioArrastrePedidos!;

    _inicioArrastrePedidos = null;

    if (delta.dy > 80 && delta.dy.abs() > delta.dx.abs()) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => _ultimoVisor!));
    }
  }

  /// Escucha la misma colección que el StreamBuilder de abajo, pero solo

  /// para detectar altas (DocumentChangeType.added) y disparar la alerta.

  /// El primer snapshot (carga inicial de la sala) no cuenta como "nuevo".

  void _escucharPedidosNuevos() {
    _pedidosSub = FirebaseFirestore.instance
        .collection('salas')
        .doc(widget.codigoSala)
        .collection('pedidos')
        .orderBy('createdAt', descending: true)
        .limit(kMaximoPedidosVisibles)
        .snapshots()
        .listen((snapshot) {
      if (_primerSnapshotPedidos) {
        _primerSnapshotPedidos = false;

        return;
      }

      final hayPedidoNuevo =
          snapshot.docChanges.any((c) => c.type == DocumentChangeType.added);

      if (hayPedidoNuevo) _notificarPedidoNuevo();
    });
  }

  void _notificarPedidoNuevo() {
    HapticFeedback
        .vibrate(); // No-op en la mayoría de navegadores web; útil cuando haya app Android/iOS.

    _alertaPlayer.play(AssetSource('sounds/pedido_nuevo.wav'));
  }

  void _togglePantallaEncendida() {
    setState(() => _pantallaEncendida = !_pantallaEncendida);

    if (_pantallaEncendida) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    await borrarSesionDeSala();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const IngressMenuScreen()),
      (route) => false,
    );
  }

  static const List<Color> _paletaRemitentes = [
    Colors.blue,
    Colors.teal,
    Colors.deepOrange,
    Colors.purple,
    Colors.brown,
    Colors.indigo,
    Colors.pink,
    Colors.green,
  ];

  /// Color determinístico por remitente (nombre + rol), así cada persona

  /// se ve siempre con el mismo color mientras dura la sala.

  Color _colorPorRemitente(String nombre, String rol) {
    final clave = '$nombre|$rol';

    final hash = clave.codeUnits.fold<int>(0, (acc, c) => acc + c);

    return _paletaRemitentes[hash % _paletaRemitentes.length];
  }

  Widget _buildPedidoTile(QueryDocumentSnapshot d) {
    final data = d.data() as Map<String, dynamic>;

    final isAtendido = data['atendido'] ?? false;

    final pedidoTexto = data['pedido'] ?? '';

    final respuestaActual = data['respuesta'] ?? '';

    final esUrgente = data['urgente'] ?? false;

    final nombre = (data['nombre'] ?? '').toString();

    final rol = (data['rol'] ?? '').toString();

    final tile = ListTile(
      tileColor: isAtendido
          ? Colors.transparent
          : (esUrgente
              ? Colors.redAccent.withOpacity(0.12)
              : context.acento.withOpacity(0.05)),
      leading: esUrgente && !isAtendido
          ? const Icon(Icons.warning_amber_rounded, color: Colors.redAccent)
          : CircleAvatar(
              radius: 15,
              backgroundColor: _colorPorRemitente(nombre, rol),
              child: Text(
                nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold),
              ),
            ),
      title: Text(
        pedidoTexto,
        style: TextStyle(
          fontWeight: isAtendido ? FontWeight.normal : FontWeight.bold,
          fontSize: 16,
          color: esUrgente && !isAtendido ? Colors.redAccent.shade700 : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$nombre (${rolParaMostrar(context.l10n, rol)})'),
          if (respuestaActual.isNotEmpty)
            Text(context.l10n.tuRespuesta(respuestaActual),
                style: TextStyle(
                    color: context.acento,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
                respuestaActual.isNotEmpty
                    ? Icons.chat
                    : Icons.chat_bubble_outline,
                color: Colors.blue),
            tooltip: context.l10n.responderPrivado,
            onPressed: () => _mostrarDialogoRespuesta(
                context, d.id, pedidoTexto, nombre.isEmpty ? 'Músico' : nombre),
          ),
          IconButton(
            icon: Icon(
                isAtendido ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isAtendido ? Colors.green : Colors.grey),
            tooltip: context.l10n.marcarAtendido,
            onPressed: () async {
              try {
                await d.reference.update({'atendido': !isAtendido});
              } catch (e) {
                if (!mounted) return;
                final yaNoExiste = '$e'.contains('not-found');
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(yaNoExiste
                      ? context.l10n.pedidoYaNoExiste
                      : mensajeError(context.l10n, e)),
                ));
              }
            },
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: context.l10n.eliminar,
            onPressed: () async {
              // Se borra enseguida pero se puede deshacer. El pedido se vuelve a
              // leer ANTES de borrarlo: la copia de la pantalla puede estar vieja
              // si otro sonidista lo cambió (ver D-07 en REQUISITOS.md).
              final ref = d.reference;
              final messenger = ScaffoldMessenger.of(context);
              final l = context.l10n;
              Map<String, dynamic> actual = data;
              try {
                final snap = await ref.get();
                if (!snap.exists) {
                  messenger.showSnackBar(
                      SnackBar(content: Text(l.pedidoYaNoExiste)));
                  return;
                }
                actual = (snap.data() as Map<String, dynamic>?) ?? data;
                await ref.delete();
              } catch (e) {
                messenger
                    .showSnackBar(SnackBar(content: Text(mensajeError(l, e))));
                return;
              }
              messenger.hideCurrentSnackBar();
              messenger.showSnackBar(SnackBar(
                content: Text(l.pedidoEliminado),
                duration: const Duration(seconds: 6),
                action: SnackBarAction(
                  label: l.deshacer,
                  onPressed: () async {
                    // Si otro sonidista ya lo volvió a crear, no se pisa.
                    if (!(await ref.get()).exists) await ref.set(actual);
                  },
                ),
              ));
            },
          ),
        ],
      ),
    );

    return esUrgente && !isAtendido ? _UrgentBlink(child: tile) : tile;
  }

  void _mostrarDialogoRespuesta(BuildContext context, String pedidoId,
      String pedidoTexto, String musico) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.responderA(musico),
            style: const TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.pedido(pedidoTexto),
                style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                    fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: context.l10n.escribirRespuestaPrivada,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.cancelar)),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await FirestoreService.responderPedido(
                    widget.codigoSala, pedidoId, controller.text.trim());
              }

              if (context.mounted) Navigator.pop(context);
            },
            child: Text(context.l10n.enviar),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Dos líneas ("Consola" arriba, el PIN abajo): en un celular no entra
        // "Consola: PIN" en una sola línea con los cuatro íconos de la derecha.
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n
                  .consola2('')
                  .replaceAll(RegExp(r'\s*[:：]\s*$'), '')
                  .trim(),
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                widget.codigoSala,
                maxLines: 1,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1),
              ),
            ),
          ],
        ),

        leading: IconButton(
          icon: const Icon(Icons.exit_to_app),
          tooltip: context.l10n.salirDeLaSala,
          onPressed: () async {
            if (await confirmarSalidaSala(context) && context.mounted) {
              _cerrarSesion(context);
            }
          },
        ),

        actions: [
          IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
              tooltip: context.l10n.borrarTodosLosPedidos,
              onPressed: () async {
                final confirm = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                            title: Text(context.l10n.borrarTodo),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(c, false),
                                  child: Text(context.l10n.no)),
                              TextButton(
                                  onPressed: () => Navigator.pop(c, true),
                                  child: Text(context.l10n.si)),
                            ]));

                if (confirm == true) {
                  await FirestoreService.borrarTodo(widget.codigoSala);
                }
              }),
          IconButton(
            icon: Icon(
                _agruparPorRol ? Icons.groups : Icons.format_list_bulleted),
            tooltip: _agruparPorRol
                ? context.l10n.agrupadoPorRolActivado
                : context.l10n.verAgrupadoPorRol,
            onPressed: () => setState(() => _agruparPorRol = !_agruparPorRol),
          ),
          IconButton(
            icon: Icon(
                _pantallaEncendida ? Icons.lightbulb : Icons.lightbulb_outline),
            tooltip: _pantallaEncendida
                ? context.l10n.pantallaSiempreEncendidaActivado
                : context.l10n.pantallaSiempreEncendidaDesactivado,
            onPressed: _togglePantallaEncendida,
          ),
          IconButton(
            icon: const Icon(Icons.view_carousel_outlined),
            tooltip: context.l10n.elegirQueVerEnLa,
            onPressed: _elegirPestanas,
          ),
        ],

        // Con una sola pestaña elegida no hace falta la barra.
        bottom: _pestanas.length < 2
            ? null
            : TabBar(
                controller: _tabController,
                // Con 4 pestañas los nombres no entran en el ancho de un
                // celular: la barra se desliza en vez de cortarlos.
                isScrollable: _pestanas.length > 3,
                tabAlignment: _pestanas.length > 3 ? TabAlignment.center : null,
                tabs: [
                  for (final p in _pestanas) Tab(text: p.etiqueta(context.l10n))
                ],
              ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _contenidoDePestanas({
          PestanaSala.pedidos: Listener(
            onPointerDown: (e) => _inicioArrastrePedidos = e.position,
            onPointerUp: _manejarSwipeAbajoEnPedidos,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('salas')
                  .doc(widget.codigoSala)
                  .collection('pedidos')
                  .orderBy('createdAt', descending: true)
                  .limit(kMaximoPedidosVisibles)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child: Text(
                          context.l10n.errorDeConexion('${snapshot.error}')));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return Center(child: Text(context.l10n.esperandoPedidos));
                }

                if (!_agruparPorRol) {
                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) => _buildPedidoTile(docs[i]),
                  );
                }

                final grupos = <String, List<QueryDocumentSnapshot>>{};

                for (final d in docs) {
                  final rol =
                      ((d.data() as Map<String, dynamic>)['rol'] ?? 'Otro')
                          .toString();

                  grupos.putIfAbsent(rol, () => []).add(d);
                }

                final rolesOrdenados = grupos.keys.toList()..sort();

                return ListView(
                  children: [
                    for (final rol in rolesOrdenados) ...[
                      Container(
                        width: double.infinity,
                        color: _colorPorRemitente(rol, rol).withOpacity(0.15),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: Text(
                          '${rolParaMostrar(context.l10n, rol)} (${grupos[rol]!.length})',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1),
                        ),
                      ),
                      for (final d in grupos[rol]!) _buildPedidoTile(d),
                    ],
                  ],
                );
              },
            ),
          ),
          PestanaSala.historial: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('salas')
                .doc(widget.codigoSala)
                .collection('pedidos')
                .where('atendido', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                    child: Text(
                        context.l10n.errorDeConexion('${snapshot.error}')));
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              // Se ordena en el cliente (en vez de .orderBy en la query) para

              // no depender de un índice compuesto de Firestore que no está

              // provisionado (where + orderBy en campos distintos lo exigiría).

              final docs = snapshot.data!.docs.toList()
                ..sort((a, b) {
                  final ta = (a.data() as Map<String, dynamic>)['createdAt']
                      as Timestamp?;

                  final tb = (b.data() as Map<String, dynamic>)['createdAt']
                      as Timestamp?;

                  if (ta == null || tb == null) return 0;

                  return tb.compareTo(ta);
                });

              if (docs.isEmpty) {
                return Center(
                    child: Text(context.l10n.todaviaNoAtendisteNingunPedido,
                        style: const TextStyle(color: Colors.grey)));
              }

              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final data = docs[i].data() as Map<String, dynamic>;

                  final respuestaActual = data['respuesta'] ?? '';

                  return ListTile(
                    leading:
                        const Icon(Icons.check_circle, color: Colors.green),
                    title: Text('${data['pedido']}',
                        style: const TextStyle(
                            decoration: TextDecoration.lineThrough)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            '${data['nombre']} (${rolParaMostrar(context.l10n, '${data['rol']}')})'),
                        if (respuestaActual.isNotEmpty)
                          Text(context.l10n.tuRespuesta(respuestaActual),
                              style: TextStyle(
                                  color: context.acento,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          PestanaSala.setlist: SetlistTab(
            codigoSala: widget.codigoSala,
            nombreUsuario: 'Sonidista',
            onIrAPedidos: _irAPedidos,
            esSonidista: true,
          ),
          PestanaSala.secuencias: SecuenciasTab(
            codigoSala: widget.codigoSala,
            nombreUsuario: 'Sonidista',
            esSonidista: true,
          ),
        }),
      ),
    );
  }

  /// El contenido de las pestañas elegidas, en orden.
  List<Widget> _contenidoDePestanas(Map<PestanaSala, Widget> contenido) =>
      [for (final p in _pestanas) contenido[p]!];
}
