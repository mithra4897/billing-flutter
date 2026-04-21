import 'package:flutter/services.dart';

class DateTimeInputFormatter extends TextInputFormatter {
  const DateTimeInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final truncated = digits.length > 14 ? digits.substring(0, 14) : digits;
    final buffer = StringBuffer();

    for (var index = 0; index < truncated.length; index++) {
      if (index == 4 || index == 6) {
        buffer.write('-');
      } else if (index == 8) {
        buffer.write(' ');
      } else if (index == 10 || index == 12) {
        buffer.write(':');
      }
      buffer.write(truncated[index]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
