import '../screen.dart';

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
    final dateFormat = Get.isRegistered<AppFormatSettings>()
        ? AppFormatSettings.to.dateFormat.value
        : AppFormatSettings.defaultDateFormat;
    final separatorMatch = RegExp(r'[^A-Za-z]').firstMatch(dateFormat);
    final separator = separatorMatch?.group(0) ?? '/';
    final dateTokens = dateFormat.split(separator);
    final tokenLengths = dateTokens
        .map((token) => token == 'yyyy' ? 4 : 2)
        .toList(growable: false);

    var digitIndex = 0;
    for (var tokenIndex = 0; tokenIndex < tokenLengths.length; tokenIndex++) {
      final length = tokenLengths[tokenIndex];
      for (var offset = 0;
          offset < length && digitIndex < truncated.length;
          offset++) {
        buffer.write(truncated[digitIndex++]);
      }
      if (tokenIndex < tokenLengths.length - 1 &&
          digitIndex < truncated.length) {
        buffer.write(separator);
      }
    }
    if (digitIndex < truncated.length) {
      buffer.write(' ');
    }
    while (digitIndex < truncated.length) {
      final timeIndex = digitIndex - tokenLengths.fold<int>(0, (a, b) => a + b);
      if ((timeIndex == 2 || timeIndex == 4) && timeIndex < 6) {
        buffer.write(':');
      }
      buffer.write(truncated[digitIndex++]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
