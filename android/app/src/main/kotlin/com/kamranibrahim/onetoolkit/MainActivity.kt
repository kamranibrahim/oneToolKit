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

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.kamranibrahim.onetoolkit/share"
    }

    private val pending = ArrayList<HashMap<String, String>>()
    private var channel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "takePending" -> {
                    val copy = ArrayList(pending)
                    pending.clear()
                    result.success(copy)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        ingest(intent)
        channel?.invokeMethod("onShared", null)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        ingest(intent)
        channel?.invokeMethod("onShared", null)
    }

    private fun ingest(intent: Intent?) {
        if (intent == null) return
        val uris = urisFrom(intent) ?: return
        val ts = System.currentTimeMillis()
        for ((index, uri) in uris.withIndex()) {
            try {
                val dest = copyUri(uri, ts, index) ?: continue
                val mime = resolveMime(intent, uri)
                pending.add(
                    hashMapOf(
                        "path" to dest.absolutePath,
                        "mime" to mime,
                    ),
                )
            } catch (_: Exception) {
                // Skip failed copies.
            }
        }
        intent.action = null
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

    private fun resolveMime(intent: Intent, uri: Uri): String {
        val declared = intent.type
        if (!declared.isNullOrBlank() &&
            !declared.contains('*') &&
            !declared.contains(';')
        ) {
            return declared
        }
        return contentResolver.getType(uri) ?: "application/octet-stream"
    }

    private fun copyUri(uri: Uri, ts: Long, index: Int): File? {
        val name = safeName(displayName(uri) ?: uri.lastPathSegment ?: "file.bin")
        val dest = File(cacheDir, "share_${ts}_${index}_$name")
        val input = contentResolver.openInputStream(uri) ?: return null
        input.use { stream ->
            FileOutputStream(dest).use { out ->
                stream.copyTo(out)
            }
        }
        if (!dest.exists() || dest.length() <= 0L) {
            dest.delete()
            return null
        }
        return dest
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
