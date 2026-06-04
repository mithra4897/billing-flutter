import '../../controller/assets/fixed_asset_management_controller.dart';
import '../../screen.dart';

class FixedAssetPage extends StatefulWidget {
  const FixedAssetPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<FixedAssetPage> createState() => _FixedAssetPageState();
}

class _FixedAssetPageState extends State<FixedAssetPage> {
  late final String _controllerTag;
  late final FixedAssetManagementController _controller;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'FixedAssetManagementController-${widget.initialId ?? 'new'}',
    );
    _controller = Get.put(
      FixedAssetManagementController(initialId: widget.initialId),
      tag: _controllerTag,
      permanent: true,
    );
  }

  void _snack() {
    final msg = _controller.consumeActionMessage();
    if (!mounted || msg == null || msg.trim().isEmpty) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _openBooks(FixedAssetManagementController controller) {
    final id = intValue(controller.detail?.toJson() ?? const {}, 'id');
    if (id == null) {
      return;
    }
    showDialog<void>(
      context: context,
      builder: (ctx) => _AssetBooksDialog(assetId: id),
    ).then((_) {
      if (mounted) {
        controller.loadDetailById(id);
      }
    });
  }

  ErpLinkFieldOption<T>? _selectedOption<T>(
    T? value,
    List<ErpLinkFieldOption<T>> options,
  ) {
    if (value == null) {
      return null;
    }
    for (final option in options) {
      if (option.value == value) {
        return option;
      }
    }
    return null;
  }

  ErpLinkFieldOption<String>? _selectedTextOption(
    String value,
    List<ErpLinkFieldOption<String>> options,
  ) {
    final text = value.trim();
    if (text.isEmpty) {
      return null;
    }
    for (final option in options) {
      if (option.value.trim().toLowerCase() == text.toLowerCase()) {
        return option;
      }
    }
    return ErpLinkFieldOption<String>(value: text, label: text);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FixedAssetManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: controller.loading
                ? null
                : () => controller.startNew(
                    isDesktop: Responsive.isDesktop(context),
                  ),
            icon: Icons.add_outlined,
            label: 'New asset',
          ),
        ];

        final content = _buildContent(context, controller);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Fixed assets',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    FixedAssetManagementController controller,
  ) {
    if (controller.loading) {
      return const AppLoadingView(message: 'Loading assets...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load assets',
        message: controller.pageError!,
        onRetry: () => controller.load(selectId: widget.initialId),
      );
    }

    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Fixed assets',
      editorTitle: controller.selected == null
          ? 'New asset'
          : controller.listTitle(controller.selected!),
      editorOnly: widget.editorOnly,
      scrollController: controller.pageScrollController,
      list: SettingsListCard<AssetModel>(
        searchController: controller.searchController,
        searchHint: 'Search code, name, category, status',
        items: controller.filteredRows,
        selectedItem: controller.selected,
        emptyMessage: 'No assets found.',
        itemBuilder: (item, selected) {
          return SettingsListTile(
            title: controller.listTitle(item),
            subtitle: controller.listSubtitle(item),
            selected: selected,
            onTap: () async {
              final isDesktop = Responsive.isDesktop(context);
              await controller.select(item);
              if (!context.mounted) {
                return;
              }
              if (!isDesktop) {
                controller.workspaceController.openEditor();
              }
            },
          );
        },
      ),
      editor: controller.detailLoading
          ? const AppLoadingView(message: 'Loading asset...')
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (controller.formError != null) ...[
                    AppErrorStateView.inline(message: controller.formError!),
                    const SizedBox(height: AppUiConstants.spacingSm),
                  ],
                  if (controller.saving || controller.actionBusy)
                    const LinearProgressIndicator(),
                  Builder(
                    builder: (context) {
                      final categoryOptions = controller.categoryOptions
                          .where(
                            (category) =>
                                intValue(category.toJson(), 'id') != null,
                          )
                          .map((category) {
                            final data = category.toJson();
                            final id = intValue(data, 'id')!;
                            final code = stringValue(data, 'category_code');
                            final name = stringValue(data, 'category_name');
                            return ErpLinkFieldOption<int>(
                              value: id,
                              label: name.isNotEmpty ? name : code,
                              subtitle: code.isNotEmpty && name.isNotEmpty
                                  ? code
                                  : null,
                              searchText: '$code $name',
                            );
                          })
                          .toList(growable: false);
                      final supplierOptions = controller.parties
                          .where((party) => party.id != null)
                          .map(
                            (party) => ErpLinkFieldOption<int>(
                              value: party.id!,
                              label: party.toString(),
                            ),
                          )
                          .toList(growable: false);
                      final costCenterOptions = controller.costCenterOptions
                          .where((costCenter) => costCenter.id != null)
                          .map(
                            (costCenter) => ErpLinkFieldOption<int>(
                              value: costCenter.id!,
                              label: costCenter.toString(),
                            ),
                          )
                          .toList(growable: false);
                      final warehouseOptions = controller.warehouseOptions
                          .where((warehouse) => warehouse.id != null)
                          .map(
                            (warehouse) => ErpLinkFieldOption<int>(
                              value: warehouse.id!,
                              label: warehouse.toString(),
                            ),
                          )
                          .toList(growable: false);
                      final departmentOptions = controller.departmentOptions
                          .map(
                            (department) => ErpLinkFieldOption<String>(
                              value: department.departmentName ?? '',
                              label: department.departmentName ?? '',
                            ),
                          )
                          .where((option) => option.value.trim().isNotEmpty)
                          .toList(growable: false);
                      final employeeOptions = controller.employeeOptions
                          .map(
                            (employee) => ErpLinkFieldOption<String>(
                              value: employee.employeeName ?? '',
                              label:
                                  employee.employeeName ??
                                  employee.employeeCode ??
                                  '',
                              subtitle:
                                  [
                                        employee.employeeCode ?? '',
                                        employee.departmentName ?? '',
                                      ]
                                      .where((value) => value.trim().isNotEmpty)
                                      .join(' · '),
                              searchText: [
                                employee.employeeName ?? '',
                                employee.employeeCode ?? '',
                                employee.departmentName ?? '',
                              ].join(' '),
                            ),
                          )
                          .where((option) => option.value.trim().isNotEmpty)
                          .toList(growable: false);

                      return SettingsFormWrap(
                        children: [
                          ErpLinkField<int>(
                            labelText: 'Asset category',
                            doctypeLabel: 'Asset category',
                            enabled:
                                !controller.saving && !controller.actionBusy,
                            initialSelection: _selectedOption(
                              controller.categoryId,
                              categoryOptions,
                            ),
                            options: categoryOptions,
                            onChanged: controller.setCategoryId,
                          ),
                          AppFormTextField(
                            labelText: 'Asset code',
                            controller: controller.assetCodeController,
                          ),
                          AppFormTextField(
                            labelText: 'Asset name',
                            controller: controller.assetNameController,
                          ),
                          AppFormTextField(
                            labelText: 'Asset tag no',
                            controller: controller.assetTagController,
                          ),
                          AppFormTextField(
                            labelText: 'Serial no',
                            controller: controller.serialNoController,
                          ),
                          AppFormTextField(
                            labelText: 'Manufacturer',
                            controller: controller.manufacturerController,
                          ),
                          AppFormTextField(
                            labelText: 'Model no',
                            controller: controller.modelNoController,
                          ),
                          AppFormTextField(
                            labelText: 'Purchase date',
                            controller: controller.purchaseDateController,
                            hintText: 'YYYY-MM-DD',
                            inputFormatters: const [DateInputFormatter()],
                          ),
                          AppFormTextField(
                            labelText: 'Capitalization date',
                            controller: controller.capitalizationDateController,
                            hintText: 'YYYY-MM-DD',
                            inputFormatters: const [DateInputFormatter()],
                          ),
                          AppFormTextField(
                            labelText: 'Put to use date',
                            controller: controller.putToUseDateController,
                            hintText: 'YYYY-MM-DD',
                            inputFormatters: const [DateInputFormatter()],
                          ),
                          ErpLinkField<int>(
                            labelText: 'Supplier',
                            doctypeLabel: 'Supplier',
                            enabled:
                                !controller.saving && !controller.actionBusy,
                            initialSelection: _selectedOption(
                              controller.supplierPartyId,
                              supplierOptions,
                            ),
                            options: supplierOptions,
                            onChanged: controller.setSupplierPartyId,
                          ),
                          ErpLinkField<int>(
                            labelText: 'Cost center',
                            doctypeLabel: 'Cost center',
                            enabled:
                                !controller.saving && !controller.actionBusy,
                            initialSelection: _selectedOption(
                              controller.costCenterId,
                              costCenterOptions,
                            ),
                            options: costCenterOptions,
                            onChanged: controller.setCostCenterId,
                          ),
                          ErpLinkField<int>(
                            labelText: 'Warehouse',
                            doctypeLabel: 'Warehouse',
                            enabled:
                                !controller.saving && !controller.actionBusy,
                            initialSelection: _selectedOption(
                              controller.warehouseId,
                              warehouseOptions,
                            ),
                            options: warehouseOptions,
                            onChanged: controller.setWarehouseId,
                          ),
                          ErpLinkField<String>(
                            labelText: 'Department',
                            doctypeLabel: 'Department',
                            enabled:
                                !controller.saving && !controller.actionBusy,
                            initialSelection: _selectedTextOption(
                              controller.departmentController.text,
                              departmentOptions,
                            ),
                            options: departmentOptions,
                            onChanged: controller.setDepartmentName,
                          ),
                          ErpLinkField<String>(
                            labelText: 'Employee',
                            doctypeLabel: 'Employee',
                            enabled:
                                !controller.saving && !controller.actionBusy,
                            initialSelection: _selectedTextOption(
                              controller.employeeController.text,
                              employeeOptions,
                            ),
                            options: employeeOptions,
                            onChanged: controller.setEmployeeName,
                          ),
                          AppFormTextField(
                            labelText: 'Acquisition cost',
                            controller: controller.acquisitionCostController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                          AppFormTextField(
                            labelText: 'Additional cost',
                            controller: controller.additionalCostController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                          AppFormTextField(
                            labelText: 'Capitalization value',
                            controller:
                                controller.capitalizationValueController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                          AppFormTextField(
                            labelText: 'Salvage value',
                            controller: controller.salvageValueController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                          AppFormTextField(
                            labelText: 'Condition status',
                            controller: controller.conditionStatusController,
                            hintText: 'good, fair, damaged',
                          ),
                          AppFormTextField(
                            labelText: 'Warranty start',
                            controller: controller.warrantyStartController,
                            hintText: 'YYYY-MM-DD',
                            inputFormatters: const [DateInputFormatter()],
                          ),
                          AppFormTextField(
                            labelText: 'Warranty end',
                            controller: controller.warrantyEndController,
                            hintText: 'YYYY-MM-DD',
                            inputFormatters: const [DateInputFormatter()],
                          ),
                          AppFormTextField(
                            labelText: 'Notes',
                            controller: controller.notesController,
                            maxLines: 3,
                          ),
                        ],
                      );
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Depreciable'),
                    value: controller.isDepreciable,
                    onChanged: controller.saving || controller.actionBusy
                        ? null
                        : controller.setIsDepreciable,
                  ),
                  SwitchListTile(
                    title: const Text('Active'),
                    value: controller.isActive,
                    onChanged: controller.saving || controller.actionBusy
                        ? null
                        : controller.setIsActive,
                  ),
                  const SizedBox(height: AppUiConstants.spacingMd),
                  Wrap(
                    spacing: AppUiConstants.spacingSm,
                    runSpacing: AppUiConstants.spacingSm,
                    children: [
                      AppActionButton(
                        icon: Icons.save_outlined,
                        label: controller.selected == null ? 'Save' : 'Update',
                        busy: controller.saving,
                        onPressed: controller.actionBusy
                            ? null
                            : () async {
                                final savedId = await controller.save();
                                if (!context.mounted) {
                                  return;
                                }
                                if (savedId != null) {
                                  _snack();
                                }
                              },
                      ),
                      if (controller.selected != null)
                        AppActionButton(
                          icon: Icons.flash_on_outlined,
                          label: 'Activate',
                          filled: false,
                          onPressed: controller.saving || controller.actionBusy
                              ? null
                              : () async {
                                  await controller.activate();
                                  if (!context.mounted) {
                                    return;
                                  }
                                  _snack();
                                },
                        ),
                      if (controller.selected != null)
                        AppActionButton(
                          icon: Icons.menu_book_outlined,
                          label: 'Books',
                          filled: false,
                          onPressed: controller.saving || controller.actionBusy
                              ? null
                              : () => _openBooks(controller),
                        ),
                      if (controller.selected != null)
                        AppActionButton(
                          icon: Icons.delete_outline,
                          label: 'Delete',
                          filled: false,
                          onPressed: controller.saving || controller.actionBusy
                              ? null
                              : () async {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete asset'),
                                      content: const Text(
                                        'Requires all asset books to be removed first. Continue?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (ok != true || !context.mounted) {
                                    return;
                                  }
                                  final deleted = await controller
                                      .deleteCurrent();
                                  if (!context.mounted) {
                                    return;
                                  }
                                  if (deleted) {
                                    _snack();
                                  }
                                },
                        ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _AssetBooksDialog extends StatefulWidget {
  const _AssetBooksDialog({required this.assetId});

  final int assetId;

  @override
  State<_AssetBooksDialog> createState() => _AssetBooksDialogState();
}

class _AssetBooksDialogState extends State<_AssetBooksDialog> {
  final AssetsService _assets = AssetsService();
  bool _loading = true;
  bool _busy = false;
  String? _error;
  List<AssetBookModel> _books = const <AssetBookModel>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _assets.assetBooks(
        widget.assetId,
        filters: const {'per_page': 100},
      );
      setState(() {
        _books = response.data ?? const <AssetBookModel>[];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _deleteBook(int bookId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete asset book'),
        content: const Text('Delete this book for the asset?'),
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
    setState(() => _busy = true);
    try {
      final response = await _assets.deleteAssetBook(widget.assetId, bookId);
      if (!mounted) {
        return;
      }
      if (response.success != true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
        return;
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Books - asset #${widget.assetId}'),
      content: SizedBox(
        width: 480,
        height: 360,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Text(_error!)
            : _busy
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _books.length,
                itemBuilder: (context, index) {
                  final book = _books[index].toJson();
                  final id = intValue(book, 'id');
                  final type = stringValue(book, 'book_type');
                  final nbv = book['net_book_value']?.toString() ?? '';
                  return ListTile(
                    title: Text(type.isEmpty ? 'Book' : type),
                    subtitle: Text('NBV: $nbv'),
                    trailing: id == null
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _deleteBook(id),
                          ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(onPressed: _load, child: const Text('Refresh')),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
