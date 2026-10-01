/// Utilities for Brahvi Unicode handling and grapheme-safe operations.
class UnicodeUtils {
  /// The signature Brahvi character: Lam with three dots above (U+06B7).
  static const String brahviLamWithDots = '\u06B7';

  /// Complete, exact set of 39 standard Brahvi Arabic-script characters.
  static const List<String> brahviAlphabet = [
    'ا', 'ب', 'پ', 'ت', 'ٹ', 'ث', 'ج', 'چ', 'ح', 'خ',
    'د', 'ڈ', 'ذ', 'ر', 'ڑ', 'ز', 'ژ', 'س', 'ش', 'ص',
    'ض', 'ط', 'ظ', 'ع', 'غ', 'ف', 'ق', 'ک', 'گ', 'ل',
    'ڷ', 'م', 'ن', 'و', 'ہ', 'ھ', 'ء', 'ی', 'ے'
  ];

  /// Standard Arabic/Urdu combining marks (Harakat).
  static const Set<int> combiningMarks = {
    0x064B, // Tanween Fatha
    0x064C, // Tanween Damma
    0x064D, // Tanween Kasra
    0x064E, // Fatha (Zabar)
    0x064F, // Damma (Pesh)
    0x0650, // Kasra (Zer)
    0x0651, // Shadda (Tashdeed)
    0x0652, // Sukun (Jazm)
    0x0653, // Maddah
    0x0654, // Hamza Above
    0x0670, // Dagger Alif (Khari Zabar)
    0x0657, // Inverted Damma
  };

  static const Set<int> wordSeparators = {
    0x0020, // space
    0x000A, // newline
    0x0009, // tab
    0x060C, // Arabic comma
    0x061B, // Arabic semicolon
    0x061F, // Arabic question mark
    0x06D4, // Urdu full stop
    0x002E, // period
    0x002C, // comma
    0x003B, // semicolon
    0x003A, // colon
    0x0021, // bang
    0x003F, // question
  };

  static bool isCombiningMark(int codeUnit) {
    return combiningMarks.contains(codeUnit);
  }

  static bool isBrahviSpecialChar(String char) {
    return char == brahviLamWithDots && char.runes.first == 0x06B7;
  }

  static bool isBrahviChar(String char) {
    return brahviAlphabet.contains(char);
  }

  /// Inserts a combining harakat after the last base character.
  static String insertHarakat(String text, String mark) {
    if (mark.isEmpty) return text;
    final markCode = mark.runes.first;
    if (!isCombiningMark(markCode)) {
      return text + mark;
    }
    return text + mark;
  }

  /// Deletes the last combining mark if present, otherwise the last base character.
  /// Never leaves an orphaned combining mark after a deleted letter.
  static String safeBackspace(String text) {
    if (text.isEmpty) return text;
    final runes = text.runes.toList();
    if (runes.isEmpty) return '';

    final lastIndex = runes.length - 1;
    if (isCombiningMark(runes[lastIndex])) {
      runes.removeLast();
      return String.fromCharCodes(runes);
    }

    runes.removeLast();
    return String.fromCharCodes(runes);
  }

  static String lastWord(String text) {
    if (text.isEmpty) return '';
    final runes = text.runes.toList();
    int end = runes.length;
    int start = end;
    while (start > 0 && !wordSeparators.contains(runes[start - 1])) {
      start--;
    }
    return String.fromCharCodes(runes.sublist(start, end));
  }

  static String replaceLastWord(String text, String replacement) {
    final word = lastWord(text);
    if (word.isEmpty) return '$replacement ';
    return '${text.substring(0, text.length - word.length)}$replacement ';
  }

  static bool containsBrahviLamWithDots(String text) {
    return text.contains(brahviLamWithDots);
  }
}
