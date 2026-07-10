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
    this.numericDisplayKind,
    this.quantityAllowsFraction,
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
  final AppNumericDisplayKind? numericDisplayKind;
  final bool? quantityAllowsFraction;

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

  AppNumericDisplayKind? get _inferredNumericDisplayKind {
    final probe = '${widget.label} ${widget.hint}'.trim().toLowerCase();
    if (probe.contains('qty') || probe.contains('quantity')) {
      return AppNumericDisplayKind.quantity;
    }
    if (probe.contains('discount')) {
      return AppNumericDisplayKind.discountPercent;
    }
    if (probe.contains('%') || probe.contains('percent')) {
      return AppNumericDisplayKind.percent;
    }
    if (probe.contains('rate') ||
        probe.contains('price') ||
        probe.contains('cost')) {
      return AppNumericDisplayKind.rate;
    }
    if (_looksLikeAmountField || probe.contains('total')) {
      return AppNumericDisplayKind.amount;
    }
    return _isNumericField ? AppNumericDisplayKind.generic : null;
  }

  AppNumericDisplayKind? get _effectiveNumericDisplayKind =>
      widget.numericDisplayKind ?? _inferredNumericDisplayKind;

  bool get _effectiveQuantityAllowsFraction =>
      widget.quantityAllowsFraction ?? true;

  String _formatNumericDisplay(String rawValue) {
    final kind = _effectiveNumericDisplayKind;
    if (kind == null) {
      return Validators.formatFlexibleNumberString(rawValue);
    }
    return formatNumericText(
      rawValue,
      kind: kind,
      quantityAllowsFraction: _effectiveQuantityAllowsFraction,
    );
  }

  TextAlign get _effectiveTextAlign =>
      widget.textAlign ??
      ((_isNumericField || _looksLikeAmountField)
          ? TextAlign.right
          : TextAlign.start);

  bool get _usesManagedControllerBehavior =>
      _effectiveNumericDisplayKind != null || _looksLikeAmountField;

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
      formatter: _formatNumericDisplay,
    );
    _handleControllerChanged();
    if (created) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          NumericFieldFocusBinding.applyFormattedDisplay(
            widget.controller,
            formatter: _formatNumericDisplay,
          );
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
      formatter: _formatNumericDisplay,
    );
    _handleControllerChanged();
    if (created) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          NumericFieldFocusBinding.applyFormattedDisplay(
            widget.controller,
            formatter: _formatNumericDisplay,
          );
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
