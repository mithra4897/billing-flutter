import '../../screen.dart';
import '../purchase/purchase_support.dart';
import 'crm_sales_pipeline_bar.dart';

class CrmOpportunitiesPage extends StatefulWidget {
  const CrmOpportunitiesPage({
    super.key,
    this.embedded = false,
    this.initialSelectId,
  });

  final bool embedded;
  final int? initialSelectId;

  @override
  State<CrmOpportunitiesPage> createState() => _CrmOpportunitiesPageState();
}

class _CrmOpportunitiesPageState extends State<CrmOpportunitiesPage>
    with SingleTickerProviderStateMixin {
  static const List<AppDropdownItem<String>> _statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'open', label: 'Open'),
        AppDropdownItem(value: 'won', label: 'Won'),
        AppDropdownItem(value: 'lost', label: 'Lost'),
      ];

  final CrmService _crmService = CrmService();
  final InventoryService _inventoryService = InventoryService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _expectedValueController =
      TextEditingController();
  final TextEditingController _probabilityController =
      TextEditingController();
  final TextEditingController _expectedCloseDateController =
      TextEditingController();

  late final TabController _tabController;
  int _activeTabIndex = 0;
  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  List<CrmOpportunityModel> _items = const <CrmOpportunityModel>[];
  List<CrmOpportunityModel> _filteredItems = const <CrmOpportunityModel>[];
  List<CrmEnquiryModel> _enquiries = const <CrmEnquiryModel>[];
  List<CrmStageModel> _stages = const <CrmStageModel>[];
  List<ItemModel> _itemsLookup = const <ItemModel>[];
  CrmOpportunityModel? _selectedItem;
  int? _enquiryId;
  int? _stageId;
  String _status = 'open';
  List<_OpportunityProductDraft> _products = <_OpportunityProductDraft>[];
  int? _expandedProductIndex;
  Map<String, dynamic>? _salesChain;

  String _normalizedStageType(CrmStageModel stage) {
    return stringValue(stage.toJson(), 'stage_type').trim().toLowerCase();
  }

  bool _isAllowedOpportunityStage(CrmStageModel stage) {
    final type = _normalizedStageType(stage);
    return type == 'opportunity' ||
        type == 'closed_won' ||
        type == 'closed_lost' ||
        type == 'closed won' ||
        type == 'closed lost';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!mounted || _tabController.indexIsChanging) {
        return;
      }
      _activeTabIndex = _tabController.index;
      setState(() {});
    });
    _searchController.addListener(_applySearch);
    _loadPage(selectId: widget.initialSelectId);
  }

  @override
  void didUpdateWidget(covariant CrmOpportunitiesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSelectId != null &&
        widget.initialSelectId != oldWidget.initialSelectId) {
      _loadPage(selectId: widget.initialSelectId);
    }
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _workspaceController.dispose();
    _searchController.dispose();
    _tabController.dispose();
    _nameController.dispose();
    _expectedValueController.dispose();
    _probabilityController.dispose();
    _expectedCloseDateController.dispose();
    _disposeProducts(_products);
    super.dispose();
  }

  Future<void> _loadPage({int? selectId}) async {
    setState(() {
      _initialLoading = _items.isEmpty;
      _pageError = null;
    });

    try {
      final responses = await Future.wait<dynamic>([
        _crmService.opportunities(
          filters: const {'per_page': 200, 'sort_by': 'opportunity_name'},
        ),
        _crmService.enquiries(
          filters: const {'per_page': 300, 'sort_by': 'enquiry_no'},
        ),
        _crmService.stages(filters: const {'per_page': 200, 'sort_by': 'sequence_no'}),
        _inventoryService.items(
          filters: const {'per_page': 300, 'sort_by': 'item_name'},
        ),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _items =
            (responses[0] as PaginatedResponse<CrmOpportunityModel>).data ??
            const <CrmOpportunityModel>[];
        _enquiries =
            (responses[1] as PaginatedResponse<CrmEnquiryModel>).data ??
            const <CrmEnquiryModel>[];
        _stages =
            () {
              final allStages =
                  ((responses[2] as PaginatedResponse<CrmStageModel>).data ??
                          const <CrmStageModel>[])
                      .where(
                        (item) =>
                            boolValue(item.toJson(), 'is_active', fallback: true),
                      )
                      .toList(growable: false);
              final filtered = allStages
                  .where(_isAllowedOpportunityStage)
                  .toList(growable: false);
              return filtered.isNotEmpty ? filtered : allStages;
            }();
        _itemsLookup =
            ((responses[3] as PaginatedResponse<ItemModel>).data ??
                    const <ItemModel>[])
                .where((item) => item.isActive)
                .toList();
        _initialLoading = false;
      });
      _applySearch();

      final selected = selectId != null
          ? _items.cast<CrmOpportunityModel?>().firstWhere(
              (item) => intValue(item?.toJson() ?? const {}, 'id') == selectId,
              orElse: () => null,
            )
          : (_selectedItem == null
                ? (_items.isNotEmpty ? _items.first : null)
                : _items.cast<CrmOpportunityModel?>().firstWhere(
                    (item) =>
                        intValue(item?.toJson() ?? const {}, 'id') ==
                        intValue(_selectedItem!.toJson(), 'id'),
                    orElse: () => _items.isNotEmpty ? _items.first : null,
                  ));

      if (selected != null) {
        await _selectItem(selected);
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
          stringValue(data, 'opportunity_name'),
          stringValue(data, 'status'),
          stringValue(data, 'expected_value'),
        ];
      });
    });
  }

  Future<void> _selectItem(CrmOpportunityModel item) async {
    final id = intValue(item.toJson(), 'id');
    if (id == null) {
      return;
    }
    final response = await _crmService.opportunity(id);
    final full = response.data ?? item;
    final data = full.toJson();
    final products = (data['products'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(_OpportunityProductDraft.fromJson)
        .toList(growable: true);

    _disposeProducts(_products);
    setState(() {
      _selectedItem = full;
      _enquiryId = intValue(data, 'enquiry_id');
      _stageId = intValue(data, 'stage_id');
      _status = stringValue(data, 'status', 'open');
      _nameController.text = stringValue(data, 'opportunity_name');
      _expectedValueController.text = stringValue(data, 'expected_value');
      _probabilityController.text = stringValue(data, 'probability_percent');
      _expectedCloseDateController.text = displayDate(
        nullableStringValue(data, 'expected_close_date'),
      );
      _products = products;
      _expandedProductIndex = null;
      _formError = null;
    });
    await _refreshSalesChainForOpportunity(id);
  }

  int? _selectedOpportunityId() =>
      intValue(_selectedItem?.toJson() ?? const {}, 'id');

  Future<void> _refreshSalesChainForOpportunity(int opportunityId) async {
    try {
      final response =
          await _crmService.salesChain(opportunityId: opportunityId);
      if (!mounted) {
        return;
      }
      setState(() => _salesChain = response.data);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _salesChain = null);
    }
  }

  void _resetForm() {
    _disposeProducts(_products);
    setState(() {
      _selectedItem = null;
      _enquiryId = null;
      _stageId = null;
      _status = 'open';
      _nameController.clear();
      _expectedValueController.clear();
      _probabilityController.clear();
      _expectedCloseDateController.clear();
      _products = <_OpportunityProductDraft>[];
      _expandedProductIndex = null;
      _formError = null;
      _tabController.index = 0;
      _activeTabIndex = 0;
      _salesChain = null;
    });
  }

  void _disposeProducts(List<_OpportunityProductDraft> products) {
    for (final product in products) {
      product.dispose();
    }
  }

  void _addProduct() {
    setState(() {
      _products = List<_OpportunityProductDraft>.from(_products)
        ..add(_OpportunityProductDraft());
      _expandedProductIndex = _products.length - 1;
    });
  }

  void _removeProduct(int index) {
    setState(() {
      final products = List<_OpportunityProductDraft>.from(_products);
      products.removeAt(index).dispose();
      _products = products;
      if (_expandedProductIndex == index) {
        _expandedProductIndex = null;
      } else if ((_expandedProductIndex ?? -1) > index) {
        _expandedProductIndex = _expandedProductIndex! - 1;
      }
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

    final payload = CrmOpportunityModel({
      'enquiry_id': _enquiryId,
      'opportunity_name': _nameController.text.trim(),
      'expected_value':
          double.tryParse(_expectedValueController.text.trim()) ?? 0,
      'stage_id': _stageId,
      'probability_percent':
          double.tryParse(_probabilityController.text.trim()) ?? 0,
      'expected_close_date': nullIfEmpty(_expectedCloseDateController.text),
      'status': _status,
      'products': _products
          .map((item) => item.toJson())
          .toList(growable: false),
    });

    try {
      final response = _selectedItem == null
          ? await _crmService.createOpportunity(payload)
          : await _crmService.updateOpportunity(
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
      final response = await _crmService.deleteOpportunity(id);
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

  Future<void> _win() async {
    final id = intValue(_selectedItem?.toJson() ?? const {}, 'id');
    if (id == null) {
      return;
    }
    try {
      final response = await _crmService.winOpportunity(
        id,
        CrmOpportunityModel(const <String, dynamic>{}),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadPage(selectId: id);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _formError = error.toString());
    }
  }

  Future<void> _lose() async {
    final id = intValue(_selectedItem?.toJson() ?? const {}, 'id');
    if (id == null) {
      return;
    }
    try {
      final response = await _crmService.loseOpportunity(
        id,
        CrmOpportunityModel(const <String, dynamic>{}),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadPage(selectId: id);
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
        label: 'New Opportunity',
      ),
    ];

    final content = _buildContent();
    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }
    return AppStandaloneShell(
      title: 'CRM Opportunities',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading CRM opportunities...');
    }
    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load CRM opportunities',
        message: _pageError!,
        onRetry: _loadPage,
      );
    }

    return SettingsWorkspace(
      title: 'CRM Opportunities',
      scrollController: _pageScrollController,
      controller: _workspaceController,
      editorTitle: _selectedItem?.toString() ?? 'New Opportunity',
      list: SettingsListCard<CrmOpportunityModel>(
        searchController: _searchController,
        searchHint: 'Search opportunities',
        items: _filteredItems,
        selectedItem: _selectedItem,
        emptyMessage: 'No CRM opportunities found.',
        itemBuilder: (item, selected) {
          final data = item.toJson();
          return SettingsListTile(
            title: item.toString(),
            subtitle: [
              stringValue(data, 'status'),
              stringValue(data, 'expected_value'),
            ].where((value) => value.isNotEmpty).join(' • '),
            selected: selected,
            onTap: () => _selectItem(item),
            trailing: SettingsStatusPill(
              label: stringValue(data, 'status', 'open'),
              active: stringValue(data, 'status', 'open') != 'lost',
            ),
          );
        },
      ),
      editor: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Primary'),
                  Tab(text: 'Products'),
                ],
              ),
              const SizedBox(height: AppUiConstants.spacingMd),
              IndexedStack(
                index: _activeTabIndex,
                children: [
                  _buildPrimaryTab(),
                  _selectedItem?.toJson()['id'] == null
                      ? _buildDependentTabPlaceholder(
                          title: 'Products',
                          message:
                              'Save this opportunity first to manage item-wise products, quantities, and prices.',
                        )
                      : _buildProductsTab(),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPrimaryTab() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_formError != null) ...[
            AppErrorStateView.inline(message: _formError!),
            const SizedBox(height: AppUiConstants.spacingSm),
          ],
          if (_selectedOpportunityId() != null) ...[
            CrmSalesPipelineBar(data: _salesChain),
            AppActionButton(
              icon: Icons.request_quote_outlined,
              label: 'New quotation (this deal)',
              filled: false,
              onPressed: () => openModuleShellRoute(
                context,
                '/sales/quotations/new?crm_opportunity_id=${_selectedOpportunityId()}',
              ),
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
          ],
          SettingsFormWrap(
            children: [
              AppDropdownField<int>.fromMapped(
                labelText: 'Enquiry',
                mappedItems: _enquiries
                    .where((item) => intValue(item.toJson(), 'id') != null)
                    .map(
                      (item) => AppDropdownItem(
                        value: intValue(item.toJson(), 'id')!,
                        label: item.toString(),
                      ),
                    )
                    .toList(growable: false),
                initialValue: _enquiryId,
                onChanged: (value) => setState(() => _enquiryId = value),
              ),
              AppFormTextField(
                controller: _nameController,
                labelText: 'Opportunity Name',
                validator: Validators.required('Opportunity Name'),
              ),
              AppFormTextField(
                controller: _expectedValueController,
                labelText: 'Expected Value',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              AppDropdownField<int>.fromMapped(
                labelText: 'Stage',
                mappedItems: _stages
                    .where((item) => intValue(item.toJson(), 'id') != null)
                    .map(
                      (item) => AppDropdownItem(
                        value: intValue(item.toJson(), 'id')!,
                        label: item.toString(),
                      ),
                    )
                    .toList(growable: false),
                initialValue: _stageId,
                onChanged: (value) => setState(() => _stageId = value),
              ),
              AppFormTextField(
                controller: _probabilityController,
                labelText: 'Probability %',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              AppFormTextField(
                controller: _expectedCloseDateController,
                labelText: 'Expected Close Date',
                keyboardType: TextInputType.datetime,
                inputFormatters: const [DateInputFormatter()],
              ),
              AppDropdownField<String>.fromMapped(
                labelText: 'Status',
                mappedItems: _statusItems,
                initialValue: _status,
                onChanged: (value) =>
                    setState(() => _status = value ?? _status),
              ),
            ],
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          Wrap(
            spacing: AppUiConstants.spacingSm,
            runSpacing: AppUiConstants.spacingSm,
            children: [
              AppActionButton(
                icon: Icons.save_outlined,
                label: _selectedItem == null
                    ? 'Save Opportunity'
                    : 'Update Opportunity',
                onPressed: _save,
                busy: _saving,
              ),
              if (_selectedItem != null) ...[
                AppActionButton(
                  icon: Icons.emoji_events_outlined,
                  label: 'Win',
                  filled: false,
                  onPressed: _win,
                ),
                AppActionButton(
                  icon: Icons.cancel_outlined,
                  label: 'Lose',
                  filled: false,
                  onPressed: _lose,
                ),
                AppActionButton(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  filled: false,
                  onPressed: _delete,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Products',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            AppActionButton(
              icon: Icons.add_outlined,
              label: 'Add Product',
              filled: false,
              onPressed: _addProduct,
            ),
          ],
        ),
        const SizedBox(height: AppUiConstants.spacingSm),
        if (_products.isEmpty)
          const SettingsEmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'No Products',
            message: 'Add item-wise deal products, quantity, and estimated price.',
            minHeight: 180,
          )
        else
          ...List<Widget>.generate(_products.length, (index) {
            final product = _products[index];
            final expanded = _expandedProductIndex == index;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
              child: SettingsExpandableTile(
                title: product.itemLabel(_itemsLookup),
                subtitle: [
                  product.qtySummary,
                  product.priceSummary,
                ].where((value) => value.isNotEmpty).join(' • '),
                expanded: expanded,
                highlighted: expanded,
                leadingIcon: Icons.inventory_2_outlined,
                trailing: IconButton(
                  onPressed: () => _removeProduct(index),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline),
                ),
                onToggle: () {
                  setState(() {
                    _expandedProductIndex = expanded ? null : index;
                  });
                },
                child: PurchaseCompactFieldGrid(
                  children: [
                    AppSearchPickerField<int>(
                      labelText: 'Item',
                      selectedLabel: _itemsLookup
                          .cast<ItemModel?>()
                          .firstWhere(
                            (item) => item?.id == product.itemId,
                            orElse: () => null,
                          )
                          ?.toString(),
                      options: _itemsLookup
                          .where((item) => item.id != null)
                          .map(
                            (item) => AppSearchPickerOption<int>(
                              value: item.id!,
                              label: item.toString(),
                              subtitle: item.itemCode,
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) =>
                          setState(() => product.itemId = value),
                    ),
                    AppFormTextField(
                      controller: product.qtyController,
                      labelText: 'Quantity',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    AppFormTextField(
                      controller: product.estimatedPriceController,
                      labelText: 'Estimated Price',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: AppUiConstants.spacingMd),
        Wrap(
          spacing: AppUiConstants.spacingSm,
          runSpacing: AppUiConstants.spacingSm,
          children: [
            AppActionButton(
              icon: Icons.save_outlined,
              label: _selectedItem == null
                  ? 'Save Opportunity'
                  : 'Update Opportunity',
              onPressed: _save,
              busy: _saving,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDependentTabPlaceholder({
    required String title,
    required String message,
  }) {
    return SettingsEmptyState(
      icon: Icons.link_outlined,
      title: title,
      message: message,
      minHeight: 240,
    );
  }
}

class _OpportunityProductDraft {
  _OpportunityProductDraft({this.itemId, String? qty, String? estimatedPrice})
    : qtyController = TextEditingController(text: qty ?? ''),
      estimatedPriceController = TextEditingController(
        text: estimatedPrice ?? '',
      );

  factory _OpportunityProductDraft.fromJson(Map<String, dynamic> json) {
    return _OpportunityProductDraft(
      itemId: intValue(json, 'item_id'),
      qty: stringValue(json, 'qty'),
      estimatedPrice: stringValue(json, 'estimated_price'),
    );
  }

  int? itemId;
  final TextEditingController qtyController;
  final TextEditingController estimatedPriceController;

  String itemLabel(List<ItemModel> items) {
    final item = items.cast<ItemModel?>().firstWhere(
      (entry) => entry?.id == itemId,
      orElse: () => null,
    );
    return item?.toString() ?? 'Opportunity Product';
  }

  String get qtySummary {
    final qty = qtyController.text.trim();
    return qty.isNotEmpty ? 'Qty $qty' : '';
  }

  String get priceSummary {
    final price = estimatedPriceController.text.trim();
    return price.isNotEmpty ? 'Price $price' : '';
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'qty': double.tryParse(qtyController.text.trim()) ?? 0,
      'estimated_price':
          double.tryParse(estimatedPriceController.text.trim()) ?? 0,
    };
  }

  void dispose() {
    qtyController.dispose();
    estimatedPriceController.dispose();
  }
}
