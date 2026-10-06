import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('1. Character Integrity and Unicode Verification', () {
    test('Exact Brahvi character set is present and valid', () {
      const expectedBrahviAlphabet = [
        'ا', 'ب', 'پ', 'ت', 'ٹ', 'ث', 'ج', 'چ', 'ح', 'خ',
        'د', 'ڈ', 'ذ', 'ر', 'ڑ', 'ز', 'ژ', 'س', 'ش', 'ص',
        'ض', 'ط', 'ظ', 'ع', 'غ', 'ف', 'ق', 'ک', 'گ', 'ل',
        'ڷ', 'م', 'ن', 'و', 'ہ', 'ھ', 'ء', 'ی', 'ے'
      ];

      final file = File('shared/config/brahvi_characters.json');
      expect(file.existsSync(), isTrue, reason: 'brahvi_characters.json must exist');
      final data = json.decode(file.readAsStringSync());
      final List alphabet = data['alphabet'];

      final loadedChars = alphabet.map((e) => e['char']).toList();

      for (final char in expectedBrahviAlphabet) {
        expect(loadedChars.contains(char), isTrue, reason: 'Character $char must be present in Brahvi alphabet');
      }
    });

    test('Special Brahvi character ڷ strictly equals U+06B7', () {
      const brahviLamWithDots = 'ڷ';
      expect(brahviLamWithDots.runes.first, equals(0x06B7), reason: 'ڷ must be strictly Unicode U+06B7');
      expect(brahviLamWithDots, equals('\u06B7'));

      final file = File('shared/config/brahvi_characters.json');
      final data = json.decode(file.readAsStringSync());
      final special = data['specialCharacter'];
      expect(special['char'], equals('ڷ'));
      expect(special['unicode'], equals('U+06B7'));
    });
  });

  group('2. Layout Parsing and Integrity', () {
    final layoutFiles = [
      'shared/config/layouts/brahvi_normal.json',
      'shared/config/layouts/brahvi_shift.json',
      'shared/config/layouts/brahvi_phonetic.json',
      'shared/config/layouts/brahvi_phonetic_shift.json',
      'shared/config/layouts/english_normal.json',
      'shared/config/layouts/english_shift.json',
      'shared/config/layouts/numbers_symbols.json',
    ];

    for (final path in layoutFiles) {
      test('Layout $path parses cleanly and adheres to schema', () {
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: 'Layout file $path must exist');
        final data = json.decode(file.readAsStringSync());

        expect(data['id'], isNotEmpty);
        expect(data['name'], isNotEmpty);
        expect(data['language'], isNotEmpty);
        expect(data['rows'], isA<List>());

        final rows = data['rows'] as List;
        expect(rows.length, inInclusiveRange(3, 5));

        for (final row in rows) {
          expect(row, isA<List>());
          for (final key in row) {
            expect(key['label'], isNotNull);
            expect(key['type'], isNotNull);
            expect(key['action'], isNotNull);
          }
        }
      });
    }

    test('Normal character keys insert themselves and do not have duplicate outputs', () {
      final file = File('shared/config/layouts/brahvi_normal.json');
      final data = json.decode(file.readAsStringSync());
      final rows = data['rows'] as List;

      final seenOutputs = <String>{};

      for (final row in rows) {
        for (final key in row) {
          if (key['type'] == 'CHARACTER') {
            expect(key['action'], equals('INSERT_TEXT'));
            final output = key['output'] ?? key['label'];
            // Normal character keys must output their character
            expect(output, equals(key['label']));
            expect(seenOutputs.contains(output), isFalse, reason: 'Duplicate output $output found in normal row');
            seenOutputs.add(output);
          }
        }
      }
    });

    test('Navigation and mode keys NEVER insert text', () {
      for (final path in layoutFiles) {
        final file = File(path);
        final data = json.decode(file.readAsStringSync());
        final rows = data['rows'] as List;

        for (final row in rows) {
          for (final key in row) {
            final type = key['type'];
            if (type == 'MODE' || type == 'NAVIGATION' || type == 'SHIFT' || type == 'BACKSPACE') {
              expect(key['action'], isNot(equals('INSERT_TEXT')),
                  reason: 'Key ${key['label']} of type $type must never have action INSERT_TEXT');
            }
          }
        }
      }
    });

    test('Space key displays lowercase "space" and outputs exactly " "', () {
      for (final path in layoutFiles) {
        final file = File(path);
        final data = json.decode(file.readAsStringSync());
        final rows = data['rows'] as List;

        bool foundSpace = false;
        for (final row in rows) {
          for (final key in row) {
            if (key['type'] == 'SPACE') {
              foundSpace = true;
              expect(key['label'], equals('space'), reason: 'Space key must display lowercase "space"');
              expect(key['output'], equals(' '), reason: 'Space key output must be exactly " "');
              expect(key['action'], equals('INSERT_SPACE'));
            }
          }
        }
        expect(foundSpace, isTrue, reason: 'Layout $path must contain a SPACE key');
      }
    });
  });

  group('3. Language and Mode Switching Flows', () {
    test('Brahvi -> English -> Brahvi language switch targets', () {
      final brahviFile = File('shared/config/layouts/brahvi_normal.json');
      final brahviData = json.decode(brahviFile.readAsStringSync());
      final brahviRows = brahviData['rows'] as List;

      String? langTargetInBrahvi;
      for (final row in brahviRows) {
        for (final key in row) {
          if (key['type'] == 'LANGUAGE') {
            langTargetInBrahvi = key['target'];
          }
        }
      }
      expect(langTargetInBrahvi, equals('english_normal'));

      final englishFile = File('shared/config/layouts/english_normal.json');
      final englishData = json.decode(englishFile.readAsStringSync());
      final englishRows = englishData['rows'] as List;

      String? langTargetInEnglish;
      for (final row in englishRows) {
        for (final key in row) {
          if (key['type'] == 'LANGUAGE') {
            langTargetInEnglish = key['target'];
          }
        }
      }
      expect(langTargetInEnglish, equals('brahvi_normal'));
    });

    test('123 number keyboard provides return to previous layout', () {
      final numbersFile = File('shared/config/layouts/numbers_symbols.json');
      final numbersData = json.decode(numbersFile.readAsStringSync());
      final rows = numbersData['rows'] as List;

      bool hasRestore = false;
      for (final row in rows) {
        for (final key in row) {
          if (key['action'] == 'RESTORE_PREVIOUS_LAYOUT') {
            hasRestore = true;
            expect(key['target'], equals('previous'));
          }
        }
      }
      expect(hasRestore, isTrue, reason: 'Numbers layout must have action RESTORE_PREVIOUS_LAYOUT');
    });
  });

  group('4. Theme IDs and Color Validation', () {
    test('All 7 user-selectable themes exist and have valid hex colors', () {
      final expectedThemeIds = [
        'light_white',
        'pure_black',
        'green',
        'olive',
        'warm_sand',
        'gboard_light',
        'gboard_dark',
      ];

      final file = File('shared/config/themes.json');
      expect(file.existsSync(), isTrue);
      final data = json.decode(file.readAsStringSync());
      final List themes = data['themes'];

      final loadedIds = themes.map((t) => t['id']).toList();

      for (final id in expectedThemeIds) {
        expect(loadedIds.contains(id), isTrue, reason: 'Theme $id must be present in themes.json');
      }

      final hexRegex = RegExp(r'^#[0-9A-Fa-f]{6}$');
      for (final theme in themes) {
        expect(hexRegex.hasMatch(theme['keyboardBackground']), isTrue);
        expect(hexRegex.hasMatch(theme['normalKeyBackground']), isTrue);
        expect(hexRegex.hasMatch(theme['normalKeyText']), isTrue);
        expect(hexRegex.hasMatch(theme['accentColor']), isTrue);

        if (theme['id'] == 'pure_black') {
          // Pure Black must be actually black #000000
          expect(theme['keyboardBackground'], equals('#000000'));
        }
      }
    });
  });
}
