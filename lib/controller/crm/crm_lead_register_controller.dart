import '../../screen.dart';

class CrmLeadRegisterController extends GetxController {
  CrmLeadRegisterController({required this.instanceTag});
  static final Set<String> _activeTags = <String>{};
  final String instanceTag;

  static const List<AppDropdownItem<String>> statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: '', label: 'All'),
        AppDropdownItem(value: 'draft', label: 'Draft'),
        AppDropdownItem(value: 'in_progress', label: 'In Progress'),
        AppDropdownItem(value: 'converted', label: 'Own'),
        AppDropdownItem(value: 'lost', label: 'Lost'),
      ];

  final CrmService _service = CrmService();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController dateFromController = TextEditingController();
  final TextEditingController dateToController = TextEditingController();

  bool loading = true;
  String? error;
  Set<String> statuses = <String>{'draft', 'in_progress'};
  List<CrmLeadModel> rows = const <CrmLeadModel>[];

  @override
  void onInit() {
    super.onInit();
    _activeTags.add(instanceTag);
    searchController.addListener(_notifySearch);
    load();
  }

  @override
  void onClose() {
    _activeTags.remove(instanceTag);
    searchController
      ..removeListener(_notifySearch)
      ..dispose();
    dateFromController.dispose();
    dateToController.dispose();
    super.onClose();
  }

  Future<void> load() async {
    loading = true;
    error = null;
    update();
    try {
      final response = await _service.leads(
        filters: const {'per_page': 200, 'sort_by': 'lead_name'},
      );
      rows = response.data ?? const <CrmLeadModel>[];
      loading = false;
    } catch (errorValue) {
      error = errorValue.toString();
      loading = false;
    }
    update();
  }

  void _notifySearch() => update();

  void setStatuses(Set<String> values) {
    statuses = values;
    update();
  }

  bool _matchesStatus(String rowStatus, Iterable<String> requestedStatuses) {
    final normalizedRow = rowStatus.trim().toLowerCase();
    final normalizedRequested = requestedStatuses
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toSet();

    if (normalizedRequested.isEmpty) {
      return true;
    }

    for (final status in normalizedRequested) {
      if (status == 'draft' &&
          (normalizedRow == 'draft' || normalizedRow == 'new')) {
        return true;
      }

      if ((status == 'converted' || status == 'own') &&
          (normalizedRow == 'converted' || normalizedRow == 'own')) {
        return true;
      }

      if (normalizedRow == status) {
        return true;
      }
    }

    return false;
  }

  bool _matchesDateRange(String? rawDate) {
    final fromDate = tryParseCalendarDate(dateFromController.text.trim());
    final toDate = tryParseCalendarDate(dateToController.text.trim());
    if (fromDate == null && toDate == null) {
      return true;
    }

    final rowDate = DateTime.tryParse((rawDate ?? '').trim());
    if (rowDate == null) {
      return false;
    }

    final normalizedRow = DateTime(rowDate.year, rowDate.month, rowDate.day);
    if (fromDate != null) {
      final normalizedFrom = DateTime(
        fromDate.year,
        fromDate.month,
        fromDate.day,
      );
      if (normalizedRow.isBefore(normalizedFrom)) {
        return false;
      }
    }
    if (toDate != null) {
      final normalizedTo = DateTime(toDate.year, toDate.month, toDate.day);
      if (normalizedRow.isAfter(normalizedTo)) {
        return false;
      }
    }
    return true;
  }

  List<CrmLeadModel> get filteredRows {
    final query = searchController.text.trim().toLowerCase();
    return rows
        .where((row) {
          final data = row.toJson();
          final statusOk = _matchesStatus(
            stringValue(data, 'lead_status'),
            statuses,
          );
          final dateOk = _matchesDateRange(
            nullableStringValue(data, 'created_at'),
          );
          final searchOk =
              query.isEmpty ||
              [
                stringValue(data, 'lead_name'),
                stringValue(data, 'company_name'),
                stringValue(data, 'mobile'),
                stringValue(data, 'email'),
                stringValue(data, 'lead_status'),
              ].join(' ').toLowerCase().contains(query);
          return statusOk && dateOk && searchOk;
        })
        .toList(growable: false);
  }

  String statusLabel(String value) {
    switch (value.trim().toLowerCase()) {
      case 'draft':
      case 'new':
        return 'Draft';
      case 'in_progress':
        return 'In Progress';
      case 'own':
      case 'converted':
        return 'Own';
      case 'lost':
        return 'Lost';
      default:
        return 'Draft';
    }
  }

  static Future<void> refreshIfRegistered() async {
    for (final tag in _activeTags.toList(growable: false)) {
      if (!Get.isRegistered<CrmLeadRegisterController>(tag: tag)) {
        _activeTags.remove(tag);
        continue;
      }
      await Get.find<CrmLeadRegisterController>(tag: tag).load();
    }
  }
}
