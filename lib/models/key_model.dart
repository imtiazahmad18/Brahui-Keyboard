enum KeyType {
  CHARACTER,
  SHIFT,
  BACKSPACE,
  ENTER,
  SPACE,
  MODE,
  LANGUAGE,
  HARAKAT,
  CLIPBOARD,
  NAVIGATION,
  EMOJI,
}

enum KeyAction {
  INSERT_TEXT,
  DELETE_BACKWARD,
  SUBMIT,
  INSERT_SPACE,
  SWITCH_LAYOUT,
  SWITCH_LANGUAGE,
  RESTORE_PREVIOUS_LAYOUT,
  OPEN_HARAKAT,
  OPEN_CLIPBOARD,
  OPEN_EMOJI,
  SWITCH_KEYBOARD,
  NAVIGATE,
}

class KeyModel {
  final String label;
  final String? output;
  final KeyType type;
  final KeyAction action;
  final String? target;
  final double weight;
  final bool active;
  final List<String> alternates;

  const KeyModel({
    required this.label,
    this.output,
    required this.type,
    required this.action,
    this.target,
    this.weight = 1.0,
    this.active = false,
    this.alternates = const [],
  });

  factory KeyModel.fromJson(Map<String, dynamic> json) {
    KeyType parsedType = KeyType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => KeyType.CHARACTER,
    );

    KeyAction parsedAction = KeyAction.values.firstWhere(
      (e) => e.name == json['action'],
      orElse: () => KeyAction.INSERT_TEXT,
    );

    List<String> altList = [];
    if (json['alternates'] is List) {
      altList = (json['alternates'] as List).map((e) => e.toString()).toList();
    }

    return KeyModel(
      label: json['label'] as String,
      output: json['output'] as String?,
      type: parsedType,
      action: parsedAction,
      target: json['target'] as String?,
      weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
      active: (json['active'] as bool?) ?? false,
      alternates: altList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      if (output != null) 'output': output,
      'type': type.name,
      'action': action.name,
      if (target != null) 'target': target,
      'weight': weight,
      'active': active,
      'alternates': alternates,
    };
  }
}
