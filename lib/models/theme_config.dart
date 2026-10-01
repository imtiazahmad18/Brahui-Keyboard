import 'package:flutter/material.dart';

class ThemeConfig {
  final String id;
  final String name;
  final bool isDark;
  final Color keyboardBackground;
  final Color normalKeyBackground;
  final Color normalKeyText;
  final Color pressedKeyBackground;
  final Color actionKeyBackground;
  final Color actionKeyText;
  final Color specialKeyBackground;
  final Color specialKeyText;
  final Color primaryText;
  final Color secondaryText;
  final Color accentColor;
  final Color suggestionBarBackground;
  final Color suggestionBarText;
  final Color dividerColor;

  const ThemeConfig({
    required this.id,
    required this.name,
    required this.isDark,
    required this.keyboardBackground,
    required this.normalKeyBackground,
    required this.normalKeyText,
    required this.pressedKeyBackground,
    required this.actionKeyBackground,
    required this.actionKeyText,
    required this.specialKeyBackground,
    required this.specialKeyText,
    required this.primaryText,
    required this.secondaryText,
    required this.accentColor,
    required this.suggestionBarBackground,
    required this.suggestionBarText,
    required this.dividerColor,
  });

  static Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  factory ThemeConfig.fromJson(Map<String, dynamic> json) {
    return ThemeConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      isDark: json['isDark'] as bool? ?? false,
      keyboardBackground: _hexToColor(json['keyboardBackground'] as String),
      normalKeyBackground: _hexToColor(json['normalKeyBackground'] as String),
      normalKeyText: _hexToColor(json['normalKeyText'] as String),
      pressedKeyBackground: _hexToColor(json['pressedKeyBackground'] as String),
      actionKeyBackground: _hexToColor(json['actionKeyBackground'] as String),
      actionKeyText: _hexToColor(json['actionKeyText'] as String),
      specialKeyBackground: _hexToColor(json['specialKeyBackground'] as String),
      specialKeyText: _hexToColor(json['specialKeyText'] as String),
      primaryText: _hexToColor(json['primaryText'] as String),
      secondaryText: _hexToColor(json['secondaryText'] as String),
      accentColor: _hexToColor(json['accentColor'] as String),
      suggestionBarBackground: _hexToColor(json['suggestionBarBackground'] as String),
      suggestionBarText: _hexToColor(json['suggestionBarText'] as String),
      dividerColor: _hexToColor(json['dividerColor'] as String),
    );
  }
}
