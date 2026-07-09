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

String _crmOpportunityStageLabel(String? raw) {
  final value = (raw ?? '').trim();
  if (value.isEmpty) {
    return '';
  }

  const suffix = ' - opportunity';
  final normalized = value.toLowerCase();
  if (normalized.endsWith(suffix)) {
    return value.substring(0, value.length - suffix.length).trimRight();
  }
  return value;
}

class CrmOpportunityRegisterPage extends StatefulWidget {
  const CrmOpportunityRegisterPage({
    super.key,
    this.embedded = false,
    this.queryParameters = const <String, String>{},
  });

  final bool embedded;
  final Map<String, String> queryParameters;

  @override
  State<CrmOpportunityRegisterPage> createState() =>
      _CrmOpportunityRegisterPageState();
}

class _CrmOpportunityRegisterPageState
    extends State<CrmOpportunityRegisterPage> {
  static const List<AppDropdownItem<String>> _statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'open', label: 'Open'),
        AppDropdownItem(value: 'lost', label: 'Lost'),
        AppDropdownItem(value: 'won', label: 'Won'),
      ];

  final CrmService _service = CrmService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _dateFromController = TextEditingController();
  final TextEditingController _dateToController = TextEditingController();
  bool _loading = true;
  String? _error;
  Set<String> _statuses = <String>{'open'};
  List<CrmOpportunityModel> _rows = const <CrmOpportunityModel>[];

  Set<String> _dashboardStatuses() {
    switch ((widget.queryParameters['dashboard_filter'] ?? '').trim()) {
      case 'open_pending':
        return <String>{'open'};
      default:
        return <String>{'open'};
    }
  }

  void _applyDashboardFilters() {
    _searchController.clear();
    _dateFromController.clear();
    _dateToController.clear();
    _statuses = _dashboardStatuses();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _applyDashboardFilters();
    _load();
  }

  @override
  void didUpdateWidget(covariant CrmOpportunityRegisterPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mapEquals(oldWidget.queryParameters, widget.queryParameters)) {
      setState(_applyDashboardFilters);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _dateFromController.dispose();
    _dateToController.dispose();
    super.dispose();
  }

  Future<void> _openRegisterFilterPanel(BuildContext context) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 600 ? 12.0 : 24.0;
    final dialogPadding = screenWidth < 600 ? 16.0 : AppUiConstants.cardPadding;
    final searchController = TextEditingController(
      text: _searchController.text,
    );
    final dateFromController = TextEditingController(
      text: _dateFromController.text,
    );
    final dateToController = TextEditingController(
      text: _dateToController.text,
    );
    Set<String> tempStatuses = Set<String>.from(_statuses);

    final applied = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final appTheme = Theme.of(
          dialogContext,
        ).extension<AppThemeExtension>()!;

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
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
                    MediaQuery.of(dialogContext).viewInsets.bottom +
                        dialogPadding,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Filter CRM Enquiries',
                              style: Theme.of(dialogContext)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            tooltip: 'Close',
                            icon: const Icon(Icons.close),
                            color: appTheme.mutedText,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _CrmOpportunityRegisterFilters(
                        searchController: searchController,
                        dateFromController: dateFromController,
                        dateToController: dateToController,
                        statuses: tempStatuses,
                        statusItems: _statusItems,
                        onStatusesChanged: (values) {
                          setDialogState(() {
                            tempStatuses = Set<String>.from(values);
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            onPressed: () {
                              setState(() {
                                _searchController.text = searchController.text;
                                _dateFromController.text =
                                    dateFromController.text;
                                _dateToController.text = dateToController.text;
                                _statuses = Set<String>.from(tempStatuses);
                              });
                              Navigator.of(dialogContext).pop(true);
                            },
                            icon: const Icon(Icons.search),
                            label: const Text('Apply Filters'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _dateFromController.clear();
                                _dateToController.clear();
                                _statuses = <String>{'open'};
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
      },
    );

    searchController.dispose();
    dateFromController.dispose();
    dateToController.dispose();
    if (applied == true && mounted) {
      setState(() {});
    }
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
    final fromDate = tryParseCalendarDate(_dateFromController.text.trim());
    final toDate = tryParseCalendarDate(_dateToController.text.trim());
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
              _statuses.isEmpty ||
              _statuses.contains(stringValue(data, 'status'));
          final enquiryDate = DateTime.tryParse(
            nullableStringValue(data, 'enquiry_date') ?? '',
          );
          final normalizedRowDate = enquiryDate == null
              ? null
              : DateTime(enquiryDate.year, enquiryDate.month, enquiryDate.day);
          final dateOk =
              (fromDate == null && toDate == null) ||
              (normalizedRowDate != null &&
                  (fromDate == null ||
                      !normalizedRowDate.isBefore(
                        DateTime(fromDate.year, fromDate.month, fromDate.day),
                      )) &&
                  (toDate == null ||
                      !normalizedRowDate.isAfter(
                        DateTime(toDate.year, toDate.month, toDate.day),
                      )));
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
          return statusOk && dateOk && searchOk;
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
    return _crmOpportunityStageLabel(
      stringValue(
      JsonModel.mapOf(data['stage']) ?? const <String, dynamic>{},
      'stage_name',
      ),
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
      case 'lost':
        return 'Lost';
      case 'open':
      default:
        return 'Open';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<CrmOpportunityModel>(
      title: 'CRM Enquiries',
      embedded: widget.embedded,
      fullPageStyle: true,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage:
          'No CRM enquiries yet. Create a new enquiry to get started.',
      actions: [
        AdaptiveShellActionButton(
          onPressed: () => _openRegisterFilterPanel(context),
          icon: Icons.filter_alt_outlined,
          label: 'Filter',
          filled: false,
        ),
        AdaptiveShellActionButton(
          onPressed: () =>
              _openCrmOpportunityShellRoute(context, '/crm/opportunities/new'),
          icon: Icons.add_outlined,
          label: 'New enquiry',
        ),
      ],
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<CrmOpportunityModel>(
          label: 'Enquiry No',
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
          alignRight: true,
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
    required this.dateFromController,
    required this.dateToController,
    required this.statuses,
    required this.statusItems,
    required this.onStatusesChanged,
  });

  final TextEditingController searchController;
  final TextEditingController dateFromController;
  final TextEditingController dateToController;
  final Set<String> statuses;
  final List<AppDropdownItem<String>> statusItems;
  final ValueChanged<Set<String>> onStatusesChanged;

  @override
  Widget build(BuildContext context) {
    return SettingsFormWrap(
      children: [
        AppFormTextField(
          labelText: 'Search',
          controller: searchController,
          hintText: 'Search enquiry, number, customer, stage, owner, or lead',
        ),
        AppDateField(labelText: 'From Date', controller: dateFromController),
        AppDateField(labelText: 'To Date', controller: dateToController),
        AppDropdownField<String>.fromMapped(
          labelText: 'Status',
          mappedItems: statusItems,
          multiInitialValues: statuses,
          multiHintText: 'Select statuses',
          onMultiChanged: onStatusesChanged,
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
    this.initialLeadId,
    this.initialCompanyId,
    this.initialAssignedTo,
  });

  final bool embedded;
  final bool editorOnly;
  final bool startInNewMode;
  final int? initialSelectId;
  final int? initialLeadId;
  final int? initialCompanyId;
  final int? initialAssignedTo;

  @override
  State<CrmOpportunitiesPage> createState() => _CrmOpportunitiesPageState();
}

class _CrmOpportunitiesPageState extends State<CrmOpportunitiesPage>
    with SingleTickerProviderStateMixin {
  static const double _opportunityColumnWidth = 210;
  static const double _dateColumnWidth = 130;
  static const double _customerColumnWidth = 240;
  static const double _stageColumnWidth = 180;
  static const double _valueColumnWidth = 150;
  static const double _leadColumnWidth = 140;
  static const double _ownerColumnWidth = 160;
  static const double _statusColumnWidth = 120;

  late final String _controllerTag;
  late final CrmOpportunitiesController _controller;
  late final TabController _tabController;
  final ScrollController _listHorizontalScrollController = ScrollController();
  late final GlobalKey<FormState> _formKey;

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
        instanceTag: _controllerTag,
        startInNewMode: widget.startInNewMode,
        initialSelectId: widget.initialSelectId,
        initialLeadId: widget.initialLeadId,
        initialCompanyId: widget.initialCompanyId,
        initialAssignedTo: widget.initialAssignedTo,
      ),
      tag: _controllerTag,
    );
    _formKey = GlobalKey<FormState>();
    _controller.formKey = _formKey;
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
        oldWidget.startInNewMode != widget.startInNewMode ||
        oldWidget.initialLeadId != widget.initialLeadId ||
        oldWidget.initialCompanyId != widget.initialCompanyId ||
        oldWidget.initialAssignedTo != widget.initialAssignedTo) {
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
    _listHorizontalScrollController.dispose();
    _tabController.dispose();
    if (identical(_controller.formKey, _formKey)) {
      _controller.formKey = null;
    }
    if (Get.isRegistered<CrmOpportunitiesController>(tag: _controllerTag)) {
      Get.delete<CrmOpportunitiesController>(tag: _controllerTag);
    }
    super.dispose();
  }

  void _syncRouteState() {
    if (widget.startInNewMode) {
      unawaited(_controller.startNewDraft(leadId: widget.initialLeadId));
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
            onPressed: () {
              if (widget.editorOnly && widget.startInNewMode) {
                controller.resetForm();
                return;
              }
              _openCrmOpportunityShellRoute(context, '/crm/opportunities/new');
            },
            icon: Icons.add_outlined,
            label: 'New Enquiry',
          ),
        ];

        final content = _buildContent(context, controller);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'CRM Enquiries',
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
                          'Filter CRM Enquiries',
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
                          mappedItems: controller.stages
                                .where(
                                  (item) =>
                                      intValue(item.toJson(), 'id') != null,
                                )
                                .map(
                                  (item) => AppDropdownItem<int>(
                                    value: intValue(item.toJson(), 'id')!,
                                    label: _crmOpportunityStageLabel(
                                      item.toString(),
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                          multiInitialValues: controller.filterStageIds,
                          multiHintText: 'Select stages',
                          onMultiChanged: controller.setFilterStageIds,
                        ),
                      ),
                      _filterBox(
                        child: AppDropdownField<String>.fromMapped(
                          labelText: 'Status',
                          mappedItems:
                              CrmOpportunitiesController.filterStatusItems,
                          multiInitialValues: controller.filterStatuses,
                          multiHintText: 'Select statuses',
                          onMultiChanged: controller.setFilterStatuses,
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

  Widget _buildContent(
    BuildContext context,
    CrmOpportunitiesController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading CRM enquiries...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load CRM enquiries',
        message: controller.pageError!,
        onRetry: controller.loadPage,
      );
    }

    if (_tabController.index != controller.activeTabIndex) {
      _tabController.index = controller.activeTabIndex;
    }

    // Migrated page/form state now lives in CrmOpportunitiesController.
    return SettingsWorkspace(
      title: 'CRM Enquiries',
      scrollController: controller.pageScrollController,
      controller: controller.workspaceController,
      editorOnly: widget.editorOnly,
      editorTitle: controller.selectedItem?.toString() ?? 'New Enquiry',
      list: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAppliedFilters(context, controller),
          if (controller.searchController.text.trim().isNotEmpty ||
              controller.filterStageIds.isNotEmpty ||
              controller.filterStatuses.isNotEmpty ||
              controller.filtersApplied ||
              controller.filterCloseFromController.text.trim().isNotEmpty ||
              controller.filterCloseToController.text.trim().isNotEmpty)
            const SizedBox(height: AppUiConstants.spacingMd),
          _buildOpportunityTable(context, controller),
        ],
      ),
      editorBuilder: (_) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.formError != null) ...[
            AppErrorStateView.inline(message: controller.formError!),
            const SizedBox(height: AppUiConstants.spacingSm),
          ],
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
          if (controller.activeTabIndex == 0)
            _buildPrimaryTab(context, controller)
          else if (controller.activeTabIndex == 1)
            controller.selectedItem?.toJson()['id'] == null
                ? _buildDependentTabPlaceholder(
                    title: 'Followups',
                    message:
                        'Save this enquiry first to manage calls and followups.',
                  )
                : _buildFollowupsTab(context, controller)
          else if (controller.activeTabIndex == 2)
            controller.selectedItem?.toJson()['id'] == null
                ? _buildDependentTabPlaceholder(
                    title: 'Products',
                    message:
                        'Save this enquiry first to manage enquiry products.',
                  )
                : _buildLinesTab(context, controller)
          else
            controller.selectedItem?.toJson()['id'] == null
                ? _buildDependentTabPlaceholder(
                    title: 'Suggested Products',
                    message:
                        'Save this enquiry first to manage suggested products.',
                  )
                : _buildProductsTab(context, controller),
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
      if (controller.filterStageIds.isNotEmpty || controller.filtersApplied)
        'Stage: ${controller.filterStageIds.isEmpty ? 'All' : controller.filterStageIds.map((id) => _crmOpportunityStageLabel(controller.stages.cast<CrmStageModel?>().firstWhere((item) => intValue(item?.toJson() ?? const {}, "id") == id, orElse: () => null)?.toString())).join(', ')}',
      if (controller.filterStatuses.isNotEmpty ||
          controller.filtersApplied)
        'Status: ${controller.filterStatuses.isEmpty ? 'All' : controller.filterStatuses.join(', ')}',
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

  Widget _tableHeader(String label, double width) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: width,
        child: Text(
          label,
          textAlign: TextAlign.left,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _tableCellText(
    String value,
    double width, {
    TextStyle? style,
    int maxLines = 1,
    TextAlign textAlign = TextAlign.left,
  }) {
    return SizedBox(
      width: width,
      child: Text(
        value,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _tableCellTopAligned(Widget child, double width) {
    return SizedBox(
      width: width,
      child: Align(alignment: Alignment.topLeft, child: child),
    );
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
                  'Search enquiry, number, customer, stage, owner, or lead',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          if (controller.filteredItems.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppUiConstants.spacingXl),
              child: Text('No CRM enquiries found.'),
            )
          else
            Scrollbar(
              controller: _listHorizontalScrollController,
              thumbVisibility: true,
              trackVisibility: true,
              notificationPredicate: (notification) =>
                  notification.metrics.axis == Axis.horizontal,
              child: SingleChildScrollView(
                controller: _listHorizontalScrollController,
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 1440),
                  child: DataTable(
                    columns: [
                      DataColumn(
                        label: _tableHeader(
                          'Enquiry No',
                          _opportunityColumnWidth,
                        ),
                      ),
                      DataColumn(label: _tableHeader('Date', _dateColumnWidth)),
                      DataColumn(
                        label: _tableHeader('Customer', _customerColumnWidth),
                      ),
                      DataColumn(
                        label: _tableHeader('Stage', _stageColumnWidth),
                      ),
                      DataColumn(
                        label: _tableHeader(
                          'Expected Value',
                          _valueColumnWidth,
                        ),
                      ),
                      DataColumn(
                        label: _tableHeader('Lead By', _leadColumnWidth),
                      ),
                      DataColumn(
                        label: _tableHeader('Owner', _ownerColumnWidth),
                      ),
                      DataColumn(
                        label: _tableHeader('Status', _statusColumnWidth),
                      ),
                    ],
                    rows: controller.filteredItems
                        .map((item) {
                          final data = item.toJson();
                          final selected = item == controller.selectedItem;
                          final customerLabel = _customerLabel(data);
                          final statusText = stringValue(
                            data,
                            'status',
                            'open',
                          );
                          final rowColor = selected
                              ? theme.colorScheme.primary.withValues(
                                  alpha: 0.08,
                                )
                              : null;
                          return DataRow(
                            selected: selected,
                            color: rowColor == null
                                ? null
                                : WidgetStatePropertyAll<Color>(rowColor),
                            cells: [
                              DataCell(
                                _tableCellTopAligned(
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        stringValue(data, 'enquiry_no'),
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (stringValue(
                                        data,
                                        'opportunity_name',
                                      ).isNotEmpty)
                                        Text(
                                          stringValue(data, 'opportunity_name'),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(color: mutedText),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                  _opportunityColumnWidth,
                                ),
                                onTap: () => controller.selectItem(item),
                              ),
                              DataCell(
                                _tableCellTopAligned(
                                  Text(
                                    displayDate(
                                      nullableStringValue(data, 'enquiry_date'),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  _dateColumnWidth,
                                ),
                                onTap: () => controller.selectItem(item),
                              ),
                              DataCell(
                                _tableCellText(
                                  customerLabel,
                                  _customerColumnWidth,
                                ),
                                onTap: () => controller.selectItem(item),
                              ),
                              DataCell(
                                _tableCellText(
                                  _stageLabel(data),
                                  _stageColumnWidth,
                                  maxLines: 2,
                                ),
                                onTap: () => controller.selectItem(item),
                              ),
                              DataCell(
                                _tableCellText(
                                  stringValue(data, 'expected_value'),
                                  _valueColumnWidth,
                                  textAlign: TextAlign.right,
                                ),
                                onTap: () => controller.selectItem(item),
                              ),
                              DataCell(
                                _tableCellText(
                                  _leadLabel(data),
                                  _leadColumnWidth,
                                ),
                                onTap: () => controller.selectItem(item),
                              ),
                              DataCell(
                                _tableCellText(
                                  _ownerLabel(data),
                                  _ownerColumnWidth,
                                ),
                                onTap: () => controller.selectItem(item),
                              ),
                              DataCell(
                                SizedBox(
                                  width: _statusColumnWidth,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: SettingsStatusPill(
                                      label: statusText,
                                      active: statusText != 'lost',
                                    ),
                                  ),
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
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.selectedOpportunityId() != null) ...[
            CrmSalesPipelineBar(
              data: controller.salesChain,
              title: 'Sales line',
              hideEnquiryChip: true,
              hideOpportunityChip: true,
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
            if (isLocked) ...[
              Text(
                'This enquiry is read-only because it is won or lost.',
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
                  onChanged: (value) {
                    unawaited(controller.setLeadId(value));
                  },
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Customer',
                  doctypeLabel: 'Customer',
                  allowCreate: true,
                  onNavigateToCreateNew: (name) {
                    final uri = Uri(
                      path: '/parties',
                      queryParameters: {
                        'new': '1',
                        'party_context': 'customer',
                        if (name.trim().isNotEmpty) 'party_name': name.trim(),
                      },
                    );
                    openModuleShellRoute(context, uri.toString());
                  },
                  mappedItems: controller.customers
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: controller.customerPartyId,
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
                  labelText: 'Enquiry Name',
                  validator: Validators.required('Enquiry Name'),
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
                          label: _crmOpportunityStageLabel(item.toString()),
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
                      ? 'Save Enquiry'
                      : 'Update Enquiry',
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
          if (controller.selectedOpportunityId() != null && !isLocked) ...[
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
                              'This suggested product will be removed from the enquiry.',
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
                      ErpLinkField<int>(
                        labelText: 'Item',
                        doctypeLabel: 'Item',
                        hintText: 'Search item',
                        initialSelection: controller.selectedItemOption(
                          product.itemId,
                        ),
                        options: controller.itemPickerOptions,
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
                              'This product row will be removed from the enquiry.',
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
                      ErpLinkField<int>(
                        labelText: 'Item',
                        doctypeLabel: 'Item',
                        hintText: 'Search item',
                        initialSelection: controller.selectedItemOption(
                          line.itemId,
                        ),
                        options: controller.itemPickerOptions,
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
    if (!controller.canManageFollowups) {
      return _buildDependentTabPlaceholder(
        title: 'Save Enquiry First',
        message:
            'Save the enquiry header before adding follow-ups. Follow-ups are tracked against an existing enquiry.',
      );
    }

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
                              'This followup will be removed from the enquiry.',
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
                      AppFormTextField(
                        controller: followup.followupDateController,
                        labelText: 'Followup Date',
                        hintText: 'YYYY-MM-DD HH:MM:SS',
                        keyboardType: TextInputType.datetime,
                        inputFormatters: const [DateTimeInputFormatter()],
                        allowType: false,
                        onChanged: (_) => controller.update(),
                      ),
                      AppFormTextField(
                        controller: followup.nextFollowupController,
                        labelText: 'Next Followup',
                        hintText: 'YYYY-MM-DD HH:MM:SS',
                        keyboardType: TextInputType.datetime,
                        inputFormatters: const [DateTimeInputFormatter()],
                        allowType: false,
                        onChanged: (_) => controller.update(),
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
          ? 'Save Enquiry'
          : 'Update Enquiry',
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
    return null;
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
