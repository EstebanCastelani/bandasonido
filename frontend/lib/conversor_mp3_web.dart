// Única excepción a "todo el código Dart en main.dart" (ver
// CONTEXTO_PARA_IA.md §2): dart:js_interop no compila fuera de la web, así
// que el puente al conversor de MP3 del navegador (web/conversor_mp3.js)
// vive acá y main.dart lo importa condicionalmente. En Android el import
// apunta a main.dart mismo, que define la versión "no disponible" con los
// mismos nombres (ver SECCIÓN SERVICIO DE SECUENCIAS en main.dart).
import 'dart:js_interop';
import 'dart:typed_data';

@JS('convertirAMp3')
external JSPromise<_ResultadoMp3> _convertirAMp3(
  JSUint8Array bytes,
  JSNumber limiteBytes,
  JSFunction alAvanzar,
);

extension type _ResultadoMp3._(JSObject _) implements JSObject {
  external JSUint8Array get bytes;
  external JSNumber get kbps;
}

const bool conversorMp3Disponible = true;

/// Convierte [bytes] (cualquier audio que el navegador sepa decodificar) a
/// MP3 con la mayor calidad que entre en [limiteBytes]. [alAvanzar] recibe
/// el progreso de 0 a 1.
Future<({Uint8List bytes, int kbps})> convertirAMp3(
  Uint8List bytes,
  int limiteBytes,
  void Function(double progreso) alAvanzar,
) async {
  final resultado = await _convertirAMp3(
    bytes.toJS,
    limiteBytes.toJS,
    ((JSNumber progreso) => alAvanzar(progreso.toDartDouble)).toJS,
  ).toDart;
  return (bytes: resultado.bytes.toDart, kbps: resultado.kbps.toDartInt);
}
