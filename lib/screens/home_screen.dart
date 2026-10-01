import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../services/platform_channel_service.dart';
import '../widgets/setting_tile.dart';
import 'appearance_screen.dart';
import 'typing_screen.dart';
import 'language_screen.dart';
import 'about_screen.dart';
import 'help_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isKeyboardEnabled = false;
  bool _isKeyboardSelected = false;
  bool _isCheckingStatus = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() => _isCheckingStatus = true);
    final enabled = await PlatformChannelService.isKeyboardEnabled();
    final selected = await PlatformChannelService.isKeyboardSelected();
    if (mounted) {
      setState(() {
        _isKeyboardEnabled = enabled;
        _isKeyboardSelected = selected;
        _isCheckingStatus = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsService = context.watch<SettingsService>();
    final settings = settingsService.settings;
    final currentTheme = settingsService.currentTheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/brahui_keyboard_logo.png',
                width: 38,
                height: 38,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Brahui Keyboard',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Check Status',
            onPressed: _checkStatus,
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpScreen()),
              );
            },
          ),
        ],
      ),
      body: settingsService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Keyboard Activation Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isKeyboardSelected
                                  ? Icons.check_circle
                                  : (_isKeyboardEnabled ? Icons.warning_amber_rounded : Icons.info_outline),
                              color: _isKeyboardSelected
                                  ? Colors.green
                                  : (_isKeyboardEnabled ? Colors.orange : const Color(0xFF5CB4E8)),
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isKeyboardSelected
                                        ? 'Brahui Keyboard is Active'
                                        : (_isKeyboardEnabled
                                            ? 'Keyboard Enabled (Not Selected)'
                                            : 'Setup Brahui Keyboard'),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    _isKeyboardSelected
                                        ? 'Ready to type in any app system-wide.'
                                        : (_isKeyboardEnabled
                                            ? 'Tap to select Brahui as your current input method.'
                                            : 'Enable Brahui in system keyboard settings.'),
                                    style: TextStyle(
                                      color: Theme.of(context).textTheme.bodySmall?.color,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            if (!_isKeyboardEnabled)
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await PlatformChannelService.openKeyboardSettings();
                                    _checkStatus();
                                  },
                                  icon: const Icon(Icons.settings),
                                  label: const Text('1. Enable in Settings'),
                                ),
                              ),
                            if (!_isKeyboardEnabled) const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () async {
                                  await PlatformChannelService.showInputMethodPicker();
                                  _checkStatus();
                                },
                                icon: const Icon(Icons.keyboard),
                                label: Text(_isKeyboardSelected ? 'Switch Keyboard' : '2. Select Keyboard'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Quick Status / Overviews
                Card(
                  child: Column(
                    children: [
                      SettingTile(
                        icon: Icons.palette_outlined,
                        title: 'Theme & Appearance',
                        subtitle: 'Current: ${currentTheme.name}',
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AppearanceScreen()),
                          );
                        },
                      ),
                      const Divider(height: 1, indent: 64),
                      SettingTile(
                        icon: Icons.keyboard_alt_outlined,
                        title: 'Typing Preferences',
                        subtitle: 'Suggestions, autocorrect, haptic feedback',
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TypingScreen()),
                          );
                        },
                      ),
                      const Divider(height: 1, indent: 64),
                      SettingTile(
                        icon: Icons.language,
                        title: 'Languages & Layouts',
                        subtitle: 'Default: ${settings.defaultLanguage.toUpperCase()} (Brahui / English)',
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LanguageScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Quick Toggles Card
                const Padding(
                  padding: EdgeInsets.only(left: 8, bottom: 8),
                  child: Text(
                    'Quick Preferences',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: const Icon(Icons.vibration),
                        title: const Text('Haptic Feedback'),
                        subtitle: const Text('Vibrate gently on key press'),
                        value: settings.hapticFeedback,
                        onChanged: (val) {
                          settingsService.updateSettings(settings.copyWith(hapticFeedback: val));
                        },
                      ),
                      const Divider(height: 1, indent: 64),
                      SwitchListTile(
                        secondary: const Icon(Icons.lightbulb_outline),
                        title: const Text('Offline Suggestions'),
                        subtitle: const Text('Predict Brahui and English words'),
                        value: settings.suggestionsEnabled,
                        onChanged: (val) {
                          settingsService.updateSettings(settings.copyWith(suggestionsEnabled: val));
                        },
                      ),
                      const Divider(height: 1, indent: 64),
                      SwitchListTile(
                        secondary: const Icon(Icons.content_paste),
                        title: const Text('Clipboard History'),
                        subtitle: const Text('Quick paste bar in keyboard'),
                        value: settings.clipboardHistory,
                        onChanged: (val) {
                          settingsService.updateSettings(settings.copyWith(clipboardHistory: val));
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Help & About
                Card(
                  child: Column(
                    children: [
                      SettingTile(
                        icon: Icons.help_center_outlined,
                        title: 'Help & Guide',
                        subtitle: 'How to use Harakat, ڷ key, and long-press',
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const HelpScreen()),
                          );
                        },
                      ),
                      const Divider(height: 1, indent: 64),
                      SettingTile(
                        icon: Icons.info_outline,
                        title: 'About Brahui Keyboard',
                        subtitle: 'v1.0.0 • Offline & Privacy-focused',
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AboutScreen()),
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
