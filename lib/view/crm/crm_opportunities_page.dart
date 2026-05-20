import '../../controller/crm/crm_opportunities_controller.dart';
import '../../screen.dart';

void _openCrmOpportunityShellRoute(BuildContext context, String route) {
  final navigate = ShellRouteScope.maybeOf(context);
  if (navigate != null) {
    navigate(route);
    return;
  }
  Navigator.of(context).pushNamed(route);
}

class CrmOpportunityRegisterPage extends StatefulWidget {
  const CrmOpportunityRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<CrmOpportunityRegisterPage> createState() =>
      _CrmOpportunityRegisterPageState();
}

class _CrmOpportunityRegisterPageState
    extends State<CrmOpportunityRegisterPage> {
  static const List<AppDropdownItem<String>> _statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: '', label: 'All'),
        AppDropdownItem(value: 'open', label: 'Open'),
        AppDropdownItem(value: 'won', label: 'Won'),
      ];

  final CrmService _service = CrmService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String _status = '';
  List<CrmOpportunityModel> _rows = const <CrmOpportunityModel>[];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _service.opportunities(
        filters: const {'per_page': 200, 'sort_by': 'opportunity_name'},
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _rows = response.data ?? const <CrmOpportunityModel>[];
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  List<CrmOpportunityModel> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    return _rows
        .where((row) {
          final data = row.toJson();
          final customer =
              JsonModel.mapOf(data['customer']) ?? const <String, dynamic>{};
          final stage =
              JsonModel.mapOf(data['stage']) ?? const <String, dynamic>{};
          final lead =
              JsonModel.mapOf(data['lead']) ?? const <String, dynamic>{};
          final statusOk =
              _status.isEmpty || stringValue(data, 'status') == _status;
          final searchOk =
              query.isEmpty ||
              [
                stringValue(data, 'opportunity_name'),
                stringValue(data, 'enquiry_no'),
                stringValue(data, 'status'),
                stringValue(customer, 'display_name'),
                stringValue(customer, 'party_name'),
                stringValue(stage, 'stage_name'),
                stringValue(lead, 'lead_name'),
              ].join(' ').toLowerCase().contains(query);
          return statusOk && searchOk;
        })
        .toList(growable: false);
  }

  String _customerLabel(Map<String, dynamic> data) {
    final customer =
        JsonModel.mapOf(data['customer']) ?? const <String, dynamic>{};
    final displayName = stringValue(customer, 'display_name');
    if (displayName.isNotEmpty) {
      return displayName;
    }
    return stringValue(customer, 'party_name');
  }

  String _stageLabel(Map<String, dynamic> data) {
    return stringValue(
      JsonModel.mapOf(data['stage']) ?? const <String, dynamic>{},
      'stage_name',
    );
  }

  String _leadLabel(Map<String, dynamic> data) {
    return stringValue(
      JsonModel.mapOf(data['lead']) ?? const <String, dynamic>{},
      'lead_name',
    );
  }

  String _ownerLabel(Map<String, dynamic> data) {
    final assigned =
        JsonModel.mapOf(data['assigned_user']) ?? const <String, dynamic>{};
    final displayName = stringValue(assigned, 'display_name');
    if (displayName.isNotEmpty) {
      return displayName;
    }
    return stringValue(assigned, 'username');
  }

  String _statusLabel(String value) {
    switch (value.trim().toLowerCase()) {
      case 'won':
        return 'Won';
      case 'open':
      default:
        return 'Open';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<CrmOpportunityModel>(
      title: 'CRM Opportunities',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage:
          'No CRM opportunities yet. Create a new opportunity to get started.',
      actions: [
        AdaptiveShellActionButton(
          onPressed: () =>
              _openCrmOpportunityShellRoute(context, '/crm/opportunities/new'),
          icon: Icons.add_outlined,
          label: 'New opportunity',
        ),
      ],
      filters: _CrmOpportunityRegisterFilters(
        searchController: _searchController,
        status: _status,
        statusItems: _statusItems,
        onStatusChanged: (value) => setState(() => _status = value ?? ''),
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<CrmOpportunityModel>(
          label: 'Opportunity No',
          flex: 2,
          valueBuilder: (row) => stringValue(row.toJson(), 'enquiry_no'),
        ),
        PurchaseRegisterColumn<CrmOpportunityModel>(
          label: 'Date',
          valueBuilder: (row) =>
              displayDate(nullableStringValue(row.toJson(), 'enquiry_date')),
        ),
        PurchaseRegisterColumn<CrmOpportunityModel>(
          label: 'Customer',
          flex: 3,
          valueBuilder: (row) => _customerLabel(row.toJson()),
        ),
        PurchaseRegisterColumn<CrmOpportunityModel>(
          label: 'Stage',
          flex: 2,
          valueBuilder: (row) => _stageLabel(row.toJson()),
        ),
        PurchaseRegisterColumn<CrmOpportunityModel>(
          label: 'Expected Value',
          valueBuilder: (row) => stringValue(row.toJson(), 'expected_value'),
        ),
        PurchaseRegisterColumn<CrmOpportunityModel>(
          label: 'Lead By',
          flex: 2,
          valueBuilder: (row) => _leadLabel(row.toJson()),
        ),
        PurchaseRegisterColumn<CrmOpportunityModel>(
          label: 'Owner',
          flex: 2,
          valueBuilder: (row) => _ownerLabel(row.toJson()),
        ),
        PurchaseRegisterColumn<CrmOpportunityModel>(
          label: 'Status',
          valueBuilder: (row) =>
              _statusLabel(stringValue(row.toJson(), 'status')),
        ),
      ],
      onRowTap: (row) => _openCrmOpportunityShellRoute(
        context,
        '/crm/opportunities/${intValue(row.toJson(), 'id')}',
      ),
    );
  }
}

class _CrmOpportunityRegisterFilters extends StatelessWidget {
  const _CrmOpportunityRegisterFilters({
    required this.searchController,
    required this.status,
    required this.statusItems,
    required this.onStatusChanged,
  });

  final TextEditingController searchController;
  final String status;
  final List<AppDropdownItem<String>> statusItems;
  final ValueChanged<String?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return SettingsFormWrap(
      children: [
        AppFormTextField(
          labelText: 'Search',
          controller: searchController,
          hintText:
              'Search opportunity, number, customer, stage, owner, or lead',
        ),
        AppDropdownField<String>.fromMapped(
          labelText: 'Status',
          mappedItems: statusItems,
          initialValue: status,
          onChanged: onStatusChanged,
        ),
      ],
    );
  }
}

class CrmOpportunitiesPage extends StatefulWidget {
  const CrmOpportunitiesPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.startInNewMode = false,
    this.initialSelectId,
  });

  final bool embedded;
  final bool editorOnly;
  final bool startInNewMode;
  final int? initialSelectId;

  @override
  State<CrmOpportunitiesPage> createState() => _CrmOpportunitiesPageState();
}

class _CrmOpportunitiesPageState extends State<CrmOpportunitiesPage>
    with SingleTickerProviderStateMixin {
  late final String _controllerTag;
  late final CrmOpportunitiesController _controller;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'CrmOpportunitiesController',
      scope: <String, Object?>{
        'widget': widget.runtimeType,
        'key': widget.key,
        'state': identityHashCode(this),
      },
    );
    _controller = Get.put(
      CrmOpportunitiesController(
        startInNewMode: widget.startInNewMode,
        initialSelectId: widget.initialSelectId,
      ),
      tag: _controllerTag,
    );
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _controller.setActiveTabIndex(_tabController.index);
      }
    });
  }

  @override
  void didUpdateWidget(covariant CrmOpportunitiesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSelectId != widget.initialSelectId ||
        oldWidget.startInNewMode != widget.startInNewMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _syncRouteState();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    if (Get.isRegistered<CrmOpportunitiesController>(tag: _controllerTag)) {
      Get.delete<CrmOpportunitiesController>(tag: _controllerTag);
    }
    super.dispose();
  }

  void _syncRouteState() {
    if (widget.startInNewMode) {
      _controller.resetForm();
      return;
    }
    if (widget.initialSelectId != null) {
      _controller.loadPage(selectId: widget.initialSelectId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CrmOpportunitiesController>(
      tag: _controllerTag,
      builder: (controller) {
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () => _openFilterPanel(context, controller),
            icon: Icons.filter_alt_outlined,
            label: 'Filter',
            filled: false,
          ),
          AdaptiveShellActionButton(
            onPressed: () => _openCrmOpportunityShellRoute(
              context,
              '/crm/opportunities/new',
            ),
            icon: Icons.add_outlined,
            label: 'New Opportunity',
          ),
        ];

        final content = _buildContent(context, controller);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'CRM Opportunities',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Future<void> _openFilterPanel(
    BuildContext context,
    CrmOpportunitiesController controller,
  ) async {
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
                          initialValue:
                              controller.filterStageId ??
                              CrmOpportunitiesController.allFilterIntValue,
                          mappedItems: <AppDropdownItem<int>>[
                            const AppDropdownItem<int>(
                              value:
                                  CrmOpportunitiesController.allFilterIntValue,
                              label: 'All',
                            ),
                            ...controller.stages
                                .where(
                                  (item) =>
                                      intValue(item.toJson(), 'id') != null,
                                )
                                .map(
                                  (item) => AppDropdownItem<int>(
                                    value: intValue(item.toJson(), 'id')!,
                                    label: item.toString(),
                                  ),
                                ),
                          ],
                          onChanged: controller.setFilterStageId,
                        ),
                      ),
                      _filterBox(
                        child: AppDropdownField<String>.fromMapped(
                          labelText: 'Status',
                          initialValue:
                              controller.filterStatus ??
                              CrmOpportunitiesController.allFilterStringValue,
                          mappedItems: <AppDropdownItem<String>>[
                            const AppDropdownItem<String>(
                              value: CrmOpportunitiesController
                                  .allFilterStringValue,
                              label: 'All',
                            ),
                            ...CrmOpportunitiesController.filterStatusItems,
                          ],
                          onChanged: controller.setFilterStatus,
                        ),
                      ),
                      _filterBox(
                        child: TextField(
                          controller: controller.filterCloseFromController,
                          decoration: const InputDecoration(
                            labelText: 'Close From',
                            hintText: 'YYYY-MM-DD',
                          ),
                        ),
                      ),
                      _filterBox(
                        child: TextField(
                          controller: controller.filterCloseToController,
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
                        onPressed: () {
                          controller.markFiltersApplied();
                          Navigator.of(dialogContext).pop(true);
                        },
                        icon: const Icon(Icons.search),
                        label: const Text('Apply Filters'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          controller.clearFilters();
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
      controller.applySearch();
    }
  }

  Future<void> _pickFollowupDate(
    BuildContext context,
    CrmOpportunitiesController controller,
    OpportunityFollowupDraft followup,
  ) async {
    final now = DateTime.now();
    final initial =
        tryParseCalendarDateTime(followup.followupDateController.text) ?? now;
    final selected = await showAppDateTimePickerDialog(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5, 1, 1),
      lastDate: DateTime(now.year + 5, 12, 31),
      dateTitle: 'Select Followup Date',
      timeTitle: 'Select Followup Time',
    );
    if (selected == null) return;
    followup.followupDateController.text = formatCalendarDateTime(selected);
    controller.update();
  }

  Future<void> _pickNextFollowupDate(
    BuildContext context,
    CrmOpportunitiesController controller,
    OpportunityFollowupDraft followup,
  ) async {
    final now = DateTime.now();
    final initial =
        tryParseCalendarDateTime(followup.nextFollowupController.text) ?? now;
    final selected = await showAppDateTimePickerDialog(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5, 1, 1),
      lastDate: DateTime(now.year + 5, 12, 31),
      dateTitle: 'Select Next Followup Date',
      timeTitle: 'Select Next Followup Time',
    );
    if (selected == null) return;
    followup.nextFollowupController.text = formatCalendarDateTime(selected);
    controller.update();
  }

  Widget _buildContent(
    BuildContext context,
    CrmOpportunitiesController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading CRM opportunities...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load CRM opportunities',
        message: controller.pageError!,
        onRetry: controller.loadPage,
      );
    }

    if (_tabController.index != controller.activeTabIndex) {
      _tabController.index = controller.activeTabIndex;
    }

    // Migrated page/form state now lives in CrmOpportunitiesController.
    return SettingsWorkspace(
      title: 'CRM Opportunities',
      scrollController: controller.pageScrollController,
      controller: controller.workspaceController,
      editorOnly: widget.editorOnly,
      editorTitle: controller.selectedItem?.toString() ?? 'New Opportunity',
      list: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAppliedFilters(context, controller),
          if (controller.searchController.text.trim().isNotEmpty ||
              controller.filterStageId != null ||
              (controller.filterStatus ?? '').isNotEmpty ||
              controller.filtersApplied ||
              controller.filterCloseFromController.text.trim().isNotEmpty ||
              controller.filterCloseToController.text.trim().isNotEmpty)
            const SizedBox(height: AppUiConstants.spacingMd),
          _buildOpportunityTable(context, controller),
        ],
      ),
      editor: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            controller: _tabController,
            onTap: controller.setActiveTabIndex,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Primary'),
              Tab(text: 'Followups'),
              Tab(text: 'Products'),
              Tab(text: 'Suggested Products'),
            ],
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          IndexedStack(
            index: controller.activeTabIndex,
            children: [
              _buildPrimaryTab(context, controller),
              controller.selectedItem?.toJson()['id'] == null
                  ? _buildDependentTabPlaceholder(
                      title: 'Followups',
                      message:
                          'Save this opportunity first to manage calls and followups.',
                    )
                  : _buildFollowupsTab(context, controller),
              controller.selectedItem?.toJson()['id'] == null
                  ? _buildDependentTabPlaceholder(
                      title: 'Products',
                      message:
                          'Save this opportunity first to manage opportunity products.',
                    )
                  : _buildLinesTab(context, controller),
              controller.selectedItem?.toJson()['id'] == null
                  ? _buildDependentTabPlaceholder(
                      title: 'Suggested Products',
                      message:
                          'Save this opportunity first to manage suggested products.',
                    )
                  : _buildProductsTab(context, controller),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppliedFilters(
    BuildContext context,
    CrmOpportunitiesController controller,
  ) {
    final chips = <String>[
      if (controller.searchController.text.trim().isNotEmpty)
        'Search: ${controller.searchController.text.trim()}',
      if (controller.filterStageId != null || controller.filtersApplied)
        'Stage: ${controller.filterStageId == null ? 'All' : controller.stages.cast<CrmStageModel?>().firstWhere((item) => intValue(item?.toJson() ?? const {}, "id") == controller.filterStageId, orElse: () => null)?.toString() ?? controller.filterStageId}',
      if ((controller.filterStatus ?? '').isNotEmpty ||
          controller.filtersApplied)
        'Status: ${(controller.filterStatus ?? CrmOpportunitiesController.allFilterStringValue) == CrmOpportunitiesController.allFilterStringValue ? 'All' : controller.filterStatus}',
      if (controller.filterCloseFromController.text.trim().isNotEmpty)
        'Close From: ${controller.filterCloseFromController.text.trim()}',
      if (controller.filterCloseToController.text.trim().isNotEmpty)
        'Close To: ${controller.filterCloseToController.text.trim()}',
    ];
    if (chips.isEmpty) return const SizedBox.shrink();
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
          children: chips.map((chip) => Chip(label: Text(chip))).toList(),
        ),
      ),
    );
  }

  Widget _filterBox({required Widget child}) =>
      SizedBox(width: 240, child: child);

  String _customerLabel(Map<String, dynamic> data) {
    final customer =
        JsonModel.mapOf(data['customer']) ?? const <String, dynamic>{};
    final displayName = stringValue(customer, 'display_name');
    if (displayName.isNotEmpty) {
      return displayName;
    }
    return stringValue(customer, 'party_name');
  }

  String _stageLabel(Map<String, dynamic> data) {
    return stringValue(
      JsonModel.mapOf(data['stage']) ?? const <String, dynamic>{},
      'stage_name',
    );
  }

  String _leadLabel(Map<String, dynamic> data) {
    return stringValue(
      JsonModel.mapOf(data['lead']) ?? const <String, dynamic>{},
      'lead_name',
    );
  }

  String _ownerLabel(Map<String, dynamic> data) {
    final assigned =
        JsonModel.mapOf(data['assigned_user']) ?? const <String, dynamic>{};
    final displayName = stringValue(assigned, 'display_name');
    if (displayName.isNotEmpty) {
      return displayName;
    }
    return stringValue(assigned, 'username');
  }

  Widget _buildOpportunityTable(
    BuildContext context,
    CrmOpportunitiesController controller,
  ) {
    final theme = Theme.of(context);
    final mutedText = theme.extension<AppThemeExtension>()!.mutedText;

    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller.searchController,
            decoration: const InputDecoration(
              hintText:
                  'Search opportunity, number, customer, stage, owner, or lead',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          if (controller.filteredItems.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppUiConstants.spacingXl),
              child: Text('No CRM opportunities found.'),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 1100),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Opportunity')),
                    DataColumn(label: Text('Customer')),
                    DataColumn(label: Text('Opportunity No')),
                    DataColumn(label: Text('Lead')),
                    DataColumn(label: Text('Stage')),
                    DataColumn(label: Text('Expected Value')),
                    DataColumn(label: Text('Probability %')),
                    DataColumn(label: Text('Close Date')),
                    DataColumn(label: Text('Owner')),
                    DataColumn(label: Text('Status')),
                  ],
                  rows: controller.filteredItems
                      .map((item) {
                        final data = item.toJson();
                        final selected = item == controller.selectedItem;
                        final customerLabel = _customerLabel(data);
                        final statusText = stringValue(data, 'status', 'open');
                        final rowColor = selected
                            ? theme.colorScheme.primary.withValues(alpha: 0.08)
                            : null;
                        return DataRow(
                          selected: selected,
                          color: rowColor == null
                              ? null
                              : WidgetStatePropertyAll<Color>(rowColor),
                          cells: [
                            DataCell(
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stringValue(
                                      data,
                                      'opportunity_name',
                                      'Opportunity',
                                    ),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (stringValue(
                                    data,
                                    'products_count',
                                  ).isNotEmpty)
                                    Text(
                                      'Products: ${stringValue(data, 'products_count')}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: mutedText),
                                    ),
                                ],
                              ),
                              onTap: () => controller.selectItem(item),
                            ),
                            DataCell(
                              Text(customerLabel),
                              onTap: () => controller.selectItem(item),
                            ),
                            DataCell(
                              Text(stringValue(data, 'enquiry_no')),
                              onTap: () => controller.selectItem(item),
                            ),
                            DataCell(
                              Text(_leadLabel(data)),
                              onTap: () => controller.selectItem(item),
                            ),
                            DataCell(
                              Text(_stageLabel(data)),
                              onTap: () => controller.selectItem(item),
                            ),
                            DataCell(
                              Text(stringValue(data, 'expected_value')),
                              onTap: () => controller.selectItem(item),
                            ),
                            DataCell(
                              Text(stringValue(data, 'probability_percent')),
                              onTap: () => controller.selectItem(item),
                            ),
                            DataCell(
                              Text(
                                displayDate(
                                  nullableStringValue(
                                    data,
                                    'expected_close_date',
                                  ),
                                ),
                              ),
                              onTap: () => controller.selectItem(item),
                            ),
                            DataCell(
                              Text(_ownerLabel(data)),
                              onTap: () => controller.selectItem(item),
                            ),
                            DataCell(
                              SettingsStatusPill(
                                label: statusText,
                                active: statusText != 'lost',
                              ),
                              onTap: () => controller.selectItem(item),
                            ),
                          ],
                        );
                      })
                      .toList(growable: false),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPrimaryTab(
    BuildContext context,
    CrmOpportunitiesController controller,
  ) {
    final isLocked = controller.isSelectedOpportunityReadOnly;
    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.formError != null) ...[
            AppErrorStateView.inline(message: controller.formError!),
            const SizedBox(height: AppUiConstants.spacingSm),
          ],
          if (controller.selectedOpportunityId() != null) ...[
            CrmSalesPipelineBar(
              data: controller.salesChain,
              title: 'Sales line',
              hideOpportunityChip: true,
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
            if (isLocked) ...[
              Text(
                'This opportunity is read-only because it is won or lost.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppUiConstants.spacingSm),
            ],
          ],
          AbsorbPointer(
            absorbing: isLocked,
            child: SettingsFormWrap(
              children: [
                AppSearchPickerField<int>(
                  labelText: 'Lead',
                  selectedLabel: controller.leads
                      .cast<CrmLeadModel?>()
                      .firstWhere(
                        (item) => item?.id == controller.leadId,
                        orElse: () => null,
                      )
                      ?.toString(),
                  options: controller.leads
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppSearchPickerOption<int>(
                          value: item.id!,
                          label: item.toString(),
                          subtitle: [item.companyName, item.mobile, item.email]
                              .where((value) => (value ?? '').trim().isNotEmpty)
                              .join(' • '),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: controller.setLeadId,
                ),
                AppSearchPickerField<int>(
                  labelText: 'Customer',
                  selectedLabel: controller.customers
                      .cast<PartyModel?>()
                      .firstWhere(
                        (item) => item?.id == controller.customerPartyId,
                        orElse: () => null,
                      )
                      ?.toString(),
                  options: controller.customers
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppSearchPickerOption<int>(
                          value: item.id!,
                          label: item.toString(),
                          subtitle: item.partyCode,
                        ),
                      )
                      .toList(growable: false),
                  onChanged: controller.setCustomerPartyId,
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Owner',
                  mappedItems: controller.users
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem(
                          value: item.id!,
                          label: item.displayName ?? item.username ?? '',
                        ),
                      )
                      .toList(growable: false),
                  initialValue: controller.assignedTo,
                  onChanged: controller.setAssignedTo,
                ),
                AppFormTextField(
                  controller: controller.nameController,
                  labelText: 'Opportunity Name',
                  validator: Validators.required('Opportunity Name'),
                ),
                AppFormTextField(
                  controller: controller.expectedValueController,
                  labelText: 'Expected Value',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Stage',
                  mappedItems: controller.stages
                      .where((item) => intValue(item.toJson(), 'id') != null)
                      .map(
                        (item) => AppDropdownItem(
                          value: intValue(item.toJson(), 'id')!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: controller.stageId,
                  onChanged: controller.setStageId,
                ),
                AppFormTextField(
                  controller: controller.probabilityController,
                  labelText: 'Probability %',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                AppFormTextField(
                  controller: controller.expectedCloseDateController,
                  labelText: 'Expected Close Date',
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                ),
                AppFormTextField(
                  controller: controller.remarksController,
                  labelText: 'Remarks',
                  maxLines: 2,
                ),
                AppFormTextField(
                  labelText: 'Status',
                  initialValue: controller.status.replaceAll('_', ' '),
                  readOnly: true,
                  enabled: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          Wrap(
            spacing: AppUiConstants.spacingSm,
            runSpacing: AppUiConstants.spacingSm,
            children: [
              if (!isLocked)
                AppActionButton(
                  icon: Icons.save_outlined,
                  label: controller.selectedItem == null
                      ? 'Save Opportunity'
                      : 'Update Opportunity',
                  onPressed: controller.save,
                  busy: controller.saving,
                ),
              if (controller.selectedItem != null) ...[
                if (!isLocked)
                  AppActionButton(
                    icon: Icons.emoji_events_outlined,
                    label: 'Won',
                    filled: false,
                    onPressed: controller.win,
                  ),
                if (!isLocked)
                  AppActionButton(
                    icon: Icons.cancel_outlined,
                    label: 'Lost',
                    filled: false,
                    onPressed: controller.lose,
                  ),
                AppActionButton(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  filled: false,
                  onPressed: isLocked ? null : controller.delete,
                ),
              ],
            ],
          ),
          if (controller.selectedOpportunityId() != null) ...[
            const SizedBox(height: AppUiConstants.spacingMd),
            Wrap(
              spacing: AppUiConstants.spacingSm,
              runSpacing: AppUiConstants.spacingSm,
              children: [
                AppActionButton(
                  icon: Icons.request_quote_outlined,
                  label: 'New quotation',
                  filled: false,
                  onPressed: () => openModuleShellRoute(
                    context,
                    '/sales/quotations/new?crm_opportunity_id=${controller.selectedOpportunityId()}',
                  ),
                ),
                AppActionButton(
                  icon: Icons.local_shipping_outlined,
                  label: 'New delivery',
                  filled: false,
                  onPressed: _latestSalesOrderId(controller) == null
                      ? null
                      : () => openModuleShellRoute(
                          context,
                          '/sales/deliveries/new?order_id=${_latestSalesOrderId(controller)}',
                        ),
                ),
                AppActionButton(
                  icon: Icons.receipt_long_outlined,
                  label: 'New invoice',
                  filled: false,
                  onPressed: _invoiceRoute(controller) == null
                      ? null
                      : () => openModuleShellRoute(
                          context,
                          _invoiceRoute(controller)!,
                        ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductsTab(
    BuildContext context,
    CrmOpportunitiesController controller,
  ) {
    final isLocked = controller.isSelectedOpportunityReadOnly;
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
            if (!isLocked) ...[
              _buildCommonSaveButton(controller),
              const SizedBox(width: AppUiConstants.spacingSm),
            ],
            AppActionButton(
              icon: Icons.add_outlined,
              label: 'Add Suggested Product',
              filled: false,
              onPressed: isLocked ? null : controller.addProduct,
            ),
          ],
        ),
        const SizedBox(height: AppUiConstants.spacingSm),
        if (controller.products.isEmpty)
          const SettingsEmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'No Products',
            message:
                'Add item-wise deal products, quantity, and estimated price.',
            minHeight: 180,
          )
        else
          ...List<Widget>.generate(controller.products.length, (index) {
            final product = controller.products[index];
            final expanded = controller.expandedProductIndex == index;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
              child: SettingsExpandableTile(
                title: product.itemLabel(controller.itemsLookup),
                subtitle: [
                  product.qtySummary,
                  product.priceSummary,
                ].where((value) => value.isNotEmpty).join(' • '),
                expanded: expanded,
                highlighted: expanded,
                leadingIcon: Icons.inventory_2_outlined,
                trailing: IconButton(
                  onPressed: isLocked
                      ? null
                      : () => _confirmRemoveChild(
                          context,
                          title: 'Delete Suggested Product?',
                          message:
                              'This suggested product will be removed from the opportunity.',
                          onConfirm: () => controller.removeProduct(index),
                        ),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline),
                ),
                onToggle: () =>
                    controller.setExpandedProductIndex(expanded ? null : index),
                child: AbsorbPointer(
                  absorbing: isLocked,
                  child: PurchaseCompactFieldGrid(
                    children: [
                      AppSearchPickerField<int>(
                        labelText: 'Item',
                        selectedLabel: controller.itemsLookup
                            .cast<ItemModel?>()
                            .firstWhere(
                              (item) => item?.id == product.itemId,
                              orElse: () => null,
                            )
                            ?.toString(),
                        options: controller.itemsLookup
                            .where((item) => item.id != null)
                            .map(
                              (item) => AppSearchPickerOption<int>(
                                value: item.id!,
                                label: item.toString(),
                                subtitle: item.itemCode,
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          product.itemId = value;
                          controller.update();
                        },
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
              ),
            );
          }),
      ],
    );
  }

  Widget _buildLinesTab(
    BuildContext context,
    CrmOpportunitiesController controller,
  ) {
    final isLocked = controller.isSelectedOpportunityReadOnly;
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
            if (!isLocked) ...[
              _buildCommonSaveButton(controller),
              const SizedBox(width: AppUiConstants.spacingSm),
            ],
            AppActionButton(
              icon: Icons.add_outlined,
              label: 'Add Product',
              filled: false,
              onPressed: isLocked ? null : controller.addLine,
            ),
          ],
        ),
        const SizedBox(height: AppUiConstants.spacingSm),
        if (controller.lines.isEmpty)
          const SettingsEmptyState(
            icon: Icons.playlist_add_check_outlined,
            title: 'No Products',
            message: 'Add requested items, descriptions, and quantities.',
            minHeight: 180,
          )
        else
          ...List<Widget>.generate(controller.lines.length, (index) {
            final line = controller.lines[index];
            final expanded = controller.expandedLineIndex == index;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
              child: SettingsExpandableTile(
                title: line.itemLabel(controller.itemsLookup),
                subtitle: line.qtySummary,
                detail: line.descriptionController.text.trim(),
                expanded: expanded,
                highlighted: expanded,
                leadingIcon: Icons.inventory_2_outlined,
                trailing: IconButton(
                  onPressed: isLocked
                      ? null
                      : () => _confirmRemoveChild(
                          context,
                          title: 'Delete Product?',
                          message:
                              'This product row will be removed from the opportunity.',
                          onConfirm: () => controller.removeLine(index),
                        ),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline),
                ),
                onToggle: () =>
                    controller.setExpandedLineIndex(expanded ? null : index),
                child: AbsorbPointer(
                  absorbing: isLocked,
                  child: PurchaseCompactFieldGrid(
                    children: [
                      AppSearchPickerField<int>(
                        labelText: 'Item',
                        selectedLabel: controller.itemsLookup
                            .cast<ItemModel?>()
                            .firstWhere(
                              (item) => item?.id == line.itemId,
                              orElse: () => null,
                            )
                            ?.toString(),
                        options: controller.itemsLookup
                            .where((item) => item.id != null)
                            .map(
                              (item) => AppSearchPickerOption<int>(
                                value: item.id!,
                                label: item.toString(),
                                subtitle: item.itemCode,
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          line.itemId = value;
                          controller.update();
                        },
                      ),
                      AppFormTextField(
                        controller: line.descriptionController,
                        labelText: 'Description',
                      ),
                      AppFormTextField(
                        controller: line.qtyController,
                        labelText: 'Quantity',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildFollowupsTab(
    BuildContext context,
    CrmOpportunitiesController controller,
  ) {
    final isLocked = controller.isSelectedOpportunityReadOnly;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Followups',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            if (!isLocked) ...[
              _buildCommonSaveButton(controller),
              const SizedBox(width: AppUiConstants.spacingSm),
            ],
            AppActionButton(
              icon: Icons.add_outlined,
              label: 'Add Followup',
              filled: false,
              onPressed: isLocked ? null : controller.addFollowup,
            ),
          ],
        ),
        const SizedBox(height: AppUiConstants.spacingSm),
        if (controller.followups.isEmpty)
          const SettingsEmptyState(
            icon: Icons.alarm_outlined,
            title: 'No Followups',
            message: 'Add next actions, notes, assignee, and status.',
            minHeight: 180,
          )
        else
          ...List<Widget>.generate(controller.followups.length, (index) {
            final followup = controller.followups[index];
            final expanded = controller.expandedFollowupIndex == index;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
              child: SettingsExpandableTile(
                title: followup.statusLabel,
                subtitle: [
                  followup.followupDateController.text.trim(),
                  followup.assigneeLabel(controller.users),
                ].where((value) => value.isNotEmpty).join(' • '),
                detail: followup.notesController.text.trim(),
                expanded: expanded,
                highlighted: expanded,
                leadingIcon: Icons.alarm_outlined,
                trailing: IconButton(
                  onPressed: isLocked
                      ? null
                      : () => _confirmRemoveChild(
                          context,
                          title: 'Delete Followup?',
                          message:
                              'This followup will be removed from the opportunity.',
                          onConfirm: () => controller.removeFollowup(index),
                        ),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline),
                ),
                onToggle: () => controller.setExpandedFollowupIndex(
                  expanded ? null : index,
                ),
                child: AbsorbPointer(
                  absorbing: isLocked,
                  child: PurchaseCompactFieldGrid(
                    children: [
                      AppDateTimeSelectorField(
                        controller: followup.followupDateController,
                        labelText: 'Followup Date',
                        hintText: 'YYYY-MM-DD HH:MM:SS',
                        onTap: () =>
                            _pickFollowupDate(context, controller, followup),
                      ),
                      AppDateTimeSelectorField(
                        controller: followup.nextFollowupController,
                        labelText: 'Next Followup',
                        hintText: 'YYYY-MM-DD HH:MM:SS',
                        onTap: () => _pickNextFollowupDate(
                          context,
                          controller,
                          followup,
                        ),
                      ),
                      AppDropdownField<int>.fromMapped(
                        labelText: 'Assigned To',
                        mappedItems: controller.users
                            .where((item) => item.id != null)
                            .map(
                              (item) => AppDropdownItem(
                                value: item.id!,
                                label: item.displayName ?? item.username ?? '',
                              ),
                            )
                            .toList(growable: false),
                        initialValue: followup.assignedTo,
                        onChanged: (value) =>
                            controller.setFollowupAssignedTo(followup, value),
                      ),
                      AppDropdownField<String>.fromMapped(
                        labelText: 'Status',
                        mappedItems:
                            CrmOpportunitiesController.followupStatuses,
                        initialValue: followup.status,
                        onChanged: (value) =>
                            controller.setFollowupStatus(followup, value),
                      ),
                      AppFormTextField(
                        controller: followup.notesController,
                        labelText: 'Notes',
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
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

  Widget _buildCommonSaveButton(CrmOpportunitiesController controller) {
    return AppActionButton(
      icon: Icons.save_outlined,
      label: controller.selectedItem == null
          ? 'Save Opportunity'
          : 'Update Opportunity',
      filled: false,
      onPressed: controller.save,
      busy: controller.saving,
    );
  }

  int? _latestSalesOrderId(CrmOpportunitiesController controller) {
    final orders = controller.salesChain?['orders'];
    if (orders is! List || orders.isEmpty) {
      return null;
    }
    final first = orders.first;
    if (first is! Map) {
      return null;
    }
    return intValue(Map<String, dynamic>.from(first), 'id');
  }

  String? _invoiceRoute(CrmOpportunitiesController controller) {
    final orderId = _latestSalesOrderId(controller);
    if (orderId != null) {
      return '/sales/invoices/new?order_id=$orderId';
    }
    final quotations = controller.salesChain?['quotations'];
    if (quotations is! List || quotations.isEmpty) {
      return null;
    }
    final first = quotations.first;
    if (first is! Map) {
      return null;
    }
    final quotationId = intValue(Map<String, dynamic>.from(first), 'id');
    return quotationId == null
        ? null
        : '/sales/invoices/new?quotation_id=$quotationId';
  }

  Future<void> _confirmRemoveChild(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      onConfirm();
    }
  }
}
