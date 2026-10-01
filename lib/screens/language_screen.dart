import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsService = context.watch<SettingsService>();
    final settings = settingsService.settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Languages & Layouts'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              'Default Keyboard Language',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Card(
            child: Column(
              children: [
                RadioListTile<String>(
                  title: const Text('Brahui (براہوئی)', style: TextStyle(fontFamily: 'NooriNastaliq')),
                  subtitle: const Text('RTL Arabic-script with special ڷ (U+06B7) character', style: TextStyle(fontFamily: 'NooriNastaliq')),
                  value: 'brahvi',
                  groupValue: settings.defaultLanguage,
                  onChanged: (val) {
                    if (val != null) {
                      settingsService.updateSettings(
                        settings.copyWith(defaultLanguage: val),
                      );
                    }
                  },
                ),
                const Divider(height: 1),
                RadioListTile<String>(
                  title: const Text('English (US)'),
                  subtitle: const Text('QWERTY Latin keys; hold letters for Urdu and Brahui characters'),
                  value: 'english',
                  groupValue: settings.defaultLanguage,
                  onChanged: (val) {
                    if (val != null) {
                      settingsService.updateSettings(
                        settings.copyWith(defaultLanguage: val),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              'Brahui Layout Style',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Card(
            child: Column(
              children: [
                RadioListTile<bool>(
                  title: const Text('Urdu-style RTL (Standard)'),
                  subtitle: const Text('Natural keyboard layout familiar to Urdu/Brahui speakers with dedicated ڷ key', style: TextStyle(fontFamily: 'NooriNastaliq')),
                  value: false,
                  groupValue: settings.phoneticLayout,
                  onChanged: (val) {
                    if (val != null) {
                      settingsService.updateSettings(
                        settings.copyWith(phoneticLayout: val),
                      );
                    }
                  },
                ),
                const Divider(height: 1),
                RadioListTile<bool>(
                  title: const Text('Phonetic Layout'),
                  subtitle: const Text('Keys arranged corresponding to English phonetic sounds'),
                  value: true,
                  groupValue: settings.phoneticLayout,
                  onChanged: (val) {
                    if (val != null) {
                      settingsService.updateSettings(
                        settings.copyWith(phoneticLayout: val),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Character Set Info Card
          Card(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified, color: const Color(0xFF5CB4E8)),
                      SizedBox(width: 8),
                      Text(
                        'Full 39-Character Brahui Alphabet Supported',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'ا ب پ ت ٹ ث ج چ ح خ د ڈ ذ ر ڑ ز ژ س ش ص ض ط ظ ع غ ف ق ک گ ل ڷ م ن و ہ ھ ء ی ے',
                    style: TextStyle(
                      fontFamily: 'NooriNastaliq',
                      fontSize: 16,
                      height: 1.8,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
