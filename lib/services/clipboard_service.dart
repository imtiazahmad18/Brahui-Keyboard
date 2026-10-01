import 'package:shared_preferences/shared_preferences.dart';

/// Local clipboard history. Never written to a server.
class ClipboardService {
  static const _key = 'clipboard_history_items';
  static const _defaultMax = 20;

  Future<List<String>> load({int maxItems = _defaultMax}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final items = prefs.getStringList(_key) ?? [];
      return items.take(maxItems).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> add(String text, {int maxItems = _defaultMax}) async {
    final value = text.trim();
    if (value.isEmpty || _looksSensitive(value)) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final items = prefs.getStringList(_key) ?? [];
      items.remove(value);
      items.insert(0, value);
      await prefs.setStringList(_key, items.take(maxItems).toList());
    } catch (_) {}
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }

  bool _looksSensitive(String text) {
    final compact = text.replaceAll(RegExp(r'\s'), '');
    if (RegExp(r'^\d{13,19}$').hasMatch(compact)) return true;
    if (text.length > 256) return true;
    return false;
  }
}
