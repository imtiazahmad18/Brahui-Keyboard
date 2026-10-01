import 'dart:convert';
import 'package:flutter/services.dart';
import '../utils/unicode_utils.dart';

class TrieNode {
  final Map<String, TrieNode> children = {};
  bool isWord = false;
  int frequency = 0;
}

/// Offline-first suggestion engine. Dictionaries can be replaced without
/// changing keyboard UI. Typing continues if dictionary load fails.
class SuggestionEngine {
  final TrieNode _brahviRoot = TrieNode();
  final TrieNode _englishRoot = TrieNode();
  final Map<String, int> _learned = {};
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  Future<void> initialize() async {
    if (_isLoaded) return;
    try {
      await _loadAsset('shared/dictionaries/brahvi_dictionary.json', _brahviRoot);
      await _loadAsset('shared/dictionaries/english_dictionary.json', _englishRoot);
    } catch (_) {
      seedFallback();
    } finally {
      _isLoaded = true;
    }
  }

  void seedFallback() {
    const brahvi = {
      'براہوئی': 1200,
      'سلّام': 1100,
      'ای': 1050,
      'ڷول': 500,
      'ڷٹ': 480,
    };
    brahvi.forEach((word, freq) => _insert(_brahviRoot, word, freq));
  }

  void loadWords(List<Map<String, dynamic>> words, {String language = 'brahvi'}) {
    final root = language == 'english' ? _englishRoot : _brahviRoot;
    for (final item in words) {
      final word = item['word'] as String? ?? '';
      final freq = (item['frequency'] as num?)?.toInt() ?? 1;
      _insert(root, word, freq);
    }
    _isLoaded = true;
  }

  Future<void> _loadAsset(String path, TrieNode root) async {
    final jsonString = await rootBundle.loadString(path);
    final data = json.decode(jsonString);
    if (data['words'] is List) {
      for (var item in data['words']) {
        _insert(root, item['word'] as String, (item['frequency'] as num).toInt());
      }
    }
  }

  void _insert(TrieNode root, String word, int frequency) {
    if (word.isEmpty) return;
    TrieNode current = root;
    for (int i = 0; i < word.length; i++) {
      final char = word[i];
      current = current.children.putIfAbsent(char, () => TrieNode());
    }
    current.isWord = true;
    current.frequency = frequency;
  }

  void learnWord(String word, {String language = 'brahvi'}) {
    final trimmed = word.trim();
    if (trimmed.length < 2) return;
    _learned[trimmed] = (_learned[trimmed] ?? 0) + 1;
    _insert(language == 'english' ? _englishRoot : _brahviRoot, trimmed, 50 + _learned[trimmed]!);
  }

  List<String> getSuggestions(String prefix, {String language = 'brahvi', int maxResults = 3}) {
    if (prefix.trim().isEmpty) return [];
    try {
      final root = language == 'english' ? _englishRoot : _brahviRoot;
      TrieNode? current = root;
      for (int i = 0; i < prefix.length; i++) {
        final char = prefix[i];
        if (!current!.children.containsKey(char)) {
          return [];
        }
        current = current.children[char];
      }
      final candidates = <MapEntry<String, int>>[];
      _collect(current!, prefix, candidates);
      candidates.sort((a, b) => b.value.compareTo(a.value));
      return candidates.take(maxResults).map((e) => e.key).toList();
    } catch (_) {
      return [];
    }
  }

  void _collect(TrieNode node, String currentPrefix, List<MapEntry<String, int>> results) {
    if (node.isWord) {
      results.add(MapEntry(currentPrefix, node.frequency));
    }
    for (final entry in node.children.entries) {
      _collect(entry.value, currentPrefix + entry.key, results);
    }
  }

  /// Conservative autocorrect: never rewrite Brahvi letters, only complete
  /// a prefix when a single high-frequency candidate exists.
  String? getAutocorrect(String word, {String language = 'brahvi'}) {
    if (word.length < 3) return null;
    if (language != 'english' && UnicodeUtils.containsBrahviLamWithDots(word)) {
      final suggestions = getSuggestions(word, language: language, maxResults: 1);
      if (suggestions.isNotEmpty && suggestions.first.startsWith(word) && suggestions.first != word) {
        return suggestions.first;
      }
      return null;
    }
    final suggestions = getSuggestions(word, language: language, maxResults: 1);
    if (suggestions.isNotEmpty && suggestions.first != word && suggestions.first.startsWith(word)) {
      return suggestions.first;
    }
    return null;
  }
}
