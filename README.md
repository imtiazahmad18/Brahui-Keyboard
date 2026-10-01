# Brahui Keyboard (براہوئی کیبورڈ)

A production-quality, privacy-first, system-wide keyboard application for **Android** and **iOS** designed specifically for the Brahui language, paired with a companion settings and customization application built in **Flutter**.

Application ID: `com.brahvi.keyboard`

---

## 1. Project Overview

Brahui (*Bráhui* / براہوئی) is a language primarily spoken in Balochistan . It uses a specialized Arabic-Urdu-derived alphabet featuring the unique voiceless alveolar lateral fricative character:

> **ڷ** — Unicode `U+06B7` (*Arabic Letter Lam with Three Dots Above*)

This keyboard app provides a real, system-wide input method across all apps on Android and iOS devices, with:
- **Full 39-Character Brahui Alphabet** with native support for `ڷ` (U+06B7).
- **Urdu-style RTL Keyboard Layout** with responsive sizing, rounded keys, and customizable height/spacing.
- **English QWERTY Layout** with seamless one-tap switching.
- **Dedicated Numbers & Symbols (123) Keyboard** with intelligent previous-layout memory.
- **Harakat Diacritics Panel** (Zabar, Zer, Pesh, Tashdeed, Jazm, Khari Zabar, etc.) with Unicode combining mark safety.
- **Long-Press Alternates** with drag-and-release selection.
- **Offline-First Word Suggestions & Autocorrect** for Brahui and English (zero data transmission).
- **8 Distinct Themes** (Light/White, Navy Dark, Pure Black AMOLED, Emerald Green, Desert Olive, Warm Sand, Gboard Light, Gboard Dark).
- **Haptic Vibration, Key Sounds, and Pressed Key Previews**.
- **Companion Flutter Settings Application** with live interactive keyboard test sandbox.

---

## 2. Architecture

```text
┌─────────────────────────────────────────────────────────────────┐
│                    Brahui Keyboard Project                      │
├────────────────────────────────┬────────────────────────────────┤
│       Flutter Companion App    │    Native Platform Engines     │
│       (lib/ & screens/)        │   (android/ & ios/ extensions) │
├────────────────────────────────┴────────────────────────────────┤
│  • Settings & Live Sandbox      │  • Android InputMethodService  │
│  • Theme Selection & Customizer │  • iOS UIInputViewController   │
│  • MethodChannel Bridge        │  • Grapheme-safe Backspace     │
│  • Offline Trie Suggestions     │  • Native Touch & Haptics      │
├─────────────────────────────────────────────────────────────────┤
│                     Shared Configuration                        │
│                           (shared/)                             │
│  • brahvi_characters.json (Unicode specifications)             │
│  • harakat.json (Arabic/Urdu diacritics metadata)               │
│  • themes.json (Universal color schemes & hex tokens)          │
│  • layouts/*.json (Keyboards for Brahui, English, Numbers)      │
│  • dictionaries/*.json (Offline word frequencies)              │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. Brahui Character Set

The keyboard strictly supports the standard Brahui Arabic-script character set:

```text
ا ب پ ت ٹ ث ج چ ح خ د ڈ ذ ر ڑ ز ژ س ش ص ض ط ظ ع غ ف ق ک گ ل ڷ م ن و ہ ھ ء ی ے
```

### The `ڷ` (U+06B7) Character
- Unicode point: `U+06B7`
- UTF-8: `0xDB 0xB7`
- Name: `ARABIC LETTER LAM WITH THREE DOTS ABOVE`
- Dedicated key placed on Row 2 next to `ل`, and also accessible via long-press on `ل`.

---

## 4. Android Native Implementation

- **Service**: `BrahviInputMethodService` extending `android.inputmethodservice.InputMethodService`.
- **View**: `NativeKeyboardView` rendering custom rounded drawables and responding to multi-touch and long-press popups.
- **Security**:
  - **No Internet Permission**: The `android.permission.INTERNET` flag is completely absent from `AndroidManifest.xml`.
  - **Password Field Detection**: Automatically switches off suggestions, dictionaries, and autocorrect in sensitive input fields (`TYPE_TEXT_VARIATION_PASSWORD`).
- **Configuration**:
  - `AndroidManifest.xml` declares `BIND_INPUT_METHOD`.
  - `res/xml/method.xml` defines Brahui and English subtypes.

---

## 5. iOS Keyboard Extension Implementation

- **Extension**: `KeyboardViewController` extending `UIInputViewController`.
- **Target**: `KeyboardExtension` bundle ID `com.brahvi.keyboard.KeyboardExtension`.
- **Inter-process Sharing**: Shared `UserDefaults` via App Group `group.com.brahvi.keyboard`.
- **Apple Standard Compliance**:
  - Integrates `needsInputModeSwitchKey` and globe button for cycling iOS keyboards.
  - Inserts text using `textDocumentProxy.insertText(...)`.
  - Performs deletion via `textDocumentProxy.deleteBackward()`.
  - Documented Full Access boundaries.

---

## 6. How to Enable the Keyboard

### On Android
1. Open **Settings** → **System** → **Languages & input** (or **General Management** → **Keyboard list and default**).
2. Tap **Manage on-screen keyboards** (or **On-screen keyboard**).
3. Toggle **Brahui Keyboard** to **ON**.
4. Tap any input field (e.g. Messages, WhatsApp, Notes).
5. Tap the keyboard selector icon at the bottom-right of navigation bar or swipe down notifications and choose **Brahui Keyboard**.

### On iOS (iPhone / iPad)
1. Open iOS **Settings** → **General** → **Keyboard** → **Keyboards**.
2. Tap **Add New Keyboard...**.
3. Under *Third-Party Keyboards*, select **Brahui Keyboard**.
4. (Optional) Tap **Brahui Keyboard** and toggle **Allow Full Access** if clipboard synchronization is desired.
5. In any app, tap or long-press the **Globe (🌐)** icon to select Brahui Keyboard.

---

## 7. Development & Building

### Prerequisites
- Flutter SDK (3.19+ / 3.22+)
- Android Studio / Android SDK (API 34)
- Xcode 15+ (for iOS build)

### Running the Companion Settings App
```bash
# Fetch Flutter packages
flutter pub get

# Run on connected Android or iOS device
flutter run
```

### Building Android APK / App Bundle
```bash
# Build release APK
flutter build apk --release

# Build Google Play App Bundle (AAB)
flutter build appbundle --release
```

### Building iOS Extension
```bash
flutter build ios --release
# Open ios/Runner.xcworkspace in Xcode, select your Team and build KeyboardExtension target.
```

---

## 8. Privacy Model

Brahui Keyboard is built upon a **zero-telemetry, offline-first** philosophy:
1. **Zero Network Calls**: No typed keystrokes, personal words, or device identifiers are ever recorded or transmitted.
2. **Local Dictionaries**: Frequency trees are bundled directly within the app assets and evaluated purely in RAM.
3. **No Keylogging**: Passwords, card numbers, and PIN codes bypass the suggestion pipeline automatically.

---

## 9. Known Platform Limitations (iOS)

- **Apple Secure Input**: Apple automatically switches to the iOS default keyboard when entering passwords in system security dialogs.
- **Full Access Requirement**: Third-party iOS keyboard extensions are sandboxed by default. Reading shared pasteboard requires user authorization under "Allow Full Access".
- **Memory Ceiling**: iOS allocates strict memory limits (~30MB–48MB) for keyboard extensions. The native extension code is kept lean with minimal dependencies.

---

## 10. License

Apache License 2.0. Open-source contribution to the Brahui language digital preservation initiative.
