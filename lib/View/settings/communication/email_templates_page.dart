import '../../../screen.dart';

class EmailTemplatesPage extends StatefulWidget {
  const EmailTemplatesPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<EmailTemplatesPage> createState() => _EmailTemplatesPageState();
}

class _EmailTemplatesPageState extends State<EmailTemplatesPage> {
  final CommunicationService _communicationService = CommunicationService();
  final MasterService _masterService = MasterService();
  final ScrollController _pageScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _moduleController = TextEditingController();
  final TextEditingController _eventCodeController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  List<CompanyModel> _companies = const <CompanyModel>[];
  List<AppDropdownItem<String>> _documentTypeItems = const [
    AppDropdownItem(value: '', label: 'All'),
  ];
  List<EmailTemplateModel> _records = const <EmailTemplateModel>[];
  List<EmailTemplateModel> _filteredRecords = const <EmailTemplateModel>[];
  EmailTemplateModel? _selectedRecord;
  int? _companyId;
  String _documentType = '';
  bool _isHtml = true;
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
    _subjectController.dispose();
    _bodyController.dispose();
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
      final recordsResponse = await _communicationService.emailTemplates(
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
      final records = recordsResponse.data ?? const <EmailTemplateModel>[];

      setState(() {
        _companies = companies;
        _documentTypeItems = [
          const AppDropdownItem(value: '', label: 'All'),
          ...documentTypes.map(
            (item) => AppDropdownItem(value: item, label: item),
          ),
        ];
        _records = records;
        _filteredRecords = filterMasterList(
          records,
          _searchController.text,
          (record) => [
            stringValue(record.data, 'template_code'),
            stringValue(record.data, 'template_name'),
            stringValue(record.data, 'module'),
            stringValue(record.data, 'event_code'),
          ],
        );
        _initialLoading = false;
      });

      final selected = selectId != null
          ? records.cast<EmailTemplateModel?>().firstWhere(
              (item) => intValue(item?.data ?? const {}, 'id') == selectId,
              orElse: () => null,
            )
          : (_selectedRecord == null
                ? (records.isNotEmpty ? records.first : null)
                : records.cast<EmailTemplateModel?>().firstWhere(
                    (item) =>
                        intValue(item?.data ?? const {}, 'id') ==
                        intValue(_selectedRecord?.data ?? const {}, 'id'),
                    orElse: () => records.isNotEmpty ? records.first : null,
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
          stringValue(record.data, 'template_code'),
          stringValue(record.data, 'template_name'),
          stringValue(record.data, 'module'),
          stringValue(record.data, 'event_code'),
        ],
      );
    });
  }

  void _selectRecord(EmailTemplateModel record) {
    final data = record.data;
    _selectedRecord = record;
    _companyId = intValue(data, 'company_id');
    _codeController.text = stringValue(data, 'template_code');
    _nameController.text = stringValue(data, 'template_name');
    _moduleController.text = stringValue(data, 'module');
    _documentType = stringValue(data, 'document_type');
    _eventCodeController.text = stringValue(data, 'event_code');
    _subjectController.text = stringValue(data, 'subject_template');
    _bodyController.text = stringValue(data, 'body_template');
    _isHtml = boolValue(data, 'is_html', fallback: true);
    _isActive = boolValue(data, 'is_active', fallback: true);
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedRecord = null;
    _companyId = null;
    _codeController.clear();
    _nameController.clear();
    _moduleController.clear();
    _documentType = '';
    _eventCodeController.clear();
    _subjectController.clear();
    _bodyController.clear();
    _isHtml = true;
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

    final body = EmailTemplateModel({
      if (intValue(_selectedRecord?.data ?? const {}, 'id') != null)
        'id': intValue(_selectedRecord!.data, 'id'),
      if (_companyId != null) 'company_id': _companyId,
      'template_code': _codeController.text.trim(),
      'template_name': _nameController.text.trim(),
      'module': _moduleController.text.trim(),
      'document_type': nullIfEmpty(_documentType),
      'event_code': nullIfEmpty(_eventCodeController.text),
      'subject_template': _subjectController.text.trim(),
      'body_template': _bodyController.text.trim(),
      'is_html': _isHtml,
      'is_active': _isActive,
    });

    try {
      final id = intValue(_selectedRecord?.data ?? const {}, 'id');
      final response = id == null
          ? await _communicationService.createEmailTemplate(body)
          : await _communicationService.updateEmailTemplate(id, body);

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
      final response = await _communicationService.deleteEmailTemplate(id);
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
        label: 'New Template',
      ),
    ];

    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }

    return AppStandaloneShell(
      title: 'Email Templates',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading email templates...');
    }

    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load email templates',
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

    return SettingsWorkspace(
      title: 'Email Templates',
      scrollController: _pageScrollController,
      list: SettingsListCard<EmailTemplateModel>(
        searchController: _searchController,
        searchHint: 'Search email templates',
        items: _filteredRecords,
        selectedItem: _selectedRecord,
        emptyMessage: 'No email templates found.',
        itemBuilder: (record, selected) => SettingsListTile(
          title: stringValue(record.data, 'template_name', 'Template'),
          subtitle: [
            stringValue(record.data, 'template_code'),
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
      editor: Form(
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
                  labelText: 'Template Code',
                  controller: _codeController,
                  validator: Validators.required('Template code'),
                ),
                AppFormTextField(
                  labelText: 'Template Name',
                  controller: _nameController,
                  validator: Validators.required('Template name'),
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
                ),
                AppFormTextField(
                  labelText: 'Subject Template',
                  controller: _subjectController,
                  validator: Validators.required('Subject template'),
                ),
                AppFormTextField(
                  labelText: 'Body Template',
                  controller: _bodyController,
                  maxLines: 10,
                  validator: Validators.required('Body template'),
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
                    label: 'HTML Template',
                    value: _isHtml,
                    onChanged: (value) => setState(() => _isHtml = value),
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
                      ? 'Save Template'
                      : 'Update Template',
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
    );
  }
}
