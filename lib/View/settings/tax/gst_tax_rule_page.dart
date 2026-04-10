import '../../../screen.dart';

class GstTaxRuleManagementPage extends StatefulWidget {
  const GstTaxRuleManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<GstTaxRuleManagementPage> createState() =>
      _GstTaxRuleManagementPageState();
}

class _GstTaxRuleManagementPageState extends State<GstTaxRuleManagementPage> {
  static const List<DropdownMenuItem<String>> _transactionTypes =
      <DropdownMenuItem<String>>[
        DropdownMenuItem(value: 'sales', child: Text('Sales')),
        DropdownMenuItem(value: 'purchase', child: Text('Purchase')),
        DropdownMenuItem(value: 'sales_return', child: Text('Sales Return')),
        DropdownMenuItem(
          value: 'purchase_return',
          child: Text('Purchase Return'),
        ),
        DropdownMenuItem(value: 'service_sales', child: Text('Service Sales')),
        DropdownMenuItem(
          value: 'service_purchase',
          child: Text('Service Purchase'),
        ),
      ];
  static const List<DropdownMenuItem<String>> _itemTypes =
      <DropdownMenuItem<String>>[
        DropdownMenuItem(value: 'all', child: Text('All')),
        DropdownMenuItem(value: 'stock', child: Text('Stock')),
        DropdownMenuItem(value: 'service', child: Text('Service')),
        DropdownMenuItem(value: 'manufactured', child: Text('Manufactured')),
        DropdownMenuItem(value: 'raw_material', child: Text('Raw Material')),
        DropdownMenuItem(value: 'semi_finished', child: Text('Semi Finished')),
        DropdownMenuItem(
          value: 'finished_goods',
          child: Text('Finished Goods'),
        ),
        DropdownMenuItem(value: 'consumable', child: Text('Consumable')),
        DropdownMenuItem(value: 'asset', child: Text('Asset')),
        DropdownMenuItem(value: 'non_stock', child: Text('Non Stock')),
      ];
  static const List<DropdownMenuItem<String>> _placeResults =
      <DropdownMenuItem<String>>[
        DropdownMenuItem(value: 'all', child: Text('All')),
        DropdownMenuItem(value: 'intra_state', child: Text('Intra State')),
        DropdownMenuItem(value: 'inter_state', child: Text('Inter State')),
        DropdownMenuItem(value: 'export', child: Text('Export')),
        DropdownMenuItem(value: 'import', child: Text('Import')),
        DropdownMenuItem(value: 'sez', child: Text('SEZ')),
        DropdownMenuItem(
          value: 'reverse_charge',
          child: Text('Reverse Charge'),
        ),
      ];
  static const List<DropdownMenuItem<String>> _taxApplications =
      <DropdownMenuItem<String>>[
        DropdownMenuItem(value: 'cgst_sgst', child: Text('CGST + SGST')),
        DropdownMenuItem(value: 'igst', child: Text('IGST')),
        DropdownMenuItem(value: 'cess_only', child: Text('CESS Only')),
        DropdownMenuItem(value: 'exempt', child: Text('Exempt')),
        DropdownMenuItem(value: 'nil_rated', child: Text('Nil Rated')),
        DropdownMenuItem(value: 'non_gst', child: Text('Non GST')),
      ];

  final TaxesService _taxesService = TaxesService();
  final InventoryService _inventoryService = InventoryService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priorityController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  List<GstTaxRuleModel> _items = const <GstTaxRuleModel>[];
  List<GstTaxRuleModel> _filteredItems = const <GstTaxRuleModel>[];
  List<TaxCodeModel> _taxCodes = const <TaxCodeModel>[];
  GstTaxRuleModel? _selectedItem;
  String _transactionType = 'sales';
  String _itemType = 'all';
  int? _taxCodeId;
  String _placeResult = 'all';
  String _taxApplication = 'cgst_sgst';
  bool _reverseCharge = false;
  bool _itcAllowed = true;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applySearch);
    _loadData();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _workspaceController.dispose();
    _searchController.dispose();
    _codeController.dispose();
    _nameController.dispose();
    _priorityController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadData({int? selectId}) async {
    setState(() {
      _initialLoading = _items.isEmpty;
      _pageError = null;
    });

    try {
      final responses = await Future.wait<dynamic>([
        _taxesService.gstTaxRules(filters: const {'per_page': 200}),
        _inventoryService.taxCodes(filters: const {'per_page': 200}),
      ]);

      final items =
          (responses[0] as PaginatedResponse<GstTaxRuleModel>).data ??
          const <GstTaxRuleModel>[];
      final taxCodes =
          (responses[1] as PaginatedResponse<TaxCodeModel>).data ??
          const <TaxCodeModel>[];

      if (!mounted) {
        return;
      }

      setState(() {
        _items = items;
        _taxCodes = taxCodes;
        _filteredItems = filterMasterList(_items, _searchController.text, (
          item,
        ) {
          return [item.ruleCode, item.ruleName, item.transactionType];
        });
        _initialLoading = false;
      });

      final selected = selectId != null
          ? items.cast<GstTaxRuleModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (_selectedItem == null
                ? (items.isNotEmpty ? items.first : null)
                : items.cast<GstTaxRuleModel?>().firstWhere(
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
        return [item.ruleCode, item.ruleName, item.transactionType];
      });
    });
  }

  void _selectItem(GstTaxRuleModel item) {
    _selectedItem = item;
    _codeController.text = item.ruleCode;
    _nameController.text = item.ruleName;
    _priorityController.text = item.priorityOrder?.toString() ?? '1';
    _remarksController.text = item.remarks ?? '';
    _transactionType = item.transactionType.isEmpty
        ? 'sales'
        : item.transactionType;
    _itemType = item.itemType.isEmpty ? 'all' : item.itemType;
    _taxCodeId = item.taxCodeId;
    _placeResult = item.placeOfSupplyResult.isEmpty
        ? 'all'
        : item.placeOfSupplyResult;
    _taxApplication = item.taxApplication.isEmpty
        ? 'cgst_sgst'
        : item.taxApplication;
    _reverseCharge = item.reverseChargeApplicable;
    _itcAllowed = item.inputTaxCreditAllowed;
    _isActive = item.isActive;
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedItem = null;
    _codeController.clear();
    _nameController.clear();
    _priorityController.text = '1';
    _remarksController.clear();
    _transactionType = 'sales';
    _itemType = 'all';
    _taxCodeId = _taxCodes.isNotEmpty ? _taxCodes.first.id : null;
    _placeResult = 'all';
    _taxApplication = 'cgst_sgst';
    _reverseCharge = false;
    _itcAllowed = true;
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

    final model = GstTaxRuleModel(
      id: _selectedItem?.id,
      ruleCode: _codeController.text.trim(),
      ruleName: _nameController.text.trim(),
      transactionType: _transactionType,
      itemType: _itemType,
      taxCodeId: _taxCodeId,
      placeOfSupplyResult: _placeResult,
      taxApplication: _taxApplication,
      reverseChargeApplicable: _reverseCharge,
      inputTaxCreditAllowed: _itcAllowed,
      priorityOrder: int.tryParse(_priorityController.text.trim()) ?? 1,
      isActive: _isActive,
      remarks: nullIfEmpty(_remarksController.text),
    );

    try {
      final response = _selectedItem == null
          ? await _taxesService.createGstTaxRule(model)
          : await _taxesService.updateGstTaxRule(_selectedItem!.id!, model);
      final saved = response.data;
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadData(selectId: saved?.id);
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
      final response = await _taxesService.deleteGstTaxRule(id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadData();
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
        icon: Icons.rule_outlined,
        label: 'New Tax Rule',
      ),
    ];

    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }

    return AppStandaloneShell(
      title: 'GST Tax Rules',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading GST tax rules...');
    }
    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load GST tax rules',
        message: _pageError!,
        onRetry: _loadData,
      );
    }

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'GST Tax Rules',
      editorTitle: _selectedItem?.toString(),
      scrollController: _pageScrollController,
      list: SettingsListCard<GstTaxRuleModel>(
        searchController: _searchController,
        searchHint: 'Search GST tax rules',
        items: _filteredItems,
        selectedItem: _selectedItem,
        emptyMessage: 'No GST tax rules found.',
        itemBuilder: (item, selected) => SettingsListTile(
          title: item.ruleName,
          subtitle: [
            item.ruleCode,
            item.transactionType,
            item.taxApplication,
          ].join(' · '),
          selected: selected,
          onTap: () => _selectItem(item),
        ),
      ),
      editor: Form(
          key: _formKey,
          child: Column(
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
                decoration: const InputDecoration(labelText: 'Rule Code'),
                validator: Validators.compose([
                  Validators.required('Rule Code'),
                  Validators.optionalMaxLength(50, 'Rule Code'),
                ]),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Rule Name'),
                validator: Validators.compose([
                  Validators.required('Rule Name'),
                  Validators.optionalMaxLength(150, 'Rule Name'),
                ]),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _transactionType,
                decoration: const InputDecoration(
                  labelText: 'Transaction Type',
                ),
                items: _transactionTypes,
                onChanged: (value) =>
                    setState(() => _transactionType = value ?? 'sales'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _itemType,
                decoration: const InputDecoration(labelText: 'Item Type'),
                items: _itemTypes,
                onChanged: (value) =>
                    setState(() => _itemType = value ?? 'all'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _taxCodeId,
                decoration: const InputDecoration(labelText: 'Tax Code'),
                items: _taxCodes
                    .map(
                      (taxCode) => DropdownMenuItem<int>(
                        value: taxCode.id,
                        child: Text(taxCode.toString()),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) => setState(() => _taxCodeId = value),
                validator: (value) =>
                    Validators.requiredSelectionField(value, 'Tax Code'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _placeResult,
                decoration: const InputDecoration(
                  labelText: 'Place Of Supply Result',
                ),
                items: _placeResults,
                onChanged: (value) =>
                    setState(() => _placeResult = value ?? 'all'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _taxApplication,
                decoration: const InputDecoration(labelText: 'Tax Application'),
                items: _taxApplications,
                onChanged: (value) =>
                    setState(() => _taxApplication = value ?? 'cgst_sgst'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priorityController,
                decoration: const InputDecoration(labelText: 'Priority Order'),
                keyboardType: TextInputType.number,
                validator: Validators.optionalNonNegativeInteger(
                  'Priority Order',
                ),
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
                title: const Text('Reverse Charge Applicable'),
                value: _reverseCharge,
                onChanged: (value) => setState(() => _reverseCharge = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Input Tax Credit Allowed'),
                value: _itcAllowed,
                onChanged: (value) => setState(() => _itcAllowed = value),
              ),
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
