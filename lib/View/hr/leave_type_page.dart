import '../../screen.dart';

class LeaveTypeManagementPage extends StatefulWidget {
  const LeaveTypeManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<LeaveTypeManagementPage> createState() =>
      _LeaveTypeManagementPageState();
}

class _LeaveTypeManagementPageState extends State<LeaveTypeManagementPage> {
  final HrService _hrService = HrService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _leaveNameController = TextEditingController();
  final TextEditingController _maxDaysController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  bool _isPaid = true;
  List<LeaveTypeModel> _leaveTypes = const <LeaveTypeModel>[];
  List<LeaveTypeModel> _filteredLeaveTypes = const <LeaveTypeModel>[];
  LeaveTypeModel? _selectedLeaveType;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applySearch);
    _loadLeaveTypes();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _workspaceController.dispose();
    _searchController.dispose();
    _leaveNameController.dispose();
    _maxDaysController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaveTypes({int? selectId}) async {
    setState(() {
      _initialLoading = _leaveTypes.isEmpty;
      _pageError = null;
    });

    try {
      final response = await _hrService.leaveTypes(
        filters: const {'per_page': 200, 'sort_by': 'leave_name'},
      );
      final items = response.data ?? const <LeaveTypeModel>[];
      if (!mounted) return;

      setState(() {
        _leaveTypes = items;
        _filteredLeaveTypes = _filterLeaveTypes(items, _searchController.text);
        _initialLoading = false;
      });

      final selected = selectId != null
          ? items.cast<LeaveTypeModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (_selectedLeaveType == null
                ? (items.isNotEmpty ? items.first : null)
                : items.cast<LeaveTypeModel?>().firstWhere(
                    (item) => item?.id == _selectedLeaveType?.id,
                    orElse: () => items.isNotEmpty ? items.first : null,
                  ));

      if (selected != null) {
        _selectLeaveType(selected);
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

  List<LeaveTypeModel> _filterLeaveTypes(
    List<LeaveTypeModel> source,
    String query,
  ) {
    return filterMasterList(source, query, (item) {
      return [item.leaveName ?? '', item.maxDaysPerYear?.toString() ?? ''];
    });
  }

  void _applySearch() {
    setState(() {
      _filteredLeaveTypes = _filterLeaveTypes(
        _leaveTypes,
        _searchController.text,
      );
    });
  }

  void _selectLeaveType(LeaveTypeModel item) {
    _selectedLeaveType = item;
    _leaveNameController.text = item.leaveName ?? '';
    _maxDaysController.text = item.maxDaysPerYear == null
        ? ''
        : (item.maxDaysPerYear! % 1 == 0
              ? item.maxDaysPerYear!.toStringAsFixed(0)
              : item.maxDaysPerYear!.toStringAsFixed(2));
    _isPaid = item.isPaid;
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedLeaveType = null;
    _leaveNameController.clear();
    _maxDaysController.clear();
    _isPaid = true;
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
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _formError = null;
    });

    final model = LeaveTypeModel(
      id: _selectedLeaveType?.id,
      leaveName: _leaveNameController.text.trim(),
      maxDaysPerYear: double.tryParse(_maxDaysController.text.trim()),
      isPaid: _isPaid,
    );

    try {
      final response = _selectedLeaveType == null
          ? await _hrService.createLeaveType(model)
          : await _hrService.updateLeaveType(_selectedLeaveType!.id!, model);
      final saved = response.data;
      if (!mounted) return;
      if (saved == null) {
        setState(() => _formError = response.message);
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadLeaveTypes(selectId: saved.id);
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
    final id = _selectedLeaveType?.id;
    if (id == null) return;

    setState(() {
      _saving = true;
      _formError = null;
    });

    try {
      final response = await _hrService.deleteLeaveType(id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadLeaveTypes();
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
        icon: Icons.beach_access_outlined,
        label: 'New Leave Type',
      ),
    ];

    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }

    return AppStandaloneShell(
      title: 'Leave Types',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading leave types...');
    }

    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load leave types',
        message: _pageError!,
        onRetry: _loadLeaveTypes,
      );
    }

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Leave Types',
      editorTitle: _selectedLeaveType?.toString(),
      scrollController: _pageScrollController,
      list: SettingsListCard<LeaveTypeModel>(
        searchController: _searchController,
        searchHint: 'Search leave types',
        items: _filteredLeaveTypes,
        selectedItem: _selectedLeaveType,
        emptyMessage: 'No leave type records found.',
        itemBuilder: (item, selected) => SettingsListTile(
          title: item.leaveName ?? '-',
          subtitle: [
            if (item.maxDaysPerYear != null)
              'Max ${item.maxDaysPerYear! % 1 == 0 ? item.maxDaysPerYear!.toStringAsFixed(0) : item.maxDaysPerYear!.toStringAsFixed(2)} days',
            item.isPaid ? 'Paid' : 'Unpaid',
          ].join(' • '),
          selected: selected,
          onTap: () => _selectLeaveType(item),
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
                  labelText: 'Leave Name',
                  controller: _leaveNameController,
                  validator: Validators.compose([
                    Validators.required('Leave Name'),
                    Validators.optionalMaxLength(100, 'Leave Name'),
                  ]),
                ),
                AppFormTextField(
                  labelText: 'Max Days Per Year',
                  controller: _maxDaysController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.optionalNonNegativeNumber(
                    'Max Days Per Year',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            AppSwitchTile(
              label: 'Paid Leave',
              value: _isPaid,
              onChanged: (value) => setState(() => _isPaid = value),
            ),
            const SizedBox(height: AppUiConstants.spacingLg),
            Wrap(
              spacing: AppUiConstants.spacingSm,
              runSpacing: AppUiConstants.spacingSm,
              children: [
                AppActionButton(
                  icon: Icons.save_outlined,
                  label: _selectedLeaveType == null
                      ? 'Save Leave Type'
                      : 'Update Leave Type',
                  onPressed: _save,
                  busy: _saving,
                ),
                if (_selectedLeaveType?.id != null)
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
