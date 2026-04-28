import 'package:flutter/material.dart';

import '../app/constants/app_ui_constants.dart';
import 'app_field_box.dart';

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
    return AppFieldBox(
      width: width,
      child: FormField<String>(
        key: ValueKey<String>('$labelText:${selectedLabel ?? ''}'),
        initialValue: selectedLabel ?? '',
        validator: validator,
        builder: (field) {
          final theme = Theme.of(context);
          final hasValue = (selectedLabel ?? '').trim().isNotEmpty;
          final textStyle = theme.textTheme.bodyLarge?.copyWith(
            color: hasValue
                ? theme.colorScheme.onSurface
                : theme.hintColor,
          );

          return InkWell(
            onTap: () async {
              FocusScope.of(context).unfocus();
              final value = await showDialog<T>(
                context: context,
                builder: (context) => _SearchPickerDialog<T>(
                  title: labelText,
                  options: options,
                ),
              );
              if (!context.mounted) {
                return;
              }
              onChanged(value);
              final selectedOption = value == null
                  ? null
                  : options.cast<AppSearchPickerOption<T>?>().firstWhere(
                        (option) => option?.value == value,
                        orElse: () => null,
                      );
              field.didChange(selectedOption?.label ?? '');
            },
            borderRadius: BorderRadius.circular(4),
            child: InputDecorator(
              isEmpty: !hasValue,
              decoration: InputDecoration(
                labelText: labelText,
                hintText: hintText ?? 'Search and select',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                contentPadding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                suffixIcon: const Icon(Icons.search),
                errorText: field.errorText,
              ),
              child: Text(
                hasValue
                    ? selectedLabel!
                    : (hintText ?? 'Search and select'),
                style: textStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SearchPickerDialog<T> extends StatefulWidget {
  const _SearchPickerDialog({required this.title, required this.options});

  final String title;
  final List<AppSearchPickerOption<T>> options;

  @override
  State<_SearchPickerDialog<T>> createState() => _SearchPickerDialogState<T>();
}

class _SearchPickerDialogState<T> extends State<_SearchPickerDialog<T>> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = widget.options
        .where((option) {
          if (query.isEmpty) {
            return true;
          }
          final haystack =
              '${option.label} ${option.subtitle ?? ''} ${option.searchText ?? ''}'
                  .toLowerCase();
          return haystack.contains(query);
        })
        .toList(growable: false);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(AppUiConstants.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppUiConstants.spacingMd),
              TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Type to search',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: AppUiConstants.spacingMd),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No matching records'))
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final option = filtered[index];
                          return ListTile(
                            title: Text(option.label),
                            subtitle: option.subtitle == null
                                ? null
                                : Text(option.subtitle!),
                            onTap: () =>
                                Navigator.of(context).pop(option.value),
                          );
                        },
                      ),
              ),
              const SizedBox(height: AppUiConstants.spacingSm),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
