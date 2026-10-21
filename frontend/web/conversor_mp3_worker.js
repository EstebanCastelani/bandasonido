// Hilo aparte que codifica a MP3 con lamejs (ver conversor_mp3.js).
importScripts('lame.min.js');

// lamejs procesa de a 1152 muestras (un frame de MP3).
const MUESTRAS_POR_BLOQUE = 1152;

function aInt16(float32) {
  const salida = new Int16Array(float32.length);
  for (let i = 0; i < float32.length; i++) {
    const s = Math.max(-1, Math.min(1, float32[i]));
    salida[i] = s < 0 ? s * 0x8000 : s * 0x7fff;
  }
  return salida;
}

self.onmessage = (e) => {
  try {
    const { canales, sampleRate, kbps } = e.data;
    const pcm = canales.map(aInt16);
    const encoder = new lamejs.Mp3Encoder(pcm.length, sampleRate, kbps);
    const partes = [];
    let total = 0;
    const largo = pcm[0].length;
    let ultimoAviso = 0;

    for (let i = 0; i < largo; i += MUESTRAS_POR_BLOQUE) {
      const izquierdo = pcm[0].subarray(i, i + MUESTRAS_POR_BLOQUE);
      const parte = pcm.length === 2
        ? encoder.encodeBuffer(izquierdo, pcm[1].subarray(i, i + MUESTRAS_POR_BLOQUE))
        : encoder.encodeBuffer(izquierdo);
      if (parte.length > 0) {
        partes.push(parte);
        total += parte.length;
      }
      // Avisa el progreso cada ~1% para no saturar al hilo principal.
      const progreso = i / largo;
      if (progreso - ultimoAviso >= 0.01) {
        ultimoAviso = progreso;
        self.postMessage({ tipo: 'progreso', valor: progreso });
      }
    }
    const cierre = encoder.flush();
    if (cierre.length > 0) {
      partes.push(cierre);
      total += cierre.length;
    }

    const mp3 = new Uint8Array(total);
    let offset = 0;
    for (const parte of partes) {
      mp3.set(new Uint8Array(parte.buffer, parte.byteOffset, parte.length), offset);
      offset += parte.length;
    }
    self.postMessage({ tipo: 'listo', mp3: mp3.buffer }, [mp3.buffer]);
  } catch (err) {
    self.postMessage({ tipo: 'error', mensaje: String(err && err.message ? err.message : err) });
  }
};
