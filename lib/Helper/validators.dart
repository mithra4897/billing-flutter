class Validators {
  const Validators._();

  static String? Function(String?) required(String fieldName) {
    return (value) => requiredField(value, fieldName);
  }

  static String? requiredField(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    return null;
  }
}
