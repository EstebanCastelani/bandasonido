// Reproductor de secuencias de la web, con tono y tempo independientes
// (como Music Speed Changer). Lo usa ReproductorSecuencias en main.dart a
// través de lib/puente_web.dart; el estado lo consulta Dart cada ~200 ms.
//
// Para que arranque rápido, la pista se reproduce mientras se descarga con un
// elemento <audio> (no se baja ni se decodifica entera antes de sonar):
//   - Tempo: lo hace el propio navegador (playbackRate con preservesPitch),
//     que cambia la velocidad sin cambiar el tono.
//   - Tono: el audio pasa por SoundTouch (soundtouch.js, LGPL-2.1) en vivo,
//     solo cuando hay semitonos; con el tono original va directo a la salida.
// Una sola pista a la vez para toda la página.
import { SoundTouch } from './soundtouch.js';

// Bloque de procesamiento del tono (~85 ms a 48 kHz). Más chico responde
// antes pero puede cortarse en celulares lentos.
const TAMANO_BLOQUE = 4096;

let contexto = null;
let audio = null;
let fuente = null;
let procesador = null;
let soundtouch = null;
// SoundTouch necesita juntar un poco de audio antes de devolver: hasta
// tener reserva se manda silencio, para no entrecortar.
let cebado = false;
let termino = false;
let semitonos = 0;
let tempo = 1;
let cargaActual = 0;

const intercalado = new Float32Array(TAMANO_BLOQUE * 2);
const procesado = new Float32Array(TAMANO_BLOQUE * 2);

function procesarTono(evento) {
  const entrada = evento.inputBuffer;
  const izqIn = entrada.getChannelData(0);
  const derIn = entrada.numberOfChannels > 1 ? entrada.getChannelData(1) : izqIn;
  const izqOut = evento.outputBuffer.getChannelData(0);
  const derOut = evento.outputBuffer.getChannelData(1);
  const n = izqIn.length;

  for (let i = 0; i < n; i++) {
    intercalado[i * 2] = izqIn[i];
    intercalado[i * 2 + 1] = derIn[i];
  }
  soundtouch.inputBuffer.putSamples(intercalado, 0, n);
  soundtouch.process();

  const disponibles = soundtouch.outputBuffer.frameCount;
  if (!cebado && disponibles >= n * 2) cebado = true;
  const k = cebado ? Math.min(n, disponibles) : 0;
  if (k > 0) soundtouch.outputBuffer.receiveSamples(procesado, k);
  for (let i = 0; i < n; i++) {
    izqOut[i] = i < k ? procesado[i * 2] : 0;
    derOut[i] = i < k ? procesado[i * 2 + 1] : 0;
  }
}

function prepararCadena() {
  if (contexto) return;
  contexto = new AudioContext();
  audio = new Audio();
  // Sin esto el navegador no deja procesar audio de Supabase (otro dominio).
  audio.crossOrigin = 'anonymous';
  audio.preload = 'auto';
  audio.preservesPitch = true;
  audio.addEventListener('ended', () => {
    termino = true;
  });
  fuente = contexto.createMediaElementSource(audio);
  procesador = contexto.createScriptProcessor(TAMANO_BLOQUE, 2, 2);
  procesador.onaudioprocess = procesarTono;
  soundtouch = new SoundTouch();
  soundtouch.pitchSemitones = semitonos;
  conectar();
}

// Con tono original el audio va directo a la salida (sin latencia ni gasto
// de CPU); con semitonos pasa por SoundTouch.
function conectar() {
  fuente.disconnect();
  procesador.disconnect();
  if (semitonos === 0) {
    fuente.connect(contexto.destination);
  } else {
    soundtouch.clear();
    cebado = false;
    fuente.connect(procesador);
    procesador.connect(contexto.destination);
  }
}

// Descarta lo que SoundTouch tenía guardado (al saltar o cambiar de pista).
function reiniciarTono() {
  if (!soundtouch) return;
  soundtouch.clear();
  cebado = false;
}

window.reproductorSecuencias = {
  // Se llama sincrónicamente desde el toque del usuario: los navegadores de
  // celular solo dejan arrancar el audio dentro de un gesto.
  desbloquear() {
    prepararCadena();
    contexto.resume();
  },

  // Empieza a reproducir [url] apenas hay datos y devuelve la duración en
  // segundos, o -1 si mientras tanto se pidió otra pista.
  async cargar(url) {
    prepararCadena();
    const carga = ++cargaActual;
    termino = false;
    reiniciarTono();
    audio.src = url;
    // Cambiar de pista vuelve la velocidad a la de por defecto.
    audio.defaultPlaybackRate = tempo;
    audio.playbackRate = tempo;
    // play() se llama acá mismo (sin await previo) para que siga dentro del
    // toque del usuario; resuelve cuando efectivamente empieza a sonar.
    await audio.play();
    if (carga !== cargaActual) return -1;
    return audio.duration;
  },

  reproducir() {
    if (!audio || !audio.src) return;
    termino = false;
    audio.play();
  },

  pausar() {
    if (audio) audio.pause();
  },

  detener() {
    if (!audio) return;
    audio.pause();
    if (audio.src) audio.currentTime = 0;
    termino = false;
    reiniciarTono();
  },

  irA(segundos) {
    if (!audio || !audio.src) return;
    audio.currentTime = segundos;
    termino = false;
    reiniciarTono();
  },

  // 1 = normal, 0.9 = 10% más lento. No cambia el tono.
  setTempo(valor) {
    tempo = valor;
    if (!audio) return;
    audio.defaultPlaybackRate = valor;
    audio.playbackRate = valor;
  },

  // En semitonos, puede ser negativo. No cambia el tempo.
  setSemitonos(valor) {
    const antes = semitonos;
    semitonos = valor;
    if (!soundtouch) return;
    soundtouch.pitchSemitones = valor;
    if ((antes === 0) !== (valor === 0)) conectar();
  },

  setRepetir(valor) {
    prepararCadena();
    audio.loop = valor;
  },

  // posicion: segundos de la pista original.
  estado() {
    const sonando = !!audio && !!audio.src && !audio.paused && !audio.ended;
    return {
      posicion: audio && audio.src ? audio.currentTime : 0,
      duracion: audio && isFinite(audio.duration) ? audio.duration : 0,
      sonando,
      termino,
    };
  },
};
