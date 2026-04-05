import '../../core/models/api_response.dart';
import '../../core/models/paginated_response.dart';
import '../../model/quality/qc_inspection_model.dart';
import '../../model/quality/qc_non_conformance_log_model.dart';
import '../../model/quality/qc_plan_model.dart';
import '../../model/quality/qc_result_action_model.dart';
import '../base/erp_module_service.dart';

class QualityService extends ErpModuleService {
  QualityService({super.apiClient});

  Future<PaginatedResponse<QcPlanModel>> qcPlans({
    Map<String, dynamic>? filters,
  }) => paginated<QcPlanModel>(
    '/quality/qc-plans',
    filters: filters,
    fromJson: QcPlanModel.fromJson,
  );
  Future<ApiResponse<QcPlanModel>> qcPlan(int id) => object<QcPlanModel>(
    '/quality/qc-plans/$id',
    fromJson: QcPlanModel.fromJson,
  );
  Future<ApiResponse<QcPlanModel>> createQcPlan(QcPlanModel body) =>
      createModel<QcPlanModel>(
        '/quality/qc-plans',
        body,
        fromJson: QcPlanModel.fromJson,
      );
  Future<ApiResponse<QcPlanModel>> updateQcPlan(int id, QcPlanModel body) =>
      updateModel<QcPlanModel>(
        '/quality/qc-plans/$id',
        body,
        fromJson: QcPlanModel.fromJson,
      );
  Future<ApiResponse<QcPlanModel>> approveQcPlan(int id, QcPlanModel body) =>
      actionModel<QcPlanModel>(
        '/quality/qc-plans/$id/approve',
        body: body,
        fromJson: QcPlanModel.fromJson,
      );
  Future<ApiResponse<QcPlanModel>> deactivateQcPlan(int id, QcPlanModel body) =>
      actionModel<QcPlanModel>(
        '/quality/qc-plans/$id/deactivate',
        body: body,
        fromJson: QcPlanModel.fromJson,
      );
  Future<ApiResponse<QcPlanModel>> obsoleteQcPlan(int id, QcPlanModel body) =>
      actionModel<QcPlanModel>(
        '/quality/qc-plans/$id/obsolete',
        body: body,
        fromJson: QcPlanModel.fromJson,
      );
  Future<ApiResponse<dynamic>> deleteQcPlan(int id) =>
      destroy('/quality/qc-plans/$id');

  Future<PaginatedResponse<QcInspectionModel>> qcInspections({
    Map<String, dynamic>? filters,
  }) => paginated<QcInspectionModel>(
    '/quality/qc-inspections',
    filters: filters,
    fromJson: QcInspectionModel.fromJson,
  );
  Future<ApiResponse<QcInspectionModel>> qcInspection(int id) =>
      object<QcInspectionModel>(
        '/quality/qc-inspections/$id',
        fromJson: QcInspectionModel.fromJson,
      );
  Future<ApiResponse<QcInspectionModel>> createQcInspection(
    QcInspectionModel body,
  ) => createModel<QcInspectionModel>(
    '/quality/qc-inspections',
    body,
    fromJson: QcInspectionModel.fromJson,
  );
  Future<ApiResponse<QcInspectionModel>> updateQcInspection(
    int id,
    QcInspectionModel body,
  ) => updateModel<QcInspectionModel>(
    '/quality/qc-inspections/$id',
    body,
    fromJson: QcInspectionModel.fromJson,
  );
  Future<ApiResponse<QcInspectionModel>> startQcInspection(
    int id,
    QcInspectionModel body,
  ) => actionModel<QcInspectionModel>(
    '/quality/qc-inspections/$id/start',
    body: body,
    fromJson: QcInspectionModel.fromJson,
  );
  Future<ApiResponse<QcInspectionModel>> completeQcInspection(
    int id,
    QcInspectionModel body,
  ) => actionModel<QcInspectionModel>(
    '/quality/qc-inspections/$id/complete',
    body: body,
    fromJson: QcInspectionModel.fromJson,
  );
  Future<ApiResponse<QcInspectionModel>> approveQcInspection(
    int id,
    QcInspectionModel body,
  ) => actionModel<QcInspectionModel>(
    '/quality/qc-inspections/$id/approve',
    body: body,
    fromJson: QcInspectionModel.fromJson,
  );
  Future<ApiResponse<QcInspectionModel>> rejectQcInspection(
    int id,
    QcInspectionModel body,
  ) => actionModel<QcInspectionModel>(
    '/quality/qc-inspections/$id/reject',
    body: body,
    fromJson: QcInspectionModel.fromJson,
  );
  Future<ApiResponse<QcInspectionModel>> cancelQcInspection(
    int id,
    QcInspectionModel body,
  ) => actionModel<QcInspectionModel>(
    '/quality/qc-inspections/$id/cancel',
    body: body,
    fromJson: QcInspectionModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteQcInspection(int id) =>
      destroy('/quality/qc-inspections/$id');

  Future<PaginatedResponse<QcResultActionModel>> qcResultActions({
    Map<String, dynamic>? filters,
  }) => paginated<QcResultActionModel>(
    '/quality/qc-result-actions',
    filters: filters,
    fromJson: QcResultActionModel.fromJson,
  );
  Future<ApiResponse<QcResultActionModel>> qcResultAction(int id) =>
      object<QcResultActionModel>(
        '/quality/qc-result-actions/$id',
        fromJson: QcResultActionModel.fromJson,
      );
  Future<ApiResponse<QcResultActionModel>> createQcResultAction(
    QcResultActionModel body,
  ) => createModel<QcResultActionModel>(
    '/quality/qc-result-actions',
    body,
    fromJson: QcResultActionModel.fromJson,
  );
  Future<ApiResponse<QcResultActionModel>> updateQcResultAction(
    int id,
    QcResultActionModel body,
  ) => updateModel<QcResultActionModel>(
    '/quality/qc-result-actions/$id',
    body,
    fromJson: QcResultActionModel.fromJson,
  );
  Future<ApiResponse<QcResultActionModel>> completeQcResultAction(
    int id,
    QcResultActionModel body,
  ) => actionModel<QcResultActionModel>(
    '/quality/qc-result-actions/$id/complete',
    body: body,
    fromJson: QcResultActionModel.fromJson,
  );
  Future<ApiResponse<QcResultActionModel>> cancelQcResultAction(
    int id,
    QcResultActionModel body,
  ) => actionModel<QcResultActionModel>(
    '/quality/qc-result-actions/$id/cancel',
    body: body,
    fromJson: QcResultActionModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteQcResultAction(int id) =>
      destroy('/quality/qc-result-actions/$id');

  Future<PaginatedResponse<QcNonConformanceLogModel>> qcNonConformanceLogs({
    Map<String, dynamic>? filters,
  }) => paginated<QcNonConformanceLogModel>(
    '/quality/qc-non-conformance-logs',
    filters: filters,
    fromJson: QcNonConformanceLogModel.fromJson,
  );
  Future<ApiResponse<QcNonConformanceLogModel>> qcNonConformanceLog(int id) =>
      object<QcNonConformanceLogModel>(
        '/quality/qc-non-conformance-logs/$id',
        fromJson: QcNonConformanceLogModel.fromJson,
      );
  Future<ApiResponse<QcNonConformanceLogModel>> createQcNonConformanceLog(
    QcNonConformanceLogModel body,
  ) => createModel<QcNonConformanceLogModel>(
    '/quality/qc-non-conformance-logs',
    body,
    fromJson: QcNonConformanceLogModel.fromJson,
  );
  Future<ApiResponse<QcNonConformanceLogModel>> updateQcNonConformanceLog(
    int id,
    QcNonConformanceLogModel body,
  ) => updateModel<QcNonConformanceLogModel>(
    '/quality/qc-non-conformance-logs/$id',
    body,
    fromJson: QcNonConformanceLogModel.fromJson,
  );
  Future<ApiResponse<QcNonConformanceLogModel>> closeQcNonConformanceLog(
    int id,
    QcNonConformanceLogModel body,
  ) => actionModel<QcNonConformanceLogModel>(
    '/quality/qc-non-conformance-logs/$id/close',
    body: body,
    fromJson: QcNonConformanceLogModel.fromJson,
  );
  Future<ApiResponse<QcNonConformanceLogModel>> waiveQcNonConformanceLog(
    int id,
    QcNonConformanceLogModel body,
  ) => actionModel<QcNonConformanceLogModel>(
    '/quality/qc-non-conformance-logs/$id/waive',
    body: body,
    fromJson: QcNonConformanceLogModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteQcNonConformanceLog(int id) =>
      destroy('/quality/qc-non-conformance-logs/$id');
}
