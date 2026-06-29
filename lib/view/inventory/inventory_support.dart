import '../../screen.dart';

Future<void> openInventorySearchStatusCategoryFilterPanel({
  required BuildContext context,
  required String title,
  required TextEditingController searchController,
  required TextEditingController dateFromController,
  required TextEditingController dateToController,
  required String searchHint,
  required String status,
  required List<AppDropdownItem<String>> statusItems,
  required String category,
  required List<AppDropdownItem<String>> categoryItems,
  required void Function(
    String search,
    String status,
    String dateFrom,
    String dateTo,
    String category,
  )
  onApply,
  required VoidCallback onClear,
}) async {
  final screenWidth = MediaQuery.of(context).size.width;
  final horizontalPadding = screenWidth < 600 ? 12.0 : 24.0;
  final dialogPadding = screenWidth < 600 ? 16.0 : AppUiConstants.cardPadding;
  final dialogSearchController = TextEditingController(
    text: searchController.text,
  );
  final dialogDateFromController = TextEditingController(
    text: dateFromController.text,
  );
  final dialogDateToController = TextEditingController(
    text: dateToController.text,
  );
  var tempStatus = status;
  var tempCategory = category;

  await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      final appTheme = Theme.of(dialogContext).extension<AppThemeExtension>()!;
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
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
                  MediaQuery.of(dialogContext).viewInsets.bottom +
                      dialogPadding,
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
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          tooltip: 'Close',
                          icon: const Icon(Icons.close),
                          color: appTheme.mutedText,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _InventorySearchStatusCategoryFilters(
                      searchController: dialogSearchController,
                      dateFromController: dialogDateFromController,
                      dateToController: dialogDateToController,
                      searchHint: searchHint,
                      status: tempStatus,
                      statusItems: statusItems,
                      onStatusChanged: (value) {
                        setDialogState(() {
                          tempStatus = value ?? '';
                        });
                      },
                      category: tempCategory,
                      categoryItems: categoryItems,
                      onCategoryChanged: (value) {
                        setDialogState(() {
                          tempCategory = value ?? '';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.icon(
                          onPressed: () {
                            onApply(
                              dialogSearchController.text,
                              tempStatus,
                              dialogDateFromController.text,
                              dialogDateToController.text,
                              tempCategory,
                            );
                            Navigator.of(dialogContext).pop(true);
                          },
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
    },
  );

  dialogSearchController.dispose();
  dialogDateFromController.dispose();
  dialogDateToController.dispose();
}

class _InventorySearchStatusCategoryFilters extends StatelessWidget {
  const _InventorySearchStatusCategoryFilters({
    required this.searchController,
    required this.dateFromController,
    required this.dateToController,
    required this.searchHint,
    required this.status,
    required this.statusItems,
    required this.onStatusChanged,
    required this.category,
    required this.categoryItems,
    required this.onCategoryChanged,
  });

  final TextEditingController searchController;
  final TextEditingController dateFromController;
  final TextEditingController dateToController;
  final String searchHint;
  final String status;
  final List<AppDropdownItem<String>> statusItems;
  final ValueChanged<String?> onStatusChanged;
  final String category;
  final List<AppDropdownItem<String>> categoryItems;
  final ValueChanged<String?> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final children = <Widget>[
          AppFormTextField(
            labelText: searchHint,
            controller: searchController,
            prefixIcon: const Icon(Icons.search_outlined),
          ),
          AppDateField(labelText: 'From Date', controller: dateFromController),
          AppDateField(labelText: 'To Date', controller: dateToController),
          AppDropdownField<String>.fromMapped(
            labelText: 'Status',
            mappedItems: statusItems,
            initialValue: status,
            onChanged: onStatusChanged,
          ),
          AppDropdownField<String>.fromMapped(
            labelText: 'Category',
            mappedItems: categoryItems,
            initialValue: category,
            onChanged: onCategoryChanged,
          ),
        ];
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children
                .map(
                  (child) => Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppUiConstants.spacingSm,
                    ),
                    child: child,
                  ),
                )
                .toList(growable: false),
          );
        }
        return Wrap(
          spacing: AppUiConstants.spacingSm,
          runSpacing: AppUiConstants.spacingSm,
          children: children
              .map(
                (child) => SizedBox(
                  width: (constraints.maxWidth - AppUiConstants.spacingSm) / 2,
                  child: child,
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}
