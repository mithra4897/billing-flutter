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

  @override
  State<AppFormTextField> createState() => _AppFormTextFieldState();
}

class _AppFormTextFieldState extends State<AppFormTextField> {
  final NumericFieldFocusBinding _numericBinding = NumericFieldFocusBinding();

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

  bool get _isNumericField =>
      NumericFieldFocusBinding.isNumericKeyboard(widget.keyboardType);

  List<TextInputFormatter>? _effectiveInputFormatters() {
    final formatters = <TextInputFormatter>[
      if (_isNumericField) const NumericInputFormatter(),
      ...?widget.inputFormatters,
    ];
    return formatters.isEmpty ? null : formatters;
  }

  @override
  void initState() {
    super.initState();
    final created = _numericBinding.sync(
      enable: _isNumericField,
      controller: widget.controller,
    );
    if (created) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          NumericFieldFocusBinding.applyFormattedDisplay(widget.controller);
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant AppFormTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final created = _numericBinding.sync(
      enable: _isNumericField,
      controller: widget.controller,
    );
    if (created) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          NumericFieldFocusBinding.applyFormattedDisplay(widget.controller);
        }
      });
    }
  }

  @override
  void dispose() {
    _numericBinding.dispose();
    super.dispose();
  }

  Future<void> _handlePickerTap(BuildContext context) async {
    if (_isAutoDateField) {
      final now = DateTime.now();
      final picked = await showAppDatePickerDialog(
        context: context,
        initialDate: tryParseCalendarDate(widget.controller!.text) ?? now,
        firstDate: DateTime(now.year - 10, 1, 1),
        lastDate: DateTime(now.year + 10, 12, 31),
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
        firstDate: DateTime(now.year - 10, 1, 1),
        lastDate: DateTime(now.year + 10, 12, 31),
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

    return AppFieldBox(
      width: widget.width,
      child: TextFormField(
        key: widget.controller != null ? ObjectKey(widget.controller) : null,
        controller: widget.controller,
        focusNode: _numericBinding.focusNode,
        initialValue: widget.controller == null ? widget.initialValue : null,
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
        onTap: (!visuallyReadOnly && autoPickerEnabled && !widget.allowType)
            ? () => _handlePickerTap(context)
            : null,
        inputFormatters: _effectiveInputFormatters(),
        textCapitalization: widget.textCapitalization,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
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
