import 'package:flutter/widgets.dart';

import 'date_value_helper.dart';

class Validators {
  const Validators._();

  static final RegExp _emailPattern = RegExp(
    r"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$",
    caseSensitive: false,
  );
  static final RegExp _wholeNumberPattern = RegExp(r'^\d+$');
  static final RegExp _mobilePattern = RegExp(r'^[6-9]\d{9}$');
  static final RegExp _phoneAllowedCharsPattern = RegExp(r'^[0-9+\-\s()]+$');
  static final RegExp _phoneDigitPattern = RegExp(r'^\d{6,15}$');

  static double? parseFlexibleNumber(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }
    final normalized = trimmed.replaceAll(',', '');
    return double.tryParse(normalized);
  }

  static double parseControllerNumber(TextEditingController? controller) {
    return parseFlexibleNumber(controller?.text) ?? 0;
  }

  static double calculateNearestWholeRoundOff(double baseTotal) {
    return (((baseTotal.round() - baseTotal) * 100).round()) / 100;
  }

  static void syncAutoRoundOffController(
    TextEditingController controller, {
    required bool enabled,
    required double baseTotal,
  }) {
    if (!enabled) {
      return;
    }
    controller.text = calculateNearestWholeRoundOff(
      baseTotal,
    ).toStringAsFixed(2);
  }

  static String formatFlexibleNumberString(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return '';
    }
    final normalized = trimmed.replaceAll(',', '');
    if (double.tryParse(normalized) == null) {
      return trimmed;
    }

    var sign = '';
    var unsigned = normalized;
    if (unsigned.startsWith('-')) {
      sign = '-';
      unsigned = unsigned.substring(1);
    }

    final parts = unsigned.split('.');
    final integerPart = parts.first;
    final fractionalPart = parts.length > 1 ? parts.sublist(1).join('.') : '';
    final groupedInteger = _groupDigits(integerPart);
    if (fractionalPart.isEmpty) {
      return '$sign$groupedInteger';
    }
    return '$sign$groupedInteger.$fractionalPart';
  }

  static String _groupDigits(String digits) {
    if (digits.isEmpty) {
      return '0';
    }
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      final remaining = digits.length - index;
      buffer.write(digits[index]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }

  static String? Function(String?) required(String fieldName) {
    return (value) => requiredField(value, fieldName);
  }

  static String? Function(T?) requiredSelection<T>(String fieldName) {
    return (value) => requiredSelectionField(value, fieldName);
  }

  static String? Function(String?) optionalMaxLength(
    int maxLength,
    String fieldName,
  ) {
    return (value) => maxLengthField(value, maxLength, fieldName);
  }

  static String? Function(String?) optionalExactLength(
    int exactLength,
    String fieldName,
  ) {
    return (value) => exactLengthField(value, exactLength, fieldName);
  }

  static String? Function(String?) optionalDigitsExactLength(
    int exactLength,
    String fieldName,
  ) {
    return (value) => digitsExactLengthField(value, exactLength, fieldName);
  }

  static String? Function(String?) optionalNonNegativeNumber(String fieldName) {
    return (value) => nonNegativeNumberField(value, fieldName);
  }

  static String? Function(String?) optionalNonNegativeInteger(
    String fieldName,
  ) {
    return (value) => nonNegativeIntegerField(value, fieldName);
  }

  static String? Function(String?) optionalMinimumInteger(
    int minimum,
    String fieldName,
  ) {
    return (value) => minimumIntegerField(value, minimum, fieldName);
  }

  static String? Function(String?) optionalDate(String fieldName) {
    return (value) => dateField(value, fieldName);
  }

  static String? Function(String?) optionalDateTime(String fieldName) {
    return (value) => dateTimeField(value, fieldName);
  }

  static String? Function(String?) dateTime(String fieldName) {
    return optionalDateTime(fieldName);
  }

  static String? Function(String?) date(String fieldName) {
    return optionalDate(fieldName);
  }

  static String? Function(String?) optionalDateOnOrAfter(
    String fieldName,
    String Function() startDateProvider, {
    required String startFieldName,
  }) {
    return (value) => dateOnOrAfterField(
      value,
      fieldName,
      startDateProvider(),
      startFieldName: startFieldName,
    );
  }

  static String? Function(String?) optionalEmail({String fieldName = 'Email'}) {
    return (value) => emailField(value, fieldName: fieldName);
  }

  static String? Function(String?) optionalPhone({String fieldName = 'Phone'}) {
    return (value) => phoneField(value, fieldName: fieldName);
  }

  static String? Function(String?) optionalMobile({
    String fieldName = 'Mobile',
  }) {
    return (value) => mobileField(value, fieldName: fieldName);
  }

  static String? Function(String?) compose(
    List<String? Function(String?)> validators,
  ) {
    return (value) {
      for (final validator in validators) {
        final message = validator(value);
        if (message != null) {
          return message;
        }
      }

      return null;
    };
  }

  /// Required numeric field that must parse and be strictly greater than zero.
  static String? Function(String?) requiredPositiveNumber(String fieldName) {
    return (value) => requiredPositiveNumberField(value, fieldName);
  }

  static String? requiredField(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    return null;
  }

  static String? requiredSelectionField<T>(T? value, String fieldName) {
    if (value == null) {
      return '$fieldName is required';
    }

    return null;
  }

  static String? requiredSelectionOrPositiveIdField<T>(
    T? value,
    String fieldName,
  ) {
    if (value == null) {
      return '$fieldName is required';
    }
    if (value is num && value <= 0) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? dependentSelectionField<T>({
    required Object? prerequisite,
    required String prerequisiteName,
    required T? value,
    required String fieldName,
    bool treatZeroAsEmpty = false,
  }) {
    if (prerequisite == null || (prerequisite is num && prerequisite <= 0)) {
      return 'Select $prerequisiteName first';
    }
    if (value == null) {
      return '$fieldName is required';
    }
    if (treatZeroAsEmpty && value is num && value <= 0) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? requiredPositiveNumberField(String? value, String fieldName) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return '$fieldName is required';
    }
    final parsed = parseFlexibleNumber(text);
    if (parsed == null) {
      return '$fieldName must be a valid number';
    }
    if (parsed <= 0) {
      return '$fieldName must be greater than zero';
    }
    return null;
  }

  static String? maxLengthField(
    String? value,
    int maxLength,
    String fieldName,
  ) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }

    if (trimmed.length > maxLength) {
      return '$fieldName must be at most $maxLength characters';
    }

    return null;
  }

  static String? exactLengthField(
    String? value,
    int exactLength,
    String fieldName,
  ) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }

    if (trimmed.length != exactLength) {
      return '$fieldName must be exactly $exactLength characters';
    }

    return null;
  }

  static String? digitsExactLengthField(
    String? value,
    int exactLength,
    String fieldName,
  ) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }

    if (!_wholeNumberPattern.hasMatch(trimmed)) {
      return '$fieldName must contain digits only';
    }

    if (trimmed.length != exactLength) {
      return '$fieldName must be exactly $exactLength digits';
    }

    return null;
  }

  static String? nonNegativeNumberField(String? value, String fieldName) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }

    final parsed = Validators.parseFlexibleNumber(trimmed);
    if (parsed == null) {
      return '$fieldName must be a valid number';
    }

    if (parsed < 0) {
      return '$fieldName cannot be negative';
    }

    return null;
  }

  static String? nonNegativeIntegerField(String? value, String fieldName) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }

    final parsed = int.tryParse(trimmed);
    if (parsed == null) {
      return '$fieldName must be a valid whole number';
    }

    if (parsed < 0) {
      return '$fieldName cannot be negative';
    }

    return null;
  }

  static String? minimumIntegerField(
    String? value,
    int minimum,
    String fieldName,
  ) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }

    if (!_wholeNumberPattern.hasMatch(trimmed)) {
      return '$fieldName must be a whole number';
    }

    final parsed = int.tryParse(trimmed);
    if (parsed == null) {
      return '$fieldName must be a valid whole number';
    }

    if (parsed < minimum) {
      return '$fieldName must be at least $minimum';
    }

    return null;
  }

  static String? dateField(String? value, String fieldName) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }

    final parsed = parseNormalizedDateValue(trimmed);
    if (parsed == null) {
      return '$fieldName must be a valid date';
    }

    return null;
  }

  static String? dateTimeField(String? value, String fieldName) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }

    final parsed = DateTime.tryParse(trimmed);
    if (parsed == null) {
      return '$fieldName must be a valid date/time';
    }

    return null;
  }

  static String? dateOnOrAfterField(
    String? value,
    String fieldName,
    String startDate, {
    required String startFieldName,
  }) {
    final endText = value?.trim() ?? '';
    if (endText.isEmpty) {
      return null;
    }

    final endDateError = dateField(endText, fieldName);
    if (endDateError != null) {
      return endDateError;
    }

    final startText = startDate.trim();
    if (startText.isEmpty) {
      return null;
    }

    final startDateError = dateField(startText, startFieldName);
    if (startDateError != null) {
      return null;
    }

    final start = parseNormalizedDateValue(startText);
    final end = parseNormalizedDateValue(endText);

    if (start != null && end != null && end.isBefore(start)) {
      return '$fieldName must be on or after $startFieldName';
    }

    return null;
  }

  static String? emailField(String? value, {String fieldName = 'Email'}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }

    if (!_emailPattern.hasMatch(trimmed)) {
      return '$fieldName is invalid';
    }

    return null;
  }

  static String? phoneField(String? value, {String fieldName = 'Phone'}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }

    if (!_phoneAllowedCharsPattern.hasMatch(trimmed)) {
      return '$fieldName is invalid';
    }

    final digitsOnly = trimmed.replaceAll(RegExp(r'\D'), '');
    if (!_phoneDigitPattern.hasMatch(digitsOnly)) {
      return '$fieldName must contain 6 to 15 digits';
    }

    return null;
  }

  static String? mobileField(String? value, {String fieldName = 'Mobile'}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }

    if (!_mobilePattern.hasMatch(trimmed)) {
      return '$fieldName must be a valid 10-digit mobile number';
    }

    return null;
  }
}

/// Optional 0–100 (inclusive), for percentage fields aligned with Laravel `numeric|min:0|max:100`.
/// Top-level so it is always visible alongside [Validators] (same library as `screen.dart` export).
String? Function(String?) percentField0To100Optional(String fieldName) {
  return (String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }
    final parsed = Validators.parseFlexibleNumber(trimmed);
    if (parsed == null) {
      return '$fieldName must be a valid number';
    }
    if (parsed < 0 || parsed > 100) {
      return '$fieldName must be between 0 and 100';
    }
    return null;
  };
}
