import 'package:flutter/services.dart';

class NumericInputFormatter extends TextInputFormatter {
  const NumericInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) {
      return newValue;
    }

    if (!_isValidNumericInput(text)) {
      return oldValue;
    }
    return newValue;
  }

  bool _isValidNumericInput(String text) {
    var decimalCount = 0;
    var signCount = 0;

    for (var index = 0; index < text.length; index++) {
      final char = text[index];
      final isDigit = char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57;
      if (isDigit || char == ',') {
        continue;
      }
      if (char == '.') {
        decimalCount++;
        if (decimalCount > 1) {
          return false;
        }
        continue;
      }
      if (char == '-') {
        signCount++;
        if (signCount > 1 || index != 0) {
          return false;
        }
        continue;
      }
      return false;
    }

    return true;
  }
}
