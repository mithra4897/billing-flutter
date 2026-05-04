import '../../screen.dart';
import '../hr/hr_workflow_dialogs.dart';

Map<String, dynamic>? _costCenterJsonMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}

String _costCenterParentLabel(Map<String, dynamic> data) {
  final parent = _costCenterJsonMap(data['parent']);
  if (parent == null) {
    return '';
  }
  final name = stringValue(parent, 'cost_center_name');
  if (name.isNotEmpty) {
    return name;
  }
  return stringValue(parent, 'cost_center_code');
}

class AssetCostCenterPage extends StatefulWidget {
  const AssetCostCenterPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<AssetCostCenterPage> createState() => _AssetCostCenterPageState();
}

class _AssetCostCenterPageState extends State<AssetCostCenterPage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final AssetsService _assets = AssetsService();
  final MasterService _master = MasterService();

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();

  bool _loading = true;
  bool _detailLoading = false;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  String? _actionMessage;
  int? _sessionCompanyId;

  List<CostCenterModel> _rows = const <CostCenterModel>[];
  List<CompanyModel> _companies = const <CompanyModel>[];
  CostCenterModel? _selected;
  CostCenterModel? _detail;

  int? _companyId;
  int? _parentId;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _load(selectId: widget.initialId);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    _codeController.dispose();
    _nameController.dispose();
    _typeController.dispose();
    _pageScrollController.dispose();
    _workspaceController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _openRoute(String route) {
    final navigate = ShellRouteScope.maybeOf(context);
    if (navigate != null) {
      navigate(route);
      return;
    }
    Navigator.of(context).pushNamed(route);
  }

  void _snack() {
    final msg = _actionMessage;
    _actionMessage = null;
    if (!mounted || msg == null || msg.trim().isEmpty) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  List<CostCenterModel> get _filteredRows {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((row) {
          final raw = row.raw ?? row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            row.costCenterCode ?? '',
            row.costCenterName ?? '',
            stringValue(raw, 'cost_center_type'),
            _costCenterParentLabel(raw),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  List<CostCenterModel> get _parentOptions {
    final editingId = _detail?.id;
    return _rows
        .where((row) {
          final id = row.id;
          if (id == null) {
            return false;
          }
          if (editingId != null && id == editingId) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  String _listTitle(CostCenterModel row) {
    return row.costCenterCode?.trim().isNotEmpty == true
        ? row.costCenterCode!
        : (row.costCenterName ?? 'Cost center');
  }

  String _listSubtitle(CostCenterModel row) {
    final raw = row.raw ?? row.toJson();
    return [
      row.costCenterName ?? '',
      stringValue(raw, 'cost_center_type'),
      _costCenterParentLabel(raw),
    ].where((value) => value.trim().isNotEmpty).join(' · ');
  }

  void _apply(CostCenterModel? model) {
    if (model == null) {
      return;
    }
    final raw = model.raw ?? model.toJson();
    _companyId = intValue(raw, 'company_id');
    _parentId = intValue(raw, 'parent_id');
    _codeController.text = stringValue(raw, 'cost_center_code');
    _nameController.text = stringValue(raw, 'cost_center_name');
    _typeController.text = stringValue(raw, 'cost_center_type');
    _isActive = raw['is_active'] == true || raw['is_active'] == 1;
  }

  void _resetDraft() {
    _selected = null;
    _detail = null;
    _formError = null;
    _companyId = _sessionCompanyId;
    if (_companyId == null && _companies.isNotEmpty) {
      _companyId = _companies.first.id;
    }
    _parentId = null;
    _codeController.clear();
    _nameController.clear();
    _typeController.clear();
    _isActive = true;
    setState(() {});
  }

  Future<void> _load({int? selectId}) async {
    setState(() {
      _loading = true;
      _pageError = null;
    });
    try {
      final info = await hrSessionCompanyInfo();
      _sessionCompanyId = info.companyId;
      final filters = <String, dynamic>{'per_page': 200};
      if (info.companyId != null) {
        filters['company_id'] = info.companyId;
      }
      final responses = await Future.wait<dynamic>([
        _assets.costCenters(filters: filters),
        _master.companies(filters: const {'per_page': 200}),
      ]);
      _rows =
          (responses[0] as PaginatedResponse<CostCenterModel>).data ??
          const <CostCenterModel>[];
      _companies =
          ((responses[1] as PaginatedResponse<CompanyModel>).data ??
                  const <CompanyModel>[])
              .where((company) => company.isActive)
              .toList(growable: false);
      _loading = false;

      if (selectId != null) {
        final existing = _rows.cast<CostCenterModel?>().firstWhere(
          (row) => row?.id == selectId,
          orElse: () => null,
        );
        if (existing != null) {
          await _select(existing);
          return;
        }
        await _loadDetailById(selectId);
        return;
      }

      _resetDraft();
    } catch (e) {
      setState(() {
        _pageError = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadDetailById(int id) async {
    setState(() {
      _detailLoading = true;
      _formError = null;
    });
    try {
      final response = await _assets.costCenter(id);
      if (response.success == true && response.data != null) {
        _detail = response.data;
        _selected = response.data;
        _apply(response.data);
      } else {
        _formError = response.message;
      }
    } catch (e) {
      _formError = e.toString();
    } finally {
      if (mounted) {
        setState(() => _detailLoading = false);
      }
    }
  }

  Future<void> _reloadList() async {
    final info = await hrSessionCompanyInfo();
    final filters = <String, dynamic>{'per_page': 200};
    if (info.companyId != null) {
      filters['company_id'] = info.companyId;
    }
    final response = await _assets.costCenters(filters: filters);
    _rows = response.data ?? const <CostCenterModel>[];
  }

  Future<void> _select(CostCenterModel row) async {
    final id = row.id;
    if (id == null) {
      return;
    }
    setState(() {
      _selected = row;
      _detailLoading = true;
      _formError = null;
    });
    try {
      final response = await _assets.costCenter(id);
      if (response.success == true && response.data != null) {
        _detail = response.data;
        _apply(response.data);
      } else {
        _formError = response.message;
      }
    } catch (e) {
      _formError = e.toString();
    } finally {
      if (mounted) {
        setState(() => _detailLoading = false);
      }
    }
  }

  Future<void> _save() async {
    final companyId = _companyId;
    if (companyId == null) {
      setState(() => _formError = 'Company is required.');
      return;
    }
    final code = _codeController.text.trim();
    final name = _nameController.text.trim();
    if (code.isEmpty || name.isEmpty) {
      setState(() => _formError = 'Cost center code and name are required.');
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    try {
      final payload = <String, dynamic>{
        'company_id': companyId,
        'cost_center_code': code,
        'cost_center_name': name,
        'cost_center_type': nullIfEmpty(_typeController.text.trim()),
        'is_active': _isActive,
        if (_parentId != null) 'parent_id': _parentId,
      };
      final existingId = _detail?.id;
      if (existingId != null) {
        final response = await _assets.updateCostCenter(
          existingId,
          CostCenterModel(
            id: existingId,
            companyId: companyId,
            costCenterCode: code,
            costCenterName: name,
            isActive: _isActive,
            raw: payload,
          ),
        );
        if (response.success != true || response.data == null) {
          setState(() => _formError = response.message);
          return;
        }
        _detail = response.data;
        await _reloadList();
        _selected =
            _rows.cast<CostCenterModel?>().firstWhere(
              (row) => row?.id == existingId,
              orElse: () => null,
            ) ??
            response.data;
        _apply(_detail);
        _actionMessage = 'Cost center saved.';
        _snack();
      } else {
        final response = await _assets.createCostCenter(
          CostCenterModel(
            companyId: companyId,
            costCenterCode: code,
            costCenterName: name,
            isActive: _isActive,
            raw: payload,
          ),
        );
        if (response.success != true || response.data == null) {
          setState(() => _formError = response.message);
          return;
        }
        _detail = response.data;
        await _reloadList();
        final newId = response.data!.id;
        _selected =
            _rows.cast<CostCenterModel?>().firstWhere(
              (row) => row?.id == newId,
              orElse: () => null,
            ) ??
            response.data;
        _apply(_detail);
        _actionMessage = 'Cost center created.';
        _snack();
        if (newId != null) {
          _openRoute('/assets/cost-centers/$newId');
        }
      }
    } catch (e) {
      setState(() => _formError = e.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _delete() async {
    final id = _detail?.id;
    if (id == null) {
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete cost center'),
        content: const Text(
          'Only cost centers without children or linked assets can be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }

    setState(() => _saving = true);
    try {
      final response = await _assets.deleteCostCenter(id);
      if (response.success != true) {
        setState(() => _formError = response.message);
        return;
      }
      await _reloadList();
      _actionMessage = 'Cost center deleted.';
      _openRoute('/assets/cost-centers');
      _resetDraft();
      _snack();
    } catch (e) {
      setState(() => _formError = e.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      AdaptiveShellActionButton(
        onPressed: _loading
            ? null
            : () {
                _resetDraft();
                if (!Responsive.isDesktop(context)) {
                  _workspaceController.openEditor();
                }
              },
        icon: Icons.add_outlined,
        label: 'New cost center',
      ),
    ];

    final content = _buildContent(context);
    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }
    return AppStandaloneShell(
      title: 'Cost centers',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_loading) {
      return const AppLoadingView(message: 'Loading cost centers...');
    }
    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load cost centers',
        message: _pageError!,
        onRetry: () => _load(selectId: widget.initialId),
      );
    }

    final editorTitle = _selected == null
        ? 'New cost center'
        : _listTitle(_selected!);

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Cost centers',
      editorTitle: editorTitle,
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: SettingsListCard<CostCenterModel>(
        searchController: _searchController,
        searchHint: 'Search code, name, type, parent',
        items: _filteredRows,
        selectedItem: _selected,
        emptyMessage: 'No cost centers found.',
        itemBuilder: (item, selected) {
          return SettingsListTile(
            title: _listTitle(item),
            subtitle: _listSubtitle(item),
            selected: selected,
            onTap: () async {
              final isDesktop = Responsive.isDesktop(context);
              await _select(item);
              if (!mounted) {
                return;
              }
              if (!isDesktop) {
                _workspaceController.openEditor();
              }
            },
          );
        },
      ),
      editor: _detailLoading
          ? const AppLoadingView(message: 'Loading cost center...')
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_formError != null) ...[
                    AppErrorStateView.inline(message: _formError!),
                    const SizedBox(height: AppUiConstants.spacingSm),
                  ],
                  Text(
                    _selected == null ? 'New cost center' : 'Edit cost center',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppUiConstants.spacingMd),
                  if (_saving) const LinearProgressIndicator(),
                  SettingsFormWrap(
                    children: [
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Company',
                          border: OutlineInputBorder(),
                        ),
                        initialValue: _companyId,
                        items: _companies
                            .where((company) => company.id != null)
                            .map(
                              (company) => DropdownMenuItem<int>(
                                value: company.id,
                                child: Text(company.toString()),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: _saving
                            ? null
                            : (value) => setState(() => _companyId = value),
                      ),
                      AppFormTextField(
                        labelText: 'Cost center code',
                        controller: _codeController,
                      ),
                      AppFormTextField(
                        labelText: 'Cost center name',
                        controller: _nameController,
                      ),
                      DropdownButtonFormField<int?>(
                        decoration: const InputDecoration(
                          labelText: 'Parent cost center',
                          border: OutlineInputBorder(),
                        ),
                        initialValue: _parentId,
                        items: <DropdownMenuItem<int?>>[
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('None'),
                          ),
                          ..._parentOptions.map(
                            (row) => DropdownMenuItem<int?>(
                              value: row.id,
                              child: Text(_listTitle(row)),
                            ),
                          ),
                        ],
                        onChanged: _saving
                            ? null
                            : (value) => setState(() => _parentId = value),
                      ),
                      AppFormTextField(
                        labelText: 'Cost center type',
                        controller: _typeController,
                      ),
                    ],
                  ),
                  SwitchListTile(
                    title: const Text('Active'),
                    value: _isActive,
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _isActive = value),
                  ),
                  const SizedBox(height: AppUiConstants.spacingMd),
                  Wrap(
                    spacing: AppUiConstants.spacingSm,
                    runSpacing: AppUiConstants.spacingSm,
                    children: [
                      AppActionButton(
                        icon: Icons.save_outlined,
                        label: _selected == null ? 'Save' : 'Update',
                        busy: _saving,
                        onPressed: _save,
                      ),
                      if (_selected != null)
                        AppActionButton(
                          icon: Icons.delete_outline,
                          label: 'Delete',
                          filled: false,
                          onPressed: _saving ? null : _delete,
                        ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
