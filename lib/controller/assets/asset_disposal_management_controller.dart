import '../../screen.dart';
import '../../view_model/assets/asset_module_refresh_controller.dart';

Map<String, dynamic>? assetDisposalJsonMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}

String assetDisposalAssetLabel(Map<String, dynamic> data) {
  final asset = assetDisposalJsonMap(data['asset']);
  if (asset == null) {
    return '';
  }
  final code = stringValue(asset, 'asset_code');
  final name = stringValue(asset, 'asset_name');
  if (code.isNotEmpty && name.isNotEmpty) {
    return '$code - $name';
  }
  return code.isNotEmpty ? code : name;
}

int? assetDisposalAssetCompanyId(Map<String, dynamic> data) {
  final asset = assetDisposalJsonMap(data['asset']);
  if (asset == null) {
    return null;
  }
  return intValue(asset, 'company_id');
}

String assetDisposalPartyName(Map<String, dynamic> data) {
  final party = assetDisposalJsonMap(data['saleParty']);
  if (party == null) {
    return '';
  }
  final displayName = stringValue(party, 'display_name');
  if (displayName.isNotEmpty) {
    return displayName;
  }
  return stringValue(party, 'party_name');
}

class AssetDisposalManagementController extends GetxController {
  AssetDisposalManagementController({this.initialId});

  final int? initialId;

  final AssetsService _assets = AssetsService();
  final AssetModuleRefreshController _refreshController =
      AssetModuleRefreshController.ensureRegistered();
  final MasterService _master = MasterService();
  final PartiesService _partiesService = PartiesService();

  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController disposalNoController = TextEditingController();
  final TextEditingController disposalDateController = TextEditingController();
  final TextEditingController disposalTypeController = TextEditingController();
  final TextEditingController disposalValueController = TextEditingController();
  final TextEditingController expenseController = TextEditingController();
  final TextEditingController bookValueController = TextEditingController();
  final TextEditingController gainLossController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool loading = true;
  bool detailLoading = false;
  bool saving = false;
  bool actionBusy = false;
  String? pageError;
  String? formError;
  String? actionMessage;
  String? companyBanner;
  int? sessionCompanyId;

  List<AssetDisposalModel> rows = const <AssetDisposalModel>[];
  List<AssetModel> assetsList = const <AssetModel>[];
  List<PartyModel> parties = const <PartyModel>[];
  List<DocumentSeriesModel> series = const <DocumentSeriesModel>[];

  AssetDisposalModel? selected;
  AssetDisposalModel? detail;

  int? assetId;
  int? salePartyId;
  int? documentSeriesId;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(update);
    load(selectId: initialId);
  }

  @override
  void onClose() {
    pageScrollController.dispose();
    workspaceController.dispose();
    searchController
      ..removeListener(update)
      ..dispose();
    disposalNoController.dispose();
    disposalDateController.dispose();
    disposalTypeController.dispose();
    disposalValueController.dispose();
    expenseController.dispose();
    bookValueController.dispose();
    gainLossController.dispose();
    remarksController.dispose();
    super.onClose();
  }

  String? consumeActionMessage() {
    final message = actionMessage;
    actionMessage = null;
    return message;
  }

  List<AssetDisposalModel> get filteredRows {
    final query = searchController.text.trim().toLowerCase();
    return rows
        .where((row) {
          final data = row.toJson();
          if (query.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'disposal_no'),
            stringValue(data, 'disposal_status'),
            assetDisposalAssetLabel(data),
            assetDisposalPartyName(data),
          ].join(' ').toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  List<DocumentSeriesModel> get seriesOptions {
    return series
        .where((item) {
          if ((item.documentType ?? '').toUpperCase() != 'ASSET_DISPOSAL') {
            return false;
          }
          if (sessionCompanyId != null && item.companyId != sessionCompanyId) {
            return false;
          }
          return item.isActive;
        })
        .toList(growable: false);
  }

  String listTitle(AssetDisposalModel row) {
    final data = row.toJson();
    final no = stringValue(data, 'disposal_no');
    if (no.isNotEmpty) {
      return no;
    }
    final asset = assetDisposalAssetLabel(data);
    return asset.isNotEmpty ? asset : 'Disposal';
  }

  String listSubtitle(AssetDisposalModel row) {
    final data = row.toJson();
    return [
      assetDisposalAssetLabel(data),
      assetDisposalPartyName(data),
      stringValue(data, 'disposal_status'),
    ].where((value) => value.trim().isNotEmpty).join(' · ');
  }

  String listAssetOption(AssetModel asset) {
    final data = asset.toJson();
    final code = stringValue(data, 'asset_code');
    final name = stringValue(data, 'asset_name');
    if (code.isNotEmpty && name.isNotEmpty) {
      return '$code - $name';
    }
    return code.isNotEmpty ? code : name;
  }

  String get scopeHint => sessionCompanyId != null
      ? 'Disposals are filtered client-side by nested asset.company_id.'
      : 'API list is not company-scoped; select a session company to filter.';

  void resetDraft() {
    selected = null;
    detail = null;
    formError = null;
    assetId = null;
    salePartyId = null;
    documentSeriesId = null;
    disposalNoController.clear();
    disposalDateController.clear();
    disposalTypeController.clear();
    disposalValueController.clear();
    expenseController.clear();
    bookValueController.clear();
    gainLossController.clear();
    remarksController.clear();
    update();
  }

  void applyFromModel(AssetDisposalModel model) {
    final data = model.toJson();
    assetId = intValue(data, 'asset_id');
    salePartyId = intValue(data, 'sale_party_id');
    documentSeriesId = intValue(data, 'document_series_id');
    disposalNoController.text = stringValue(data, 'disposal_no');
    disposalDateController.text = stringValue(data, 'disposal_date');
    disposalTypeController.text = stringValue(data, 'disposal_type');
    disposalValueController.text = data['disposal_value']?.toString() ?? '';
    expenseController.text = data['disposal_expense']?.toString() ?? '';
    bookValueController.text = data['book_value_at_disposal']?.toString() ?? '';
    gainLossController.text = data['gain_or_loss_amount']?.toString() ?? '';
    remarksController.text = stringValue(data, 'remarks');
  }

  Future<void> load({int? selectId}) async {
    loading = true;
    pageError = null;
    update();
    try {
      final info = await hrSessionCompanyInfo();
      sessionCompanyId = info.companyId;
      companyBanner = info.banner;
      final assetFilters = <String, dynamic>{'per_page': 300};
      if (info.companyId != null) {
        assetFilters['company_id'] = info.companyId;
      }
      final responses = await Future.wait<dynamic>([
        _assets.disposals(filters: const {'per_page': 200}),
        _assets.assets(filters: assetFilters),
        _partiesService.parties(filters: const {'per_page': 500}),
        _master.documentSeries(filters: const {'per_page': 400}),
      ]);

      var nextRows =
          (responses[0] as PaginatedResponse<AssetDisposalModel>).data ??
          const <AssetDisposalModel>[];
      if (info.companyId != null) {
        nextRows = nextRows
            .where((row) {
              return assetDisposalAssetCompanyId(row.toJson()) ==
                  info.companyId;
            })
            .toList(growable: false);
      }

      rows = nextRows;
      assetsList =
          (responses[1] as PaginatedResponse<AssetModel>).data ??
          const <AssetModel>[];
      parties =
          ((responses[2] as PaginatedResponse<PartyModel>).data ??
                  const <PartyModel>[])
              .where((party) => party.isActive)
              .toList(growable: false);
      series =
          (responses[3] as PaginatedResponse<DocumentSeriesModel>).data ??
          const <DocumentSeriesModel>[];

      loading = false;

      if (selectId != null) {
        if (await restoreSelectionAfterReload<AssetDisposalModel>(
          selectId: selectId,
          rows: rows,
          selected: selected,
          onSelect: select,
          replaceRows: (nextRows) => rows = nextRows,
          notify: update,
          onMissingId: loadDetailById,
        )) {
          return;
        }
      }

      resetDraft();
    } catch (errorValue) {
      pageError = errorValue.toString();
      loading = false;
      update();
    }
  }

  Future<void> reloadList() async {
    final info = await hrSessionCompanyInfo();
    final response = await _assets.disposals(filters: const {'per_page': 200});
    var nextRows = response.data ?? const <AssetDisposalModel>[];
    if (info.companyId != null) {
      nextRows = nextRows
          .where((row) {
            return assetDisposalAssetCompanyId(row.toJson()) == info.companyId;
          })
          .toList(growable: false);
    }
    rows = nextRows;
    update();
  }

  Future<void> loadDetailById(int id) async {
    detailLoading = true;
    formError = null;
    update();
    try {
      final response = await _assets.disposal(id);
      if (response.success == true && response.data != null) {
        detail = response.data;
        selected = response.data;
        applyFromModel(response.data!);
      } else {
        formError = response.message;
      }
    } catch (errorValue) {
      formError = errorValue.toString();
    } finally {
      detailLoading = false;
      update();
    }
  }

  Future<void> select(AssetDisposalModel row) async {
    final id = intValue(row.toJson(), 'id');
    if (id == null) {
      return;
    }
    selected = row;
    detailLoading = true;
    formError = null;
    update();
    try {
      final response = await _assets.disposal(id);
      if (response.success == true && response.data != null) {
        detail = response.data;
        applyFromModel(response.data!);
      } else {
        formError = response.message;
      }
    } catch (errorValue) {
      formError = errorValue.toString();
    } finally {
      detailLoading = false;
      update();
    }
  }

  void setAssetId(int? value) {
    assetId = value;
    update();
  }

  void setDocumentSeriesId(int? value) {
    documentSeriesId = value;
    update();
  }

  void setSalePartyId(int? value) {
    salePartyId = value;
    update();
  }

  Future<int?> save() async {
    final nextAssetId = assetId;
    final disposalDate = disposalDateController.text.trim();
    final disposalType = disposalTypeController.text.trim();
    final disposalNo = disposalNoController.text.trim();
    if (nextAssetId == null) {
      formError = 'Asset is required.';
      update();
      return null;
    }
    if (disposalDate.isEmpty) {
      formError = 'Disposal date is required.';
      update();
      return null;
    }
    if (disposalType.isEmpty) {
      formError = 'Disposal type is required.';
      update();
      return null;
    }
    if (disposalNo.isEmpty && documentSeriesId == null) {
      formError = 'Enter disposal no. or select a series.';
      update();
      return null;
    }

    saving = true;
    formError = null;
    update();
    try {
      final payload = <String, dynamic>{
        'asset_id': nextAssetId,
        'disposal_date': disposalDate,
        'disposal_type': disposalType,
        if (disposalNo.isNotEmpty) 'disposal_no': disposalNo,
        if (documentSeriesId != null) 'document_series_id': documentSeriesId,
        if (salePartyId != null) 'sale_party_id': salePartyId,
        if (Validators.parseFlexibleNumber(disposalValueController.text) != null)
          'disposal_value': double.parse(disposalValueController.text.trim()),
        if (Validators.parseFlexibleNumber(expenseController.text) != null)
          'disposal_expense': double.parse(expenseController.text.trim()),
        if (nullIfEmpty(remarksController.text.trim()) != null)
          'remarks': remarksController.text.trim(),
      };

      final existingId = intValue(detail?.toJson() ?? const {}, 'id');
      final response = existingId == null
          ? await _assets.createDisposal(AssetDisposalModel.fromJson(payload))
          : await _assets.updateDisposal(
              existingId,
              AssetDisposalModel.fromJson(payload),
            );
      if (response.success != true || response.data == null) {
        formError = response.message;
        return null;
      }

      detail = response.data;
      selected = response.data;
      applyFromModel(response.data!);
      await reloadList();
      final savedId = intValue(response.data!.toJson(), 'id');
      if (savedId != null) {
        selected =
            rows.cast<AssetDisposalModel?>().firstWhere(
              (row) => intValue(row?.toJson() ?? const {}, 'id') == savedId,
              orElse: () => null,
            ) ??
            response.data;
      }
      actionMessage = existingId == null
          ? 'Disposal created.'
          : 'Disposal updated.';
      _refreshController.notifyChanged(source: 'asset_disposal');
      return savedId;
    } catch (errorValue) {
      formError = errorValue.toString();
      return null;
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> runAction(
    Future<ApiResponse<AssetDisposalModel>> Function() fn,
    String message,
  ) async {
    actionBusy = true;
    formError = null;
    update();
    try {
      final response = await fn();
      if (response.success != true || response.data == null) {
        formError = response.message;
        return;
      }
      detail = response.data;
      selected = response.data;
      applyFromModel(response.data!);
      await reloadList();
      actionMessage = message;
      _refreshController.notifyChanged(source: 'asset_disposal');
    } catch (errorValue) {
      formError = errorValue.toString();
    } finally {
      actionBusy = false;
      update();
    }
  }

  Future<bool> deleteCurrent() async {
    final id = intValue(detail?.toJson() ?? const {}, 'id');
    if (id == null) {
      return false;
    }
    actionBusy = true;
    formError = null;
    update();
    try {
      final response = await _assets.deleteDisposal(id);
      if (response.success != true) {
        formError = response.message;
        return false;
      }
      await reloadList();
      resetDraft();
      actionMessage = 'Disposal deleted.';
      _refreshController.notifyChanged(source: 'asset_disposal');
      return true;
    } catch (errorValue) {
      formError = errorValue.toString();
      return false;
    } finally {
      actionBusy = false;
      update();
    }
  }

  Future<void> approve() async {
    final id = intValue(detail?.toJson() ?? const {}, 'id');
    if (id == null) {
      return;
    }
    await runAction(
      () => _assets.approveDisposal(
        id,
        AssetDisposalModel.fromJson(<String, dynamic>{}),
      ),
      'Disposal updated.',
    );
  }

  Future<void> post() async {
    final id = intValue(detail?.toJson() ?? const {}, 'id');
    if (id == null) {
      return;
    }
    await runAction(
      () => _assets.postDisposal(
        id,
        AssetDisposalModel.fromJson(<String, dynamic>{}),
      ),
      'Disposal updated.',
    );
  }

  Future<void> cancel() async {
    final id = intValue(detail?.toJson() ?? const {}, 'id');
    if (id == null) {
      return;
    }
    await runAction(
      () => _assets.cancelDisposal(
        id,
        AssetDisposalModel.fromJson(<String, dynamic>{}),
      ),
      'Disposal updated.',
    );
  }

  void startNew({required bool isDesktop}) {
    resetDraft();
    if (!isDesktop) {
      workspaceController.openEditor();
    }
  }
}
