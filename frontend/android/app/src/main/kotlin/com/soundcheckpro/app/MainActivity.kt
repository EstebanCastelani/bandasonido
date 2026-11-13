package com.soundcheckpro.app

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * Recibe PDF, archivos de texto y texto compartidos desde otras apps (por
 * ejemplo desde WhatsApp: "Compartir -> Sound Check Pro") y se los da a Flutter
 * por el canal "soundcheckpro/compartir". Cada archivo se lee entero (hasta
 * [MAXIMO_BYTES]) y viaja como {nombre, bytes}; el texto suelto viaja como un
 * archivo "texto compartido.txt".
 */
class MainActivity : FlutterActivity() {
    private val pendientes = mutableListOf<Map<String, Any>>()
    private var canal: MethodChannel? = null

    /** Un solo trabajo de compresión a la vez (cada uno usa el codificador del sistema). */
    private val hiloAudio: ExecutorService = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        canal = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "soundcheckpro/compartir")
        canal!!.setMethodCallHandler { llamada, resultado ->
            if (llamada.method == "tomarArchivos") {
                val lista = ArrayList(pendientes)
                pendientes.clear()
                resultado.success(lista)
            } else {
                resultado.notImplemented()
            }
        }
        leer(intent)

        // Compresión de audio: "comprimir" pasa un archivo a AAC (.m4a) y avisa el
        // avance con "progreso". Corre en un hilo aparte (un audio largo tarda).
        val canalAudio = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "soundcheckpro/audio")
        canalAudio.setMethodCallHandler { llamada, resultado ->
            if (llamada.method != "comprimir") {
                resultado.notImplemented()
                return@setMethodCallHandler
            }
            val entrada = llamada.argument<String>("entrada")
            val salida = llamada.argument<String>("salida")
            val kbps = llamada.argument<Int>("kbps") ?: 128
            val maxBytes = (llamada.argument<Number>("maxBytes") ?: 28L * 1024 * 1024).toLong()
            if (entrada == null || salida == null) {
                resultado.error("error", "Faltan la ruta de entrada o la de salida", null)
                return@setMethodCallHandler
            }
            hiloAudio.execute {
                try {
                    val r = CompresorAudio.comprimir(entrada, salida, kbps, maxBytes) { p ->
                        runOnUiThread { canalAudio.invokeMethod("progreso", p) }
                    }
                    runOnUiThread {
                        resultado.success(
                            mapOf("omitido" to r.omitido, "kbps" to r.kbps, "duracionMs" to r.duracionMs)
                        )
                    }
                } catch (e: ErrorCompresion) {
                    runOnUiThread { resultado.error(e.codigo, e.message, null) }
                } catch (e: Throwable) {
                    runOnUiThread { resultado.error("error", e.message, null) }
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        leer(intent)
        if (pendientes.isNotEmpty()) canal?.invokeMethod("hayArchivos", null)
    }

    @Suppress("DEPRECATION")
    private fun uris(i: Intent): List<Uri> = when (i.action) {
        Intent.ACTION_SEND -> listOfNotNull(
            if (Build.VERSION.SDK_INT >= 33) i.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
            else i.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
        )
        Intent.ACTION_SEND_MULTIPLE ->
            (if (Build.VERSION.SDK_INT >= 33) i.getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java)
            else i.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)) ?: emptyList<Uri>()
        else -> emptyList()
    }

    private fun leer(i: Intent?) {
        if (i == null) return
        if (i.action != Intent.ACTION_SEND && i.action != Intent.ACTION_SEND_MULTIPLE) return
        val lista = uris(i)
        for (uri in lista) {
            try {
                val nombre = nombreDe(uri)
                contentResolver.openInputStream(uri)?.use { entrada ->
                    val bytes = entrada.readBytes()
                    if (bytes.size <= MAXIMO_BYTES) {
                        pendientes.add(mapOf("nombre" to nombre, "bytes" to bytes))
                    } else {
                        pendientes.add(ilegible(nombre))
                    }
                } ?: pendientes.add(ilegible(nombre))
            } catch (_: Exception) {
                // Un archivo que no se puede leer se avisa; los demás siguen.
                pendientes.add(ilegible(runCatching { nombreDe(uri) }.getOrDefault("archivo")))
            }
        }
        if (lista.isEmpty() && i.action == Intent.ACTION_SEND) {
            val texto = i.getStringExtra(Intent.EXTRA_TEXT)
            if (!texto.isNullOrBlank() && texto.length <= MAXIMO_BYTES) {
                pendientes.add(mapOf("nombre" to "texto compartido.txt", "bytes" to texto.toByteArray(Charsets.UTF_8)))
            }
        }
        // El intent ya se atendió: no se vuelve a leer al rotar o reabrir.
        i.action = null
    }

    /** Un archivo que no se pudo leer o pesa de más: Flutter lo avisa en vez de ignorarlo. */
    private fun ilegible(nombre: String): Map<String, Any> =
        mapOf("nombre" to nombre, "bytes" to ByteArray(0), "ilegible" to true)

    private fun nombreDe(uri: Uri): String {
        try {
            contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { c ->
                if (c.moveToFirst()) {
                    val n = c.getString(0)
                    if (!n.isNullOrBlank()) return n
                }
            }
        } catch (_: Exception) {
        }
        return uri.lastPathSegment ?: "archivo"
    }

    companion object {
        private const val MAXIMO_BYTES = 12 * 1024 * 1024
    }
}
