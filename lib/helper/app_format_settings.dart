import '../screen.dart';

class AppFormatSettings extends GetxController {
  AppFormatSettings._();

  static AppFormatSettings get to => Get.find<AppFormatSettings>();

  final RxString dateFormat = 'dd/MM/yyyy'.obs;
  final RxString amountGrouping = 'indian'.obs;
  final RxInt decimalPlaces = 2.obs;

  static const List<AppDropdownItem<String>> dateFormatItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'dd/MM/yyyy', label: 'DD/MM/YYYY  (04/07/2026)'),
        AppDropdownItem(value: 'MM/dd/yyyy', label: 'MM/DD/YYYY  (07/04/2026)'),
        AppDropdownItem(value: 'yyyy-MM-dd', label: 'YYYY-MM-DD  (2026-07-04)'),
        AppDropdownItem(value: 'dd-MM-yyyy', label: 'DD-MM-YYYY  (04-07-2026)'),
        AppDropdownItem(value: 'MM-dd-yyyy', label: 'MM-DD-YYYY  (07-04-2026)'),
        AppDropdownItem(value: 'yyyy/MM/dd', label: 'YYYY/MM/DD  (2026/07/04)'),
      ];

  static const List<AppDropdownItem<String>> amountGroupingItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'indian', label: 'Indian (2,3)  — 1,23,456'),
        AppDropdownItem(value: 'us', label: 'International (3,3)  — 123,456'),
        AppDropdownItem(value: 'none', label: 'None  — 123456'),
      ];

  static const List<AppDropdownItem<int>> decimalPlacesItems =
      <AppDropdownItem<int>>[
        AppDropdownItem(value: 0, label: '0 decimals  — 1234'),
        AppDropdownItem(value: 2, label: '2 decimals  — 1234.00'),
        AppDropdownItem(value: 3, label: '3 decimals  — 1234.000'),
      ];

  static AppFormatSettings ensureRegistered() {
    if (!Get.isRegistered<AppFormatSettings>()) {
      Get.put<AppFormatSettings>(AppFormatSettings._(), permanent: true);
    }
    return Get.find<AppFormatSettings>();
  }

  void applyFromCompany(CompanyModel company) {
    dateFormat.value = company.dateFormat ?? 'dd/MM/yyyy';
    amountGrouping.value = company.amountGrouping ?? 'indian';
    decimalPlaces.value = company.decimalPlaces ?? 2;
  }

  void setDateFormat(String? value) {
    if (value != null) dateFormat.value = value;
  }

  void setAmountGrouping(String? value) {
    if (value != null) amountGrouping.value = value;
  }

  void setDecimalPlaces(int? value) {
    if (value != null) decimalPlaces.value = value;
  }
}

String displayDate(String? value) {
  if (value == null || value.trim().isEmpty) return '';
  final raw = value.split('T').first.split(' ').first.trim();
  if (raw.isEmpty) return '';

  final parts = raw.split('-');
  if (parts.length != 3) return raw;
  final year = parts[0];
  final month = parts[1];
  final day = parts[2];

  final fmt = Get.isRegistered<AppFormatSettings>()
      ? AppFormatSettings.to.dateFormat.value
      : 'dd/MM/yyyy';

  return fmt
      .replaceAll('yyyy', year)
      .replaceAll('MM', month)
      .replaceAll('dd', day);
}

String formatAmount(double? value) {
  if (value == null) return '-';

  final settings = Get.isRegistered<AppFormatSettings>()
      ? AppFormatSettings.to
      : null;

  final decimals = settings?.decimalPlaces.value ?? 2;
  final grouping = settings?.amountGrouping.value ?? 'indian';

  final fixed = value.toStringAsFixed(decimals);
  final dotIndex = fixed.indexOf('.');
  final intPart = dotIndex >= 0 ? fixed.substring(0, dotIndex) : fixed;
  final decPart = dotIndex >= 0 ? fixed.substring(dotIndex) : '';

  final isNegative = intPart.startsWith('-');
  final digits = isNegative ? intPart.substring(1) : intPart;

  final grouped = _groupDigits(digits, grouping);
  return '${isNegative ? '-' : ''}$grouped$decPart';
}

String _groupDigits(String digits, String grouping) {
  if (grouping == 'none' || digits.length <= 3) return digits;

  if (grouping == 'indian') {
    if (digits.length <= 3) return digits;
    final last3 = digits.substring(digits.length - 3);
    final rest = digits.substring(0, digits.length - 3);
    final buffer = StringBuffer();
    for (int i = 0; i < rest.length; i++) {
      if (i > 0 && (rest.length - i) % 2 == 0) buffer.write(',');
      buffer.write(rest[i]);
    }
    return '${buffer.toString()},$last3';
  }

  final buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
