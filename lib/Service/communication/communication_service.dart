import '../base/erp_module_service.dart';

class CommunicationService extends ErpModuleService {
  CommunicationService({super.apiClient});

  Future emailSettings({Map<String, dynamic>? filters}) =>
      index('/communication/email-settings', filters: filters);
  Future createEmailSetting(Map<String, dynamic> body) =>
      store('/communication/email-settings', body);
  Future updateEmailSetting(int id, Map<String, dynamic> body) =>
      update('/communication/email-settings/$id', body);

  Future emailModuleSettings({Map<String, dynamic>? filters}) =>
      index('/communication/email-module-settings', filters: filters);
  Future createEmailModuleSetting(Map<String, dynamic> body) =>
      store('/communication/email-module-settings', body);
  Future updateEmailModuleSetting(int id, Map<String, dynamic> body) =>
      update('/communication/email-module-settings/$id', body);

  Future emailTemplates({Map<String, dynamic>? filters}) =>
      index('/communication/email-templates', filters: filters);
  Future emailTemplate(int id) => show('/communication/email-templates/$id');
  Future createEmailTemplate(Map<String, dynamic> body) =>
      store('/communication/email-templates', body);
  Future updateEmailTemplate(int id, Map<String, dynamic> body) =>
      update('/communication/email-templates/$id', body);
  Future deleteEmailTemplate(int id) =>
      destroy('/communication/email-templates/$id');

  Future emailRules({Map<String, dynamic>? filters}) =>
      index('/communication/email-rules', filters: filters);
  Future emailRule(int id) => show('/communication/email-rules/$id');
  Future createEmailRule(Map<String, dynamic> body) =>
      store('/communication/email-rules', body);
  Future updateEmailRule(int id, Map<String, dynamic> body) =>
      update('/communication/email-rules/$id', body);
  Future deleteEmailRule(int id) => destroy('/communication/email-rules/$id');

  Future emailMessages({Map<String, dynamic>? filters}) =>
      index('/communication/email-messages', filters: filters);
  Future emailMessage(int id) => show('/communication/email-messages/$id');
  Future sendEmail(Map<String, dynamic> body) =>
      action('/communication/emails/send', body: body);
}
