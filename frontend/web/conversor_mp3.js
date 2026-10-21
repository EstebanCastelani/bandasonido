// Conversión a MP3 en el navegador para "Mis secuencias" (ver
// CONTEXTO_PARA_IA.md, Secuencias). Supabase gratis rechaza archivos de más
// de 50 MB, así que los audios que no entran se convierten acá, antes de
// subirlos. El navegador decodifica el audio (WAV, MP3, M4A, OGG...) y el
// MP3 lo codifica lamejs (lame.min.js) en conversor_mp3_worker.js, en un
// hilo aparte para no congelar la app. Lo llama lib/puente_web.dart.

// Bitrates válidos de MP3 de más a menos calidad: se usa el más alto con el
// que el resultado entra en el límite.
const KBPS_PERMITIDOS = [320, 256, 224, 192, 160, 128, 112, 96];

/**
 * @param {Uint8Array} bytes archivo de audio original
 * @param {number} limiteBytes tamaño máximo del MP3 resultante
 * @param {(progreso: number) => void} alAvanzar recibe 0..1
 * @returns {Promise<{bytes: Uint8Array, kbps: number}>}
 */
window.convertirAMp3 = async function (bytes, limiteBytes, alAvanzar) {
  // 44,1 kHz: frecuencia estándar de MP3; decodeAudioData remuestrea a esto.
  const contexto = new OfflineAudioContext(2, 1, 44100);
  // decodeAudioData se queda con el buffer: se le pasa una copia.
  const audio = await contexto.decodeAudioData(bytes.slice().buffer);

  // Margen del 2% + 16 KB por la cabecera y el redondeo de los frames.
  const estimarBytes = (kbps) => (kbps * 1000 / 8) * audio.duration * 1.02 + 16384;
  const kbps = KBPS_PERMITIDOS.find((k) => estimarBytes(k) <= limiteBytes);
  if (kbps === undefined) {
    const minutos = Math.round(audio.duration / 60);
    throw new Error(`El audio dura ${minutos} min: ni en MP3 de baja calidad entra en el límite.`);
  }

  // lamejs codifica hasta 2 canales; si hay más se usan los dos primeros.
  const canales = [];
  for (let c = 0; c < Math.min(audio.numberOfChannels, 2); c++) {
    canales.push(audio.getChannelData(c));
  }

  const mp3 = await new Promise((resolver, rechazar) => {
    const worker = new Worker('conversor_mp3_worker.js');
    worker.onmessage = (e) => {
      if (e.data.tipo === 'progreso') {
        alAvanzar(e.data.valor);
      } else if (e.data.tipo === 'listo') {
        worker.terminate();
        resolver(new Uint8Array(e.data.mp3));
      } else if (e.data.tipo === 'error') {
        worker.terminate();
        rechazar(new Error(e.data.mensaje));
      }
    };
    worker.onerror = (e) => {
      worker.terminate();
      rechazar(new Error(e.message || 'Falló el conversor de MP3'));
    };
    worker.postMessage(
      { canales, sampleRate: audio.sampleRate, kbps },
      canales.map((c) => c.buffer),
    );
  });

  return { bytes: mp3, kbps };
};
