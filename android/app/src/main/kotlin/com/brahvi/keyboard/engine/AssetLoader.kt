package com.brahvi.keyboard.engine

import android.content.Context
import android.util.Log
import org.json.JSONObject

object AssetLoader {
    private const val TAG = "BrahviKeyboard"

    fun readJson(context: Context, relativePath: String): JSONObject? {
        val candidates = listOf(
            "shared/$relativePath",
            "flutter_assets/shared/$relativePath"
        )
        for (path in candidates) {
            try {
                val text = context.assets.open(path).bufferedReader().use { it.readText() }
                return JSONObject(text)
            } catch (_: Exception) {
            }
        }
        Log.w(TAG, "Missing asset: $relativePath")
        return null
    }
}
