import '../../screen.dart';

class CrmLeadRegisterController extends GetxController {
  CrmLeadRegisterController();

  static const List<AppDropdownItem<String>> statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: '', label: 'All'),
        AppDropdownItem(value: 'new', label: 'New'),
        AppDropdownItem(value: 'in_progress', label: 'In Progress'),
        AppDropdownItem(value: 'converted', label: 'Converted'),
        AppDropdownItem(value: 'lost', label: 'Lost'),
      ];

  final CrmService _service = CrmService();
  final TextEditingController searchController = TextEditingController();

  bool loading = true;
  String? error;
  String status = '';
  List<CrmLeadModel> rows = const <CrmLeadModel>[];

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_notifySearch);
    load();
  }

  @override
  void onClose() {
    searchController
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

  void setStatus(String? value) {
    status = value ?? '';
    update();
  }

  List<CrmLeadModel> get filteredRows {
    final query = searchController.text.trim().toLowerCase();
    return rows
        .where((row) {
          final data = row.toJson();
          final statusOk =
              status.isEmpty || stringValue(data, 'lead_status') == status;
          final searchOk =
              query.isEmpty ||
              [
                stringValue(data, 'lead_name'),
                stringValue(data, 'company_name'),
                stringValue(data, 'mobile'),
                stringValue(data, 'email'),
                stringValue(data, 'lead_status'),
              ].join(' ').toLowerCase().contains(query);
          return statusOk && searchOk;
        })
        .toList(growable: false);
  }

  String statusLabel(String value) {
    switch (value.trim().toLowerCase()) {
      case 'in_progress':
        return 'In Progress';
      case 'converted':
        return 'Converted';
      case 'lost':
        return 'Lost';
      case 'new':
      default:
        return 'New';
    }
  }
}
