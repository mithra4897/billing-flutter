import '../../../screen.dart';

class UomManagementController extends GetxController {
  UomManagementController({required this.initialTabIndex});

  final InventoryService _inventoryService = InventoryService();
  final int initialTabIndex;

  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController symbolController = TextEditingController();
  final GlobalKey<FormState> conversionFormKey = GlobalKey<FormState>();
  final TextEditingController conversionFactorController =
      TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  bool savingConversion = false;
  String? pageError;
  String? formError;
  String? conversionError;
  List<UomModel> uoms = const <UomModel>[];
  List<UomModel> filteredUoms = const <UomModel>[];
  List<UomConversionModel> conversions = const <UomConversionModel>[];
  UomModel? selectedUom;
  bool isActive = true;
  bool isFractionAllowed = false;
  int? conversionTargetUomId;
  bool conversionActive = true;
  UomConversionModel? selectedConversionRecord;
  bool selectedConversionReversed = false;
  int activeTabIndex = 0;

  @override
  void onInit() {
    super.onInit();
    activeTabIndex = initialTabIndex.clamp(0, 1);
    searchController.addListener(_applySearch);
    loadData();
  }

  @override
  void onClose() {
    pageScrollController.dispose();
    workspaceController.dispose();
    searchController
      ..removeListener(_applySearch)
      ..dispose();
    codeController.dispose();
    nameController.dispose();
    symbolController.dispose();
    conversionFactorController.dispose();
    super.onClose();
  }

  Future<void> loadData({int? selectId}) async {
    initialLoading = uoms.isEmpty;
    pageError = null;
    update();

    try {
      await MasterDataCache.to.ensureLoaded();
      final cache = MasterDataCache.to;
      final responses = await Future.wait<dynamic>([
        _inventoryService.uomConversions(
          filters: const {
            'per_page': 500,
            'sort_by': 'id',
            'sort_order': 'asc',
          },
        ),
      ]);

      final nextConversions =
          (responses[0] as PaginatedResponse<UomConversionModel>).data ??
          const <UomConversionModel>[];

      uoms = cache.activeUoms;
      conversions = nextConversions;
      filteredUoms = _filterUoms(uoms, searchController.text);
      initialLoading = false;

      final selected = selectId != null
          ? uoms.cast<UomModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (selectedUom == null
                ? (uoms.isNotEmpty ? uoms.first : null)
                : uoms.cast<UomModel?>().firstWhere(
                    (item) => item?.id == selectedUom?.id,
                    orElse: () => uoms.isNotEmpty ? uoms.first : null,
                  ));

      if (selected != null) {
        selectUom(selected, notify: false);
      } else {
        resetForm(notify: false);
      }
    } catch (error) {
      initialLoading = false;
      pageError = error.toString();
    }

    update();
  }

  List<UomModel> _filterUoms(List<UomModel> source, String query) {
    return filterMasterList(source, query, (uom) {
      return [uom.uomCode ?? '', uom.uomName ?? '', uom.symbol ?? ''];
    });
  }

  void _applySearch() {
    filteredUoms = _filterUoms(uoms, searchController.text);
    update();
  }

  void selectUom(UomModel uom, {bool notify = true}) {
    selectedUom = uom;
    codeController.text = uom.uomCode ?? '';
    nameController.text = uom.uomName ?? '';
    symbolController.text = uom.symbol ?? '';
    isFractionAllowed = uom.isFractionAllowed;
    isActive = uom.isActive;
    formError = null;
    resetConversionForm(notify: false);
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selectedUom = null;
    codeController.clear();
    nameController.clear();
    symbolController.clear();
    isFractionAllowed = false;
    isActive = true;
    formError = null;
    resetConversionForm(notify: false);
    if (notify) {
      update();
    }
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    saving = true;
    formError = null;
    update();

    final model = UomModel(
      id: selectedUom?.id,
      uomCode: codeController.text.trim(),
      uomName: nameController.text.trim(),
      symbol: symbolController.text.trim(),
      isFractionAllowed: isFractionAllowed,
      isActive: isActive,
    );

    try {
      final response = selectedUom == null
          ? await _inventoryService.createUom(model)
          : await _inventoryService.updateUom(selectedUom!.id!, model);
      final saved = response.data;
      if (saved == null) {
        formError = response.message;
        update();
        return;
      }

      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadData(selectId: saved.id);
    } catch (error) {
      formError = error.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> delete() async {
    final id = selectedUom?.id;
    if (id == null) {
      return;
    }

    saving = true;
    formError = null;
    update();

    try {
      final response = await _inventoryService.deleteUom(id);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadData();
    } catch (error) {
      formError = error.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  List<UomConversionViewModel> get displayConversions {
    final selectedId = selectedUom?.id;
    if (selectedId == null) {
      return const <UomConversionViewModel>[];
    }

    final views = <UomConversionViewModel>[];
    for (final record in conversions) {
      if (record.fromUomId == selectedId) {
        views.add(
          UomConversionViewModel(
            record: record,
            otherUomId: record.toUomId,
            otherLabel: _uomLabel(record.toUomName, record.toUomCode),
            displayFactor: record.conversionFactor,
            isActive: record.isActive,
            reversed: false,
          ),
        );
      } else if (record.toUomId == selectedId) {
        final factor = record.conversionFactor;
        views.add(
          UomConversionViewModel(
            record: record,
            otherUomId: record.fromUomId,
            otherLabel: _uomLabel(record.fromUomName, record.fromUomCode),
            displayFactor: factor == null || factor == 0 ? null : (1 / factor),
            isActive: record.isActive,
            reversed: true,
          ),
        );
      }
    }

    views.sort(
      (left, right) => left.otherLabel.toLowerCase().compareTo(
        right.otherLabel.toLowerCase(),
      ),
    );
    return views;
  }

  String _uomLabel(String? name, String? code) {
    final trimmedName = (name ?? '').trim();
    if (trimmedName.isNotEmpty) {
      return trimmedName;
    }
    return (code ?? '').trim();
  }

  void resetConversionForm({bool notify = true}) {
    final selectedId = selectedUom?.id;
    selectedConversionRecord = null;
    selectedConversionReversed = false;
    conversionFactorController.clear();
    conversionActive = true;
    conversionError = null;
    conversionTargetUomId = uoms
        .where((uom) => uom.id != null && uom.id != selectedId)
        .cast<UomModel?>()
        .firstWhere((_) => true, orElse: () => null)
        ?.id;
    if (notify) {
      update();
    }
  }

  void selectConversion(UomConversionViewModel view) {
    selectedConversionRecord = view.record;
    selectedConversionReversed = view.reversed;
    conversionTargetUomId = view.otherUomId;
    conversionFactorController.text = view.displayFactor?.toString() ?? '';
    conversionActive = view.isActive;
    conversionError = null;
    update();
  }

  Future<void> saveConversion() async {
    final currentUomId = selectedUom?.id;
    if (currentUomId == null ||
        !(conversionFormKey.currentState?.validate() ?? false)) {
      return;
    }

    final targetUomId = conversionTargetUomId;
    final displayFactor = Validators.parseFlexibleNumber(
      conversionFactorController.text,
    );
    if (targetUomId == null || displayFactor == null || displayFactor <= 0) {
      conversionError = 'Target UOM and valid conversion factor are required.';
      update();
      return;
    }

    final fromUomId = selectedConversionRecord == null
        ? currentUomId
        : (selectedConversionReversed ? targetUomId : currentUomId);
    final toUomId = selectedConversionRecord == null
        ? targetUomId
        : (selectedConversionReversed ? currentUomId : targetUomId);
    final storedFactor = selectedConversionReversed
        ? 1 / displayFactor
        : displayFactor;

    savingConversion = true;
    conversionError = null;
    update();

    final model = UomConversionModel(
      id: selectedConversionRecord?.id,
      fromUomId: fromUomId,
      toUomId: toUomId,
      conversionFactor: storedFactor,
      isActive: conversionActive,
    );

    try {
      final response = selectedConversionRecord == null
          ? await _inventoryService.createUomConversion(model)
          : await _inventoryService.updateUomConversion(
              selectedConversionRecord!.id!,
              model,
            );
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadData(selectId: currentUomId);
    } catch (error) {
      conversionError = error.toString();
      update();
    } finally {
      savingConversion = false;
      update();
    }
  }

  Future<void> deleteConversion() async {
    final id = selectedConversionRecord?.id;
    final currentUomId = selectedUom?.id;
    if (id == null || currentUomId == null) {
      return;
    }

    savingConversion = true;
    conversionError = null;
    update();

    try {
      final response = await _inventoryService.deleteUomConversion(id);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadData(selectId: currentUomId);
    } catch (error) {
      conversionError = error.toString();
      update();
    } finally {
      savingConversion = false;
      update();
    }
  }

  void startNewUom({required bool isDesktop}) {
    resetForm();
    activeTabIndex = 0;
    update();
    if (!isDesktop) {
      workspaceController.openEditor();
    }
  }

  void setIsFractionAllowed(bool value) {
    isFractionAllowed = value;
    update();
  }

  void setIsActive(bool value) {
    isActive = value;
    update();
  }

  void setConversionTargetUomId(int? value) {
    conversionTargetUomId = value;
    update();
  }

  void setConversionActive(bool value) {
    conversionActive = value;
    update();
  }

  void setActiveTabIndex(int index) {
    activeTabIndex = index;
    update();
  }
}

class UomConversionViewModel {
  const UomConversionViewModel({
    required this.record,
    required this.otherUomId,
    required this.otherLabel,
    required this.displayFactor,
    required this.isActive,
    required this.reversed,
  });

  final UomConversionModel record;
  final int? otherUomId;
  final String otherLabel;
  final double? displayFactor;
  final bool isActive;
  final bool reversed;
}
