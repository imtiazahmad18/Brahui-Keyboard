import 'package:flutter/services.dart';
import '../models/settings_model.dart';

class PlatformChannelService {
  static const MethodChannel _channel = MethodChannel('com.brahvi.keyboard/settings');

  /// Synchronize settings to native platform (Android SharedPreferences / iOS App Group UserDefaults).
  static Future<bool> syncSettings(KeyboardSettings settings) async {
    try {
      final result = await _channel.invokeMethod<bool>('syncSettings', settings.toMap());
      return result ?? true;
    } on PlatformException catch (_) {
      // In web/desktop or test environment fallback gracefully
      return false;
    }
  }

  /// Check if the Brahvi keyboard is enabled in system settings.
  static Future<bool> isKeyboardEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isKeyboardEnabled');
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Check if the Brahvi keyboard is currently selected as active IME.
  static Future<bool> isKeyboardSelected() async {
    try {
      final result = await _channel.invokeMethod<bool>('isKeyboardSelected');
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Open system input method settings to allow enabling the keyboard.
  static Future<void> openKeyboardSettings() async {
    try {
      await _channel.invokeMethod('openKeyboardSettings');
    } on PlatformException catch (_) {
      // Fallback
    }
  }

  /// Open system input method picker so user can select Brahvi Keyboard.
  static Future<void> showInputMethodPicker() async {
    try {
      await _channel.invokeMethod('showInputMethodPicker');
    } on PlatformException catch (_) {
      // Fallback
    }
  }
}
