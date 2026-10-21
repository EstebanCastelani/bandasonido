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
  String get etiqueta => switch (this) {
        UserRole.musico => 'Músico',
        UserRole.cantante => 'Cantante',
      };
}

/// Una persona puede tener varios roles a la vez (ej: canta y toca). Se
/// guardan en prefs/Firestore como un único texto legible ("Músico y
/// Cantante"), que es también lo que ve el sonidista en los pedidos.
String etiquetaRoles(Set<UserRole> roles) {
  final nombres = [for (final r in UserRole.values) if (roles.contains(r)) r.etiqueta];
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

/// Casillas para elegir uno o más roles al crear o unirse a una sala.
class SelectorRoles extends StatelessWidget {
  final Set<UserRole> seleccionados;
  final ValueChanged<Set<UserRole>> alCambiar;

  const SelectorRoles({super.key, required this.seleccionados, required this.alCambiar});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, bottom: 4),
          child: Text('Tu rol (podés marcar más de uno)'),
        ),
        for (final rol in UserRole.values)
          CheckboxListTile(
            title: Text(rol.etiqueta),
            value: seleccionados.contains(rol),
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (marcado) => alCambiar(
              marcado == true ? {...seleccionados, rol} : ({...seleccionados}..remove(rol)),
            ),
          ),
      ],
    );
  }
}



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
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
  ];

  static const List<String> _bemoles = [
    'C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B',
  ];

  static final RegExp _tokenAcorde = RegExp(
    r'^([A-G])(#|b)?((?:maj|min|dim|aug|sus|add|m)?[0-9⁰¹²³⁴⁵⁶⁷⁸⁹]*(?:[#b][0-9]+)?\+?)?(?:/([A-G])(#|b)?)?$',
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
      final lineasPdf = extractor.extractTextLines(startPageIndex: i, endPageIndex: i);
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
    final ordenadas = [...lineasPdf]..sort((a, b) => a.bounds.top.compareTo(b.bounds.top));
    final grupos = <List<sf_pdf.TextLine>>[];
    for (final l in ordenadas) {
      if (grupos.isNotEmpty && (l.bounds.top - grupos.last.first.bounds.top).abs() < 2.0) {
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

    salida.add(_ubicarFichas(acordes, (x) => columnaSobreLetra(x) + corrimiento, 0).trimRight());
    salida.add((' ' * (sangria + corrimiento)) + letra.texto);
  }

  /// Arma una línea poniendo cada "ficha" (acorde o palabra) en su columna,
  /// siempre con al menos un espacio entre una y otra.
  static String _ubicarFichas(_LineaPdf linea, int Function(double) columnaDe, int base) {
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
    sf_pdf.PdfDocument? documento;
    try {
      documento = sf_pdf.PdfDocument(inputBytes: bytes);
      try {
        // Reconstruye el layout con la posición real de cada acorde.
        final conPosiciones = CifradoPdfExtractor.extraer(documento);
        if (conPosiciones.isNotEmpty) return conPosiciones;
      } catch (e) {
        debugPrint('No se pudo reconstruir el layout del PDF, uso extracción simple: $e');
      }
      // Respaldo: extracción simple (los acordes pueden quedar desalineados).
      return sf_pdf.PdfTextExtractor(documento).extractText(layoutText: true).trim();
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
  static Future<({int actualizadas, int sinTexto, int fallidas})> regenerarCifrados(
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
              ? await supabase.storage.from(kSupabaseRepertorioBucket).download(storagePath)
              : await FirebaseStorage.instance.ref(storagePath).getData();
          if (bytes == null) {
            fallidas++;
          } else {
            final texto = extraerTextoPdf(bytes);
            if (texto.isEmpty) {
              sinTexto++;
            } else {
              await _ref(uid).doc(doc.id).update({'cifradoTexto': texto, 'cifradoVersion': kVersionCifrado});
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
  static Future<void> guardarCifradoRegenerado(String uid, String cancionId, String texto) async {
    await _ref(uid).doc(cancionId).update({'cifradoTexto': texto, 'cifradoVersion': kVersionCifrado});
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
  static Future<void> actualizarCifrado(String codigoSala, String itemId, String texto) async {
    await _ref(codigoSala).doc(itemId).update({'cifradoTexto': texto, 'cifradoVersion': kVersionCifrado});
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

  static String formatearMb(int bytes) => '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

  /// Los archivos que pasan tamanoMaximoBytes se convierten a MP3 en el
  /// navegador antes de subirlos (web/conversor_mp3.js, solo en web). Se
  /// apunta un poco por debajo del límite para no rozarlo.
  static const tamanoObjetivoMp3Bytes = 48 * 1024 * 1024;

  static CollectionReference<Map<String, dynamic>> _refUsuario(String uid) =>
      FirebaseFirestore.instance.collection('usuarios').doc(uid).collection('mis_secuencias');

  static CollectionReference<Map<String, dynamic>> _refSala(String codigoSala) =>
      FirebaseFirestore.instance.collection('salas').doc(codigoSala).collection('secuencias');

  static Stream<QuerySnapshot<Map<String, dynamic>>> streamMisSecuencias(String uid) {
    return _refUsuario(uid).orderBy('createdAt', descending: true).snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> streamSecuenciasSala(String codigoSala) {
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
    final audioUrl = supabase.storage.from(kSupabaseRepertorioBucket).getPublicUrl(storagePath);

    await _refUsuario(uid).add({
      'titulo': titulo,
      'audioUrl': audioUrl,
      'storagePath': storagePath,
      'storageProvider': 'supabase',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> renombrarSecuencia(String uid, String id, String titulo) async {
    await _refUsuario(uid).doc(id).update({'titulo': titulo});
  }

  /// Borra el archivo (best-effort) y el documento. Las copias que ya estén
  /// cargadas en alguna sala quedan apuntando a un audio que ya no existe;
  /// se ven en la lista pero no suenan, igual que un PDF borrado del setlist.
  static Future<void> eliminarSecuencia(String uid, String id, String? storagePath) async {
    if (storagePath != null && storagePath.isNotEmpty) {
      try {
        await supabase.storage.from(kSupabaseRepertorioBucket).remove([storagePath]);
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

  static Future<void> reordenarSala(String codigoSala, List<String> idsEnOrden) async {
    final batch = FirebaseFirestore.instance.batch();
    for (var i = 0; i < idsEnOrden.length; i++) {
      batch.update(_refSala(codigoSala).doc(idsEnOrden[i]), {'orden': i});
    }
    await batch.commit();
  }

  /// Tono (semitonos) y tempo (porcentaje, 100 = normal) de una secuencia de
  /// la sala. Se guardan en el documento para que a todos les suene igual.
  static Future<void> actualizarAjustes(
    String codigoSala,
    String id, {
    required int semitonos,
    required int tempoPorcentaje,
  }) async {
    await _refSala(codigoSala).doc(id).update({'semitonos': semitonos, 'tempoPorcentaje': tempoPorcentaje});
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
    throw UnsupportedError('La conversión a MP3 solo está disponible en la versión web.');

const bool reproductorWebDisponible = false;

Never _soloWeb() => throw UnsupportedError('El reproductor con tono y tempo solo está disponible en la versión web.');
void rwDesbloquear() => _soloWeb();
Future<double> rwCargar(String url) => _soloWeb();
void rwReproducir() => _soloWeb();
void rwPausar() => _soloWeb();
void rwDetener() => _soloWeb();
void rwIrA(double segundos) => _soloWeb();
void rwTempo(double valor) => _soloWeb();
void rwSemitonos(int valor) => _soloWeb();
void rwRepetir(bool valor) => _soloWeb();
({double posicion, double duracion, bool sonando, bool termino}) rwEstado() => _soloWeb();

/// Reproductor compartido por la pestaña Secuencias de la sala y por "Mis
/// secuencias": una sola pista a la vez (dar play a otra corta la anterior).
/// Cada dispositivo reproduce por su cuenta — no se sincroniza el play entre
/// los integrantes de la sala; quien maneja las secuencias en el show es el
/// que las dispara.
///
/// Tono y tempo independientes (como Music Speed Changer): en web se usa el
/// reproductor de web/reproductor_secuencias.js (SoundTouch), que es único
/// para toda la página; fuera de la web, audioplayers, que solo cambia el
/// tempo (soportaTono = false).
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

  String? idActual;
  PlayerState estado = PlayerState.stopped;
  Duration posicion = Duration.zero;
  Duration duracion = Duration.zero;
  bool repetir = false;
  bool cargando = false;
  double tempo = 1.0;
  int semitonos = 0;

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

  bool estaSonando(String id) => idActual == id && estado == PlayerState.playing;

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
      }
      notifyListeners();
    });
  }

  /// Play/pausa sobre la pista [id]. Si es otra distinta a la actual, corta
  /// la anterior y arranca la nueva desde el principio, con [tempo] (1 =
  /// normal) y [semitonos].
  Future<void> alternar(String id, String url, {double tempo = 1.0, int semitonos = 0}) async {
    // Antes de cualquier await: los navegadores de celular solo dejan
    // arrancar audio dentro del toque del usuario.
    if (_web) puente.rwDesbloquear();
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
    cargando = true;
    notifyListeners();
    try {
      if (_web) {
        _duenoWeb = this;
        _sondeo?.cancel();
        final segundos = await puente.rwCargar(url);
        // Se pidió otra pista (o la tomó otra pantalla) mientras cargaba.
        if (segundos < 0 || idActual != id || _duenoWeb != this) return;
        duracion = Duration(milliseconds: (segundos * 1000).round());
        puente.rwTempo(this.tempo);
        puente.rwSemitonos(this.semitonos);
        puente.rwRepetir(repetir);
        puente.rwReproducir();
        estado = PlayerState.playing;
        _empezarSondeo();
      } else {
        await _player!.stop();
        await _player!.setReleaseMode(repetir ? ReleaseMode.loop : ReleaseMode.stop);
        await _player!.play(UrlSource(url));
        await _player!.setPlaybackRate(this.tempo);
      }
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  /// Aplica tono y tempo a la pista [id] si es la que está cargada (si no,
  /// se toman la próxima vez que se le dé play). Se llama al mover los
  /// controles y cuando llega el cambio de otro integrante de la sala.
  Future<void> aplicarAjustes(String id, {required double tempo, required int semitonos}) async {
    if (idActual != id || (this.tempo == tempo && this.semitonos == semitonos)) return;
    this.tempo = tempo;
    this.semitonos = semitonos;
    if (_web) {
      if (_duenoWeb == this) {
        puente.rwTempo(tempo);
        puente.rwSemitonos(semitonos);
      }
    } else {
      await _player!.setPlaybackRate(tempo);
    }
    notifyListeners();
  }

  Future<void> detener() async {
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
      await _player!.setReleaseMode(repetir ? ReleaseMode.loop : ReleaseMode.stop);
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

  /// Con qué tempo (1 = normal) y tono arranca la pista al darle play.
  final double tempo;
  final int semitonos;

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
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: reproductor,
      builder: (context, _) {
        final esActual = reproductor.idActual == id;
        final sonando = reproductor.estaSonando(id);
        final maxMs = reproductor.duracion.inMilliseconds.toDouble();
        final posMs = reproductor.posicion.inMilliseconds.toDouble().clamp(0.0, maxMs > 0 ? maxMs : 0.0);
        return Container(
          color: esActual ? context.acento.withOpacity(0.08) : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: IconButton.filledTonal(
                  iconSize: 32,
                  icon: (esActual && reproductor.cargando)
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(sonando ? Icons.pause : Icons.play_arrow),
                  tooltip: sonando ? 'Pausar' : 'Reproducir',
                  onPressed: audioUrl.isEmpty
                      ? null
                      : () => reproductor.alternar(id, audioUrl, tempo: tempo, semitonos: semitonos).catchError((e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('No se pudo reproducir: $e'), backgroundColor: Colors.redAccent),
                              );
                            }
                          }),
                ),
                title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: subtitulo == null ? null : Text(subtitulo!, style: const TextStyle(fontSize: 12)),
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
                      Text(ReproductorSecuencias.formatear(reproductor.posicion), style: const TextStyle(fontSize: 12)),
                      Expanded(
                        child: Slider(
                          value: posMs,
                          max: maxMs,
                          onChanged: (v) => reproductor.irA(Duration(milliseconds: v.round())),
                        ),
                      ),
                      Text(ReproductorSecuencias.formatear(reproductor.duracion), style: const TextStyle(fontSize: 12)),
                      IconButton(
                        icon: const Icon(Icons.stop),
                        tooltip: 'Detener',
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

          final roles = rolesDesdeEtiqueta(rolStr);



          Navigator.pushReplacement(

            context,

            MaterialPageRoute(

              builder: (_) => RequestScreen(

                userName: nombre,

                roles: roles,

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

              const SizedBox(height: 12),

              OutlinedButton.icon(
                icon: const Icon(Icons.graphic_eq),
                label: const Text('MIS SECUENCIAS'),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MisSecuenciasScreen())),
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

  Set<UserRole> _roles = {UserRole.musico};

  bool _procesando = false;



  Future<void> _crearYEntrar() async {

    final nombre = _nameController.text.trim();

    if (nombre.isEmpty || _procesando) return;

    if (_roles.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marcá al menos un rol.')));

      return;

    }



    setState(() => _procesando = true);

    try {

      await AuthService.asegurarSesion();

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('tipo_login', 'usuario');

      await prefs.setString('sala_id', _pin);

      await prefs.setString('nombre', nombre);

      await prefs.setString('rol', etiquetaRoles(_roles));

      await _registrarSalaSiCorresponde(

        codigoSala: _pin,

        rolUsado: etiquetaRoles(_roles),

        nombre: nombre,

      );



      if (!mounted) return;



      Navigator.pushAndRemoveUntil(

        context,

        MaterialPageRoute(

          builder: (_) => RequestScreen(

            userName: nombre,

            roles: _roles,

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

            SelectorRoles(seleccionados: _roles, alCambiar: (roles) => setState(() => _roles = roles)),

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

  Set<UserRole> _roles = {UserRole.musico};

  bool _procesando = false;



  Future<void> _unirmeASala() async {

    final pin = _pinController.text.trim().toUpperCase();

    final nombre = _nameController.text.trim();



    if (nombre.isEmpty || pin.length != 8 || _procesando) return;

    if (_roles.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marcá al menos un rol.')));

      return;

    }



    setState(() => _procesando = true);

    try {

      await AuthService.asegurarSesion();

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('tipo_login', 'usuario');

      await prefs.setString('sala_id', pin);

      await prefs.setString('nombre', nombre);

      await prefs.setString('rol', etiquetaRoles(_roles));

      await _registrarSalaSiCorresponde(

        codigoSala: pin,

        rolUsado: etiquetaRoles(_roles),

        nombre: nombre,

      );



      if (!mounted) return;



      Navigator.pushAndRemoveUntil(

        context,

        MaterialPageRoute(

          builder: (_) => RequestScreen(

            userName: nombre,

            roles: _roles,

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

            SelectorRoles(seleccionados: _roles, alCambiar: (roles) => setState(() => _roles = roles)),

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
            roles: rolesDesdeEtiqueta(rol),
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

  final Set<UserRole> roles;

  final String codigoSala;

  const RequestScreen({super.key, required this.userName, required this.roles, required this.codigoSala});



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

    _tabController = TabController(length: 3, vsync: this);

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

    final rolStr = etiquetaRoles(widget.roles);

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

    final rolStr = etiquetaRoles(widget.roles);



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

          Padding(

            padding: const EdgeInsets.only(right: 8),

            child: Material(

              color: context.acento,

              borderRadius: BorderRadius.circular(20),

              child: InkWell(

                borderRadius: BorderRadius.circular(20),

                onTap: () {

                  Clipboard.setData(ClipboardData(text: widget.codigoSala));

                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código de sala copiado')));

                },

                child: Padding(

                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),

                  child: Text('SALA: ${widget.codigoSala}',

                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),

                ),

              ),

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

            Tab(text: 'SECUENCIAS'),

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

          SecuenciasTab(
            codigoSala: widget.codigoSala,
            nombreUsuario: widget.userName,
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

  Future<void> _confirmarAgregar(BuildContext context, String titulo, String pdfUrl, {String cifradoTexto = '', int? cifradoVersion}) async {

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

              'cifradoVersion': m['cifradoVersion'] as int?,

            };

          }).toList();

          String estadoDe(Map<String, dynamic> data) {

            return (data['estado'] as String?) ??

                ((data['completado'] as bool? ?? false) ? 'tocado' : 'pendiente');

          }

          final primerPendienteIndex = docs.indexWhere((d) => estadoDe(d.data()) == 'pendiente');

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

                              puedeTransponer: !esSonidista,

                              pdfUrl: pdfUrl,

                              versionCifrado: data['cifradoVersion'] as int?,

                              alRegenerar: (texto) => SetlistService.actualizarCifrado(codigoSala, doc.id, texto),

                            ),

                          ),

                        ),

                      ),

                    if (!esSonidista)

                      IconButton(

                        icon: const Icon(Icons.delete_outline, color: Colors.red),

                        onPressed: () => SetlistService.eliminarDelSetlist(codigoSala, doc.id),

                      ),

                  ],

                ),

              );

            }

            if (esSonidista) {

              return ListView.builder(itemCount: docs.length, itemBuilder: construirItem);

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

class _SecuenciasTabState extends State<SecuenciasTab> with AutomaticKeepAliveClientMixin {
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
  Future<void> _cargarDesdeMisSecuencias(Set<String> urlsEnSala, int cantidadEnSala) async {
    final user = AuthService.currentUser;
    if (user == null || user.isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Necesitás iniciar sesión para usar tus secuencias.')),
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
          builder: (context, scrollController) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: SecuenciasService.streamMisSecuencias(user.uid),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = RepertorioService.ordenarPorTitulo(snapshot.data!.docs);
              if (docs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No tenés secuencias todavía.\nSubilas desde "Mis secuencias" en el menú principal.',
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
                        hintText: 'Buscar secuencia...',
                        isDense: true,
                        prefixIcon: const Icon(Icons.search, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                              : (v) => setModalState(() => v == true ? elegidas[id] = data : elegidas.remove(id)),
                          secondary: Icon(Icons.graphic_eq, color: context.acento),
                          title: Text(data['titulo'] as String? ?? ''),
                          subtitle: yaCargada ? const Text('Ya está en la sala') : null,
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
                              ? 'Elegí las secuencias de hoy'
                              : 'CARGAR ${elegidas.length} A LA SALA'),
                          onPressed: elegidas.isEmpty ? null : () => Navigator.pop(context, true),
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
          SnackBar(content: Text('No se pudieron cargar: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _quitar(String id, String titulo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitar de la sala'),
        content: Text('¿Quitar "$titulo" de las secuencias de hoy? Sigue estando en la biblioteca de quien la subió.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Quitar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (_reproductor.idActual == id) await _reproductor.detener();
    await SecuenciasService.quitarDeSala(widget.codigoSala, id);
  }

  static String _textoSemitonos(int semitonos) {
    if (semitonos == 0) return 'Original';
    final signo = semitonos > 0 ? '+' : '−';
    return '$signo${semitonos.abs()} ${semitonos.abs() == 1 ? 'semitono' : 'semitonos'}';
  }

  /// "Tono +2 · Tempo 95%", o null si la secuencia está como se subió.
  static String? _resumenAjustes(int semitonos, int tempoPorcentaje) {
    final partes = [
      if (semitonos != 0) 'Tono ${semitonos > 0 ? '+' : '−'}${semitonos.abs()}',
      if (tempoPorcentaje != 100) 'Tempo $tempoPorcentaje%',
    ];
    return partes.isEmpty ? null : partes.join(' · ');
  }

  /// Tono (±12 semitonos) y tempo (50-150%) de una secuencia, como Music
  /// Speed Changer: uno no cambia al otro. Suena en vivo mientras se mueve y
  /// se guarda en la sala para todos (el tempo al soltar el deslizador).
  Future<void> _ajustarTonoYTempo(String id, String titulo, int semitonosIniciales, int tempoInicial) async {
    var semitonos = semitonosIniciales;
    var tempo = tempoInicial;

    void guardar() {
      SecuenciasService.actualizarAjustes(widget.codigoSala, id, semitonos: semitonos, tempoPorcentaje: tempo)
          .catchError((e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudo guardar el ajuste: $e'), backgroundColor: Colors.redAccent),
          );
        }
      });
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) {
          void cambiar({int? nuevoTono, int? nuevoTempo, bool guardarYa = true}) {
            setSheet(() {
              if (nuevoTono != null) semitonos = nuevoTono;
              if (nuevoTempo != null) tempo = nuevoTempo;
            });
            _reproductor.aplicarAjustes(id, tempo: tempo / 100, semitonos: semitonos);
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
                  Text(titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text(
                    'Se guarda para toda la sala. Tono y tempo se cambian por separado.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  const Text('TONO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        iconSize: 32,
                        icon: const Icon(Icons.remove),
                        tooltip: 'Bajar un semitono',
                        onPressed: soportaTono && semitonos > -12 ? () => cambiar(nuevoTono: semitonos - 1) : null,
                      ),
                      SizedBox(
                        width: 160,
                        child: Text(
                          _textoSemitonos(semitonos),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton.filledTonal(
                        iconSize: 32,
                        icon: const Icon(Icons.add),
                        tooltip: 'Subir un semitono',
                        onPressed: soportaTono && semitonos < 12 ? () => cambiar(nuevoTono: semitonos + 1) : null,
                      ),
                    ],
                  ),
                  if (!soportaTono)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'El cambio de tono por ahora solo funciona en la versión web.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(
                        child: Text('TEMPO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                      Text('$tempo%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        tooltip: 'Más lento (1%)',
                        onPressed: tempo > 50 ? () => cambiar(nuevoTempo: tempo - 1) : null,
                      ),
                      Expanded(
                        child: Slider(
                          value: tempo.toDouble(),
                          min: 50,
                          max: 150,
                          divisions: 100,
                          label: '$tempo%',
                          onChanged: (v) => cambiar(nuevoTempo: v.round(), guardarYa: false),
                          onChangeEnd: (_) => guardar(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        tooltip: 'Más rápido (1%)',
                        onPressed: tempo < 150 ? () => cambiar(nuevoTempo: tempo + 1) : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Restablecer (tono original, 100%)'),
                    onPressed: semitonos == 0 && tempo == 100 ? null : () => cambiar(nuevoTono: 0, nuevoTempo: 100),
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
              child: Text('No se pudieron cargar las secuencias: ${snapshot.error}', textAlign: TextAlign.center),
            ),
          );
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        final urlsEnSala = docs.map((d) => d.data()['audioUrl'] as String? ?? '').toSet();

        Widget fila(QueryDocumentSnapshot<Map<String, dynamic>> doc, int i) {
          final data = doc.data();
          final titulo = data['titulo'] as String? ?? '';
          final semitonos = (data['semitonos'] as num?)?.toInt() ?? 0;
          final tempoPorcentaje = (data['tempoPorcentaje'] as num?)?.toInt() ?? 100;
          // Si otro integrante cambió tono o tempo de la pista que está
          // cargada acá, se aplica en vivo (fuera del build).
          if (_reproductor.idActual == doc.id) {
            scheduleMicrotask(() => _reproductor.aplicarAjustes(
                  doc.id,
                  tempo: tempoPorcentaje / 100,
                  semitonos: semitonos,
                ));
          }
          final ajustes = _resumenAjustes(semitonos, tempoPorcentaje);
          return FilaSecuencia(
            key: ValueKey(doc.id),
            reproductor: _reproductor,
            id: doc.id,
            titulo: '${i + 1}. $titulo',
            audioUrl: data['audioUrl'] as String? ?? '',
            subtitulo: [
              'Cargada por ${data['subidoPor'] ?? '—'}',
              if (ajustes != null) ajustes,
            ].join(' · '),
            tempo: tempoPorcentaje / 100,
            semitonos: semitonos,
            acciones: widget.esSonidista
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.tune, color: ajustes != null ? context.acento : null),
                        tooltip: 'Tono y tempo',
                        onPressed: () => _ajustarTonoYTempo(doc.id, titulo, semitonos, tempoPorcentaje),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        tooltip: 'Quitar de la sala',
                        onPressed: () => _quitar(doc.id, titulo),
                      ),
                      ReorderableDragStartListener(index: i, child: const Icon(Icons.drag_handle)),
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
                          docs.isEmpty ? '' : '${docs.length} secuencia${docs.length == 1 ? '' : 's'} para hoy',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                      FilterChip(
                        avatar: const Icon(Icons.repeat, size: 18),
                        label: const Text('Repetir'),
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
                              Icon(Icons.graphic_eq, size: 64, color: context.acento.withOpacity(0.5)),
                              const SizedBox(height: 12),
                              Text(
                                widget.esSonidista
                                    ? 'Todavía no hay secuencias cargadas para hoy.'
                                    : 'Todavía no hay secuencias cargadas para hoy.\nTocá + para elegirlas de "Mis secuencias".',
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
                            separatorBuilder: (_, __) => const Divider(height: 1),
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
                              SecuenciasService.reordenarSala(widget.codigoSala, ids);
                            },
                          ),
              ),
            ],
          ),
          floatingActionButton: widget.esSonidista
              ? null
              : FloatingActionButton(
                  heroTag: 'agregar_secuencias',
                  tooltip: 'Cargar secuencias de hoy',
                  onPressed: () => _cargarDesdeMisSecuencias(urlsEnSala, docs.length),
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

                    style: const TextStyle(fontFamily: 'RobotoMono', fontSize: 12),

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

  Future<void> _regenerarCifrados(String uid) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regenerar cifrados'),
        content: const Text(
          'Se va a volver a leer cada PDF de tu biblioteca para rearmar el cifrado '
          'con los acordes ubicados como en el PDF original.\n\n'
          'Esto reemplaza el cifrado en texto que tengas guardado en cada canción '
          '(incluido lo que hayas editado a mano). Las canciones cuyo PDF no tiene '
          'texto seleccionable no se tocan.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Regenerar')),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    final progreso = ValueNotifier<String>('Preparando...');
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
      alAvanzar: (hechas, total) => progreso.value = 'Procesando $hechas de $total...',
    );
    progreso.dispose();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    final partes = <String>['${resultado.actualizadas} actualizadas'];
    if (resultado.sinTexto > 0) partes.add('${resultado.sinTexto} sin texto en el PDF');
    if (resultado.fallidas > 0) partes.add('${resultado.fallidas} con error');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cifrados: ${partes.join(', ')}.')));
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

      appBar: AppBar(
        title: const Text('Mi repertorio'),
        actions: [
          if (user != null && !user.isAnonymous)
            IconButton(
              icon: const Icon(Icons.auto_fix_high),
              tooltip: 'Regenerar cifrados desde los PDF',
              onPressed: () => _regenerarCifrados(user.uid),
            ),
        ],
      ),

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

                                MaterialPageRoute(
                                  builder: (_) => CifradoViewerScreen(
                                    titulo: titulo,
                                    cifradoOriginal: cifradoTexto,
                                    pdfUrl: pdfUrl,
                                    versionCifrado: data['cifradoVersion'] as int?,
                                    alRegenerar: (texto) => RepertorioService.guardarCifradoRegenerado(user.uid, id, texto),
                                  ),
                                ),

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
    final esPro = kFuncionesProGratisPorAhora || await UsuarioService.streamEsPro(uid).first;
    if (!esPro) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Función Pro'),
          content: const Text('Subir tus propias secuencias es parte de Sound Check Pro. Activá tu cuenta Pro para usar esta función.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido'))],
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
            title: Text(grandes.length == 1 ? 'Archivo demasiado grande' : 'Archivos demasiado grandes'),
            content: Text(
              '${grandes.map((a) => '• ${a.name} (${SecuenciasService.formatearMb(a.size)})').join('\n')}\n\n'
              'El máximo por archivo es ${SecuenciasService.formatearMb(limite)}. '
              'Convertilo a MP3 (a 320 kbps una canción entera ocupa unos 10-15 MB) y volvé a subirlo, '
              'o subilo desde la versión web, que lo convierte sola.',
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido'))],
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
        final contador = aSubir.length > 1 ? ' (${i + 1}/${aSubir.length})' : '';
        final punto = archivo.name.lastIndexOf('.');
        final titulo = punto > 0 ? archivo.name.substring(0, punto) : archivo.name;
        var nombreArchivo = archivo.name;
        var bytes = archivo.bytes!;
        try {
          if (bytes.length > limite) {
            setState(() => _progresoSubida = 'Convirtiendo a MP3$contador');
            final mp3 = await puente.convertirAMp3(
              bytes,
              SecuenciasService.tamanoObjetivoMp3Bytes,
              (p) {
                if (mounted) setState(() => _progresoSubida = 'Convirtiendo a MP3 ${(p * 100).round()}%$contador');
              },
            );
            bytes = mp3.bytes;
            nombreArchivo = '$titulo.mp3';
            convertidos.add('$titulo (${SecuenciasService.formatearMb(archivo.size)} → '
                '${SecuenciasService.formatearMb(bytes.length)}, ${mp3.kbps} kbps)');
          }
          setState(() => _progresoSubida = 'Subiendo$contador');
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
          title: Text(errores.isEmpty ? 'Secuencias subidas' : 'Algunas secuencias no se subieron'),
          content: SingleChildScrollView(
            child: Text([
              if (convertidos.isNotEmpty)
                'Se convirtieron a MP3 porque pasaban el máximo de '
                    '${SecuenciasService.formatearMb(limite)}:\n${convertidos.map((c) => '• $c').join('\n')}',
              if (errores.isNotEmpty) 'No se pudieron subir:\n${errores.map((e) => '• $e').join('\n')}',
            ].join('\n\n')),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido'))],
        ),
      );
    }
  }

  Future<void> _renombrar(String uid, String id, String tituloActual) async {
    final controller = TextEditingController(text: tituloActual);
    final nuevo = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renombrar secuencia'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Título'),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Guardar')),
        ],
      ),
    );
    if (nuevo == null || nuevo.trim().isEmpty) return;
    await SecuenciasService.renombrarSecuencia(uid, id, nuevo.trim());
  }

  Future<void> _confirmarEliminar(String uid, String id, String titulo, String? storagePath) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar secuencia'),
        content: Text('¿Eliminar "$titulo" de tu biblioteca?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
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
      appBar: AppBar(title: const Text('Mis secuencias')),
      body: (user == null || user.isAnonymous)
          ? const Center(child: Text('Necesitás iniciar sesión para tener tus secuencias.'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _busquedaController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Buscar secuencia...',
                      isDense: true,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: SecuenciasService.streamMisSecuencias(user.uid),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error al cargar: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final docs = RepertorioService.ordenarPorTitulo(snapshot.data!.docs);
                      if (docs.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'Todavía no subiste secuencias.\nTocá el botón de abajo para cargar tus pistas de audio (MP3, WAV, M4A...).',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      final secuencias = docs.map((d) => {...d.data(), 'id': d.id}).toList();
                      final filtradas = RepertorioService.filtrarPorTituloYTonalidad(
                        secuencias,
                        titulo: _busquedaController.text,
                        tonalidad: '',
                      );
                      if (filtradas.isEmpty) return const Center(child: Text('Sin resultados.'));
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
                                  tooltip: 'Renombrar',
                                  onPressed: () => _renombrar(user.uid, id, titulo),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Eliminar',
                                  onPressed: () =>
                                      _confirmarEliminar(user.uid, id, titulo, data['storagePath'] as String?),
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
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.upload_file),
              label: Text(_subiendo ? _progresoSubida : 'Subir secuencias'),
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

      SetlistService.actualizarTransposicion(widget.codigoSala!, widget.itemId!, nuevo);

    } else {

      setState(() => _semitonosLocal = nuevo);

    }

  }

  final _swipe = DetectorSwipe();

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
              ? (texto) => SetlistService.actualizarCifrado(widget.codigoSala!, item['id'] as String, texto)
              : null,

        ),

      ),

    );

  }

  void _manejarSwipe(PointerUpEvent evento) {

    final delta = _swipe.alSubir(evento);

    if (delta == null) return;

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

    final texto = ChordTransposer.transponerTexto(_cifradoRegenerado ?? widget.cifradoOriginal, semitonos);

    final etiquetaSemitonos = semitonos == 0 ? '0' : (semitonos > 0 ? '+$semitonos' : '$semitonos');

    return Scaffold(

      appBar: AppBar(

        title: Text(widget.titulo, overflow: TextOverflow.ellipsis),

        actions: [

          if (widget.puedeTransponer)

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

          if (widget.puedeTransponer) ...[

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

        ],

      ),

      body: Listener(

        onPointerDown: _swipe.alBajar,

        onPointerUp: _manejarSwipe,

        onPointerCancel: _swipe.alCancelar,

        // Los acordes quedan alineados con la letra solo si ninguna línea se
        // parte en dos: se achica la letra para que entre el renglón más
        // largo (Roboto Mono mide 0,6 veces su tamaño de ancho por carácter)
        // y, si aun así no entra, se puede desplazar hacia el costado.
        child: LayoutBuilder(

          builder: (context, constraints) {

            final columnas = texto.split('\n').fold<int>(0, (m, l) => max(m, l.length));

            final disponible = constraints.maxWidth - 32;

            final tamano = columnas == 0 ? 14.0 : (disponible / (columnas * 0.6)).clamp(9.0, 14.0);

            return SingleChildScrollView(

              padding: const EdgeInsets.all(16),

              child: SingleChildScrollView(

                scrollDirection: Axis.horizontal,

                child: SelectableText(

                  texto,

                  style: TextStyle(fontFamily: 'RobotoMono', fontSize: tamano, height: 1.6),

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

        onPointerDown: _swipe.alBajar,

        onPointerUp: _manejarSwipe,

        onPointerCancel: _swipe.alCancelar,

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

    _tabController = TabController(length: 4, vsync: this);

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

          // Con 4 pestañas los nombres no entran en el ancho de un celular:
          // la barra se desliza en vez de cortarlos.
          isScrollable: true,

          tabAlignment: TabAlignment.center,

          tabs: const [

            Tab(text: 'PEDIDOS'),

            Tab(text: 'HISTORIAL'),

            Tab(text: 'SETLIST'),

            Tab(text: 'SECUENCIAS'),

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

            esSonidista: true,

          ),

          SecuenciasTab(
            codigoSala: widget.codigoSala,
            nombreUsuario: 'Sonidista',
            esSonidista: true,
          ),

        ],

      ),

    );

  }

}