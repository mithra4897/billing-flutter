import '../../core/api/api_endpoints.dart';
import '../../core/models/api_response.dart';
import '../../model/printing/print_template_model.dart';
import '../base/erp_module_service.dart';

class PrintTemplateService extends ErpModuleService {
  PrintTemplateService({super.apiClient});

  Future<ApiResponse<DocumentPrintTemplate>> getTemplate(String documentType) {
    return object<DocumentPrintTemplate>(
      '${ApiEndpoints.printTemplates}/$documentType',
      fromJson: DocumentPrintTemplate.fromJson,
    );
  }

  Future<ApiResponse<DocumentPrintTemplate>> saveTemplate(
    String documentType,
    DocumentPrintTemplate template,
  ) {
    return client.post<DocumentPrintTemplate>(
      ApiEndpoints.printTemplates,
      body: {
        'document_type': documentType,
        'template_data': template.toJson(),
      },
      fromData: (json) => DocumentPrintTemplate.fromJson(json as Map<String, dynamic>),
    );
  }
}
