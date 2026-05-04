import 'package:billing/screen.dart';
import 'package:billing/view/hr/hr_workflow_dialogs.dart';

class AssetCategoryViewModel extends ChangeNotifier {
  AssetCategoryViewModel() {
    searchController.addListener(notifyListeners);
  }

  final AssetsService _assets = AssetsService();
  final MasterService _master = MasterService();

  final TextEditingController searchController = TextEditingController();
  final TextEditingController categoryCodeController = TextEditingController();
  final TextEditingController categoryNameController = TextEditingController();
  final TextEditingController assetTypeController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  final TextEditingController defaultDepreciationMethodController =
      TextEditingController();
  final TextEditingController defaultUsefulLifeMonthsController =
      TextEditingController();
  final TextEditingController defaultSalvageValueController =
      TextEditingController();
  final TextEditingController capitalizationThresholdController =
      TextEditingController();

  bool loading = true;
  bool detailLoading = false;
  bool saving = false;
  String? pageError;
  String? formError;
  String? actionMessage;

  List<AssetCategoryModel> rows = const <AssetCategoryModel>[];
  List<CompanyModel> companies = const <CompanyModel>[];
  AssetCategoryModel? selected;
  AssetCategoryModel? detail;

  int? companyId;
  int? parentCategoryId;
  int? sessionCompanyId;

  bool isActive = true;
  bool isDepreciable = true;
  bool isTagRequired = false;
  bool isSerialRequired = false;

  List<AssetCategoryModel> get filteredRows {
    final q = searchController.text.trim().toLowerCase();
    return rows
        .where((AssetCategoryModel row) {
          if (q.isEmpty) {
            return true;
          }
          final data = row.toJson();
          return [
            stringValue(data, 'category_code'),
            stringValue(data, 'category_name'),
            stringValue(data, 'asset_type'),
            _parentLabel(data),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  String _parentLabel(Map<String, dynamic> data) {
    final p = data['parent'];
    if (p is! Map) {
      return '';
    }
    final m = Map<String, dynamic>.from(p);
    return stringValue(m, 'category_name');
  }

  String listTitle(AssetCategoryModel row) {
    final data = row.toJson();
    final c = stringValue(data, 'category_code');
    if (c.isNotEmpty) {
      return c;
    }
    return stringValue(data, 'category_name');
  }

  String listSubtitle(AssetCategoryModel row) {
    final data = row.toJson();
    return [
      stringValue(data, 'category_name'),
      stringValue(data, 'asset_type'),
    ].where((s) => s.trim().isNotEmpty).join(' · ');
  }

  String? consumeActionMessage() {
    final m = actionMessage;
    actionMessage = null;
    return m;
  }

  List<AssetCategoryModel> parentOptions() {
    final editingId = intValue(detail?.toJson() ?? const {}, 'id');
    return rows
        .where((AssetCategoryModel r) {
          final id = intValue(r.toJson(), 'id');
          if (id == null) {
            return false;
          }
          if (editingId != null && id == editingId) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  void _applyFromModel(AssetCategoryModel? m) {
    if (m == null) {
      return;
    }
    final d = m.toJson();
    categoryCodeController.text = stringValue(d, 'category_code');
    categoryNameController.text = stringValue(d, 'category_name');
    assetTypeController.text = stringValue(d, 'asset_type');
    remarksController.text = stringValue(d, 'remarks');
    defaultDepreciationMethodController.text =
        stringValue(d, 'default_depreciation_method');
    defaultUsefulLifeMonthsController.text =
        intValue(d, 'default_useful_life_months')?.toString() ?? '';
    defaultSalvageValueController.text =
        d['default_salvage_value']?.toString() ?? '';
    capitalizationThresholdController.text =
        d['capitalization_threshold']?.toString() ?? '';
    companyId = intValue(d, 'company_id');
    parentCategoryId = intValue(d, 'parent_category_id');
    isActive = d['is_active'] == true || d['is_active'] == 1;
    isDepreciable = d['is_depreciable'] == true || d['is_depreciable'] == 1;
    isTagRequired = d['is_tag_required'] == true || d['is_tag_required'] == 1;
    isSerialRequired =
        d['is_serial_required'] == true || d['is_serial_required'] == 1;
  }

  void clearForm() {
    categoryCodeController.clear();
    categoryNameController.clear();
    assetTypeController.clear();
    remarksController.clear();
    defaultDepreciationMethodController.clear();
    defaultUsefulLifeMonthsController.clear();
    defaultSalvageValueController.clear();
    capitalizationThresholdController.clear();
    parentCategoryId = null;
    isActive = true;
    isDepreciable = true;
    isTagRequired = false;
    isSerialRequired = false;
  }

  void resetDraft() {
    selected = null;
    detail = null;
    formError = null;
    clearForm();
    companyId = sessionCompanyId;
    if (companyId == null && companies.isNotEmpty) {
      companyId = companies.first.id;
    }
    notifyListeners();
  }

  Map<String, dynamic> _buildPayload() {
    final body = <String, dynamic>{
      'company_id': companyId,
      'category_code': nullIfEmpty(categoryCodeController.text.trim()) ?? '',
      'category_name': nullIfEmpty(categoryNameController.text.trim()) ?? '',
      'asset_type': nullIfEmpty(assetTypeController.text.trim()),
      'remarks': nullIfEmpty(remarksController.text.trim()),
      'default_depreciation_method':
          nullIfEmpty(defaultDepreciationMethodController.text.trim()),
      'is_active': isActive,
      'is_depreciable': isDepreciable,
      'is_tag_required': isTagRequired,
      'is_serial_required': isSerialRequired,
    };
    if (parentCategoryId != null) {
      body['parent_category_id'] = parentCategoryId;
    }
    final life = int.tryParse(defaultUsefulLifeMonthsController.text.trim());
    if (life != null) {
      body['default_useful_life_months'] = life;
    }
    final sav = double.tryParse(defaultSalvageValueController.text.trim());
    if (sav != null) {
      body['default_salvage_value'] = sav;
    }
    final cap = double.tryParse(capitalizationThresholdController.text.trim());
    if (cap != null) {
      body['capitalization_threshold'] = cap;
    }
    return body;
  }

  Future<void> load({int? selectId}) async {
    loading = true;
    pageError = null;
    notifyListeners();
    try {
      final info = await hrSessionCompanyInfo();
      sessionCompanyId = info.companyId;
      final filters = <String, dynamic>{'per_page': 200};
      if (info.companyId != null) {
        filters['company_id'] = info.companyId;
      }
      final responses = await Future.wait<dynamic>([
        _assets.categories(filters: filters),
        _master.companies(filters: const {'per_page': 200}),
      ]);
      rows = (responses[0] as PaginatedResponse<AssetCategoryModel>).data ??
          const <AssetCategoryModel>[];
      companies = ((responses[1] as PaginatedResponse<CompanyModel>).data ??
              const <CompanyModel>[])
          .where((CompanyModel c) => c.isActive)
          .toList(growable: false);
      loading = false;

      if (selectId != null) {
        for (final AssetCategoryModel r in rows) {
          if (intValue(r.toJson(), 'id') == selectId) {
            await select(r);
            return;
          }
        }
        await _loadDetailByIdOnly(selectId);
        return;
      }
      resetDraft();
      notifyListeners();
    } catch (e) {
      pageError = e.toString();
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _loadDetailByIdOnly(int id) async {
    detailLoading = true;
    notifyListeners();
    try {
      final response = await _assets.category(id);
      if (response.success == true && response.data != null) {
        detail = response.data;
        selected = detail;
        _applyFromModel(detail);
      } else {
        formError = response.message;
      }
    } catch (e) {
      formError = e.toString();
    } finally {
      detailLoading = false;
      notifyListeners();
    }
  }

  Future<void> _reloadCategoryList() async {
    final info = await hrSessionCompanyInfo();
    final filters = <String, dynamic>{'per_page': 200};
    if (info.companyId != null) {
      filters['company_id'] = info.companyId;
    }
    final res = await _assets.categories(filters: filters);
    rows = res.data ?? const <AssetCategoryModel>[];
  }

  Future<void> select(AssetCategoryModel row) async {
    final id = intValue(row.toJson(), 'id');
    if (id == null) {
      return;
    }
    selected = row;
    detailLoading = true;
    formError = null;
    notifyListeners();
    try {
      final response = await _assets.category(id);
      if (response.success == true && response.data != null) {
        detail = response.data;
        _applyFromModel(detail);
      } else {
        formError = response.message;
      }
    } catch (e) {
      formError = e.toString();
    } finally {
      detailLoading = false;
      notifyListeners();
    }
  }

  Future<bool> save() async {
    final cid = companyId;
    if (cid == null) {
      formError = 'Company is required.';
      notifyListeners();
      return false;
    }
    final code = categoryCodeController.text.trim();
    final name = categoryNameController.text.trim();
    if (code.isEmpty || name.isEmpty) {
      formError = 'Category code and name are required.';
      notifyListeners();
      return false;
    }

    saving = true;
    formError = null;
    notifyListeners();
    try {
      final payload = _buildPayload();
      final existingId = intValue(detail?.toJson() ?? {}, 'id');
      if (existingId != null) {
        final flat = Map<String, dynamic>.from(detail!.toJson());
        flat.removeWhere((dynamic k, dynamic v) => v is Map || v is List);
        flat.addAll(payload);
        final response = await _assets.updateCategory(
          existingId,
          AssetCategoryModel(flat),
        );
        if (response.success != true || response.data == null) {
          formError = response.message;
          return false;
        }
        detail = response.data;
        _applyFromModel(detail);
        await _reloadCategoryList();
        final nid = intValue(detail!.toJson(), 'id');
        if (nid != null) {
          for (final AssetCategoryModel r in rows) {
            if (intValue(r.toJson(), 'id') == nid) {
              selected = r;
              break;
            }
          }
        }
        selected ??= detail;
        actionMessage = 'Category saved.';
        return true;
      }
      final response = await _assets.createCategory(
        AssetCategoryModel(payload),
      );
      if (response.success != true || response.data == null) {
        formError = response.message;
        return false;
      }
      detail = response.data;
      _applyFromModel(detail);
      await _reloadCategoryList();
      final newId = intValue(detail!.toJson(), 'id');
      if (newId != null) {
        for (final AssetCategoryModel r in rows) {
          if (intValue(r.toJson(), 'id') == newId) {
            selected = r;
            break;
          }
        }
      }
      selected ??= detail;
      actionMessage = 'Category created.';
      return true;
    } catch (e) {
      formError = e.toString();
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteCategory() async {
    final id = intValue(detail?.toJson() ?? {}, 'id');
    if (id == null) {
      return false;
    }
    saving = true;
    notifyListeners();
    try {
      final response = await _assets.deleteCategory(id);
      if (response.success != true) {
        formError = response.message;
        return false;
      }
      return true;
    } catch (e) {
      formError = e.toString();
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  void setCompanyId(int? v) {
    companyId = v;
    notifyListeners();
  }

  void setParentCategoryId(int? v) {
    parentCategoryId = v;
    notifyListeners();
  }

  void setIsActive(bool v) {
    isActive = v;
    notifyListeners();
  }

  void setIsDepreciable(bool v) {
    isDepreciable = v;
    notifyListeners();
  }

  void setIsTagRequired(bool v) {
    isTagRequired = v;
    notifyListeners();
  }

  void setIsSerialRequired(bool v) {
    isSerialRequired = v;
    notifyListeners();
  }

  @override
  void dispose() {
    searchController.dispose();
    categoryCodeController.dispose();
    categoryNameController.dispose();
    assetTypeController.dispose();
    remarksController.dispose();
    defaultDepreciationMethodController.dispose();
    defaultUsefulLifeMonthsController.dispose();
    defaultSalvageValueController.dispose();
    capitalizationThresholdController.dispose();
    super.dispose();
  }
}
