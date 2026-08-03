import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:firebase_core/firebase_core.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:google_sign_in/google_sign_in.dart';

import 'package:shared_preferences/shared_preferences.dart';



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
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<Map<String, dynamic>?> obtenerPerfil(String uid) async {
    final snap = await _ref(uid).get();
    return snap.data();
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



  void toggleTheme() {

    setState(() {

      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;

    });

  }



  @override

  Widget build(BuildContext context) {

    return MaterialApp(

      debugShowCheckedModeBanner: false,

      title: 'Sound Check Pro',

      theme: ThemeData(

        useMaterial3: true,

        colorSchemeSeed: Colors.deepPurple,

        brightness: Brightness.light,

      ),

      darkTheme: ThemeData(

        useMaterial3: true,

        colorSchemeSeed: Colors.deepPurple,

        brightness: Brightness.dark,

      ),

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

    return const Scaffold(

      body: Center(

        child: CircularProgressIndicator(color: Colors.deepPurple),

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

                const Icon(Icons.settings_input_component, size: 64, color: Colors.deepPurpleAccent),

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

            const Icon(Icons.settings_input_component, size: 80, color: Colors.deepPurpleAccent),

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

            if (user != null)

              OutlinedButton.icon(

                icon: const Icon(Icons.edit_note),

                label: const Text('MIS FRASES'),

                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FrasesAdminScreen())),

                style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),

              ),

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

                subtitle: Text(_pin, textAlign: TextAlign.center, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent)),

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

            backgroundColor: Colors.deepPurple.withOpacity(0.05),

            elevation: 0,

            shape: RoundedRectangleBorder(

                borderRadius: BorderRadius.circular(6),

                side: BorderSide(color: Colors.deepPurple.withOpacity(0.2))

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

  void dispose() {

    _customPedidoController.dispose();

    super.dispose();

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

              color: Colors.deepPurple,

              borderRadius: BorderRadius.circular(20),

            ),

            child: Center(

              child: Text('SALA: ${widget.codigoSala}',

                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),

            ),

          )

        ],

      ),

      body: Column(

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

                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepPurple),

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

class SonidistaPage extends StatelessWidget {

  final String codigoSala;

  const SonidistaPage({super.key, required this.codigoSala});



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

                await FirestoreService.responderPedido(codigoSala, pedidoId, controller.text.trim());

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

        title: Text('Consola: $codigoSala'),

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

                if (confirm == true) await FirestoreService.borrarTodo(codigoSala);

              }

          )

        ],

      ),

      body: StreamBuilder<QuerySnapshot>(

        stream: FirebaseFirestore.instance

            .collection('salas')

            .doc(codigoSala)

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

                tileColor: isAtendido ? Colors.transparent : Colors.deepPurple.withOpacity(0.05),

                title: Text(pedidoTexto, style: TextStyle(fontWeight: isAtendido ? FontWeight.normal : FontWeight.bold, fontSize: 16)),

                subtitle: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Text('${data['nombre']} (${data['rol']})'),

                    if (respuestaActual.isNotEmpty)

                      Text('Tu respuesta: $respuestaActual', style: const TextStyle(color: Colors.deepPurple, fontSize: 12, fontWeight: FontWeight.w500)),

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

    );

  }

}