import 'dart:convert';

// Helper top-level para usar con `compute()` desde providers.
// Recibe cualquier valor JSON-serializable y devuelve su representación en String.
String encodeToJson(dynamic value) {
  return jsonEncode(value);
}
