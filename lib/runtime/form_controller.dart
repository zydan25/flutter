import 'form_runtime.dart';

class DynamicFormController {
  DynamicFormController(this.spec, {Map<String, dynamic>? initialValues})
    : _values = {...?initialValues};

  final DynamicFormSpec spec;
  final Map<String, dynamic> _values;

  Map<String, dynamic> get values => Map<String, dynamic>.unmodifiable(_values);

  bool isVisible(String fieldName) {
    final field = spec.fields.firstWhere(
      (item) => item.name == fieldName,
      orElse: () => throw ArgumentError('Unknown form field: $fieldName'),
    );
    return spec.isVisible(field, _values);
  }

  void setValue(String name, dynamic value) {
    if (!spec.fields.any((field) => field.name == name)) {
      throw ArgumentError('Unknown form field: $name');
    }
    _values[name] = value;
  }

  void setValues(Map<String, dynamic> values) {
    for (final entry in values.entries) {
      if (spec.fields.any((field) => field.name == entry.key)) {
        _values[entry.key] = entry.value;
      }
    }
  }

  Map<String, String> validate() => spec.validate(_values);

  void removeHiddenValues() {
    for (final field in spec.fields) {
      if (!spec.isVisible(field, _values)) {
        _values.remove(field.name);
      }
    }
  }

  Map<String, dynamic> submission({Map<String, dynamic>? mapping}) {
    final source = <String, dynamic>{..._values};
    if (mapping == null || mapping.isEmpty) return source;
    final output = <String, dynamic>{};
    for (final entry in mapping.entries) {
      final key = entry.key;
      final expression = '${entry.value}';
      if (expression.startsWith(r'${') && expression.endsWith('}')) {
        final path = expression.substring(2, expression.length - 1);
        output[key] = _lookup(source, path);
      } else {
        output[key] = entry.value;
      }
    }
    return output;
  }

  dynamic _lookup(Map<String, dynamic> source, String path) {
    dynamic current = source;
    for (final segment in path.split('.')) {
      if (current is Map<String, dynamic>) {
        current = current[segment];
      } else if (current is Map) {
        current = current[segment];
      } else {
        return null;
      }
    }
    return current;
  }
}
