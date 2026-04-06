import '../../core/models/api_response.dart';
import '../../core/models/paginated_response.dart';
import '../../model/communication/email_message_model.dart';
import '../../model/communication/email_module_setting_model.dart';
import '../../model/communication/email_rule_model.dart';
import '../../model/communication/email_setting_model.dart';
import '../../model/communication/email_template_model.dart';
import '../base/erp_module_service.dart';

class CommunicationService extends ErpModuleService {
  CommunicationService({super.apiClient});

  Future<ApiResponse<List<EmailSettingModel>>> emailSettings({
    Map<String, dynamic>? filters,
  }) => collection<EmailSettingModel>(
    '/communication/email-settings',
    filters: filters,
    fromJson: EmailSettingModel.fromJson,
  );
  Future<ApiResponse<EmailSettingModel>> createEmailSetting(
    EmailSettingModel body,
  ) => createModel<EmailSettingModel>(
    '/communication/email-settings',
    body,
    fromJson: EmailSettingModel.fromJson,
  );
  Future<ApiResponse<EmailSettingModel>> updateEmailSetting(
    int id,
    EmailSettingModel body,
  ) => updateModel<EmailSettingModel>(
    '/communication/email-settings/$id',
    body,
    fromJson: EmailSettingModel.fromJson,
  );

  Future<ApiResponse<List<EmailModuleSettingModel>>> emailModuleSettings({
    Map<String, dynamic>? filters,
  }) => collection<EmailModuleSettingModel>(
    '/communication/email-module-settings',
    filters: filters,
    fromJson: EmailModuleSettingModel.fromJson,
  );
  Future<ApiResponse<EmailModuleSettingModel>> createEmailModuleSetting(
    EmailModuleSettingModel body,
  ) => createModel<EmailModuleSettingModel>(
    '/communication/email-module-settings',
    body,
    fromJson: EmailModuleSettingModel.fromJson,
  );
  Future<ApiResponse<EmailModuleSettingModel>> updateEmailModuleSetting(
    int id,
    EmailModuleSettingModel body,
  ) => updateModel<EmailModuleSettingModel>(
    '/communication/email-module-settings/$id',
    body,
    fromJson: EmailModuleSettingModel.fromJson,
  );

  Future<PaginatedResponse<EmailTemplateModel>> emailTemplates({
    Map<String, dynamic>? filters,
  }) => paginated<EmailTemplateModel>(
    '/communication/email-templates',
    filters: filters,
    fromJson: EmailTemplateModel.fromJson,
  );
  Future<ApiResponse<EmailTemplateModel>> emailTemplate(int id) =>
      object<EmailTemplateModel>(
        '/communication/email-templates/$id',
        fromJson: EmailTemplateModel.fromJson,
      );
  Future<ApiResponse<EmailTemplateModel>> createEmailTemplate(
    EmailTemplateModel body,
  ) => createModel<EmailTemplateModel>(
    '/communication/email-templates',
    body,
    fromJson: EmailTemplateModel.fromJson,
  );
  Future<ApiResponse<EmailTemplateModel>> updateEmailTemplate(
    int id,
    EmailTemplateModel body,
  ) => updateModel<EmailTemplateModel>(
    '/communication/email-templates/$id',
    body,
    fromJson: EmailTemplateModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteEmailTemplate(int id) =>
      destroy('/communication/email-templates/$id');

  Future<PaginatedResponse<EmailRuleModel>> emailRules({
    Map<String, dynamic>? filters,
  }) => paginated<EmailRuleModel>(
    '/communication/email-rules',
    filters: filters,
    fromJson: EmailRuleModel.fromJson,
  );
  Future<ApiResponse<EmailRuleModel>> emailRule(int id) =>
      object<EmailRuleModel>(
        '/communication/email-rules/$id',
        fromJson: EmailRuleModel.fromJson,
      );
  Future<ApiResponse<EmailRuleModel>> createEmailRule(EmailRuleModel body) =>
      createModel<EmailRuleModel>(
        '/communication/email-rules',
        body,
        fromJson: EmailRuleModel.fromJson,
      );
  Future<ApiResponse<EmailRuleModel>> updateEmailRule(
    int id,
    EmailRuleModel body,
  ) => updateModel<EmailRuleModel>(
    '/communication/email-rules/$id',
    body,
    fromJson: EmailRuleModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteEmailRule(int id) =>
      destroy('/communication/email-rules/$id');

  Future<PaginatedResponse<EmailMessageModel>> emailMessages({
    Map<String, dynamic>? filters,
  }) => paginated<EmailMessageModel>(
    '/communication/email-messages',
    filters: filters,
    fromJson: EmailMessageModel.fromJson,
  );
  Future<ApiResponse<EmailMessageModel>> emailMessage(int id) =>
      object<EmailMessageModel>(
        '/communication/email-messages/$id',
        fromJson: EmailMessageModel.fromJson,
      );
  Future<ApiResponse<EmailMessageModel>> sendEmail(EmailMessageModel body) =>
      actionModel<EmailMessageModel>(
        '/communication/emails/send',
        body: body,
        fromJson: EmailMessageModel.fromJson,
      );
}
