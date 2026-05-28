import '../../../screen.dart';

enum MrpReadonlyModule { demand, supply, netRequirement }

class MrpReadonlyViewModel extends GetxController {
  MrpReadonlyViewModel(this.module) {
    searchController.addListener(update);
  }

  final MrpReadonlyModule module;
  final PlanningService _service = PlanningService();
  final TextEditingController searchController = TextEditingController();

  bool loading = true;
  bool detailLoading = false;
  String? pageError;
  String? formError;
  List<JsonModel> rows = const <JsonModel>[];
  JsonModel? selected;

  List<JsonModel> get filteredRows {
    final q = searchController.text.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows
        .where((row) {
          final data = row.toJson();
          return data.values.join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  Future<void> load({int? selectId}) async {
    loading = true;
    pageError = null;
    update();
    try {
      final companyId = await SessionStorage.getCurrentCompanyId();
      if (companyId == null) {
        rows = const <JsonModel>[];
        selected = null;
        loading = false;
        pageError = 'Select a company in the header to load MRP records.';
        update();
        return;
      }
      final filters = <String, dynamic>{'per_page': 100};
      filters['company_id'] = companyId;
      switch (module) {
        case MrpReadonlyModule.demand:
          rows =
              (await _service.mrpDemands(filters: filters)).data ??
              const <MrpDemandModel>[];
          break;
        case MrpReadonlyModule.supply:
          rows =
              (await _service.mrpSupplies(filters: filters)).data ??
              const <MrpSupplyModel>[];
          break;
        case MrpReadonlyModule.netRequirement:
          rows =
              (await _service.mrpNetRequirements(filters: filters)).data ??
              const <MrpNetRequirementModel>[];
          break;
      }
      loading = false;
      if (selectId != null) {
        if (await restoreSelectionAfterReload<JsonModel>(
          selectId: selectId,
          rows: rows,
          selected: selected,
          onSelect: select,
          replaceRows: (nextRows) => rows = nextRows,
          notify: update,
        )) {
          return;
        }
      }
      selected = null;
      update();
    } catch (e) {
      pageError = e.toString();
      loading = false;
      update();
    }
  }

  Future<void> select(JsonModel row) async {
    final id = intValue(row.toJson(), 'id');
    if (id == null) return;
    detailLoading = true;
    formError = null;
    update();
    try {
      switch (module) {
        case MrpReadonlyModule.demand:
          selected = (await _service.mrpDemand(id)).data ?? row;
          break;
        case MrpReadonlyModule.supply:
          selected = (await _service.mrpSupply(id)).data ?? row;
          break;
        case MrpReadonlyModule.netRequirement:
          selected = (await _service.mrpNetRequirement(id)).data ?? row;
          break;
      }
    } catch (e) {
      formError = e.toString();
    } finally {
      detailLoading = false;
      update();
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
