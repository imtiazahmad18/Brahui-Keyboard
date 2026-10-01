import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../services/suggestion_service.dart';
import '../models/keyboard_layout.dart';
import '../widgets/theme_card.dart';
import '../widgets/keyboard_preview.dart';

class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  KeyboardLayout? _currentLayout;
  String _activeLayoutId = 'brahvi_normal';
  String _previousLayoutId = 'brahvi_normal';
  final SuggestionEngine _suggestionEngine = SuggestionEngine();

  @override
  void initState() {
    super.initState();
    _loadInitialLayout();
    _suggestionEngine.initialize();
  }

  Future<void> _loadInitialLayout() async {
    final settingsService = context.read<SettingsService>();
    final layout = await settingsService.loadLayout(_activeLayoutId);
    if (mounted) {
      setState(() => _currentLayout = layout);
    }
  }

  Future<void> _switchLayout(String layoutId) async {
    final settingsService = context.read<SettingsService>();
    final layout = await settingsService.loadLayout(layoutId);
    if (mounted) {
      setState(() {
        _previousLayoutId = _activeLayoutId;
        _activeLayoutId = layoutId;
        _currentLayout = layout;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsService = context.watch<SettingsService>();
    final settings = settingsService.settings;
    final themes = settingsService.themes;
    final currentTheme = settingsService.currentTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme & Appearance'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Live Keyboard Preview Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Live Keyboard Preview',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              DropdownButton<String>(
                value: _activeLayoutId,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'brahvi_normal', child: Text('Brahui (Normal)')),
                  DropdownMenuItem(value: 'brahvi_shift', child: Text('Brahui (Shift)')),
                  DropdownMenuItem(value: 'english_normal', child: Text('English (Normal)')),
                  DropdownMenuItem(value: 'english_shift', child: Text('English (Shift)')),
                  DropdownMenuItem(value: 'numbers_symbols', child: Text('Numbers & Symbols')),
                ],
                onChanged: (val) {
                  if (val != null) _switchLayout(val);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Interactive Keyboard Preview Frame
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: _currentLayout == null
                ? const SizedBox(
                    height: 220,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : KeyboardPreview(
                    layout: _currentLayout!,
                    theme: currentTheme,
                    settings: settings,
                    harakatList: settingsService.harakatList,
                    suggestionEngine: _suggestionEngine,
                    onSwitchLayout: (target) => _switchLayout(target),
                    onSwitchLanguage: (target) => _switchLayout(target),
                    onRestorePrevious: () => _switchLayout(_previousLayoutId),
                  ),
          ),

          const SizedBox(height: 24),

          // Themes Grid
          const Text(
            'Select Theme',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.6,
            ),
            itemCount: themes.length,
            itemBuilder: (context, index) {
              final theme = themes[index];
              return ThemeCard(
                theme: theme,
                isSelected: theme.id == settings.currentThemeId,
                onSelect: () {
                  settingsService.setTheme(theme.id);
                },
              );
            },
          ),

          const SizedBox(height: 24),

          // Sizing & Spacing Adjustments
          const Text(
            'Layout & Sizing',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Keyboard Height (${(settings.keyboardHeightRatio * 100).toInt()}%)'),
                  Slider(
                    value: settings.keyboardHeightRatio,
                    min: 0.8,
                    max: 1.3,
                    divisions: 10,
                    onChanged: (val) {
                      settingsService.updateSettings(
                        settings.copyWith(keyboardHeightRatio: val),
                      );
                    },
                  ),
                  const Divider(),
                  Text('Key Spacing (${settings.keySpacing.toStringAsFixed(1)} dp)'),
                  Slider(
                    value: settings.keySpacing,
                    min: 2.0,
                    max: 8.0,
                    divisions: 12,
                    onChanged: (val) {
                      settingsService.updateSettings(
                        settings.copyWith(keySpacing: val),
                      );
                    },
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
