import 'dart:convert';

import 'package:billing/screen.dart';

class MrpRecommendationViewModel extends ChangeNotifier {
  final PlanningService _service = PlanningService();
  final TextEditingController searchController = TextEditingController();

  bool loading = true;
  bool detailLoading = false;
  bool saving = false;
  String? pageError;
  String? formError;
  String? actionMessage;
  List<MrpRecommendationModel> rows = const <MrpRecommendationModel>[];
  MrpRecommendationModel? selected;

  MrpRecommendationViewModel() {
    searchController.addListener(notifyListeners);
  }

  List<MrpRecommendationModel> get filteredRows {
    final q = searchController.text.trim().toLowerCase();
    return rows.where((row) {
      final data = row.toJson();
      if (q.isEmpty) return true;
      return [
        stringValue(data, 'recommendation_type'),
        stringValue(data, 'recommendation_status'),
        stringValue(data, 'recommended_qty'),
      ].join(' ').toLowerCase().contains(q);
    }).toList(growable: false);
  }

  String? consumeActionMessage() {
    final value = actionMessage;
    actionMessage = null;
    return value;
  }

  Future<void> load({int? selectId}) async {
    loading = true;
    pageError = null;
    notifyListeners();
    try {
      final companyId = await SessionStorage.getCurrentCompanyId();
      if (companyId == null) {
        rows = const <MrpRecommendationModel>[];
        selected = null;
        loading = false;
        pageError = 'Select a company in the header to load MRP recommendations.';
        notifyListeners();
        return;
      }
      rows = (await _service.mrpRecommendations(
        filters: <String, dynamic>{'per_page': 100, 'company_id': companyId},
      ))
              .data ??
          const <MrpRecommendationModel>[];
      loading = false;
      if (selectId != null) {
        final existing = rows.cast<MrpRecommendationModel?>().firstWhere(
          (x) => intValue(x?.toJson() ?? const <String, dynamic>{}, 'id') == selectId,
          orElse: () => null,
        );
        if (existing != null) {
          await select(existing);
          return;
        }
      }
      selected = null;
      notifyListeners();
    } catch (e) {
      pageError = e.toString();
      loading = false;
      notifyListeners();
    }
  }

  Future<void> select(MrpRecommendationModel row) async {
    final id = intValue(row.toJson(), 'id');
    if (id == null) return;
    detailLoading = true;
    formError = null;
    notifyListeners();
    try {
      selected = (await _service.mrpRecommendation(id)).data ?? row;
    } catch (e) {
      formError = e.toString();
    } finally {
      detailLoading = false;
      notifyListeners();
    }
  }

  String get status => stringValue(
        selected?.toJson() ?? const <String, dynamic>{},
        'recommendation_status',
        'open',
      );

  String get detailText => const JsonEncoder.withIndent(
        '  ',
      ).convert(selected?.toJson() ?? const <String, dynamic>{});

  Future<void> approve() => _act((id) => _service.approveMrpRecommendation(
        id,
        const MrpRecommendationModel(<String, dynamic>{}),
      ));

  Future<void> reject() => _act((id) => _service.rejectMrpRecommendation(
        id,
        const MrpRecommendationModel(<String, dynamic>{}),
      ));

  Future<void> convert() => _act((id) => _service.convertMrpRecommendation(
        id,
        const MrpRecommendationModel(<String, dynamic>{}),
      ));

  Future<void> cancel() => _act((id) => _service.cancelMrpRecommendation(
        id,
        const MrpRecommendationModel(<String, dynamic>{}),
      ));

  Future<void> _act(
    Future<ApiResponse<MrpRecommendationModel>> Function(int id) fn,
  ) async {
    final id = intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');
    if (id == null) return;
    saving = true;
    formError = null;
    notifyListeners();
    try {
      final response = await fn(id);
      actionMessage = response.message;
      await load(selectId: id);
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
