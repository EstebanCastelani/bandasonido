// Cambio de tono de las secuencias, corriendo en el hilo de audio del
// navegador (AudioWorklet). Lo carga reproductor_secuencias.js. Va en el
// hilo de audio y no en el principal (ScriptProcessor) porque el principal
// también dibuja la app: si está ocupado, el audio se entrecorta, sobre todo
// en celulares.
import { SoundTouch } from './soundtouch.js';

// Audio que SoundTouch tiene que tener listo antes de empezar a sonar (~170
// ms a 48 kHz). Devuelve el audio en tandas de ~5.300 muestras: con 4.096
// de reserva se quedaba sin audio y hacía huecos (simulado: 3 a 8 huecos en
// 20 s); con 8.192 no hubo ninguno y siempre sobraron más de 4.400.
const RESERVA = 8192;

// Al volver a sonar (activar o cambiar el tono, saltar) el audio entra con
// esta rampa (~20 ms) en vez de golpe, que se escucharía como un "click".
const MUESTRAS_RAMPA = 1024;

// Si en un segundo de audio se usa más que esta fracción procesando, se
// pasa a la búsqueda rápida de SoundTouch (algo menos de calidad, mucho
// menos trabajo) para no cortarse en dispositivos lentos.
const USO_MAXIMO = 0.35;

class ProcesadorTono extends AudioWorkletProcessor {
  constructor() {
    super();
    this.soundtouch = new SoundTouch();
    // Por defecto SoundTouch mide sus ventanas para 44,1 kHz; con el valor
    // real del contexto (suele ser 48 kHz) suena mejor.
    this.soundtouch.stretch.setParameters(sampleRate, 0, 0, 8);
    this.soundtouch.stretch.quickSeek = false;
    this.busquedaRapida = false;
    this.cebado = false;
    this.muestrasDesdeInicio = 0;
    this.intercalado = new Float32Array(256);
    this.salida = new Float32Array(256);
    this.msUsados = 0;
    this.muestrasMedidas = 0;
    this.port.onmessage = (e) => {
      const m = e.data;
      if (m.tipo === 'semitonos') this.soundtouch.pitchSemitones = m.valor;
      // Tanto al cambiar el tono como al saltar o cambiar de pista se vacía
      // SoundTouch: cambiar parámetros con audio a medio procesar empalma
      // mal y se escucha.
      this.soundtouch.clear();
      this.cebado = false;
    };
  }

  process(inputs, outputs) {
    const entrada = inputs[0];
    const salida = outputs[0];
    const n = salida[0].length;
    const inicio = Date.now();

    if (entrada.length > 0) {
      const izq = entrada[0];
      const der = entrada.length > 1 ? entrada[1] : izq;
      if (this.intercalado.length < n * 2) {
        this.intercalado = new Float32Array(n * 2);
        this.salida = new Float32Array(n * 2);
      }
      for (let i = 0; i < n; i++) {
        this.intercalado[i * 2] = izq[i];
        this.intercalado[i * 2 + 1] = der[i];
      }
      this.soundtouch.inputBuffer.putSamples(this.intercalado, 0, n);
      this.soundtouch.process();
    }

    const disponibles = this.soundtouch.outputBuffer.frameCount;
    if (!this.cebado && disponibles >= RESERVA) {
      this.cebado = true;
      this.muestrasDesdeInicio = 0;
    }
    const k = this.cebado ? Math.min(n, disponibles) : 0;
    if (k > 0) this.soundtouch.outputBuffer.receiveSamples(this.salida, k);
    const izqOut = salida[0];
    const derOut = salida.length > 1 ? salida[1] : salida[0];
    for (let i = 0; i < n; i++) {
      if (i >= k) {
        izqOut[i] = 0;
        derOut[i] = 0;
        continue;
      }
      const rampa = this.muestrasDesdeInicio < MUESTRAS_RAMPA ? this.muestrasDesdeInicio / MUESTRAS_RAMPA : 1;
      this.muestrasDesdeInicio++;
      izqOut[i] = this.salida[i * 2] * rampa;
      derOut[i] = this.salida[i * 2 + 1] * rampa;
    }
    // Sin reserva: vuelve a juntar antes de seguir (y entra con rampa) en
    // vez de sonar entrecortado.
    if (this.cebado && k < n) this.cebado = false;

    if (!this.busquedaRapida) {
      this.msUsados += Date.now() - inicio;
      this.muestrasMedidas += n;
      if (this.muestrasMedidas >= sampleRate) {
        if (this.msUsados > 1000 * USO_MAXIMO) {
          this.busquedaRapida = true;
          this.soundtouch.stretch.quickSeek = true;
          this.port.postMessage({ tipo: 'busquedaRapida' });
        }
        this.msUsados = 0;
        this.muestrasMedidas = 0;
      }
    }
    return true;
  }
}

registerProcessor('procesador-tono', ProcesadorTono);
