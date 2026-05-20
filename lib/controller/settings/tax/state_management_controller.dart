import '../../../screen.dart';

class StateManagementController extends GetxController {
  StateManagementController();

  final TaxesService _taxesService = TaxesService();

  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController countryCodeController = TextEditingController();
  final TextEditingController stateCodeController = TextEditingController();
  final TextEditingController stateNameController = TextEditingController();
  final TextEditingController gstStateCodeController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  List<StateModel> states = const <StateModel>[];
  List<StateModel> filteredStates = const <StateModel>[];
  StateModel? selectedState;
  bool isUnionTerritory = false;
  bool isActive = true;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_applySearch);
    loadStates();
  }

  @override
  void onClose() {
    pageScrollController.dispose();
    workspaceController.dispose();
    searchController
      ..removeListener(_applySearch)
      ..dispose();
    countryCodeController.dispose();
    stateCodeController.dispose();
    stateNameController.dispose();
    gstStateCodeController.dispose();
    super.onClose();
  }

  Future<void> loadStates({int? selectId}) async {
    initialLoading = states.isEmpty;
    pageError = null;
    update();

    try {
      final response = await _taxesService.states(
        filters: const {'per_page': 200, 'sort_by': 'state_name'},
      );
      final items = response.data ?? const <StateModel>[];

      states = items;
      filteredStates = _filterStates(items, searchController.text);
      initialLoading = false;

      final selected = selectId != null
          ? items.cast<StateModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (selectedState == null
                ? (items.isNotEmpty ? items.first : null)
                : items.cast<StateModel?>().firstWhere(
                    (item) => item?.id == selectedState?.id,
                    orElse: () => items.isNotEmpty ? items.first : null,
                  ));

      if (selected != null) {
        selectState(selected, notify: false);
      } else {
        resetForm(notify: false);
      }
    } catch (error) {
      initialLoading = false;
      pageError = error.toString();
    }

    update();
  }

  List<StateModel> _filterStates(List<StateModel> source, String query) {
    return filterMasterList(source, query, (item) {
      return [item.stateCode, item.stateName, item.gstStateCode];
    });
  }

  void _applySearch() {
    filteredStates = _filterStates(states, searchController.text);
    update();
  }

  void selectState(StateModel item, {bool notify = true}) {
    selectedState = item;
    countryCodeController.text = item.countryCode;
    stateCodeController.text = item.stateCode;
    stateNameController.text = item.stateName;
    gstStateCodeController.text = item.gstStateCode;
    isUnionTerritory = item.isUnionTerritory;
    isActive = item.isActive;
    formError = null;
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selectedState = null;
    countryCodeController.text = 'IN';
    stateCodeController.clear();
    stateNameController.clear();
    gstStateCodeController.clear();
    isUnionTerritory = false;
    isActive = true;
    formError = null;
    if (notify) {
      update();
    }
  }

  void setIsUnionTerritory(bool value) {
    isUnionTerritory = value;
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

    final model = StateModel(
      id: selectedState?.id,
      countryCode: countryCodeController.text.trim(),
      stateCode: stateCodeController.text.trim(),
      stateName: stateNameController.text.trim(),
      gstStateCode: gstStateCodeController.text.trim(),
      isUnionTerritory: isUnionTerritory,
      isActive: isActive,
    );

    try {
      final response = selectedState == null
          ? await _taxesService.createState(model)
          : await _taxesService.updateState(selectedState!.id!, model);
      final saved = response.data;
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadStates(selectId: saved?.id);
    } catch (error) {
      formError = error.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> delete() async {
    final id = selectedState?.id;
    if (id == null) {
      return;
    }

    saving = true;
    formError = null;
    update();

    try {
      final response = await _taxesService.deleteState(id);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadStates();
    } catch (error) {
      formError = error.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }
}
