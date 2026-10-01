package com.brahvi.keyboard.engine

import android.content.Context
import com.brahvi.keyboard.model.KeyAction
import com.brahvi.keyboard.model.KeyType
import com.brahvi.keyboard.model.NativeKey
import com.brahvi.keyboard.model.NativeLayout
import com.brahvi.keyboard.model.NativeRow
import org.json.JSONObject

object LayoutLoader {
    fun load(context: Context, layoutId: String): NativeLayout? {
        val obj = AssetLoader.readJson(context, "config/layouts/$layoutId.json") ?: return fallback(layoutId)
        return parse(obj) ?: fallback(layoutId)
    }

    fun parse(obj: JSONObject): NativeLayout? {
        return try {
            val rowsArray = obj.getJSONArray("rows")
            val rows = ArrayList<NativeRow>()
            for (r in 0 until rowsArray.length()) {
                val rowJson = rowsArray.getJSONArray(r)
                val keys = ArrayList<NativeKey>()
                for (k in 0 until rowJson.length()) {
                    val keyObj = rowJson.getJSONObject(k)
                    val alternates = ArrayList<String>()
                    if (keyObj.has("alternates")) {
                        val alts = keyObj.getJSONArray("alternates")
                        for (a in 0 until alts.length()) {
                            alternates.add(alts.getString(a))
                        }
                    }
                    keys.add(
                        NativeKey(
                            label = keyObj.getString("label"),
                            output = if (keyObj.has("output")) keyObj.getString("output") else null,
                            type = runCatching { KeyType.valueOf(keyObj.getString("type")) }.getOrDefault(KeyType.CHARACTER),
                            action = runCatching { KeyAction.valueOf(keyObj.getString("action")) }.getOrDefault(KeyAction.INSERT_TEXT),
                            target = if (keyObj.has("target")) keyObj.getString("target") else null,
                            weight = if (keyObj.has("weight")) keyObj.getDouble("weight").toFloat() else 1.0f,
                            active = keyObj.optBoolean("active", false),
                            alternates = alternates
                        )
                    )
                }
                rows.add(NativeRow(keys))
            }
            NativeLayout(
                id = obj.getString("id"),
                name = obj.getString("name"),
                language = obj.getString("language"),
                direction = obj.optString("direction", "ltr"),
                rows = rows
            )
        } catch (_: Exception) {
            null
        }
    }

    private fun fallback(layoutId: String): NativeLayout? {
        if (layoutId.startsWith("english")) return englishFallback()
        return brahviFallback()
    }

    private fun charKey(label: String, vararg alts: String) = NativeKey(
        label = label,
        output = label,
        type = KeyType.CHARACTER,
        action = KeyAction.INSERT_TEXT,
        alternates = alts.toList()
    )

    private fun brahviFallback(): NativeLayout {
        val row1 = listOf("ق", "و", "ع", "ر", "ت", "ے", "ء", "ی", "ہ", "پ").map {
            if (it == "ت") charKey(it, "ٹ") else charKey(it)
        }
        val row2 = listOf("ا", "س", "د", "ف", "گ", "ح", "ج", "ک", "ل", "م").map {
            if (it == "ل") charKey(it, "ڷ") else charKey(it)
        }
        val row3 = listOf(
            NativeKey("⇧", null, KeyType.SHIFT, KeyAction.SWITCH_LAYOUT, "brahvi_shift", 1.25f),
        ) + listOf("ز", "ڑ", "ڈ", "ن", "ب", "چ", "خ").map { charKey(it) } + listOf(
            NativeKey("⌫", null, KeyType.BACKSPACE, KeyAction.DELETE_BACKWARD, weight = 1.25f)
        )
        val row4 = listOf(
            NativeKey("123", null, KeyType.MODE, KeyAction.SWITCH_LAYOUT, "numbers_symbols", 1.2f),
            NativeKey("EN", null, KeyType.LANGUAGE, KeyAction.SWITCH_LANGUAGE, "english_normal", 1.0f),
            NativeKey("◌َ", null, KeyType.HARAKAT, KeyAction.OPEN_HARAKAT, weight = 1.0f),
            NativeKey("space", " ", KeyType.SPACE, KeyAction.INSERT_SPACE, weight = 3.8f),
            charKey("۔"),
            NativeKey("↵", null, KeyType.ENTER, KeyAction.SUBMIT, weight = 1.3f)
        )
        return NativeLayout("brahvi_normal", "Brahui", "brahvi", "rtl", listOf(NativeRow(row1), NativeRow(row2), NativeRow(row3), NativeRow(row4)))
    }

    private fun englishFallback(): NativeLayout {
        val row1 = "qwertyuiop".map { charKey(it.toString()) }
        val row2 = "asdfghjkl".map { charKey(it.toString()) }
        val row3 = listOf(NativeKey("⇧", null, KeyType.SHIFT, KeyAction.SWITCH_LAYOUT, "english_shift", 1.4f)) +
            "zxcvbnm".map { charKey(it.toString()) } +
            listOf(NativeKey("⌫", null, KeyType.BACKSPACE, KeyAction.DELETE_BACKWARD, weight = 1.4f))
        val row4 = listOf(
            NativeKey("123", null, KeyType.MODE, KeyAction.SWITCH_LAYOUT, "numbers_symbols", 1.3f),
            NativeKey("براہوئی", null, KeyType.LANGUAGE, KeyAction.SWITCH_LANGUAGE, "brahvi_normal", 1.3f),
            NativeKey("space", " ", KeyType.SPACE, KeyAction.INSERT_SPACE, weight = 4.5f),
            charKey("."),
            NativeKey("↵", null, KeyType.ENTER, KeyAction.SUBMIT, weight = 1.4f)
        )
        return NativeLayout("english_normal", "English", "english", "ltr", listOf(NativeRow(row1), NativeRow(row2), NativeRow(row3), NativeRow(row4)))
    }
}
