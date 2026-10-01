package com.brahvi.keyboard.engine

import android.content.Context
import android.view.inputmethod.InputConnection

object UnicodeHelper {
    const val BRAHVI_LAM_DOTS = "\u06B7"

    val COMBINING_MARKS = setOf(
        0x064B, 0x064C, 0x064D, 0x064E, 0x064F, 0x0650,
        0x0651, 0x0652, 0x0653, 0x0654, 0x0670, 0x0657
    )

    fun isCombiningMark(codePoint: Int): Boolean = COMBINING_MARKS.contains(codePoint)

    fun handleSafeBackspace(ic: InputConnection?) {
        if (ic == null) return
        val textBefore = ic.getTextBeforeCursor(4, 0)
        if (textBefore.isNullOrEmpty()) {
            ic.deleteSurroundingText(1, 0)
            return
        }
        val lastChar = textBefore.last()
        val codePoint = lastChar.code
        when {
            isCombiningMark(codePoint) -> ic.deleteSurroundingText(1, 0)
            Character.isSurrogate(lastChar) -> ic.deleteSurroundingText(2, 0)
            else -> ic.deleteSurroundingText(1, 0)
        }
    }

    fun lastWord(text: String): String {
        if (text.isEmpty()) return ""
        var start = text.length
        while (start > 0) {
            val ch = text[start - 1]
            if (ch.isWhitespace() || isSeparator(ch)) break
            start--
        }
        return text.substring(start)
    }

    private fun isSeparator(ch: Char): Boolean {
        return ch == '،' || ch == '۔' || ch == '؟' || ch == '؛' ||
            ch == '.' || ch == ',' || ch == '!' || ch == '?' || ch == ':' || ch == ';'
    }
}
