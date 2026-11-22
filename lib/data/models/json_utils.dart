/// Reads a JSON value as a trimmed string, whatever type the API sent
/// (PHP may return numbers, strings or null for the same field).
String? jsonString(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}
