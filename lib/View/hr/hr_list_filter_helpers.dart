import '../../screen.dart';

Widget hrListFilterBox({required Widget child}) {
  return SizedBox(width: 240, child: child);
}

Future<bool?> showHrListFilterDialog({
  required BuildContext context,
  required String title,
  Widget? header,
  required List<Widget> filterFields,
  required VoidCallback onClear,
}) async {
  final screenWidth = MediaQuery.of(context).size.width;
  final horizontalPadding = screenWidth < 600 ? 12.0 : 24.0;
  final dialogPadding = screenWidth < 600 ? 16.0 : AppUiConstants.cardPadding;

  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      final appTheme = Theme.of(dialogContext).extension<AppThemeExtension>()!;

      return Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 20,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              dialogPadding,
              dialogPadding,
              dialogPadding,
              MediaQuery.of(dialogContext).viewInsets.bottom + dialogPadding,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(dialogContext).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      tooltip: 'Close',
                      icon: const Icon(Icons.close),
                      color: appTheme.mutedText,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (header != null) ...[header, const SizedBox(height: 12)],
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: filterFields,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      icon: const Icon(Icons.search),
                      label: const Text('Apply Filters'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        onClear();
                        Navigator.of(dialogContext).pop(true);
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget hrListAppliedFiltersCard(BuildContext context, List<String> chips) {
  if (chips.isEmpty) {
    return const SizedBox.shrink();
  }
  final appTheme = Theme.of(context).extension<AppThemeExtension>()!;
  return DecoratedBox(
    decoration: BoxDecoration(
      color: appTheme.cardBackground,
      borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
      boxShadow: [
        BoxShadow(
          color: appTheme.cardShadow,
          blurRadius: 18,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(AppUiConstants.cardPadding),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: chips
            .map((String chip) => Chip(label: Text(chip)))
            .toList(growable: false),
      ),
    ),
  );
}

String hrDropdownLabel<T>(List<AppDropdownItem<T>> items, T? value) {
  for (final AppDropdownItem<T> item in items) {
    if (item.value == value) {
      return item.label;
    }
  }
  return '';
}
