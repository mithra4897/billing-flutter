import '../../../screen.dart';

class BrandManagementPage extends StatefulWidget {
  const BrandManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<BrandManagementPage> createState() => _BrandManagementPageState();
}

class _BrandManagementPageState extends State<BrandManagementPage> {
  final InventoryService _inventoryService = InventoryService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  List<BrandModel> _brands = const <BrandModel>[];
  List<BrandModel> _filteredBrands = const <BrandModel>[];
  BrandModel? _selectedBrand;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applySearch);
    _loadBrands();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _workspaceController.dispose();
    _searchController.dispose();
    _codeController.dispose();
    _nameController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadBrands({int? selectId}) async {
    setState(() {
      _initialLoading = _brands.isEmpty;
      _pageError = null;
    });

    try {
      final response = await _inventoryService.brands(
        filters: const {'per_page': 200, 'sort_by': 'brand_name'},
      );
      final items = response.data ?? const <BrandModel>[];
      if (!mounted) {
        return;
      }

      setState(() {
        _brands = items;
        _filteredBrands = _filterBrands(items, _searchController.text);
        _initialLoading = false;
      });

      final selected = selectId != null
          ? items.cast<BrandModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (_selectedBrand == null
                ? (items.isNotEmpty ? items.first : null)
                : items.cast<BrandModel?>().firstWhere(
                    (item) => item?.id == _selectedBrand?.id,
                    orElse: () => items.isNotEmpty ? items.first : null,
                  ));

      if (selected != null) {
        _selectBrand(selected);
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

  List<BrandModel> _filterBrands(List<BrandModel> source, String query) {
    return filterMasterList(source, query, (brand) {
      return [
        brand.brandCode ?? '',
        brand.brandName ?? '',
        brand.remarks ?? '',
      ];
    });
  }

  void _applySearch() {
    setState(() {
      _filteredBrands = _filterBrands(_brands, _searchController.text);
    });
  }

  void _selectBrand(BrandModel brand) {
    _selectedBrand = brand;
    _codeController.text = brand.brandCode ?? '';
    _nameController.text = brand.brandName ?? '';
    _remarksController.text = brand.remarks ?? '';
    _isActive = brand.isActive;
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedBrand = null;
    _codeController.clear();
    _nameController.clear();
    _remarksController.clear();
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

    final model = BrandModel(
      id: _selectedBrand?.id,
      brandCode: _codeController.text.trim(),
      brandName: _nameController.text.trim(),
      remarks: nullIfEmpty(_remarksController.text),
      isActive: _isActive,
    );

    try {
      final response = _selectedBrand == null
          ? await _inventoryService.createBrand(model)
          : await _inventoryService.updateBrand(_selectedBrand!.id!, model);
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
      await _loadBrands(selectId: saved.id);
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
    final id = _selectedBrand?.id;
    if (id == null) {
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    try {
      final response = await _inventoryService.deleteBrand(id);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadBrands();
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
        icon: Icons.sell_outlined,
        label: 'New Brand',
      ),
    ];

    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }

    return AppStandaloneShell(
      title: 'Brands',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading brands...');
    }

    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load brands',
        message: _pageError!,
        onRetry: _loadBrands,
      );
    }

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Brands',
      editorTitle: _selectedBrand?.toString(),
      scrollController: _pageScrollController,
      list: SettingsListCard<BrandModel>(
        searchController: _searchController,
        searchHint: 'Search brands',
        items: _filteredBrands,
        selectedItem: _selectedBrand,
        emptyMessage: 'No brand records found.',
        itemBuilder: (brand, selected) => SettingsListTile(
          title: brand.brandName ?? '-',
          subtitle: brand.brandCode ?? '',
          selected: selected,
          onTap: () => _selectBrand(brand),
          trailing: SettingsStatusPill(
            label: brand.isActive ? 'Active' : 'Inactive',
            active: brand.isActive,
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
                AppFormTextField(
                  labelText: 'Brand Code',
                  controller: _codeController,
                  validator: Validators.compose([
                    Validators.required('Brand code'),
                    Validators.optionalMaxLength(50, 'Brand code'),
                  ]),
                ),
                AppFormTextField(
                  labelText: 'Brand Name',
                  controller: _nameController,
                  validator: Validators.compose([
                    Validators.required('Brand name'),
                    Validators.optionalMaxLength(150, 'Brand name'),
                  ]),
                ),
                AppFormTextField(
                  labelText: 'Remarks',
                  controller: _remarksController,
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppSwitchTile(
              label: 'Active',
              subtitle: 'Inactive brands stay hidden from normal selection.',
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                AppActionButton(
                  icon: Icons.save_outlined,
                  label: _selectedBrand == null ? 'Save Brand' : 'Update Brand',
                  onPressed: _save,
                  busy: _saving,
                ),
                if (_selectedBrand?.id != null)
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
