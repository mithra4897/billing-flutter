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
    if (!(_focusNode?.hasFocus ?? false)) {
      applyFormattedDisplay(_controller);
    }
  }

  void dispose() {
    _focusNode?.removeListener(_handleFocusChanged);
    _focusNode?.dispose();
    _focusNode = null;
    _controller = null;
  }
}
