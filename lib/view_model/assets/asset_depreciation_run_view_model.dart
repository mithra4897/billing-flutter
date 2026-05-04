import 'package:billing/screen.dart';
import 'package:billing/view/hr/hr_workflow_dialogs.dart';
import 'package:billing/view/purchase/purchase_support.dart';

class AssetDepreciationRunViewModel extends ChangeNotifier {
  AssetDepreciationRunViewModel() {
    searchController.addListener(notifyListeners);
  }

  final AssetsService _assets = AssetsService();
  final MasterService _master = MasterService();

  final TextEditingController searchController = TextEditingController();
  final TextEditingController runDateController = TextEditingController();
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();

  bool loading = true;
  bool detailLoading = false;
  bool actionBusy = false;
  bool createBusy = false;
  String? pageError;
  String? actionMessage;

  List<AssetDepreciationRunModel> rows = const <AssetDepreciationRunModel>[];
  AssetDepreciationRunModel? selected;
  AssetDepreciationRunModel? detail;

  List<DocumentSeriesModel> seriesOptions = const <DocumentSeriesModel>[];
  int? documentSeriesId;
  String bookType = 'financial';
  int? sessionCompanyId;

  static String _isoDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  List<AssetDepreciationRunModel> get filteredRows {
    final q = searchController.text.trim().toLowerCase();
    return rows
        .where((AssetDepreciationRunModel row) {
          if (q.isEmpty) {
            return true;
          }
          final data = row.toJson();
          return [
            stringValue(data, 'run_no'),
            stringValue(data, 'run_status'),
            stringValue(data, 'book_type'),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  String listTitle(AssetDepreciationRunModel row) {
    final data = row.toJson();
    final no = stringValue(data, 'run_no');
    if (no.isNotEmpty) {
      return no;
    }
    final id = intValue(data, 'id');
    return id != null ? 'Run #$id' : 'Depreciation run';
  }

  String listSubtitle(AssetDepreciationRunModel row) {
    final data = row.toJson();
    return [
      displayDate(nullableStringValue(data, 'run_date')),
      stringValue(data, 'run_status'),
      stringValue(data, 'book_type'),
    ].where((s) => s.trim().isNotEmpty).join(' · ');
  }

  String? consumeActionMessage() {
    final m = actionMessage;
    actionMessage = null;
    return m;
  }

  Future<void> _loadSeriesOptions() async {
    final response = await _master.documentSeries(
      filters: const {'per_page': 400},
    );
    final cid = sessionCompanyId;
    final rows =
        (response.data ?? const <DocumentSeriesModel>[])
            .where((DocumentSeriesModel s) {
              if (!s.isActive) {
                return false;
              }
              if ((s.documentType ?? '').trim() != 'ASSET_DEPRECIATION_RUN') {
                return false;
              }
              if (cid != null &&
                  s.companyId != null &&
                  s.companyId != cid) {
                return false;
              }
              return true;
            })
            .toList(growable: false);
    DocumentSeriesModel? chosen;
    for (final DocumentSeriesModel s in rows) {
      if (s.isDefault) {
        chosen = s;
        break;
      }
    }
    chosen ??= rows.isNotEmpty ? rows.first : null;
    seriesOptions = rows;
    documentSeriesId = chosen?.id;
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
      final res = await _assets.depreciationRuns(filters: filters);
      rows = res.data ?? const <AssetDepreciationRunModel>[];
      await _loadSeriesOptions();
      loading = false;

      if (selectId != null) {
        AssetDepreciationRunModel? inList;
        for (final AssetDepreciationRunModel r in rows) {
          if (intValue(r.toJson(), 'id') == selectId) {
            inList = r;
            break;
          }
        }
        if (inList != null) {
          await select(inList);
          return;
        }
        await _loadDetailById(selectId);
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

  Future<void> _loadDetailById(int id) async {
    detailLoading = true;
    notifyListeners();
    try {
      final response = await _assets.depreciationRun(id);
      if (response.success == true && response.data != null) {
        detail = response.data;
        selected = detail;
      } else {
        actionMessage = response.message;
      }
    } catch (e) {
      actionMessage = e.toString();
    } finally {
      detailLoading = false;
      notifyListeners();
    }
  }

  void resetDraft() {
    selected = null;
    detail = null;
    final now = DateTime.now();
    runDateController.text = _isoDate(now);
    fromDateController.text = _isoDate(DateTime(now.year, now.month, 1));
    toDateController.text = _isoDate(DateTime(now.year, now.month + 1, 0));
    bookType = 'financial';
    notifyListeners();
  }

  Future<void> select(AssetDepreciationRunModel row) async {
    final id = intValue(row.toJson(), 'id');
    if (id == null) {
      return;
    }
    selected = row;
    detailLoading = true;
    notifyListeners();
    try {
      final response = await _assets.depreciationRun(id);
      if (response.success == true && response.data != null) {
        detail = response.data;
      } else {
        actionMessage = response.message;
      }
    } catch (e) {
      actionMessage = e.toString();
    } finally {
      detailLoading = false;
      notifyListeners();
    }
  }

  Future<int?> createDraft() async {
    final cid = sessionCompanyId;
    if (cid == null) {
      actionMessage = 'Select a company in the header before creating.';
      notifyListeners();
      return null;
    }
    if (documentSeriesId == null) {
      actionMessage =
          'Configure an active ASSET_DEPRECIATION_RUN document series.';
      notifyListeners();
      return null;
    }
    createBusy = true;
    notifyListeners();
    try {
      final body = AssetDepreciationRunModel(<String, dynamic>{
        'company_id': cid,
        'run_date': runDateController.text.trim(),
        'depreciation_from_date': fromDateController.text.trim(),
        'depreciation_to_date': toDateController.text.trim(),
        'book_type': bookType,
        'document_series_id': documentSeriesId,
      });
      final response = await _assets.createDepreciationRun(body);
      if (response.success != true || response.data == null) {
        actionMessage = response.message;
        return null;
      }
      final newId = intValue(response.data!.toJson(), 'id');
      if (newId == null) {
        actionMessage = 'Created but missing id in response.';
        return null;
      }
      return newId;
    } catch (e) {
      actionMessage = e.toString();
      return null;
    } finally {
      createBusy = false;
      notifyListeners();
    }
  }

  Future<void> refreshDetail() async {
    final id =
        intValue(detail?.toJson() ?? selected?.toJson() ?? {}, 'id');
    if (id == null) {
      return;
    }
    detailLoading = true;
    notifyListeners();
    try {
      final response = await _assets.depreciationRun(id);
      if (response.success == true && response.data != null) {
        detail = response.data;
      } else {
        actionMessage = response.message;
      }
    } catch (e) {
      actionMessage = e.toString();
    } finally {
      detailLoading = false;
      notifyListeners();
    }
  }

  Future<void> runProcess() async {
    final id = intValue(detail?.toJson() ?? {}, 'id');
    if (id == null) {
      return;
    }
    final empty = AssetDepreciationRunModel(<String, dynamic>{});
    await _runAction(() => _assets.processDepreciationRun(id, empty));
  }

  Future<void> runPost() async {
    final id = intValue(detail?.toJson() ?? {}, 'id');
    if (id == null) {
      return;
    }
    final empty = AssetDepreciationRunModel(<String, dynamic>{});
    await _runAction(() => _assets.postDepreciationRun(id, empty));
  }

  Future<void> runCancel() async {
    final id = intValue(detail?.toJson() ?? {}, 'id');
    if (id == null) {
      return;
    }
    final empty = AssetDepreciationRunModel(<String, dynamic>{});
    await _runAction(() => _assets.cancelDepreciationRun(id, empty));
  }

  Future<bool> runDelete() async {
    final id = intValue(detail?.toJson() ?? {}, 'id');
    if (id == null) {
      return false;
    }
    actionBusy = true;
    notifyListeners();
    try {
      final response = await _assets.deleteDepreciationRun(id);
      if (response.success != true) {
        actionMessage = response.message;
        return false;
      }
      return true;
    } catch (e) {
      actionMessage = e.toString();
      return false;
    } finally {
      actionBusy = false;
      notifyListeners();
    }
  }

  Future<void> _runAction(
    Future<ApiResponse<AssetDepreciationRunModel>> Function() fn,
  ) async {
    actionBusy = true;
    notifyListeners();
    try {
      final response = await fn();
      if (response.success != true) {
        actionMessage = response.message;
        return;
      }
      actionMessage = 'Run updated.';
      await refreshDetail();
    } catch (e) {
      actionMessage = e.toString();
    } finally {
      actionBusy = false;
      notifyListeners();
    }
  }

  void setBookType(String v) {
    bookType = v;
    notifyListeners();
  }

  void setDocumentSeriesId(int? v) {
    documentSeriesId = v;
    notifyListeners();
  }

  @override
  void dispose() {
    searchController.dispose();
    runDateController.dispose();
    fromDateController.dispose();
    toDateController.dispose();
    super.dispose();
  }
}
