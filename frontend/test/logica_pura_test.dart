// Pruebas de la lógica pura de la app (sin Firebase ni pantallas).
// Ver AUDITORIA_TESTING.md (casos CP-xx) y REQUISITOS.md (RQ-xx).
//
// Los casos marcados con `skip` son defectos YA CONOCIDOS (ver DEFECTOS.md):
// se dejan escritos con el resultado esperado para activarlos cuando se
// corrijan (Etapa 2 del plan de testing). No se borran ni se "arreglan" el
// test para que pase.
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
    const soportados = [Locale('es'), Locale('en'), Locale('pt'), Locale('fr'), Locale('it')];
    final casos = <String, (List<Locale>?, String)>{
      'idioma no soportado → español': ([const Locale('ja')], 'es'),
      'pt-BR → portugués': ([const Locale('pt', 'BR')], 'pt'),
      'en-GB → inglés': ([const Locale('en', 'GB')], 'en'),
      'toma el primero soportado de la lista': ([const Locale('de'), const Locale('fr')], 'fr'),
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
      'channel-error → sin conexión': ('[firebase_auth/channel-error] dev.flutter.pigeon', 'No hay conexión. Revisá tu internet e intentá de nuevo.'),
      'permission-denied → sin permiso': ('[cloud_firestore/permission-denied] Missing or insufficient permissions.', 'No tenés permiso para hacer esto.'),
      'error de DNS → sin conexión': ('SocketException: Failed host lookup', 'No hay conexión. Revisá tu internet e intentá de nuevo.'),
      'error desconocido → genérico': ('FormatException: x', 'Algo salió mal. Intentá de nuevo.'),
      'null → genérico': (null, 'Algo salió mal. Intentá de nuevo.'),
    };
    casos.forEach((nombre, caso) {
      test(nombre, () => expect(mensajeError(l, caso.$1), caso.$2));
    });

    test('nunca muestra el código técnico al usuario', () {
      final texto = mensajeError(l, '[firebase_auth/channel-error] dev.flutter.pigeon');
      expect(texto, isNot(contains('firebase')));
      expect(texto, isNot(contains('pigeon')));
    });
  });

  group('esRolSonidista (RQ-04)', () {
    for (final r in ['Sonidista', 'Sonido', 'sonido', 'Técnico de sonido', 'Sound engineer']) {
      test('"$r" entra al panel', () => expect(esRolSonidista(r), isTrue));
    }
    for (final r in ['Guitarrista', 'Músico', 'Baterista', 'Sonia']) {
      test('"$r" NO entra al panel', () => expect(esRolSonidista(r), isFalse));
    }
    test(
      '"Vocalista de Somos Mil" NO debe entrar al panel',
      () => expect(esRolSonidista('Vocalista de Somos Mil'), isFalse),
      skip: 'DF-01: la palabra clave "de som" da falso positivo (se corrige en la Etapa 2, tras decidir RQ-04)',
    );
    for (final r in ['Ingeniero de audio', 'Operador de audio', 'FOH', 'Monitorista']) {
      test(
        '"$r" entra al panel (a confirmar en RQ-04)',
        () => expect(esRolSonidista(r), isTrue),
        skip: 'DF-02: falso negativo; depende de la decisión RQ-04',
      );
    }
  });

  group('ChordTransposer (RQ-14)', () {
    final casos = <String, (String, int, String)>{
      'acordes entre corchetes con bajo': ('[C]Hola [G/B]mundo [Am7]hoy', 2, '[D]Hola [A/C#]mundo [Bm7]hoy'),
      'sostenidos pasan de F#m a Gm': ('[Bb]x [F#m]y', 1, '[B]x [Gm]y'),
      'sufijos maj7, sus4, 7, dim': ('[Cmaj7]a [Dsus4]b [E7]c [F#dim]d', 5, '[Fmaj7]a [Gsus4]b [A7]c [Bdim]d'),
      'add9, m7b5 y bajo con sostenido': ('[Cadd9]a [Gm7b5]b [A7/C#]c', 2, '[Dadd9]a [Am7b5]b [B7/D#]c'),
      'los bemoles se conservan': ('[Db]a [Ebm]b', 3, '[E]a [Gbm]b'),
      'N.C. no es un acorde y no cambia': ('[N.C.]a [C]b', 2, '[N.C.]a [D]b'),
      '+12 semitonos deja el texto igual': ('C   G   Am   F', 12, 'C   G   Am   F'),
      '-12 semitonos deja el texto igual': ('C   G   Am   F', -12, 'C   G   Am   F'),
      '0 semitonos no toca nada': ('[C]Hola [G]mundo', 0, '[C]Hola [G]mundo'),
    };
    casos.forEach((nombre, caso) {
      test(nombre, () => expect(ChordTransposer.transponerTexto(caso.$1, caso.$2), caso.$3));
    });

    test('ir y volver (+5 y −5) devuelve el original', () {
      const original = '[C]Hola [G/B]mundo [Am7]hoy [F#m]fin';
      final ida = ChordTransposer.transponerTexto(original, 5);
      expect(ChordTransposer.transponerTexto(ida, -5), original);
    });

    test(
      'notación latina [Do] [Re] [Mi] +2 → [Re] [Mi] [Fa#]',
      () => expect(ChordTransposer.transponerTexto('[Do]a [Re]b [Mi]c', 2), '[Re]a [Mi]b [Fa#]c'),
      skip: 'DF-03: hoy devuelve el texto sin cambios (se corrige en la Etapa 2, tras decidir RQ-05)',
    );
  });

  group('rolParaMostrar (RQ-11)', () {
    final l = AppLocalizationsEs();
    for (final r in ['Músico', 'Músico y Cantante', 'Sonidista', 'Otro', 'Guitarrista']) {
      test('"$r" se muestra tal cual en español', () => expect(rolParaMostrar(l, r), r));
    }
    test('ignora mayúsculas de los valores antiguos ("músico")', () {
      expect(rolParaMostrar(l, 'músico'), 'Músico');
    });
  });

  group('AppPalette.porClave (RQ-12)', () {
    test('clave conocida', () => expect(AppPalette.porClave('consola').key, 'consola'));
    for (final k in [null, 'xx', '']) {
      test('clave "$k" → paleta por defecto', () => expect(AppPalette.porClave(k).key, AppPalette.porDefecto.key));
    }
  });
}
