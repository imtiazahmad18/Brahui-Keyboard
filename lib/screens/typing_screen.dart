import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';

class TypingScreen extends StatelessWidget {
  const TypingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsService = context.watch<SettingsService>();
    final settings = settingsService.settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Typing Preferences'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              'Input & Prediction',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.spellcheck),
                  title: const Text('Word Suggestions'),
                  subtitle: const Text('Show offline dictionary suggestions for Brahui & English'),
                  value: settings.suggestionsEnabled,
                  onChanged: (val) {
                    settingsService.updateSettings(
                      settings.copyWith(suggestionsEnabled: val),
                    );
                  },
                ),
                const Divider(height: 1, indent: 64),
                SwitchListTile(
                  secondary: const Icon(Icons.auto_fix_high),
                  title: const Text('Autocorrect'),
                  subtitle: const Text('Conservatively correct common typing errors (disabled in passwords)'),
                  value: settings.autocorrectEnabled,
                  onChanged: (val) {
                    settingsService.updateSettings(
                      settings.copyWith(autocorrectEnabled: val),
                    );
                  },
                ),
                const Divider(height: 1, indent: 64),
                SwitchListTile(
                  secondary: const Icon(Icons.content_paste),
                  title: const Text('Clipboard Suggestions'),
                  subtitle: const Text('Show recently copied text in suggestions bar for quick paste'),
                  value: settings.clipboardHistory,
                  onChanged: (val) {
                    settingsService.updateSettings(
                      settings.copyWith(clipboardHistory: val),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              'Feedback & Visuals',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.vibration),
                  title: const Text('Haptic Feedback (Vibration)'),
                  subtitle: const Text('Vibrate gently when pressing keys'),
                  value: settings.hapticFeedback,
                  onChanged: (val) {
                    settingsService.updateSettings(
                      settings.copyWith(hapticFeedback: val),
                    );
                  },
                ),
                const Divider(height: 1, indent: 64),
                SwitchListTile(
                  secondary: const Icon(Icons.volume_up_outlined),
                  title: const Text('Key Sound'),
                  subtitle: const Text('Play gentle click sound when typing'),
                  value: settings.soundOnKeyPress,
                  onChanged: (val) {
                    settingsService.updateSettings(
                      settings.copyWith(soundOnKeyPress: val),
                    );
                  },
                ),
                const Divider(height: 1, indent: 64),
                SwitchListTile(
                  secondary: const Icon(Icons.call_to_action_outlined),
                  title: const Text('Key Popup Preview'),
                  subtitle: const Text('Show magnified bubble above pressed key'),
                  value: settings.popupOnKeyPress,
                  onChanged: (val) {
                    settingsService.updateSettings(
                      settings.copyWith(popupOnKeyPress: val),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
