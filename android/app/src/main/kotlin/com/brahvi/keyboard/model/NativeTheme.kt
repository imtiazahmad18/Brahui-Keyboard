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

        fun defaultSystemDark(): NativeTheme {
            return NativeTheme(
                id = "gboard_dark",
                name = "System Dark",
                isDark = true,
                keyboardBackground = Color.parseColor("#263238"),
                normalKeyBackground = Color.parseColor("#37474F"),
                normalKeyText = Color.parseColor("#ECEFF1"),
                pressedKeyBackground = Color.parseColor("#455A64"),
                actionKeyBackground = Color.parseColor("#29B6F6"),
                actionKeyText = Color.parseColor("#01579B"),
                specialKeyBackground = Color.parseColor("#1E272C"),
                specialKeyText = Color.parseColor("#B0BEC5"),
                primaryText = Color.parseColor("#ECEFF1"),
                secondaryText = Color.parseColor("#90A4AE"),
                accentColor = Color.parseColor("#29B6F6"),
                suggestionBarBackground = Color.parseColor("#1E272C"),
                suggestionBarText = Color.parseColor("#ECEFF1"),
                dividerColor = Color.parseColor("#37474F")
            )
        }

        fun defaultSystemLight(): NativeTheme {
            return NativeTheme(
                id = "light_white",
                name = "System Light",
                isDark = false,
                keyboardBackground = Color.parseColor("#F1F3F4"),
                normalKeyBackground = Color.WHITE,
                normalKeyText = Color.parseColor("#202124"),
                pressedKeyBackground = Color.parseColor("#E8EAED"),
                actionKeyBackground = Color.parseColor("#1A73E8"),
                actionKeyText = Color.WHITE,
                specialKeyBackground = Color.parseColor("#E0E3E7"),
                specialKeyText = Color.parseColor("#3C4043"),
                primaryText = Color.parseColor("#202124"),
                secondaryText = Color.parseColor("#5F6368"),
                accentColor = Color.parseColor("#1A73E8"),
                suggestionBarBackground = Color.parseColor("#E8EAED"),
                suggestionBarText = Color.parseColor("#202124"),
                dividerColor = Color.parseColor("#DADCE0")
            )
        }
    }
}
