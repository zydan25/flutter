class FormValidationException implements Exception {
  const FormValidationException(this.errors);

  final Map<String, String> errors;

  @override
  String toString() => 'FormValidationException: $errors';
}

class FormFieldSpec {
  const FormFieldSpec({
    required this.name,
    required this.type,
    this.required = false,
    this.min,
    this.max,
    this.regex,
    this.visibleWhen,
    this.options,
  });

  final String name;
  final String type;
  final bool required;
  final num? min;
  final num? max;
  final String? regex;
  final Map<String, dynamic>? visibleWhen;
  final List<dynamic>? options;

  factory FormFieldSpec.fromJson(Map<String, dynamic> json) => FormFieldSpec(
        name: '${json['name'] ?? ''}',
        type: '${json['type'] ?? 'text'}',
        required: json['required'] == true,
        min: _num(json['min']),
        max: _num(json['max']),
        regex: json['regex']?.toString(),
        visibleWhen: (json['visible_when'] as Map?)?.cast<String, dynamic>(),
        options: json['options'] is List ? List<dynamic>.from(json['options']) : null,
      );

  static num? _num(dynamic value) =>
      value is num ? value : num.tryParse('$value');
}

class DynamicFormSpec {
  const DynamicFormSpec({required this.id, required this.fields});

  final String id;
  final List<FormFieldSpec> fields;

  factory DynamicFormSpec.fromJson(Map<String, dynamic> json) => DynamicFormSpec(
        id: '${json['id'] ?? 'form'}',
        fields: (json['fields'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => FormFieldSpec.fromJson(e.cast<String, dynamic>()))
            .toList(),
      );

  Map<String, String> validate(Map<String, dynamic> values) {
    final errors = <String, String>{};
    for (final field in fields) {
      if (!isVisible(field, values)) continue;
      final value = values[field.name];
      final text = value?.toString().trim() ?? '';
      if (field.required && text.isEmpty) {
        errors[field.name] = 'required';
        continue;
      }
      if (text.isEmpty) continue;
      if (field.regex != null && !RegExp(field.regex!).hasMatch(text)) {
        errors[field.name] = 'invalid_format';
        continue;
      }
      final number = field.type == 'number' ? num.tryParse(text) : null;
      if (field.type == 'number' && number == null) {
        errors[field.name] = 'invalid_number';
        continue;
      }
      if (number != null && field.min != null && number < field.min!) {
        errors[field.name] = 'min';
      } else if (number != null && field.max != null && number > field.max!) {
        errors[field.name] = 'max';
      }
    }
    return errors;
  }

  bool isVisible(FormFieldSpec field, Map<String, dynamic> values) {
    final condition = field.visibleWhen;
    if (condition == null) return true;
    final dependsOn = condition['field']?.toString();
    if (dependsOn == null || dependsOn.isEmpty) return true;
    final actual = values[dependsOn];
    if (condition.containsKey('equals')) return actual == condition['equals'];
    if (condition.containsKey('not_equals')) return actual != condition['not_equals'];
    return actual == true;
  }
}
