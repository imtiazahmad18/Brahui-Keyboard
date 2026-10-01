package com.brahvi.keyboard.model

import android.graphics.Color

data class NativeTheme(
    val id: String,
    val name: String,
    val isDark: Boolean,
    val keyboardBackground: Int,
    val normalKeyBackground: Int,
    val normalKeyText: Int,
    val pressedKeyBackground: Int,
    val actionKeyBackground: Int,
    val actionKeyText: Int,
    val specialKeyBackground: Int,
    val specialKeyText: Int,
    val primaryText: Int,
    val secondaryText: Int,
    val accentColor: Int,
    val suggestionBarBackground: Int,
    val suggestionBarText: Int,
    val dividerColor: Int
) {
    companion object {
        fun parseHexColor(colorStr: String): Int {
            return try {
                Color.parseColor(colorStr)
            } catch (e: Exception) {
                Color.DKGRAY
            }
        }

        fun defaultNavyDark(): NativeTheme {
            return NativeTheme(
                id = "navy_dark",
                name = "Navy Dark",
                isDark = true,
                keyboardBackground = Color.parseColor("#123A5E"),
                normalKeyBackground = Color.parseColor("#DCEFFD"),
                normalKeyText = Color.parseColor("#0C2A44"),
                pressedKeyBackground = Color.parseColor("#8CCDF2"),
                actionKeyBackground = Color.parseColor("#5CB4E8"),
                actionKeyText = Color.parseColor("#0C2A44"),
                specialKeyBackground = Color.parseColor("#0C2A44"),
                specialKeyText = Color.parseColor("#B9DFF7"),
                primaryText = Color.parseColor("#F4FAFF"),
                secondaryText = Color.parseColor("#8CCDF2"),
                accentColor = Color.parseColor("#5CB4E8"),
                suggestionBarBackground = Color.parseColor("#0C2A44"),
                suggestionBarText = Color.parseColor("#F4FAFF"),
                dividerColor = Color.parseColor("#214D70")
            )
        }
    }
}
