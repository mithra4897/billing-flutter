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
        AppDropdownItem(value: 'own', label: 'Own'),
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
