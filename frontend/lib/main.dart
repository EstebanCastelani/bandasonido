import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:file_picker/file_picker.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:firebase_core/firebase_core.dart';

import 'package:firebase_storage/firebase_storage.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:google_sign_in/google_sign_in.dart';

import 'package:shared_preferences/shared_preferences.dart';

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



void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  try {

    await Firebase.initializeApp(options: firebaseOptions);

  } catch (e) {

    debugPrint("Error inicializando Firebase: $e");

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

  static const List<AppPalette> todas = [consola, placa, wash, worklight];

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

  static Stream<User?> authStateChanges() => _auth.authStateChanges();

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

// --- SERVICIO DE REPERTORIO PERSONAL (BIBLIOTECA DE PARTITURAS) ---

/// Biblioteca de canciones/partituras propia de cada usuario.
/// PDFs en Storage: usuarios/{uid}/canciones/{archivo}.pdf
/// Metadatos en Firestore: usuarios/{uid}/mi_repertorio/{cancionId}
class RepertorioService {
  static CollectionReference<Map<String, dynamic>> _ref(String uid) =>
      FirebaseFirestore.instance.collection('usuarios').doc(uid).collection('mi_repertorio');

  static Stream<QuerySnapshot<Map<String, dynamic>>> streamRepertorio(String uid) {
    return _ref(uid).orderBy('createdAt', descending: true).snapshots();
  }

  /// Intenta extraer el texto embebido del PDF (best-effort). Si el PDF es
  /// un escaneo/foto no va a tener texto seleccionable y devuelve ''.
  static String extraerTextoPdf(Uint8List bytes) {
    try {
      final documento = sf_pdf.PdfDocument(inputBytes: bytes);
      final texto = sf_pdf.PdfTextExtractor(documento).extractText();
      documento.dispose();
      return texto.trim();
    } catch (e) {
      debugPrint('No se pudo extraer texto del PDF: $e');
      return '';
    }
  }

  /// Sube el PDF a Storage y crea el documento de metadatos en Firestore.
  /// Devuelve el mapa con los datos guardados (incluye pdfUrl).
  static Future<Map<String, dynamic>> subirCancion({
    required String uid,
    required String titulo,
    required String tonalidad,
    required String nombreArchivo,
    required Uint8List bytes,
    String cifradoTexto = '',
  }) async {
    final nombreUnico = '${DateTime.now().millisecondsSinceEpoch}_$nombreArchivo';
    final storagePath = 'usuarios/$uid/canciones/$nombreUnico';
    final storageRef = FirebaseStorage.instance.ref(storagePath);

    await storageRef.putData(bytes, SettableMetadata(contentType: 'application/pdf'));
    final pdfUrl = await storageRef.getDownloadURL();

    final data = {
      'titulo': titulo,
      'tonalidad': tonalidad,
      'pdfUrl': pdfUrl,
      'storagePath': storagePath,
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

  static Future<void> eliminarCancion({
    required String uid,
    required String cancionId,
    String? storagePath,
  }) async {
    if (storagePath != null && storagePath.isNotEmpty) {
      try {
        await FirebaseStorage.instance.ref(storagePath).delete();
      } catch (e) {
        debugPrint('No se pudo borrar el archivo de Storage: $e');
      }
    }
    await _ref(uid).doc(cancionId).delete();
  }

  /// Busca canciones por título en TODAS las bibliotecas (collectionGroup).
  /// Firestore no soporta full-text search: se trae un lote reciente y se
  /// filtra por substring del lado del cliente.
  static Future<List<Map<String, dynamic>>> buscarEnTodasLasBibliotecas(String query) async {
    final snap = await FirebaseFirestore.instance
        .collectionGroup('mi_repertorio')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .get();

    final queryLower = query.trim().toLowerCase();
    return snap.docs
        .map((d) => {...d.data(), 'id': d.id})
        .where((c) => queryLower.isEmpty || (c['titulo'] as String? ?? '').toLowerCase().contains(queryLower))
        .toList();
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

  static Future<void> marcarCompletado(String codigoSala, String itemId, bool completado) async {
    await _ref(codigoSala).doc(itemId).update({
      'completado': completado,
      'completadoAt': completado ? FieldValue.serverTimestamp() : FieldValue.delete(),
    });
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

  }) async {

    await _pedidosRef(codigo).add({

      'sala_id': codigo, // Ajustado para coincidir con tu índice de Firebase

      'nombre': nombre,

      'rol': rol,

      'pedido': pedido,

      'atendido': false,

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



    final destino = AuthService.currentUser == null
        ? const AuthScreen()
        : const IngressMenuScreen();

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

          if (user != null)

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

      body: Container(

        padding: const EdgeInsets.all(24),

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

            if (user != null) ...[

              const SizedBox(height: 8),

              Text(

                'Sesión: ${user.email ?? user.displayName ?? user.uid}',

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

            if (user != null) ...[

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

            const SizedBox(height: 32),

            TextButton(

              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SonidistaPinScreen())),

              child: const Text('Acceso Sonidista', style: TextStyle(color: Colors.grey)),

            ),

          ],

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

  final String _pin = (100000 + Random().nextInt(900000)).toString();

  UserRole? _role = UserRole.musico;

  bool _procesando = false;



  Future<void> _crearYEntrar() async {

    final nombre = _nameController.text.trim();

    if (nombre.isEmpty || _procesando) return;



    setState(() => _procesando = true);

    try {

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('tipo_login', 'usuario');

      await prefs.setString('sala_id', _pin);

      await prefs.setString('nombre', nombre);

      await prefs.setString('rol', _role == UserRole.cantante ? 'Cantante' : 'Músico');



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

  const UnirmeSalaScreen({super.key});

  @override

  State<UnirmeSalaScreen> createState() => _UnirmeSalaScreenState();

}



class _UnirmeSalaScreenState extends State<UnirmeSalaScreen> {

  final _nameController = TextEditingController();

  final _pinController = TextEditingController();

  UserRole? _role = UserRole.musico;

  bool _procesando = false;



  Future<void> _unirmeASala() async {

    final pin = _pinController.text.trim();

    final nombre = _nameController.text.trim();



    if (nombre.isEmpty || pin.length != 6 || _procesando) return;



    setState(() => _procesando = true);

    try {

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('tipo_login', 'usuario');

      await prefs.setString('sala_id', pin);

      await prefs.setString('nombre', nombre);

      await prefs.setString('rol', _role == UserRole.cantante ? 'Cantante' : 'Músico');



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

            TextField(controller: _pinController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'PIN de 6 dígitos', border: OutlineInputBorder())),

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



// --- PANTALLA DE PEDIDOS INDIVIDUAL (MÚSICO/CANTANTE) ---

class RequestScreen extends StatefulWidget {

  final String userName;

  final UserRole role;

  final String codigoSala;

  const RequestScreen({super.key, required this.userName, required this.role, required this.codigoSala});



  @override

  State<RequestScreen> createState() => _RequestScreenState();

}



class _RequestScreenState extends State<RequestScreen> {

  final _customPedidoController = TextEditingController();

  bool _pantallaEncendida = true;

  @override

  void initState() {

    super.initState();

    WakelockPlus.enable();

  }

  @override

  void dispose() {

    WakelockPlus.disable();

    _customPedidoController.dispose();

    super.dispose();

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

    FirestoreService.enviarPedido(

        codigo: widget.codigoSala,

        nombre: widget.userName,

        rol: rolStr,

        pedido: texto.trim()

    );

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(content: Text('Enviado: ${texto.trim()}'), duration: const Duration(milliseconds: 400)),

    );

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



    return DefaultTabController(

      length: 2,

      child: Scaffold(

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

        bottom: const TabBar(

          tabs: [

            Tab(text: 'PEDIDOS'),

            Tab(text: 'SETLIST'),

          ],

        ),

      ),

      body: TabBarView(

        children: [

          Column(

        children: [

          Expanded(

            flex: 3,

            child: Builder(builder: (context) {

              final user = AuthService.currentUser;

              if (user == null) {

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

                const SizedBox(width: 8),

                IconButton.filled(

                  icon: const Icon(Icons.send, size: 18),

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

                          isAtendido ? Icons.check_circle : Icons.access_time_filled,

                          color: isAtendido ? Colors.green : Colors.orange,

                          size: 16,

                        ),

                        title: Text(

                          "${data['pedido']}",

                          style: TextStyle(

                            fontSize: 12,

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

          SetlistTab(codigoSala: widget.codigoSala, nombreUsuario: widget.userName),

        ],

      ),

      ),

    );

  }

}



// --- LISTA DE TEMAS COMPARTIDA (SETLIST DE SALA) ---

class SetlistTab extends StatelessWidget {

  final String codigoSala;

  final String nombreUsuario;

  const SetlistTab({super.key, required this.codigoSala, required this.nombreUsuario});

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

              title: const Text('Buscar en todas las bibliotecas'),

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

      await _buscarGlobal(context);

    }

  }

  Future<void> _elegirDesdeBiblioteca(BuildContext context) async {

    final user = AuthService.currentUser;

    if (user == null) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(content: Text('Necesitás iniciar sesión para usar tu biblioteca.')),

      );

      return;

    }

    final seleccion = await showModalBottomSheet<Map<String, dynamic>>(

      context: context,

      isScrollControlled: true,

      builder: (context) => DraggableScrollableSheet(

        expand: false,

        builder: (context, scrollController) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(

          stream: RepertorioService.streamRepertorio(user.uid),

          builder: (context, snapshot) {

            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

            final docs = snapshot.data!.docs;

            if (docs.isEmpty) return const Center(child: Text('Tu biblioteca está vacía.'));

            return ListView.builder(

              controller: scrollController,

              itemCount: docs.length,

              itemBuilder: (context, i) {

                final data = docs[i].data();

                return ListTile(

                  leading: Icon(Icons.picture_as_pdf, color: context.acento),

                  title: Text(data['titulo'] as String? ?? ''),

                  subtitle: Text(data['tonalidad'] as String? ?? ''),

                  onTap: () => Navigator.pop(context, data),

                );

              },

            );

          },

        ),

      ),

    );

    if (seleccion == null || !context.mounted) return;

    await _confirmarAgregar(

      context,

      seleccion['titulo'] as String? ?? '',

      seleccion['pdfUrl'] as String? ?? '',

      cifradoTexto: seleccion['cifradoTexto'] as String? ?? '',

    );

  }

  Future<void> _buscarGlobal(BuildContext context) async {

    final controller = TextEditingController();

    final seleccion = await showModalBottomSheet<Map<String, dynamic>>(

      context: context,

      isScrollControlled: true,

      builder: (context) {

        List<Map<String, dynamic>> resultados = [];

        bool buscando = false;

        bool buscoAlMenosUnaVez = false;

        return StatefulBuilder(

          builder: (context, setModalState) {

            Future<void> ejecutarBusqueda() async {

              setModalState(() => buscando = true);

              final r = await RepertorioService.buscarEnTodasLasBibliotecas(controller.text);

              setModalState(() {

                resultados = r;

                buscando = false;

                buscoAlMenosUnaVez = true;

              });

            }

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

                            controller: controller,

                            autofocus: true,

                            decoration: const InputDecoration(

                              hintText: 'Buscar canción por título...',

                              border: OutlineInputBorder(),

                            ),

                            onSubmitted: (_) => ejecutarBusqueda(),

                          ),

                        ),

                        const SizedBox(width: 8),

                        IconButton.filled(

                          icon: const Icon(Icons.search),

                          onPressed: ejecutarBusqueda,

                        ),

                      ],

                    ),

                    const SizedBox(height: 12),

                    if (buscando) const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()),

                    if (!buscando && buscoAlMenosUnaVez && resultados.isEmpty)

                      const Padding(padding: EdgeInsets.all(16), child: Text('Sin resultados.')),

                    if (!buscando && resultados.isNotEmpty)

                      Flexible(

                        child: ListView.builder(

                          shrinkWrap: true,

                          itemCount: resultados.length,

                          itemBuilder: (context, i) {

                            final data = resultados[i];

                            return ListTile(

                              leading: Icon(Icons.picture_as_pdf, color: context.acento),

                              title: Text(data['titulo'] as String? ?? ''),

                              subtitle: Text(data['tonalidad'] as String? ?? ''),

                              onTap: () => Navigator.pop(context, data),

                            );

                          },

                        ),

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

          final primerPendienteIndex = docs.indexWhere(

            (d) => (d.data()['completado'] as bool? ?? false) == false,

          );

          return ListView.separated(

            itemCount: docs.length,

            separatorBuilder: (_, __) => const Divider(height: 1),

            itemBuilder: (context, i) {

              final doc = docs[i];

              final data = doc.data();

              final titulo = data['titulo'] as String? ?? '';

              final subidoPor = data['subidoPor'] as String? ?? '';

              final pdfUrl = data['pdfUrl'] as String? ?? '';

              final cifradoTexto = data['cifradoTexto'] as String? ?? '';

              final completado = data['completado'] as bool? ?? false;

              final esProximo = !completado && i == primerPendienteIndex;

              return ListTile(

                tileColor: esProximo ? context.acento.withOpacity(0.06) : null,

                leading: IconButton(

                  icon: Icon(

                    completado ? Icons.check_circle : Icons.check_circle_outline,

                    color: completado ? Colors.green : context.acento.withOpacity(0.5),

                  ),

                  tooltip: completado ? 'Marcar como pendiente' : 'Marcar como tocado',

                  onPressed: () => SetlistService.marcarCompletado(codigoSala, doc.id, !completado),

                ),

                title: Row(

                  children: [

                    Flexible(

                      child: Text(

                        titulo,

                        style: TextStyle(

                          decoration: completado ? TextDecoration.lineThrough : null,

                          color: completado ? Colors.grey : null,

                        ),

                      ),

                    ),

                    if (esProximo) ...[

                      const SizedBox(width: 8),

                      Container(

                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),

                        decoration: BoxDecoration(

                          color: context.acento,

                          borderRadius: BorderRadius.circular(10),

                        ),

                        child: const Text(

                          'PRÓXIMO',

                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),

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

      floatingActionButton: FloatingActionButton(

        onPressed: () => _agregarCancion(context),

        tooltip: 'Agregar canción',

        child: const Icon(Icons.add),

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

      body: user == null

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

      floatingActionButton: user == null

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

      body: user == null

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

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {

                  return const Center(child: Text('Todavía no subiste ninguna canción.'));

                }

                return ListView.separated(

                  itemCount: docs.length,

                  separatorBuilder: (_, __) => const Divider(height: 1),

                  itemBuilder: (context, i) {

                    final doc = docs[i];

                    final data = doc.data();

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

                            onPressed: () => _editarCancion(user.uid, doc.id, titulo, tonalidad, cifradoTexto),

                          ),

                          IconButton(

                            icon: const Icon(Icons.delete, color: Colors.red),

                            onPressed: () => _confirmarEliminar(user.uid, doc.id, data['storagePath'] as String?),

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

      floatingActionButton: user == null || _subiendo

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

  const CifradoViewerScreen({super.key, required this.titulo, required this.cifradoOriginal});

  @override

  State<CifradoViewerScreen> createState() => _CifradoViewerScreenState();

}

class _CifradoViewerScreenState extends State<CifradoViewerScreen> {

  int _semitonos = 0;

  @override

  Widget build(BuildContext context) {

    final texto = ChordTransposer.transponerTexto(widget.cifradoOriginal, _semitonos);

    final etiquetaSemitonos = _semitonos == 0 ? '0' : (_semitonos > 0 ? '+$_semitonos' : '$_semitonos');

    return Scaffold(

      appBar: AppBar(

        title: Text(widget.titulo, overflow: TextOverflow.ellipsis),

        actions: [

          IconButton(

            icon: const Icon(Icons.remove_circle_outline),

            tooltip: 'Bajar un semitono',

            onPressed: () => setState(() => _semitonos--),

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

            onPressed: () => setState(() => _semitonos++),

          ),

          IconButton(

            icon: const Icon(Icons.refresh),

            tooltip: 'Restablecer tono original',

            onPressed: _semitonos == 0 ? null : () => setState(() => _semitonos = 0),

          ),

        ],

      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(16),

        child: SelectableText(

          texto,

          style: const TextStyle(fontFamily: 'monospace', fontSize: 14, height: 1.6),

        ),

      ),

    );

  }

}

// --- VISOR DE PDF ---

class PdfViewerScreen extends StatefulWidget {

  final String titulo;

  final String pdfUrl;

  const PdfViewerScreen({super.key, required this.titulo, required this.pdfUrl});

  @override

  State<PdfViewerScreen> createState() => _PdfViewerScreenState();

}

class _PdfViewerScreenState extends State<PdfViewerScreen> {

  String? _error;

  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.black,

      appBar: AppBar(

        title: Text(widget.titulo, overflow: TextOverflow.ellipsis),

      ),

      body: _error != null

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

    final pin = _pinController.text.trim();

    if (pin.isEmpty || _procesando) return;



    setState(() => _procesando = true);

    try {

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('tipo_login', 'sonidista');

      await prefs.setString('sala_id', pin);



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

            TextField(controller: _pinController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'PIN de Sala o Crear Sala', border: OutlineInputBorder())),

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

class SonidistaPage extends StatefulWidget {

  final String codigoSala;

  const SonidistaPage({super.key, required this.codigoSala});

  @override

  State<SonidistaPage> createState() => _SonidistaPageState();

}

class _SonidistaPageState extends State<SonidistaPage> {

  bool _pantallaEncendida = true;

  @override

  void initState() {

    super.initState();

    WakelockPlus.enable();

  }

  @override

  void dispose() {

    WakelockPlus.disable();

    super.dispose();

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

    return DefaultTabController(

      length: 2,

      child: Scaffold(

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

            icon: Icon(_pantallaEncendida ? Icons.lightbulb : Icons.lightbulb_outline),

            tooltip: _pantallaEncendida ? 'Pantalla siempre encendida: activado' : 'Pantalla siempre encendida: desactivado',

            onPressed: _togglePantallaEncendida,

          ),

        ],

        bottom: const TabBar(

          tabs: [

            Tab(text: 'PEDIDOS'),

            Tab(text: 'SETLIST'),

          ],

        ),

      ),

      body: TabBarView(

        children: [

          StreamBuilder<QuerySnapshot>(

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



          return ListView.separated(

            itemCount: docs.length,

            separatorBuilder: (_, __) => const Divider(height: 1),

            itemBuilder: (context, i) {

              final d = docs[i];

              final data = d.data() as Map<String, dynamic>;

              final isAtendido = data['atendido'] ?? false;

              final pedidoTexto = data['pedido'] ?? '';

              final respuestaActual = data['respuesta'] ?? '';



              return ListTile(

                tileColor: isAtendido ? Colors.transparent : context.acento.withOpacity(0.05),

                title: Text(pedidoTexto, style: TextStyle(fontWeight: isAtendido ? FontWeight.normal : FontWeight.bold, fontSize: 16)),

                subtitle: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Text('${data['nombre']} (${data['rol']})'),

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

                      onPressed: () => _mostrarDialogoRespuesta(context, d.id, pedidoTexto, data['nombre'] ?? 'Músico'),

                    ),

                    IconButton(

                      icon: Icon(isAtendido ? Icons.check_circle : Icons.radio_button_unchecked, color: isAtendido ? Colors.green : Colors.grey),

                      onPressed: () => d.reference.update({'atendido': !isAtendido}),

                    ),

                    IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => d.reference.delete()),

                  ],

                ),

              );

            },

          );

        },

      ),

          SetlistTab(codigoSala: widget.codigoSala, nombreUsuario: 'Sonidista'),

        ],

      ),

      ),

    );

  }

}