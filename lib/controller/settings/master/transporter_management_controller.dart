import '../../../screen.dart';

const List<AppDropdownItem<String>> transporterTypeItems =
    <AppDropdownItem<String>>[
      AppDropdownItem(value: 'courier', label: 'Courier'),
      AppDropdownItem(value: 'local', label: 'Local'),
      AppDropdownItem(value: 'vehicle', label: 'Vehicle'),
      AppDropdownItem(value: 'third_party', label: 'Third Party'),
    ];

const List<AppDropdownItem<String>> transporterDeliveryModeItems =
    <AppDropdownItem<String>>[
      AppDropdownItem(value: 'direct_delivery', label: 'Direct Delivery'),
      AppDropdownItem(value: 'pickup_by_us', label: 'Pickup By Us'),
    ];

class TransporterManagementController extends GetxController {
  final InventoryService _inventoryService = InventoryService();

  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  List<TransporterModel> transporters = const <TransporterModel>[];
  List<TransporterModel> filteredTransporters = const <TransporterModel>[];
  TransporterModel? selectedTransporter;
  String transporterType = 'courier';
  String deliveryMode = 'direct_delivery';
  bool isActive = true;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_applySearch);
    loadTransporters();
  }

  @override
  void onClose() {
    pageScrollController.dispose();
    workspaceController.dispose();
    searchController
      ..removeListener(_applySearch)
      ..dispose();
    nameController.dispose();
    remarksController.dispose();
    super.onClose();
  }

  Future<void> loadTransporters({int? selectId}) async {
    initialLoading = transporters.isEmpty;
    pageError = null;
    update();

    try {
      final response = await _inventoryService.transporters(
        filters: const {'per_page': 200, 'sort_by': 'name'},
      );
      final items = response.data ?? const <TransporterModel>[];

      transporters = items;
      filteredTransporters = _filterTransporters(items, searchController.text);
      initialLoading = false;

      final selected = selectId != null
          ? items.cast<TransporterModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (selectedTransporter == null
                ? (items.isNotEmpty ? items.first : null)
                : items.cast<TransporterModel?>().firstWhere(
                    (item) => item?.id == selectedTransporter?.id,
                    orElse: () => items.isNotEmpty ? items.first : null,
                  ));

      if (selected != null) {
        selectTransporter(selected, notify: false);
      } else {
        resetForm(notify: false);
      }
    } catch (error) {
      initialLoading = false;
      pageError = error.toString();
    }

    update();
  }

  List<TransporterModel> _filterTransporters(
    List<TransporterModel> source,
    String query,
  ) {
    return filterMasterList(source, query, (transporter) {
      return [
        transporter.name ?? '',
        transporter.transporterTypeLabel,
        transporter.deliveryModeLabel,
        transporter.remarks ?? '',
      ];
    });
  }

  void _applySearch() {
    filteredTransporters = _filterTransporters(transporters, searchController.text);
    update();
  }

  void selectTransporter(TransporterModel transporter, {bool notify = true}) {
    selectedTransporter = transporter;
    nameController.text = transporter.name ?? '';
    transporterType = transporter.transporterType ?? 'courier';
    deliveryMode = transporter.deliveryMode ?? 'direct_delivery';
    remarksController.text = transporter.remarks ?? '';
    isActive = transporter.isActive;
    formError = null;
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selectedTransporter = null;
    nameController.clear();
    transporterType = 'courier';
    deliveryMode = 'direct_delivery';
    remarksController.clear();
    isActive = true;
    formError = null;
    if (notify) {
      update();
    }
  }

  void setTransporterType(String? value) {
    transporterType = value ?? 'courier';
    update();
  }

  void setDeliveryMode(String? value) {
    deliveryMode = value ?? 'direct_delivery';
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

    final model = TransporterModel(
      id: selectedTransporter?.id,
      name: nameController.text.trim(),
      transporterType: transporterType,
      deliveryMode: deliveryMode,
      remarks: nullIfEmpty(remarksController.text),
      isActive: isActive,
    );

    try {
      final response = selectedTransporter == null
          ? await _inventoryService.createTransporter(model)
          : await _inventoryService.updateTransporter(
              selectedTransporter!.id!,
              model,
            );
      final saved = response.data;
      if (saved == null) {
        formError = response.message;
        update();
        return;
      }

      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadTransporters(selectId: saved.id);
    } catch (error) {
      formError = error.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> delete() async {
    final id = selectedTransporter?.id;
    if (id == null) {
      return;
    }

    saving = true;
    formError = null;
    update();

    try {
      final response = await _inventoryService.deleteTransporter(id);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadTransporters();
    } catch (error) {
      formError = error.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }
}
