import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_model.dart';
import '../models/theme_config.dart';
import '../models/harakat_model.dart';
import '../models/keyboard_layout.dart';
import 'platform_channel_service.dart';

class SettingsService extends ChangeNotifier with WidgetsBindingObserver {
  KeyboardSettings _settings = KeyboardSettings();
  List<ThemeConfig> _themes = [];
  List<HarakatItem> _harakatList = [];
  final Map<String, KeyboardLayout> _layoutCache = {};
  bool _isLoading = true;

  KeyboardSettings get settings => _settings;
  List<ThemeConfig> get themes => _themes;
  List<HarakatItem> get harakatList => _harakatList;
  bool get isLoading => _isLoading;

  ThemeConfig get currentTheme {
    if (_settings.currentThemeId == 'system' && _themes.isNotEmpty) {
      final isDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
      final systemThemeId = isDark ? 'gboard_dark' : 'light_white';
      return _themes.firstWhere(
        (theme) => theme.id == systemThemeId,
        orElse: () => _themes.first,
      );
    }
    return _themes.firstWhere(
      (t) => t.id == _settings.currentThemeId,
      orElse: () => _themes.isNotEmpty
          ? _themes.first
          : const ThemeConfig(
              id: 'light_white',
              name: 'Light / White',
              isDark: false,
              keyboardBackground: Color(0xFFF1F3F4),
              normalKeyBackground: Color(0xFFFFFFFF),
              normalKeyText: Color(0xFF202124),
              pressedKeyBackground: Color(0xFFE8EAED),
              actionKeyBackground: Color(0xFF1A73E8),
              actionKeyText: Color(0xFFFFFFFF),
              specialKeyBackground: Color(0xFFE0E3E7),
              specialKeyText: Color(0xFF3C4043),
              primaryText: Color(0xFF202124),
              secondaryText: Color(0xFF5F6368),
              accentColor: Color(0xFF1A73E8),
              suggestionBarBackground: Color(0xFFE8EAED),
              suggestionBarText: Color(0xFF202124),
              dividerColor: Color(0xFFDADCE0),
            ),
    );
  }

  Future<void> initialize() async {
    WidgetsBinding.instance.addObserver(this);
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Load themes from shared/config/themes.json
      final themesString = await rootBundle.loadString('shared/config/themes.json');
      final themesData = json.decode(themesString);
      if (themesData['themes'] is List) {
        _themes = (themesData['themes'] as List)
            .map((e) => ThemeConfig.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // 2. Load Harakat from shared/config/harakat.json
      final harakatString = await rootBundle.loadString('shared/config/harakat.json');
      final harakatData = json.decode(harakatString);
      if (harakatData['harakat'] is List) {
        _harakatList = (harakatData['harakat'] as List)
            .map((e) => HarakatItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // 3. Load SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      const migratedKey = 'systemThemeDefaultsMigratedV1';
      final alreadyMigrated = prefs.getBool(migratedKey) ?? false;
      final savedThemeId = prefs.getString('currentThemeId');
      final savedHeightRatio = prefs.getDouble('keyboardHeightRatio');
      final savedKeySpacing = prefs.getDouble('keySpacing');
      const sizingDefaultsMigratedKey = 'keyboardSizingDefaultsMigratedV2';
      final sizingDefaultsMigrated = prefs.getBool(sizingDefaultsMigratedKey) ?? false;
      final themeId = !alreadyMigrated && (savedThemeId == null || savedThemeId == 'navy_dark')
          ? 'system'
          : (savedThemeId ?? 'system');
      final heightRatio = !sizingDefaultsMigrated && (savedHeightRatio == null || savedHeightRatio == 0.9)
          ? 0.96
          : (savedHeightRatio ?? 0.96);
      final keySpacing = !sizingDefaultsMigrated && (savedKeySpacing == null || savedKeySpacing == 4.0)
          ? 5.0
          : (savedKeySpacing ?? 5.0);
      await prefs.setString('currentThemeId', themeId);
      await prefs.setDouble('keyboardHeightRatio', heightRatio);
      await prefs.setDouble('keySpacing', keySpacing);
      if (!alreadyMigrated) await prefs.setBool(migratedKey, true);
      if (!sizingDefaultsMigrated) await prefs.setBool(sizingDefaultsMigratedKey, true);
      _settings = KeyboardSettings(
        currentThemeId: themeId,
        keyboardHeightRatio: heightRatio,
        keySizeRatio: prefs.getDouble('keySizeRatio') ?? 1.0,
        keySpacing: keySpacing,
        suggestionsEnabled: prefs.getBool('suggestionsEnabled') ?? true,
        autocorrectEnabled: prefs.getBool('autocorrectEnabled') ?? false,
        hapticFeedback: prefs.getBool('hapticFeedback') ?? true,
        soundOnKeyPress: prefs.getBool('soundOnKeyPress') ?? false,
        popupOnKeyPress: prefs.getBool('popupOnKeyPress') ?? true,
        clipboardHistory: prefs.getBool('clipboardHistory') ?? true,
        defaultLanguage: prefs.getString('defaultLanguage') ?? 'brahvi',
        phoneticLayout: prefs.getBool('phoneticLayout') ?? true,
      );

      // Sync with native platform
      await PlatformChannelService.syncSettings(_settings);
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing SettingsService: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void didChangePlatformBrightness() {
    if (_settings.currentThemeId == 'system') notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> updateSettings(KeyboardSettings newSettings) async {
    _settings = newSettings;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentThemeId', _settings.currentThemeId);
      await prefs.setDouble('keyboardHeightRatio', _settings.keyboardHeightRatio);
      await prefs.setDouble('keySizeRatio', _settings.keySizeRatio);
      await prefs.setDouble('keySpacing', _settings.keySpacing);
      await prefs.setBool('suggestionsEnabled', _settings.suggestionsEnabled);
      await prefs.setBool('autocorrectEnabled', _settings.autocorrectEnabled);
      await prefs.setBool('hapticFeedback', _settings.hapticFeedback);
      await prefs.setBool('soundOnKeyPress', _settings.soundOnKeyPress);
      await prefs.setBool('popupOnKeyPress', _settings.popupOnKeyPress);
      await prefs.setBool('clipboardHistory', _settings.clipboardHistory);
      await prefs.setString('defaultLanguage', _settings.defaultLanguage);
      await prefs.setBool('phoneticLayout', _settings.phoneticLayout);

      // Synchronize with native platform
      await PlatformChannelService.syncSettings(_settings);
    } catch (e) {
      if (kDebugMode) {
        print('Error persisting settings: $e');
      }
    }
  }

  Future<void> setTheme(String themeId) async {
    await updateSettings(_settings.copyWith(currentThemeId: themeId));
  }

  Future<KeyboardLayout> loadLayout(String layoutId) async {
    if (_layoutCache.containsKey(layoutId)) {
      return _layoutCache[layoutId]!;
    }

    final path = 'shared/config/layouts/$layoutId.json';
    final layoutString = await rootBundle.loadString(path);
    final layoutData = json.decode(layoutString);
    final layout = KeyboardLayout.fromJson(layoutData as Map<String, dynamic>);
    _layoutCache[layoutId] = layout;
    return layout;
  }
}
