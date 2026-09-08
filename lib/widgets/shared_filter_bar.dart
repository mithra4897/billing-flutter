import 'package:flutter/material.dart';

import '../components/app_dropdown_field.dart';
import '../components/app_register_filters.dart';

class SharedFilterBar extends StatelessWidget {
  const SharedFilterBar({
    super.key,
    this.searchController,
    this.searchLabel = 'Search',
    this.searchHint,
    this.dateFromController,
    this.dateToController,
    this.asOfDateController,
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
    this.additionalFields = const <Widget>[],
    this.showDateFilters = true,
    required this.onClear,
    this.maxWidth,
    this.suggestions = const <AppRegisterFilterSuggestion>[],
  }) : customChild = null;

  const SharedFilterBar.custom({super.key, required Widget child})
    : customChild = child,
      searchController = null,
      searchLabel = 'Search',
      searchHint = null,
      dateFromController = null,
      dateToController = null,
      asOfDateController = null,
      statusItems = null,
      selectedStatuses = null,
      onStatusesChanged = null,
      sortItems = null,
      sort = null,
      onSortChanged = null,
      partyLabel = null,
      partyItems = null,
      selectedPartyIds = null,
      onPartyChanged = null,
      secondaryPartyLabel = null,
      secondaryPartyItems = null,
      selectedSecondaryPartyIds = null,
      onSecondaryPartyChanged = null,
      itemItems = null,
      itemLabel = 'Item',
      selectedItemIds = null,
      onItemsChanged = null,
      typeItems = null,
      typeLabel = 'Type',
      selectedTypes = null,
      onTypesChanged = null,
      categoryItems = null,
      categoryLabel = 'Category',
      selectedCategories = null,
      onCategoriesChanged = null,
      additionalFields = const <Widget>[],
      showDateFilters = true,
      onClear = null,
      maxWidth = null,
      suggestions = const <AppRegisterFilterSuggestion>[];

  final Widget? customChild;
  final TextEditingController? searchController;
  final String searchLabel;
  final String? searchHint;
  final TextEditingController? dateFromController;
  final TextEditingController? dateToController;
  final TextEditingController? asOfDateController;
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
  final List<Widget> additionalFields;
  final bool showDateFilters;
  final VoidCallback? onClear;
  final double? maxWidth;
  final List<AppRegisterFilterSuggestion> suggestions;

  @override
  Widget build(BuildContext context) {
    final child = customChild;
    if (child != null) {
      return child;
    }
    return AppRegisterFilters(
      searchController: searchController,
      searchLabel: searchLabel,
      searchHint: searchHint,
      dateFromController: dateFromController,
      dateToController: dateToController,
      asOfDateController: asOfDateController,
      statusItems: statusItems,
      selectedStatuses: selectedStatuses,
      onStatusesChanged: onStatusesChanged,
      sortItems: sortItems,
      sort: sort,
      onSortChanged: onSortChanged,
      partyLabel: partyLabel,
      partyItems: partyItems,
      selectedPartyIds: selectedPartyIds,
      onPartyChanged: onPartyChanged,
      secondaryPartyLabel: secondaryPartyLabel,
      secondaryPartyItems: secondaryPartyItems,
      selectedSecondaryPartyIds: selectedSecondaryPartyIds,
      onSecondaryPartyChanged: onSecondaryPartyChanged,
      itemItems: itemItems,
      itemLabel: itemLabel,
      selectedItemIds: selectedItemIds,
      onItemsChanged: onItemsChanged,
      typeItems: typeItems,
      typeLabel: typeLabel,
      selectedTypes: selectedTypes,
      onTypesChanged: onTypesChanged,
      categoryItems: categoryItems,
      categoryLabel: categoryLabel,
      selectedCategories: selectedCategories,
      onCategoriesChanged: onCategoriesChanged,
      additionalFields: additionalFields,
      showDateFilters: showDateFilters,
      onClear: onClear!,
      maxWidth: maxWidth,
      suggestions: suggestions,
    );
  }
}
