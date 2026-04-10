import '../../../helper/media_upload_helper.dart';
import '../../../screen.dart';

class ItemCategoryManagementPage extends StatefulWidget {
  const ItemCategoryManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ItemCategoryManagementPage> createState() =>
      _ItemCategoryManagementPageState();
}

class _ItemCategoryManagementPageState
    extends State<ItemCategoryManagementPage> {
  final InventoryService _inventoryService = InventoryService();
  final MediaService _mediaService = MediaService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _imagePathController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  bool _uploadingImage = false;
  String? _pageError;
  String? _formError;
  List<ItemCategoryModel> _items = const <ItemCategoryModel>[];
  List<ItemCategoryModel> _filteredItems = const <ItemCategoryModel>[];
  ItemCategoryModel? _selectedItem;
  int? _parentCategoryId;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applySearch);
    _loadItems();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _workspaceController.dispose();
    _searchController.dispose();
    _codeController.dispose();
    _nameController.dispose();
    _imagePathController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadItems({int? selectId}) async {
    setState(() {
      _initialLoading = _items.isEmpty;
      _pageError = null;
    });

    try {
      final response = await _inventoryService.itemCategories(
        filters: const {'per_page': 200, 'sort_by': 'category_name'},
      );
      final items = response.data ?? const <ItemCategoryModel>[];
      if (!mounted) {
        return;
      }

      setState(() {
        _items = items;
        _filteredItems = filterMasterList(items, _searchController.text, (
          item,
        ) {
          return [item.categoryCode, item.categoryName];
        });
        _initialLoading = false;
      });

      final selected = selectId != null
          ? items.cast<ItemCategoryModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (_selectedItem == null
                ? (items.isNotEmpty ? items.first : null)
                : items.cast<ItemCategoryModel?>().firstWhere(
                    (item) => item?.id == _selectedItem?.id,
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
        return [item.categoryCode, item.categoryName];
      });
    });
  }

  void _selectItem(ItemCategoryModel item) {
    _selectedItem = item;
    _codeController.text = item.categoryCode;
    _nameController.text = item.categoryName;
    _imagePathController.text = item.imagePath ?? '';
    _remarksController.text = item.remarks ?? '';
    _parentCategoryId = item.parentCategoryId;
    _isActive = item.isActive;
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedItem = null;
    _codeController.clear();
    _nameController.clear();
    _imagePathController.clear();
    _remarksController.clear();
    _parentCategoryId = null;
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

    final model = ItemCategoryModel(
      id: _selectedItem?.id,
      categoryCode: _codeController.text.trim(),
      categoryName: _nameController.text.trim(),
      parentCategoryId: _parentCategoryId,
      imagePath: nullIfEmpty(_imagePathController.text),
      isActive: _isActive,
      remarks: nullIfEmpty(_remarksController.text),
    );

    try {
      final response = _selectedItem == null
          ? await _inventoryService.createItemCategory(model)
          : await _inventoryService.updateItemCategory(
              _selectedItem!.id!,
              model,
            );
      final saved = response.data;
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadItems(selectId: saved?.id);
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
    final id = _selectedItem?.id;
    if (id == null) {
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    try {
      final response = await _inventoryService.deleteItemCategory(id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadItems();
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

  Future<void> _uploadCategoryImage() async {
    await MediaUploadHelper.uploadImage(
      context: context,
      mediaService: _mediaService,
      onLoading: (isLoading) {
        if (mounted) setState(() => _uploadingImage = isLoading);
      },
      onSuccess: (filePath) {
        if (mounted) {
          setState(() {
            _imagePathController.text = filePath;
            _formError = null;
          });
        }
      },
      onError: (error) {
        if (mounted) setState(() => _formError = error);
      },
      module: 'inventory',
      documentType: 'item_categories',
      documentId: _selectedItem?.id,
      purpose: 'category_image',
      folder: 'inventory/item-categories',
      isPublic: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();
    final actions = <Widget>[
      AdaptiveShellActionButton(
        onPressed: _startNew,
        icon: Icons.category_outlined,
        label: 'New Category',
      ),
    ];

    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }

    return AppStandaloneShell(
      title: 'Item Categories',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading item categories...');
    }

    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load item categories',
        message: _pageError!,
        onRetry: _loadItems,
      );
    }

    final parentOptions = _items
        .where((item) => item.id != _selectedItem?.id)
        .toList(growable: false);

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Item Categories',
      editorTitle: _selectedItem?.toString(),
      scrollController: _pageScrollController,
      list: SettingsListCard<ItemCategoryModel>(
        searchController: _searchController,
        searchHint: 'Search item categories',
        items: _filteredItems,
        selectedItem: _selectedItem,
        emptyMessage: 'No item categories found.',
        itemBuilder: (item, selected) => SettingsListTile(
          title: item.categoryName,
          subtitle: item.categoryCode,
          selected: selected,
          onTap: () => _selectItem(item),
        ),
      ),
      editor: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_formError != null) ...[
                Text(
                  _formError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'Category Code'),
                validator: Validators.compose([
                  Validators.required('Category Code'),
                  Validators.optionalMaxLength(50, 'Category Code'),
                ]),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Category Name'),
                validator: Validators.compose([
                  Validators.required('Category Name'),
                  Validators.optionalMaxLength(150, 'Category Name'),
                ]),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: _parentCategoryId,
                decoration: const InputDecoration(labelText: 'Parent Category'),
                items: <DropdownMenuItem<int?>>[
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('None'),
                  ),
                  ...parentOptions.map(
                    (item) => DropdownMenuItem<int?>(
                      value: item.id,
                      child: Text(item.categoryName),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _parentCategoryId = value),
              ),
              const SizedBox(height: 12),
              UploadPathField(
                controller: _imagePathController,
                labelText: 'Image Path',
                isUploading: _uploadingImage,
                onUpload: _uploadCategoryImage,
                previewUrl: AppConfig.resolvePublicFileUrl(
                  _imagePathController.text,
                ),
                previewIcon: Icons.category_outlined,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _remarksController,
                decoration: const InputDecoration(
                  labelText: 'Remarks',
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_selectedItem?.id != null)
                    TextButton(
                      onPressed: _saving ? null : _delete,
                      child: const Text('Delete'),
                    ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Saving...' : 'Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
    );
  }
}
