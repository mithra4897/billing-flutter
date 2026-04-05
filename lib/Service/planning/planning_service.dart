import '../base/erp_module_service.dart';

class PlanningService extends ErpModuleService {
  PlanningService({super.apiClient});

  Future stockReservations({Map<String, dynamic>? filters}) =>
      index('/planning/stock-reservations', filters: filters);
  Future stockReservation(int id) => show('/planning/stock-reservations/$id');
  Future createStockReservation(Map<String, dynamic> body) =>
      store('/planning/stock-reservations', body);
  Future updateStockReservation(int id, Map<String, dynamic> body) =>
      update('/planning/stock-reservations/$id', body);
  Future releaseStockReservation(int id, Map<String, dynamic> body) =>
      action('/planning/stock-reservations/$id/release', body: body);
  Future deleteStockReservation(int id) =>
      destroy('/planning/stock-reservations/$id');

  Future itemPolicies({Map<String, dynamic>? filters}) =>
      index('/planning/item-policies', filters: filters);
  Future itemPolicy(int id) => show('/planning/item-policies/$id');
  Future createItemPolicy(Map<String, dynamic> body) =>
      store('/planning/item-policies', body);
  Future updateItemPolicy(int id, Map<String, dynamic> body) =>
      update('/planning/item-policies/$id', body);
  Future deleteItemPolicy(int id) => destroy('/planning/item-policies/$id');

  Future calendars({Map<String, dynamic>? filters}) =>
      index('/planning/calendars', filters: filters);
  Future calendar(int id) => show('/planning/calendars/$id');
  Future createCalendar(Map<String, dynamic> body) =>
      store('/planning/calendars', body);
  Future updateCalendar(int id, Map<String, dynamic> body) =>
      update('/planning/calendars/$id', body);
  Future deleteCalendar(int id) => destroy('/planning/calendars/$id');

  Future mrpRuns({Map<String, dynamic>? filters}) =>
      index('/planning/mrp-runs', filters: filters);
  Future mrpRun(int id) => show('/planning/mrp-runs/$id');
  Future createMrpRun(Map<String, dynamic> body) =>
      store('/planning/mrp-runs', body);
  Future updateMrpRun(int id, Map<String, dynamic> body) =>
      update('/planning/mrp-runs/$id', body);
  Future processMrpRun(int id, Map<String, dynamic> body) =>
      action('/planning/mrp-runs/$id/process', body: body);
  Future cancelMrpRun(int id, Map<String, dynamic> body) =>
      action('/planning/mrp-runs/$id/cancel', body: body);
  Future deleteMrpRun(int id) => destroy('/planning/mrp-runs/$id');

  Future mrpDemands({Map<String, dynamic>? filters}) =>
      index('/planning/mrp-demands', filters: filters);
  Future mrpDemand(int id) => show('/planning/mrp-demands/$id');
  Future mrpSupplies({Map<String, dynamic>? filters}) =>
      index('/planning/mrp-supplies', filters: filters);
  Future mrpSupply(int id) => show('/planning/mrp-supplies/$id');
  Future mrpNetRequirements({Map<String, dynamic>? filters}) =>
      index('/planning/mrp-net-requirements', filters: filters);
  Future mrpNetRequirement(int id) =>
      show('/planning/mrp-net-requirements/$id');
  Future mrpRecommendations({Map<String, dynamic>? filters}) =>
      index('/planning/mrp-recommendations', filters: filters);
  Future mrpRecommendation(int id) => show('/planning/mrp-recommendations/$id');
  Future approveMrpRecommendation(int id, Map<String, dynamic> body) =>
      action('/planning/mrp-recommendations/$id/approve', body: body);
  Future rejectMrpRecommendation(int id, Map<String, dynamic> body) =>
      action('/planning/mrp-recommendations/$id/reject', body: body);
  Future convertMrpRecommendation(int id, Map<String, dynamic> body) =>
      action('/planning/mrp-recommendations/$id/convert', body: body);
  Future cancelMrpRecommendation(int id, Map<String, dynamic> body) =>
      action('/planning/mrp-recommendations/$id/cancel', body: body);
}
