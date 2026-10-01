package com.brahvi.keyboard.clipboard

import android.content.Context
import org.json.JSONArray

class ClipboardStore(context: Context) {
    private val prefs = context.getSharedPreferences("brahvi_clipboard", Context.MODE_PRIVATE)

    fun add(text: String, maxItems: Int) {
        val value = text.trim()
        if (value.isEmpty() || looksSensitive(value)) return
        val items = items().toMutableList()
        items.remove(value)
        items.add(0, value)
        save(items.take(maxItems.coerceIn(1, 50)))
    }

    fun items(): List<String> {
        val raw = prefs.getString(KEY, "[]") ?: "[]"
        return try {
            val array = JSONArray(raw)
            (0 until array.length()).map { array.getString(it) }
        } catch (_: Exception) {
            emptyList()
        }
    }

    fun clear() {
        prefs.edit().putString(KEY, "[]").apply()
    }

    private fun save(items: List<String>) {
        val array = JSONArray()
        items.forEach { array.put(it) }
        prefs.edit().putString(KEY, array.toString()).apply()
    }

    fun looksSensitive(text: String): Boolean {
        val compact = text.replace("\\s".toRegex(), "")
        if (compact.matches(Regex("^\\d{13,19}$"))) return true
        if (text.length > 256) return true
        return false
    }

    companion object {
        private const val KEY = "items"
    }
}
