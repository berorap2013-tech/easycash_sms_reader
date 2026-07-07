package com.easycash.smsreader

import android.content.ContentResolver
import android.database.Cursor
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val channelName = "easycash_sms_reader/sms"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            if (call.method == "getRecentSms") {
                val limit = call.argument<Int>("limit") ?: 40
                try {
                    result.success(readRecentSms(limit))
                } catch (e: Exception) {
                    result.error("SMS_READ_ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun readRecentSms(limit: Int): List<Map<String, String>> {
        val messages = mutableListOf<Map<String, String>>()
        val resolver: ContentResolver = contentResolver
        val uri: Uri = Uri.parse("content://sms/inbox")
        val projection = arrayOf("address", "body", "date")
        val cursor: Cursor? = resolver.query(
            uri,
            projection,
            null,
            null,
            "date DESC"
        )

        cursor?.use {
            val addressIndex = it.getColumnIndex("address")
            val bodyIndex = it.getColumnIndex("body")
            val dateIndex = it.getColumnIndex("date")
            var count = 0
            while (it.moveToNext() && count < limit) {
                messages.add(
                    mapOf(
                        "sender" to (it.getString(addressIndex) ?: ""),
                        "body" to (it.getString(bodyIndex) ?: ""),
                        "date" to (it.getLong(dateIndex).toString())
                    )
                )
                count++
            }
        }
        return messages
    }
}
