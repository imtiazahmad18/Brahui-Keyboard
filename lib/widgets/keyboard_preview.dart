import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/key_model.dart';
import '../models/keyboard_layout.dart';
import '../models/theme_config.dart';
import '../models/settings_model.dart';
import '../models/harakat_model.dart';
import '../utils/unicode_utils.dart';
import '../services/suggestion_service.dart';
import 'harakat_panel.dart';

class KeyboardPreview extends StatefulWidget {
  final KeyboardLayout layout;
  final ThemeConfig theme;
  final KeyboardSettings settings;
  final List<HarakatItem> harakatList;
  final Function(String targetLayout)? onSwitchLayout;
  final Function(String targetLanguage)? onSwitchLanguage;
  final VoidCallback? onRestorePrevious;
  final SuggestionEngine? suggestionEngine;

  const KeyboardPreview({
    super.key,
    required this.layout,
    required this.theme,
    required this.settings,
    required this.harakatList,
    this.onSwitchLayout,
    this.onSwitchLanguage,
    this.onRestorePrevious,
    this.suggestionEngine,
  });

  @override
  State<KeyboardPreview> createState() => _KeyboardPreviewState();
}

class _KeyboardPreviewState extends State<KeyboardPreview> {
  final TextEditingController _textController = TextEditingController();
  bool _showHarakatPanel = false;
  String? _activeAlternateKey;
  List<String> _currentAlternates = [];
  List<String> _suggestions = [];

  bool _containsArabicScript(String text) => text.runes.any((rune) =>
      (rune >= 0x0600 && rune <= 0x06FF) ||
      (rune >= 0x0750 && rune <= 0x077F) ||
      (rune >= 0x08A0 && rune <= 0x08FF));

  @override
  void initState() {
    super.initState();
    _updateSuggestions();
  }

  void _updateSuggestions() {
    if (!widget.settings.suggestionsEnabled || widget.suggestionEngine == null) {
      setState(() => _suggestions = []);
      return;
    }
    final text = _textController.text;
    final words = text.split(RegExp(r'\s+'));
    final lastWord = words.isNotEmpty ? words.last : '';
    final results = widget.suggestionEngine!.getSuggestions(
      lastWord,
      language: widget.layout.language,
      maxResults: 3,
    );
    setState(() => _suggestions = results);
  }

  void _handleKeyTap(KeyModel key) {
    if (widget.settings.hapticFeedback) {
      HapticFeedback.lightImpact();
    }

    switch (key.action) {
      case KeyAction.INSERT_TEXT:
        final char = key.output ?? key.label;
        _insertText(char);
        break;
      case KeyAction.INSERT_SPACE:
        _insertText(' ');
        break;
      case KeyAction.DELETE_BACKWARD:
        final current = _textController.text;
        _textController.text = UnicodeUtils.safeBackspace(current);
        _updateSuggestions();
        break;
      case KeyAction.SWITCH_LAYOUT:
        if (key.target != null && widget.onSwitchLayout != null) {
          widget.onSwitchLayout!(key.target!);
        }
        break;
      case KeyAction.SWITCH_LANGUAGE:
        if (key.target != null && widget.onSwitchLanguage != null) {
          widget.onSwitchLanguage!(key.target!);
        }
        break;
      case KeyAction.RESTORE_PREVIOUS_LAYOUT:
        if (widget.onRestorePrevious != null) {
          widget.onRestorePrevious!();
        }
        break;
      case KeyAction.OPEN_HARAKAT:
        setState(() {
          _showHarakatPanel = !_showHarakatPanel;
        });
        break;
      case KeyAction.SUBMIT:
        _insertText('\n');
        break;
      case KeyAction.OPEN_CLIPBOARD:
        // Show clipboard snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clipboard: Paste recent clips')),
        );
        break;
      case KeyAction.OPEN_EMOJI:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Emoji picker is not available in preview')),
        );
        break;
      case KeyAction.SWITCH_KEYBOARD:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Use the system keyboard picker while the keyboard is active')),
        );
        break;
      case KeyAction.NAVIGATE:
        // Pure navigation - never insert text
        break;
    }
  }

  void _insertText(String str) {
    final current = _textController.text;
    _textController.text = current + str;
    _updateSuggestions();
  }

  void _handleLongPress(KeyModel key) {
    if (key.alternates.isNotEmpty) {
      if (widget.settings.hapticFeedback) {
        HapticFeedback.mediumImpact();
      }
      setState(() {
        _activeAlternateKey = key.label;
        _currentAlternates = key.alternates;
      });
      _showAlternatesDialog(key);
    }
  }

  void _showAlternatesDialog(KeyModel key) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: widget.theme.keyboardBackground,
          title: Text(
            'Alternates for ${key.label}',
            style: TextStyle(
              color: widget.theme.primaryText,
              fontSize: 16,
              fontFamily: _containsArabicScript(key.label) ? 'NooriNastaliq' : null,
            ),
          ),
          content: Wrap(
            spacing: 8,
            children: key.alternates.map((alt) {
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.theme.normalKeyBackground,
                  foregroundColor: widget.theme.normalKeyText,
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _insertText(alt);
                },
                child: Text(
                  alt,
                  style: TextStyle(
                    fontSize: 20,
                    fontFamily: _containsArabicScript(alt) ? 'NooriNastaliq' : null,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = widget.layout.isRTL;
    final rowHeight = 44.0 * widget.settings.keyboardHeightRatio;
    final spacing = widget.settings.keySpacing;

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Live input test field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: widget.theme.keyboardBackground.withOpacity(0.5),
              border: Border(bottom: BorderSide(color: widget.theme.dividerColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    textAlign: isRTL ? TextAlign.right : TextAlign.left,
                    textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                    style: TextStyle(
                      color: widget.theme.primaryText,
                      fontSize: 18,
                      fontFamily: _containsArabicScript(_textController.text) || isRTL ? 'NooriNastaliq' : null,
                    ),
                    decoration: InputDecoration(
                      hintText: isRTL ? 'داڑے ٹائپ کبو...' : 'Type here to test...',
                      hintStyle: TextStyle(color: widget.theme.secondaryText.withOpacity(0.7)),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (_textController.text.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.clear, color: widget.theme.secondaryText, size: 20),
                    onPressed: () {
                      _textController.clear();
                      _updateSuggestions();
                    },
                  ),
              ],
            ),
          ),

          // Suggestion bar
          if (widget.settings.suggestionsEnabled && _suggestions.isNotEmpty)
            Container(
              height: 38,
              color: widget.theme.suggestionBarBackground,
              child: Row(
                children: _suggestions.map((suggestion) {
                  return Expanded(
                    child: InkWell(
                      onTap: () {
                        // Replace last word with suggestion
                        final words = _textController.text.split(RegExp(r'\s+'));
                        if (words.isNotEmpty) words.removeLast();
                        words.add(suggestion);
                        _textController.text = '${words.join(' ')} ';
                        _updateSuggestions();
                      },
                      child: Center(
                        child: Text(
                          suggestion,
                          style: TextStyle(
                            color: widget.theme.suggestionBarText,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            fontFamily: _containsArabicScript(suggestion) ? 'NooriNastaliq' : null,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          // Harakat expandable panel
          if (_showHarakatPanel)
            HarakatPanel(
              harakatList: widget.harakatList,
              theme: widget.theme,
              onSelectHarakat: (h) {
                _insertText(h);
                setState(() => _showHarakatPanel = false);
              },
              onClose: () => setState(() => _showHarakatPanel = false),
            ),

          // Keyboard Rows Container
          Container(
            color: widget.theme.keyboardBackground,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Column(
              children: widget.layout.rows.map((row) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: spacing / 2),
                  child: Row(
                    children: row.map((key) {
                      return _buildKeyWidget(key, rowHeight, spacing);
                    }).toList(),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyWidget(KeyModel key, double height, double spacing) {
    Color bg;
    Color fg;

    switch (key.type) {
      case KeyType.ENTER:
        bg = widget.theme.actionKeyBackground;
        fg = widget.theme.actionKeyText;
        break;
      case KeyType.SHIFT:
      case KeyType.BACKSPACE:
      case KeyType.MODE:
      case KeyType.LANGUAGE:
      case KeyType.HARAKAT:
      case KeyType.CLIPBOARD:
      case KeyType.NAVIGATION:
        bg = key.active ? widget.theme.actionKeyBackground : widget.theme.specialKeyBackground;
        fg = key.active ? widget.theme.actionKeyText : widget.theme.specialKeyText;
        break;
      default:
        bg = widget.theme.normalKeyBackground;
        fg = widget.theme.normalKeyText;
    }

    final isSpecialChar = key.label == 'ڷ';

    return Expanded(
      flex: (key.weight * 100).toInt(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: spacing / 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _handleKeyTap(key),
            onLongPress: () => _handleLongPress(key),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(8),
                border: isSpecialChar
                    ? Border.all(color: widget.theme.accentColor, width: 1.5)
                    : Border.all(color: widget.theme.dividerColor.withOpacity(0.5), width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    key.label,
                    style: TextStyle(
                      color: fg,
                      fontSize: key.type == KeyType.SPACE ? 14 : (key.label.length > 2 ? 13 : 20),
                      fontWeight: isSpecialChar ? FontWeight.bold : FontWeight.w500,
                      fontFamily: _containsArabicScript(key.label) ? 'NooriNastaliq' : null,
                    ),
                  ),
                  if (key.alternates.isNotEmpty && key.type == KeyType.CHARACTER)
                    Positioned(
                      top: 2,
                      right: widget.layout.isRTL ? null : 4,
                      left: widget.layout.isRTL ? 4 : null,
                      child: Text(
                        key.alternates.first,
                        style: TextStyle(
                          color: fg.withOpacity(0.45),
                          fontSize: 9,
                          fontFamily: _containsArabicScript(key.alternates.first) ? 'NooriNastaliq' : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
