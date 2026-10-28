// Reproductor de secuencias de la web, con tono y tempo independientes
// (como Music Speed Changer). Lo usa ReproductorSecuencias en main.dart a
// través de lib/puente_web.dart; el estado lo consulta Dart cada ~200 ms.
//
// Para que arranque rápido, la pista se reproduce mientras se descarga con un
// elemento <audio> (no se baja ni se decodifica entera antes de sonar):
//   - Tempo: lo hace el propio navegador (playbackRate con preservesPitch),
//     que cambia la velocidad sin cambiar el tono.
//   - Tono: SoundTouch (soundtouch.js, LGPL-2.1) en el hilo de audio
//     (procesador_tono.js, AudioWorklet), solo cuando hay semitonos; con el
//     tono original el audio va directo.
// Cadena: <audio> → [tono si hay semitonos] → volumen → fundido → salida.
// Una sola pista a la vez para toda la página.

// Fundidos cortos al arrancar, pausar, frenar y saltar: un corte en seco de
// la onda se escucha como un "click" en los parlantes.
const FUNDIDO_ENTRADA = 0.03;
const FUNDIDO_SALIDA = 0.04;

let contexto = null;
let audio = null;
let fuente = null;
let nodoTono = null;
let nodoVolumen = null;
let nodoFundido = null;
let termino = false;
let semitonos = 0;
let tempo = 1;
let volumen = 1;
let cargaActual = 0;
let busquedaRapida = false;
// Pausa/stop/fade out programados para cuando termina el fundido; se
// cancelan si mientras tanto se vuelve a dar play.
let accionPendiente = null;

// Se arma apenas carga la página (el contexto arranca suspendido hasta el
// primer toque) para que el procesador de tono ya esté cargado cuando se
// dé play: cargarlo recién en el toque haría esperar con un await, y los
// navegadores de celular solo dejan arrancar audio sin awaits de por medio.
function prepararCadena() {
  if (contexto) return;
  contexto = new AudioContext();
  audio = new Audio();
  // Sin esto el navegador no deja procesar audio de Supabase (otro dominio):
  // entrega silencio sin avisar.
  audio.crossOrigin = 'anonymous';
  audio.preload = 'auto';
  audio.preservesPitch = true;
  audio.addEventListener('ended', () => {
    termino = true;
  });
  fuente = contexto.createMediaElementSource(audio);
  nodoVolumen = contexto.createGain();
  nodoVolumen.gain.value = volumen;
  nodoFundido = contexto.createGain();
  nodoFundido.gain.value = 0;
  nodoVolumen.connect(nodoFundido);
  nodoFundido.connect(contexto.destination);
  conectar();
  if (contexto.audioWorklet) {
    contexto.audioWorklet
      .addModule(new URL('procesador_tono.js', import.meta.url))
      .then(() => {
        nodoTono = new AudioWorkletNode(contexto, 'procesador-tono', { outputChannelCount: [2] });
        nodoTono.port.onmessage = (e) => {
          if (e.data.tipo === 'busquedaRapida') busquedaRapida = true;
        };
        nodoTono.port.postMessage({ tipo: 'semitonos', valor: semitonos });
        conectar();
      })
      .catch((e) => console.warn('No se pudo cargar el procesador de tono:', e));
  }
}

// Con tono original (o si el procesador todavía no cargó) el audio va
// directo, sin latencia ni gasto de CPU; con semitonos pasa por SoundTouch.
function conectar() {
  fuente.disconnect();
  if (nodoTono) nodoTono.disconnect();
  if (semitonos === 0 || !nodoTono) {
    fuente.connect(nodoVolumen);
  } else {
    fuente.connect(nodoTono);
    nodoTono.connect(nodoVolumen);
  }
}

// Vacía SoundTouch (al saltar o cambiar de pista) para que no suene audio
// viejo; vuelve a entrar con rampa.
function reiniciarTono() {
  if (nodoTono) nodoTono.port.postMessage({ tipo: 'reiniciar' });
}

function cancelarPendiente() {
  if (accionPendiente) {
    clearTimeout(accionPendiente);
    accionPendiente = null;
  }
}

// Lleva el fundido a [destino] en [segundos] desde el valor actual.
function fundir(destino, segundos) {
  const ahora = contexto.currentTime;
  const g = nodoFundido.gain;
  g.cancelScheduledValues(ahora);
  g.setValueAtTime(g.value, ahora);
  g.linearRampToValueAtTime(destino, ahora + segundos);
}

// Baja el fundido y recién después ejecuta [accion] (pausar, frenar...).
function fundirYLuego(segundos, accion) {
  cancelarPendiente();
  fundir(0, segundos);
  accionPendiente = setTimeout(() => {
    accionPendiente = null;
    accion();
  }, segundos * 1000 + 15);
}

prepararCadena();

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
    cancelarPendiente();
    const carga = ++cargaActual;
    termino = false;
    fundir(0, 0.005);
    reiniciarTono();
    // Si la pista ya está guardada en el navegador (cache_archivos.js) se
    // usa esa copia: suena al instante y sin red. Es sincrónico a propósito.
    audio.src = (window.__blobUrls && window.__blobUrls.get(url)) || url;
    // Cambiar de pista vuelve la velocidad a la de por defecto.
    audio.defaultPlaybackRate = tempo;
    audio.playbackRate = tempo;
    // play() se llama acá mismo (sin await previo) para que siga dentro del
    // toque del usuario; resuelve cuando efectivamente empieza a sonar.
    await audio.play();
    if (carga !== cargaActual) return -1;
    fundir(1, FUNDIDO_ENTRADA);
    return audio.duration;
  },

  reproducir() {
    if (!audio || !audio.src) return;
    cancelarPendiente();
    termino = false;
    audio.play();
    fundir(1, FUNDIDO_ENTRADA);
  },

  pausar() {
    if (!audio) return;
    fundirYLuego(FUNDIDO_SALIDA, () => audio.pause());
  },

  detener() {
    if (!audio) return;
    termino = false;
    fundirYLuego(FUNDIDO_SALIDA, () => {
      audio.pause();
      if (audio.src) audio.currentTime = 0;
      reiniciarTono();
    });
  },

  // Baja el volumen hasta silencio en [segundos] y frena (para terminar una
  // pista en vivo). Al terminar se informa como si la pista hubiera
  // llegado al final.
  fadeOut(segundos) {
    if (!audio || audio.paused) return;
    fundirYLuego(segundos, () => {
      audio.pause();
      if (audio.src) audio.currentTime = 0;
      reiniciarTono();
      termino = true;
    });
  },

  irA(segundos) {
    if (!audio || !audio.src) return;
    termino = false;
    if (audio.paused) {
      audio.currentTime = segundos;
      reiniciarTono();
      return;
    }
    fundirYLuego(0.015, () => {
      audio.currentTime = segundos;
      reiniciarTono();
      fundir(1, FUNDIDO_ENTRADA);
    });
  },

  // 1 = normal, 0.9 = 10% más lento. No cambia el tono.
  setTempo(valor) {
    tempo = valor;
    if (!audio) return;
    const aplicar = () => {
      audio.defaultPlaybackRate = valor;
      audio.playbackRate = valor;
    };
    // Sin tono el navegador cambia el tempo en vivo sin cortes. Con tono, el
    // reacomodo del navegador entra a SoundTouch y empalma mal (medido: un
    // "click" en el instante del cambio), así que se hace como con el tono:
    // bajar, aplicar, vaciar SoundTouch y volver con rampa. Si llegan muchos
    // cambios seguidos (deslizador), se aplica solo el último al soltar.
    if (semitonos === 0 || !nodoTono || audio.paused) {
      aplicar();
      return;
    }
    fundirYLuego(0.015, () => {
      aplicar();
      reiniciarTono();
      fundir(1, 0.005);
    });
  },

  // En semitonos, puede ser negativo. No cambia el tempo.
  setSemitonos(valor) {
    if (valor === semitonos) return;
    semitonos = valor;
    if (!contexto) return;
    // Se baja el volumen, el procesador se vacía y arranca con el tono nuevo
    // (cambiar parámetros con audio a medio procesar empalma mal) y el
    // sonido vuelve con rampa apenas sale audio procesado.
    const aplicar = () => {
      if (nodoTono) nodoTono.port.postMessage({ tipo: 'semitonos', valor });
      conectar();
    };
    if (audio.paused) {
      aplicar();
      return;
    }
    fundirYLuego(0.015, () => {
      aplicar();
      // Con tono original vuelve directo: rampa del fundido. Con SoundTouch,
      // la rampa la hace el procesador cuando empieza a salir audio.
      fundir(1, valor === 0 || !nodoTono ? FUNDIDO_ENTRADA : 0.005);
    });
  },

  // 0 a 1. Lo aplica suave para que no salte.
  setVolumen(valor) {
    volumen = valor;
    if (!nodoVolumen) return;
    const ahora = contexto.currentTime;
    nodoVolumen.gain.cancelScheduledValues(ahora);
    nodoVolumen.gain.setValueAtTime(nodoVolumen.gain.value, ahora);
    nodoVolumen.gain.linearRampToValueAtTime(valor, ahora + 0.05);
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
      tonoDisponible: !!nodoTono,
      busquedaRapida,
    };
  },
};
