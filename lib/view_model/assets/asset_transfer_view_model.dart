import 'package:billing/screen.dart';
import 'package:billing/view/hr/hr_workflow_dialogs.dart';
import 'package:billing/view/purchase/purchase_support.dart';

class AssetTransferViewModel extends ChangeNotifier {
  AssetTransferViewModel() {
    searchController.addListener(notifyListeners);
  }

  final AssetsService _assets = AssetsService();

  final TextEditingController searchController = TextEditingController();

  bool loading = true;
  bool detailLoading = false;
  bool actionBusy = false;
  String? pageError;
  String? actionMessage;

  List<AssetTransferModel> rows = const <AssetTransferModel>[];
  AssetTransferModel? selected;
  AssetTransferModel? detail;

  List<AssetTransferModel> get filteredRows {
    final q = searchController.text.trim().toLowerCase();
    return rows
        .where((AssetTransferModel row) {
          if (q.isEmpty) {
            return true;
          }
          final data = row.toJson();
          return [
            stringValue(data, 'transfer_no'),
            stringValue(data, 'transfer_status'),
            _branchPair(data),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  String _branchPair(Map<String, dynamic> data) {
    final from = _jsonMap(data['fromBranch']);
    final to = _jsonMap(data['toBranch']);
    final a = from != null ? stringValue(from, 'name') : '';
    final b = to != null ? stringValue(to, 'name') : '';
    if (a.isEmpty && b.isEmpty) {
      return '';
    }
    return '$a → $b';
  }

  Map<String, dynamic>? _jsonMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  String listTitle(AssetTransferModel row) {
    final data = row.toJson();
    final no = stringValue(data, 'transfer_no');
    if (no.isNotEmpty) {
      return no;
    }
    final id = intValue(data, 'id');
    return id != null ? 'Transfer #$id' : 'Transfer';
  }

  String listSubtitle(AssetTransferModel row) {
    final data = row.toJson();
    return [
      displayDate(nullableStringValue(data, 'transfer_date')),
      stringValue(data, 'transfer_status'),
      _branchPair(data),
    ].where((s) => s.trim().isNotEmpty).join(' · ');
  }

  String? consumeActionMessage() {
    final m = actionMessage;
    actionMessage = null;
    return m;
  }

  Future<void> load({int? selectId}) async {
    loading = true;
    pageError = null;
    notifyListeners();
    try {
      final info = await hrSessionCompanyInfo();
      final filters = <String, dynamic>{'per_page': 200};
      if (info.companyId != null) {
        filters['company_id'] = info.companyId;
      }
      final res = await _assets.transfers(filters: filters);
      rows = res.data ?? const <AssetTransferModel>[];
      loading = false;

      if (selectId != null) {
        AssetTransferModel? inList;
        for (final AssetTransferModel r in rows) {
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
      final response = await _assets.transfer(id);
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
    notifyListeners();
  }

  Future<void> select(AssetTransferModel row) async {
    final id = intValue(row.toJson(), 'id');
    if (id == null) {
      return;
    }
    selected = row;
    detailLoading = true;
    notifyListeners();
    try {
      final response = await _assets.transfer(id);
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

  Future<void> refreshDetail() async {
    final id =
        intValue(detail?.toJson() ?? selected?.toJson() ?? {}, 'id');
    if (id == null) {
      return;
    }
    detailLoading = true;
    notifyListeners();
    try {
      final response = await _assets.transfer(id);
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

  Future<void> approve() async {
    final id = intValue(detail?.toJson() ?? {}, 'id');
    if (id == null) {
      return;
    }
    final empty = AssetTransferModel(<String, dynamic>{});
    await _runAction(() => _assets.approveTransfer(id, empty));
  }

  Future<void> complete() async {
    final id = intValue(detail?.toJson() ?? {}, 'id');
    if (id == null) {
      return;
    }
    final empty = AssetTransferModel(<String, dynamic>{});
    await _runAction(() => _assets.completeTransfer(id, empty));
  }

  Future<void> cancel() async {
    final id = intValue(detail?.toJson() ?? {}, 'id');
    if (id == null) {
      return;
    }
    final empty = AssetTransferModel(<String, dynamic>{});
    await _runAction(() => _assets.cancelTransfer(id, empty));
  }

  Future<bool> deleteTransfer() async {
    final id = intValue(detail?.toJson() ?? {}, 'id');
    if (id == null) {
      return false;
    }
    actionBusy = true;
    notifyListeners();
    try {
      final response = await _assets.deleteTransfer(id);
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
    Future<ApiResponse<AssetTransferModel>> Function() fn,
  ) async {
    actionBusy = true;
    notifyListeners();
    try {
      final response = await fn();
      if (response.success != true) {
        actionMessage = response.message;
        return;
      }
      actionMessage = 'Transfer updated.';
      await refreshDetail();
    } catch (e) {
      actionMessage = e.toString();
    } finally {
      actionBusy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
