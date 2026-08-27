import '../screen.dart';

/// A reusable, responsive register filters panel shared across
/// Sales, Purchase, and CRM modules.
class AppRegisterFilters extends StatelessWidget {
  const AppRegisterFilters({
    super.key,
    required this.dateFromController,
    required this.dateToController,
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
    required this.onClear,
    this.maxWidth,
  });

  final TextEditingController dateFromController;
  final TextEditingController dateToController;
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
  final VoidCallback onClear;
  final double? maxWidth;

  Widget _dateField({
    required String label,
    required TextEditingController textController,
  }) {
    return AppDateField(
      labelText: label,
      controller: textController,
      validator: Validators.optionalDate(label),
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
    final hasParty = partyLabel != null &&
        partyItems != null &&
        partyItems!.isNotEmpty &&
        selectedPartyIds != null &&
        onPartyChanged != null;

    final hasStatus = statusItems != null &&
        statusItems!.isNotEmpty &&
        selectedStatuses != null &&
        onStatusesChanged != null;

    final hasSort = sortItems != null &&
        sortItems!.isNotEmpty &&
        sort != null &&
        onSortChanged != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsFormWrap(
          maxWidth: maxWidth ?? double.infinity,
          maxColumns: 6,
          expandChildren: true,
          children: [
            if (hasParty)
              AppDropdownField<int>.fromMapped(
                labelText: partyLabel!,
                mappedItems: partyItems!,
                multiInitialValues: selectedPartyIds!,
                multiHintText: 'Select ${partyLabel!.toLowerCase()}s',
                onMultiChanged: onPartyChanged,
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
              ),
            if (hasSort)
              AppDropdownField<String>.fromMapped(
                labelText: 'Sort',
                mappedItems: sortItems!,
                initialValue: sort!,
                onChanged: onSortChanged,
              ),
            _dateField(
              label: 'Date From',
              textController: dateFromController,
            ),
            _dateField(
              label: 'Date To',
              textController: dateToController,
            ),
            _actionField(context),
          ],
        ),
      ],
    );
  }
}
