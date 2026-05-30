import '../../screen.dart';
import '../../helper/crm_register_reload_helper.dart';

class CrmSourcesController extends GetxController {
  CrmSourcesController({required this.startInNewMode});

  final bool startInNewMode;
  final CrmService _crmService = CrmService();

  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  List<CrmSourceModel> items = const <CrmSourceModel>[];
  List<CrmSourceModel> filteredItems = const <CrmSourceModel>[];
  CrmSourceModel? selectedItem;
  bool isActive = true;
  bool appliedInitialNewMode = false;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_applySearch);
    loadPage();
  }

  @override
  void onClose() {
    pageScrollController.dispose();
    workspaceController.dispose();
    searchController
      ..removeListener(_applySearch)
      ..dispose();
    nameController.dispose();
    super.onClose();
  }

  Future<void> loadPage({int? selectId}) async {
    initialLoading = items.isEmpty;
    pageError = null;
    update();

    try {
      final response = await _crmService.sources(
        filters: const {'per_page': 200, 'sort_by': 'source_name'},
      );
      final nextItems = response.data ?? const <CrmSourceModel>[];

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
          ? nextItems.cast<CrmSourceModel?>().firstWhere(
              (item) => intValue(item?.toJson() ?? const {}, 'id') == selectId,
              orElse: () => null,
            )
          : (selectedItem == null
                ? (nextItems.isNotEmpty ? nextItems.first : null)
                : nextItems.cast<CrmSourceModel?>().firstWhere(
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
      return [stringValue(data, 'source_name')];
    });
    if (notify) {
      update();
    }
  }

  void selectItem(CrmSourceModel item, {bool notify = true}) {
    final data = item.toJson();
    selectedItem = item;
    nameController.text = stringValue(data, 'source_name');
    isActive = boolValue(data, 'is_active', fallback: true);
    formError = null;
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selectedItem = null;
    nameController.clear();
    isActive = true;
    formError = null;
    if (notify) {
      update();
    }
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

    final payload = CrmSourceModel.fromJson({
      'source_name': nameController.text.trim(),
      'is_active': isActive,
    });

    try {
      final response = selectedItem == null
          ? await _crmService.createSource(payload)
          : await _crmService.updateSource(
              intValue(selectedItem!.toJson(), 'id')!,
              payload,
            );
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      reloadCrmSourceRegister();
      await loadPage(
        selectId: intValue(response.data?.toJson() ?? const {}, 'id'),
      );
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
      final response = await _crmService.deleteSource(id);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      reloadCrmSourceRegister();
      await loadPage();
    } catch (error) {
      formError = error.toString();
      update();
    }
  }
}
