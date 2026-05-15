import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_calendar_picker.dart';
import 'app_field_box.dart';
import 'date_input_formatter.dart';
import 'date_time_input_formatter.dart';

class AppFormTextField extends StatelessWidget {
  const AppFormTextField({
    super.key,
    required this.labelText,
    this.controller,
    this.initialValue,
    this.width,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.readOnly = false,
    this.suffixIcon,
    this.prefixIcon,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.hintText,
    this.enabled,
    this.allowType = true,
  });

  final String labelText;
  final TextEditingController? controller;
  final String? initialValue;
  final double? width;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final String? hintText;
  final bool? enabled;
  final bool allowType;

  bool get _isAutoDateField =>
      !readOnly &&
      enabled != false &&
      controller != null &&
      (inputFormatters?.any((formatter) => formatter is DateInputFormatter) ??
          false);

  bool get _isAutoDateTimeField =>
      !readOnly &&
      enabled != false &&
      controller != null &&
      (inputFormatters?.any(
            (formatter) => formatter is DateTimeInputFormatter,
          ) ??
          false);

  Future<void> _handlePickerTap(BuildContext context) async {
    if (_isAutoDateField) {
      final now = DateTime.now();
      final picked = await showAppDatePickerDialog(
        context: context,
        initialDate: tryParseCalendarDate(controller!.text) ?? now,
        firstDate: DateTime(now.year - 10, 1, 1),
        lastDate: DateTime(now.year + 10, 12, 31),
        title: 'Select $labelText',
      );
      if (picked == null) {
        return;
      }
      controller!.text = formatCalendarDate(picked);
      onChanged?.call(controller!.text);
      return;
    }

    if (_isAutoDateTimeField) {
      final now = DateTime.now();
      final picked = await showAppDateTimePickerDialog(
        context: context,
        initialDate: tryParseCalendarDateTime(controller!.text) ?? now,
        firstDate: DateTime(now.year - 10, 1, 1),
        lastDate: DateTime(now.year + 10, 12, 31),
        dateTitle: 'Select $labelText',
        timeTitle: 'Select $labelText Time',
      );
      if (picked == null) {
        return;
      }
      controller!.text = formatCalendarDateTime(picked);
      onChanged?.call(controller!.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final autoPickerEnabled = _isAutoDateField || _isAutoDateTimeField;
    final visuallyReadOnly = enabled == false;
    final effectiveReadOnly =
        readOnly || visuallyReadOnly || (autoPickerEnabled && !allowType);

    return AppFieldBox(
      width: width,
      child: TextFormField(
        controller: controller,
        initialValue: controller == null ? initialValue : null,
        maxLines: maxLines,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        obscureText: obscureText,
        validator: validator,
        onChanged: onChanged,
        readOnly: effectiveReadOnly,
        enabled: true,
        onTap: (!visuallyReadOnly && autoPickerEnabled && !allowType)
            ? () => _handlePickerTap(context)
            : null,
        inputFormatters: inputFormatters,
        textCapitalization: textCapitalization,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          alignLabelWithHint: maxLines > 1,
          prefixIcon: prefixIcon,
          suffixIcon:
              suffixIcon ??
              (autoPickerEnabled
                  ? (!visuallyReadOnly && allowType
                        ? MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => _handlePickerTap(context),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                ),
                                child: Icon(
                                  _isAutoDateTimeField
                                      ? Icons.schedule_outlined
                                      : Icons.calendar_month_outlined,
                                  size: 18,
                                ),
                              ),
                            ),
                          )
                        : Icon(
                            _isAutoDateTimeField
                                ? Icons.schedule_outlined
                                : Icons.calendar_month_outlined,
                          ))
                  : null),
        ),
      ),
    );
  }
}
