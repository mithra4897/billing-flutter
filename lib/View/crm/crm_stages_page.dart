import '../../screen.dart';

class CrmStagesPage extends StatefulWidget {
  const CrmStagesPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<CrmStagesPage> createState() => _CrmStagesPageState();
}

class _CrmStagesPageState extends State<CrmStagesPage> {
  static const List<AppDropdownItem<String>> _stageTypes =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'lead', label: 'Lead'),
        AppDropdownItem(value: 'enquiry', label: 'Enquiry'),
        AppDropdownItem(value: 'opportunity', label: 'Opportunity'),
        AppDropdownItem(value: 'closed_won', label: 'Closed Won'),
        AppDropdownItem(value: 'closed_lost', label: 'Closed Lost'),
      ];

  final CrmService _crmService = CrmService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _sequenceController = TextEditingController();
  final TextEditingController _probabilityController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  List<CrmStageModel> _items = const <CrmStageModel>[];
  List<CrmStageModel> _filteredItems = const <CrmStageModel>[];
  CrmStageModel? _selectedItem;
  String _stageType = 'lead';
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
    _workspaceController.dispose();
    _searchController.dispose();
    _nameController.dispose();
    _sequenceController.dispose();
    _probabilityController.dispose();
    super.dispose();
  }

  Future<void> _loadPage({int? selectId}) async {
    setState(() {
      _initialLoading = _items.isEmpty;
      _pageError = null;
    });

    try {
      final response = await _crmService.stages(
        filters: const {'per_page': 200, 'sort_by': 'sequence_no'},
      );
      final items = response.data ?? const <CrmStageModel>[];
      if (!mounted) {
        return;
      }

      setState(() {
        _items = items;
        _initialLoading = false;
      });
      _applySearch();

      final selected = selectId != null
          ? items.cast<CrmStageModel?>().firstWhere(
              (item) => intValue(item?.toJson() ?? const {}, 'id') == selectId,
              orElse: () => null,
            )
          : (_selectedItem == null
                ? (items.isNotEmpty ? items.first : null)
                : items.cast<CrmStageModel?>().firstWhere(
                    (item) =>
                        intValue(item?.toJson() ?? const {}, 'id') ==
                        intValue(_selectedItem!.toJson(), 'id'),
                    orElse: () => items.isNotEmpty ? items.first : null,
                  ));

      if (selected != null) {
        _selectItem(selected);
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
      _filteredItems = filterMasterList(_items, _searchController.text, (item) {
        final data = item.toJson();
        return [
          stringValue(data, 'stage_name'),
          stringValue(data, 'stage_type'),
          stringValue(data, 'sequence_no'),
        ];
      });
    });
  }

  void _selectItem(CrmStageModel item) {
    final data = item.toJson();
    setState(() {
      _selectedItem = item;
      _nameController.text = stringValue(data, 'stage_name');
      _sequenceController.text = stringValue(data, 'sequence_no');
      _probabilityController.text = stringValue(data, 'probability_percent');
      _stageType = stringValue(data, 'stage_type', 'lead');
      _isDefault = boolValue(data, 'is_default');
      _isActive = boolValue(data, 'is_active', fallback: true);
      _formError = null;
    });
  }

  void _resetForm() {
    setState(() {
      _selectedItem = null;
      _nameController.clear();
      _sequenceController.text = '1';
      _probabilityController.text = '0';
      _stageType = 'lead';
      _isDefault = false;
      _isActive = true;
      _formError = null;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    final payload = CrmStageModel({
      'stage_name': _nameController.text.trim(),
      'stage_type': _stageType,
      'sequence_no': int.tryParse(_sequenceController.text.trim()) ?? 1,
      'probability_percent':
          double.tryParse(_probabilityController.text.trim()) ?? 0,
      'is_default': _isDefault,
      'is_active': _isActive,
    });

    try {
      final response = _selectedItem == null
          ? await _crmService.createStage(payload)
          : await _crmService.updateStage(
              intValue(_selectedItem!.toJson(), 'id')!,
              payload,
            );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadPage(selectId: intValue(response.data?.toJson() ?? const {}, 'id'));
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _formError = error.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _delete() async {
    final id = intValue(_selectedItem?.toJson() ?? const {}, 'id');
    if (id == null) {
      return;
    }

    try {
      final response = await _crmService.deleteStage(id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadPage();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _formError = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      AdaptiveShellActionButton(
        onPressed: () {
          _resetForm();
          if (!Responsive.isDesktop(context)) {
            _workspaceController.openEditor();
          }
        },
        icon: Icons.add_outlined,
        label: 'New Stage',
      ),
    ];

    final content = _buildContent();
    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }
    return AppStandaloneShell(
      title: 'CRM Stages',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading CRM stages...');
    }
    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load CRM stages',
        message: _pageError!,
        onRetry: _loadPage,
      );
    }

    return SettingsWorkspace(
      title: 'CRM Stages',
      scrollController: _pageScrollController,
      controller: _workspaceController,
      editorTitle: _selectedItem?.toString() ?? 'New Stage',
      list: SettingsListCard<CrmStageModel>(
        searchController: _searchController,
        searchHint: 'Search stages',
        items: _filteredItems,
        selectedItem: _selectedItem,
        emptyMessage: 'No CRM stages found.',
        itemBuilder: (item, selected) {
          final data = item.toJson();
          return SettingsListTile(
            title: item.toString(),
            subtitle: [
              stringValue(data, 'stage_type'),
              'Seq ${stringValue(data, 'sequence_no')}',
            ].join(' • '),
            selected: selected,
            onTap: () => _selectItem(item),
            trailing: SettingsStatusPill(
              label: boolValue(data, 'is_active', fallback: true)
                  ? 'Active'
                  : 'Inactive',
              active: boolValue(data, 'is_active', fallback: true),
            ),
          );
        },
      ),
      editor: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_formError != null) ...[
              AppErrorStateView.inline(message: _formError!),
              const SizedBox(height: AppUiConstants.spacingSm),
            ],
            SettingsFormWrap(
              children: [
                AppFormTextField(
                  controller: _nameController,
                  labelText: 'Stage Name',
                  validator: Validators.required('Stage Name'),
                ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Stage Type',
                  mappedItems: _stageTypes,
                  initialValue: _stageType,
                  onChanged: (value) =>
                      setState(() => _stageType = value ?? _stageType),
                ),
                AppFormTextField(
                  controller: _sequenceController,
                  labelText: 'Sequence No',
                  keyboardType: TextInputType.number,
                  validator: Validators.compose([
                    Validators.required('Sequence No'),
                    Validators.optionalNonNegativeNumber('Sequence No'),
                  ]),
                ),
                AppFormTextField(
                  controller: _probabilityController,
                  labelText: 'Probability %',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.optionalNonNegativeNumber(
                    'Probability %',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            AppSwitchTile(
              label: 'Default Stage',
              value: _isDefault,
              onChanged: (value) => setState(() => _isDefault = value),
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
            AppSwitchTile(
              label: 'Active',
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            Wrap(
              spacing: AppUiConstants.spacingSm,
              runSpacing: AppUiConstants.spacingSm,
              children: [
                AppActionButton(
                  icon: Icons.save_outlined,
                  label: _selectedItem == null ? 'Save Stage' : 'Update Stage',
                  onPressed: _save,
                  busy: _saving,
                ),
                if (_selectedItem != null)
                  AppActionButton(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    filled: false,
                    onPressed: _delete,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
