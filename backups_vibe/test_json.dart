import 'dart:convert';

void main() {
  try {
    final json = '{"test": "value"}';
    final decoded = jsonDecode(json);
    print("jsonDecode funciona: $decoded");
    
    final encoded = jsonEncode({"test": "value"});
    print("jsonEncode funciona: $encoded");
  } catch (e) {
    print("ERRO com dart:convert: $e");
  }
}
