import '../../core/models/api_response.dart';
import '../../core/models/paginated_response.dart';
import '../../model/planning/item_planning_policy_model.dart';
import '../../model/planning/mrp_demand_model.dart';
import '../../model/planning/mrp_net_requirement_model.dart';
import '../../model/planning/mrp_recommendation_model.dart';
import '../../model/planning/mrp_run_model.dart';
import '../../model/planning/mrp_supply_model.dart';
import '../../model/planning/planning_calendar_model.dart';
import '../../model/planning/stock_reservation_model.dart';
import '../base/erp_module_service.dart';

class PlanningService extends ErpModuleService {
  PlanningService({super.apiClient});

  Future<PaginatedResponse<StockReservationModel>> stockReservations({
    Map<String, dynamic>? filters,
  }) => paginated<StockReservationModel>(
    '/planning/stock-reservations',
    filters: filters,
    fromJson: StockReservationModel.fromJson,
  );
  Future<ApiResponse<StockReservationModel>> stockReservation(int id) =>
      object<StockReservationModel>(
        '/planning/stock-reservations/$id',
        fromJson: StockReservationModel.fromJson,
      );
  Future<ApiResponse<StockReservationModel>> createStockReservation(
    StockReservationModel body,
  ) => createModel<StockReservationModel>(
    '/planning/stock-reservations',
    body,
    fromJson: StockReservationModel.fromJson,
  );
  Future<ApiResponse<StockReservationModel>> updateStockReservation(
    int id,
    StockReservationModel body,
  ) => updateModel<StockReservationModel>(
    '/planning/stock-reservations/$id',
    body,
    fromJson: StockReservationModel.fromJson,
  );
  Future<ApiResponse<StockReservationModel>> releaseStockReservation(
    int id,
    StockReservationModel body,
  ) => actionModel<StockReservationModel>(
    '/planning/stock-reservations/$id/release',
    body: body,
    fromJson: StockReservationModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteStockReservation(int id) =>
      destroy('/planning/stock-reservations/$id');

  Future<PaginatedResponse<ItemPlanningPolicyModel>> itemPolicies({
    Map<String, dynamic>? filters,
  }) => paginated<ItemPlanningPolicyModel>(
    '/planning/item-policies',
    filters: filters,
    fromJson: ItemPlanningPolicyModel.fromJson,
  );
  Future<ApiResponse<ItemPlanningPolicyModel>> itemPolicy(int id) =>
      object<ItemPlanningPolicyModel>(
        '/planning/item-policies/$id',
        fromJson: ItemPlanningPolicyModel.fromJson,
      );
  Future<ApiResponse<ItemPlanningPolicyModel>> createItemPolicy(
    ItemPlanningPolicyModel body,
  ) => createModel<ItemPlanningPolicyModel>(
    '/planning/item-policies',
    body,
    fromJson: ItemPlanningPolicyModel.fromJson,
  );
  Future<ApiResponse<ItemPlanningPolicyModel>> updateItemPolicy(
    int id,
    ItemPlanningPolicyModel body,
  ) => updateModel<ItemPlanningPolicyModel>(
    '/planning/item-policies/$id',
    body,
    fromJson: ItemPlanningPolicyModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteItemPolicy(int id) =>
      destroy('/planning/item-policies/$id');

  Future<PaginatedResponse<PlanningCalendarModel>> calendars({
    Map<String, dynamic>? filters,
  }) => paginated<PlanningCalendarModel>(
    '/planning/calendars',
    filters: filters,
    fromJson: PlanningCalendarModel.fromJson,
  );
  Future<ApiResponse<PlanningCalendarModel>> calendar(int id) =>
      object<PlanningCalendarModel>(
        '/planning/calendars/$id',
        fromJson: PlanningCalendarModel.fromJson,
      );
  Future<ApiResponse<PlanningCalendarModel>> createCalendar(
    PlanningCalendarModel body,
  ) => createModel<PlanningCalendarModel>(
    '/planning/calendars',
    body,
    fromJson: PlanningCalendarModel.fromJson,
  );
  Future<ApiResponse<PlanningCalendarModel>> updateCalendar(
    int id,
    PlanningCalendarModel body,
  ) => updateModel<PlanningCalendarModel>(
    '/planning/calendars/$id',
    body,
    fromJson: PlanningCalendarModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteCalendar(int id) =>
      destroy('/planning/calendars/$id');

  Future<PaginatedResponse<MrpRunModel>> mrpRuns({
    Map<String, dynamic>? filters,
  }) => paginated<MrpRunModel>(
    '/planning/mrp-runs',
    filters: filters,
    fromJson: MrpRunModel.fromJson,
  );
  Future<ApiResponse<MrpRunModel>> mrpRun(int id) => object<MrpRunModel>(
    '/planning/mrp-runs/$id',
    fromJson: MrpRunModel.fromJson,
  );
  Future<ApiResponse<MrpRunModel>> createMrpRun(MrpRunModel body) =>
      createModel<MrpRunModel>(
        '/planning/mrp-runs',
        body,
        fromJson: MrpRunModel.fromJson,
      );
  Future<ApiResponse<MrpRunModel>> updateMrpRun(int id, MrpRunModel body) =>
      updateModel<MrpRunModel>(
        '/planning/mrp-runs/$id',
        body,
        fromJson: MrpRunModel.fromJson,
      );
  Future<ApiResponse<MrpRunModel>> processMrpRun(int id, MrpRunModel body) =>
      actionModel<MrpRunModel>(
        '/planning/mrp-runs/$id/process',
        body: body,
        fromJson: MrpRunModel.fromJson,
      );
  Future<ApiResponse<MrpRunModel>> cancelMrpRun(int id, MrpRunModel body) =>
      actionModel<MrpRunModel>(
        '/planning/mrp-runs/$id/cancel',
        body: body,
        fromJson: MrpRunModel.fromJson,
      );
  Future<ApiResponse<dynamic>> deleteMrpRun(int id) =>
      destroy('/planning/mrp-runs/$id');

  Future<PaginatedResponse<MrpDemandModel>> mrpDemands({
    Map<String, dynamic>? filters,
  }) => paginated<MrpDemandModel>(
    '/planning/mrp-demands',
    filters: filters,
    fromJson: MrpDemandModel.fromJson,
  );
  Future<ApiResponse<MrpDemandModel>> mrpDemand(int id) =>
      object<MrpDemandModel>(
        '/planning/mrp-demands/$id',
        fromJson: MrpDemandModel.fromJson,
      );
  Future<PaginatedResponse<MrpSupplyModel>> mrpSupplies({
    Map<String, dynamic>? filters,
  }) => paginated<MrpSupplyModel>(
    '/planning/mrp-supplies',
    filters: filters,
    fromJson: MrpSupplyModel.fromJson,
  );
  Future<ApiResponse<MrpSupplyModel>> mrpSupply(int id) =>
      object<MrpSupplyModel>(
        '/planning/mrp-supplies/$id',
        fromJson: MrpSupplyModel.fromJson,
      );
  Future<PaginatedResponse<MrpNetRequirementModel>> mrpNetRequirements({
    Map<String, dynamic>? filters,
  }) => paginated<MrpNetRequirementModel>(
    '/planning/mrp-net-requirements',
    filters: filters,
    fromJson: MrpNetRequirementModel.fromJson,
  );
  Future<ApiResponse<MrpNetRequirementModel>> mrpNetRequirement(int id) =>
      object<MrpNetRequirementModel>(
        '/planning/mrp-net-requirements/$id',
        fromJson: MrpNetRequirementModel.fromJson,
      );
  Future<PaginatedResponse<MrpRecommendationModel>> mrpRecommendations({
    Map<String, dynamic>? filters,
  }) => paginated<MrpRecommendationModel>(
    '/planning/mrp-recommendations',
    filters: filters,
    fromJson: MrpRecommendationModel.fromJson,
  );
  Future<ApiResponse<MrpRecommendationModel>> mrpRecommendation(int id) =>
      object<MrpRecommendationModel>(
        '/planning/mrp-recommendations/$id',
        fromJson: MrpRecommendationModel.fromJson,
      );
  Future<ApiResponse<MrpRecommendationModel>> approveMrpRecommendation(
    int id,
    MrpRecommendationModel body,
  ) => actionModel<MrpRecommendationModel>(
    '/planning/mrp-recommendations/$id/approve',
    body: body,
    fromJson: MrpRecommendationModel.fromJson,
  );
  Future<ApiResponse<MrpRecommendationModel>> rejectMrpRecommendation(
    int id,
    MrpRecommendationModel body,
  ) => actionModel<MrpRecommendationModel>(
    '/planning/mrp-recommendations/$id/reject',
    body: body,
    fromJson: MrpRecommendationModel.fromJson,
  );
  Future<ApiResponse<MrpRecommendationModel>> convertMrpRecommendation(
    int id,
    MrpRecommendationModel body,
  ) => actionModel<MrpRecommendationModel>(
    '/planning/mrp-recommendations/$id/convert',
    body: body,
    fromJson: MrpRecommendationModel.fromJson,
  );
  Future<ApiResponse<MrpRecommendationModel>> cancelMrpRecommendation(
    int id,
    MrpRecommendationModel body,
  ) => actionModel<MrpRecommendationModel>(
    '/planning/mrp-recommendations/$id/cancel',
    body: body,
    fromJson: MrpRecommendationModel.fromJson,
  );
}
