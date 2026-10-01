package com.brahvi.keyboard.settings

import android.content.Context
import android.content.SharedPreferences

class KeyboardPreferences(context: Context) {
    private val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    companion object {
        const val PREFS_NAME = "brahvi_keyboard_prefs"
        const val KEY_THEME_ID = "currentThemeId"
        const val KEY_THEME_MODE = "themeMode"
        const val KEY_HEIGHT_RATIO = "keyboardHeightRatio"
        const val KEY_KEY_SIZE_RATIO = "keySizeRatio"
        const val KEY_SPACING = "keySpacing"
        const val KEY_SUGGESTIONS = "suggestionsEnabled"
        const val KEY_AUTOCORRECT = "autocorrectEnabled"
        const val KEY_HAPTIC = "hapticFeedback"
        const val KEY_SOUND = "soundOnKeyPress"
        const val KEY_POPUP = "popupOnKeyPress"
        const val KEY_CLIPBOARD = "clipboardHistory"
        const val KEY_CLIPBOARD_MAX = "clipboardMaxItems"
        const val KEY_DEFAULT_LANG = "defaultLanguage"
        const val KEY_PHONETIC = "phoneticLayout"
    }

    var themeId: String
        get() = prefs.getString(KEY_THEME_ID, "system") ?: "system"
        set(value) = prefs.edit().putString(KEY_THEME_ID, value).apply()

    var themeMode: String
        get() = prefs.getString(KEY_THEME_MODE, "system") ?: "system"
        set(value) = prefs.edit().putString(KEY_THEME_MODE, value).apply()

    var heightRatio: Float
        get() = prefs.getFloat(KEY_HEIGHT_RATIO, 0.96f)
        set(value) = prefs.edit().putFloat(KEY_HEIGHT_RATIO, value).apply()

    var keySizeRatio: Float
        get() = prefs.getFloat(KEY_KEY_SIZE_RATIO, 1.0f)
        set(value) = prefs.edit().putFloat(KEY_KEY_SIZE_RATIO, value).apply()

    var keySpacing: Float
        get() = prefs.getFloat(KEY_SPACING, 5.0f)
        set(value) = prefs.edit().putFloat(KEY_SPACING, value).apply()

    var suggestionsEnabled: Boolean
        get() = prefs.getBoolean(KEY_SUGGESTIONS, true)
        set(value) = prefs.edit().putBoolean(KEY_SUGGESTIONS, value).apply()

    var autocorrectEnabled: Boolean
        get() = prefs.getBoolean(KEY_AUTOCORRECT, false)
        set(value) = prefs.edit().putBoolean(KEY_AUTOCORRECT, value).apply()

    var hapticFeedback: Boolean
        get() = prefs.getBoolean(KEY_HAPTIC, true)
        set(value) = prefs.edit().putBoolean(KEY_HAPTIC, value).apply()

    var soundOnKeyPress: Boolean
        get() = prefs.getBoolean(KEY_SOUND, false)
        set(value) = prefs.edit().putBoolean(KEY_SOUND, value).apply()

    var popupOnKeyPress: Boolean
        get() = prefs.getBoolean(KEY_POPUP, true)
        set(value) = prefs.edit().putBoolean(KEY_POPUP, value).apply()

    var clipboardHistory: Boolean
        get() = prefs.getBoolean(KEY_CLIPBOARD, true)
        set(value) = prefs.edit().putBoolean(KEY_CLIPBOARD, value).apply()

    var clipboardMaxItems: Int
        get() = prefs.getInt(KEY_CLIPBOARD_MAX, 20)
        set(value) = prefs.edit().putInt(KEY_CLIPBOARD_MAX, value).apply()

    var defaultLanguage: String
        get() = prefs.getString(KEY_DEFAULT_LANG, "brahvi") ?: "brahvi"
        set(value) = prefs.edit().putString(KEY_DEFAULT_LANG, value).apply()

    var phoneticLayout: Boolean
        get() = prefs.getBoolean(KEY_PHONETIC, true)
        set(value) = prefs.edit().putBoolean(KEY_PHONETIC, value).apply()
}
