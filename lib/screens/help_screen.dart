import 'package:flutter/material.dart';
import '../services/platform_channel_service.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & User Guide'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Android Setup Guide
          _buildGuideSection(
            context,
            title: 'Android Setup Guide',
            icon: Icons.android,
            color: Colors.green,
            steps: [
              'Step 1: Open system Settings > System > Languages & input > On-screen keyboard (or "Manage keyboards").',
              'Step 2: Find "Brahui Keyboard" and toggle the switch to ON.',
              'Step 3: When typing in any app, tap the keyboard icon at the bottom right corner (or swipe down notification bar) and select "Brahui Keyboard".',
            ],
            action: ElevatedButton.icon(
              onPressed: () => PlatformChannelService.openKeyboardSettings(),
              icon: const Icon(Icons.settings),
              label: const Text('Open Android Keyboard Settings'),
            ),
          ),

          const SizedBox(height: 16),

          // iOS Setup Guide
          _buildGuideSection(
            context,
            title: 'iOS Setup Guide (iPhone / iPad)',
            icon: Icons.apple,
            color: Colors.grey.shade800,
            steps: [
              'Step 1: Open iOS Settings > General > Keyboard > Keyboards.',
              'Step 2: Tap "Add New Keyboard..." and choose "Brahui Keyboard" under Third-Party Keyboards.',
              'Step 3: (Optional) Tap "Brahui Keyboard" and enable "Allow Full Access" if you wish to use clipboard history features.',
              'Step 4: When typing, tap or long-press the Globe (🌐) icon to switch to Brahui Keyboard.',
            ],
          ),

          const SizedBox(height: 16),

          // How to type Brahui special character ڷ
          _buildGuideSection(
            context,
            title: 'Brahui Special Character: ڷ (U+06B7)',
            icon: Icons.star_outline,
            color: Colors.amber.shade800,
            steps: [
              'The signature Brahui sound (Lam with 3 dots above, U+06B7) has a dedicated key directly next to Lam (ل) on row 2.',
              'You can also type ڷ by long-pressing the normal Lam (ل) key.',
              'This letter is preserved exactly according to standard Unicode U+06B7.',
            ],
          ),

          const SizedBox(height: 16),

          // How to use Harakat
          _buildGuideSection(
            context,
            title: 'How to use Harakat (حَرَکات)',
            icon: Icons.format_color_text,
            color: const Color(0xFF5CB4E8),
            steps: [
              'Tap the Harakat button (◌َ) to type Zabar. Hold it and drag to a mark to choose another diacritic.',
              'Select Zabar (Fatha), Zer (Kasra), Pesh (Damma), Tashdeed, Jazm, Khari Zabar, etc.',
              'Harakat are true Unicode combining marks and automatically attach to the preceding character.',
              'Pressing Backspace intelligently removes combining marks without deleting the base consonant!',
            ],
          ),

          const SizedBox(height: 16),

          // How to use Long-Press Alternates
          _buildGuideSection(
            context,
            title: 'Long-Press Alternates',
            icon: Icons.touch_app,
            color: Colors.blue,
            steps: [
              'Keys with alternates display a small hint mark.',
              'Long press any key to view additional characters (e.g. ب reveals پ and ٻ; ت reveals ٹ; د reveals ڈ; ر reveals ڑ).',
              'Drag to the character you want and release to type it.',
            ],
          ),

          const SizedBox(height: 16),

          // Language & 123 Switching
          _buildGuideSection(
            context,
            title: 'Switching Languages & Numbers (123)',
            icon: Icons.swap_horiz,
            color: Colors.purple,
            steps: [
              'Tap the "EN" button to switch between Brahui and English QWERTY.',
              'Tap the "123" button to access numbers and symbols. When returning with "ABC / بر", the keyboard remembers your previous language and restores it accurately.',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuideSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<String> steps,
    Widget? action,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...steps.map((step) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    step,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.9),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                )),
            if (action != null) ...[
              const SizedBox(height: 12),
              action,
            ],
          ],
        ),
      ),
    );
  }
}
