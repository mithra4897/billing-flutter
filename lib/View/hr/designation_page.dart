import '../../screen.dart';

class DesignationManagementPage extends StatefulWidget {
  const DesignationManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<DesignationManagementPage> createState() =>
      _DesignationManagementPageState();
}

class _DesignationManagementPageState extends State<DesignationManagementPage> {
  final HrService _hrService = HrService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  List<DesignationModel> _designations = const <DesignationModel>[];
  List<DesignationModel> _filteredDesignations = const <DesignationModel>[];
  DesignationModel? _selectedDesignation;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applySearch);
    _loadDesignations();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _workspaceController.dispose();
    _searchController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadDesignations({int? selectId}) async {
    setState(() {
      _initialLoading = _designations.isEmpty;
      _pageError = null;
    });

    try {
      final response = await _hrService.designations(
        filters: const {'per_page': 200, 'sort_by': 'designation_name'},
      );
      final items = response.data ?? const <DesignationModel>[];
      if (!mounted) return;

      setState(() {
        _designations = items;
        _filteredDesignations = _filterDesignations(
          items,
          _searchController.text,
        );
        _initialLoading = false;
      });

      final selected = selectId != null
          ? items.cast<DesignationModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (_selectedDesignation == null
                ? (items.isNotEmpty ? items.first : null)
                : items.cast<DesignationModel?>().firstWhere(
                    (item) => item?.id == _selectedDesignation?.id,
                    orElse: () => items.isNotEmpty ? items.first : null,
                  ));

      if (selected != null) {
        _selectDesignation(selected);
      } else {
        _resetForm();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pageError = error.toString();
        _initialLoading = false;
      });
    }
  }

  List<DesignationModel> _filterDesignations(
    List<DesignationModel> source,
    String query,
  ) {
    return filterMasterList(source, query, (item) {
      return [item.designationName ?? ''];
    });
  }

  void _applySearch() {
    setState(() {
      _filteredDesignations = _filterDesignations(
        _designations,
        _searchController.text,
      );
    });
  }

  void _selectDesignation(DesignationModel item) {
    _selectedDesignation = item;
    _nameController.text = item.designationName ?? '';
    _isActive = item.isActive;
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedDesignation = null;
    _nameController.clear();
    _isActive = true;
    _formError = null;
    setState(() {});
  }

  void _startNew() {
    _resetForm();
    if (!Responsive.isDesktop(context)) {
      _workspaceController.openEditor();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    final model = DesignationModel(
      id: _selectedDesignation?.id,
      designationName: _nameController.text.trim(),
      isActive: _isActive,
    );

    try {
      final response = _selectedDesignation == null
          ? await _hrService.createDesignation(model)
          : await _hrService.updateDesignation(
              _selectedDesignation!.id!,
              model,
            );
      final saved = response.data;
      if (!mounted) return;
      if (saved == null) {
        setState(() => _formError = response.message);
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadDesignations(selectId: saved.id);
    } catch (error) {
      if (!mounted) return;
      setState(() => _formError = error.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _delete() async {
    final id = _selectedDesignation?.id;
    if (id == null) return;

    setState(() {
      _saving = true;
      _formError = null;
    });

    try {
      final response = await _hrService.deleteDesignation(id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadDesignations();
    } catch (error) {
      if (!mounted) return;
      setState(() => _formError = error.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();
    final actions = <Widget>[
      AdaptiveShellActionButton(
        onPressed: _startNew,
        icon: Icons.workspace_premium_outlined,
        label: 'New Designation',
      ),
    ];

    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }

    return AppStandaloneShell(
      title: 'Designations',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading designations...');
    }

    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load designations',
        message: _pageError!,
        onRetry: _loadDesignations,
      );
    }

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Designations',
      editorTitle: _selectedDesignation?.toString(),
      scrollController: _pageScrollController,
      list: SettingsListCard<DesignationModel>(
        searchController: _searchController,
        searchHint: 'Search designations',
        items: _filteredDesignations,
        selectedItem: _selectedDesignation,
        emptyMessage: 'No designation records found.',
        itemBuilder: (item, selected) => SettingsListTile(
          title: item.designationName ?? '-',
          subtitle: item.id?.toString() ?? '',
          selected: selected,
          onTap: () => _selectDesignation(item),
          trailing: SettingsStatusPill(
            label: item.isActive ? 'Active' : 'Inactive',
            active: item.isActive,
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
              const SizedBox(height: AppUiConstants.spacingSm),
            ],
            SettingsFormWrap(
              children: [
                AppFormTextField(
                  labelText: 'Designation Name',
                  controller: _nameController,
                  validator: Validators.compose([
                    Validators.required('Designation Name'),
                    Validators.optionalMaxLength(100, 'Designation Name'),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            AppSwitchTile(
              label: 'Active',
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
            const SizedBox(height: AppUiConstants.spacingLg),
            Wrap(
              spacing: AppUiConstants.spacingSm,
              runSpacing: AppUiConstants.spacingSm,
              children: [
                AppActionButton(
                  icon: Icons.save_outlined,
                  label: _selectedDesignation == null
                      ? 'Save Designation'
                      : 'Update Designation',
                  onPressed: _save,
                  busy: _saving,
                ),
                if (_selectedDesignation?.id != null)
                  AppActionButton(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    onPressed: _delete,
                    busy: _saving,
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
