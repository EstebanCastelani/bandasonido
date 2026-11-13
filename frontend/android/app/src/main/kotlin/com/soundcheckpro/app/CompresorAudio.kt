package com.soundcheckpro.app

import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder

/** Un fallo que Flutter puede mostrar con un mensaje propio según el [codigo]. */
class ErrorCompresion(val codigo: String, mensaje: String) : Exception(mensaje)

/**
 * Achica un audio (WAV, MP3, M4A, OGG, FLAC...) a AAC dentro de un archivo .m4a,
 * usando solo los codificadores que trae Android. Las secuencias pesan mucho
 * (un WAV de 8 minutos son ~80 MB y un AAC de 128 kbps ~7 MB) y se pagan por lo
 * que se guarda y se descarga.
 *
 * - Un audio con pérdidas (MP3, AAC, OGG) que ya es liviano no se toca ([Resultado.omitido]):
 *   volver a codificarlo lo empeora y casi no lo achica.
 * - El bitrate se baja solo si hace falta para que entre en [maxBytes].
 * - Solo se entienden 1 o 2 canales y hasta 48 kHz (lo que admite el codificador).
 */
object CompresorAudio {
    data class Resultado(val omitido: Boolean, val kbps: Int, val duracionMs: Long)

    private const val TIEMPO_ESPERA_US = 10_000L
    private const val KBPS_MINIMO = 64

    /** Un audio con pérdidas de hasta este múltiplo del objetivo se deja como está. */
    private const val MARGEN_PARA_OMITIR = 1.15
    private val SIN_PERDIDAS = setOf("audio/raw", "audio/flac", "audio/x-flac")

    // Codificaciones de PCM (AudioFormat.ENCODING_*); se usan los números para no
    // depender del nivel de API de cada constante.
    private const val PCM_8 = 3
    private const val PCM_16 = 2
    private const val PCM_FLOAT = 4
    private const val PCM_24_EMPAQUETADO = 21
    private const val PCM_32 = 22

    fun comprimir(
        entrada: String,
        salida: String,
        kbpsObjetivo: Int,
        maxBytes: Long,
        alProgreso: (Double) -> Unit,
    ): Resultado {
        val extractor = MediaExtractor()
        var decodificador: MediaCodec? = null
        var codificador: MediaCodec? = null
        var muxer: MediaMuxer? = null
        var muxerIniciado = false
        try {
            try {
                extractor.setDataSource(entrada)
            } catch (e: Exception) {
                throw ErrorCompresion("no_soportado", "No se pudo abrir el audio: ${e.message}")
            }

            var pista = -1
            var formatoEntrada: MediaFormat? = null
            for (i in 0 until extractor.trackCount) {
                val f = extractor.getTrackFormat(i)
                if (f.getString(MediaFormat.KEY_MIME)?.startsWith("audio/") == true) {
                    pista = i
                    formatoEntrada = f
                    break
                }
            }
            if (pista < 0 || formatoEntrada == null) {
                throw ErrorCompresion("no_soportado", "El archivo no tiene audio")
            }
            extractor.selectTrack(pista)

            val mime = formatoEntrada.getString(MediaFormat.KEY_MIME)!!
            val duracionUs =
                if (formatoEntrada.containsKey(MediaFormat.KEY_DURATION)) formatoEntrada.getLong(MediaFormat.KEY_DURATION) else 0L
            val tamanoEntrada = File(entrada).length()

            // Con pérdidas y ya liviano: no se recodifica.
            if (mime !in SIN_PERDIDAS && duracionUs > 0) {
                val kbpsEntrada = tamanoEntrada * 8_000.0 / duracionUs
                if (kbpsEntrada <= kbpsObjetivo * MARGEN_PARA_OMITIR) {
                    return Resultado(true, kbpsEntrada.toInt(), duracionUs / 1000)
                }
            }

            var kbps = kbpsObjetivo
            if (duracionUs > 0) {
                kbps = minOf(kbps, (maxBytes * 8_000.0 / duracionUs).toInt())
            }
            if (kbps < KBPS_MINIMO) {
                throw ErrorCompresion("muy_largo", "El audio dura demasiado para entrar en $maxBytes bytes")
            }

            val decoder = try {
                MediaCodec.createDecoderByType(mime).also {
                    it.configure(formatoEntrada, null, null, 0)
                    it.start()
                }
            } catch (e: Exception) {
                throw ErrorCompresion("no_soportado", "No se pudo decodificar $mime: ${e.message}")
            }
            decodificador = decoder

            val info = MediaCodec.BufferInfo()
            var entradaTerminada = false
            var decodificadorTerminado = false
            var finEnviadoAlCodificador = false
            var codificadorTerminado = false

            // PCM de 16 bits que salió del decodificador y todavía no entró al codificador.
            var pendiente: ByteArray? = null
            var posicionPendiente = 0
            var cuadrosEntregados = 0L
            var frecuencia = 0
            var canales = 0
            var codificacionPcm = PCM_16
            var pistaMuxer = -1
            var ultimoProgreso = -1.0

            fun prepararCodificador(formatoSalida: MediaFormat) {
                frecuencia = formatoSalida.getInteger(MediaFormat.KEY_SAMPLE_RATE)
                canales = formatoSalida.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
                codificacionPcm =
                    if (formatoSalida.containsKey("pcm-encoding")) formatoSalida.getInteger("pcm-encoding") else PCM_16
                if (canales !in 1..2 || frecuencia !in 8000..48000) {
                    throw ErrorCompresion("no_soportado", "Audio de $canales canales a $frecuencia Hz")
                }
                if (codificador != null) return
                try {
                    val formato = MediaFormat.createAudioFormat(MediaFormat.MIMETYPE_AUDIO_AAC, frecuencia, canales)
                    formato.setInteger(MediaFormat.KEY_AAC_PROFILE, MediaCodecInfo.CodecProfileLevel.AACObjectLC)
                    formato.setInteger(MediaFormat.KEY_BIT_RATE, kbps * 1000)
                    formato.setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, 16384)
                    val c = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_AUDIO_AAC)
                    c.configure(formato, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
                    c.start()
                    codificador = c
                    muxer = MediaMuxer(salida, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
                } catch (e: Exception) {
                    throw ErrorCompresion("no_soportado", "No se pudo preparar el codificador AAC: ${e.message}")
                }
            }

            while (!codificadorTerminado) {
                var huboProgreso = false

                // 1. Del archivo al decodificador.
                if (!entradaTerminada) {
                    val i = decoder.dequeueInputBuffer(0)
                    if (i >= 0) {
                        val buffer = decoder.getInputBuffer(i)!!
                        val n = extractor.readSampleData(buffer, 0)
                        if (n < 0) {
                            decoder.queueInputBuffer(i, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                            entradaTerminada = true
                        } else {
                            val tiempo = extractor.sampleTime
                            decoder.queueInputBuffer(i, 0, n, tiempo, 0)
                            extractor.advance()
                            if (duracionUs > 0) {
                                val p = (tiempo.toDouble() / duracionUs).coerceIn(0.0, 1.0)
                                if (p - ultimoProgreso >= 0.01) {
                                    ultimoProgreso = p
                                    alProgreso(p)
                                }
                            }
                        }
                        huboProgreso = true
                    }
                }

                // 2. Del decodificador al "pendiente" (un solo bloque a la vez).
                if (pendiente == null && !decodificadorTerminado) {
                    val o = decoder.dequeueOutputBuffer(info, 0)
                    if (o == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                        prepararCodificador(decoder.outputFormat)
                        huboProgreso = true
                    } else if (o >= 0) {
                        if (codificador == null) prepararCodificador(decoder.outputFormat)
                        if (info.size > 0) {
                            val buffer = decoder.getOutputBuffer(o)!!
                            buffer.position(info.offset)
                            buffer.limit(info.offset + info.size)
                            pendiente = aPcm16(buffer, codificacionPcm)
                            posicionPendiente = 0
                        }
                        if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) decodificadorTerminado = true
                        decoder.releaseOutputBuffer(o, false)
                        huboProgreso = true
                    }
                }

                // 3. Del "pendiente" al codificador (o el aviso de que se terminó).
                val enc = codificador
                if (enc != null && !finEnviadoAlCodificador) {
                    val p = pendiente
                    if (p != null) {
                        val i = enc.dequeueInputBuffer(0)
                        if (i >= 0) {
                            val buffer = enc.getInputBuffer(i)!!
                            buffer.clear()
                            val cuadro = 2 * canales
                            var n = minOf(buffer.capacity(), p.size - posicionPendiente)
                            n -= n % cuadro
                            if (n <= 0) {
                                // Un resto que no completa un cuadro: se descarta.
                                pendiente = null
                            } else {
                                buffer.put(p, posicionPendiente, n)
                                enc.queueInputBuffer(i, 0, n, cuadrosEntregados * 1_000_000L / frecuencia, 0)
                                posicionPendiente += n
                                cuadrosEntregados += n / cuadro
                                if (posicionPendiente >= p.size) pendiente = null
                            }
                            huboProgreso = true
                        }
                    } else if (decodificadorTerminado) {
                        val i = enc.dequeueInputBuffer(0)
                        if (i >= 0) {
                            enc.queueInputBuffer(
                                i, 0, 0, cuadrosEntregados * 1_000_000L / frecuencia,
                                MediaCodec.BUFFER_FLAG_END_OF_STREAM,
                            )
                            finEnviadoAlCodificador = true
                            huboProgreso = true
                        }
                    }
                }

                // 4. Del codificador al archivo (se vacía todo lo que haya listo).
                if (enc != null) {
                    while (true) {
                        val o = enc.dequeueOutputBuffer(info, 0)
                        if (o == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                            pistaMuxer = muxer!!.addTrack(enc.outputFormat)
                            muxer!!.start()
                            muxerIniciado = true
                            huboProgreso = true
                        } else if (o >= 0) {
                            val buffer = enc.getOutputBuffer(o)!!
                            if (info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0) info.size = 0
                            if (info.size > 0 && muxerIniciado) {
                                buffer.position(info.offset)
                                buffer.limit(info.offset + info.size)
                                muxer!!.writeSampleData(pistaMuxer, buffer, info)
                            }
                            val fin = info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0
                            enc.releaseOutputBuffer(o, false)
                            huboProgreso = true
                            if (fin) {
                                codificadorTerminado = true
                                break
                            }
                        } else {
                            break
                        }
                    }
                }

                // Si nada avanzó, se espera un instante para no gastar batería de más.
                if (!huboProgreso) Thread.sleep(TIEMPO_ESPERA_US / 1000)
            }
            alProgreso(1.0)
            return Resultado(false, kbps, duracionUs / 1000)
        } catch (e: ErrorCompresion) {
            File(salida).delete()
            throw e
        } catch (e: Exception) {
            File(salida).delete()
            throw ErrorCompresion("error", e.message ?: e.javaClass.simpleName)
        } finally {
            runCatching { decodificador?.stop() }
            runCatching { decodificador?.release() }
            runCatching { codificador?.stop() }
            runCatching { codificador?.release() }
            if (muxerIniciado) runCatching { muxer?.stop() }
            runCatching { muxer?.release() }
            extractor.release()
        }
    }

    /** El PCM que entregó el decodificador, pasado a 16 bits (lo único que acepta el codificador AAC). */
    private fun aPcm16(origen: ByteBuffer, codificacion: Int): ByteArray {
        origen.order(ByteOrder.LITTLE_ENDIAN)
        when (codificacion) {
            PCM_8 -> {
                val salida = ByteArray(origen.remaining() * 2)
                var j = 0
                while (origen.hasRemaining()) {
                    val v = ((origen.get().toInt() and 0xFF) - 128) shl 8
                    salida[j++] = (v and 0xFF).toByte()
                    salida[j++] = (v shr 8).toByte()
                }
                return salida
            }
            PCM_FLOAT -> {
                val muestras = origen.asFloatBuffer()
                val salida = ByteArray(muestras.remaining() * 2)
                var j = 0
                while (muestras.hasRemaining()) {
                    val v = (muestras.get() * 32767f).toInt().coerceIn(-32768, 32767)
                    salida[j++] = (v and 0xFF).toByte()
                    salida[j++] = (v shr 8).toByte()
                }
                return salida
            }
            PCM_24_EMPAQUETADO -> {
                val salida = ByteArray(origen.remaining() / 3 * 2)
                var j = 0
                while (origen.remaining() >= 3) {
                    origen.get() // el byte más bajo se descarta
                    salida[j++] = origen.get()
                    salida[j++] = origen.get()
                }
                return salida
            }
            PCM_32 -> {
                val salida = ByteArray(origen.remaining() / 4 * 2)
                var j = 0
                while (origen.remaining() >= 4) {
                    origen.get()
                    origen.get()
                    salida[j++] = origen.get()
                    salida[j++] = origen.get()
                }
                return salida
            }
            else -> {
                val salida = ByteArray(origen.remaining())
                origen.get(salida)
                return salida
            }
        }
    }
}
