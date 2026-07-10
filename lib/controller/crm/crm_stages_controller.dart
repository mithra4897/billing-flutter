import '../../screen.dart';
import 'crm_module_refresh_controller.dart';

class CrmStagesController extends GetxController {
  CrmStagesController({required this.startInNewMode});

  final bool startInNewMode;
  final CrmService _crmService = CrmService();
  final CrmModuleRefreshController _refreshController =
      CrmModuleRefreshController.ensureRegistered();

  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController sequenceController = TextEditingController();
  final TextEditingController probabilityController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  List<CrmStageModel> items = const <CrmStageModel>[];
  List<CrmStageModel> filteredItems = const <CrmStageModel>[];
  CrmStageModel? selectedItem;
  String stageType = 'lead';
  bool isDefault = false;
  bool isActive = true;
  bool appliedInitialNewMode = false;
  Worker? _refreshWorker;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_applySearch);
    _refreshWorker = ever<CrmModuleRefreshEvent?>(
      _refreshController.lastEvent,
      (event) {
        if (event == null || event.source == 'crm_stages') {
          return;
        }
        unawaited(
          loadPage(
            selectId: intValue(selectedItem?.toJson() ?? const {}, 'id'),
          ),
        );
      },
    );
    loadPage();
  }

  @override
  void onClose() {
    _refreshWorker?.dispose();
    pageScrollController.dispose();
    workspaceController.dispose();
    searchController
      ..removeListener(_applySearch)
      ..dispose();
    nameController.dispose();
    sequenceController.dispose();
    probabilityController.dispose();
    super.onClose();
  }

  Future<void> loadPage({int? selectId}) async {
    initialLoading = items.isEmpty;
    pageError = null;
    update();

    try {
      final response = await _crmService.stages(
        filters: const {'per_page': 200, 'sort_by': 'sequence_no'},
      );
      final nextItems = response.data ?? const <CrmStageModel>[];

      items = nextItems;
      initialLoading = false;
      _applySearch(notify: false);

      if (startInNewMode && selectId == null && !appliedInitialNewMode) {
        appliedInitialNewMode = true;
        resetForm(notify: false);
        update();
        return;
      }

      final selected = selectId != null
          ? nextItems.cast<CrmStageModel?>().firstWhere(
              (item) => intValue(item?.toJson() ?? const {}, 'id') == selectId,
              orElse: () => null,
            )
          : (selectedItem == null
                ? (nextItems.isNotEmpty ? nextItems.first : null)
                : nextItems.cast<CrmStageModel?>().firstWhere(
                    (item) =>
                        intValue(item?.toJson() ?? const {}, 'id') ==
                        intValue(selectedItem!.toJson(), 'id'),
                    orElse: () => nextItems.isNotEmpty ? nextItems.first : null,
                  ));

      if (selected != null) {
        selectItem(selected, notify: false);
      } else {
        resetForm(notify: false);
      }
    } catch (error) {
      initialLoading = false;
      pageError = error.toString();
    }

    update();
  }

  void _applySearch({bool notify = true}) {
    filteredItems = filterMasterList(items, searchController.text, (item) {
      final data = item.toJson();
      return [
        stringValue(data, 'stage_name'),
        stringValue(data, 'stage_type'),
        stringValue(data, 'sequence_no'),
      ];
    });
    if (notify) {
      update();
    }
  }

  void selectItem(CrmStageModel item, {bool notify = true}) {
    final data = item.toJson();
    selectedItem = item;
    nameController.text = stringValue(data, 'stage_name');
    sequenceController.text = stringValue(data, 'sequence_no');
    probabilityController.text = stringValue(data, 'probability_percent');
    stageType = stringValue(data, 'stage_type', 'lead');
    isDefault = boolValue(data, 'is_default');
    isActive = boolValue(data, 'is_active', fallback: true);
    formError = null;
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selectedItem = null;
    nameController.clear();
    sequenceController.text = '1';
    probabilityController.text = '0';
    stageType = 'lead';
    isDefault = false;
    isActive = true;
    formError = null;
    if (notify) {
      update();
    }
  }

  void setStageType(String? value) {
    stageType = value ?? stageType;
    update();
  }

  void setIsDefault(bool value) {
    isDefault = value;
    update();
  }

  void setIsActive(bool value) {
    isActive = value;
    update();
  }

  void startNew({required bool isDesktop}) {
    resetForm();
    if (!isDesktop) {
      workspaceController.openEditor();
    }
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    saving = true;
    formError = null;
    update();

    final payload = CrmStageModel.fromJson(normalizeDatePayload({
      'stage_name': nameController.text.trim(),
      'stage_type': stageType,
      'sequence_no': int.tryParse(sequenceController.text.trim()) ?? 1,
      'probability_percent':
          double.tryParse(probabilityController.text.trim()) ?? 0,
      'is_default': isDefault,
      'is_active': isActive,
    }));

    try {
      final response = selectedItem == null
          ? await _crmService.createStage(payload)
          : await _crmService.updateStage(
              intValue(selectedItem!.toJson(), 'id')!,
              payload,
            );
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadPage(
        selectId: intValue(response.data?.toJson() ?? const {}, 'id'),
      );
      _refreshController.notifyChanged(source: 'crm_stages');
    } catch (error) {
      formError = error.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> delete() async {
    final id = intValue(selectedItem?.toJson() ?? const {}, 'id');
    if (id == null) {
      return;
    }

    try {
      final response = await _crmService.deleteStage(id);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadPage();
      _refreshController.notifyChanged(source: 'crm_stages');
    } catch (error) {
      formError = error.toString();
      update();
    }
  }
}
