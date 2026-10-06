package com.brahvi.keyboard

import android.content.Context
import android.content.res.Configuration
import android.inputmethodservice.InputMethodService
import android.media.AudioManager
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.text.InputType
import android.view.HapticFeedbackConstants
import android.view.View
import android.view.ViewGroup
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputMethodManager
import com.brahvi.keyboard.engine.SuggestionEngine
import com.brahvi.keyboard.engine.UnicodeHelper
import com.brahvi.keyboard.clipboard.ClipboardStore
import com.brahvi.keyboard.keyboard.NativeKeyboardView
import com.brahvi.keyboard.model.*
import com.brahvi.keyboard.settings.KeyboardPreferences
import org.json.JSONObject

class BrahviInputMethodService : InputMethodService() {

    private lateinit var prefs: KeyboardPreferences
    private lateinit var suggestionEngine: SuggestionEngine
    private lateinit var clipboardStore: ClipboardStore
    private var keyboardView: NativeKeyboardView? = null

    private var currentLayoutId = "brahvi_normal"
    private var previousLanguageLayoutId = "brahvi_normal"

    private val layoutsCache = HashMap<String, NativeLayout>()
    private val themesCache = HashMap<String, NativeTheme>()

    private var audioManager: AudioManager? = null
    private var vibrator: Vibrator? = null
    private var isPasswordField = false

    // Emulators report a physical keyboard even when the user needs the on-screen IME.
    override fun onEvaluateInputViewShown(): Boolean = true

    override fun onCreate() {
        super.onCreate()

        prefs = KeyboardPreferences(this)
        clipboardStore = ClipboardStore(this)

        suggestionEngine = SuggestionEngine(this)
        suggestionEngine.initialize()

        audioManager =
            getSystemService(Context.AUDIO_SERVICE) as? AudioManager

        vibrator =
            getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator

        loadThemes()

        loadLayout("brahvi_normal")
        loadLayout("brahvi_shift")
        loadLayout("brahvi_phonetic")
        loadLayout("brahvi_phonetic_shift")
        loadLayout("english_normal")
        loadLayout("english_shift")
        loadLayout("numbers_symbols")
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        if (::prefs.isInitialized && prefs.themeId == "system") applyCurrentTheme()
    }

    override fun onCreateInputView(): View {
        android.util.Log.d("BrahviKeyboard", "onCreateInputView called")

        keyboardView = NativeKeyboardView(
            context = this,
            prefs = prefs,
            onKeyAction = { handleKey(it) },
            onSelectSuggestion = { handleSuggestionSelected(it) },
            onOpenSettings = { openSettingsScreen() },
            onOpenClipboard = { showClipboardMenu() },
            onOpenThemes = { showThemeMenu() }
        ).apply {
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
        }

        android.util.Log.d("BrahviKeyboard", "NativeKeyboardView created")

        applyCurrentTheme()

        val defaultLang = prefs.defaultLanguage
        val initialLayoutId = if (defaultLang == "english") {
            "english_normal"
        } else {
            preferredBrahviLayout()
        }

        currentLayoutId = initialLayoutId
        previousLanguageLayoutId = initialLayoutId

        android.util.Log.d("BrahviKeyboard", "Loading layout: $initialLayoutId")

        // Populate initial key views
        switchLayout(initialLayoutId)

        // Force an immediate measure pass before returning to the system
        keyboardView?.measure(
            View.MeasureSpec.makeMeasureSpec(resources.displayMetrics.widthPixels, View.MeasureSpec.EXACTLY),
            View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED)
        )

        return keyboardView!!
    }

    override fun onStartInputView(
        info: EditorInfo?,
        restarting: Boolean
    ) {
        super.onStartInputView(info, restarting)

        // Check for password/sensitive fields
        if (info != null) {
            val inputType = info.inputType
            val variation =
                inputType and InputType.TYPE_MASK_VARIATION

            isPasswordField =
                variation == InputType.TYPE_TEXT_VARIATION_PASSWORD ||
                        variation == InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD ||
                        variation == InputType.TYPE_TEXT_VARIATION_WEB_PASSWORD
        } else {
            isPasswordField = false
        }

        applyCurrentTheme()
        recordCurrentClipboard()

        // FIX:
        // updateSuggestions expects List<String>, not String.
        updateSuggestions(emptyList())
    }

    private fun handleKey(key: NativeKey) {
        performFeedback()

        when (key.action) {

            KeyAction.INSERT_TEXT -> {
                val text = key.output ?: key.label

                currentInputConnection?.commitText(
                    text,
                    1
                )

                triggerSuggestionsUpdate()
            }

            KeyAction.INSERT_SPACE -> {
                currentInputConnection?.commitText(
                    " ",
                    1
                )

                triggerSuggestionsUpdate()
            }

            KeyAction.DELETE_BACKWARD -> {
                UnicodeHelper.handleSafeBackspace(
                    currentInputConnection
                )

                triggerSuggestionsUpdate()
            }

            KeyAction.SUBMIT -> {
                handleEnterAction()
            }

            KeyAction.SWITCH_LAYOUT -> {
                key.target?.let {
                    switchLayout(it)
                }
            }

            KeyAction.SWITCH_LANGUAGE -> {
                switchLanguage()
            }

            KeyAction.RESTORE_PREVIOUS_LAYOUT -> {
                switchLayout(previousLanguageLayoutId)
            }

            KeyAction.OPEN_HARAKAT -> {
                // Handled in view
            }

            KeyAction.OPEN_CLIPBOARD -> {
                // Clipboard paste
                val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as android.content.ClipboardManager
                if (clipboard.hasPrimaryClip()) {
                    val item = clipboard.primaryClip?.getItemAt(0)
                    val pasteText = item?.coerceToText(this)?.toString()
                    if (!pasteText.isNullOrEmpty()) {
                        currentInputConnection?.commitText(pasteText, 1)
                    }
                }
            }

            KeyAction.OPEN_EMOJI -> {
                // Emoji picker is opened by the native toolbar.
            }

            KeyAction.SWITCH_KEYBOARD -> {
                val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as? InputMethodManager
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    if (!switchToNextInputMethod(false)) imm?.showInputMethodPicker()
                } else {
                    imm?.showInputMethodPicker()
                }
            }

            KeyAction.NAVIGATE -> {
                // Pure navigation: NEVER insert text
            }
        }
    }

    private fun handleEnterAction() {
        val ic = currentInputConnection ?: return
        val currentInfo = currentInputEditorInfo

        if (
            currentInfo != null &&
            currentInfo.imeOptions and
            EditorInfo.IME_FLAG_NO_ENTER_ACTION == 0
        ) {
            val action =
                currentInfo.imeOptions and
                        EditorInfo.IME_MASK_ACTION

            if (
                action != EditorInfo.IME_ACTION_NONE &&
                action != EditorInfo.IME_ACTION_UNSPECIFIED
            ) {
                ic.performEditorAction(action)
                return
            }
        }

        ic.commitText("\n", 1)
    }

    private fun handleSuggestionSelected(
        suggestion: String
    ) {
        val ic = currentInputConnection ?: return

        val textBefore =
            ic.getTextBeforeCursor(30, 0)?.toString()
                ?: ""

        val lastWord =
            textBefore
                .split("\\s+".toRegex())
                .lastOrNull()
                ?: ""

        if (lastWord.isNotEmpty()) {
            ic.deleteSurroundingText(
                lastWord.length,
                0
            )
        }

        ic.commitText(
            "$suggestion ",
            1
        )

        // FIX:
        // Pass an empty List<String>, not an empty String.
        updateSuggestions(emptyList())
    }

    private fun triggerSuggestionsUpdate() {

        if (
            !prefs.suggestionsEnabled ||
            isPasswordField
        ) {
            // FIX:
            // updateSuggestions expects List<String>.
            updateSuggestions(emptyList())
            return
        }

        val ic = currentInputConnection
            ?: return

        val textBefore =
            ic.getTextBeforeCursor(20, 0)?.toString()
                ?: ""

        val lastWord =
            textBefore
                .split("\\s+".toRegex())
                .lastOrNull()
                ?: ""

        val currentLayout =
            layoutsCache[currentLayoutId]

        val lang =
            currentLayout?.language ?: "brahvi"

        val suggestions =
            suggestionEngine.getSuggestions(
                lastWord,
                lang
            )

        updateSuggestions(suggestions)
    }

    private fun updateSuggestions(
        suggestions: List<String>
    ) {
        keyboardView?.updateSuggestions(
            suggestions
        )
    }

    private fun switchLayout(
        layoutId: String
    ) {
        val resolvedLayoutId = when {
            prefs.phoneticLayout && layoutId == "brahvi_normal" -> "brahvi_phonetic"
            prefs.phoneticLayout && layoutId == "brahvi_shift" -> "brahvi_phonetic_shift"
            !prefs.phoneticLayout && layoutId == "brahvi_phonetic" -> "brahvi_normal"
            !prefs.phoneticLayout && layoutId == "brahvi_phonetic_shift" -> "brahvi_shift"
            else -> layoutId
        }
        currentLayoutId = resolvedLayoutId

        var layout =
            layoutsCache[resolvedLayoutId]

        if (layout == null) {
            layout = loadLayout(resolvedLayoutId)
        }

        layout?.let {
            keyboardView?.setLayout(it)
        }
    }

    private fun preferredBrahviLayout(): String =
        if (prefs.phoneticLayout) "brahvi_phonetic" else "brahvi_normal"

    private fun switchLanguage() {
        val target = if (currentLayoutId.startsWith("english")) {
            preferredBrahviLayout()
        } else {
            "english_normal"
        }
        previousLanguageLayoutId = target
        switchLayout(target)
    }

    private fun recordCurrentClipboard() {
        if (!prefs.clipboardHistory) return
        val manager = getSystemService(Context.CLIPBOARD_SERVICE) as? android.content.ClipboardManager ?: return
        if (manager.hasPrimaryClip()) {
            manager.primaryClip?.getItemAt(0)?.coerceToText(this)?.toString()?.let {
                clipboardStore.add(it, prefs.clipboardMaxItems)
            }
        }
    }

    private fun showClipboardMenu() {
        recordCurrentClipboard()
        val entries = if (prefs.clipboardHistory) clipboardStore.items() else emptyList()
        keyboardView?.showClipboardMenu(entries) { text ->
            currentInputConnection?.commitText(text, 1)
            triggerSuggestionsUpdate()
        }
    }

    private fun showThemeMenu() {
        val themes = themesCache.values.map { theme ->
            theme.id to if (theme.id == "system") systemTheme().keyboardBackground else theme.keyboardBackground
        }.sortedBy { it.first }
        keyboardView?.showThemeMenu(themes) { id ->
            prefs.themeId = id
            getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                .edit()
                .putString("flutter.currentThemeId", id)
                .apply()
            applyCurrentTheme()
        }
    }

    private fun applyCurrentTheme() {
        val theme = if (prefs.themeId == "system") systemTheme() else themesCache[prefs.themeId]
        keyboardView?.applyTheme(theme ?: systemTheme())
    }

    private fun systemTheme(): NativeTheme {
        val themeId = if (isSystemInDarkMode(this)) "gboard_dark" else "light_white"
        return themesCache[themeId] ?: if (isSystemInDarkMode(this)) {
            NativeTheme.defaultSystemDark()
        } else {
            NativeTheme.defaultSystemLight()
        }
    }

    private fun isSystemInDarkMode(context: Context): Boolean {
        val nightModeFlags = context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
        return nightModeFlags == Configuration.UI_MODE_NIGHT_YES
    }

    private fun performFeedback() {

        if (prefs.hapticFeedback) {
            try {

                if (
                    Build.VERSION.SDK_INT >=
                    Build.VERSION_CODES.O
                ) {
                    vibrator?.vibrate(
                        VibrationEffect.createOneShot(
                            20,
                            VibrationEffect.DEFAULT_AMPLITUDE
                        )
                    )
                } else {
                    @Suppress("DEPRECATION")
                    vibrator?.vibrate(20)
                }

            } catch (e: Exception) {
                keyboardView?.performHapticFeedback(
                    HapticFeedbackConstants.KEYBOARD_TAP
                )
            }
        }

        if (prefs.soundOnKeyPress) {
            audioManager?.playSoundEffect(
                AudioManager.FX_KEYPRESS_STANDARD,
                1.0f
            )
        }
    }

    private fun loadThemes() {
        try {

            val jsonString =
                assets
                    .open("flutter_assets/shared/config/themes.json")
                    .bufferedReader()
                    .use {
                        it.readText()
                    }

            val obj =
                JSONObject(jsonString)

            val themesArray =
                obj.getJSONArray("themes")

            for (i in 0 until themesArray.length()) {

                val t =
                    themesArray.getJSONObject(i)

                val id =
                    t.getString("id")

                val theme =
                    NativeTheme(
                        id = id,
                        name = t.getString("name"),
                        isDark = t.optBoolean(
                            "isDark",
                            false
                        ),
                        keyboardBackground =
                            NativeTheme.parseHexColor(
                                t.getString(
                                    "keyboardBackground"
                                )
                            ),
                        normalKeyBackground =
                            NativeTheme.parseHexColor(
                                t.getString(
                                    "normalKeyBackground"
                                )
                            ),
                        normalKeyText =
                            NativeTheme.parseHexColor(
                                t.getString(
                                    "normalKeyText"
                                )
                            ),
                        pressedKeyBackground =
                            NativeTheme.parseHexColor(
                                t.getString(
                                    "pressedKeyBackground"
                                )
                            ),
                        actionKeyBackground =
                            NativeTheme.parseHexColor(
                                t.getString(
                                    "actionKeyBackground"
                                )
                            ),
                        actionKeyText =
                            NativeTheme.parseHexColor(
                                t.getString(
                                    "actionKeyText"
                                )
                            ),
                        specialKeyBackground =
                            NativeTheme.parseHexColor(
                                t.getString(
                                    "specialKeyBackground"
                                )
                            ),
                        specialKeyText =
                            NativeTheme.parseHexColor(
                                t.getString(
                                    "specialKeyText"
                                )
                            ),
                        primaryText =
                            NativeTheme.parseHexColor(
                                t.getString(
                                    "primaryText"
                                )
                            ),
                        secondaryText =
                            NativeTheme.parseHexColor(
                                t.getString(
                                    "secondaryText"
                                )
                            ),
                        accentColor =
                            NativeTheme.parseHexColor(
                                t.getString(
                                    "accentColor"
                                )
                            ),
                        suggestionBarBackground =
                            NativeTheme.parseHexColor(
                                t.getString(
                                    "suggestionBarBackground"
                                )
                            ),
                        suggestionBarText =
                            NativeTheme.parseHexColor(
                                t.getString(
                                    "suggestionBarText"
                                )
                            ),
                        dividerColor =
                            NativeTheme.parseHexColor(
                                t.getString(
                                    "dividerColor"
                                )
                            )
                    )

                themesCache[id] = theme
            }

        } catch (e: Exception) {

            themesCache["gboard_dark"] = NativeTheme.defaultSystemDark()
            themesCache["light_white"] = NativeTheme.defaultSystemLight()
        }
    }

    private fun loadLayout(layoutId: String): NativeLayout? {
        return try {
            val jsonString = assets
                .open("flutter_assets/shared/config/layouts/$layoutId.json")
                .bufferedReader()
                .use { it.readText() }

            val obj = JSONObject(jsonString)
            val rowsArray = obj.getJSONArray("rows")

            val rows = ArrayList<NativeRow>()

            for (r in 0 until rowsArray.length()) {
                val rowJson = rowsArray.getJSONArray(r)
                val keys = ArrayList<NativeKey>()

                for (k in 0 until rowJson.length()) {
                    val keyObj = rowJson.getJSONObject(k)

                    val label = keyObj.getString("label")

                    val output = if (keyObj.has("output")) {
                        keyObj.getString("output")
                    } else {
                        null
                    }

                    val typeStr = keyObj.getString("type")
                    val actionStr = keyObj.getString("action")

                    val target = if (keyObj.has("target")) {
                        keyObj.getString("target")
                    } else {
                        null
                    }

                    val weight = if (keyObj.has("weight")) {
                        keyObj.getDouble("weight").toFloat()
                    } else {
                        1.0f
                    }

                    val active = keyObj.optBoolean("active", false)

                    val alternatesList = ArrayList<String>()

                    if (keyObj.has("alternates")) {
                        val alts = keyObj.getJSONArray("alternates")

                        for (a in 0 until alts.length()) {
                            alternatesList.add(alts.getString(a))
                        }
                    }

                    keys.add(
                        NativeKey(
                            label = label,
                            output = output,
                            type = KeyType.valueOf(typeStr),
                            action = KeyAction.valueOf(actionStr),
                            target = target,
                            weight = weight,
                            active = active,
                            alternates = alternatesList
                        )
                    )
                }

                rows.add(NativeRow(keys))
            }

            val layout = NativeLayout(
                id = obj.getString("id"),
                name = obj.getString("name"),
                language = obj.getString("language"),
                direction = obj.optString("direction", "ltr"),
                rows = rows
            )

            layoutsCache[layoutId] = layout

            layout

        } catch (e: Exception) {
            android.util.Log.e(
                "BrahviKeyboard",
                "Failed to load layout: $layoutId",
                e
            )
            null
        }
    }
    private fun openSettingsScreen() {
        val intent = android.content.Intent(this, MainActivity::class.java).apply {
            addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
            putExtra("route", "/appearance")
        }
        startActivity(intent)
    }
}
