class KeyboardSettings {
  String currentThemeId;
  double keyboardHeightRatio;
  double keySizeRatio;
  double keySpacing;
  bool suggestionsEnabled;
  bool autocorrectEnabled;
  bool hapticFeedback;
  bool soundOnKeyPress;
  bool popupOnKeyPress;
  bool clipboardHistory;
  int clipboardMaxItems;
  String defaultLanguage;
  bool phoneticLayout;
  String themeMode;

  KeyboardSettings({
    this.currentThemeId = 'system',
    this.keyboardHeightRatio = 0.96,
    this.keySizeRatio = 1.0,
    this.keySpacing = 5.0,
    this.suggestionsEnabled = true,
    this.autocorrectEnabled = false,
    this.hapticFeedback = true,
    this.soundOnKeyPress = false,
    this.popupOnKeyPress = true,
    this.clipboardHistory = true,
    this.clipboardMaxItems = 20,
    this.defaultLanguage = 'brahvi',
    this.phoneticLayout = true,
    this.themeMode = 'system',
  });

  factory KeyboardSettings.fromMap(Map<String, dynamic> map) {
    return KeyboardSettings(
      currentThemeId: map['currentThemeId'] as String? ?? 'system',
      keyboardHeightRatio: (map['keyboardHeightRatio'] as num?)?.toDouble() ?? 0.96,
      keySizeRatio: (map['keySizeRatio'] as num?)?.toDouble() ?? 1.0,
      keySpacing: (map['keySpacing'] as num?)?.toDouble() ?? 5.0,
      suggestionsEnabled: map['suggestionsEnabled'] as bool? ?? true,
      autocorrectEnabled: map['autocorrectEnabled'] as bool? ?? false,
      hapticFeedback: map['hapticFeedback'] as bool? ?? true,
      soundOnKeyPress: map['soundOnKeyPress'] as bool? ?? false,
      popupOnKeyPress: map['popupOnKeyPress'] as bool? ?? true,
      clipboardHistory: map['clipboardHistory'] as bool? ?? true,
      clipboardMaxItems: (map['clipboardMaxItems'] as num?)?.toInt() ?? 20,
      defaultLanguage: map['defaultLanguage'] as String? ?? 'brahvi',
      phoneticLayout: map['phoneticLayout'] as bool? ?? true,
      themeMode: map['themeMode'] as String? ?? 'system',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currentThemeId': currentThemeId,
      'keyboardHeightRatio': keyboardHeightRatio,
      'keySizeRatio': keySizeRatio,
      'keySpacing': keySpacing,
      'suggestionsEnabled': suggestionsEnabled,
      'autocorrectEnabled': autocorrectEnabled,
      'hapticFeedback': hapticFeedback,
      'soundOnKeyPress': soundOnKeyPress,
      'popupOnKeyPress': popupOnKeyPress,
      'clipboardHistory': clipboardHistory,
      'clipboardMaxItems': clipboardMaxItems,
      'defaultLanguage': defaultLanguage,
      'phoneticLayout': phoneticLayout,
      'themeMode': themeMode,
    };
  }

  KeyboardSettings copyWith({
    String? currentThemeId,
    double? keyboardHeightRatio,
    double? keySizeRatio,
    double? keySpacing,
    bool? suggestionsEnabled,
    bool? autocorrectEnabled,
    bool? hapticFeedback,
    bool? soundOnKeyPress,
    bool? popupOnKeyPress,
    bool? clipboardHistory,
    int? clipboardMaxItems,
    String? defaultLanguage,
    bool? phoneticLayout,
    String? themeMode,
  }) {
    return KeyboardSettings(
      currentThemeId: currentThemeId ?? this.currentThemeId,
      keyboardHeightRatio: keyboardHeightRatio ?? this.keyboardHeightRatio,
      keySizeRatio: keySizeRatio ?? this.keySizeRatio,
      keySpacing: keySpacing ?? this.keySpacing,
      suggestionsEnabled: suggestionsEnabled ?? this.suggestionsEnabled,
      autocorrectEnabled: autocorrectEnabled ?? this.autocorrectEnabled,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      soundOnKeyPress: soundOnKeyPress ?? this.soundOnKeyPress,
      popupOnKeyPress: popupOnKeyPress ?? this.popupOnKeyPress,
      clipboardHistory: clipboardHistory ?? this.clipboardHistory,
      clipboardMaxItems: clipboardMaxItems ?? this.clipboardMaxItems,
      defaultLanguage: defaultLanguage ?? this.defaultLanguage,
      phoneticLayout: phoneticLayout ?? this.phoneticLayout,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}
