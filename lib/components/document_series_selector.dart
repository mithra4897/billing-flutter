import '../screen.dart';

String formatDocumentSeriesPreviewNumber(DocumentSeriesModel? series) {
  if (series == null) {
    return '';
  }

  final prefix = series.prefix ?? '';
  final suffix = series.suffix ?? '';
  final nextNumber = series.nextNumber;
  final numberLength = series.numberLength ?? 0;

  if (nextNumber == null) {
    return '$prefix$suffix';
  }

  final numberText = numberLength > 0
      ? nextNumber.toString().padLeft(numberLength, '0')
      : nextNumber.toString();
  return '$prefix$numberText$suffix';
}

class DocumentSeriesSelector<T> extends StatelessWidget {
  const DocumentSeriesSelector({
    super.key,
    required this.labelText,
    required this.mappedItems,
    required this.initialValue,
    this.onChanged,
    this.validator,
    this.enabled = true,
  });

  final String labelText;
  final List<AppDropdownItem<T>> mappedItems;
  final T? initialValue;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T?>? validator;
  final bool enabled;

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
      if (enabled && onChanged != null && initialValue != onlyItem.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onChanged?.call(onlyItem.value);
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
      enabled: enabled,
    );
  }
}

class GeneratedDocumentNumberField extends StatelessWidget {
  const GeneratedDocumentNumberField({
    super.key,
    required this.labelText,
    required this.controller,
    required this.documentSeries,
    required this.documentSeriesId,
    this.enabled = true,
    this.validator,
    this.hintText,
  });

  final String labelText;
  final TextEditingController controller;
  final List<DocumentSeriesModel> documentSeries;
  final int? documentSeriesId;
  final bool enabled;
  final FormFieldValidator<String>? validator;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    final selectedSeries = documentSeries.cast<DocumentSeriesModel?>().firstWhere(
      (item) => item?.id == documentSeriesId,
      orElse: () => null,
    );
    final hasSeriesSelection = selectedSeries != null;

    if (!hasSeriesSelection) {
      return AppFormTextField(
        labelText: labelText,
        controller: controller,
        hintText: hintText,
        enabled: enabled,
        validator: validator,
      );
    }

    final value = controller.text.trim().isNotEmpty
        ? controller.text.trim()
        : formatDocumentSeriesPreviewNumber(selectedSeries);

    return AppFormTextField(
      labelText: labelText,
      initialValue: value,
      hintText: hintText,
      readOnly: true,
      validator: validator,
    );
  }
}
