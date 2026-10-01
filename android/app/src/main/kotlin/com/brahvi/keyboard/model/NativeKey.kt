package com.brahvi.keyboard.model

enum class KeyType {
    CHARACTER,
    SHIFT,
    BACKSPACE,
    ENTER,
    SPACE,
    MODE,
    LANGUAGE,
    HARAKAT,
    CLIPBOARD,
    NAVIGATION,
    EMOJI
}

enum class KeyAction {
    INSERT_TEXT,
    DELETE_BACKWARD,
    SUBMIT,
    INSERT_SPACE,
    SWITCH_LAYOUT,
    SWITCH_LANGUAGE,
    RESTORE_PREVIOUS_LAYOUT,
    OPEN_HARAKAT,
    OPEN_CLIPBOARD,
    OPEN_EMOJI,
    SWITCH_KEYBOARD,
    NAVIGATE
}

data class NativeKey(
    val label: String,
    val output: String?,
    val type: KeyType,
    val action: KeyAction,
    val target: String? = null,
    val weight: Float = 1.0f,
    val active: Boolean = false,
    val alternates: List<String> = emptyList()
)

data class NativeRow(
    val keys: List<NativeKey>
)

data class NativeLayout(
    val id: String,
    val name: String,
    val language: String,
    val direction: String,
    val rows: List<NativeRow>
) {
    val isRtl: Boolean get() = direction.equals("rtl", ignoreCase = true)
}
