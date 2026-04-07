import '../../../screen.dart';

class EmailModuleSettingsPage extends StatefulWidget {
  const EmailModuleSettingsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<EmailModuleSettingsPage> createState() =>
      _EmailModuleSettingsPageState();
}

class _EmailModuleSettingsPageState extends State<EmailModuleSettingsPage> {
  final CommunicationService _communicationService = CommunicationService();
  final MasterService _masterService = MasterService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _moduleController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  List<CompanyModel> _companies = const <CompanyModel>[];
  List<AppDropdownItem<String>> _documentTypeItems = const [
    AppDropdownItem(value: '', label: 'All'),
  ];
  List<EmailModuleSettingModel> _records = const <EmailModuleSettingModel>[];
  List<EmailModuleSettingModel> _filteredRecords =
      const <EmailModuleSettingModel>[];
  EmailModuleSettingModel? _selectedRecord;
  int? _companyId;
  String _documentType = '';
  bool _autoEmailEnabled = true;
  bool _manualEmailEnabled = true;
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
    _workspaceController.dispose();
    _searchController.dispose();
    _moduleController.dispose();
    _remarksController.dispose();
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
      final recordsResponse = await _communicationService.emailModuleSettings();

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
      final records = recordsResponse.data ?? const <EmailModuleSettingModel>[];

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
            stringValue(record.data, 'module'),
            stringValue(record.data, 'document_type'),
            stringValue(record.data, 'remarks'),
          ],
        );
        _initialLoading = false;
      });

      final selected = selectId != null
          ? records.cast<EmailModuleSettingModel?>().firstWhere(
              (item) => intValue(item?.data ?? const {}, 'id') == selectId,
              orElse: () => null,
            )
          : (_selectedRecord == null
                ? (records.isNotEmpty ? records.first : null)
                : records.cast<EmailModuleSettingModel?>().firstWhere(
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
          stringValue(record.data, 'module'),
          stringValue(record.data, 'document_type'),
          stringValue(record.data, 'remarks'),
        ],
      );
    });
  }

  void _selectRecord(EmailModuleSettingModel record) {
    final data = record.data;
    _selectedRecord = record;
    _companyId = intValue(data, 'company_id');
    _moduleController.text = stringValue(data, 'module');
    _documentType = stringValue(data, 'document_type');
    _remarksController.text = stringValue(data, 'remarks');
    _autoEmailEnabled = boolValue(data, 'auto_email_enabled', fallback: true);
    _manualEmailEnabled = boolValue(
      data,
      'manual_email_enabled',
      fallback: true,
    );
    _isActive = boolValue(data, 'is_active', fallback: true);
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedRecord = null;
    _companyId = null;
    _moduleController.clear();
    _documentType = '';
    _remarksController.clear();
    _autoEmailEnabled = true;
    _manualEmailEnabled = true;
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

    final body = EmailModuleSettingModel({
      if (intValue(_selectedRecord?.data ?? const {}, 'id') != null)
        'id': intValue(_selectedRecord!.data, 'id'),
      if (_companyId != null) 'company_id': _companyId,
      'module': _moduleController.text.trim(),
      'document_type': nullIfEmpty(_documentType),
      'auto_email_enabled': _autoEmailEnabled,
      'manual_email_enabled': _manualEmailEnabled,
      'is_active': _isActive,
      'remarks': nullIfEmpty(_remarksController.text),
    });

    try {
      final id = intValue(_selectedRecord?.data ?? const {}, 'id');
      final response = id == null
          ? await _communicationService.createEmailModuleSetting(body)
          : await _communicationService.updateEmailModuleSetting(id, body);

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

  void _startNewModuleSetting() {
    _resetForm();

    if (!Responsive.isDesktop(context)) {
      _workspaceController.openEditor();
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    final actions = <Widget>[
      AdaptiveShellActionButton(
        onPressed: _startNewModuleSetting,
        icon: Icons.add_outlined,
        label: 'New Module Setting',
      ),
    ];

    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }

    return AppStandaloneShell(
      title: 'Module Settings',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading email module settings...');
    }

    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load module settings',
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
      controller: _workspaceController,
      title: 'Module Settings',
      editorTitle: _selectedRecord?.toString(),
      scrollController: _pageScrollController,
      list: SettingsListCard<EmailModuleSettingModel>(
        searchController: _searchController,
        searchHint: 'Search module settings',
        items: _filteredRecords,
        selectedItem: _selectedRecord,
        emptyMessage: 'No module settings found.',
        itemBuilder: (record, selected) => SettingsListTile(
          title: stringValue(record.data, 'module', 'Module'),
          subtitle: stringValue(record.data, 'document_type', 'All documents'),
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
                  labelText: 'Remarks',
                  controller: _remarksController,
                  maxLines: 3,
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
                    label: 'Auto Email Enabled',
                    value: _autoEmailEnabled,
                    onChanged: (value) =>
                        setState(() => _autoEmailEnabled = value),
                  ),
                ),
                SizedBox(
                  child: AppSwitchTile(
                    label: 'Manual Email Enabled',
                    value: _manualEmailEnabled,
                    onChanged: (value) =>
                        setState(() => _manualEmailEnabled = value),
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
            AppActionButton(
              icon: Icons.save_outlined,
              label: _selectedRecord == null
                  ? 'Save Module Setting'
                  : 'Update Module Setting',
              onPressed: _save,
              busy: _saving,
            ),
          ],
        ),
      ),
    );
  }
}
