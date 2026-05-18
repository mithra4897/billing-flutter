import '../screen.dart';

enum FieldValidationType { none, email, phone, mobile }

class ValidatedFormTextField extends StatelessWidget {
  const ValidatedFormTextField({
    super.key,
    required this.labelText,
    this.validationType = FieldValidationType.none,
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
    this.isRequired = false,
  });

  final String labelText;
  final FieldValidationType validationType;
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
  final bool isRequired;

  String? Function(String?) _defaultValidator() {
    final validators = <String? Function(String?)>[];
    if (isRequired) {
      validators.add(Validators.required(labelText));
    }

    switch (validationType) {
      case FieldValidationType.none:
        break;
      case FieldValidationType.email:
        validators.add(Validators.optionalEmail(fieldName: labelText));
        break;
      case FieldValidationType.phone:
        validators.add(Validators.optionalPhone(fieldName: labelText));
        break;
      case FieldValidationType.mobile:
        validators.add(Validators.optionalMobile(fieldName: labelText));
        break;
    }

    if (validator != null) {
      validators.add(validator!);
    }

    if (validators.isEmpty) {
      return (_) => null;
    }

    return Validators.compose(validators);
  }

  TextInputType _effectiveKeyboardType() {
    if (keyboardType != null) {
      return keyboardType!;
    }

    switch (validationType) {
      case FieldValidationType.email:
        return TextInputType.emailAddress;
      case FieldValidationType.phone:
      case FieldValidationType.mobile:
        return TextInputType.phone;
      case FieldValidationType.none:
        return TextInputType.text;
    }
  }

  List<TextInputFormatter>? _effectiveInputFormatters() {
    if (inputFormatters != null) {
      return inputFormatters;
    }

    switch (validationType) {
      case FieldValidationType.mobile:
        return <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ];
      case FieldValidationType.phone:
        return <TextInputFormatter>[
          FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]')),
          LengthLimitingTextInputFormatter(20),
        ];
      case FieldValidationType.email:
      case FieldValidationType.none:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFormTextField(
      labelText: labelText,
      controller: controller,
      initialValue: initialValue,
      width: width,
      maxLines: maxLines,
      keyboardType: _effectiveKeyboardType(),
      textInputAction: textInputAction,
      obscureText: obscureText,
      validator: _defaultValidator(),
      onChanged: onChanged,
      readOnly: readOnly,
      suffixIcon: suffixIcon,
      prefixIcon: prefixIcon,
      inputFormatters: _effectiveInputFormatters(),
      textCapitalization: textCapitalization,
      hintText: hintText,
      enabled: enabled,
      allowType: allowType,
    );
  }
}
