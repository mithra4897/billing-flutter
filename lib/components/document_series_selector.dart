import '../screen.dart';

class DocumentSeriesSelector<T> extends StatelessWidget {
  const DocumentSeriesSelector({
    super.key,
    required this.labelText,
    required this.mappedItems,
    required this.initialValue,
    required this.onChanged,
    this.validator,
  });

  final String labelText;
  final List<AppDropdownItem<T>> mappedItems;
  final T? initialValue;
  final ValueChanged<T?> onChanged;
  final FormFieldValidator<T?>? validator;

  @override
  Widget build(BuildContext context) {
    final selectableItems = mappedItems
        .where((item) => item.value != null)
        .toList(growable: false);
    final onlyItem = selectableItems.length == 1 ? selectableItems.first : null;
    final shouldRenderReadOnly =
        onlyItem != null &&
        mappedItems.every(
          (item) => item.value == null || item.value == onlyItem.value,
        );

    if (shouldRenderReadOnly) {
      if (initialValue != onlyItem.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onChanged(onlyItem.value);
        });
      }

      return AppFieldBox(
        child: InputDecorator(
          decoration: InputDecoration(labelText: labelText),
          child: Text(onlyItem.label),
        ),
      );
    }

    return AppDropdownField<T>.fromMapped(
      key: key,
      labelText: labelText,
      mappedItems: mappedItems,
      initialValue: initialValue,
      onChanged: onChanged,
      validator: validator,
    );
  }
}
