import '../../../screen.dart';

class PostingRuleGroupManagementPage extends StatefulWidget {
  const PostingRuleGroupManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<PostingRuleGroupManagementPage> createState() =>
      _PostingRuleGroupManagementPageState();
}

class _PostingRuleGroupManagementPageState
    extends State<PostingRuleGroupManagementPage> {
  static const List<AppDropdownItem<String>> _triggerItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'on_save', label: 'On save'),
        AppDropdownItem(value: 'on_approve', label: 'On approve'),
        AppDropdownItem(value: 'on_post', label: 'On post'),
        AppDropdownItem(value: 'on_cancel', label: 'On cancel'),
        AppDropdownItem(value: 'on_reverse', label: 'On reverse'),
      ];

  final AccountsService _accountsService = AccountsService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _documentTypeController =
      TextEditingController();
  final TextEditingController _descriptionController =
      TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  List<PostingRuleGroupModel> _rows = const <PostingRuleGroupModel>[];
  List<PostingRuleGroupModel> _filtered = const <PostingRuleGroupModel>[];
  PostingRuleGroupModel? _selected;
  String _triggerEvent = 'on_post';
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applySearch);
    _load();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _workspaceController.dispose();
    _searchController.dispose();
    _codeController.dispose();
    _nameController.dispose();
    _documentTypeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _json(PostingRuleGroupModel? m) =>
      m?.data ?? const <String, dynamic>{};

  Future<void> _load({int? selectId}) async {
    setState(() {
      _initialLoading = _rows.isEmpty;
      _pageError = null;
    });
    try {
      final response = await _accountsService.postingRuleGroups(
        filters: const {'per_page': 300, 'sort_by': 'group_name'},
      );
      final items = response.data ?? const <PostingRuleGroupModel>[];
      if (!mounted) return;
      setState(() {
        _rows = items;
        _filtered = _filter(items, _searchController.text);
        _initialLoading = false;
      });

      final selected = selectId != null
          ? items.cast<PostingRuleGroupModel?>().firstWhere(
              (e) => intValue(_json(e), 'id') == selectId,
              orElse: () => null,
            )
          : (_selected == null
                ? (items.isNotEmpty ? items.first : null)
                : items.cast<PostingRuleGroupModel?>().firstWhere(
                    (e) =>
                        intValue(_json(e), 'id') ==
                        intValue(_json(_selected), 'id'),
                    orElse: () => items.isNotEmpty ? items.first : null,
                  ));
      if (selected != null) {
        _applySelection(selected);
      } else {
        _resetForm();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pageError = e.toString();
        _initialLoading = false;
      });
    }
  }

  List<PostingRuleGroupModel> _filter(
    List<PostingRuleGroupModel> source,
    String q,
  ) {
    return filterMasterList(source, q, (item) {
      final d = item.data;
      return [
        stringValue(d, 'group_code'),
        stringValue(d, 'group_name'),
        stringValue(d, 'document_type'),
      ];
    });
  }

  void _applySearch() {
    setState(() => _filtered = _filter(_rows, _searchController.text));
  }

  void _applySelection(PostingRuleGroupModel item) {
    final d = item.data;
    _selected = item;
    _codeController.text = stringValue(d, 'group_code');
    _nameController.text = stringValue(d, 'group_name');
    _documentTypeController.text = stringValue(d, 'document_type');
    _descriptionController.text = stringValue(d, 'description');
    _triggerEvent = stringValue(d, 'trigger_event', 'on_post');
    _isActive = boolValue(d, 'is_active', fallback: true);
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selected = null;
    _codeController.clear();
    _nameController.clear();
    _documentTypeController.clear();
    _descriptionController.clear();
    _triggerEvent = 'on_post';
    _isActive = true;
    _formError = null;
    setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _formError = null;
    });
    final body = PostingRuleGroupModel.fromJson(<String, dynamic>{
      'group_code': _codeController.text.trim(),
      'group_name': _nameController.text.trim(),
      'document_type': _documentTypeController.text.trim(),
      'trigger_event': _triggerEvent,
      'description': nullIfEmpty(_descriptionController.text),
      'is_active': _isActive,
    });
    try {
      final ApiResponse<PostingRuleGroupModel> response;
      final sid = intValue(_json(_selected), 'id');
      if (sid == null) {
        response = await _accountsService.createPostingRuleGroup(body);
      } else {
        response = await _accountsService.updatePostingRuleGroup(sid, body);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _load(selectId: intValue(_json(response.data), 'id') ?? sid);
    } catch (e) {
      if (mounted) setState(() => _formError = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final id = intValue(_json(_selected), 'id');
    if (id == null) return;
    setState(() {
      _saving = true;
      _formError = null;
    });
    try {
      final response = await _accountsService.deletePostingRuleGroup(id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _load();
    } catch (e) {
      if (mounted) setState(() => _formError = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _startNew() {
    _resetForm();
    if (!Responsive.isDesktop(context)) {
      _workspaceController.openEditor();
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();
    final actions = <Widget>[
      AdaptiveShellActionButton(
        onPressed: _startNew,
        icon: Icons.folder_special_outlined,
        label: 'New Group',
      ),
    ];
    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }
    return AppStandaloneShell(
      title: 'Posting Rule Groups',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading posting rule groups...');
    }
    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load',
        message: _pageError!,
        onRetry: _load,
      );
    }
    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Posting Rule Groups',
      editorTitle: stringValue(_json(_selected), 'group_name').isEmpty
          ? null
          : stringValue(_json(_selected), 'group_name'),
      scrollController: _pageScrollController,
      list: SettingsListCard<PostingRuleGroupModel>(
        searchController: _searchController,
        searchHint: 'Search groups',
        items: _filtered,
        selectedItem: _selected,
        emptyMessage: 'No posting rule groups.',
        itemBuilder: (item, selected) {
          final d = item.data;
          return SettingsListTile(
            title: stringValue(d, 'group_name'),
            subtitle: [
              stringValue(d, 'group_code'),
              stringValue(d, 'document_type'),
              stringValue(d, 'trigger_event'),
            ].join(' · '),
            selected: selected,
            onTap: () => _applySelection(item),
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
                  labelText: 'Group code',
                  controller: _codeController,
                  validator: Validators.compose([
                    Validators.required('Group code'),
                    Validators.optionalMaxLength(50, 'Group code'),
                  ]),
                ),
                AppFormTextField(
                  labelText: 'Group name',
                  controller: _nameController,
                  validator: Validators.compose([
                    Validators.required('Group name'),
                    Validators.optionalMaxLength(150, 'Group name'),
                  ]),
                ),
                AppFormTextField(
                  labelText: 'Document type',
                  controller: _documentTypeController,
                  validator: Validators.compose([
                    Validators.required('Document type'),
                    Validators.optionalMaxLength(50, 'Document type'),
                  ]),
                ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Trigger event',
                  mappedItems: _triggerItems,
                  initialValue: _triggerEvent,
                  onChanged: (v) => setState(() => _triggerEvent = v ?? 'on_post'),
                ),
                AppFormTextField(
                  labelText: 'Description',
                  controller: _descriptionController,
                  maxLines: 3,
                ),
                SizedBox(
                  width: AppUiConstants.switchFieldWidth,
                  child: AppSwitchTile(
                    label: 'Active',
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingLg),
            Wrap(
              spacing: AppUiConstants.spacingSm,
              runSpacing: AppUiConstants.spacingSm,
              children: [
                AppActionButton(
                  icon: Icons.save_outlined,
                  label: intValue(_json(_selected), 'id') == null
                      ? 'Save'
                      : 'Update',
                  onPressed: _save,
                  busy: _saving,
                ),
                if (intValue(_json(_selected), 'id') != null)
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
