import 'package:flutter/material.dart';
import '../models/harakat_model.dart';
import '../models/theme_config.dart';

class HarakatPanel extends StatelessWidget {
  final List<HarakatItem> harakatList;
  final ThemeConfig theme;
  final Function(String output) onSelectHarakat;
  final VoidCallback onClose;

  const HarakatPanel({
    super.key,
    required this.harakatList,
    required this.theme,
    required this.onSelectHarakat,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.keyboardBackground,
        border: Border(top: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'حَرَکات (Harakat / Diacritics)',
                style: TextStyle(
                  color: theme.primaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: 'NooriNastaliq',
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: theme.secondaryText, size: 18),
                onPressed: onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: harakatList.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: InkWell(
                    onTap: () => onSelectHarakat(item.output),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: theme.normalKeyBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.dividerColor, width: 0.8),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.symbol,
                            style: TextStyle(
                              color: theme.normalKeyText,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'NooriNastaliq',
                            ),
                          ),
                          Text(
                            item.name.split(' ').first,
                            style: TextStyle(
                              color: theme.secondaryText,
                              fontSize: 9,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
