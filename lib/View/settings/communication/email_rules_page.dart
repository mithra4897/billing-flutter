import '../../../screen.dart';

class EmailRulesPage extends StatefulWidget {
  const EmailRulesPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<EmailRulesPage> createState() => _EmailRulesPageState();
}

class _EmailRulesPageState extends State<EmailRulesPage> {
  final CommunicationService _communicationService = CommunicationService();
  final MasterService _masterService = MasterService();
  final ScrollController _pageScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _moduleController = TextEditingController();
  final TextEditingController _eventCodeController = TextEditingController();
  final TextEditingController _recipientEmailsController =
      TextEditingController();
  final TextEditingController _ccEmailsController = TextEditingController();
  final TextEditingController _bccEmailsController = TextEditingController();
  final TextEditingController _subjectOverrideController =
      TextEditingController();
  final TextEditingController _bodyOverrideController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  List<CompanyModel> _companies = const <CompanyModel>[];
  List<AppDropdownItem<String>> _documentTypeItems = const [
    AppDropdownItem(value: '', label: 'All'),
  ];
  List<EmailTemplateModel> _templates = const <EmailTemplateModel>[];
  List<EmailRuleModel> _records = const <EmailRuleModel>[];
  List<EmailRuleModel> _filteredRecords = const <EmailRuleModel>[];
  EmailRuleModel? _selectedRecord;
  int? _companyId;
  int? _templateId;
  String _documentType = '';
  bool _autoEnabled = true;
  bool _manualEnabled = true;
  bool _sendToPartyEmail = true;
  bool _sendToContactEmail = false;
  bool _sendToAssignedUser = false;
  bool _sendToOwnerUser = false;
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
    _codeController.dispose();
    _nameController.dispose();
    _moduleController.dispose();
    _eventCodeController.dispose();
    _recipientEmailsController.dispose();
    _ccEmailsController.dispose();
    _bccEmailsController.dispose();
    _subjectOverrideController.dispose();
    _bodyOverrideController.dispose();
    super.dispose();
  }

  Future<void> _loadPage({int? selectId}) async {
    setState(() {
      _initialLoading = _records.isEmpty;
      _pageError = null;
    });

    try {
      final companiesResponse = await _masterService.companies(
        filters: const {'per_page': 100, 'sort_by': 'legal_name'},
      );
      final documentSeriesResponse = await _masterService.documentSeries(
        filters: const {'per_page': 500},
      );
      final templatesResponse = await _communicationService.emailTemplates(
        filters: const {'per_page': 100},
      );
      final rulesResponse = await _communicationService.emailRules(
        filters: const {'per_page': 100},
      );

      if (!mounted) {
        return;
      }

      final companies = companiesResponse.data ?? const <CompanyModel>[];
      final documentTypes =
          (documentSeriesResponse.data ?? const <DocumentSeriesModel>[])
              .map((item) => (item.documentType ?? '').trim())
              .where((item) => item.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
      final templates = templatesResponse.data ?? const <EmailTemplateModel>[];
      final rules = rulesResponse.data ?? const <EmailRuleModel>[];

      setState(() {
        _companies = companies;
        _documentTypeItems = [
          const AppDropdownItem(value: '', label: 'All'),
          ...documentTypes.map(
            (item) => AppDropdownItem(value: item, label: item),
          ),
        ];
        _templates = templates;
        _records = rules;
        _filteredRecords = filterMasterList(
          rules,
          _searchController.text,
          (record) => [
            stringValue(record.data, 'rule_code'),
            stringValue(record.data, 'rule_name'),
            stringValue(record.data, 'module'),
            stringValue(record.data, 'event_code'),
          ],
        );
        _initialLoading = false;
      });

      final selected = selectId != null
          ? rules.cast<EmailRuleModel?>().firstWhere(
              (item) => intValue(item?.data ?? const {}, 'id') == selectId,
              orElse: () => null,
            )
          : (_selectedRecord == null
                ? (rules.isNotEmpty ? rules.first : null)
                : rules.cast<EmailRuleModel?>().firstWhere(
                    (item) =>
                        intValue(item?.data ?? const {}, 'id') ==
                        intValue(_selectedRecord?.data ?? const {}, 'id'),
                    orElse: () => rules.isNotEmpty ? rules.first : null,
                  ));

      if (selected != null) {
        _selectRecord(selected);
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
      _filteredRecords = filterMasterList(
        _records,
        _searchController.text,
        (record) => [
          stringValue(record.data, 'rule_code'),
          stringValue(record.data, 'rule_name'),
          stringValue(record.data, 'module'),
          stringValue(record.data, 'event_code'),
        ],
      );
    });
  }

  void _selectRecord(EmailRuleModel record) {
    final data = record.data;
    _selectedRecord = record;
    _companyId = intValue(data, 'company_id');
    _templateId = intValue(data, 'template_id');
    _codeController.text = stringValue(data, 'rule_code');
    _nameController.text = stringValue(data, 'rule_name');
    _moduleController.text = stringValue(data, 'module');
    _documentType = stringValue(data, 'document_type');
    _eventCodeController.text = stringValue(data, 'event_code');
    _recipientEmailsController.text = stringValue(data, 'recipient_emails');
    _ccEmailsController.text = stringValue(data, 'cc_emails');
    _bccEmailsController.text = stringValue(data, 'bcc_emails');
    _subjectOverrideController.text = stringValue(data, 'subject_override');
    _bodyOverrideController.text = stringValue(data, 'body_override');
    _autoEnabled = boolValue(data, 'auto_enabled', fallback: true);
    _manualEnabled = boolValue(data, 'manual_enabled', fallback: true);
    _sendToPartyEmail = boolValue(data, 'send_to_party_email', fallback: true);
    _sendToContactEmail = boolValue(data, 'send_to_contact_email');
    _sendToAssignedUser = boolValue(data, 'send_to_assigned_user');
    _sendToOwnerUser = boolValue(data, 'send_to_owner_user');
    _isActive = boolValue(data, 'is_active', fallback: true);
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedRecord = null;
    _companyId = null;
    _templateId = null;
    _codeController.clear();
    _nameController.clear();
    _moduleController.clear();
    _documentType = '';
    _eventCodeController.clear();
    _recipientEmailsController.clear();
    _ccEmailsController.clear();
    _bccEmailsController.clear();
    _subjectOverrideController.clear();
    _bodyOverrideController.clear();
    _autoEnabled = true;
    _manualEnabled = true;
    _sendToPartyEmail = true;
    _sendToContactEmail = false;
    _sendToAssignedUser = false;
    _sendToOwnerUser = false;
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

    final body = EmailRuleModel({
      if (intValue(_selectedRecord?.data ?? const {}, 'id') != null)
        'id': intValue(_selectedRecord!.data, 'id'),
      if (_companyId != null) 'company_id': _companyId,
      'rule_code': _codeController.text.trim(),
      'rule_name': _nameController.text.trim(),
      'module': _moduleController.text.trim(),
      'document_type': nullIfEmpty(_documentType),
      'event_code': _eventCodeController.text.trim(),
      if (_templateId != null) 'template_id': _templateId,
      'auto_enabled': _autoEnabled,
      'manual_enabled': _manualEnabled,
      'send_to_party_email': _sendToPartyEmail,
      'send_to_contact_email': _sendToContactEmail,
      'send_to_assigned_user': _sendToAssignedUser,
      'send_to_owner_user': _sendToOwnerUser,
      'recipient_emails': nullIfEmpty(_recipientEmailsController.text),
      'cc_emails': nullIfEmpty(_ccEmailsController.text),
      'bcc_emails': nullIfEmpty(_bccEmailsController.text),
      'subject_override': nullIfEmpty(_subjectOverrideController.text),
      'body_override': nullIfEmpty(_bodyOverrideController.text),
      'is_active': _isActive,
    });

    try {
      final id = intValue(_selectedRecord?.data ?? const {}, 'id');
      final response = id == null
          ? await _communicationService.createEmailRule(body)
          : await _communicationService.updateEmailRule(id, body);

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

  Future<void> _delete() async {
    final id = intValue(_selectedRecord?.data ?? const {}, 'id');
    if (id == null) {
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    try {
      final response = await _communicationService.deleteEmailRule(id);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadPage();
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
        label: 'New Rule',
      ),
    ];

    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }

    return AppStandaloneShell(
      title: 'Email Rules',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading email rules...');
    }

    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load email rules',
        message: _pageError!,
        onRetry: _loadPage,
      );
    }

    final companyItems = <AppDropdownItem<int?>>[
      const AppDropdownItem<int?>(value: null, label: 'All'),
      ..._companies.map(
        (company) => AppDropdownItem<int?>(
          value: company.id,
          label: company.legalName ?? company.code ?? 'Company',
        ),
      ),
    ];
    final templateItems = _templates
        .map(
          (template) => AppDropdownItem<int>(
            value: intValue(template.data, 'id') ?? 0,
            label: stringValue(
              template.data,
              'template_name',
              stringValue(template.data, 'template_code', 'Template'),
            ),
          ),
        )
        .toList(growable: false);

    return SettingsWorkspace(
      scrollController: _pageScrollController,
      list: SettingsListCard<EmailRuleModel>(
        title: 'Email Rules',
        subtitle:
            'Define when templates should auto-send and who should receive them.',
        searchController: _searchController,
        searchHint: 'Search email rules',
        items: _filteredRecords,
        selectedItem: _selectedRecord,
        emptyMessage: 'No email rules found.',
        itemBuilder: (record, selected) => SettingsListTile(
          title: stringValue(record.data, 'rule_name', 'Rule'),
          subtitle: [
            stringValue(record.data, 'rule_code'),
            stringValue(record.data, 'module'),
            stringValue(record.data, 'event_code'),
          ].where((value) => value.isNotEmpty).join(' • '),
          selected: selected,
          onTap: () => _selectRecord(record),
          trailing: SettingsStatusPill(
            label: boolValue(record.data, 'is_active', fallback: true)
                ? 'Active'
                : 'Inactive',
            active: boolValue(record.data, 'is_active', fallback: true),
          ),
        ),
      ),
      editor: SettingsEditorCard(
        title: _selectedRecord == null
            ? 'Create Email Rule'
            : 'Edit Email Rule',
        subtitle:
            'Use rules to connect document events, recipients, and reusable templates.',
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
                  AppDropdownField<int?>.fromMapped(
                    labelText: 'Company',
                    mappedItems: companyItems,
                    initialValue: _companyId,
                    onChanged: (value) => setState(() => _companyId = value),
                  ),
                  AppFormTextField(
                    labelText: 'Rule Code',
                    controller: _codeController,
                    validator: Validators.required('Rule code'),
                  ),
                  AppFormTextField(
                    labelText: 'Rule Name',
                    controller: _nameController,
                    validator: Validators.required('Rule name'),
                  ),
                  AppFormTextField(
                    labelText: 'Module',
                    controller: _moduleController,
                    validator: Validators.required('Module'),
                  ),
                  AppDropdownField<String>.fromMapped(
                    labelText: 'Document Type',
                    mappedItems: _documentTypeItems,
                    initialValue: _documentType,
                    onChanged: (value) =>
                        setState(() => _documentType = value ?? ''),
                  ),
                  AppFormTextField(
                    labelText: 'Event Code',
                    controller: _eventCodeController,
                    validator: Validators.required('Event code'),
                  ),
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Template',
                    mappedItems: templateItems,
                    initialValue: _templateId,
                    onChanged: (value) => setState(() => _templateId = value),
                  ),
                  AppFormTextField(
                    labelText: 'Recipient Emails',
                    controller: _recipientEmailsController,
                  ),
                  AppFormTextField(
                    labelText: 'CC Emails',
                    controller: _ccEmailsController,
                  ),
                  AppFormTextField(
                    labelText: 'BCC Emails',
                    controller: _bccEmailsController,
                  ),
                  AppFormTextField(
                    labelText: 'Subject Override',
                    controller: _subjectOverrideController,
                  ),
                  AppFormTextField(
                    labelText: 'Body Override',
                    controller: _bodyOverrideController,
                    maxLines: 6,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  SizedBox(
                    child: AppSwitchTile(
                      label: 'Auto Enabled',
                      value: _autoEnabled,
                      onChanged: (value) =>
                          setState(() => _autoEnabled = value),
                    ),
                  ),
                  SizedBox(
                    child: AppSwitchTile(
                      label: 'Manual Enabled',
                      value: _manualEnabled,
                      onChanged: (value) =>
                          setState(() => _manualEnabled = value),
                    ),
                  ),
                  SizedBox(
                    child: AppSwitchTile(
                      label: 'Send To Party Email',
                      value: _sendToPartyEmail,
                      onChanged: (value) =>
                          setState(() => _sendToPartyEmail = value),
                    ),
                  ),
                  SizedBox(
                    child: AppSwitchTile(
                      label: 'Send To Contact Email',
                      value: _sendToContactEmail,
                      onChanged: (value) =>
                          setState(() => _sendToContactEmail = value),
                    ),
                  ),
                  SizedBox(
                    child: AppSwitchTile(
                      label: 'Send To Assigned User',
                      value: _sendToAssignedUser,
                      onChanged: (value) =>
                          setState(() => _sendToAssignedUser = value),
                    ),
                  ),
                  SizedBox(
                    child: AppSwitchTile(
                      label: 'Send To Owner User',
                      value: _sendToOwnerUser,
                      onChanged: (value) =>
                          setState(() => _sendToOwnerUser = value),
                    ),
                  ),
                  SizedBox(
                    child: AppSwitchTile(
                      label: 'Active',
                      value: _isActive,
                      onChanged: (value) => setState(() => _isActive = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  AppActionButton(
                    icon: Icons.save_outlined,
                    label: _selectedRecord == null
                        ? 'Save Rule'
                        : 'Update Rule',
                    onPressed: _save,
                    busy: _saving,
                  ),
                  if (intValue(_selectedRecord?.data ?? const {}, 'id') != null)
                    AppActionButton(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      onPressed: _saving ? null : _delete,
                      filled: false,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
