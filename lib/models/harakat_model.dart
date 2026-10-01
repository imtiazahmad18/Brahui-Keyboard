class HarakatItem {
  final String id;
  final String name;
  final String symbol;
  final String output;
  final String unicode;
  final String description;

  const HarakatItem({
    required this.id,
    required this.name,
    required this.symbol,
    required this.output,
    required this.unicode,
    required this.description,
  });

  factory HarakatItem.fromJson(Map<String, dynamic> json) {
    return HarakatItem(
      id: json['id'] as String,
      name: json['name'] as String,
      symbol: json['symbol'] as String,
      output: json['output'] as String,
      unicode: json['unicode'] as String,
      description: json['description'] as String,
    );
  }
}
