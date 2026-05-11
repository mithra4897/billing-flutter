import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_field_box.dart';
import 'decimal_input_formatter.dart';

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

  List<TextInputFormatter>? _effectiveInputFormatters() {
    final formatters = <TextInputFormatter>[
      ...?inputFormatters,
    ];

    final usesDecimalKeyboard = keyboardType is TextInputType &&
        (keyboardType as TextInputType).decimal == true;
    final usesSignedKeyboard = keyboardType is TextInputType &&
        (keyboardType as TextInputType).signed == true;

    if (usesDecimalKeyboard &&
        !formatters.any((item) => item is DecimalInputFormatter)) {
      formatters.insert(
        0,
        DecimalInputFormatter(allowSigned: usesSignedKeyboard),
      );
    }

    return formatters.isEmpty ? null : formatters;
  }

  @override
  Widget build(BuildContext context) {
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
        readOnly: readOnly,
        enabled: enabled,
        inputFormatters: _effectiveInputFormatters(),
        textCapitalization: textCapitalization,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          alignLabelWithHint: maxLines > 1,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
