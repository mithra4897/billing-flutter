import '../base/erp_module_service.dart';

class QualityService extends ErpModuleService {
  QualityService({super.apiClient});

  Future qcPlans({Map<String, dynamic>? filters}) =>
      index('/quality/qc-plans', filters: filters);
  Future qcPlan(int id) => show('/quality/qc-plans/$id');
  Future createQcPlan(Map<String, dynamic> body) =>
      store('/quality/qc-plans', body);
  Future updateQcPlan(int id, Map<String, dynamic> body) =>
      update('/quality/qc-plans/$id', body);
  Future approveQcPlan(int id, Map<String, dynamic> body) =>
      action('/quality/qc-plans/$id/approve', body: body);
  Future deactivateQcPlan(int id, Map<String, dynamic> body) =>
      action('/quality/qc-plans/$id/deactivate', body: body);
  Future obsoleteQcPlan(int id, Map<String, dynamic> body) =>
      action('/quality/qc-plans/$id/obsolete', body: body);
  Future deleteQcPlan(int id) => destroy('/quality/qc-plans/$id');

  Future qcInspections({Map<String, dynamic>? filters}) =>
      index('/quality/qc-inspections', filters: filters);
  Future qcInspection(int id) => show('/quality/qc-inspections/$id');
  Future createQcInspection(Map<String, dynamic> body) =>
      store('/quality/qc-inspections', body);
  Future updateQcInspection(int id, Map<String, dynamic> body) =>
      update('/quality/qc-inspections/$id', body);
  Future startQcInspection(int id, Map<String, dynamic> body) =>
      action('/quality/qc-inspections/$id/start', body: body);
  Future completeQcInspection(int id, Map<String, dynamic> body) =>
      action('/quality/qc-inspections/$id/complete', body: body);
  Future approveQcInspection(int id, Map<String, dynamic> body) =>
      action('/quality/qc-inspections/$id/approve', body: body);
  Future rejectQcInspection(int id, Map<String, dynamic> body) =>
      action('/quality/qc-inspections/$id/reject', body: body);
  Future cancelQcInspection(int id, Map<String, dynamic> body) =>
      action('/quality/qc-inspections/$id/cancel', body: body);
  Future deleteQcInspection(int id) => destroy('/quality/qc-inspections/$id');

  Future qcResultActions({Map<String, dynamic>? filters}) =>
      index('/quality/qc-result-actions', filters: filters);
  Future qcResultAction(int id) => show('/quality/qc-result-actions/$id');
  Future createQcResultAction(Map<String, dynamic> body) =>
      store('/quality/qc-result-actions', body);
  Future updateQcResultAction(int id, Map<String, dynamic> body) =>
      update('/quality/qc-result-actions/$id', body);
  Future completeQcResultAction(int id, Map<String, dynamic> body) =>
      action('/quality/qc-result-actions/$id/complete', body: body);
  Future cancelQcResultAction(int id, Map<String, dynamic> body) =>
      action('/quality/qc-result-actions/$id/cancel', body: body);
  Future deleteQcResultAction(int id) =>
      destroy('/quality/qc-result-actions/$id');

  Future qcNonConformanceLogs({Map<String, dynamic>? filters}) =>
      index('/quality/qc-non-conformance-logs', filters: filters);
  Future qcNonConformanceLog(int id) =>
      show('/quality/qc-non-conformance-logs/$id');
  Future createQcNonConformanceLog(Map<String, dynamic> body) =>
      store('/quality/qc-non-conformance-logs', body);
  Future updateQcNonConformanceLog(int id, Map<String, dynamic> body) =>
      update('/quality/qc-non-conformance-logs/$id', body);
  Future closeQcNonConformanceLog(int id, Map<String, dynamic> body) =>
      action('/quality/qc-non-conformance-logs/$id/close', body: body);
  Future waiveQcNonConformanceLog(int id, Map<String, dynamic> body) =>
      action('/quality/qc-non-conformance-logs/$id/waive', body: body);
  Future deleteQcNonConformanceLog(int id) =>
      destroy('/quality/qc-non-conformance-logs/$id');
}
