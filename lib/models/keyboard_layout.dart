import 'key_model.dart';

class KeyboardLayout {
  final String id;
  final String name;
  final String language;
  final String direction; // 'rtl' or 'ltr'
  final List<List<KeyModel>> rows;

  const KeyboardLayout({
    required this.id,
    required this.name,
    required this.language,
    required this.direction,
    required this.rows,
  });

  bool get isRTL => direction.toLowerCase() == 'rtl';

  factory KeyboardLayout.fromJson(Map<String, dynamic> json) {
    var rawRows = json['rows'] as List;
    List<List<KeyModel>> parsedRows = rawRows.map((row) {
      return (row as List).map((k) => KeyModel.fromJson(k as Map<String, dynamic>)).toList();
    }).toList();

    return KeyboardLayout(
      id: json['id'] as String,
      name: json['name'] as String,
      language: json['language'] as String,
      direction: json['direction'] as String? ?? 'ltr',
      rows: parsedRows,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'language': language,
      'direction': direction,
      'rows': rows.map((row) => row.map((k) => k.toJson()).toList()).toList(),
    };
  }
}
