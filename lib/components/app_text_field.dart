import '../screen.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.textAlign,
  });

  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextAlign? textAlign;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  final NumericFieldFocusBinding _numericBinding = NumericFieldFocusBinding();
  bool _isNormalizingAmountZero = false;

  bool get _isNumericField =>
      NumericFieldFocusBinding.isNumericKeyboard(widget.keyboardType);

  bool get _looksLikeAmountField {
    final label = widget.label.trim().toLowerCase();
    return label.contains('amount') ||
        label.contains('balance') ||
        label.contains('paid') ||
        label.contains('credit') ||
        label.contains('debit') ||
        label.contains('value');
  }

  TextAlign get _effectiveTextAlign =>
      widget.textAlign ??
      (_looksLikeAmountField ? TextAlign.right : TextAlign.start);

  bool get _usesManagedControllerBehavior =>
      _isNumericField || _looksLikeAmountField;

  void _handleControllerChanged() {
    if (!_looksLikeAmountField || _isNormalizingAmountZero) {
      return;
    }
    final controller = widget.controller;
    if (controller == null) {
      return;
    }
    if (_numericBinding.focusNode?.hasFocus ?? false) {
      return;
    }
    final text = controller.text.trim();
    if (text.isEmpty) {
      return;
    }
    final parsed = Validators.parseFlexibleNumber(text);
    if (parsed == null || parsed != 0) {
      return;
    }
    _isNormalizingAmountZero = true;
    controller.value = const TextEditingValue(
      text: '',
      selection: TextSelection.collapsed(offset: 0),
      composing: TextRange.empty,
    );
    _isNormalizingAmountZero = false;
  }

  void _attachControllerListener(TextEditingController? controller) {
    controller?.addListener(_handleControllerChanged);
  }

  void _detachControllerListener(TextEditingController? controller) {
    controller?.removeListener(_handleControllerChanged);
  }

  @override
  void initState() {
    super.initState();
    _attachControllerListener(widget.controller);
    final created = _numericBinding.sync(
      enable: _usesManagedControllerBehavior,
      controller: widget.controller,
      clearZeroOnBlur: _looksLikeAmountField,
      onBlur: _handleControllerChanged,
    );
    _handleControllerChanged();
    if (created) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          NumericFieldFocusBinding.applyFormattedDisplay(widget.controller);
          _handleControllerChanged();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _detachControllerListener(oldWidget.controller);
      _attachControllerListener(widget.controller);
    }
    final created = _numericBinding.sync(
      enable: _usesManagedControllerBehavior,
      controller: widget.controller,
      clearZeroOnBlur: _looksLikeAmountField,
      onBlur: _handleControllerChanged,
    );
    _handleControllerChanged();
    if (created) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          NumericFieldFocusBinding.applyFormattedDisplay(widget.controller);
          _handleControllerChanged();
        }
      });
    }
  }

  @override
  void dispose() {
    _detachControllerListener(widget.controller);
    _numericBinding.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          focusNode: _numericBinding.focusNode,
          validator: widget.validator,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          textAlign: _effectiveTextAlign,
          inputFormatters: _isNumericField
              ? const <TextInputFormatter>[NumericInputFormatter()]
              : null,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: Icon(widget.icon),
            suffixIcon: widget.suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppUiConstants.fieldRadius),
            ),
          ),
        ),
      ],
    );
  }
}
