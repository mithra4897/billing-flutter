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

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  final NumericFieldFocusBinding _numericBinding = NumericFieldFocusBinding();

  bool get _isNumericField =>
      NumericFieldFocusBinding.isNumericKeyboard(widget.keyboardType);

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
  void didUpdateWidget(covariant AppTextField oldWidget) {
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
