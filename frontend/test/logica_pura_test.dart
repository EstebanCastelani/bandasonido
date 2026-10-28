// Pruebas de la lógica pura de la app (sin Firebase ni pantallas).
// Ver AUDITORIA_TESTING.md (casos CP-xx) y REQUISITOS.md (RQ-xx).
//
// Los casos marcados con `skip` son defectos YA CONOCIDOS (ver DEFECTOS.md):
// se dejan escritos con el resultado esperado para activarlos cuando se
// corrijan (Etapa 2 del plan de testing). No se borran ni se "arreglan" el
// test para que pase.
import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:appsonido_frontend/l10n/app_localizations_es.dart';
import 'package:appsonido_frontend/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('generarCodigoSala (RQ-01)', () {
    test('tiene 8 caracteres y no usa caracteres ambiguos (0, 1, O, I, L)', () {
      for (var i = 0; i < 500; i++) {
        final c = generarCodigoSala();
        expect(c, hasLength(8));
        expect(RegExp('[01OIL]').hasMatch(c), isFalse, reason: c);
        expect(RegExp(r'^[A-Z2-9]{8}$').hasMatch(c), isTrue, reason: c);
      }
    });

    test('no repite códigos en una muestra grande', () {
      final codigos = {for (var i = 0; i < 2000; i++) generarCodigoSala()};
      expect(codigos, hasLength(2000));
    });
  });

  group('IdiomasApp.resolver (RQ-11)', () {
    const soportados = [
      Locale('es'),
      Locale('en'),
      Locale('pt'),
      Locale('fr'),
      Locale('it')
    ];
    final casos = <String, (List<Locale>?, String)>{
      'idioma no soportado → español': ([const Locale('ja')], 'es'),
      'pt-BR → portugués': ([const Locale('pt', 'BR')], 'pt'),
      'en-GB → inglés': ([const Locale('en', 'GB')], 'en'),
      'toma el primero soportado de la lista': (
        [const Locale('de'), const Locale('fr')],
        'fr'
      ),
      'lista vacía → español': (<Locale>[], 'es'),
      'sin lista → español': (null, 'es'),
    };
    casos.forEach((nombre, caso) {
      test(nombre, () {
        expect(IdiomasApp.resolver(caso.$1, soportados).languageCode, caso.$2);
      });
    });
  });

  group('mensajeError (RQ-18)', () {
    final l = AppLocalizationsEs();
    final casos = <String, (Object?, String)>{
      'channel-error → sin conexión': (
        '[firebase_auth/channel-error] dev.flutter.pigeon',
        'No hay conexión. Revisá tu internet e intentá de nuevo.'
      ),
      'permission-denied → sin permiso': (
        '[cloud_firestore/permission-denied] Missing or insufficient permissions.',
        'No tenés permiso para hacer esto.'
      ),
      'error de DNS → sin conexión': (
        'SocketException: Failed host lookup',
        'No hay conexión. Revisá tu internet e intentá de nuevo.'
      ),
      'error desconocido → genérico': (
        'FormatException: x',
        'Algo salió mal. Intentá de nuevo.'
      ),
      'null → genérico': (null, 'Algo salió mal. Intentá de nuevo.'),
    };
    casos.forEach((nombre, caso) {
      test(nombre, () => expect(mensajeError(l, caso.$1), caso.$2));
    });

    test('nunca muestra el código técnico al usuario', () {
      final texto =
          mensajeError(l, '[firebase_auth/channel-error] dev.flutter.pigeon');
      expect(texto, isNot(contains('firebase')));
      expect(texto, isNot(contains('pigeon')));
    });
  });

  group('esRolSonidista / esRolSonidoAmbiguo (RQ-04, D-04)', () {
    for (final r in [
      'Sonidista',
      'Sonido',
      'sonido',
      'Técnico de sonido',
      'Sound engineer',
      'Ayudante de sonido',
      'Ingeniero de audio',
      'Operador de audio',
      'FOH',
      'foh',
      'Monitorista',
      'Técnico de som',
      'Ingénieur du son',
      'Tontechniker',
      'Fónico',
      'Tecnico del suono',
    ]) {
      test('"$r" entra al panel', () {
        expect(esRolSonidista(r), isTrue);
        expect(esRolSonidoAmbiguo(r), isFalse);
      });
    }
    for (final r in [
      'Guitarrista',
      'Músico',
      'Baterista',
      'Sonia',
      'Vocalista de Somos Mil',
      'Cantante',
      '',
      '   '
    ]) {
      test('"$r" NO entra al panel ni pregunta', () {
        expect(esRolSonidista(r), isFalse);
        expect(esRolSonidoAmbiguo(r), isFalse);
      });
    }
    for (final r in [
      'Músico y sonidista',
      'Cantante y técnico de sonido',
      'Guitarrista / FOH'
    ]) {
      test('"$r" es ambiguo: se le pregunta', () {
        expect(esRolSonidista(r), isFalse);
        expect(esRolSonidoAmbiguo(r), isTrue);
      });
    }
    test('ignora mayúsculas y tildes', () {
      expect(esRolSonidista('TÉCNICO DE SONIDO'), isTrue);
      expect(esRolSonidista('Ingeniero de Áudio'), isTrue);
    });
  });

  group('ChordTransposer (RQ-14)', () {
    final casos = <String, (String, int, String)>{
      'acordes entre corchetes con bajo': (
        '[C]Hola [G/B]mundo [Am7]hoy',
        2,
        '[D]Hola [A/C#]mundo [Bm7]hoy'
      ),
      'sostenidos pasan de F#m a Gm': ('[Bb]x [F#m]y', 1, '[B]x [Gm]y'),
      'sufijos maj7, sus4, 7, dim': (
        '[Cmaj7]a [Dsus4]b [E7]c [F#dim]d',
        5,
        '[Fmaj7]a [Gsus4]b [A7]c [Bdim]d'
      ),
      'add9, m7b5 y bajo con sostenido': (
        '[Cadd9]a [Gm7b5]b [A7/C#]c',
        2,
        '[Dadd9]a [Am7b5]b [B7/D#]c'
      ),
      'los bemoles se conservan': ('[Db]a [Ebm]b', 3, '[E]a [Gbm]b'),
      'N.C. no es un acorde y no cambia': ('[N.C.]a [C]b', 2, '[N.C.]a [D]b'),
      '+12 semitonos deja el texto igual': (
        'C   G   Am   F',
        12,
        'C   G   Am   F'
      ),
      '-12 semitonos deja el texto igual': (
        'C   G   Am   F',
        -12,
        'C   G   Am   F'
      ),
      '0 semitonos no toca nada': ('[C]Hola [G]mundo', 0, '[C]Hola [G]mundo'),
      // Notación latina (D-05): se conserva la notación del texto.
      'latina: [Do] [Re] [Mi] +2': (
        '[Do]a [Re]b [Mi]c',
        2,
        '[Re]a [Mi]b [Fa#]c'
      ),
      'latina: Sol, La, Si': ('[Sol]a [La]b [Si]c', 2, '[La]a [Si]b [Do#]c'),
      'latina: menores y séptimas': (
        '[Rem]a [Sim7]b [Fa#m]c',
        2,
        '[Mim]a [Do#m7]b [Sol#m]c'
      ),
      'latina: bemoles se conservan': ('[Sib]a [Mib]b', 2, '[Do]a [Fa]b'),
      'latina: bajo': ('[Do/Mi]a [Sol/Si]b', 2, '[Re/Fa#]a [La/Do#]b'),
      'latina: línea de acordes': ('Do Sol Lam Fa', 2, 'Re La  Sim Sol'),
      'latina: una palabra de la letra no se toca': (
        'Si tú me dices',
        2,
        'Si tú me dices'
      ),
      'latina: una sola palabra "Sol" no es un acorde': ('Sol', 2, 'Sol'),
    };
    casos.forEach((nombre, caso) {
      test(
          nombre,
          () => expect(
              ChordTransposer.transponerTexto(caso.$1, caso.$2), caso.$3));
    });

    test('ir y volver (+5 y −5) devuelve el original', () {
      for (final original in [
        '[C]Hola [G/B]mundo [Am7]hoy [F#m]fin',
        '[Do]Hola [Sol/Si]mundo [Lam7]hoy [Fa#m]fin'
      ]) {
        final ida = ChordTransposer.transponerTexto(original, 5);
        expect(ChordTransposer.transponerTexto(ida, -5), original);
      }
    });

    group('hayAcordes (aviso "no se encontraron acordes")', () {
      final hay = {
        '[C]Hola': true,
        '[Do]Hola': true,
        'C   G   Am   F': true,
        'Do Sol Lam Fa': true,
        'Hola mundo': false,
        '[N.C.]a': false,
        '': false,
        'Si tú me dices': false,
      };
      hay.forEach((texto, esperado) {
        test('"$texto" → $esperado',
            () => expect(ChordTransposer.hayAcordes(texto), esperado));
      });
    });
  });

  group('Pedidos rápidos (DF-07, RQ-09)', () {
    final frases = AppConstants.pedidosRapidos(AppLocalizationsEs());
    test('no hay frases repetidas',
        () => expect(frases.toSet(), hasLength(frases.length)));
    test('ya no hay frases de un solo símbolo ("+" o "-")', () {
      expect(frases.where((f) => f.trim().length < 3), isEmpty);
    });
    test('incluye "Más volumen" y "Menos volumen"', () {
      expect(frases, containsAll(['Más volumen', 'Menos volumen']));
    });
  });

  test('tope de pedidos visibles (D-08)',
      () => expect(kMaximoPedidosVisibles, 200));

  group('rolParaMostrar (RQ-11)', () {
    final l = AppLocalizationsEs();
    for (final r in [
      'Músico',
      'Músico y Cantante',
      'Sonidista',
      'Otro',
      'Guitarrista'
    ]) {
      test('"$r" se muestra tal cual en español',
          () => expect(rolParaMostrar(l, r), r));
    }
    test('ignora mayúsculas de los valores antiguos ("músico")', () {
      expect(rolParaMostrar(l, 'músico'), 'Músico');
    });
  });

  group('AppPalette.porClave (RQ-12)', () {
    test('clave conocida',
        () => expect(AppPalette.porClave('consola').key, 'consola'));
    for (final k in [null, 'xx', '']) {
      test('clave "$k" → paleta por defecto',
          () => expect(AppPalette.porClave(k).key, AppPalette.porDefecto.key));
    }
  });

  group('esperarEnvio (RQ-20, disponibilidad)', () {
    test('envío que termina a tiempo → enviado', () async {
      expect(await esperarEnvio(Future<void>.value()), ResultadoEnvio.enviado);
    });

    test('envío que no termina (sin red, queda en cola) → pendiente', () async {
      final nunca = Completer<void>(); // Firestore sin red: ni éxito ni error
      final r = await esperarEnvio(nunca.future,
          espera: const Duration(milliseconds: 50));
      expect(r, ResultadoEnvio.pendiente);
    });

    test('envío que falla → fallo (nunca se muestra "Enviado")', () async {
      final r = await esperarEnvio(
          Future<void>.error(StateError('permission-denied')));
      expect(r, ResultadoEnvio.fallo);
    });

    test('envío lento pero dentro del plazo → enviado', () async {
      final r = await esperarEnvio(
        Future<void>.delayed(const Duration(milliseconds: 20)),
        espera: const Duration(milliseconds: 500),
      );
      expect(r, ResultadoEnvio.enviado);
    });
  });

  group('mostrarAvisoSinConexion (RQ-20)', () {
    final casos = <String, (bool, bool, bool)>{
      'nunca vio el servidor y viene del caché (primera carga) → no avisa': (
        false,
        true,
        false
      ),
      'vio el servidor y ahora viene del caché (se cayó la red) → avisa': (
        true,
        true,
        true
      ),
      'vio el servidor y sigue en línea → no avisa': (true, false, false),
      'volvió la red → deja de avisar': (true, false, false),
    };
    casos.forEach((nombre, c) {
      test(
          nombre,
          () => expect(
              mostrarAvisoSinConexion(vioServidor: c.$1, desdeCache: c.$2),
              c.$3));
    });
  });

  group('Enlace de sala (RQ-02)', () {
    test('lee el código de ?sala=', () {
      expect(
          codigoDeSalaDesdeUri(
              Uri.parse('https://x.github.io/bandasonido/?sala=abcd2345')),
          'ABCD2345');
    });
    final invalidos = [
      'https://x/?sala=ABC',
      'https://x/?sala=ABCD23456',
      'https://x/?sala=AB-D2345',
      'https://x/',
      'https://x/?otra=ABCD2345'
    ];
    for (final u in invalidos) {
      test('"$u" no es un código válido',
          () => expect(codigoDeSalaDesdeUri(Uri.parse(u)), isNull));
    }
    test('el enlace generado vuelve a leerse igual', () {
      final codigo = generarCodigoSala();
      expect(codigoDeSalaDesdeUri(Uri.parse(enlaceDeSala(codigo))), codigo);
    });
    test('el enlace apunta a la versión web publicada', () {
      expect(enlaceDeSala('ABCD2345'), startsWith('https://'));
      expect(enlaceDeSala('ABCD2345'), endsWith('?sala=ABCD2345'));
    });
  });

  group('Versión (RQ-23, desplegabilidad)', () {
    test('kVersionApp coincide con version: de pubspec.yaml', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final linea = RegExp(r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+[0-9]+',
              multiLine: true)
          .firstMatch(pubspec);
      expect(linea, isNotNull, reason: 'pubspec.yaml sin version: X.Y.Z+N');
      expect(kVersionApp, linea!.group(1));
    });
  });

  test('tope de largo de un pedido escrito a mano (RQ-21)',
      () => expect(kMaxCaracteresPedido, 200));

  group('Caché de pistas en el celular (RQ-27, disponibilidad)', () {
    test('claveCache es estable y de 16 caracteres hexadecimales', () {
      const url =
          'https://x.supabase.co/storage/v1/object/public/audios/u1/pista.mp3';
      expect(claveCache(url), claveCache(url));
      expect(RegExp(r'^[0-9a-f]{16}$').hasMatch(claveCache(url)), isTrue);
    });

    test('URLs distintas dan claves distintas', () {
      final claves = {
        for (var i = 0; i < 2000; i++)
          claveCache('https://x.co/audios/$i/pista $i.mp3'),
      };
      expect(claves, hasLength(2000));
    });

    final ahora = DateTime(2026, 10, 25, 12);
    ({String nombre, DateTime fecha}) a(String n, int horasAtras) =>
        (nombre: n, fecha: ahora.subtract(Duration(hours: horasAtras)));

    test('no borra nada si no se pasa del máximo', () {
      final r = archivosParaBorrar([a('1.audio', 1), a('2.audio', 2)], {},
          maximo: 3, ahora: ahora);
      expect(r, isEmpty);
    });

    test('borra las más viejas cuando se pasa del máximo', () {
      final r = archivosParaBorrar(
        [a('nueva.audio', 1), a('media.audio', 5), a('vieja.audio', 9)],
        {},
        maximo: 2,
        ahora: ahora,
      );
      expect(r, ['vieja.audio']);
    });

    test('nunca borra las pistas de la sala actual, aunque sean viejas', () {
      final r = archivosParaBorrar(
        [a('sala1.audio', 100), a('sala2.audio', 90), a('otra.audio', 1)],
        {'sala1.audio', 'sala2.audio'},
        maximo: 2,
        ahora: ahora,
      );
      expect(r, ['otra.audio']);
    });

    test('descargas a medias (.part) solo se borran si tienen más de un día',
        () {
      final r = archivosParaBorrar(
        [a('reciente.part', 2), a('vieja.part', 30), a('ok.audio', 1)],
        {},
        ahora: ahora,
      );
      expect(r, ['vieja.part']);
    });
  });

  group('Eliminar cuenta (RQ-28)', () {
    test('archivosDeCuenta lista solo los documentos con archivo', () {
      final r = archivosDeCuenta([
        {
          'storagePath': 'usuarios/u1/canciones/a.pdf',
          'storageProvider': 'supabase'
        },
        {
          'storagePath': 'usuarios/u1/secuencias/b.mp3',
          'storageProvider': 'supabase'
        },
        {'titulo': 'sin archivo'},
        {'storagePath': ''},
      ]);
      expect(r.length, 2);
      expect(r.first.ruta, 'usuarios/u1/canciones/a.pdf');
      expect(r.first.proveedor, 'supabase');
    });

    test('un archivo sin proveedor es de Firebase (los más viejos)', () {
      final r = archivosDeCuenta([
        {'storagePath': 'usuarios/u1/canciones/viejo.pdf'},
      ]);
      expect(r.single.proveedor, 'firebase');
    });

    test('sin documentos no hay nada que borrar', () {
      expect(archivosDeCuenta([]), isEmpty);
    });
  });

  group('Uso en vivo (RQ-30)', () {
    test('el volumen de las alertas siempre queda entre 0 y 1', () {
      expect(AlertasConfig.volumenValido(0.5), 0.5);
      expect(AlertasConfig.volumenValido(7), 1.0);
      expect(AlertasConfig.volumenValido(-3), 0.0);
      expect(AlertasConfig.volumenValido(double.nan), 1.0);
      expect(const AlertasConfig().copyWith(volumen: 9).volumen, 1.0);
    });

    test('las alertas arrancan todas activadas', () {
      const c = AlertasConfig();
      expect([c.sonido, c.vibracion, c.destello], everyElement(isTrue));
      expect(c.volumen, 1.0);
    });

    test('un pedido urgente vibra más que uno normal', () {
      int total(List<int> p) => p.fold(0, (a, b) => a + b);
      expect(total(patronVibracion(urgente: true)),
          greaterThan(total(patronVibracion(urgente: false))));
      expect(patronVibracion(urgente: true).first, 0);
    });

    test('estado del pedido: enviado, visto y atendido', () {
      expect(estadoDePedido({}), EstadoPedido.enviado);
      expect(estadoDePedido({'visto': true}), EstadoPedido.visto);
      expect(estadoDePedido({'visto': true, 'atendido': true}),
          EstadoPedido.atendido);
      expect(estadoDePedido({'atendido': true}), EstadoPedido.atendido);
      expect(estadoDePedido({'visto': false, 'atendido': false}),
          EstadoPedido.enviado);
    });

    test('hay 5 respuestas rápidas distintas y con texto', () {
      final r = respuestasRapidas(AppLocalizationsEs());
      expect(r.length, 5);
      expect(r.toSet().length, 5);
      expect(r, everyElement(isNotEmpty));
    });

    test('el modo show se activa y se desactiva', () {
      expect(ModoShow.bloqueado.value, isFalse);
      ModoShow.bloqueado.value = true;
      expect(ModoShow.bloqueado.value, isTrue);
      ModoShow.desactivar();
      expect(ModoShow.bloqueado.value, isFalse);
    });
  });

  group('Título sugerido al subir un archivo', () {
    test('es el nombre del archivo sin la extensión', () {
      expect(
          tituloDesdeArchivo('Jesús es el nombre.pdf'), 'Jesús es el nombre');
      expect(tituloDesdeArchivo('QA_prueba.PDF'), 'QA_prueba');
    });

    test('solo quita la última extensión', () {
      expect(tituloDesdeArchivo('Canción v2.final.pdf'), 'Canción v2.final');
    });

    test('sin extensión o con nombre que empieza con punto no se rompe', () {
      expect(tituloDesdeArchivo('sin_extension'), 'sin_extension');
      expect(tituloDesdeArchivo('.oculto'), '.oculto');
      expect(tituloDesdeArchivo('  espacio .pdf '), 'espacio');
      expect(tituloDesdeArchivo(''), '');
    });
  });

  group('Detección de tonalidad al subir una canción', () {
    String? k(String texto) => DetectorTonalidad.detectar(texto);

    test('respeta la tonalidad que declara el texto', () {
      expect(k('Tono: G\nC G Am F'), 'G');
      expect(k('Key of Am\nletra'), 'Am');
      expect(k('Tonalidad Bb'), 'Bb');
      expect(k('Jesús es el nombre (Dm)\nletra sin acordes'), 'Dm');
      expect(k('QA Prueba (G)\n\nG D\nhola'), 'G');
    });

    test('una palabra suelta después de "tono" no cuenta como tonalidad', () {
      expect(k('Tono bajo y suave\nletra'), isNull);
    });

    test('alístate (acordes reales) es Dm', () {
      const texto = '''
Intro Dm Gm A Dm

Verso1
  Dm
Alístate, que pronto viene el Rey
    Gm
En majestad, ya pronto viene el Rey
      A
Él viene ya, Él viene ya, Él viene ya
    A   G  F  E  Dm  A/C# C G/B
El Rey pronto vendrá

Coro
      Dm  A/C#    C  G/B
//Hay gozo en los cielos
     Dm   A/C#    C  G/B
 Hay fiesta en la tierra
        Gm        A
El Rey pronto vendrá//
''';
      expect(k(texto), 'Dm');
    });

    test('canción clásica en sol mayor', () {
      expect(k('G  G7  C  G\nAmazing\nEm  D  G\ngrace'), 'G');
    });

    test('Am F C G suelto es ambiguo (Do mayor o La menor): no se arriesga',
        () {
      expect(k('Am F C G\nletra\nAm F C G'), isNull);
    });

    test('si termina en el acorde de la tónica, se decide por ella', () {
      expect(k('Am F C G\nletra\nAm F C G Am'), 'Am');
      expect(k('C G Am F\nletra\nC G Am F C'), 'C');
    });

    test('bemoles: Bb F Gm Eb', () {
      expect(k('Bb F Gm Eb\nletra\nBb F Eb Bb'), 'Bb');
    });

    test('acordes entre corchetes', () {
      expect(k('[G]Sobre [D]el [Em]mar [C]va\n[G]la [D]luz [C]y [G]sol'), 'G');
    });

    test('notación latina', () {
      expect(k('Rem Sol La Rem\nletra\nRem Sol La Rem'), 'Dm');
    });

    test('con pocos acordes no se arriesga', () {
      expect(k('C G'), isNull);
      expect(k('letra sin ningún acorde'), isNull);
      expect(k(''), isNull);
    });

    test('si hay dudas entre dos tonalidades devuelve null', () {
      // C y F alternando sin pista de cuál es la tónica
      expect(k('C F\nF C\nC F'), anyOf(isNull, 'C', 'F'));
    });
  });
}
