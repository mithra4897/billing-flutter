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
  final TextEditingController _probabilityController = TextEditingController();
  final TextEditingController _expectedCloseDateController =
      TextEditingController();
  final TextEditingController _filterCloseFromController =
      TextEditingController();
  final TextEditingController _filterCloseToController =
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
  int? _filterEnquiryId;
  int? _filterStageId;
  String? _filterStatus;
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
    _filterCloseFromController.dispose();
    _filterCloseToController.dispose();
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
        _crmService.stages(
          filters: const {'per_page': 200, 'sort_by': 'sequence_no'},
        ),
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
        _stages = () {
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
      _filteredItems =
          filterMasterList(_items, _searchController.text, (item) {
                final data = item.toJson();
                return [
                  stringValue(data, 'opportunity_name'),
                  stringValue(data, 'status'),
                  stringValue(data, 'expected_value'),
                ];
              })
              .where((item) {
                final data = item.toJson();
                final closeDate = displayDate(
                  nullableStringValue(data, 'expected_close_date'),
                );
                final filterFrom = _filterCloseFromController.text.trim();
                final filterTo = _filterCloseToController.text.trim();
                if (_filterEnquiryId != null &&
                    intValue(data, 'enquiry_id') != _filterEnquiryId) {
                  return false;
                }
                if (_filterStageId != null &&
                    intValue(data, 'stage_id') != _filterStageId) {
                  return false;
                }
                if ((_filterStatus ?? '').isNotEmpty &&
                    stringValue(data, 'status') != _filterStatus) {
                  return false;
                }
                if (filterFrom.isNotEmpty &&
                    (closeDate.isEmpty ||
                        closeDate.compareTo(filterFrom) < 0)) {
                  return false;
                }
                if (filterTo.isNotEmpty &&
                    (closeDate.isEmpty || closeDate.compareTo(filterTo) > 0)) {
                  return false;
                }
                return true;
              })
              .toList(growable: false);
    });
  }

  Future<void> _openFilterPanel() async {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 600 ? 12.0 : 24.0;
    final dialogPadding = screenWidth < 600 ? 16.0 : AppUiConstants.cardPadding;

    final applied = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final appTheme = Theme.of(
          dialogContext,
        ).extension<AppThemeExtension>()!;

        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 20,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                dialogPadding,
                dialogPadding,
                dialogPadding,
                MediaQuery.of(dialogContext).viewInsets.bottom + dialogPadding,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Filter CRM Opportunities',
                          style: Theme.of(dialogContext).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        tooltip: 'Close',
                        icon: const Icon(Icons.close),
                        color: appTheme.mutedText,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _filterBox(
                        child: AppDropdownField<int>.fromMapped(
                          labelText: 'Stage',
                          initialValue: _filterStageId,
                          mappedItems: _stages
                              .where(
                                (item) => intValue(item.toJson(), 'id') != null,
                              )
                              .map(
                                (item) => AppDropdownItem(
                                  value: intValue(item.toJson(), 'id')!,
                                  label: item.toString(),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) =>
                              setState(() => _filterStageId = value),
                        ),
                      ),
                      _filterBox(
                        child: AppDropdownField<String>.fromMapped(
                          labelText: 'Status',
                          initialValue: _filterStatus,
                          mappedItems: _statusItems,
                          onChanged: (value) =>
                              setState(() => _filterStatus = value),
                        ),
                      ),
                      _filterBox(
                        child: TextField(
                          controller: _filterCloseFromController,
                          decoration: const InputDecoration(
                            labelText: 'Close From',
                            hintText: 'YYYY-MM-DD',
                          ),
                        ),
                      ),
                      _filterBox(
                        child: TextField(
                          controller: _filterCloseToController,
                          decoration: const InputDecoration(
                            labelText: 'Close To',
                            hintText: 'YYYY-MM-DD',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        icon: const Icon(Icons.search),
                        label: const Text('Apply Filters'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _filterStageId = null;
                            _filterStatus = null;
                            _filterCloseFromController.clear();
                            _filterCloseToController.clear();
                          });
                          Navigator.of(dialogContext).pop(true);
                        },
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (applied == true) {
      _applySearch();
    }
  }

  Widget _buildAppliedFilters(BuildContext context) {
    final chips = <String>[
      if (_searchController.text.trim().isNotEmpty)
        'Search: ${_searchController.text.trim()}',
      if (_filterEnquiryId != null)
        'Enquiry: ${_enquiries.cast<CrmEnquiryModel?>().firstWhere((item) => intValue(item?.toJson() ?? const {}, "id") == _filterEnquiryId, orElse: () => null)?.toString() ?? _filterEnquiryId}',
      if (_filterStageId != null)
        'Stage: ${_stages.cast<CrmStageModel?>().firstWhere((item) => intValue(item?.toJson() ?? const {}, "id") == _filterStageId, orElse: () => null)?.toString() ?? _filterStageId}',
      if ((_filterStatus ?? '').isNotEmpty) 'Status: $_filterStatus',
      if (_filterCloseFromController.text.trim().isNotEmpty)
        'Close From: ${_filterCloseFromController.text.trim()}',
      if (_filterCloseToController.text.trim().isNotEmpty)
        'Close To: ${_filterCloseToController.text.trim()}',
    ];

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: appTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
        boxShadow: [
          BoxShadow(
            color: appTheme.cardShadow,
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppUiConstants.cardPadding),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: chips
              .map((chip) => Chip(label: Text(chip)))
              .toList(growable: false),
        ),
      ),
    );
  }

  Widget _filterBox({required Widget child}) {
    return SizedBox(width: 240, child: child);
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
      final response = await _crmService.salesChain(
        opportunityId: opportunityId,
      );
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
      await _loadPage(
        selectId: intValue(response.data?.toJson() ?? const {}, 'id'),
      );
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
        onPressed: _openFilterPanel,
        icon: Icons.filter_alt_outlined,
        label: 'Filter',
        filled: false,
      ),
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
      list: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAppliedFilters(context),
          if (_searchController.text.trim().isNotEmpty ||
              _filterEnquiryId != null ||
              _filterStageId != null ||
              (_filterStatus ?? '').isNotEmpty ||
              _filterCloseFromController.text.trim().isNotEmpty ||
              _filterCloseToController.text.trim().isNotEmpty)
            const SizedBox(height: AppUiConstants.spacingMd),
          SettingsListCard<CrmOpportunityModel>(
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
        ],
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
            CrmSalesPipelineBar(data: _salesChain, hideOpportunityChip: true),
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
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
            message:
                'Add item-wise deal products, quantity, and estimated price.',
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
