import 'dart:async';

import 'dart:math';

import 'package:audioplayers/audioplayers.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:file_picker/file_picker.dart';

import 'package:firebase_app_check/firebase_app_check.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:firebase_core/firebase_core.dart';

import 'package:firebase_storage/firebase_storage.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:google_sign_in/google_sign_in.dart';

import 'package:share_plus/share_plus.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import 'package:syncfusion_flutter_pdf/pdf.dart' as sf_pdf;

import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'package:wakelock_plus/wakelock_plus.dart';



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



class AppConstants {

  static const List<String> pedidosRapidos = [

    'Volumen retorno', 'Volumen al 2', 'Volumen al 3', 'Volumen al 4',

    'Volumen guitarra', 'Volumen teclado', 'Volumen Talkback', 'Volumen pista', 'Volumen click',

    'Volumen retorno', 'Volumen coordinator', 'Volumen general', '+', '-', 'Listo',

  ];

}

/// Genera un código de sala de 8 caracteres alfanuméricos (excluye 0/O/1/I/L
/// para que no se confundan al leerlos en voz alta o escribirlos a mano).
/// 32^8 ≈ 1,1 billones de combinaciones, contra las 900.000 del PIN
/// numérico de 6 dígitos anterior.
String generarCodigoSala() {
  const alfabeto = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
  final random = Random.secure();
  return List.generate(8, (_) => alfabeto[random.nextInt(alfabeto.length)]).join();
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

  static const List<AppPalette> todas = [consola, placa, wash, worklight, camarin];

  static AppPalette porClave(String? clave) {
    return todas.firstWhere((p) => p.key == clave, orElse: () => consola);
  }
}

/// Construye el ThemeData de Material 3 para una paleta y un brillo dados.
ThemeData construirTema(AppPalette paleta, Brightness brightness) {
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
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
  ];

  static const List<String> _bemoles = [
    'C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B',
  ];

  static final RegExp _tokenAcorde = RegExp(
    r'^([A-G])(#|b)?((?:maj|min|dim|aug|sus|add|m)?[0-9]*(?:[#b][0-9]+)?\+?)?(?:/([A-G])(#|b)?)?$',
  );

  static final RegExp _entreCorchetes = RegExp(r'\[([^\]]+)\]');

  static String transponerTexto(String texto, int semitonos) {
    if (semitonos == 0) return texto;
    return texto.split('\n').map((linea) => _transponerLinea(linea, semitonos)).join('\n');
  }

  static String _transponerLinea(String linea, int semitonos) {
    if (_entreCorchetes.hasMatch(linea)) {
      return linea.replaceAllMapped(_entreCorchetes, (m) {
        final adentro = m.group(1)!;
        return '[${_transponerToken(adentro, semitonos) ?? adentro}]';
      });
    }

    if (!_esLineaDeAcordes(linea)) return linea;

    return linea.replaceAllMapped(RegExp(r'\S+'), (m) {
      return _transponerToken(m.group(0)!, semitonos) ?? m.group(0)!;
    });
  }

  static bool _esLineaDeAcordes(String linea) {
    final palabras = linea.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (palabras.isEmpty) return false;
    final acordes = palabras.where((w) => _tokenAcorde.hasMatch(w)).length;
    return acordes / palabras.length >= 0.6;
  }

  static String? _transponerToken(String token, int semitonos) {
    final match = _tokenAcorde.firstMatch(token);
    if (match == null) return null;

    final raiz = match.group(1)!;
    final alteracion = match.group(2) ?? '';
    final sufijo = match.group(3) ?? '';
    final bajoRaiz = match.group(4);
    final bajoAlteracion = match.group(5) ?? '';

    var resultado = _transponerNota(raiz + alteracion, semitonos) + sufijo;
    if (bajoRaiz != null) {
      resultado += '/${_transponerNota(bajoRaiz + bajoAlteracion, semitonos)}';
    }
    return resultado;
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
      throw Exception('Inicio de sesión con Google cancelado.');
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  static Future<UserCredential> registerWithEmail(String email, String password) {
    return _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
  }

  static Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
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
          return 'El email no es válido.';
        case 'user-disabled':
          return 'Esta cuenta fue deshabilitada.';
        case 'user-not-found':
          return 'No existe una cuenta con ese email.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Email o contraseña incorrectos.';
        case 'email-already-in-use':
          return 'Ya existe una cuenta con ese email.';
        case 'weak-password':
          return 'La contraseña debe tener al menos 6 caracteres.';
        default:
          return error.message ?? 'Error de autenticación.';
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
      FirebaseFirestore.instance.collection('usuarios').doc(uid).collection('mis_salas');

  static Stream<QuerySnapshot<Map<String, dynamic>>> streamMisSalas(String uid) {
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

  static Future<void> renombrar(String uid, String codigoSala, String nombreSala) async {
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
  final esPro = kFuncionesProGratisPorAhora || await UsuarioService.streamEsPro(uid).first;
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
      FirebaseFirestore.instance.collection('usuarios').doc(uid).collection('frases');

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
  /// del usuario. Se llama una sola vez, al registrarse.
  static Future<void> copiarFrasesBaseParaUsuario(String uid) async {
    final batch = FirebaseFirestore.instance.batch();
    for (var i = 0; i < AppConstants.pedidosRapidos.length; i++) {
      final doc = _ref(uid).doc();
      batch.set(doc, {
        'texto': AppConstants.pedidosRapidos[i],
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
      FirebaseFirestore.instance.collection('salas').doc(codigoSala).collection('miembros');

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
  static Future<List<Map<String, dynamic>>> obtenerPresentes(String codigoSala) async {
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
      FirebaseFirestore.instance.collection('usuarios').doc(uid).collection('mi_repertorio');

  static Stream<QuerySnapshot<Map<String, dynamic>>> streamRepertorio(String uid) {
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
    ordenados.sort((a, b) =>
        (a.data()['titulo'] as String? ?? '').toLowerCase().compareTo((b.data()['titulo'] as String? ?? '').toLowerCase()));
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
    try {
      final documento = sf_pdf.PdfDocument(inputBytes: bytes);
      final texto = sf_pdf.PdfTextExtractor(documento).extractText(layoutText: true);
      documento.dispose();
      return texto.trim();
    } catch (e) {
      debugPrint('No se pudo extraer texto del PDF: $e');
      return '';
    }
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
    final nombreUnico = '${DateTime.now().millisecondsSinceEpoch}_${_sanitizarNombreArchivo(nombreArchivo)}';
    final storagePath = 'usuarios/$uid/canciones/$nombreUnico';

    await supabase.storage.from(kSupabaseRepertorioBucket).uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(contentType: 'application/pdf'),
        );
    final pdfUrl = supabase.storage.from(kSupabaseRepertorioBucket).getPublicUrl(storagePath);

    final data = {
      'titulo': titulo,
      'tonalidad': tonalidad,
      'pdfUrl': pdfUrl,
      'storagePath': storagePath,
      'storageProvider': 'supabase',
      'cifradoTexto': cifradoTexto,
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
    await _ref(uid).doc(cancionId).update({
      'titulo': titulo,
      'tonalidad': tonalidad,
      'cifradoTexto': cifradoTexto,
    });
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
        final storageProvider = doc.data()?['storageProvider'] as String? ?? 'firebase';
        if (storageProvider == 'supabase') {
          await supabase.storage.from(kSupabaseRepertorioBucket).remove([storagePath]);
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
      final snap = await _ref(uid).orderBy('createdAt', descending: true).limit(50).get();
      resultados.addAll(snap.docs.map((d) => {...d.data(), 'id': d.id, 'propietarioNombre': nombreCompanero}));
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
      final coincideTitulo = tituloQuery.isEmpty || _normalizar(c['titulo'] as String? ?? '').contains(tituloQuery);
      final coincideTonalidad =
          tonalidadQuery.isEmpty || _normalizar(c['tonalidad'] as String? ?? '').contains(tonalidadQuery);
      return coincideTitulo && coincideTonalidad;
    }).toList();
  }
}

// --- SERVICIO DE SETLIST DE SALA (LISTA DE TEMAS DEL DÍA) ---

class SetlistService {
  static CollectionReference<Map<String, dynamic>> _ref(String codigoSala) =>
      FirebaseFirestore.instance.collection('salas').doc(codigoSala).collection('setlist');

  static Stream<QuerySnapshot<Map<String, dynamic>>> streamSetlist(String codigoSala) {
    return _ref(codigoSala).orderBy('orden').snapshots();
  }

  static Future<void> agregarAlSetlist({
    required String codigoSala,
    required String titulo,
    required String pdfUrl,
    required String subidoPor,
    required int orden,
    String cifradoTexto = '',
  }) async {
    await _ref(codigoSala).add({
      'titulo': titulo,
      'pdfUrl': pdfUrl,
      'subidoPor': subidoPor,
      'orden': orden,
      'cifradoTexto': cifradoTexto,
      'completado': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> eliminarDelSetlist(String codigoSala, String itemId) async {
    await _ref(codigoSala).doc(itemId).delete();
  }

  /// Actualiza el estado de un tema: 'pendiente', 'pausado' (corte técnico)
  /// o 'tocado'. Mantiene 'completado' (bool) en sync para no romper
  /// documentos/lecturas viejas que solo conocían ese campo binario.
  static Future<void> actualizarEstado(String codigoSala, String itemId, String estado) async {
    await _ref(codigoSala).doc(itemId).update({
      'estado': estado,
      'completado': estado == 'tocado',
      'completadoAt': estado == 'tocado' ? FieldValue.serverTimestamp() : FieldValue.delete(),
    });
  }

  /// Actualiza la transposición (en semitonos) de un tema, para que se
  /// sincronice en vivo a todos los que estén viendo el cifrado de esa
  /// canción en la sala.
  static Future<void> actualizarTransposicion(String codigoSala, String itemId, int semitonos) async {
    await _ref(codigoSala).doc(itemId).update({'transposicion': semitonos});
  }

  /// Reescribe el campo 'orden' de todos los temas según su posición en
  /// [idsEnOrden] (ej. después de un drag & drop en vivo).
  static Future<void> reordenarSetlist(String codigoSala, List<String> idsEnOrden) async {
    final batch = FirebaseFirestore.instance.batch();
    for (var i = 0; i < idsEnOrden.length; i++) {
      batch.update(_ref(codigoSala).doc(idsEnOrden[i]), {'orden': i});
    }
    await batch.commit();
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

      'createdAt': FieldValue.serverTimestamp(), // Cambiado 'creadoEn' por 'createdAt'

    });

  }



  static Future<void> responderPedido(String codigoSala, String pedidoId, String textoRespuesta) async {

    try {

      await _pedidosRef(codigoSala).doc(pedidoId).update({

        'respuesta': textoRespuesta,

      });

    } catch (e) {

      debugPrint("Error al responder pedido: $e");

    }

  }



  static Future<void> eliminarPedidoIndividual(String codigoSala, String pedidoId) async {

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

  ThemeMode _themeMode = ThemeMode.light;

  AppPalette _paleta = AppPalette.consola;

  @override

  void initState() {

    super.initState();

    _cargarPaletaGuardada();

  }

  Future<void> _cargarPaletaGuardada() async {

    final prefs = await SharedPreferences.getInstance();

    final clave = prefs.getString('paleta_app');

    if (clave != null && mounted) {

      setState(() => _paleta = AppPalette.porClave(clave));

    }

  }

  void toggleTheme() {

    setState(() {

      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;

    });

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

            MaterialPageRoute(builder: (_) => SonidistaPage(codigoSala: salaId)),

          );

          return;

        } else {

          final nombre = prefs.getString('nombre') ?? 'Músico';

          final rolStr = prefs.getString('rol') ?? 'Músico';

          final userRole = (rolStr == 'Cantante') ? UserRole.cantante : UserRole.musico;



          Navigator.pushReplacement(

            context,

            MaterialPageRoute(

              builder: (_) => RequestScreen(

                userName: nombre,

                role: userRole,

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
        : const AuthScreen();

    Navigator.pushReplacement(

      context,

      MaterialPageRoute(builder: (_) => destino),

    );

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



// --- PANTALLA DE LOGIN / REGISTRO ---

class AuthScreen extends StatefulWidget {

  const AuthScreen({super.key});

  @override

  State<AuthScreen> createState() => _AuthScreenState();

}

class _AuthScreenState extends State<AuthScreen> {

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

      SnackBar(content: Text(AuthService.mensajeError(error)), backgroundColor: Colors.redAccent),

    );

  }

  Future<void> _enviarFormulario() async {

    if (_procesando) return;

    if (_modoRegistro && !(_formKey.currentState?.validate() ?? false)) return;

    if (!_modoRegistro && (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty)) {

      _mostrarError(Exception('Completá email y contraseña.'));

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

        await AuthService.signInWithEmail(_emailController.text, _passwordController.text);

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

    final nombreController = TextEditingController(text: user.displayName ?? '');

    final rolController = TextEditingController();

    final formKey = GlobalKey<FormState>();

    await showDialog<void>(

      context: context,

      barrierDismissible: false,

      builder: (context) => AlertDialog(

        title: const Text('Completá tu perfil'),

        content: Form(

          key: formKey,

          child: Column(

            mainAxisSize: MainAxisSize.min,

            children: [

              TextFormField(

                controller: nombreController,

                decoration: const InputDecoration(labelText: 'Tu nombre'),

                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,

              ),

              const SizedBox(height: 12),

              TextFormField(

                controller: rolController,

                decoration: const InputDecoration(labelText: 'Tu rol (ej: sonidista, guitarrista)'),

                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,

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

            child: const Text('Guardar'),

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

        title: const Text('Recuperar contraseña'),

        content: TextField(

          controller: controller,

          keyboardType: TextInputType.emailAddress,

          decoration: const InputDecoration(labelText: 'Tu email', border: OutlineInputBorder()),

        ),

        actions: [

          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),

          TextButton(

            onPressed: () => Navigator.pop(context, controller.text.trim()),

            child: const Text('Enviar email'),

          ),

        ],

      ),

    );

    if (email == null || email.isEmpty) return;

    try {

      await AuthService.sendPasswordResetEmail(email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(content: Text('Te enviamos un email para restablecer tu contraseña.')),

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

                Icon(Icons.settings_input_component, size: 64, color: context.acento),

                const SizedBox(height: 16),

                Text(

                  _modoRegistro ? 'Crear cuenta' : 'Iniciar sesión',

                  textAlign: TextAlign.center,

                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),

                ),

                const SizedBox(height: 24),

                if (_modoRegistro) ...[

                  TextFormField(

                    controller: _nombreController,

                    decoration: const InputDecoration(labelText: 'Tu nombre', border: OutlineInputBorder()),

                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,

                  ),

                  const SizedBox(height: 12),

                  TextFormField(

                    controller: _rolController,

                    decoration: const InputDecoration(

                      labelText: 'Tu rol (ej: sonidista, guitarrista, corista)',

                      border: OutlineInputBorder(),

                    ),

                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,

                  ),

                  const SizedBox(height: 12),

                ],

                TextFormField(

                  controller: _emailController,

                  keyboardType: TextInputType.emailAddress,

                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),

                  validator: (v) => (v == null || !v.contains('@')) ? 'Email inválido' : null,

                ),

                const SizedBox(height: 12),

                TextFormField(

                  controller: _passwordController,

                  obscureText: true,

                  decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder()),

                  validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,

                ),

                if (!_modoRegistro)

                  Align(

                    alignment: Alignment.centerRight,

                    child: TextButton(

                      onPressed: _procesando ? null : _olvideMiContrasena,

                      child: const Text('¿Olvidaste tu contraseña?'),

                    ),

                  ),

                const SizedBox(height: 12),

                FilledButton(

                  onPressed: _procesando ? null : _enviarFormulario,

                  style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),

                  child: _procesando

                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))

                      : Text(_modoRegistro ? 'REGISTRARME' : 'INICIAR SESIÓN'),

                ),

                TextButton(

                  onPressed: _procesando ? null : () => setState(() => _modoRegistro = !_modoRegistro),

                  child: Text(_modoRegistro

                      ? '¿Ya tenés cuenta? Iniciar sesión'

                      : '¿No tenés cuenta? Registrarme'),

                ),

                const SizedBox(height: 8),

                const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('O')), Expanded(child: Divider())]),

                const SizedBox(height: 8),

                OutlinedButton.icon(

                  onPressed: _procesando ? null : _continuarConGoogle,

                  icon: const Icon(Icons.g_mobiledata, size: 28),

                  label: const Text('Continuar con Google'),

                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),

                ),

                const SizedBox(height: 24),

                TextButton(

                  onPressed: _procesando ? null : _irAIngreso,

                  child: const Text('Continuar sin cuenta', style: TextStyle(color: Colors.grey)),

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

      MaterialPageRoute(builder: (_) => const AuthScreen()),

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

        actions: [

          IconButton(

            icon: Icon(isLight ? Icons.wb_sunny : Icons.nightlight_round),

            onPressed: () => SoundCheckProApp.of(context).toggleTheme(),

          ),

          IconButton(

            icon: const Icon(Icons.palette_outlined),

            tooltip: 'Color de la app',

            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaletaPickerScreen())),

          ),

          if (registrado)

            IconButton(

              icon: const Icon(Icons.logout),

              tooltip: 'Cerrar sesión de cuenta',

              onPressed: () => _cerrarSesionCuenta(context),

            )

          else

            IconButton(

              icon: const Icon(Icons.login),

              tooltip: 'Iniciar sesión',

              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen())),

            ),

        ],

      ),

      body: SafeArea(

        child: LayoutBuilder(

          builder: (context, constraints) => SingleChildScrollView(

            padding: const EdgeInsets.all(24),

            child: ConstrainedBox(

              constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),

              child: Column(

          mainAxisAlignment: MainAxisAlignment.center,

          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [

            Icon(Icons.settings_input_component, size: 80, color: context.acento),

            const SizedBox(height: 24),

            const Text(

              'SOUND CHECK PRO',

              textAlign: TextAlign.center,

              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 2),

            ),

            if (registrado) ...[

              const SizedBox(height: 8),

              Text(

                'Sesión: ${user!.email ?? user.displayName ?? user.uid}',

                textAlign: TextAlign.center,

                style: const TextStyle(fontSize: 12, color: Colors.grey),

              ),

            ],

            const SizedBox(height: 48),

            FilledButton.icon(

              icon: const Icon(Icons.add),

              label: const Text('CREAR NUEVA SALA'),

              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CrearSalaScreen())),

              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),

            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(

              icon: const Icon(Icons.login),

              label: const Text('UNIRME A SALA'),

              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UnirmeSalaScreen())),

              style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),

            ),

            const SizedBox(height: 12),

            if (registrado) ...[

              OutlinedButton.icon(

                icon: const Icon(Icons.history),

                label: const Text('MIS SALAS'),

                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MisSalasScreen())),

                style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),

              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(

                icon: const Icon(Icons.edit_note),

                label: const Text('MIS FRASES'),

                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FrasesAdminScreen())),

                style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),

              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(

                icon: const Icon(Icons.library_music),

                label: const Text('MI REPERTORIO'),

                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MiRepertorioScreen())),

                style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),

              ),

            ],

            const SizedBox(height: 12),

            OutlinedButton.icon(

              icon: const Icon(Icons.tune),

              label: const Text('ACCESO SONIDISTA'),

              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SonidistaPinScreen())),

              style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),

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

class PaletaPickerScreen extends StatelessWidget {

  const PaletaPickerScreen({super.key});

  @override

  Widget build(BuildContext context) {

    final actual = SoundCheckProApp.of(context).paletaActual;

    final esOscuro = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(

      appBar: AppBar(title: const Text('Color de la app')),

      body: ListView(

        padding: const EdgeInsets.all(16),

        children: [

          Text(

            'Elegí la identidad visual de la app. Se guarda en este dispositivo.',

            style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),

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

            color: seleccionada ? acento : Theme.of(context).colorScheme.outlineVariant,

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

                  decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4)),

                );

              }).toList(),

            ),

            const SizedBox(width: 14),

            Expanded(

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Text(paleta.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),

                  Text(paleta.tag, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),

                ],

              ),

            ),

            Icon(

              seleccionada ? Icons.check_circle : Icons.radio_button_unchecked,

              color: seleccionada ? acento : Theme.of(context).colorScheme.outlineVariant,

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

  UserRole? _role = UserRole.musico;

  bool _procesando = false;



  Future<void> _crearYEntrar() async {

    final nombre = _nameController.text.trim();

    if (nombre.isEmpty || _procesando) return;



    setState(() => _procesando = true);

    try {

      await AuthService.asegurarSesion();

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('tipo_login', 'usuario');

      await prefs.setString('sala_id', _pin);

      await prefs.setString('nombre', nombre);

      await prefs.setString('rol', _role == UserRole.cantante ? 'Cantante' : 'Músico');

      await _registrarSalaSiCorresponde(

        codigoSala: _pin,

        rolUsado: _role == UserRole.cantante ? 'Cantante' : 'Músico',

        nombre: nombre,

      );



      if (!mounted) return;



      Navigator.pushAndRemoveUntil(

        context,

        MaterialPageRoute(

          builder: (_) => RequestScreen(

            userName: nombre,

            role: _role!,

            codigoSala: _pin,

          ),

        ),

            (route) => false,

      );

    } catch (e) {

      setState(() => _procesando = false);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al ingresar: $e')));

    }

  }



  @override

  void dispose() {

    _nameController.dispose();

    super.dispose();

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(title: const Text('Configurar Sala')),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(24),

        child: Column(

          children: [

            Card(

              child: ListTile(

                title: const Text('Tu PIN de Sala', textAlign: TextAlign.center),

                subtitle: Text(_pin, textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: context.acento)),

                trailing: IconButton(icon: const Icon(Icons.copy), onPressed: () {

                  Clipboard.setData(ClipboardData(text: _pin));

                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN copiado')));

                }),

              ),

            ),

            const SizedBox(height: 24),

            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Tu Nombre', border: OutlineInputBorder())),

            const SizedBox(height: 16),

            RadioListTile(title: const Text('Músico'), value: UserRole.musico, groupValue: _role, onChanged: (v) => setState(() => _role = v)),

            RadioListTile(title: const Text('Cantante'), value: UserRole.cantante, groupValue: _role, onChanged: (v) => setState(() => _role = v)),

            const SizedBox(height: 24),

            SizedBox(

              width: double.infinity,

              child: FilledButton(

                onPressed: _procesando ? null : _crearYEntrar,

                child: _procesando ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('EMPEZAR'),

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

  late final _pinController = TextEditingController(text: widget.codigoInicial ?? '');

  UserRole? _role = UserRole.musico;

  bool _procesando = false;



  Future<void> _unirmeASala() async {

    final pin = _pinController.text.trim().toUpperCase();

    final nombre = _nameController.text.trim();



    if (nombre.isEmpty || pin.length != 8 || _procesando) return;



    setState(() => _procesando = true);

    try {

      await AuthService.asegurarSesion();

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('tipo_login', 'usuario');

      await prefs.setString('sala_id', pin);

      await prefs.setString('nombre', nombre);

      await prefs.setString('rol', _role == UserRole.cantante ? 'Cantante' : 'Músico');

      await _registrarSalaSiCorresponde(

        codigoSala: pin,

        rolUsado: _role == UserRole.cantante ? 'Cantante' : 'Músico',

        nombre: nombre,

      );



      if (!mounted) return;



      Navigator.pushAndRemoveUntil(

        context,

        MaterialPageRoute(

          builder: (_) => RequestScreen(

            userName: nombre,

            role: _role!,

            codigoSala: pin,

          ),

        ),

            (route) => false,

      );

    } catch (e) {

      setState(() => _procesando = false);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al ingresar: $e')));

    }

  }



  @override

  void dispose() {

    _nameController.dispose();

    _pinController.dispose();

    super.dispose();

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(title: const Text('Unirse a Sala')),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(24),

        child: Column(

          children: [

            TextField(

              controller: _pinController,

              textCapitalization: TextCapitalization.characters,

              decoration: const InputDecoration(labelText: 'Código de sala (8 caracteres)', border: OutlineInputBorder()),

            ),

            const SizedBox(height: 16),

            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Tu Nombre', border: OutlineInputBorder())),

            const SizedBox(height: 16),

            RadioListTile(title: const Text('Músico'), value: UserRole.musico, groupValue: _role, onChanged: (v) => setState(() => _role = v)),

            RadioListTile(title: const Text('Cantante'), value: UserRole.cantante, groupValue: _role, onChanged: (v) => setState(() => _role = v)),

            const SizedBox(height: 24),

            SizedBox(

              width: double.infinity,

              child: FilledButton(

                onPressed: _procesando ? null : _unirmeASala,

                child: _procesando ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('UNIRME'),

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

  Future<void> _entrar(BuildContext context, String uid, String codigoSala, String rol, String nombre) async {
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
    await MisSalasService.registrarAcceso(uid: uid, codigoSala: codigoSala, rolUsado: rol, nombre: nombre);
    if (!context.mounted) return;
    if (rol == 'Sonidista') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => SonidistaPage(codigoSala: codigoSala)),
        (route) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => RequestScreen(
            userName: nombre,
            role: rol == 'Cantante' ? UserRole.cantante : UserRole.musico,
            codigoSala: codigoSala,
          ),
        ),
        (route) => false,
      );
    }
  }

  Future<void> _renombrar(BuildContext context, String uid, String codigoSala, String nombreActual) async {
    final controller = TextEditingController(text: nombreActual);
    final nuevo = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nombre para esta sala'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Ej: Banda X - Ensayo jueves', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Guardar')),
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
      appBar: AppBar(title: const Text('Mis salas')),
      body: (user == null || user.isAnonymous)
          ? const Center(child: Text('Necesitás iniciar sesión para tener un historial de salas.'))
          : StreamBuilder<bool>(
              stream: UsuarioService.streamEsPro(user.uid),
              builder: (context, proSnapshot) {
                final esPro = kFuncionesProGratisPorAhora || proSnapshot.data == true;
                if (!esPro) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.workspace_premium, color: context.acento, size: 48),
                          const SizedBox(height: 12),
                          const Text(
                            'Guardar un historial de varias salas/bandas para volver a entrar con un toque es una función Pro.',
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
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return const Center(child: Text('Todavía no entraste a ninguna sala con esta cuenta.'));
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
                        final tieneNombre = nombreSala != null && nombreSala.isNotEmpty;
                        return ListTile(
                          leading: Icon(rol == 'Sonidista' ? Icons.tune : Icons.mic_external_on, color: context.acento),
                          title: Text(tieneNombre ? nombreSala : codigoSala),
                          subtitle: Text(tieneNombre ? '$codigoSala · $rol' : rol),
                          onTap: () => _entrar(context, user.uid, codigoSala, rol, nombre),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                tooltip: 'Renombrar',
                                onPressed: () => _renombrar(context, user.uid, codigoSala, nombreSala ?? ''),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                tooltip: 'Quitar del historial',
                                onPressed: () => MisSalasService.quitar(user.uid, codigoSala),
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

// --- PANTALLA DE PEDIDOS INDIVIDUAL (MÚSICO/CANTANTE) ---

class RequestScreen extends StatefulWidget {

  final String userName;

  final UserRole role;

  final String codigoSala;

  const RequestScreen({super.key, required this.userName, required this.role, required this.codigoSala});



  @override

  State<RequestScreen> createState() => _RequestScreenState();

}



class _RequestScreenState extends State<RequestScreen> with SingleTickerProviderStateMixin {

  final _customPedidoController = TextEditingController();

  bool _pantallaEncendida = true;

  bool _esUrgente = false;

  late final TabController _tabController;

  /// Último visor de PDF/cifrado abierto desde el setlist, para poder

  /// volver a él con un swipe hacia abajo desde la pestaña de Pedidos.

  Widget? _ultimoVisor;

  Offset? _inicioArrastrePedidos;

  @override

  void initState() {

    super.initState();

    WakelockPlus.enable();

    MiembrosSalaService.registrarPresencia(widget.codigoSala)
        .catchError((e) => debugPrint('No se pudo registrar presencia en la sala: $e'));

    _tabController = TabController(length: 2, vsync: this);

  }

  @override

  void dispose() {

    WakelockPlus.disable();

    _customPedidoController.dispose();

    _tabController.dispose();

    super.dispose();

  }

  void _irAPedidos(Widget visorActual) {

    _ultimoVisor = visorActual;

    Navigator.pop(context);

    _tabController.animateTo(0);

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

    final prefs = await SharedPreferences.getInstance();

    await prefs.clear();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(

      context,

      MaterialPageRoute(builder: (_) => const IngressMenuScreen()),

          (route) => false,

    );

  }



  void _enviarMensaje(String texto) {

    if (texto.trim().isEmpty) return;

    final rolStr = widget.role == UserRole.musico ? 'Músico' : 'Cantante';

    final urgente = _esUrgente;

    FirestoreService.enviarPedido(

        codigo: widget.codigoSala,

        nombre: widget.userName,

        rol: rolStr,

        pedido: texto.trim(),

        urgente: urgente,

    );

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(

        content: Text(urgente ? '¡Urgente enviado!: ${texto.trim()}' : 'Enviado: ${texto.trim()}'),

        duration: const Duration(milliseconds: 400),

        backgroundColor: urgente ? Colors.redAccent : null,

      ),

    );

    if (_esUrgente) setState(() => _esUrgente = false);

  }



  Widget _construirGridFrases(List<String> pedidosRapidos) {

    return GridView.builder(

      padding: const EdgeInsets.all(8),

      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(

          crossAxisCount: 3,

          childAspectRatio: 1.8,

          crossAxisSpacing: 6,

          mainAxisSpacing: 6

      ),

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

                side: BorderSide(color: context.acento.withOpacity(0.2))

            ),

          ),

          onPressed: () => _enviarMensaje(pedido),

          child: Text(pedido,

              textAlign: TextAlign.center,

              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500)),

        );

      },

    );

  }



  @override

  Widget build(BuildContext context) {

    final rolStr = widget.role == UserRole.musico ? 'Músico' : 'Cantante';



    return Scaffold(

      appBar: AppBar(

        title: Text('${widget.userName} ($rolStr)'),

        centerTitle: true,

        leading: IconButton(

          icon: const Icon(Icons.logout),

          tooltip: 'Cerrar Sesión',

          onPressed: () => _cerrarSesion(context),

        ),

        actions: [

          Container(

            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),

            margin: const EdgeInsets.only(right: 8),

            decoration: BoxDecoration(

              color: context.acento,

              borderRadius: BorderRadius.circular(20),

            ),

            child: Center(

              child: Text('SALA: ${widget.codigoSala}',

                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),

            ),

          ),

          IconButton(

            icon: Icon(_pantallaEncendida ? Icons.lightbulb : Icons.lightbulb_outline),

            tooltip: _pantallaEncendida ? 'Pantalla siempre encendida: activado' : 'Pantalla siempre encendida: desactivado',

            onPressed: _togglePantallaEncendida,

          ),

        ],

        bottom: TabBar(

          controller: _tabController,

          tabs: const [

            Tab(text: 'PEDIDOS'),

            Tab(text: 'SETLIST'),

          ],

        ),

      ),

      body: TabBarView(

        controller: _tabController,

        children: [

          Listener(

            onPointerDown: (e) => _inicioArrastrePedidos = e.position,

            onPointerUp: _manejarSwipeAbajoEnPedidos,

            child: Column(

        children: [

          Expanded(

            flex: 3,

            child: Builder(builder: (context) {

              final user = AuthService.currentUser;

              if (user == null || user.isAnonymous) {

                return _construirGridFrases(AppConstants.pedidosRapidos);

              }

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(

                stream: FrasesService.streamFrases(user.uid),

                builder: (context, snapshot) {

                  final docs = snapshot.data?.docs;

                  final pedidosRapidos = (docs == null || docs.isEmpty)

                      ? AppConstants.pedidosRapidos

                      : docs.map((d) => d.data()['texto'] as String).toList();

                  return _construirGridFrases(pedidosRapidos);

                },

              );

            }),

          ),



          Padding(

            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

            child: Row(

              children: [

                Expanded(

                  child: TextField(

                    controller: _customPedidoController,

                    style: const TextStyle(fontSize: 13),

                    decoration: const InputDecoration(

                      hintText: 'Escribir pedido personalizado...',

                      isDense: true,

                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),

                      border: OutlineInputBorder(),

                    ),

                  ),

                ),

                const SizedBox(width: 4),

                IconButton(

                  icon: Icon(Icons.priority_high, color: _esUrgente ? Colors.redAccent : Colors.grey),

                  tooltip: _esUrgente ? 'Pedido urgente: activado' : 'Marcar el próximo pedido como urgente',

                  onPressed: () => setState(() => _esUrgente = !_esUrgente),

                ),

                const SizedBox(width: 4),

                IconButton.filled(

                  icon: const Icon(Icons.send, size: 18),

                  style: _esUrgente ? IconButton.styleFrom(backgroundColor: Colors.redAccent) : null,

                  onPressed: () {

                    _enviarMensaje(_customPedidoController.text);

                    _customPedidoController.clear();

                  },

                ),

              ],

            ),

          ),



          const Divider(thickness: 1, height: 1),

          const Padding(

              padding: EdgeInsets.symmetric(vertical: 6),

              child: Text('MIS ÚLTIMOS PEDIDOS', style: TextStyle(fontSize: 9, color: Colors.grey, letterSpacing: 1.1))

          ),



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

                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(fontSize: 10)));

                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());



                final docs = snapshot.data!.docs;

                if (docs.isEmpty) return const Center(child: Text('Sin pedidos propios', style: TextStyle(color: Colors.grey, fontSize: 11)));



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

                            content: Text('Eliminando pedido: "${data['pedido']}"'),

                            duration: const Duration(seconds: 2),

                            backgroundColor: Colors.redAccent,

                          ),

                        );

                        await FirestoreService.eliminarPedidoIndividual(widget.codigoSala, doc.id);

                      },

                      child: ListTile(

                        dense: true,

                        visualDensity: VisualDensity.compact,

                        leading: Icon(

                          isAtendido

                              ? Icons.check_circle

                              : (esUrgente ? Icons.priority_high : Icons.access_time_filled),

                          color: isAtendido ? Colors.green : (esUrgente ? Colors.redAccent : Colors.orange),

                          size: 16,

                        ),

                        title: Text(

                          "${data['pedido']}",

                          style: TextStyle(

                            fontSize: 12,

                            fontWeight: esUrgente && !isAtendido ? FontWeight.bold : null,

                            decoration: isAtendido ? TextDecoration.lineThrough : null,

                          ),

                        ),

                        subtitle: respuestaTecnico.isNotEmpty

                            ? Text(

                          "Consola: $respuestaTecnico",

                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.acento),

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

          SetlistTab(

            codigoSala: widget.codigoSala,

            nombreUsuario: widget.userName,

            onIrAPedidos: _irAPedidos,

          ),

        ],

      ),

    );

  }

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

  const SetlistTab({

    super.key,

    required this.codigoSala,

    required this.nombreUsuario,

    this.onIrAPedidos,

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

              title: const Text('Desde mi biblioteca'),

              onTap: () => Navigator.pop(context, 'biblioteca'),

            ),

            ListTile(

              leading: Icon(Icons.search, color: context.acento),

              title: const Text('Buscar en bibliotecas de la sala'),

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

        const SnackBar(content: Text('Necesitás iniciar sesión para usar tu biblioteca.')),

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

            builder: (context, scrollController) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(

              stream: RepertorioService.streamRepertorio(user.uid),

              builder: (context, snapshot) {

                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final docs = RepertorioService.ordenarPorTitulo(snapshot.data!.docs);

                if (docs.isEmpty) return const Center(child: Text('Tu biblioteca está vacía.'));

                final canciones = docs.map((d) => {...d.data(), 'id': d.id}).toList();

                final docsFiltrados = RepertorioService.filtrarPorTituloYTonalidad(
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

                                hintText: 'Título...',

                                isDense: true,

                                prefixIcon: const Icon(Icons.search, size: 20),

                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),

                              ),

                            ),

                          ),

                          const SizedBox(width: 8),

                          Expanded(

                            child: TextField(

                              controller: controllerTonalidad,

                              onChanged: (_) => setModalState(() {}),

                              decoration: InputDecoration(

                                hintText: 'Tonalidad...',

                                isDense: true,

                                prefixIcon: const Icon(Icons.music_note, size: 20),

                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),

                              ),

                            ),

                          ),

                        ],

                      ),

                    ),

                    Expanded(

                      child: docsFiltrados.isEmpty

                          ? const Center(child: Text('Sin resultados.'))

                          : ListView.builder(

                              controller: scrollController,

                              itemCount: docsFiltrados.length,

                              itemBuilder: (context, i) {

                                final data = docsFiltrados[i];

                                return ListTile(

                                  leading: Icon(Icons.picture_as_pdf, color: context.acento),

                                  title: Text(data['titulo'] as String? ?? ''),

                                  subtitle: Text(data['tonalidad'] as String? ?? ''),

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

                            decoration: const InputDecoration(

                              hintText: 'Título...',

                              prefixIcon: Icon(Icons.search),

                              border: OutlineInputBorder(),

                            ),

                          ),

                        ),

                        const SizedBox(width: 8),

                        Expanded(

                          child: TextField(

                            controller: controllerTonalidad,

                            decoration: const InputDecoration(

                              hintText: 'Tonalidad...',

                              prefixIcon: Icon(Icons.music_note),

                              border: OutlineInputBorder(),

                            ),

                          ),

                        ),

                      ],

                    ),

                    const SizedBox(height: 12),

                    if (snapshot.connectionState == ConnectionState.waiting)

                      const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()),

                    if (snapshot.connectionState != ConnectionState.waiting && snapshot.hasError)

                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No se pudo buscar. Intentá de nuevo en un momento.',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),

                    if (snapshot.connectionState != ConnectionState.waiting && !snapshot.hasError && snapshot.data == null)

                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Todavía no hay bibliotecas para buscar en esta sala.'),
                      ),

                    if (snapshot.connectionState != ConnectionState.waiting && !snapshot.hasError && snapshot.data != null)

                      ListenableBuilder(

                        listenable: Listenable.merge([controllerTitulo, controllerTonalidad]),

                        builder: (context, _) {

                          final sugerencias = RepertorioService.filtrarPorTituloYTonalidad(
                            snapshot.data!,
                            titulo: controllerTitulo.text,
                            tonalidad: controllerTonalidad.text,
                          );

                          if (sugerencias.isEmpty) {
                            return const Padding(padding: EdgeInsets.all(16), child: Text('Sin resultados.'));
                          }

                          return Flexible(

                            child: ListView.builder(

                              shrinkWrap: true,

                              itemCount: sugerencias.length,

                              itemBuilder: (context, i) {

                                final data = sugerencias[i];

                                final tonalidad = data['tonalidad'] as String? ?? '';

                                final propietario = data['propietarioNombre'] as String? ?? '';

                                return ListTile(

                                  leading: Icon(Icons.picture_as_pdf, color: context.acento),

                                  title: Text(data['titulo'] as String? ?? ''),

                                  subtitle: Text(
                                    [tonalidad, if (propietario.isNotEmpty) 'de $propietario']
                                        .where((s) => s.isNotEmpty)
                                        .join(' · '),
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

        const SnackBar(content: Text('El setlist está vacío, no hay nada para exportar.')),

      );

      return;

    }

    final buffer = StringBuffer('Setlist — Sala $codigoSala\n\n');

    for (var i = 0; i < docs.length; i++) {

      final data = docs[i].data();

      final titulo = data['titulo'] as String? ?? '';

      final estado = (data['estado'] as String?) ?? ((data['completado'] as bool? ?? false) ? 'tocado' : 'pendiente');

      final marca = estado == 'tocado' ? '[X]' : (estado == 'pausado' ? '[~]' : '[ ]');

      buffer.writeln('${i + 1}. $marca $titulo');

    }

    final texto = buffer.toString();

    if (!context.mounted) return;

    await showDialog<void>(

      context: context,

      builder: (dialogContext) => AlertDialog(

        title: const Text('Exportar setlist'),

        content: SingleChildScrollView(child: SelectableText(texto)),

        actions: [

          TextButton(

            onPressed: () async {

              await Clipboard.setData(ClipboardData(text: texto));

              if (dialogContext.mounted) {

                ScaffoldMessenger.of(dialogContext).showSnackBar(

                  const SnackBar(content: Text('Copiado al portapapeles'), duration: Duration(seconds: 1)),

                );

              }

            },

            child: const Text('Copiar'),

          ),

          TextButton(

            onPressed: () => Share.share(texto, subject: 'Setlist - Sala $codigoSala'),

            child: const Text('Compartir'),

          ),

          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cerrar')),

        ],

      ),

    );

  }

  Future<void> _confirmarAgregar(BuildContext context, String titulo, String pdfUrl, {String cifradoTexto = ''}) async {

    if (titulo.isEmpty || pdfUrl.isEmpty) return;

    final actual = await SetlistService.streamSetlist(codigoSala).first;

    await SetlistService.agregarAlSetlist(

      codigoSala: codigoSala,

      titulo: titulo,

      pdfUrl: pdfUrl,

      subidoPor: nombreUsuario,

      orden: actual.docs.length,

      cifradoTexto: cifradoTexto,

    );

    if (context.mounted) {

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(content: Text('Agregado: $titulo'), duration: const Duration(seconds: 1)),

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

            return Center(child: Text('Error: ${snapshot.error}'));

          }

          if (!snapshot.hasData) {

            return const Center(child: CircularProgressIndicator());

          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {

            return const Center(child: Text('Todavía no hay temas en la lista.'));

          }

          final setlistItems = docs.map((d) {

            final m = d.data();

            return {

              'id': d.id,

              'titulo': m['titulo'] as String? ?? '',

              'pdfUrl': m['pdfUrl'] as String? ?? '',

              'cifradoTexto': m['cifradoTexto'] as String? ?? '',

            };

          }).toList();

          String estadoDe(Map<String, dynamic> data) {

            return (data['estado'] as String?) ??

                ((data['completado'] as bool? ?? false) ? 'tocado' : 'pendiente');

          }

          final primerPendienteIndex = docs.indexWhere((d) => estadoDe(d.data()) == 'pendiente');

          return ReorderableListView.builder(

            itemCount: docs.length,

            onReorder: (oldIndex, newIndex) {

              final idsEnOrden = docs.map((d) => d.id).toList();

              final ajustado = newIndex > oldIndex ? newIndex - 1 : newIndex;

              final id = idsEnOrden.removeAt(oldIndex);

              idsEnOrden.insert(ajustado, id);

              SetlistService.reordenarSetlist(codigoSala, idsEnOrden);

            },

            itemBuilder: (context, i) {

              final doc = docs[i];

              final data = doc.data();

              final titulo = data['titulo'] as String? ?? '';

              final subidoPor = data['subidoPor'] as String? ?? '';

              final pdfUrl = data['pdfUrl'] as String? ?? '';

              final cifradoTexto = data['cifradoTexto'] as String? ?? '';

              final estado = estadoDe(data);

              final completado = estado == 'tocado';

              final pausado = estado == 'pausado';

              final esProximo = estado == 'pendiente' && i == primerPendienteIndex;

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

                  tooltip: 'Cambiar estado del tema',

                  icon: Icon(iconosEstado[estado], color: coloresEstado[estado] ?? context.acento.withOpacity(0.5)),

                  onSelected: (nuevoEstado) => SetlistService.actualizarEstado(codigoSala, doc.id, nuevoEstado),

                  itemBuilder: (context) => const [

                    PopupMenuItem(value: 'pendiente', child: Text('Pendiente')),

                    PopupMenuItem(value: 'pausado', child: Text('Pausado (corte técnico)')),

                    PopupMenuItem(value: 'tocado', child: Text('Tocado')),

                  ],

                ),

                title: Row(

                  children: [

                    Flexible(

                      child: Text(

                        titulo,

                        style: TextStyle(

                          decoration: completado ? TextDecoration.lineThrough : null,

                          fontStyle: pausado ? FontStyle.italic : null,

                          color: completado ? Colors.grey : (pausado ? Colors.orange.shade800 : null),

                        ),

                      ),

                    ),

                    if (esProximo || pausado) ...[

                      const SizedBox(width: 8),

                      Container(

                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),

                        decoration: BoxDecoration(

                          color: pausado ? Colors.orange : context.acento,

                          borderRadius: BorderRadius.circular(10),

                        ),

                        child: Text(

                          pausado ? 'PAUSADO' : 'PRÓXIMO',

                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),

                        ),

                      ),

                    ],

                  ],

                ),

                subtitle: Text(

                  'Subido por $subidoPor',

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

                        tooltip: 'Ver cifrado (transponer)',

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

                            ),

                          ),

                        ),

                      ),

                    IconButton(

                      icon: const Icon(Icons.delete_outline, color: Colors.red),

                      onPressed: () => SetlistService.eliminarDelSetlist(codigoSala, doc.id),

                    ),

                  ],

                ),

              );

            },

          );

        },

      ),

      floatingActionButton: Column(

        mainAxisSize: MainAxisSize.min,

        children: [

          FloatingActionButton.small(

            heroTag: 'exportar_setlist_$codigoSala',

            onPressed: () => _exportarSetlist(context),

            tooltip: 'Exportar / compartir setlist',

            child: const Icon(Icons.ios_share),

          ),

          const SizedBox(height: 12),

          FloatingActionButton(

            heroTag: 'agregar_cancion_$codigoSala',

            onPressed: () => _agregarCancion(context),

            tooltip: 'Agregar canción',

            child: const Icon(Icons.add),

          ),

        ],

      ),

    );

  }

}



// --- ADMINISTRACIÓN DE FRASES PREDEFINIDAS ---

class FrasesAdminScreen extends StatelessWidget {

  const FrasesAdminScreen({super.key});

  Future<void> _agregarFrase(BuildContext context, String uid, int siguienteOrden) async {

    final controller = TextEditingController();

    final texto = await showDialog<String>(

      context: context,

      builder: (context) => AlertDialog(

        title: const Text('Nueva frase'),

        content: TextField(

          controller: controller,

          autofocus: true,

          decoration: const InputDecoration(labelText: 'Texto de la frase', border: OutlineInputBorder()),

        ),

        actions: [

          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),

          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Agregar')),

        ],

      ),

    );

    if (texto == null || texto.isEmpty) return;

    await FrasesService.agregarFrase(uid, texto, siguienteOrden);

  }

  Future<void> _editarFrase(BuildContext context, String uid, String id, String textoActual) async {

    final controller = TextEditingController(text: textoActual);

    final texto = await showDialog<String>(

      context: context,

      builder: (context) => AlertDialog(

        title: const Text('Editar frase'),

        content: TextField(

          controller: controller,

          autofocus: true,

          decoration: const InputDecoration(border: OutlineInputBorder()),

        ),

        actions: [

          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),

          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Guardar')),

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

      appBar: AppBar(title: const Text('Mis frases')),

      body: (user == null || user.isAnonymous)

          ? const Center(child: Text('Necesitás iniciar sesión para editar tus frases.'))

          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(

              stream: FrasesService.streamFrases(user.uid),

              builder: (context, snapshot) {

                if (snapshot.hasError) {

                  return Center(child: Text('Error: ${snapshot.error}'));

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

                        const Text('Todavía no tenés frases propias cargadas.'),

                        const SizedBox(height: 16),

                        FilledButton(

                          onPressed: () => FrasesService.copiarFrasesBaseParaUsuario(user.uid),

                          child: const Text('Cargar frases por defecto'),

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

                            onPressed: () => _editarFrase(context, user.uid, doc.id, texto),

                          ),

                          IconButton(

                            icon: const Icon(Icons.delete, color: Colors.red),

                            onPressed: () => FrasesService.eliminarFrase(user.uid, doc.id),

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

                  onPressed: () => _agregarFrase(context, user.uid, siguienteOrden),

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

        title: const Text('Función Pro'),

        content: const Text('Subir tus propias partituras/cifrados en PDF es parte de Sound Check Pro. Activá tu cuenta Pro para usar esta función.'),

        actions: [

          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido')),

        ],

      ),

    );

  }

  Future<void> _subirNuevaCancion(String uid) async {

    final esPro = kFuncionesProGratisPorAhora || await UsuarioService.streamEsPro(uid).first;

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

    final datos = await _pedirDatosCancion(context, cifradoInicial: cifradoExtraido);

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

          SnackBar(content: Text('Error al subir: $e'), backgroundColor: Colors.redAccent),

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

    final tonalidadController = TextEditingController(text: tonalidadInicial ?? '');

    final cifradoController = TextEditingController(text: cifradoInicial ?? '');

    final formKey = GlobalKey<FormState>();

    return showDialog<(String, String, String)>(

      context: context,

      builder: (context) => AlertDialog(

        title: Text(tituloInicial == null ? 'Nueva canción' : 'Editar canción'),

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

                    decoration: const InputDecoration(labelText: 'Título', border: OutlineInputBorder()),

                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,

                  ),

                  const SizedBox(height: 12),

                  TextFormField(

                    controller: tonalidadController,

                    decoration: const InputDecoration(labelText: 'Tonalidad (opcional)', border: OutlineInputBorder()),

                  ),

                  const SizedBox(height: 12),

                  TextFormField(

                    controller: cifradoController,

                    maxLines: 8,

                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),

                    decoration: const InputDecoration(

                      labelText: 'Cifrado en texto (opcional, para transponer)',

                      hintText: 'Pegá los acordes acá. Ej: [C]Amazing [G]grace...',

                      border: OutlineInputBorder(),

                      alignLabelWithHint: true,

                    ),

                  ),

                ],

              ),

            ),

          ),

        ),

        actions: [

          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),

          TextButton(

            onPressed: () {

              if (!(formKey.currentState?.validate() ?? false)) return;

              Navigator.pop(context, (tituloController.text.trim(), tonalidadController.text.trim(), cifradoController.text.trim()));

            },

            child: const Text('Guardar'),

          ),

        ],

      ),

    );

  }

  Future<void> _editarCancion(String uid, String id, String tituloActual, String tonalidadActual, String cifradoActual) async {

    final datos = await _pedirDatosCancion(

      context,

      tituloInicial: tituloActual,

      tonalidadInicial: tonalidadActual,

      cifradoInicial: cifradoActual,

    );

    if (datos == null) return;

    await RepertorioService.editarCancion(uid: uid, cancionId: id, titulo: datos.$1, tonalidad: datos.$2, cifradoTexto: datos.$3);

  }

  Future<void> _confirmarEliminar(String uid, String id, String? storagePath) async {

    final confirm = await showDialog<bool>(

      context: context,

      builder: (c) => AlertDialog(

        title: const Text('¿Eliminar canción?'),

        content: const Text('Se borra de tu biblioteca. Si está en el setlist de alguna sala, va a dejar de abrir.'),

        actions: [

          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),

          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Eliminar')),

        ],

      ),

    );

    if (confirm == true) {

      await RepertorioService.eliminarCancion(uid: uid, cancionId: id, storagePath: storagePath);

    }

  }

  @override

  Widget build(BuildContext context) {

    final user = AuthService.currentUser;

    return Scaffold(

      appBar: AppBar(title: const Text('Mi repertorio')),

      body: (user == null || user.isAnonymous)

          ? const Center(child: Text('Necesitás iniciar sesión para tener tu biblioteca.'))

          : Column(

              children: [

                StreamBuilder<bool>(

                  stream: UsuarioService.streamEsPro(user.uid),

                  builder: (context, snapshot) {

                    if (kFuncionesProGratisPorAhora || snapshot.data == true) return const SizedBox.shrink();

                    return Container(

                      width: double.infinity,

                      color: context.acento.withOpacity(0.08),

                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),

                      child: Row(

                        children: [

                          Icon(Icons.workspace_premium, color: context.acento, size: 18),

                          const SizedBox(width: 8),

                          const Expanded(

                            child: Text(

                              'Subir tus propias partituras es una función Pro.',

                              style: TextStyle(fontSize: 12),

                            ),

                          ),

                          TextButton(

                            onPressed: () => _mostrarUpsellPro(context),

                            child: const Text('Más info', style: TextStyle(fontSize: 12)),

                          ),

                        ],

                      ),

                    );

                  },

                ),

                Padding(

                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

                  child: Row(

                    children: [

                      Expanded(

                        child: TextField(

                          controller: _busquedaTituloController,

                          onChanged: (_) => setState(() {}),

                          decoration: InputDecoration(

                            hintText: 'Título...',

                            isDense: true,

                            prefixIcon: const Icon(Icons.search, size: 20),

                            suffixIcon: _busquedaTituloController.text.isEmpty

                                ? null

                                : IconButton(

                                    icon: const Icon(Icons.clear, size: 18),

                                    onPressed: () => setState(() => _busquedaTituloController.clear()),

                                  ),

                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),

                          ),

                        ),

                      ),

                      const SizedBox(width: 8),

                      Expanded(

                        child: TextField(

                          controller: _busquedaTonalidadController,

                          onChanged: (_) => setState(() {}),

                          decoration: InputDecoration(

                            hintText: 'Tonalidad...',

                            isDense: true,

                            prefixIcon: const Icon(Icons.music_note, size: 20),

                            suffixIcon: _busquedaTonalidadController.text.isEmpty

                                ? null

                                : IconButton(

                                    icon: const Icon(Icons.clear, size: 18),

                                    onPressed: () => setState(() => _busquedaTonalidadController.clear()),

                                  ),

                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),

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

                  return Center(child: Text('Error: ${snapshot.error}'));

                }

                if (!snapshot.hasData) {

                  return const Center(child: CircularProgressIndicator());

                }

                final todasLasCanciones = RepertorioService.ordenarPorTitulo(snapshot.data!.docs)
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

                      todasLasCanciones.isEmpty ? 'Todavía no subiste ninguna canción.' : 'Sin resultados.',

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

                    final cifradoTexto = data['cifradoTexto'] as String? ?? '';

                    return ListTile(

                      leading: Icon(Icons.picture_as_pdf, color: context.acento),

                      title: Text(titulo),

                      subtitle: tonalidad.isNotEmpty ? Text('Tonalidad: $tonalidad') : null,

                      onTap: () => Navigator.push(

                        context,

                        MaterialPageRoute(builder: (_) => PdfViewerScreen(titulo: titulo, pdfUrl: pdfUrl)),

                      ),

                      trailing: Row(

                        mainAxisSize: MainAxisSize.min,

                        children: [

                          if (cifradoTexto.isNotEmpty)

                            IconButton(

                              icon: Icon(Icons.music_note, color: context.acento),

                              tooltip: 'Ver cifrado (transponer)',

                              onPressed: () => Navigator.push(

                                context,

                                MaterialPageRoute(builder: (_) => CifradoViewerScreen(titulo: titulo, cifradoOriginal: cifradoTexto)),

                              ),

                            ),

                          IconButton(

                            icon: const Icon(Icons.edit, color: Colors.blue),

                            onPressed: () => _editarCancion(user.uid, id, titulo, tonalidad, cifradoTexto),

                          ),

                          IconButton(

                            icon: const Icon(Icons.delete, color: Colors.red),

                            onPressed: () => _confirmarEliminar(user.uid, id, data['storagePath'] as String?),

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

          ? (_subiendo ? const FloatingActionButton(onPressed: null, child: CircularProgressIndicator(color: Colors.white)) : null)

          : FloatingActionButton(

              onPressed: () => _subirNuevaCancion(user.uid),

              child: const Icon(Icons.upload_file),

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

  const CifradoViewerScreen({

    super.key,

    required this.titulo,

    required this.cifradoOriginal,

    this.codigoSala,

    this.itemId,

    this.setlistItems,

    this.indiceEnSetlist,

    this.onIrAPedidos,

  });

  bool get sincronizada => codigoSala != null && itemId != null;

  @override

  State<CifradoViewerScreen> createState() => _CifradoViewerScreenState();

}

class _CifradoViewerScreenState extends State<CifradoViewerScreen> {

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

      SetlistService.actualizarTransposicion(widget.codigoSala!, widget.itemId!, nuevo);

    } else {

      setState(() => _semitonosLocal = nuevo);

    }

  }

  Offset? _inicioArrastre;

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

        ),

      ),

    );

  }

  void _manejarSwipe(PointerUpEvent evento) {

    if (_inicioArrastre == null) return;

    final delta = evento.position - _inicioArrastre!;

    _inicioArrastre = null;

    const umbral = 80.0;

    if (delta.dx.abs() > delta.dy.abs()) {

      if (delta.dx.abs() < umbral || widget.setlistItems == null || widget.indiceEnSetlist == null) return;

      final nuevoIndice = widget.indiceEnSetlist! + (delta.dx < 0 ? 1 : -1);

      if (nuevoIndice < 0 || nuevoIndice >= widget.setlistItems!.length) return;

      _navegarAIndice(nuevoIndice);

    } else {

      if (delta.dy >= 0 || delta.dy.abs() < umbral) return;

      widget.onIrAPedidos?.call(widget);

    }

  }

  Widget _construirVisor(BuildContext context, int semitonos) {

    final texto = ChordTransposer.transponerTexto(widget.cifradoOriginal, semitonos);

    final etiquetaSemitonos = semitonos == 0 ? '0' : (semitonos > 0 ? '+$semitonos' : '$semitonos');

    return Scaffold(

      appBar: AppBar(

        title: Text(widget.titulo, overflow: TextOverflow.ellipsis),

        actions: [

          IconButton(

            icon: const Icon(Icons.remove_circle_outline),

            tooltip: 'Bajar un semitono',

            onPressed: () => _cambiarSemitonos(semitonos - 1),

          ),

          Padding(

            padding: const EdgeInsets.symmetric(horizontal: 4),

            child: Center(

              child: Text(etiquetaSemitonos, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),

            ),

          ),

          IconButton(

            icon: const Icon(Icons.add_circle_outline),

            tooltip: 'Subir un semitono',

            onPressed: () => _cambiarSemitonos(semitonos + 1),

          ),

          IconButton(

            icon: const Icon(Icons.refresh),

            tooltip: 'Restablecer tono original',

            onPressed: semitonos == 0 ? null : () => _cambiarSemitonos(0),

          ),

          if (widget.sincronizada)

            IconButton(

              icon: Icon(_sincronizado ? Icons.sync : Icons.sync_disabled),

              color: _sincronizado ? Colors.green : Colors.red,

              tooltip: _sincronizado

                  ? 'Sincronizado con toda la sala (tocá para desincronizar)'

                  : 'Desincronizado — cambios solo locales (tocá para volver a sincronizar)',

              onPressed: () => _toggleSincronizado(semitonos),

            ),

        ],

      ),

      body: Listener(

        onPointerDown: (e) => _inicioArrastre = e.position,

        onPointerUp: _manejarSwipe,

        child: SingleChildScrollView(

          padding: const EdgeInsets.all(16),

          child: SelectableText(

            texto,

            style: const TextStyle(fontFamily: 'monospace', fontSize: 14, height: 1.6),

          ),

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

  Offset? _inicioArrastre;

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

    if (_inicioArrastre == null) return;

    final delta = evento.position - _inicioArrastre!;

    _inicioArrastre = null;

    const umbral = 80.0;

    if (delta.dx.abs() > delta.dy.abs()) {

      if (delta.dx.abs() < umbral || widget.setlistItems == null || widget.indiceEnSetlist == null) return;

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

        onPointerDown: (e) => _inicioArrastre = e.position,

        onPointerUp: _manejarSwipe,

        child: _error != null

            ? Center(

                child: Padding(

                  padding: const EdgeInsets.all(24),

                  child: Column(

                    mainAxisSize: MainAxisSize.min,

                    children: [

                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),

                      const SizedBox(height: 12),

                      Text(

                        'No se pudo cargar el PDF.\n$_error',

                        textAlign: TextAlign.center,

                        style: const TextStyle(color: Colors.white),

                      ),

                    ],

                  ),

                ),

              )

            : SfPdfViewer.network(

                widget.pdfUrl,

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

  bool _procesando = false;



  Future<void> _ingresarComoSonidista() async {

    final pin = _pinController.text.trim().toUpperCase();

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

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al ingresar al panel: $e')));

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

      appBar: AppBar(title: const Text('Acceso Sonidista')),

      body: Padding(

        padding: const EdgeInsets.all(24),

        child: Column(

          children: [

            TextField(controller: _pinController, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'PIN de Sala o Crear Sala', border: OutlineInputBorder())),

            const SizedBox(height: 24),

            SizedBox(

              width: double.infinity,

              child: FilledButton(

                onPressed: _procesando ? null : _ingresarComoSonidista,

                child: _procesando ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('ACCEDER AL PANEL'),

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

class _UrgentBlinkState extends State<_UrgentBlink> with SingleTickerProviderStateMixin {

  late final AnimationController _controller;

  @override

  void initState() {

    super.initState();

    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat(reverse: true);

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

class _SonidistaPageState extends State<SonidistaPage> with SingleTickerProviderStateMixin {

  bool _pantallaEncendida = true;

  bool _agruparPorRol = false;

  final AudioPlayer _alertaPlayer = AudioPlayer();

  StreamSubscription<QuerySnapshot>? _pedidosSub;

  bool _primerSnapshotPedidos = true;

  late final TabController _tabController;

  /// Último visor de PDF/cifrado abierto desde el setlist, para poder

  /// volver a él con un swipe hacia abajo desde la pestaña de Pedidos.

  Widget? _ultimoVisor;

  Offset? _inicioArrastrePedidos;

  @override

  void initState() {

    super.initState();

    WakelockPlus.enable();

    MiembrosSalaService.registrarPresencia(widget.codigoSala)
        .catchError((e) => debugPrint('No se pudo registrar presencia en la sala: $e'));

    _escucharPedidosNuevos();

    _tabController = TabController(length: 3, vsync: this);

  }

  @override

  void dispose() {

    WakelockPlus.disable();

    _pedidosSub?.cancel();

    _alertaPlayer.dispose();

    _tabController.dispose();

    super.dispose();

  }

  void _irAPedidos(Widget visorActual) {

    _ultimoVisor = visorActual;

    Navigator.pop(context);

    _tabController.animateTo(0);

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

        .snapshots()

        .listen((snapshot) {

      if (_primerSnapshotPedidos) {

        _primerSnapshotPedidos = false;

        return;

      }

      final hayPedidoNuevo = snapshot.docChanges.any((c) => c.type == DocumentChangeType.added);

      if (hayPedidoNuevo) _notificarPedidoNuevo();

    });

  }

  void _notificarPedidoNuevo() {

    HapticFeedback.vibrate(); // No-op en la mayoría de navegadores web; útil cuando haya app Android/iOS.

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

    final prefs = await SharedPreferences.getInstance();

    await prefs.clear();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(

      context,

      MaterialPageRoute(builder: (_) => const IngressMenuScreen()),

          (route) => false,

    );

  }



  static const List<Color> _paletaRemitentes = [

    Colors.blue, Colors.teal, Colors.deepOrange, Colors.purple,

    Colors.brown, Colors.indigo, Colors.pink, Colors.green,

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

          : (esUrgente ? Colors.redAccent.withOpacity(0.12) : context.acento.withOpacity(0.05)),

      leading: esUrgente && !isAtendido

          ? const Icon(Icons.warning_amber_rounded, color: Colors.redAccent)

          : CircleAvatar(

              radius: 15,

              backgroundColor: _colorPorRemitente(nombre, rol),

              child: Text(

                nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',

                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),

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

          Text('$nombre ($rol)'),

          if (respuestaActual.isNotEmpty)

            Text('Tu respuesta: $respuestaActual', style: TextStyle(color: context.acento, fontSize: 12, fontWeight: FontWeight.w500)),

        ],

      ),

      trailing: Row(

        mainAxisSize: MainAxisSize.min,

        children: [

          IconButton(

            icon: Icon(respuestaActual.isNotEmpty ? Icons.chat : Icons.chat_bubble_outline, color: Colors.blue),

            tooltip: 'Responder privado',

            onPressed: () => _mostrarDialogoRespuesta(context, d.id, pedidoTexto, nombre.isEmpty ? 'Músico' : nombre),

          ),

          IconButton(

            icon: Icon(isAtendido ? Icons.check_circle : Icons.radio_button_unchecked, color: isAtendido ? Colors.green : Colors.grey),

            onPressed: () => d.reference.update({'atendido': !isAtendido}),

          ),

          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => d.reference.delete()),

        ],

      ),

    );

    return esUrgente && !isAtendido ? _UrgentBlink(child: tile) : tile;

  }

  void _mostrarDialogoRespuesta(BuildContext context, String pedidoId, String pedidoTexto, String musico) {

    final controller = TextEditingController();

    showDialog(

      context: context,

      builder: (context) => AlertDialog(

        title: Text('Responder a $musico', style: const TextStyle(fontSize: 16)),

        content: Column(

          mainAxisSize: MainAxisSize.min,

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Text('Pedido: "$pedidoTexto"', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 13)),

            const SizedBox(height: 12),

            TextField(

              controller: controller,

              decoration: const InputDecoration(

                labelText: 'Escribir respuesta privada...',

                border: OutlineInputBorder(),

              ),

            ),

          ],

        ),

        actions: [

          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),

          TextButton(

            onPressed: () async {

              if (controller.text.trim().isNotEmpty) {

                await FirestoreService.responderPedido(widget.codigoSala, pedidoId, controller.text.trim());

              }

              if (context.mounted) Navigator.pop(context);

            },

            child: const Text('Enviar'),

          ),

        ],

      ),

    );

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: Text('Consola: ${widget.codigoSala}'),

        leading: IconButton(

          icon: const Icon(Icons.logout),

          tooltip: 'Cerrar Sesión',

          onPressed: () => _cerrarSesion(context),

        ),

        actions: [

          IconButton(

              icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),

              onPressed: () async {

                final confirm = await showDialog<bool>(

                    context: context,

                    builder: (c) => AlertDialog(

                        title: const Text('¿Borrar todo?'),

                        actions: [

                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('No')),

                          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Sí')),

                        ]

                    )

                );

                if (confirm == true) await FirestoreService.borrarTodo(widget.codigoSala);

              }

          ),

          IconButton(

            icon: Icon(_agruparPorRol ? Icons.groups : Icons.format_list_bulleted),

            tooltip: _agruparPorRol ? 'Agrupado por rol: activado' : 'Ver agrupado por rol',

            onPressed: () => setState(() => _agruparPorRol = !_agruparPorRol),

          ),

          IconButton(

            icon: Icon(_pantallaEncendida ? Icons.lightbulb : Icons.lightbulb_outline),

            tooltip: _pantallaEncendida ? 'Pantalla siempre encendida: activado' : 'Pantalla siempre encendida: desactivado',

            onPressed: _togglePantallaEncendida,

          ),

        ],

        bottom: TabBar(

          controller: _tabController,

          tabs: const [

            Tab(text: 'PEDIDOS'),

            Tab(text: 'HISTORIAL'),

            Tab(text: 'SETLIST'),

          ],

        ),

      ),

      body: TabBarView(

        controller: _tabController,

        children: [

          Listener(

            onPointerDown: (e) => _inicioArrastrePedidos = e.position,

            onPointerUp: _manejarSwipeAbajoEnPedidos,

            child: StreamBuilder<QuerySnapshot>(

        stream: FirebaseFirestore.instance

            .collection('salas')

            .doc(widget.codigoSala)

            .collection('pedidos')

            .orderBy('createdAt', descending: true)

            .snapshots(),

        builder: (context, snapshot) {

          if (snapshot.hasError) return Center(child: Text('Error de conexión: ${snapshot.error}'));

          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) return const Center(child: Text('Esperando pedidos...'));



          if (!_agruparPorRol) {

            return ListView.separated(

              itemCount: docs.length,

              separatorBuilder: (_, __) => const Divider(height: 1),

              itemBuilder: (context, i) => _buildPedidoTile(docs[i]),

            );

          }



          final grupos = <String, List<QueryDocumentSnapshot>>{};

          for (final d in docs) {

            final rol = ((d.data() as Map<String, dynamic>)['rol'] ?? 'Otro').toString();

            grupos.putIfAbsent(rol, () => []).add(d);

          }

          final rolesOrdenados = grupos.keys.toList()..sort();



          return ListView(

            children: [

              for (final rol in rolesOrdenados) ...[

                Container(

                  width: double.infinity,

                  color: _colorPorRemitente(rol, rol).withOpacity(0.15),

                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

                  child: Text(

                    '$rol (${grupos[rol]!.length})',

                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),

                  ),

                ),

                for (final d in grupos[rol]!) _buildPedidoTile(d),

              ],

            ],

          );

        },

      ),

          ),

          StreamBuilder<QuerySnapshot>(

            stream: FirebaseFirestore.instance

                .collection('salas')

                .doc(widget.codigoSala)

                .collection('pedidos')

                .where('atendido', isEqualTo: true)

                .snapshots(),

            builder: (context, snapshot) {

              if (snapshot.hasError) return Center(child: Text('Error de conexión: ${snapshot.error}'));

              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              // Se ordena en el cliente (en vez de .orderBy en la query) para

              // no depender de un índice compuesto de Firestore que no está

              // provisionado (where + orderBy en campos distintos lo exigiría).

              final docs = snapshot.data!.docs.toList()

                ..sort((a, b) {

                  final ta = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;

                  final tb = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;

                  if (ta == null || tb == null) return 0;

                  return tb.compareTo(ta);

                });

              if (docs.isEmpty) return const Center(child: Text('Todavía no atendiste ningún pedido', style: TextStyle(color: Colors.grey)));

              return ListView.separated(

                itemCount: docs.length,

                separatorBuilder: (_, __) => const Divider(height: 1),

                itemBuilder: (context, i) {

                  final data = docs[i].data() as Map<String, dynamic>;

                  final respuestaActual = data['respuesta'] ?? '';

                  return ListTile(

                    leading: const Icon(Icons.check_circle, color: Colors.green),

                    title: Text('${data['pedido']}', style: const TextStyle(decoration: TextDecoration.lineThrough)),

                    subtitle: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        Text('${data['nombre']} (${data['rol']})'),

                        if (respuestaActual.isNotEmpty)

                          Text('Tu respuesta: $respuestaActual', style: TextStyle(color: context.acento, fontSize: 12, fontWeight: FontWeight.w500)),

                      ],

                    ),

                  );

                },

              );

            },

          ),

          SetlistTab(

            codigoSala: widget.codigoSala,

            nombreUsuario: 'Sonidista',

            onIrAPedidos: _irAPedidos,

          ),

        ],

      ),

    );

  }

}