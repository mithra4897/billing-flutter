import 'package:flutter/material.dart';

import '../app/constants/app_ui_constants.dart';
import 'app_form_text_field.dart';

Future<DateTimeRange?> showAppDateRangePickerDialog({
  required BuildContext context,
  required DateTimeRange initialRange,
  required DateTime firstDate,
  required DateTime lastDate,
  String title = 'Select Custom Range',
}) {
  return showDialog<DateTimeRange>(
    context: context,
    builder: (dialogContext) => AppDateRangePickerDialog(
      title: title,
      initialRange: initialRange,
      firstDate: firstDate,
      lastDate: lastDate,
    ),
  );
}

Future<DateTime?> showAppDatePickerDialog({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String title = 'Select Date',
}) {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    helpText: title,
  );
}

Future<DateTime?> showAppDateTimePickerDialog({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String dateTitle = 'Select Date',
  String timeTitle = 'Select Time',
}) async {
  final selectedDate = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    helpText: dateTitle,
  );
  if (selectedDate == null || !context.mounted) {
    return null;
  }

  final selectedTime = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initialDate),
    helpText: timeTitle,
  );
  if (selectedTime == null) {
    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      initialDate.hour,
      initialDate.minute,
      initialDate.second,
    );
  }

  return DateTime(
    selectedDate.year,
    selectedDate.month,
    selectedDate.day,
    selectedTime.hour,
    selectedTime.minute,
    initialDate.second,
  );
}

class AppDateRangePickerDialog extends StatefulWidget {
  const AppDateRangePickerDialog({
    super.key,
    required this.title,
    required this.initialRange,
    required this.firstDate,
    required this.lastDate,
  });

  final String title;
  final DateTimeRange initialRange;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<AppDateRangePickerDialog> createState() =>
      _AppDateRangePickerDialogState();
}

class _AppDateRangePickerDialogState extends State<AppDateRangePickerDialog> {
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    _start = widget.initialRange.start;
    _end = widget.initialRange.end;
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 980;

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920),
        child: Padding(
          padding: const EdgeInsets.all(AppUiConstants.cardPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppUiConstants.spacingXs),
              Text(
                '${formatCalendarDate(_start)} - ${formatCalendarDate(_end)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppUiConstants.spacingMd),
              Flexible(
                child: isCompact
                    ? SingleChildScrollView(
                        child: Column(
                          children: [
                            _AppCalendarPane(
                              label: 'Start Date',
                              selectedDate: _start,
                              firstDate: widget.firstDate,
                              lastDate: widget.lastDate,
                              onChanged: (value) {
                                setState(() {
                                  _start = value;
                                  if (_end.isBefore(_start)) {
                                    _end = _start;
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: AppUiConstants.spacingMd),
                            _AppCalendarPane(
                              label: 'End Date',
                              selectedDate: _end,
                              firstDate: widget.firstDate,
                              lastDate: widget.lastDate,
                              onChanged: (value) {
                                setState(() {
                                  _end = value.isBefore(_start)
                                      ? _start
                                      : value;
                                });
                              },
                            ),
                          ],
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _AppCalendarPane(
                            label: 'Start Date',
                            selectedDate: _start,
                            firstDate: widget.firstDate,
                            lastDate: widget.lastDate,
                            onChanged: (value) {
                              setState(() {
                                _start = value;
                                if (_end.isBefore(_start)) {
                                  _end = _start;
                                }
                              });
                            },
                          ),
                          const SizedBox(width: AppUiConstants.spacingMd),
                          _AppCalendarPane(
                            label: 'End Date',
                            selectedDate: _end,
                            firstDate: widget.firstDate,
                            lastDate: widget.lastDate,
                            onChanged: (value) {
                              setState(() {
                                _end = value.isBefore(_start) ? _start : value;
                              });
                            },
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: AppUiConstants.spacingMd),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppUiConstants.spacingSm),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pop(DateTimeRange(start: _start, end: _end));
                    },
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppDateSelectorField extends StatelessWidget {
  const AppDateSelectorField({
    super.key,
    required this.labelText,
    required this.controller,
    required this.onTap,
    this.width,
    this.validator,
    this.enabled,
    this.hintText,
  });

  final String labelText;
  final TextEditingController controller;
  final Future<void> Function() onTap;
  final double? width;
  final String? Function(String?)? validator;
  final bool? enabled;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled == false ? null : onTap,
      child: AbsorbPointer(
        child: AppFormTextField(
          labelText: labelText,
          controller: controller,
          width: width,
          readOnly: true,
          enabled: enabled,
          validator: validator,
          hintText: hintText,
          suffixIcon: const Icon(Icons.calendar_month_outlined),
        ),
      ),
    );
  }
}

class AppDateTimeSelectorField extends StatelessWidget {
  const AppDateTimeSelectorField({
    super.key,
    required this.labelText,
    required this.controller,
    required this.onTap,
    this.width,
    this.validator,
    this.enabled,
    this.hintText,
  });

  final String labelText;
  final TextEditingController controller;
  final Future<void> Function() onTap;
  final double? width;
  final String? Function(String?)? validator;
  final bool? enabled;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled == false ? null : onTap,
      child: AbsorbPointer(
        child: AppFormTextField(
          labelText: labelText,
          controller: controller,
          width: width,
          readOnly: true,
          enabled: enabled,
          validator: validator,
          hintText: hintText,
          suffixIcon: const Icon(Icons.schedule_outlined),
        ),
      ),
    );
  }
}

class _AppCalendarPane extends StatelessWidget {
  const _AppCalendarPane({
    required this.label,
    required this.selectedDate,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
  });

  final String label;
  final DateTime selectedDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppUiConstants.spacingSm),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppUiConstants.buttonRadius),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.16),
              ),
            ),
            padding: const EdgeInsets.all(AppUiConstants.spacingSm),
            child: CalendarDatePicker(
              initialDate: selectedDate,
              firstDate: firstDate,
              lastDate: lastDate,
              onDateChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

String formatCalendarDate(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

String formatCalendarDateTime(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  final second = value.second.toString().padLeft(2, '0');
  return '${value.year}-$month-$day $hour:$minute:$second';
}

DateTime? tryParseCalendarDate(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return DateTime.tryParse(trimmed);
}

DateTime? tryParseCalendarDateTime(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return DateTime.tryParse(trimmed);
}
