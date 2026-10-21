// Reproductor de secuencias de la web, con tono y tempo independientes
// (como Music Speed Changer). El reproductor normal (audioplayers) solo
// cambia la velocidad; para mover el tono sin cambiar el tempo hace falta
// procesar el audio, y eso lo hace SoundTouch (soundtouch.js, LGPL-2.1).
// La pista se baja y decodifica entera antes de sonar. Una sola pista a la
// vez. Lo usa ReproductorSecuencias en main.dart a través de
// lib/puente_web.dart; el estado lo consulta Dart cada ~200 ms (estado()).
import { PitchShifter } from './soundtouch.js';

// Tamaño del bloque que procesa SoundTouch: más chico responde antes a los
// cambios pero puede cortarse en celulares lentos.
const TAMANO_BLOQUE = 8192;

let contexto = null;
let ganancia = null;
let shifter = null;
let buffer = null;
let sonando = false;
let termino = false;
let repetir = false;
let tempo = 1;
let semitonos = 0;
let cargaActual = 0;

function obtenerContexto() {
  if (!contexto) {
    contexto = new AudioContext();
    ganancia = contexto.createGain();
    ganancia.connect(contexto.destination);
  }
  return contexto;
}

// SoundTouch avisa el final en cada bloque una vez que se vació: se atiende
// solo mientras está sonando.
function alTerminar() {
  if (!sonando) return;
  if (repetir) {
    shifter.percentagePlayed = 0;
    return;
  }
  shifter.disconnect();
  shifter.percentagePlayed = 0;
  sonando = false;
  termino = true;
}

function detenerInterno() {
  if (shifter && sonando) shifter.disconnect();
  sonando = false;
  termino = false;
  if (shifter) shifter.percentagePlayed = 0;
}

window.reproductorSecuencias = {
  // Se llama sincrónicamente desde el toque del usuario: los navegadores de
  // celular solo dejan arrancar el audio dentro de un gesto.
  desbloquear() {
    obtenerContexto().resume();
  },

  // Devuelve la duración en segundos, o -1 si mientras tanto se pidió otra
  // pista (esta carga quedó descartada).
  async cargar(url) {
    const carga = ++cargaActual;
    detenerInterno();
    const respuesta = await fetch(url);
    if (!respuesta.ok) throw new Error(`No se pudo bajar el audio (HTTP ${respuesta.status})`);
    const datos = await respuesta.arrayBuffer();
    const decodificado = await obtenerContexto().decodeAudioData(datos);
    if (carga !== cargaActual) return -1;
    if (shifter) shifter.disconnect();
    buffer = decodificado;
    shifter = new PitchShifter(obtenerContexto(), buffer, TAMANO_BLOQUE, alTerminar);
    shifter.tempo = tempo;
    shifter.pitchSemitones = semitonos;
    termino = false;
    return buffer.duration;
  },

  reproducir() {
    if (!shifter || sonando) return;
    if (termino) {
      shifter.percentagePlayed = 0;
      termino = false;
    }
    shifter.connect(ganancia);
    sonando = true;
    obtenerContexto().resume();
  },

  pausar() {
    if (shifter && sonando) shifter.disconnect();
    sonando = false;
  },

  detener() {
    detenerInterno();
  },

  irA(segundos) {
    if (!shifter || !buffer) return;
    shifter.percentagePlayed = Math.min(Math.max(segundos / buffer.duration, 0), 1);
    termino = false;
  },

  // 1 = normal, 0.9 = 10% más lento. No cambia el tono.
  setTempo(valor) {
    tempo = valor;
    if (shifter) shifter.tempo = valor;
  },

  // En semitonos, puede ser negativo. No cambia el tempo.
  setSemitonos(valor) {
    semitonos = valor;
    if (shifter) shifter.pitchSemitones = valor;
  },

  setRepetir(valor) {
    repetir = valor;
  },

  // posicion: segundos de la pista original (no del audio ya estirado).
  estado() {
    return {
      posicion: shifter ? shifter.timePlayed : 0,
      duracion: buffer ? buffer.duration : 0,
      sonando,
      termino,
    };
  },
};
