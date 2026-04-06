import '../../../screen.dart';

class EmailSettingsPage extends StatefulWidget {
  const EmailSettingsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<EmailSettingsPage> createState() => _EmailSettingsPageState();
}

class _EmailSettingsPageState extends State<EmailSettingsPage> {
  static const List<AppDropdownItem<String>> _driverItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'disabled', label: 'Disabled'),
        AppDropdownItem(value: 'log', label: 'Log'),
        AppDropdownItem(value: 'mail', label: 'Mail / SMTP'),
      ];

  static const List<AppDropdownItem<String>> _encryptionItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'none', label: 'None'),
        AppDropdownItem(value: 'tls', label: 'TLS'),
        AppDropdownItem(value: 'ssl', label: 'SSL'),
      ];

  final CommunicationService _communicationService = CommunicationService();
  final MasterService _masterService = MasterService();
  final ScrollController _pageScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _settingNameController = TextEditingController();
  final TextEditingController _fromNameController = TextEditingController();
  final TextEditingController _fromEmailController = TextEditingController();
  final TextEditingController _replyToEmailController = TextEditingController();
  final TextEditingController _smtpHostController = TextEditingController();
  final TextEditingController _smtpPortController = TextEditingController();
  final TextEditingController _smtpUsernameController = TextEditingController();
  final TextEditingController _smtpPasswordController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  List<CompanyModel> _companies = const <CompanyModel>[];
  List<EmailSettingModel> _settings = const <EmailSettingModel>[];
  List<EmailSettingModel> _filteredSettings = const <EmailSettingModel>[];
  EmailSettingModel? _selectedSetting;
  int? _companyId;
  String _mailDriver = 'disabled';
  String _smtpEncryption = 'none';
  bool _autoEmailEnabled = true;
  bool _isDefault = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applySearch);
    _loadPage();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _searchController.dispose();
    _settingNameController.dispose();
    _fromNameController.dispose();
    _fromEmailController.dispose();
    _replyToEmailController.dispose();
    _smtpHostController.dispose();
    _smtpPortController.dispose();
    _smtpUsernameController.dispose();
    _smtpPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadPage({int? selectId}) async {
    setState(() {
      _initialLoading = _settings.isEmpty;
      _pageError = null;
    });

    try {
      final companiesResponse = await _masterService.companies(
        filters: const {'per_page': 100, 'sort_by': 'legal_name'},
      );
      final settingsResponse = await _communicationService.emailSettings();

      if (!mounted) {
        return;
      }

      final companies = companiesResponse.data ?? const <CompanyModel>[];
      final settings = settingsResponse.data ?? const <EmailSettingModel>[];

      setState(() {
        _companies = companies;
        _settings = settings;
        _filteredSettings = filterMasterList(settings, _searchController.text, (
          setting,
        ) {
          final data = setting.data;
          return [
            stringValue(data, 'setting_name'),
            stringValue(data, 'mail_driver'),
            stringValue(data, 'from_email'),
          ];
        });
        _initialLoading = false;
      });

      final selected = selectId != null
          ? settings.cast<EmailSettingModel?>().firstWhere(
              (item) => intValue(item?.data ?? const {}, 'id') == selectId,
              orElse: () => null,
            )
          : (_selectedSetting == null
                ? (settings.isNotEmpty ? settings.first : null)
                : settings.cast<EmailSettingModel?>().firstWhere(
                    (item) =>
                        intValue(item?.data ?? const {}, 'id') ==
                        intValue(_selectedSetting?.data ?? const {}, 'id'),
                    orElse: () => settings.isNotEmpty ? settings.first : null,
                  ));

      if (selected != null) {
        _selectSetting(selected);
      } else {
        _resetForm();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _initialLoading = false;
        _pageError = error.toString();
      });
    }
  }

  void _applySearch() {
    setState(() {
      _filteredSettings = filterMasterList(_settings, _searchController.text, (
        setting,
      ) {
        final data = setting.data;
        return [
          stringValue(data, 'setting_name'),
          stringValue(data, 'mail_driver'),
          stringValue(data, 'from_email'),
        ];
      });
    });
  }

  void _selectSetting(EmailSettingModel setting) {
    final data = setting.data;
    _selectedSetting = setting;
    _companyId = intValue(data, 'company_id');
    _settingNameController.text = stringValue(data, 'setting_name');
    _fromNameController.text = stringValue(data, 'from_name');
    _fromEmailController.text = stringValue(data, 'from_email');
    _replyToEmailController.text = stringValue(data, 'reply_to_email');
    _smtpHostController.text = stringValue(data, 'smtp_host');
    _smtpPortController.text = stringValue(data, 'smtp_port');
    _smtpUsernameController.text = stringValue(data, 'smtp_username');
    _smtpPasswordController.text = stringValue(data, 'smtp_password');
    _mailDriver = stringValue(data, 'mail_driver', 'disabled');
    _smtpEncryption = stringValue(data, 'smtp_encryption', 'none');
    _autoEmailEnabled = boolValue(data, 'auto_email_enabled', fallback: true);
    _isDefault = boolValue(data, 'is_default');
    _isActive = boolValue(data, 'is_active', fallback: true);
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedSetting = null;
    _companyId = null;
    _settingNameController.clear();
    _fromNameController.clear();
    _fromEmailController.clear();
    _replyToEmailController.clear();
    _smtpHostController.clear();
    _smtpPortController.clear();
    _smtpUsernameController.clear();
    _smtpPasswordController.clear();
    _mailDriver = 'disabled';
    _smtpEncryption = 'none';
    _autoEmailEnabled = true;
    _isDefault = false;
    _isActive = true;
    _formError = null;
    setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    final body = EmailSettingModel({
      if (intValue(_selectedSetting?.data ?? const {}, 'id') != null)
        'id': intValue(_selectedSetting!.data, 'id'),
      if (_companyId != null) 'company_id': _companyId,
      'setting_name': _settingNameController.text.trim(),
      'mail_driver': _mailDriver,
      'from_name': _fromNameController.text.trim(),
      'from_email': _fromEmailController.text.trim(),
      'reply_to_email': nullIfEmpty(_replyToEmailController.text),
      'smtp_host': nullIfEmpty(_smtpHostController.text),
      'smtp_port': int.tryParse(_smtpPortController.text.trim()),
      'smtp_encryption': _smtpEncryption,
      'smtp_username': nullIfEmpty(_smtpUsernameController.text),
      'smtp_password': nullIfEmpty(_smtpPasswordController.text),
      'auto_email_enabled': _autoEmailEnabled,
      'is_default': _isDefault,
      'is_active': _isActive,
    });

    try {
      final id = intValue(_selectedSetting?.data ?? const {}, 'id');
      final response = id == null
          ? await _communicationService.createEmailSetting(body)
          : await _communicationService.updateEmailSetting(id, body);

      final saved = response.data;
      if (!mounted) {
        return;
      }
      if (saved == null) {
        setState(() {
          _formError = response.message;
        });
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadPage(selectId: intValue(saved.data, 'id'));
    } catch (error) {
      setState(() {
        _formError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    final actions = <Widget>[
      AdaptiveShellActionButton(
        onPressed: _resetForm,
        icon: Icons.add_outlined,
        label: 'New Email Setting',
      ),
    ];

    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }

    return AppStandaloneShell(
      title: 'Email Settings',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading email settings...');
    }

    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load email settings',
        message: _pageError!,
        onRetry: _loadPage,
      );
    }

    final fieldWidth = settingsResponsiveFieldWidth(context);
    final companyItems = _companies
        .map(
          (company) => AppDropdownItem<int>(
            value: company.id ?? 0,
            label: company.legalName ?? company.code ?? 'Company',
          ),
        )
        .toList(growable: false);

    return SettingsWorkspace(
      scrollController: _pageScrollController,
      list: SettingsListCard<EmailSettingModel>(
        title: 'Email Settings',
        subtitle:
            'Configure actual outgoing mail accounts and default sender identities.',
        searchController: _searchController,
        searchHint: 'Search email settings',
        items: _filteredSettings,
        selectedItem: _selectedSetting,
        emptyMessage: 'No email settings found.',
        itemBuilder: (setting, selected) {
          final data = setting.data;
          return SettingsListTile(
            title: stringValue(data, 'setting_name', 'Email Setting'),
            subtitle: [
              stringValue(data, 'mail_driver').toUpperCase(),
              stringValue(data, 'from_email'),
            ].where((value) => value.isNotEmpty).join(' • '),
            selected: selected,
            onTap: () => _selectSetting(setting),
            trailing: SettingsStatusPill(
              label: boolValue(data, 'is_active', fallback: true)
                  ? 'Active'
                  : 'Inactive',
              active: boolValue(data, 'is_active', fallback: true),
            ),
          );
        },
      ),
      editor: SettingsEditorCard(
        title: _selectedSetting == null
            ? 'Create Email Setting'
            : 'Edit Email Setting',
        subtitle:
            'Keep sender identity, SMTP settings, and auto-mail behavior in one place.',
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_formError != null) ...[
                AppErrorStateView.inline(message: _formError!),
                const SizedBox(height: 16),
              ],
              SettingsFormWrap(
                children: [
                  AppDropdownField<int>.fromMapped(
                    width: fieldWidth,
                    labelText: 'Company',
                    mappedItems: companyItems,
                    initialValue: _companyId,
                    onChanged: (value) => setState(() => _companyId = value),
                  ),
                  AppFormTextField(
                    width: fieldWidth,
                    labelText: 'Setting Name',
                    controller: _settingNameController,
                    validator: Validators.required('Setting name'),
                  ),
                  AppDropdownField<String>.fromMapped(
                    width: fieldWidth,
                    labelText: 'Mail Driver',
                    mappedItems: _driverItems,
                    initialValue: _mailDriver,
                    onChanged: (value) =>
                        setState(() => _mailDriver = value ?? 'disabled'),
                  ),
                  AppFormTextField(
                    width: fieldWidth,
                    labelText: 'From Name',
                    controller: _fromNameController,
                    validator: Validators.required('From name'),
                  ),
                  AppFormTextField(
                    width: fieldWidth,
                    labelText: 'From Email',
                    controller: _fromEmailController,
                    validator: Validators.required('From email'),
                  ),
                  AppFormTextField(
                    width: fieldWidth,
                    labelText: 'Reply-To Email',
                    controller: _replyToEmailController,
                  ),
                  AppFormTextField(
                    width: fieldWidth,
                    labelText: 'SMTP Host',
                    controller: _smtpHostController,
                  ),
                  AppFormTextField(
                    width: fieldWidth,
                    labelText: 'SMTP Port',
                    controller: _smtpPortController,
                    keyboardType: TextInputType.number,
                  ),
                  AppDropdownField<String>.fromMapped(
                    width: fieldWidth,
                    labelText: 'Encryption',
                    mappedItems: _encryptionItems,
                    initialValue: _smtpEncryption,
                    onChanged: (value) =>
                        setState(() => _smtpEncryption = value ?? 'none'),
                  ),
                  AppFormTextField(
                    width: fieldWidth,
                    labelText: 'SMTP Username',
                    controller: _smtpUsernameController,
                  ),
                  AppFormTextField(
                    width: fieldWidth,
                    labelText: 'SMTP Password',
                    controller: _smtpPasswordController,
                    obscureText: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: fieldWidth,
                    child: AppSwitchTile(
                      label: 'Auto Email Enabled',
                      value: _autoEmailEnabled,
                      onChanged: (value) =>
                          setState(() => _autoEmailEnabled = value),
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: AppSwitchTile(
                      label: 'Default Setting',
                      value: _isDefault,
                      onChanged: (value) => setState(() => _isDefault = value),
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: AppSwitchTile(
                      label: 'Active',
                      value: _isActive,
                      onChanged: (value) => setState(() => _isActive = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AppActionButton(
                icon: Icons.save_outlined,
                label: _selectedSetting == null
                    ? 'Save Email Setting'
                    : 'Update Email Setting',
                onPressed: _save,
                busy: _saving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
