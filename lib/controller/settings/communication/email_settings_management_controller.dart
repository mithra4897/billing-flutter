import '../../../screen.dart';

class EmailSettingsManagementController extends GetxController {
  EmailSettingsManagementController();

  static const List<AppDropdownItem<String>> driverItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'disabled', label: 'Disabled'),
        AppDropdownItem(value: 'log', label: 'Log'),
        AppDropdownItem(value: 'mail', label: 'Mail / SMTP'),
      ];

  static const List<AppDropdownItem<String>> encryptionItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'none', label: 'None'),
        AppDropdownItem(value: 'tls', label: 'TLS'),
        AppDropdownItem(value: 'ssl', label: 'SSL'),
      ];

  final CommunicationService _communicationService = CommunicationService();
  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController settingNameController = TextEditingController();
  final TextEditingController fromNameController = TextEditingController();
  final TextEditingController fromEmailController = TextEditingController();
  final TextEditingController replyToEmailController = TextEditingController();
  final TextEditingController smtpHostController = TextEditingController();
  final TextEditingController smtpPortController = TextEditingController();
  final TextEditingController smtpUsernameController = TextEditingController();
  final TextEditingController smtpPasswordController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  List<EmailSettingModel> settings = const <EmailSettingModel>[];
  List<EmailSettingModel> filteredSettings = const <EmailSettingModel>[];
  EmailSettingModel? selectedSetting;
  int? contextCompanyId;
  int? companyId;
  String mailDriver = 'disabled';
  String smtpEncryption = 'none';
  bool autoEmailEnabled = true;
  bool isDefault = false;
  bool isActive = true;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_applySearch);
    loadPage();
  }

  @override
  void onClose() {
    pageScrollController.dispose();
    workspaceController.dispose();
    searchController
      ..removeListener(_applySearch)
      ..dispose();
    settingNameController.dispose();
    fromNameController.dispose();
    fromEmailController.dispose();
    replyToEmailController.dispose();
    smtpHostController.dispose();
    smtpPortController.dispose();
    smtpUsernameController.dispose();
    smtpPasswordController.dispose();
    super.onClose();
  }

  Future<void> loadPage({int? selectId}) async {
    initialLoading = settings.isEmpty;
    pageError = null;
    update();

    try {
      await MasterDataCache.to.ensureLoaded();
      final cache = MasterDataCache.to;
      final settingsResponse = await _communicationService.emailSettings();

      final nextSettings = settingsResponse.data ?? const <EmailSettingModel>[];
      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: cache.activeCompanies,
            branches: const <BranchModel>[],
            locations: const <BusinessLocationModel>[],
            financialYears: const <FinancialYearModel>[],
          );

      contextCompanyId = contextSelection.companyId;
      settings = nextSettings;
      filteredSettings = _filterSettings(nextSettings, searchController.text);
      initialLoading = false;

      final selected = selectId != null
          ? nextSettings.cast<EmailSettingModel?>().firstWhere(
              (item) => intValue(item?.toJson() ?? const {}, 'id') == selectId,
              orElse: () => null,
            )
          : (selectedSetting == null
                ? (nextSettings.isNotEmpty ? nextSettings.first : null)
                : nextSettings.cast<EmailSettingModel?>().firstWhere(
                    (item) =>
                        intValue(item?.toJson() ?? const {}, 'id') ==
                        intValue(selectedSetting?.toJson() ?? const {}, 'id'),
                    orElse: () =>
                        nextSettings.isNotEmpty ? nextSettings.first : null,
                  ));

      if (selected != null) {
        selectSetting(selected, notify: false);
      } else {
        resetForm(notify: false);
      }
    } catch (errorValue) {
      initialLoading = false;
      pageError = errorValue.toString();
    }

    update();
  }

  List<EmailSettingModel> _filterSettings(
    List<EmailSettingModel> source,
    String query,
  ) {
    return filterMasterList(source, query, (setting) {
      final data = setting.toJson();
      return [
        stringValue(data, 'setting_name'),
        stringValue(data, 'mail_driver'),
        stringValue(data, 'from_email'),
      ];
    });
  }

  void _applySearch() {
    filteredSettings = _filterSettings(settings, searchController.text);
    update();
  }

  void selectSetting(EmailSettingModel setting, {bool notify = true}) {
    final data = setting.toJson();
    selectedSetting = setting;
    companyId = intValue(data, 'company_id');
    settingNameController.text = stringValue(data, 'setting_name');
    fromNameController.text = stringValue(data, 'from_name');
    fromEmailController.text = stringValue(data, 'from_email');
    replyToEmailController.text = stringValue(data, 'reply_to_email');
    smtpHostController.text = stringValue(data, 'smtp_host');
    smtpPortController.text = stringValue(data, 'smtp_port');
    smtpUsernameController.text = stringValue(data, 'smtp_username');
    smtpPasswordController.text = stringValue(data, 'smtp_password');
    mailDriver = stringValue(data, 'mail_driver', 'disabled');
    smtpEncryption = stringValue(data, 'smtp_encryption', 'none');
    autoEmailEnabled = boolValue(data, 'auto_email_enabled', fallback: true);
    isDefault = boolValue(data, 'is_default');
    isActive = boolValue(data, 'is_active', fallback: true);
    formError = null;
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selectedSetting = null;
    companyId = contextCompanyId;
    settingNameController.clear();
    fromNameController.clear();
    fromEmailController.clear();
    replyToEmailController.clear();
    smtpHostController.clear();
    smtpPortController.clear();
    smtpUsernameController.clear();
    smtpPasswordController.clear();
    mailDriver = 'disabled';
    smtpEncryption = 'none';
    autoEmailEnabled = true;
    isDefault = false;
    isActive = true;
    formError = null;
    if (notify) {
      update();
    }
  }

  void setMailDriver(String? value) {
    mailDriver = value ?? 'disabled';
    update();
  }

  void setSmtpEncryption(String? value) {
    smtpEncryption = value ?? 'none';
    update();
  }

  void setAutoEmailEnabled(bool value) {
    autoEmailEnabled = value;
    update();
  }

  void setIsDefault(bool value) {
    isDefault = value;
    update();
  }

  void setIsActive(bool value) {
    isActive = value;
    update();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    saving = true;
    formError = null;
    update();

    final body = EmailSettingModel.fromJson(
      normalizeDatePayload({
        if (intValue(selectedSetting?.toJson() ?? const {}, 'id') != null)
          'id': intValue(selectedSetting!.toJson(), 'id'),
        if (companyId != null) 'company_id': companyId,
        'setting_name': settingNameController.text.trim(),
        'mail_driver': mailDriver,
        'from_name': fromNameController.text.trim(),
        'from_email': fromEmailController.text.trim(),
        'reply_to_email': nullIfEmpty(replyToEmailController.text),
        'smtp_host': nullIfEmpty(smtpHostController.text),
        'smtp_port': int.tryParse(smtpPortController.text.trim()),
        'smtp_encryption': smtpEncryption,
        'smtp_username': nullIfEmpty(smtpUsernameController.text),
        'smtp_password': nullIfEmpty(smtpPasswordController.text),
        'auto_email_enabled': autoEmailEnabled,
        'is_default': isDefault,
        'is_active': isActive,
      }),
    );

    try {
      final id = intValue(selectedSetting?.toJson() ?? const {}, 'id');
      final response = id == null
          ? await _communicationService.createEmailSetting(body)
          : await _communicationService.updateEmailSetting(id, body);

      final saved = response.data;
      if (saved == null) {
        formError = response.message;
        update();
        return;
      }

      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadPage(selectId: intValue(saved.toJson(), 'id'));
    } catch (errorValue) {
      formError = errorValue.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  void startNewEmailSetting({required bool isDesktop}) {
    resetForm();

    if (!isDesktop) {
      workspaceController.openEditor();
    }
  }
}
