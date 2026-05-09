import 'package:flutter/material.dart';

import '../app/constants/app_ui_constants.dart';
import 'app_field_box.dart';
import 'app_form_text_field.dart';

typedef AppSerialNumbersValidator = String? Function(List<String> values);

class AppSerialNumbersField extends StatelessWidget {
  const AppSerialNumbersField({
    super.key,
    required this.values,
    required this.onChanged,
    this.labelText = 'Serial Numbers',
    this.dialogTitle = 'Enter Serial Numbers',
    this.emptyText = 'No serial numbers added',
    this.enabled = true,
    this.canOpen = true,
    this.countSummaryBuilder,
    this.validator,
    this.beforeOpen,
  });

  final List<String> values;
  final ValueChanged<List<String>> onChanged;
  final String labelText;
  final String dialogTitle;
  final String emptyText;
  final bool enabled;
  final bool canOpen;
  final String Function(int count)? countSummaryBuilder;
  final AppSerialNumbersValidator? validator;
  final Future<void> Function()? beforeOpen;

  String get _summaryText {
    if (values.isEmpty) {
      return emptyText;
    }
    return countSummaryBuilder?.call(values.length) ??
        '${values.length} serial number(s) added';
  }

  Future<void> _openDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _SerialNumbersDialog(
        initialValues: values,
        dialogTitle: dialogTitle,
        editable: enabled,
        validator: validator,
        onSave: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppFieldBox(
      child: InputDecorator(
        decoration: InputDecoration(labelText: labelText),
        child: Row(
          children: [
            Expanded(child: Text(_summaryText)),
            TextButton(
              onPressed: canOpen
                  ? () async {
                      await beforeOpen?.call();
                      if (!context.mounted) {
                        return;
                      }
                      await _openDialog(context);
                    }
                  : null,
              child: const Text('Open'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SerialNumbersDialog extends StatefulWidget {
  const _SerialNumbersDialog({
    required this.initialValues,
    required this.dialogTitle,
    required this.editable,
    required this.onSave,
    this.validator,
  });

  final List<String> initialValues;
  final String dialogTitle;
  final bool editable;
  final ValueChanged<List<String>> onSave;
  final AppSerialNumbersValidator? validator;

  @override
  State<_SerialNumbersDialog> createState() => _SerialNumbersDialogState();
}

class _SerialNumbersDialogState extends State<_SerialNumbersDialog> {
  late final List<TextEditingController> _controllers;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controllers = widget.initialValues
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .map((value) => TextEditingController(text: value))
        .toList(growable: true);
    if (_controllers.isEmpty) {
      _controllers.add(TextEditingController());
    } else if (widget.editable) {
      _controllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _normalizeControllers() {
    if (!widget.editable) {
      return;
    }
    final lastFilledIndex = _controllers.lastIndexWhere(
      (controller) => controller.text.trim().isNotEmpty,
    );
    final targetCount = lastFilledIndex < 0 ? 1 : lastFilledIndex + 2;
    if (_controllers.length == targetCount) {
      return;
    }
    setState(() {
      while (_controllers.length < targetCount) {
        _controllers.add(TextEditingController());
      }
      while (_controllers.length > targetCount) {
        _controllers.removeLast().dispose();
      }
    });
  }

  void _save() {
    final normalizedValues = _controllers
        .map((controller) => controller.text.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    if (normalizedValues.isEmpty) {
      setState(() => _errorText = 'Enter at least one serial number.');
      return;
    }
    final unique = normalizedValues.map((value) => value.toLowerCase()).toSet();
    if (unique.length != normalizedValues.length) {
      setState(() => _errorText = 'Duplicate serial numbers are not allowed.');
      return;
    }
    final validationError = widget.validator?.call(normalizedValues);
    if (validationError != null && validationError.trim().isNotEmpty) {
      setState(() => _errorText = validationError);
      return;
    }
    widget.onSave(normalizedValues);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.dialogTitle),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Entered serials: ${_controllers.where((controller) => controller.text.trim().isNotEmpty).length}',
              ),
              const SizedBox(height: AppUiConstants.spacingMd),
              ...List<Widget>.generate(_controllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppUiConstants.spacingSm,
                  ),
                  child: AppFormTextField(
                    key: ValueKey('serial-$index'),
                    labelText: 'Serial ${index + 1}',
                    controller: _controllers[index],
                    readOnly: !widget.editable,
                    enabled: widget.editable,
                    onChanged: (_) {
                      if (_errorText != null) {
                        setState(() => _errorText = null);
                      }
                      _normalizeControllers();
                    },
                  ),
                );
              }),
              if (_errorText != null) ...[
                const SizedBox(height: AppUiConstants.spacingXs),
                Text(
                  _errorText!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        if (widget.editable)
          FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
