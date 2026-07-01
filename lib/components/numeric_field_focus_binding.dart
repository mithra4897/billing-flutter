import '../screen.dart';

class NumericFieldFocusBinding {
  FocusNode? _focusNode;
  TextEditingController? _controller;

  FocusNode? get focusNode => _focusNode;

  static bool isNumericKeyboard(TextInputType? keyboardType) {
    return keyboardType?.index == TextInputType.number.index;
  }

  static void applyFormattedDisplay(TextEditingController? controller) {
    if (controller == null) {
      return;
    }
    final formatted = Validators.formatFlexibleNumberString(controller.text);
    if (formatted == controller.text) {
      return;
    }
    controller.value = controller.value.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
      composing: TextRange.empty,
    );
  }

  bool sync({
    required bool enable,
    required TextEditingController? controller,
  }) {
    _controller = controller;
    if (enable && controller != null) {
      if (_focusNode == null) {
        _focusNode = FocusNode()..addListener(_handleFocusChanged);
        return true;
      }
      return false;
    }

    dispose();
    return false;
  }

  void _handleFocusChanged() {
    if (_focusNode?.hasFocus ?? false) {
      _selectAllIfZero(_controller);
      return;
    }
    if (!(_focusNode?.hasFocus ?? false)) {
      applyFormattedDisplay(_controller);
    }
  }

  static void _selectAllIfZero(TextEditingController? controller) {
    if (controller == null) {
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
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: text.length,
    );
  }

  void dispose() {
    _focusNode?.removeListener(_handleFocusChanged);
    _focusNode?.dispose();
    _focusNode = null;
    _controller = null;
  }
}
