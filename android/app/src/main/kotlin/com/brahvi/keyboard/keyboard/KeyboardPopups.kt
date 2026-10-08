package com.brahvi.keyboard.keyboard

import android.content.Context
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.graphics.Typeface
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.PopupWindow
import android.widget.TextView

/** Key preview and drag-select popup used by the native keyboard canvas. */
internal class KeyPreviewPopup(context: Context, private val onAlternate: (String) -> Unit) {
    private val popup = PopupWindow(context).apply {
        isTouchable = false
        isFocusable = false
        isOutsideTouchable = false
        width = WindowManager.LayoutParams.WRAP_CONTENT
        height = WindowManager.LayoutParams.WRAP_CONTENT
    }
    private var cells: List<TextView> = emptyList()
    private var alternatives: List<String> = emptyList()
    private var displayedAlternatives: List<String> = emptyList()
    private var selected = -1

    fun show(anchor: View, label: String, left: Int, top: Int, width: Int, height: Int) {
        val density = anchor.resources.displayMetrics.density
        val content = TextView(anchor.context).apply {
            text = label
            textSize = 32f
            typeface = if (label.containsArabicScript()) nastaliq(anchor.context) else Typeface.DEFAULT
            gravity = Gravity.CENTER
            setTextColor(Color.WHITE)
            setPadding((18 * density).toInt(), (8 * density).toInt(), (18 * density).toInt(), (8 * density).toInt())
            background = bubble(density, Color.rgb(48, 58, 74))
        }
        popup.contentView = content
        positionAbove(anchor, content, left, top, width, density)
    }

    fun showAlternates(anchor: View, values: List<String>, left: Int, top: Int, width: Int) {
        val density = anchor.resources.displayMetrics.density
        alternatives = values
        // Lay cells out physically left-to-right, and reverse the data for RTL
        // so the first configured variant remains at the right edge.
        val isRtl = anchor.layoutDirection == View.LAYOUT_DIRECTION_RTL
        displayedAlternatives = if (isRtl) values.reversed() else values
        selected = displayedAlternatives.indexOf(values.firstOrNull()).coerceAtLeast(0)
        val strip = LinearLayout(anchor.context).apply {
            orientation = LinearLayout.HORIZONTAL
            layoutDirection = View.LAYOUT_DIRECTION_LTR
            gravity = Gravity.CENTER
            setPadding((5 * density).toInt(), (5 * density).toInt(), (5 * density).toInt(), (5 * density).toInt())
            background = bubble(density, Color.rgb(36, 44, 58))
        }
        cells = displayedAlternatives.mapIndexed { index, value ->
            TextView(anchor.context).apply {
                text = value
                textSize = 27f
                typeface = if (value.containsArabicScript()) nastaliq(anchor.context) else Typeface.DEFAULT
                gravity = Gravity.CENTER
                setTextColor(Color.WHITE)
                background = bubble(density, if (index == selected) Color.rgb(76, 104, 142) else Color.TRANSPARENT)
                setPadding((12 * density).toInt(), (8 * density).toInt(), (12 * density).toInt(), (8 * density).toInt())
                strip.addView(this)
            }
        }
        popup.contentView = strip
        positionAbove(anchor, strip, left, top, width, density)
    }

    fun isShowingAlternates() = popup.isShowing && alternatives.isNotEmpty()

    fun commitDefaultAlternate() {
        val value = alternatives.firstOrNull()
        dismiss()
        if (value != null) onAlternate(value)
    }

    fun handleDragMotion(event: MotionEvent, anchor: View) {
        val origin = IntArray(2)
        anchor.getLocationOnScreen(origin)
        val x = origin[0] + event.x.toInt()
        val y = origin[1] + event.y.toInt()
        val hit = cells.indexOfFirst { cell ->
            val pos = IntArray(2)
            cell.getLocationOnScreen(pos)
            x >= pos[0] && x < pos[0] + cell.width && y >= pos[1] && y < pos[1] + cell.height
        }
        if (hit >= 0 && hit != selected) {
            selected = hit
            val density = anchor.resources.displayMetrics.density
            cells.forEachIndexed { index, cell -> cell.background = bubble(density, if (index == selected) Color.rgb(76, 104, 142) else Color.TRANSPARENT) }
        }
        when (event.actionMasked) {
            MotionEvent.ACTION_UP -> {
                val value = displayedAlternatives.getOrNull(selected.coerceAtLeast(0))
                dismiss()
                if (value != null) onAlternate(value)
            }
            MotionEvent.ACTION_CANCEL -> {
                val value = displayedAlternatives.getOrNull(selected.coerceAtLeast(0))
                dismiss()
                if (value != null) onAlternate(value)
            }
        }
    }

    private fun positionAbove(anchor: View, content: View, left: Int, top: Int, width: Int, density: Float) {
        val location = IntArray(2)
        anchor.getLocationInWindow(location)
        content.measure(
            View.MeasureSpec.makeMeasureSpec(anchor.resources.displayMetrics.widthPixels, View.MeasureSpec.AT_MOST),
            View.MeasureSpec.makeMeasureSpec(anchor.resources.displayMetrics.heightPixels, View.MeasureSpec.AT_MOST)
        )
        val popupWidth = content.measuredWidth
        val keyCenter = location[0] + left + width / 2
        val screenWidth = anchor.resources.displayMetrics.widthPixels
        val x = (keyCenter - popupWidth / 2).coerceIn(0, (screenWidth - popupWidth).coerceAtLeast(0))
        val y = (location[1] + top - content.measuredHeight - (4 * density).toInt()).coerceAtLeast(0)
        popup.showAtLocation(anchor, Gravity.TOP or Gravity.START, x, y)
    }

    fun dismiss() {
        popup.dismiss()
        alternatives = emptyList()
        displayedAlternatives = emptyList()
        cells = emptyList()
        selected = -1
    }
}

/** Standalone harakat marks selected by holding the key, dragging, and releasing. */
internal class HarakatPopupView(
    context: Context,
    private val markTypeface: Typeface,
    private val onSelect: (String) -> Unit
) {
    private val popup = PopupWindow(context).apply {
        isFocusable = false
        isOutsideTouchable = false
        isTouchable = false
        width = WindowManager.LayoutParams.WRAP_CONTENT
        height = WindowManager.LayoutParams.WRAP_CONTENT
    }
    private val symbols = listOf(
        "\u064E", "\u0650", "\u0651", "\u064F", "\u0652", "\u0656",
        "\u0614", "\u064B", "\u064C", "\u064D", "\u0610", "\u0613", "\u0653", "\u0654", "\u0670"
    )
    private var cells: List<TextView> = emptyList()
    private var selected = -1
    private var stripView: LinearLayout? = null
    private var panelColor = Color.rgb(36, 44, 58)
    private var cellColor = Color.rgb(220, 239, 253)
    private var markColor = Color.rgb(12, 42, 68)
    private var selectedColor = Color.rgb(76, 104, 142)

    fun isShowing() = popup.isShowing

    fun show(anchor: View, keyTop: Int = 0, backgroundColor: Int = panelColor, keyColor: Int = cellColor, textColor: Int = markColor, activeColor: Int = selectedColor) {
        val density = anchor.resources.displayMetrics.density
        selected = -1
        applyTheme(backgroundColor, keyColor, textColor, activeColor)
        val strip = LinearLayout(anchor.context).apply {
            orientation = LinearLayout.VERTICAL
            clipChildren = false
            clipToPadding = false
            setPadding((6 * density).toInt(), (6 * density).toInt(), (6 * density).toInt(), (6 * density).toInt())
            background = bubble(density, panelColor)
        }
        stripView = strip
        val built = mutableListOf<TextView>()
        symbols.chunked(7).forEach { rowSymbols ->
            val row = LinearLayout(anchor.context).apply {
                orientation = LinearLayout.HORIZONTAL
                layoutDirection = anchor.layoutDirection
                gravity = Gravity.CENTER
                clipChildren = false
                clipToPadding = false
            }
            rowSymbols.forEach { symbol ->
                TextView(anchor.context).apply {
                    text = "\u25CC$symbol"
                    textSize = 26f
                    typeface = markTypeface
                    gravity = Gravity.CENTER
                    setTextColor(markColor)
                    background = bubble(density, cellColor)
                    layoutParams = LinearLayout.LayoutParams((36 * density).toInt(), (42 * density).toInt()).apply {
                        setMargins((2 * density).toInt(), (2 * density).toInt(), (2 * density).toInt(), (2 * density).toInt())
                    }
                    row.addView(this)
                    built.add(this)
                }
            }
            strip.addView(row)
        }
        cells = built
        popup.contentView = strip
        val location = IntArray(2)
        anchor.getLocationInWindow(location)
        strip.measure(
            View.MeasureSpec.makeMeasureSpec(anchor.resources.displayMetrics.widthPixels, View.MeasureSpec.AT_MOST),
            View.MeasureSpec.makeMeasureSpec(anchor.resources.displayMetrics.heightPixels, View.MeasureSpec.AT_MOST)
        )
        val y = (location[1] + keyTop - strip.measuredHeight - (4 * density).toInt()).coerceAtLeast(0)
        popup.showAtLocation(anchor, Gravity.TOP or Gravity.CENTER_HORIZONTAL, 0, y)
    }

    fun applyTheme(backgroundColor: Int, keyColor: Int, textColor: Int, activeColor: Int) {
        panelColor = backgroundColor
        cellColor = keyColor
        markColor = textColor
        selectedColor = activeColor
        val density = stripView?.resources?.displayMetrics?.density ?: 1f
        stripView?.background = bubble(density, panelColor)
        cells.forEachIndexed { index, cell ->
            cell.setTextColor(markColor)
            cell.text = "\u25CC${symbols[index]}"
            cell.background = bubble(density, if (index == selected) selectedColor else cellColor)
        }
    }

    fun handleDragMotion(event: MotionEvent, anchor: View) {
        val origin = IntArray(2)
        anchor.getLocationOnScreen(origin)
        val x = origin[0] + event.x.toInt()
        val y = origin[1] + event.y.toInt()
        val hit = cells.indexOfFirst { cell ->
            val pos = IntArray(2)
            cell.getLocationOnScreen(pos)
            x >= pos[0] && x < pos[0] + cell.width && y >= pos[1] && y < pos[1] + cell.height
        }
        if (hit != selected) {
            selected = hit
            val density = anchor.resources.displayMetrics.density
            cells.forEachIndexed { index, cell -> cell.background = bubble(density, if (index == selected) selectedColor else cellColor) }
        }
        when (event.actionMasked) {
            MotionEvent.ACTION_UP -> {
                val value = symbols.getOrNull(selected)
                dismiss()
                if (value != null) onSelect(value)
            }
            MotionEvent.ACTION_CANCEL -> dismiss()
        }
    }

    fun dismiss() {
        popup.dismiss()
        cells = emptyList()
        stripView = null
        selected = -1
    }
}

private fun bubble(density: Float, color: Int) = GradientDrawable().apply {
    setColor(color)
    cornerRadius = 12 * density
}

private fun nastaliq(context: Context): Typeface = runCatching {
    Typeface.createFromAsset(context.assets, "flutter_assets/NooriNastaliq.ttf")
}.getOrNull() ?: Typeface.DEFAULT

internal fun String.containsArabicScript(): Boolean = any {
    it.code in 0x0600..0x06FF || it.code in 0x0750..0x077F || it.code in 0x08A0..0x08FF
}
