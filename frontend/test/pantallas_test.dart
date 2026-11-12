// Pruebas de widgets que no necesitan Firebase: el diálogo para compartir una
// sala (con su código QR), la guía de bienvenida, los estados vacíos y el
// botón de desplazamiento automático. Las pantallas completas (que sí hablan
// con Firestore) se prueban en el celular; ver AUDITORIA_TESTING.md (B-09).
import 'package:appsonido_frontend/l10n/app_localizations.dart';
import 'package:appsonido_frontend/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Una app mínima con los textos en español, para probar un widget suelto.
Widget conApp(Widget Function(BuildContext) contenido) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('es'),
      home: Builder(builder: (context) {
        L10n.t = AppLocalizations.of(context);
        return Scaffold(body: contenido(context));
      }),
    );

void main() {
  testWidgets('compartir sala muestra el código, el QR y los botones',
      (tester) async {
    await tester.pumpWidget(conApp((context) => TextButton(
        onPressed: () => mostrarCompartirSala(context, 'ABCD2345'),
        child: const Text('abrir'))));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Compartir sala'), findsOneWidget);
    expect(find.text('ABCD2345'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('Copiar'), findsOneWidget);
    expect(find.text('Compartir'), findsOneWidget);

    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.text('Compartir sala'), findsNothing);
  });

  testWidgets('la guía de bienvenida explica los tres pasos y se cierra',
      (tester) async {
    await tester.pumpWidget(conApp((context) => TextButton(
        onPressed: () => mostrarGuiaDeBienvenida(context),
        child: const Text('abrir'))));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Así funciona Sound Check Pro'), findsOneWidget);
    expect(find.textContaining('Creá una sala'), findsOneWidget);
    expect(find.textContaining('Mandá pedidos'), findsOneWidget);
    expect(find.textContaining('Subí tus PDF'), findsOneWidget);
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
    expect(find.text('Así funciona Sound Check Pro'), findsNothing);
  });

  testWidgets('un estado vacío con botón avisa al tocarlo', (tester) async {
    var toques = 0;
    await tester.pumpWidget(conApp((context) => EstadoVacio(
          icono: Icons.library_music,
          titulo: context.l10n.vacioRepertorioTitulo,
          ayuda: context.l10n.vacioRepertorioAyuda,
          textoBoton: context.l10n.subirUnPdf,
          alTocarBoton: () => toques++,
        )));
    expect(find.text('Tu repertorio está vacío'), findsOneWidget);
    expect(find.textContaining('importá canciones'), findsOneWidget);
    await tester.tap(find.text('Subir un PDF'));
    expect(toques, 1);
  });

  testWidgets('un estado vacío sin botón no lo muestra', (tester) async {
    await tester.pumpWidget(conApp((context) =>
        const EstadoVacio(icono: Icons.history, titulo: 'Nada todavía')));
    expect(find.text('Nada todavía'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('el botón de desplazamiento automático alterna y elige velocidad',
      (tester) async {
    var activo = false;
    double velocidad = BotonAutoDesplazar.normal;
    await tester.pumpWidget(conApp((context) => StatefulBuilder(
          builder: (context, setState) => BotonAutoDesplazar(
            activo: activo,
            velocidad: velocidad,
            alAlternar: () => setState(() => activo = !activo),
            alElegirVelocidad: (v) => setState(() => velocidad = v),
          ),
        )));
    expect(find.byIcon(Icons.play_circle), findsOneWidget);
    await tester.tap(find.byIcon(Icons.play_circle));
    await tester.pump();
    expect(activo, isTrue);
    expect(find.byIcon(Icons.pause_circle), findsOneWidget);

    await tester.tap(find.byIcon(Icons.speed));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rápido'));
    await tester.pumpAndSettle();
    expect(velocidad, BotonAutoDesplazar.rapida);
  });

  testWidgets('cómo instalar la app explica iPhone y Android', (tester) async {
    await tester.pumpWidget(conApp((context) => TextButton(
        onPressed: () => mostrarComoInstalar(context),
        child: const Text('abrir'))));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Instalar la app'), findsOneWidget);
    expect(find.textContaining('iPhone: abrí esta página en Safari'),
        findsOneWidget);
    expect(find.textContaining('Android: en Chrome'), findsOneWidget);
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
    expect(find.text('Instalar la app'), findsNothing);
  });

  group('archivos compartidos desde otras apps', () {
    const canal = MethodChannel('soundcheckpro/compartir');

    void respondiendo(Future<Object?> Function(MethodCall) respuesta) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(canal, respuesta);
      addTearDown(() => TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .setMockMethodCallHandler(canal, null));
    }

    test('entrega el nombre y los bytes de cada archivo', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      respondiendo((llamada) async {
        expect(llamada.method, 'tomarArchivos');
        return [
          {
            'nombre': 'Tema.pdf',
            'bytes': Uint8List.fromList([37, 80, 68, 70])
          },
          {
            'nombre': 'texto compartido.txt',
            'bytes': Uint8List.fromList([65, 109])
          },
        ];
      });
      final archivos = await ArchivosCompartidos.tomar();
      expect(
          archivos.map((a) => a.nombre), ['Tema.pdf', 'texto compartido.txt']);
      expect(archivos.first.bytes, [37, 80, 68, 70]);
      expect(archivos.last.bytes, [65, 109]);
    });

    test('un archivo ilegible llega marcado para avisarlo', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      respondiendo((_) async => [
            {'nombre': 'Grande.pdf', 'bytes': Uint8List(0), 'ilegible': true},
            {
              'nombre': 'Bien.pdf',
              'bytes': Uint8List.fromList([1])
            },
          ]);
      final r = await ArchivosCompartidos.tomar();
      expect(r.map((a) => a.ilegible), [true, false]);
      expect(r.first.nombre, 'Grande.pdf');
    });

    test('sin nada pendiente devuelve una lista vacía', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      respondiendo((_) async => null);
      expect(await ArchivosCompartidos.tomar(), isEmpty);
      respondiendo((_) async => []);
      expect(await ArchivosCompartidos.tomar(), isEmpty);
    });

    test('si el canal falla no rompe la app', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      respondiendo((_) async => throw PlatformException(code: 'falla'));
      expect(await ArchivosCompartidos.tomar(), isEmpty);
    });
  });

  group('visor de cifrados: pedal, teclado y desplazamiento automático', () {
    final letra = List.generate(300, (i) => 'Línea $i de la letra').join('\n');

    /// El desplazamiento vertical del visor (hay también uno horizontal).
    ScrollPosition vertical(WidgetTester tester) => tester
        .stateList<ScrollableState>(find.byType(Scrollable))
        .map((s) => s.position)
        .firstWhere((p) => p.axis == Axis.vertical && p.maxScrollExtent > 0);

    Future<void> abrir(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(conApp((context) =>
          CifradoViewerScreen(titulo: 'Tema', cifradoOriginal: letra)));
      await tester.pumpAndSettle();
    }

    testWidgets('Av Pág y espacio bajan; Re Pág sube', (tester) async {
      await abrir(tester);
      expect(vertical(tester).pixels, 0);

      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pumpAndSettle();
      final primera = vertical(tester).pixels;
      expect(primera, greaterThan(300));

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      final segunda = vertical(tester).pixels;
      expect(segunda, greaterThan(primera));

      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await tester.pumpAndSettle();
      expect(vertical(tester).pixels, lessThan(segunda));
    });

    testWidgets('las flechas arriba y abajo también desplazan', (tester) async {
      await abrir(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      final abajo = vertical(tester).pixels;
      expect(abajo, greaterThan(0));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(vertical(tester).pixels, lessThan(abajo));
    });

    testWidgets('no pasa de los extremos', (tester) async {
      await abrir(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await tester.pumpAndSettle();
      expect(vertical(tester).pixels, 0);
      for (var i = 0; i < 60; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
        await tester.pumpAndSettle();
      }
      final p = vertical(tester);
      expect(p.pixels, p.maxScrollExtent);
    });

    testWidgets('con las flechas laterales y sin setlist no pasa nada',
        (tester) async {
      await abrir(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(find.text('Tema'), findsWidgets);
      expect(vertical(tester).pixels, 0);
    });

    testWidgets('el desplazamiento automático avanza solo y se pausa',
        (tester) async {
      await abrir(tester);
      await tester.tap(find.byIcon(Icons.play_circle));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      final avanzo = vertical(tester).pixels;
      expect(avanzo, greaterThan(20));

      await tester.tap(find.byIcon(Icons.pause_circle));
      await tester.pump();
      final alPausar = vertical(tester).pixels;
      await tester.pump(const Duration(seconds: 3));
      expect(vertical(tester).pixels, alPausar);
    });
  });
}
