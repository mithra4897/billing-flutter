import '../screen.dart';

class AppDateField extends StatelessWidget {
  const AppDateField({
    super.key,
    required this.labelText,
    required this.controller,
    this.validator,
    this.enabled,
    this.hintText,
    this.width,
    this.firstDate,
    this.lastDate,
    this.allowType = true,
    this.showClearButton = false,
  });

  final String labelText;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool? enabled;
  final String? hintText;
  final double? width;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool allowType;
  final bool showClearButton;

  String get _dateHint {
    final format = Get.isRegistered<AppFormatSettings>()
        ? AppFormatSettings.to.dateFormat.value
        : AppFormatSettings.defaultDateFormat;
    return format.replaceAll('yyyy', 'YYYY').replaceAll('dd', 'DD');
  }

  DateTime get _effectiveFirstDate => firstDate ?? appCalendarFirstDate();

  DateTime get _effectiveLastDate => lastDate ?? appCalendarLastDate();

  DateTime get _initialPickerDate {
    final parsed = tryParseCalendarDate(controller.text);
    if (parsed == null) {
      return DateTime.now();
    }
    if (parsed.isBefore(_effectiveFirstDate)) return _effectiveFirstDate;
    if (parsed.isAfter(_effectiveLastDate)) return _effectiveLastDate;
    return parsed;
  }

  Future<void> _openPicker(BuildContext context) async {
    if (enabled == false) return;
    final picked = await showAppDatePickerDialog(
      context: context,
      initialDate: _initialPickerDate,
      firstDate: _effectiveFirstDate,
      lastDate: _effectiveLastDate,
      title: 'Select $labelText',
    );
    if (picked != null) {
      controller.text = formatCalendarDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFormTextField(
      labelText: labelText,
      controller: controller,
      width: width,
      enabled: enabled,
      hintText: hintText ?? _dateHint,
      keyboardType: TextInputType.datetime,
      inputFormatters: const [DateInputFormatter()],
      validator: validator,
      allowType: allowType,
      suffixIcon: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showClearButton && value.text.trim().isNotEmpty)
              IconButton(
                tooltip: 'Clear $labelText',
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                onPressed: controller.clear,
                icon: const Icon(Icons.close),
              ),
            IconButton(
              tooltip: 'Select $labelText',
              visualDensity: VisualDensity.compact,
              iconSize: 18,
              onPressed: () => _openPicker(context),
              icon: const Icon(Icons.calendar_month_outlined),
            ),
          ],
        ),
      ),
    );
  }
}
