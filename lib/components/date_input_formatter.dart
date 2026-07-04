import '../screen.dart';

class DateInputFormatter extends TextInputFormatter {
  const DateInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final truncated = digits.length > 8 ? digits.substring(0, 8) : digits;
    final format = Get.isRegistered<AppFormatSettings>()
        ? AppFormatSettings.to.dateFormat.value
        : AppFormatSettings.defaultDateFormat;
    final separator = format.contains('/')
        ? '/'
        : format.contains('-')
        ? '-'
        : '-';
    final tokens = format.split(separator);
    final tokenLengths = tokens
        .map((token) => token == 'yyyy' ? 4 : 2)
        .toList(growable: false);
    final buffer = StringBuffer();
    var digitIndex = 0;

    for (var tokenIndex = 0; tokenIndex < tokenLengths.length; tokenIndex++) {
      final tokenLength = tokenLengths[tokenIndex];
      final remaining = truncated.length - digitIndex;
      if (remaining <= 0) {
        break;
      }
      final take = remaining >= tokenLength ? tokenLength : remaining;
      buffer.write(truncated.substring(digitIndex, digitIndex + take));
      digitIndex += take;
      if (take == tokenLength &&
          digitIndex < truncated.length &&
          tokenIndex < tokenLengths.length - 1) {
        buffer.write(separator);
      }
    }

    final formatted = buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
