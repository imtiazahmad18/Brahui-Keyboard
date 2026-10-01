package com.brahvi.keyboard

import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.view.inputmethod.InputMethodManager
import com.brahvi.keyboard.settings.KeyboardPreferences
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.inputmethodservice.InputMethodService
import android.view.View

class MyKeyboardService : InputMethodService() {

    override fun onCreateInputView(): View {
        return layoutInflater.inflate(
            R.layout.keyboard_view,
            null
        )
    }
}
class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.brahvi.keyboard/settings"

    override fun getInitialRoute(): String = intent?.getStringExtra("route") ?: "/"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            val prefs = KeyboardPreferences(this)

            when (call.method) {
                "syncSettings" -> {
                    val args = call.arguments as? Map<*, *>
                    if (args != null) {
                        (args["currentThemeId"] as? String)?.let { prefs.themeId = it }
                        (args["keyboardHeightRatio"] as? Number)?.let { prefs.heightRatio = it.toFloat() }
                        (args["keySpacing"] as? Number)?.let { prefs.keySpacing = it.toFloat() }
                        (args["suggestionsEnabled"] as? Boolean)?.let { prefs.suggestionsEnabled = it }
                        (args["autocorrectEnabled"] as? Boolean)?.let { prefs.autocorrectEnabled = it }
                        (args["hapticFeedback"] as? Boolean)?.let { prefs.hapticFeedback = it }
                        (args["soundOnKeyPress"] as? Boolean)?.let { prefs.soundOnKeyPress = it }
                        (args["popupOnKeyPress"] as? Boolean)?.let { prefs.popupOnKeyPress = it }
                        (args["clipboardHistory"] as? Boolean)?.let { prefs.clipboardHistory = it }
                        (args["defaultLanguage"] as? String)?.let { prefs.defaultLanguage = it }
                        (args["phoneticLayout"] as? Boolean)?.let { prefs.phoneticLayout = it }
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                "isKeyboardEnabled" -> {
                    // Android restricts direct reads of ENABLED_INPUT_METHODS
                    // for apps targeting newer SDKs. InputMethodManager exposes
                    // the same information through its supported public API.
                    val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as? InputMethodManager
                    val isEnabled = imm?.enabledInputMethodList?.any { it.packageName == packageName } ?: false
                    result.success(isEnabled)
                }
                "isKeyboardSelected" -> {
                    try {
                        val defaultMethod = Settings.Secure.getString(contentResolver, Settings.Secure.DEFAULT_INPUT_METHOD) ?: ""
                        result.success(defaultMethod.contains(packageName))
                    } catch (_: SecurityException) {
                        // Some Android builds also protect DEFAULT_INPUT_METHOD.
                        // Report unknown/not selected without failing app startup.
                        result.success(false)
                    }
                }
                "openKeyboardSettings" -> {
                    val intent = Intent(Settings.ACTION_INPUT_METHOD_SETTINGS)
                    startActivity(intent)
                    result.success(null)
                }
                "showInputMethodPicker" -> {
                    val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as? InputMethodManager
                    imm?.showInputMethodPicker()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
