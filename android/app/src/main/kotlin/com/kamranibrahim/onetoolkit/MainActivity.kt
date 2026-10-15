package com.kamranibrahim.onetoolkit

import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.UUID
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.kamranibrahim.onetoolkit/share"
    }

    private val pending = ArrayList<HashMap<String, String>>()
    private val copies = Executors.newSingleThreadExecutor()
    private var channel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
            "com.kamranibrahim.onetoolkit/saved_work").setMethodCallHandler { call, result ->
            if (call.method == "directory") {
                val directory = File(noBackupFilesDir, "saved_work")
                if (directory.isDirectory || directory.mkdirs()) result.success(directory.absolutePath)
                else result.error("storage", "Private saved storage is unavailable", null)
            } else result.notImplemented()
        }
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "takePending" -> {
                    val copy = ArrayList(pending)
                    result.success(copy)
                }
                "acknowledge" -> {
                    val paths = (call.arguments as? List<*>)?.filterIsInstance<String>()?.toSet() ?: emptySet()
                    pending.removeAll { it["path"] in paths }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        ingest(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        ingest(intent)
    }

    private fun ingest(intent: Intent?) {
        if (intent == null) return
        val uris = urisFrom(intent) ?: return
        // Metadata queries and copies run serially off the activity thread.
        val declaredMime = intent.type
        intent.action = null
        copies.execute {
            val rows = ArrayList<HashMap<String, String>>()
            for (uri in uris) {
                try {
                    val name = safeName(displayName(uri) ?: "file.bin")
                    val mime = resolveMime(declaredMime, uri)
                    val dest = copyUri(uri, name)
                    rows.add(hashMapOf("path" to dest.absolutePath, "mime" to mime))
                } catch (_: Exception) {
                    // Surface failed copies without dropping successful inputs.
                    runOnUiThread {
                        android.widget.Toast.makeText(this,
                            "Could not import a shared file. Please share it again.",
                            android.widget.Toast.LENGTH_LONG).show()
                    }
                }
            }
            runOnUiThread {
                pending.addAll(rows)
                channel?.invokeMethod("onShared", null)
            }
        }
    }

    override fun onDestroy() {
        copies.shutdown()
        channel?.setMethodCallHandler(null)
        channel = null
        super.onDestroy()
    }

    private fun urisFrom(intent: Intent): List<Uri>? {
        return when (intent.action) {
            Intent.ACTION_SEND -> {
                val uri = streamExtra(intent) ?: return null
                listOf(uri)
            }
            Intent.ACTION_SEND_MULTIPLE -> {
                streamListExtra(intent)
            }
            else -> null
        }
    }

    private fun streamExtra(intent: Intent): Uri? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(Intent.EXTRA_STREAM)
        }
    }

    private fun streamListExtra(intent: Intent): List<Uri>? {
        val list = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)
        }
        return list
    }

    private fun resolveMime(declared: String?, uri: Uri): String {
        val actual = contentResolver.getType(uri)
        if (!actual.isNullOrBlank() && !actual.contains('*')) return actual
        if (!declared.isNullOrBlank() &&
            !declared.contains('*') &&
            !declared.contains(';')
        ) {
            return declared
        }
        return "application/octet-stream"
    }

    private fun copyUri(uri: Uri, name: String): File {
        val dest = File(cacheDir, "share_${UUID.randomUUID()}_$name")
        try {
            val input = contentResolver.openInputStream(uri)
                ?: throw java.io.IOException("Cannot open shared file")
            input.use { stream ->
                FileOutputStream(dest).use { out -> stream.copyTo(out) }
            }
            if (!dest.exists() || dest.length() <= 0L) {
                throw java.io.IOException("Empty shared file")
            }
            return dest
        } catch (error: Exception) {
            dest.delete()
            throw error
        }
    }

    private fun displayName(uri: Uri): String? {
        var cursor: Cursor? = null
        return try {
            cursor = contentResolver.query(
                uri,
                arrayOf(OpenableColumns.DISPLAY_NAME),
                null,
                null,
                null,
            )
            if (cursor != null && cursor.moveToFirst()) {
                val idx = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (idx >= 0) cursor.getString(idx) else null
            } else {
                null
            }
        } catch (_: Exception) {
            null
        } finally {
            cursor?.close()
        }
    }

    private fun safeName(raw: String): String {
        return raw
            .replace('/', '_')
            .replace('\\', '_')
            .ifBlank { "file.bin" }
    }
}
