import '../screen.dart';

class AppSearchPickerOption<T> {
  const AppSearchPickerOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.searchText,
  });

  final T value;
  final String label;
  final String? subtitle;
  final String? searchText;
}

class AppSearchPickerField<T> extends StatelessWidget {
  const AppSearchPickerField({
    super.key,
    required this.labelText,
    required this.selectedLabel,
    required this.options,
    required this.onChanged,
    this.hintText,
    this.validator,
    this.width,
  });

  final String labelText;
  final String? selectedLabel;
  final List<AppSearchPickerOption<T>> options;
  final ValueChanged<T?> onChanged;
  final String? hintText;
  final FormFieldValidator<String>? validator;
  final double? width;

  @override
  Widget build(BuildContext context) {
    ErpLinkFieldOption<T>? initialOption;
    final erpOptions = options.map((opt) {
      final erpOpt = ErpLinkFieldOption<T>(
        value: opt.value,
        label: opt.label,
        subtitle: opt.subtitle,
        searchText: opt.searchText,
      );
      if (opt.label == selectedLabel) {
        initialOption = erpOpt;
      }
      return erpOpt;
    }).toList(growable: false);

    return ErpLinkField<T>(
      labelText: labelText,
      hintText: hintText,
      width: width,
      options: erpOptions,
      initialSelection: initialOption,
      onChanged: onChanged,
      validator: validator == null
          ? null
          : (T? value) {
              final label = value == null
                  ? ''
                  : (erpOptions
                          .cast<ErpLinkFieldOption<T>?>()
                          .firstWhere(
                            (e) => e?.value == value,
                            orElse: () => null,
                          )
                          ?.label ??
                      '');
              return validator!(label);
            },
    );
  }
}
