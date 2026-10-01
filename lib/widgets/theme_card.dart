import 'package:flutter/material.dart';
import '../models/theme_config.dart';

class ThemeCard extends StatelessWidget {
  final ThemeConfig theme;
  final bool isSelected;
  final VoidCallback onSelect;

  const ThemeCard({
    super.key,
    required this.theme,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: theme.keyboardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.accentColor : theme.dividerColor,
            width: isSelected ? 2.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.accentColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    theme.name,
                    style: TextStyle(
                      color: theme.primaryText,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: theme.accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 14, color: Colors.white),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Mini keyboard preview swatch
            Row(
              children: [
                _buildMiniKey(theme.normalKeyBackground, 'ب', theme.normalKeyText),
                const SizedBox(width: 4),
                _buildMiniKey(theme.normalKeyBackground, 'ڷ', theme.normalKeyText, isSpecialChar: true),
                const SizedBox(width: 4),
                _buildMiniKey(theme.specialKeyBackground, '123', theme.specialKeyText),
                const SizedBox(width: 4),
                _buildMiniKey(theme.actionKeyBackground, '↵', theme.actionKeyText),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniKey(Color bg, String text, Color textColor, {bool isSpecialChar = false}) {
    return Expanded(
      child: Container(
        height: 28,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: isSpecialChar ? Border.all(color: theme.accentColor, width: 1) : null,
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontFamily: RegExp(r'[\u0600-\u08FF]').hasMatch(text) ? 'NooriNastaliq' : null,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
