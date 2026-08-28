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
  final panelSearchController = TextEditingController(
    text: searchController.text,
  );
  final panelDateFromController = TextEditingController(
    text: dateFromController.text,
  );
  final panelDateToController = TextEditingController(
    text: dateToController.text,
  );
  var selectedStatuses = status.trim().isEmpty ? <String>{} : <String>{status};
  var selectedCategories = category.trim().isEmpty
      ? <String>{}
      : <String>{category};

  await showAppFilterPanel<void>(
    context: context,
    title: title,
    builder: (panelContext) {
      return StatefulBuilder(
        builder: (context, setPanelState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppFormTextField(
                labelText: 'Search',
                controller: panelSearchController,
                hintText: searchHint,
                textInputAction: TextInputAction.search,
              ),
              const SizedBox(height: AppUiConstants.spacingMd),
              AppRegisterFilters(
                dateFromController: panelDateFromController,
                dateToController: panelDateToController,
                statusItems: statusItems,
                selectedStatuses: selectedStatuses,
                onStatusesChanged: (values) {
                  setPanelState(() {
                    selectedStatuses = values.isEmpty
                        ? <String>{}
                        : <String>{values.last};
                  });
                },
                categoryItems: categoryItems,
                selectedCategories: selectedCategories,
                onCategoriesChanged: (values) {
                  setPanelState(() {
                    selectedCategories = values.isEmpty
                        ? <String>{}
                        : <String>{values.last};
                  });
                },
                onClear: () {
                  setPanelState(() {
                    panelSearchController.clear();
                    panelDateFromController.clear();
                    panelDateToController.clear();
                    selectedStatuses = <String>{};
                    selectedCategories = <String>{};
                  });
                  onClear();
                },
              ),
              const SizedBox(height: AppUiConstants.spacingMd),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: () {
                    onApply(
                      panelSearchController.text,
                      selectedStatuses.isEmpty ? '' : selectedStatuses.first,
                      panelDateFromController.text,
                      panelDateToController.text,
                      selectedCategories.isEmpty
                          ? ''
                          : selectedCategories.first,
                    );
                    Navigator.of(panelContext).pop();
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('Apply Filters'),
                ),
              ),
            ],
          );
        },
      );
    },
  );

  panelSearchController.dispose();
  panelDateFromController.dispose();
  panelDateToController.dispose();
}

Widget buildInventoryRegisterFilters({
  required TextEditingController dateFromController,
  required TextEditingController dateToController,
  required String status,
  required List<AppDropdownItem<String>> statusItems,
  required String category,
  required List<AppDropdownItem<String>> categoryItems,
  required ValueChanged<String> onStatusChanged,
  required ValueChanged<String> onCategoryChanged,
  required VoidCallback onClear,
}) {
  return AppSectionCard(
    child: AppRegisterFilters(
      dateFromController: dateFromController,
      dateToController: dateToController,
      statusItems: statusItems,
      selectedStatuses: status.trim().isEmpty
          ? const <String>{}
          : <String>{status},
      onStatusesChanged: (values) {
        onStatusChanged(values.isEmpty ? '' : values.last);
      },
      categoryItems: categoryItems,
      selectedCategories: category.trim().isEmpty
          ? const <String>{}
          : <String>{category},
      onCategoriesChanged: (values) {
        onCategoryChanged(values.isEmpty ? '' : values.last);
      },
      onClear: onClear,
    ),
  );
}
