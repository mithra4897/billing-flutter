import 'package:flutter/material.dart';

import 'app_calendar_picker.dart';
import 'app_form_text_field.dart';
import 'date_input_formatter.dart';
import '../app/constants/app_ui_constants.dart';

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
  });

  final String labelText;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool? enabled;
  final String? hintText;
  final double? width;
  final DateTime? firstDate;
  final DateTime? lastDate;

  DateTime get _effectiveFirstDate =>
      firstDate ?? DateTime(DateTime.now().year - 10);

  DateTime get _effectiveLastDate =>
      lastDate ?? DateTime(DateTime.now().year + 10, 12, 31);

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
      hintText: hintText ?? 'YYYY-MM-DD',
      keyboardType: TextInputType.datetime,
      inputFormatters: const [DateInputFormatter()],
      validator: validator,
      suffixIcon: GestureDetector(
        onTap: () => _openPicker(context),
        child: const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppUiConstants.spacingSm,
          ),
          child: Icon(Icons.calendar_month_outlined, size: 18),
        ),
      ),
    );
  }
}
