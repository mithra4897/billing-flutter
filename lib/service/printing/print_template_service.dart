import '../../screen.dart';

class PrintTemplateService extends ErpModuleService {
  PrintTemplateService({super.apiClient});

  Future<ApiResponse<DocumentPrintTemplate>> getTemplate(
    String documentType,
  ) {
    return client.get<DocumentPrintTemplate>(
      '${ApiEndpoints.printTemplates}/$documentType',
      fromData: (json) =>
          DocumentPrintTemplate.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<DocumentPrintTemplate>> saveTemplate(
    String documentType,
    DocumentPrintTemplate template,
  ) {
    return client.post<DocumentPrintTemplate>(
      ApiEndpoints.printTemplates,
      body: {'document_type': documentType, 'template_data': template.toJson()},
      fromData: (json) =>
          DocumentPrintTemplate.fromJson(json as Map<String, dynamic>),
    );
  }
}
