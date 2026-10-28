// Única excepción a "todo el código Dart en main.dart" (ver
// CONTEXTO_PARA_IA.md §2): dart:js_interop no compila fuera de la web, así
// que el puente a lo que corre en JS del navegador vive acá y main.dart lo
// importa condicionalmente con el prefijo `puente`. En Android el import
// apunta a main.dart mismo, que define las versiones "no disponible" con
// los mismos nombres (ver SERVICIO DE SECUENCIAS en main.dart).
//   - Conversor de MP3: web/conversor_mp3.js
//   - Reproductor con tono y tempo: web/reproductor_secuencias.js
import 'dart:js_interop';
import 'dart:typed_data';

// --- CONVERSOR DE MP3 ---

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

// --- REPRODUCTOR CON TONO Y TEMPO ---

@JS('reproductorSecuencias')
external _ReproductorJs get _reproductor;

extension type _ReproductorJs._(JSObject _) implements JSObject {
  external void desbloquear();
  external JSPromise<JSNumber> cargar(JSString url);
  external void reproducir();
  external void pausar();
  external void detener();
  external void irA(JSNumber segundos);
  external void setTempo(JSNumber valor);
  external void setSemitonos(JSNumber valor);
  external void setRepetir(JSBoolean valor);
  external void setVolumen(JSNumber valor);
  external void fadeOut(JSNumber segundos);
  external _EstadoJs estado();
}

extension type _EstadoJs._(JSObject _) implements JSObject {
  external JSNumber get posicion;
  external JSNumber get duracion;
  external JSBoolean get sonando;
  external JSBoolean get termino;
}

const bool reproductorWebDisponible = true;

/// Llamar sincrónicamente desde el toque del usuario, antes de cualquier
/// await: los navegadores de celular solo dejan arrancar audio en un gesto.
void rwDesbloquear() => _reproductor.desbloquear();

/// Empieza a reproducir la pista apenas hay datos (no la baja entera) y
/// devuelve la duración en segundos, o -1 si mientras tanto se pidió otra.
/// Aplicar tempo/semitonos/repetir antes de llamarla.
Future<double> rwCargar(String url) async =>
    (await _reproductor.cargar(url.toJS).toDart).toDartDouble;

void rwReproducir() => _reproductor.reproducir();
void rwPausar() => _reproductor.pausar();
void rwDetener() => _reproductor.detener();
void rwIrA(double segundos) => _reproductor.irA(segundos.toJS);
void rwTempo(double valor) => _reproductor.setTempo(valor.toJS);
void rwSemitonos(int valor) => _reproductor.setSemitonos(valor.toJS);
void rwRepetir(bool valor) => _reproductor.setRepetir(valor.toJS);

/// 0 a 1.
void rwVolumen(double valor) => _reproductor.setVolumen(valor.toJS);

/// Baja hasta silencio en [segundos] y frena; al terminar, rwEstado()
/// informa `termino` como si la pista hubiera llegado al final.
void rwFadeOut(double segundos) => _reproductor.fadeOut(segundos.toJS);

({double posicion, double duracion, bool sonando, bool termino}) rwEstado() {
  final e = _reproductor.estado();
  return (
    posicion: e.posicion.toDartDouble,
    duracion: e.duracion.toDartDouble,
    sonando: e.sonando.toDart,
    termino: e.termino.toDart,
  );
}

// --- ARCHIVOS GUARDADOS EN EL NAVEGADOR (SIN CONEXIÓN) ---
// web/cache_archivos.js (Cache Storage). Nombres: 'sc-pdfs' y 'sc-audio'.

@JS('cacheArchivos')
external _CacheJs? get _cache;

extension type _CacheJs._(JSObject _) implements JSObject {
  external JSBoolean get disponible;
  external JSPromise<JSArray<JSString>> precargar(
      JSString nombre, JSArray<JSString> urls);
  external JSPromise<JSUint8Array?> bytes(JSString nombre, JSString url);
  external JSPromise<JSAny?> borrar(JSString nombre, JSString url);
}

bool get cacheArchivosDisponible => _cache?.disponible.toDart ?? false;

/// Baja y guarda las [urls] que falten; devuelve las que quedaron guardadas.
Future<List<String>> cachePrecargar(String nombre, List<String> urls) async {
  final lista = await _cache!
      .precargar(nombre.toJS, [for (final u in urls) u.toJS].toJS)
      .toDart;
  return [for (final u in lista.toDart) u.toDart];
}

Future<Uint8List?> cacheBytes(String nombre, String url) async =>
    (await _cache!.bytes(nombre.toJS, url.toJS).toDart)?.toDart;

Future<void> cacheBorrar(String nombre, String url) async {
  await _cache!.borrar(nombre.toJS, url.toJS).toDart;
}
