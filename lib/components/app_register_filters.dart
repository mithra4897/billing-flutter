import '../screen.dart';

class AppRegisterFilterSuggestion {
  const AppRegisterFilterSuggestion({
    required this.label,
    required this.onSelected,
  });

  final String label;
  final VoidCallback onSelected;
}

class AppRegisterFiltersSection extends StatelessWidget {
  const AppRegisterFiltersSection({
    super.key,
    required this.filters,
    this.keyPrefix = 'register',
  });

  final Widget? filters;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return SizeTransition(
          sizeFactor: animation,
          axisAlignment: -1,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: filters == null
          ? SizedBox.shrink(key: ValueKey<String>('$keyPrefix-filters-hidden'))
          : Padding(
              key: ValueKey<String>('$keyPrefix-filters-visible'),
              padding: const EdgeInsets.only(bottom: AppUiConstants.spacingLg),
              child: SizedBox(
                width: double.infinity,
                child: AppSectionCard(child: filters!),
              ),
            ),
    );
  }
}

/// A reusable, responsive register filters panel shared across
/// Sales, Purchase, Inventory, and CRM modules.
class AppRegisterFilters extends StatelessWidget {
  const AppRegisterFilters({
    super.key,
    this.searchController,
    this.searchLabel = 'Search',
    this.searchHint,
    this.dateFromController,
    this.dateToController,
    this.statusItems,
    this.selectedStatuses,
    this.onStatusesChanged,
    this.sortItems,
    this.sort,
    this.onSortChanged,
    this.partyLabel,
    this.partyItems,
    this.selectedPartyIds,
    this.onPartyChanged,
    this.secondaryPartyLabel,
    this.secondaryPartyItems,
    this.selectedSecondaryPartyIds,
    this.onSecondaryPartyChanged,
    this.itemItems,
    this.itemLabel = 'Item',
    this.selectedItemIds,
    this.onItemsChanged,
    this.typeItems,
    this.typeLabel = 'Type',
    this.selectedTypes,
    this.onTypesChanged,
    this.categoryItems,
    this.categoryLabel = 'Category',
    this.selectedCategories,
    this.onCategoriesChanged,
    this.showDateFilters = true,
    required this.onClear,
    this.maxWidth,
    this.suggestions = const <AppRegisterFilterSuggestion>[],
  });

  final TextEditingController? searchController;
  final String searchLabel;
  final String? searchHint;
  final TextEditingController? dateFromController;
  final TextEditingController? dateToController;
  final List<AppDropdownItem<String>>? statusItems;
  final Set<String>? selectedStatuses;
  final ValueChanged<Set<String>>? onStatusesChanged;
  final List<AppDropdownItem<String>>? sortItems;
  final String? sort;
  final ValueChanged<String?>? onSortChanged;
  final String? partyLabel;
  final List<AppDropdownItem<int>>? partyItems;
  final Set<int>? selectedPartyIds;
  final ValueChanged<Set<int>>? onPartyChanged;
  final String? secondaryPartyLabel;
  final List<AppDropdownItem<int>>? secondaryPartyItems;
  final Set<int>? selectedSecondaryPartyIds;
  final ValueChanged<Set<int>>? onSecondaryPartyChanged;
  final List<AppDropdownItem<int>>? itemItems;
  final String itemLabel;
  final Set<int>? selectedItemIds;
  final ValueChanged<Set<int>>? onItemsChanged;
  final List<AppDropdownItem<String>>? typeItems;
  final String typeLabel;
  final Set<String>? selectedTypes;
  final ValueChanged<Set<String>>? onTypesChanged;
  final List<AppDropdownItem<String>>? categoryItems;
  final String categoryLabel;
  final Set<String>? selectedCategories;
  final ValueChanged<Set<String>>? onCategoriesChanged;
  final bool showDateFilters;
  final VoidCallback onClear;
  final double? maxWidth;
  final List<AppRegisterFilterSuggestion> suggestions;

  Widget _dateField({
    required String label,
    required TextEditingController textController,
  }) {
    return AppDateField(
      labelText: label,
      controller: textController,
      validator: Validators.optionalDate(label),
      showClearButton: true,
    );
  }

  Widget _actionField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppUiConstants.spacingXs),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.clear_outlined),
            label: const Text('Clear'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppUiConstants.buttonRadius,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasParty =
        partyLabel != null &&
        partyItems != null &&
        partyItems!.isNotEmpty &&
        selectedPartyIds != null &&
        onPartyChanged != null;

    final hasStatus =
        statusItems != null &&
        statusItems!.isNotEmpty &&
        selectedStatuses != null &&
        onStatusesChanged != null;

    final hasSecondaryParty =
        secondaryPartyLabel != null &&
        secondaryPartyItems != null &&
        secondaryPartyItems!.isNotEmpty &&
        selectedSecondaryPartyIds != null &&
        onSecondaryPartyChanged != null;

    final hasItem =
        itemItems != null &&
        itemItems!.isNotEmpty &&
        selectedItemIds != null &&
        onItemsChanged != null;

    final hasType =
        typeItems != null &&
        typeItems!.isNotEmpty &&
        selectedTypes != null &&
        onTypesChanged != null;

    final hasSort =
        sortItems != null &&
        sortItems!.isNotEmpty &&
        sort != null &&
        onSortChanged != null;

    final hasCategory =
        categoryItems != null &&
        categoryItems!.isNotEmpty &&
        selectedCategories != null &&
        onCategoriesChanged != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsFormWrap(
          maxWidth: maxWidth ?? double.infinity,
          maxColumns: 6,
          expandChildren: true,
          children: [
            if (searchController != null)
              AppFormTextField(
                controller: searchController!,
                labelText: searchLabel,
                hintText: searchHint,
                prefixIcon: const Icon(Icons.search_outlined),
              ),
            if (hasParty)
              AppDropdownField<int>.fromMapped(
                labelText: partyLabel!,
                mappedItems: partyItems!,
                multiInitialValues: selectedPartyIds!,
                multiHintText: 'Select ${partyLabel!.toLowerCase()}s',
                onMultiChanged: onPartyChanged,
                onClear: selectedPartyIds!.isEmpty
                    ? null
                    : () => onPartyChanged!(<int>{}),
              ),
            if (hasSecondaryParty)
              AppDropdownField<int>.fromMapped(
                labelText: secondaryPartyLabel!,
                mappedItems: secondaryPartyItems!,
                multiInitialValues: selectedSecondaryPartyIds!,
                multiHintText: 'Select ${secondaryPartyLabel!.toLowerCase()}s',
                onMultiChanged: onSecondaryPartyChanged,
                onClear: selectedSecondaryPartyIds!.isEmpty
                    ? null
                    : () => onSecondaryPartyChanged!(<int>{}),
              ),
            if (hasItem)
              AppDropdownField<int>.fromMapped(
                labelText: itemLabel,
                mappedItems: itemItems!,
                multiInitialValues: selectedItemIds!,
                multiHintText: 'Select ${itemLabel.toLowerCase()}s',
                onMultiChanged: onItemsChanged,
                onClear: selectedItemIds!.isEmpty
                    ? null
                    : () => onItemsChanged!(<int>{}),
              ),
            if (hasType)
              AppDropdownField<String>.fromMapped(
                labelText: typeLabel,
                mappedItems: typeItems!,
                multiInitialValues: selectedTypes!,
                multiHintText: 'Select ${typeLabel.toLowerCase()}s',
                onMultiChanged: onTypesChanged,
                onClear: selectedTypes!.isEmpty
                    ? null
                    : () => onTypesChanged!(<String>{}),
              ),
            if (hasStatus)
              AppDropdownField<String>.fromMapped(
                labelText: 'Status',
                mappedItems: statusItems!
                    .where((item) => item.value.trim().isNotEmpty)
                    .toList(growable: false),
                multiInitialValues: selectedStatuses!,
                multiHintText: 'Select statuses',
                onMultiChanged: onStatusesChanged,
                onClear: selectedStatuses!.isEmpty
                    ? null
                    : () => onStatusesChanged!(<String>{}),
              ),
            if (hasSort)
              AppDropdownField<String>.fromMapped(
                labelText: 'Sort',
                mappedItems: sortItems!,
                initialValue: sort!,
                onChanged: onSortChanged,
              ),
            if (hasCategory)
              AppDropdownField<String>.fromMapped(
                labelText: categoryLabel,
                mappedItems: categoryItems!
                    .where((item) => item.value.trim().isNotEmpty)
                    .toList(growable: false),
                multiInitialValues: selectedCategories!,
                multiHintText: 'Select ${categoryLabel.toLowerCase()} values',
                onMultiChanged: onCategoriesChanged,
                onClear: selectedCategories!.isEmpty
                    ? null
                    : () => onCategoriesChanged!(<String>{}),
              ),
            if (showDateFilters && dateFromController != null)
              _dateField(
                label: 'Date From',
                textController: dateFromController!,
              ),
            if (showDateFilters && dateToController != null)
              _dateField(label: 'Date To', textController: dateToController!),
            _actionField(context),
          ],
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: AppUiConstants.spacingSm),
          Wrap(
            spacing: AppUiConstants.spacingSm,
            runSpacing: AppUiConstants.spacingXs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text(
                'Suggestions:',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              ...suggestions.map(
                (suggestion) => ActionChip(
                  label: Text(suggestion.label),
                  onPressed: suggestion.onSelected,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
