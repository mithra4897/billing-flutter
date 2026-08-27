import '../../screen.dart';
import 'crm_module_refresh_controller.dart';

class CrmLeadRegisterController extends GetxController {
  CrmLeadRegisterController({required this.instanceTag});
  final String instanceTag;

  static const List<AppDropdownItem<String>> statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: '', label: 'All'),
        AppDropdownItem(value: 'draft', label: 'Draft'),
        AppDropdownItem(value: 'in_progress', label: 'In Progress'),
        AppDropdownItem(value: 'converted', label: 'Own'),
        AppDropdownItem(value: 'lost', label: 'Lost'),
      ];
  static const List<AppDropdownItem<String>> sortItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'date_desc', label: 'Newest first'),
        AppDropdownItem(value: 'date_asc', label: 'Oldest first'),
        AppDropdownItem(value: 'name_asc', label: 'Name A-Z'),
        kPendingRedFirstSortItem,
      ];

  final CrmService _service = CrmService();
  final CrmModuleRefreshController _refreshController =
      CrmModuleRefreshController.ensureRegistered();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController dateFromController = TextEditingController();
  final TextEditingController dateToController = TextEditingController();

  bool loading = true;
  String? error;
  Set<String> statuses = <String>{'draft', 'in_progress'};
  Set<int> assignedToIds = <int>{};
  String sort = 'date_desc';
  List<CrmLeadModel> rows = const <CrmLeadModel>[];
  Worker? _refreshWorker;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_notifySearch);
    dateFromController.addListener(_notifySearch);
    dateToController.addListener(_notifySearch);
    _refreshWorker = ever<CrmModuleRefreshEvent?>(
      _refreshController.lastEvent,
      (event) {
        if (event == null) {
          return;
        }
        unawaited(load());
      },
    );
    load();
  }

  @override
  void onClose() {
    _refreshWorker?.dispose();
    searchController
      ..removeListener(_notifySearch)
      ..dispose();
    dateFromController
      ..removeListener(_notifySearch)
      ..dispose();
    dateToController
      ..removeListener(_notifySearch)
      ..dispose();
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

  void setSort(String value) {
    sort = value;
    update();
  }

  void setAssignedToIds(Set<int> values) {
    assignedToIds = Set<int>.from(values);
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

  bool isPendingLead(CrmLeadModel row) {
    final status = stringValue(row.toJson(), 'lead_status').trim().toLowerCase();
    return !const <String>{'converted', 'own', 'lost'}.contains(status);
  }

  List<CrmLeadModel> get filteredRows {
    final query = searchController.text.trim().toLowerCase();
    final filtered = rows
        .where((row) {
          final data = row.toJson();
          final statusOk = _matchesStatus(
            stringValue(data, 'lead_status'),
            statuses,
          );
          final assignedUser =
              JsonModel.mapOf(data['assigned_user']) ??
              const <String, dynamic>{};
          final assignedOk =
              assignedToIds.isEmpty ||
              assignedToIds.contains(intValue(assignedUser, 'id'));
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
          final pendingOk =
              sort != kPendingRedFirstSort || isPendingLead(row);
          return statusOk && assignedOk && dateOk && searchOk && pendingOk;
        })
        .toList(growable: false);
    final sorted = List<CrmLeadModel>.from(filtered);
    sorted.sort((left, right) {
      if (sort == 'name_asc') {
        return stringValue(left.toJson(), 'lead_name').toLowerCase().compareTo(
          stringValue(right.toJson(), 'lead_name').toLowerCase(),
        );
      }
      if (sort == kPendingRedFirstSort) {
        final leftPending = isPendingLead(left);
        final rightPending = isPendingLead(right);
        if (leftPending && !rightPending) return -1;
        if (!leftPending && rightPending) return 1;
        // Within pending, oldest first (red at top)
        final leftDate = nullableStringValue(left.toJson(), 'created_at') ?? '';
        final rightDate =
            nullableStringValue(right.toJson(), 'created_at') ?? '';
        return leftDate.compareTo(rightDate);
      }
      final leftDate = nullableStringValue(left.toJson(), 'created_at') ?? '';
      final rightDate = nullableStringValue(right.toJson(), 'created_at') ?? '';
      return sort == 'date_asc'
          ? leftDate.compareTo(rightDate)
          : rightDate.compareTo(leftDate);
    });
    return sorted;
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
}
