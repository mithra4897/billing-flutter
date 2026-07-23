import '../screen.dart';

class AppFormTextField extends StatefulWidget {
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
    this.onFieldSubmitted,
    this.onEditingComplete,
    this.readOnly = false,
    this.suffixIcon,
    this.prefixIcon,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.hintText,
    this.enabled,
    this.allowType = true,
    this.textAlign,
    this.numericDisplayKind,
    this.quantityAllowsFraction,
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
  final ValueChanged<String>? onFieldSubmitted;
  final VoidCallback? onEditingComplete;
  final bool readOnly;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final String? hintText;
  final bool? enabled;
  final bool allowType;
  final TextAlign? textAlign;
  final AppNumericDisplayKind? numericDisplayKind;
  final bool? quantityAllowsFraction;

  @override
  State<AppFormTextField> createState() => _AppFormTextFieldState();
}

class _AppFormTextFieldState extends State<AppFormTextField> {
  final NumericFieldFocusBinding _numericBinding = NumericFieldFocusBinding();
  TextEditingController? _displayController;
  String? _pendingDisplayValue;
  bool _isNormalizingAmountZero = false;

  bool get _isAutoDateField =>
      !widget.readOnly &&
      widget.enabled != false &&
      widget.controller != null &&
      (widget.inputFormatters?.any(
            (formatter) => formatter is DateInputFormatter,
          ) ??
          false);

  bool get _isAutoDateTimeField =>
      !widget.readOnly &&
      widget.enabled != false &&
      widget.controller != null &&
      (widget.inputFormatters?.any(
            (formatter) => formatter is DateTimeInputFormatter,
          ) ??
          false);

  String? get _effectiveHintText {
    if (widget.hintText != null && widget.hintText!.trim().isNotEmpty) {
      return widget.hintText;
    }
    if (_isAutoDateTimeField) {
      final format = Get.isRegistered<AppFormatSettings>()
          ? AppFormatSettings.to.dateFormat.value
          : AppFormatSettings.defaultDateFormat;
      return '${format.replaceAll('yyyy', 'YYYY').replaceAll('dd', 'DD')} HH:MM:SS';
    }
    if (_isAutoDateField) {
      final format = Get.isRegistered<AppFormatSettings>()
          ? AppFormatSettings.to.dateFormat.value
          : AppFormatSettings.defaultDateFormat;
      return format.replaceAll('yyyy', 'YYYY').replaceAll('dd', 'DD');
    }
    return widget.hintText;
  }

  bool get _isNumericField =>
      NumericFieldFocusBinding.isNumericKeyboard(widget.keyboardType);

  bool get _looksLikeAmountField {
    final label = widget.labelText.trim().toLowerCase();
    return label.contains('amount') ||
        label.contains('balance') ||
        label.contains('paid') ||
        label.contains('credit') ||
        label.contains('debit') ||
        label.contains('value');
  }

  AppNumericDisplayKind? get _inferredNumericDisplayKind {
    final probe = '${widget.labelText} ${widget.hintText ?? ''}'
        .trim()
        .toLowerCase();
    if (probe.isEmpty) {
      return null;
    }
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
    return _isNumericField && widget.keyboardType?.decimal == true
        ? AppNumericDisplayKind.generic
        : null;
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

  bool get _useSanitizedReadOnlyDisplay =>
      (widget.readOnly || widget.enabled == false) &&
      (widget.controller != null || widget.initialValue != null);

  String _sanitizedReadOnlyValue(String? rawValue) {
    final raw = (rawValue ?? '').trim();
    if (raw.isEmpty || raw == '-') {
      return '';
    }
    if (_effectiveNumericDisplayKind != null) {
      final formatted = _formatNumericDisplay(raw);
      if (_looksLikeAmountField) {
        final parsed = Validators.parseFlexibleNumber(formatted);
        if (parsed != null && parsed == 0) {
          return '';
        }
      }
      return formatted;
    }
    if (_looksLikeAmountField) {
      final parsed = Validators.parseFlexibleNumber(raw);
      if (parsed != null && parsed == 0) {
        return '';
      }
    }
    return raw;
  }

  String? _sanitizedEditableInitialValue(String? rawValue) {
    if (!_looksLikeAmountField) {
      return rawValue;
    }
    final raw = (rawValue ?? '').trim();
    if (raw.isEmpty) {
      return rawValue;
    }
    final parsed = Validators.parseFlexibleNumber(raw);
    if (parsed != null && parsed == 0) {
      return '';
    }
    return rawValue;
  }

  void _disposeDisplayControllerDeferred(TextEditingController? controller) {
    if (controller == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });
  }

  void _applyPendingDisplayValue() {
    final controller = _displayController;
    final nextValue = _pendingDisplayValue;
    if (controller == null ||
        nextValue == null ||
        controller.text == nextValue) {
      _pendingDisplayValue = null;
      return;
    }
    controller.value = controller.value.copyWith(
      text: nextValue,
      selection: TextSelection.collapsed(offset: nextValue.length),
      composing: TextRange.empty,
    );
    _pendingDisplayValue = null;
  }

  void _syncDisplayController({bool allowImmediateUpdate = false}) {
    if (!_useSanitizedReadOnlyDisplay) {
      final previousController = _displayController;
      _displayController = null;
      _pendingDisplayValue = null;
      _disposeDisplayControllerDeferred(previousController);
      return;
    }
    final nextValue = _sanitizedReadOnlyValue(
      widget.controller?.text ?? widget.initialValue,
    );
    _displayController ??= TextEditingController(text: nextValue);
    if (_displayController!.text == nextValue) {
      _pendingDisplayValue = null;
      return;
    }
    if (allowImmediateUpdate) {
      _displayController!.value = _displayController!.value.copyWith(
        text: nextValue,
        selection: TextSelection.collapsed(offset: nextValue.length),
        composing: TextRange.empty,
      );
      _pendingDisplayValue = null;
      return;
    }
    _pendingDisplayValue = nextValue;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _applyPendingDisplayValue();
      }
    });
  }

  List<TextInputFormatter>? _effectiveInputFormatters() {
    final formatters = <TextInputFormatter>[
      if (_isNumericField) const NumericInputFormatter(),
      ...?widget.inputFormatters,
    ];
    return formatters.isEmpty ? null : formatters;
  }

  void _handleControllerChanged() {
    if (_useSanitizedReadOnlyDisplay) {
      _syncDisplayController(allowImmediateUpdate: true);
      return;
    }
    _clearAmountZeroIfNeeded();
  }

  void _clearAmountZeroIfNeeded() {
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
    _syncDisplayController(allowImmediateUpdate: true);
    _attachControllerListener(widget.controller);
    final numericController = _useSanitizedReadOnlyDisplay
        ? _displayController
        : widget.controller;
    final created = _numericBinding.sync(
      enable: _usesManagedControllerBehavior,
      controller: numericController,
      clearZeroOnBlur: _looksLikeAmountField,
      onBlur: _handleControllerChanged,
      formatter: _formatNumericDisplay,
    );
    _clearAmountZeroIfNeeded();
    if (created) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          NumericFieldFocusBinding.applyFormattedDisplay(
            numericController,
            formatter: _formatNumericDisplay,
          );
          _clearAmountZeroIfNeeded();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant AppFormTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncDisplayController();
    if (oldWidget.controller != widget.controller) {
      _detachControllerListener(oldWidget.controller);
      _attachControllerListener(widget.controller);
    }
    final numericController = _useSanitizedReadOnlyDisplay
        ? _displayController
        : widget.controller;
    final created = _numericBinding.sync(
      enable: _usesManagedControllerBehavior,
      controller: numericController,
      clearZeroOnBlur: _looksLikeAmountField,
      onBlur: _handleControllerChanged,
      formatter: _formatNumericDisplay,
    );
    _clearAmountZeroIfNeeded();
    if (created) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          NumericFieldFocusBinding.applyFormattedDisplay(
            numericController,
            formatter: _formatNumericDisplay,
          );
          _clearAmountZeroIfNeeded();
        }
      });
    }
  }

  @override
  void dispose() {
    _detachControllerListener(widget.controller);
    _numericBinding.dispose();
    _displayController?.dispose();
    super.dispose();
  }

  Future<void> _handlePickerTap(BuildContext context) async {
    if (_isAutoDateField) {
      final now = DateTime.now();
      final picked = await showAppDatePickerDialog(
        context: context,
        initialDate: tryParseCalendarDate(widget.controller!.text) ?? now,
        firstDate: appCalendarFirstDate(now),
        lastDate: appCalendarLastDate(now),
        title: 'Select ${widget.labelText}',
      );
      if (picked == null) {
        return;
      }
      widget.controller!.text = formatCalendarDate(picked);
      widget.onChanged?.call(widget.controller!.text);
      return;
    }

    if (_isAutoDateTimeField) {
      final now = DateTime.now();
      final picked = await showAppDateTimePickerDialog(
        context: context,
        initialDate: tryParseCalendarDateTime(widget.controller!.text) ?? now,
        firstDate: appCalendarFirstDate(now),
        lastDate: appCalendarLastDate(now),
        dateTitle: 'Select ${widget.labelText}',
        timeTitle: 'Select ${widget.labelText} Time',
      );
      if (picked == null) {
        return;
      }
      widget.controller!.text = formatCalendarDateTime(picked);
      widget.onChanged?.call(widget.controller!.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final autoPickerEnabled = _isAutoDateField || _isAutoDateTimeField;
    final visuallyReadOnly = widget.enabled == false;
    final effectiveReadOnly =
        widget.readOnly ||
        visuallyReadOnly ||
        (autoPickerEnabled && !widget.allowType);
    final effectiveController = _useSanitizedReadOnlyDisplay
        ? _displayController
        : widget.controller;
    final effectiveInitialValue = _useSanitizedReadOnlyDisplay
        ? _sanitizedReadOnlyValue(widget.initialValue)
        : _sanitizedEditableInitialValue(widget.initialValue);

    return AppFieldBox(
      width: widget.width,
      child: TextFormField(
        key: effectiveController != null
            ? ObjectKey(effectiveController)
            : null,
        controller: effectiveController,
        focusNode: _numericBinding.focusNode,
        initialValue: effectiveController == null
            ? effectiveInitialValue
            : null,
        maxLines: widget.maxLines,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        obscureText: widget.obscureText,
        validator: widget.validator,
        onChanged: widget.onChanged,
        onFieldSubmitted: widget.onFieldSubmitted,
        onEditingComplete: widget.onEditingComplete,
        readOnly: effectiveReadOnly,
        enabled: true,
        textAlign: _effectiveTextAlign,
        onTap: (!visuallyReadOnly && autoPickerEnabled && !widget.allowType)
            ? () => _handlePickerTap(context)
            : null,
        inputFormatters: _effectiveInputFormatters(),
        textCapitalization: widget.textCapitalization,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: _effectiveHintText,
          alignLabelWithHint: widget.maxLines > 1,
          prefixIcon: widget.prefixIcon,
          suffixIcon:
              widget.suffixIcon ??
              (autoPickerEnabled
                  ? (!visuallyReadOnly && widget.allowType
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
