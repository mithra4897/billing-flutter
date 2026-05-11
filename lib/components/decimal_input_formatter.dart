import 'package:flutter/services.dart';

class DecimalInputFormatter extends TextInputFormatter {
  const DecimalInputFormatter({this.allowSigned = false});

  final bool allowSigned;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final normalized = newValue.text.replaceAll(',', '.');

    if (normalized.isEmpty) {
      return newValue.copyWith(text: normalized);
    }

    if (allowSigned && normalized == '-') {
      return newValue.copyWith(text: normalized);
    }

    final pattern = allowSigned
        ? RegExp(r'^-?\d*\.?\d*$')
        : RegExp(r'^\d*\.?\d*$');

    if (!pattern.hasMatch(normalized)) {
      return oldValue;
    }

    final cursorDelta = normalized.length - newValue.text.length;
    final selectionIndex =
        (newValue.selection.end + cursorDelta).clamp(0, normalized.length);

    return TextEditingValue(
      text: normalized,
      selection: TextSelection.collapsed(offset: selectionIndex),
      composing: TextRange.empty,
    );
  }
}
