package com.brahvi.keyboard.keyboard

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowInsets
import android.widget.LinearLayout
import android.widget.PopupWindow
import android.widget.ScrollView
import android.widget.TextView
import android.widget.ImageButton
import com.brahvi.keyboard.model.KeyAction
import com.brahvi.keyboard.model.KeyType
import com.brahvi.keyboard.model.NativeKey
import com.brahvi.keyboard.model.NativeLayout
import com.brahvi.keyboard.model.NativeTheme
import com.brahvi.keyboard.settings.KeyboardPreferences
import com.brahvi.keyboard.R

class NativeKeyboardView(
    context: Context,
    private val prefs: KeyboardPreferences,
    private val onKeyAction: (NativeKey) -> Unit,
    private val onSelectSuggestion: (String) -> Unit,
    private val onOpenSettings: (() -> Unit)? = null,
    private val onOpenClipboard: (() -> Unit)? = null,
    private val onOpenThemes: (() -> Unit)? = null
) : LinearLayout(context) {

    private val nastaliqTypeface: Typeface? = runCatching {
        Typeface.createFromAsset(context.assets, "flutter_assets/NooriNastaliq.ttf")
    }.getOrNull()

    private val suggestionBarContainer: LinearLayout
    private val suggestionTextViews = mutableListOf<TextView>()
    private val toolbarButtons = mutableListOf<ImageButton>()
    private val innerKeyboardView: KeyCanvasView
    private var currentTheme: NativeTheme = NativeTheme.defaultNavyDark()

    init {
        orientation = VERTICAL
        setBackgroundColor(currentTheme.keyboardBackground)
        // Leave the device-specific navigation/keyboard-switcher area clear below
        // the last key row. Insets vary by gesture navigation, three-button nav,
        // and manufacturers that add their own IME controls.
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
            setOnApplyWindowInsetsListener { view, insets ->
                val navBottom = insets.getInsets(WindowInsets.Type.navigationBars()).bottom
                val gestureBottom = insets.getInsets(WindowInsets.Type.systemGestures()).bottom
                view.setPadding(view.paddingLeft, view.paddingTop, view.paddingRight, maxOf(navBottom, gestureBottom))
                insets
            }
            requestApplyInsets()
        } else {
            val navBarHeight = resources.getIdentifier("navigation_bar_height", "dimen", "android")
                .takeIf { it != 0 }
                ?.let { resources.getDimensionPixelSize(it) }
                ?: 0
            setPadding(paddingLeft, paddingTop, paddingRight, navBarHeight)
        }

        // 1. Suggestion Bar
        suggestionBarContainer = LinearLayout(context).apply {
            orientation = HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setBackgroundColor(currentTheme.suggestionBarBackground)
            setPadding(16, 8, 16, 8)
        }

        for (i in 0 until 3) {
            val tv = TextView(context).apply {
                layoutParams = LayoutParams(0, LayoutParams.MATCH_PARENT, 1f)
                gravity = Gravity.CENTER
                textSize = 16f
                setTextColor(currentTheme.suggestionBarText)
                visibility = GONE
                setOnClickListener {
                    val text = text.toString()
                    if (text.isNotEmpty()) {
                        onSelectSuggestion(text)
                    }
                }
            }
            suggestionBarContainer.addView(tv)
            suggestionTextViews.add(tv)
        }

        suggestionBarContainer.addView(toolbarButton(R.drawable.ime_settings, "Settings") { onOpenSettings?.invoke() })
        suggestionBarContainer.addView(toolbarButton(R.drawable.ime_clipboard, "Clipboard") { onOpenClipboard?.invoke() })
        suggestionBarContainer.addView(toolbarButton(R.drawable.ime_palette, "Themes") { onOpenThemes?.invoke() })
        suggestionBarContainer.addView(toolbarButton(R.drawable.ime_emoji, "Emojis") { showEmojiPicker() })

        addView(
            suggestionBarContainer,
            LayoutParams(LayoutParams.MATCH_PARENT, (44 * resources.displayMetrics.density).toInt())
        )

        // 2. Main Keyboard Canvas View
        innerKeyboardView = KeyCanvasView(context)
        addView(
            innerKeyboardView,
            LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
        )
    }

    fun setLayout(layout: NativeLayout) {
        innerKeyboardView.setLayout(layout)
    }

    fun applyTheme(theme: NativeTheme) {
        currentTheme = theme
        setBackgroundColor(theme.keyboardBackground)
        suggestionBarContainer.setBackgroundColor(theme.suggestionBarBackground)
        for (tv in suggestionTextViews) {
            tv.setTextColor(theme.suggestionBarText)
        }
        toolbarButtons.forEach { it.imageTintList = android.content.res.ColorStateList.valueOf(theme.secondaryText) }
        innerKeyboardView.applyTheme(theme)
    }

    fun updateSuggestions(suggestions: List<String>) {
        for (i in suggestionTextViews.indices) {
            if (i < suggestions.size) {
                suggestionTextViews[i].text = suggestions[i]
                suggestionTextViews[i].typeface = if (suggestions[i].containsArabicScript()) {
                    nastaliqTypeface ?: Typeface.DEFAULT
                } else {
                    Typeface.DEFAULT
                }
                suggestionTextViews[i].visibility = VISIBLE
            } else {
                suggestionTextViews[i].text = ""
                suggestionTextViews[i].visibility = GONE
            }
        }
    }

    private fun toolbarButton(icon: Int, description: String, action: () -> Unit) =
        ImageButton(context).apply {
            setImageResource(icon)
            contentDescription = description
            imageTintList = android.content.res.ColorStateList.valueOf(currentTheme.secondaryText)
            scaleType = android.widget.ImageView.ScaleType.CENTER
            setBackgroundResource(android.R.drawable.list_selector_background)
            layoutParams = LayoutParams(0, LayoutParams.MATCH_PARENT, 1f)
            toolbarButtons.add(this)
            setOnClickListener { action() }
        }

    /** A compact, rounded emoji sheet with selectable Unicode emoji. */
    private fun showEmojiPicker() {
        val density = resources.displayMetrics.density
        val emojis = listOf(
            "😀", "😃", "😄", "😁", "😆", "😅", "😂", "🤣", "😊", "😇", "🙂", "🙃",
            "😉", "😍", "🥰", "😘", "😋", "😎", "🤩", "🥳", "😭", "😢", "😡", "🤔",
            "👍", "👎", "👏", "🙏", "🤝", "💪", "👋", "❤️", "💙", "💚", "💯", "✨",
            "🔥", "🌟", "🌹", "🌙", "☀️", "🍎", "🍕", "☕", "⚽", "🎉", "🚗", "✈️"
        )
        lateinit var popup: PopupWindow
        val sheet = LinearLayout(context).apply {
            orientation = VERTICAL
            setPadding((8 * density).toInt(), (8 * density).toInt(), (8 * density).toInt(), (8 * density).toInt())
            background = android.graphics.drawable.GradientDrawable().apply {
                setColor(currentTheme.suggestionBarBackground)
                cornerRadius = 18 * density
                setStroke((1 * density).toInt(), currentTheme.dividerColor)
            }
        }
        emojis.chunked(6).forEach { emojiRow ->
            val row = LinearLayout(context).apply { orientation = HORIZONTAL }
            emojiRow.forEach { emoji ->
                row.addView(TextView(context).apply {
                    text = emoji
                    textSize = 26f
                    gravity = Gravity.CENTER
                    contentDescription = emoji
                    setBackgroundResource(android.R.drawable.list_selector_background)
                    layoutParams = LayoutParams(0, (44 * density).toInt(), 1f)
                    setOnClickListener {
                        onKeyAction(NativeKey(emoji, emoji, KeyType.CHARACTER, KeyAction.INSERT_TEXT))
                        popup.dismiss()
                    }
                })
            }
            sheet.addView(row)
        }
        popup = PopupWindow(sheet, (minOf(360, resources.displayMetrics.widthPixels / density.toInt()) * density).toInt(), LayoutParams.WRAP_CONTENT, true).apply {
            elevation = 12 * density
            isOutsideTouchable = true
        }
        val anchor = suggestionBarContainer.getChildAt(suggestionBarContainer.childCount - 1)
        if (anchor != null) popup.showAsDropDown(anchor, 0, 0)
    }

    fun showClipboardMenu(items: List<String>, onSelect: (String) -> Unit) {
        showMenu("Clipboard", items.ifEmpty { listOf("Clipboard is empty") }, onSelect)
    }

    fun showThemeMenu(themes: List<Pair<String, Int>>, onSelect: (String) -> Unit) {
        val density = resources.displayMetrics.density
        lateinit var popup: PopupWindow
        val panel = LinearLayout(context).apply {
            orientation = VERTICAL
            setPadding((12 * density).toInt(), (12 * density).toInt(), (12 * density).toInt(), (12 * density).toInt())
            setBackgroundColor(currentTheme.suggestionBarBackground)
        }
        themes.chunked(4).forEach { themeRow ->
            val row = LinearLayout(context).apply { orientation = HORIZONTAL }
            themeRow.forEach { (id, color) ->
                row.addView(ImageButton(context).apply {
                    contentDescription = id
                    background = if (id == "system") {
                        android.graphics.drawable.GradientDrawable(
                            android.graphics.drawable.GradientDrawable.Orientation.TL_BR,
                            intArrayOf(Color.WHITE, Color.rgb(18, 58, 94))
                        ).apply {
                            shape = android.graphics.drawable.GradientDrawable.OVAL
                            setStroke((2 * density).toInt(), currentTheme.dividerColor)
                        }
                    } else {
                        android.graphics.drawable.GradientDrawable().apply {
                            shape = android.graphics.drawable.GradientDrawable.OVAL
                            setColor(color)
                            setStroke((2 * density).toInt(), currentTheme.dividerColor)
                        }
                    }
                    layoutParams = LayoutParams((44 * density).toInt(), (44 * density).toInt()).apply {
                        setMargins((8 * density).toInt(), (6 * density).toInt(), (8 * density).toInt(), (6 * density).toInt())
                    }
                    setOnClickListener {
                        onSelect(id)
                        popup.dismiss()
                    }
                })
            }
            panel.addView(row)
        }
        popup = PopupWindow(panel, LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT, true).apply {
            elevation = 12 * density
            isOutsideTouchable = true
        }
        suggestionBarContainer.post {
            val anchor = suggestionBarContainer.getChildAt(suggestionBarContainer.childCount - 1)
            if (anchor != null) popup.showAsDropDown(anchor, 0, 0)
        }
    }

    private fun showMenu(title: String, entries: List<*>, onSelect: (String) -> Unit) {
        val density = resources.displayMetrics.density
        lateinit var popup: PopupWindow
        val content = LinearLayout(context).apply {
            orientation = VERTICAL
            setPadding((8 * density).toInt(), (4 * density).toInt(), (8 * density).toInt(), (4 * density).toInt())
            setBackgroundColor(currentTheme.suggestionBarBackground)
        }
        content.addView(TextView(context).apply {
            text = title
            textSize = 15f
            setTextColor(currentTheme.secondaryText)
            setPadding((12 * density).toInt(), (8 * density).toInt(), (12 * density).toInt(), (8 * density).toInt())
        })
        entries.take(8).forEach { entry ->
            val value: String
            val label: String
            if (entry is Pair<*, *>) {
                value = entry.first.toString()
                label = entry.second.toString()
            } else {
                value = entry.toString()
                label = value
            }
            content.addView(TextView(context).apply {
                text = label
                textSize = 17f
                maxLines = 2
                ellipsize = android.text.TextUtils.TruncateAt.END
                setTextColor(currentTheme.primaryText)
                setPadding((12 * density).toInt(), (10 * density).toInt(), (12 * density).toInt(), (10 * density).toInt())
                setOnClickListener {
                    if (value.isNotEmpty() && value != "Clipboard is empty") onSelect(value)
                    popup.dismiss()
                }
            })
        }
        val scroll = ScrollView(context).apply { addView(content) }
        popup = PopupWindow(scroll, (resources.displayMetrics.widthPixels - 24 * density).toInt(), LayoutParams.WRAP_CONTENT, true).apply {
            elevation = 12 * density
            isOutsideTouchable = true
        }
        content.setOnClickListener { }
        // Keep the menu anchored to the toolbar control even when the device has
        // a tall navigation area or additional IME buttons.
        suggestionBarContainer.post {
            val index = if (title == "Clipboard") suggestionBarContainer.childCount - 2 else suggestionBarContainer.childCount - 1
            val anchor = suggestionBarContainer.getChildAt(index)
            if (anchor != null) popup.showAsDropDown(anchor, 0, 0)
        }
    }

    /**
     * Inner custom View responsible for rendering keys and handling touch events
     */
    private inner class KeyCanvasView(context: Context) : View(context) {

        private var layout: NativeLayout? = null
        private val keyBounds = mutableListOf<Pair<NativeKey, RectF>>()
        private var pressedKey: NativeKey? = null
        private var pressedRect: RectF? = null

        private val keyPaint = Paint(Paint.ANTI_ALIAS_FLAG)
        private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG)
        private val subTextPaint = Paint(Paint.ANTI_ALIAS_FLAG)
        private val globePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.STROKE }

        private val keyPreview = KeyPreviewPopup(context) { alternate ->
            onKeyAction(NativeKey(alternate, alternate, KeyType.CHARACTER, KeyAction.INSERT_TEXT))
        }
        private var harakatPopup: HarakatPopupView? = null
        private var isLongPressingHarakat = false
        private var isSelectingAlternate = false
        private var isRepeatingBackspace = false

        private val longPressHandler = Handler(Looper.getMainLooper())
        private var pendingLongPressKey: NativeKey? = null
        private val backspaceRepeat = object : Runnable {
            override fun run() {
                if (isRepeatingBackspace && pressedKey?.action == KeyAction.DELETE_BACKWARD) {
                    pressedKey?.let(onKeyAction)
                    longPressHandler.postDelayed(this, 65L)
                }
            }
        }

        init {
            textPaint.textSize = 28f * resources.displayMetrics.density
            textPaint.textAlign = Paint.Align.CENTER
            nastaliqTypeface?.let { textPaint.typeface = it }

            subTextPaint.textSize = 14f * resources.displayMetrics.density
            subTextPaint.textAlign = Paint.Align.CENTER
            nastaliqTypeface?.let { subTextPaint.typeface = it }

            harakatPopup = HarakatPopupView(context, nastaliqTypeface ?: Typeface.DEFAULT) { harakatChar ->
                val harakatKey = NativeKey(
                    label = harakatChar,
                    output = harakatChar,
                    type = KeyType.CHARACTER,
                    action = KeyAction.INSERT_TEXT
                )
                onKeyAction(harakatKey)
            }
        }

        fun setLayout(newLayout: NativeLayout) {
            this.layout = newLayout
            if (width > 0 && height > 0) {
                calculateKeyBounds(width, height)
            }
            requestLayout()
            invalidate()
        }

        fun applyTheme(theme: NativeTheme) {
            harakatPopup?.applyTheme(
                theme.suggestionBarBackground,
                theme.normalKeyBackground,
                theme.suggestionBarText,
                theme.actionKeyBackground
            )
            invalidate()
        }

        override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
            val width = MeasureSpec.getSize(widthMeasureSpec)
            val density = resources.displayMetrics.density
            val baseHeightDp = 220f * prefs.heightRatio
            val height = (baseHeightDp * density).toInt()
            setMeasuredDimension(width, height)
        }

        override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
            super.onSizeChanged(w, h, oldw, oldh)
            calculateKeyBounds(w, h)
        }

        private fun calculateKeyBounds(width: Int, height: Int) {
            keyBounds.clear()
            val currentLayout = layout ?: return
            val rows = currentLayout.rows
            if (rows.isEmpty()) return

            val density = resources.displayMetrics.density
            val spacing = prefs.keySpacing * density
            val rowHeight = (height - spacing * (rows.size + 1)) / rows.size

            var top = spacing
            for (row in rows) {
                val totalWeight = row.keys.sumOf { it.weight.toDouble() }.toFloat()
                val availableWidth = width - spacing * (row.keys.size + 1)
                var left = spacing

                for (key in row.keys) {
                    val keyWidth = availableWidth * (key.weight / totalWeight)
                    val rect = RectF(left, top, left + keyWidth, top + rowHeight)
                    keyBounds.add(key to rect)
                    left += keyWidth + spacing
                }
                top += rowHeight + spacing
            }
        }

        override fun onDraw(canvas: Canvas) {
            super.onDraw(canvas)
            canvas.drawColor(currentTheme.keyboardBackground)

            val radius = 12f * resources.displayMetrics.density

            for ((key, rect) in keyBounds) {
                val isPressed = (key == pressedKey)
                textPaint.typeface = if (key.label.containsArabicScript()) {
                    nastaliqTypeface ?: Typeface.DEFAULT
                } else {
                    Typeface.DEFAULT
                }
                subTextPaint.typeface = if (key.alternates.any { it.containsArabicScript() }) {
                    nastaliqTypeface ?: Typeface.DEFAULT
                } else {
                    Typeface.DEFAULT
                }

                val bgColor = when {
                    isPressed -> currentTheme.pressedKeyBackground
                    key.type == KeyType.CHARACTER -> currentTheme.normalKeyBackground
                    key.action == KeyAction.SUBMIT -> currentTheme.actionKeyBackground
                    else -> currentTheme.specialKeyBackground
                }

                val textColor = when {
                    key.action == KeyAction.SUBMIT -> currentTheme.actionKeyText
                    key.type == KeyType.CHARACTER -> currentTheme.normalKeyText
                    else -> currentTheme.specialKeyText
                }

                keyPaint.color = bgColor
                canvas.drawRoundRect(rect, radius, radius, keyPaint)

                textPaint.color = textColor
                textPaint.textSize = when (key.label) {
                    "ABC / بر" -> 12f * resources.displayMetrics.density
                    "#+=" -> 15f * resources.displayMetrics.density
                    "EN", "123" -> 16f * resources.displayMetrics.density
                    "space" -> 16f * resources.displayMetrics.density
                    else -> 28f * resources.displayMetrics.density
                }
                val textY = rect.centerY() - ((textPaint.descent() + textPaint.ascent()) / 2)
                if (key.action == KeyAction.SWITCH_KEYBOARD) {
                    drawGlobe(canvas, rect, textColor)
                } else {
                    canvas.drawText(key.label, rect.centerX(), textY, textPaint)
                }

                if (key.alternates.isNotEmpty()) {
                    subTextPaint.color = currentTheme.secondaryText
                    canvas.drawText(key.alternates.first(), rect.right - 14f, rect.top + 22f, subTextPaint)
                }
            }
        }

        private fun drawGlobe(canvas: Canvas, rect: RectF, color: Int) {
            val density = resources.displayMetrics.density
            val radius = minOf(rect.width(), rect.height()) * 0.22f
            val cx = rect.centerX()
            val cy = rect.centerY()
            globePaint.color = color
            globePaint.strokeWidth = 1.7f * density
            canvas.drawCircle(cx, cy, radius, globePaint)
            canvas.drawOval(RectF(cx - radius * 0.48f, cy - radius, cx + radius * 0.48f, cy + radius), globePaint)
            canvas.drawOval(RectF(cx - radius, cy - radius * 0.42f, cx + radius, cy + radius * 0.42f), globePaint)
        }

        override fun onTouchEvent(event: MotionEvent): Boolean {
            if (isSelectingAlternate) {
                if (keyPreview.isShowingAlternates()) {
                    keyPreview.handleDragMotion(event, this)
                } else if (event.actionMasked == MotionEvent.ACTION_UP || event.actionMasked == MotionEvent.ACTION_CANCEL) {
                    keyPreview.commitDefaultAlternate()
                }
                if (event.actionMasked == MotionEvent.ACTION_UP || event.actionMasked == MotionEvent.ACTION_CANCEL) {
                    isSelectingAlternate = false
                    pressedKey = null
                    pressedRect = null
                    invalidate()
                }
                return true
            }
            if (isLongPressingHarakat && harakatPopup?.isShowing() == true) {
                harakatPopup?.handleDragMotion(event, this)
                if (event.actionMasked == MotionEvent.ACTION_UP || event.actionMasked == MotionEvent.ACTION_CANCEL) {
                    isLongPressingHarakat = false
                    pressedKey = null
                    pressedRect = null
                    invalidate()
                }
                return true
            }

            when (event.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    val keyPair = findKeyAt(event.x, event.y)
                    if (keyPair != null) {
                        val key = keyPair.first
                        val rect = keyPair.second
                        pressedKey = key
                        pressedRect = rect
                        invalidate()

                        if (prefs.popupOnKeyPress && key.type == KeyType.CHARACTER) {
                            keyPreview.show(
                                this,
                                key.label,
                                rect.left.toInt(),
                                rect.top.toInt(),
                                rect.width().toInt(),
                                rect.height().toInt()
                            )
                        }

                        pendingLongPressKey = key
                        longPressHandler.postDelayed({ onLongPressTriggered(key, rect) }, 350)
                    }
                }
                MotionEvent.ACTION_MOVE -> {
                    if (isLongPressingHarakat) {
                        harakatPopup?.handleDragMotion(event, this)
                    }
                }
                MotionEvent.ACTION_UP -> {
                    val hadRepeatingBackspace = isRepeatingBackspace
                    longPressHandler.removeCallbacksAndMessages(null)
                    keyPreview.dismiss()

                    val currentKey = pressedKey
                    if (!isLongPressingHarakat && !hadRepeatingBackspace && currentKey != null) {
                        if (currentKey.action == KeyAction.OPEN_HARAKAT) {
                            val fatha = "\u064E"
                            onKeyAction(NativeKey(fatha, fatha, KeyType.CHARACTER, KeyAction.INSERT_TEXT))
                        } else {
                            onKeyAction(currentKey)
                        }
                    }
                    isLongPressingHarakat = false
                    isRepeatingBackspace = false
                    pressedKey = null
                    pressedRect = null
                    invalidate()
                }
                MotionEvent.ACTION_CANCEL -> {
                    longPressHandler.removeCallbacksAndMessages(null)
                    keyPreview.dismiss()
                    harakatPopup?.dismiss()
                    isLongPressingHarakat = false
                    isSelectingAlternate = false
                    isRepeatingBackspace = false
                    pressedKey = null
                    pressedRect = null
                    invalidate()
                }
            }
            return true
        }

        private fun onLongPressTriggered(key: NativeKey?, rect: RectF?) {
            if (key == null) return

            if (key.action == KeyAction.DELETE_BACKWARD) {
                isRepeatingBackspace = true
                onKeyAction(key)
                longPressHandler.postDelayed(backspaceRepeat, 65L)
            } else if (key.type == KeyType.HARAKAT) {
                isLongPressingHarakat = true
                keyPreview.dismiss()
                harakatPopup?.show(
                    this,
                    rect?.top?.toInt() ?: 0,
                    currentTheme.suggestionBarBackground,
                    currentTheme.normalKeyBackground,
                    currentTheme.suggestionBarText,
                    currentTheme.actionKeyBackground
                )
            } else if (key.alternates.isNotEmpty()) {
                isSelectingAlternate = true
                keyPreview.dismiss()
                keyPreview.showAlternates(this, key.alternates, rect?.left?.toInt() ?: 0, rect?.top?.toInt() ?: 0, rect?.width()?.toInt() ?: 0)
            }
        }

        private fun findKeyAt(x: Float, y: Float): Pair<NativeKey, RectF>? {
            return keyBounds.firstOrNull { it.second.contains(x, y) }
        }
    }
}
