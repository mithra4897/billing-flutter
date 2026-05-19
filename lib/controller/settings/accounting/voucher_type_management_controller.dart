import '../../../screen.dart';

class VoucherTypeManagementController extends GetxController {
  VoucherTypeManagementController();

  final AccountsService _accountsService = AccountsService();

  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController documentTypeController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  List<VoucherTypeModel> types = const <VoucherTypeModel>[];
  List<VoucherTypeModel> filteredTypes = const <VoucherTypeModel>[];
  VoucherTypeModel? selectedType;
  String voucherCategory = 'journal';
  bool autoPost = true;
  bool requiresApproval = false;
  bool allowsReferenceAllocation = true;
  bool isActive = true;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_applySearch);
    loadTypes();
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
    documentTypeController.dispose();
    super.onClose();
  }

  Future<void> loadTypes({int? selectId}) async {
    initialLoading = types.isEmpty;
    pageError = null;
    update();

    try {
      final response = await _accountsService.voucherTypes(
        filters: const {'per_page': 300, 'sort_by': 'name'},
      );
      final items = response.data ?? const <VoucherTypeModel>[];

      types = items;
      filteredTypes = _filterTypes(items, searchController.text);
      initialLoading = false;

      final selected = selectId != null
          ? items.cast<VoucherTypeModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (selectedType == null
                ? (items.isNotEmpty ? items.first : null)
                : items.cast<VoucherTypeModel?>().firstWhere(
                    (item) => item?.id == selectedType?.id,
                    orElse: () => items.isNotEmpty ? items.first : null,
                  ));

      if (selected != null) {
        selectType(selected, notify: false);
      } else {
        resetForm(notify: false);
      }
    } catch (error) {
      initialLoading = false;
      pageError = error.toString();
    }

    update();
  }

  List<VoucherTypeModel> _filterTypes(
    List<VoucherTypeModel> source,
    String query,
  ) {
    return filterMasterList(source, query, (item) {
      return [
        item.code ?? '',
        item.name ?? '',
        item.voucherCategory ?? '',
        item.documentType ?? '',
      ];
    });
  }

  void _applySearch() {
    filteredTypes = _filterTypes(types, searchController.text);
    update();
  }

  void selectType(VoucherTypeModel item, {bool notify = true}) {
    selectedType = item;
    codeController.text = item.code ?? '';
    nameController.text = item.name ?? '';
    documentTypeController.text = item.documentType ?? '';
    voucherCategory = item.voucherCategory ?? 'journal';
    autoPost = item.autoPost;
    requiresApproval = item.requiresApproval;
    allowsReferenceAllocation = item.allowsReferenceAllocation;
    isActive = item.isActive;
    formError = null;
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selectedType = null;
    codeController.clear();
    nameController.clear();
    documentTypeController.clear();
    voucherCategory = 'journal';
    autoPost = true;
    requiresApproval = false;
    allowsReferenceAllocation = true;
    isActive = true;
    formError = null;
    if (notify) {
      update();
    }
  }

  void setVoucherCategory(String? value) {
    voucherCategory = value ?? 'journal';
    update();
  }

  void setAutoPost(bool value) {
    autoPost = value;
    update();
  }

  void setRequiresApproval(bool value) {
    requiresApproval = value;
    update();
  }

  void setAllowsReferenceAllocation(bool value) {
    allowsReferenceAllocation = value;
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

    final model = VoucherTypeModel(
      id: selectedType?.id,
      code: codeController.text.trim(),
      name: nameController.text.trim(),
      voucherCategory: voucherCategory,
      documentType: nullIfEmpty(documentTypeController.text),
      autoPost: autoPost,
      requiresApproval: requiresApproval,
      allowsReferenceAllocation: allowsReferenceAllocation,
      isSystemType: selectedType?.isSystemType ?? false,
      isActive: isActive,
    );

    try {
      final response = selectedType == null
          ? await _accountsService.createVoucherType(model)
          : await _accountsService.updateVoucherType(selectedType!.id!, model);
      final saved = response.data;
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadTypes(selectId: saved?.id);
    } catch (error) {
      formError = error.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> delete() async {
    final id = selectedType?.id;
    if (id == null) {
      return;
    }

    saving = true;
    formError = null;
    update();

    try {
      final response = await _accountsService.deleteVoucherType(id);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadTypes();
    } catch (error) {
      formError = error.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }
}
