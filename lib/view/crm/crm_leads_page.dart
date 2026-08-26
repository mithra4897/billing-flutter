import '../../controller/crm/crm_leads_controller.dart';
import '../../controller/crm/crm_lead_register_controller.dart';
import '../../screen.dart';

void _openCrmShellRoute(BuildContext context, String route) {
  final navigate = ShellRouteScope.maybeOf(context);
  if (navigate != null) {
    navigate(route);
    return;
  }
  Navigator.of(context).pushNamed(route);
}

class CrmLeadRegisterPage extends StatefulWidget {
  const CrmLeadRegisterPage({
    super.key,
    this.embedded = false,
    this.queryParameters = const <String, String>{},
  });

  final bool embedded;
  final Map<String, String> queryParameters;

  @override
  State<CrmLeadRegisterPage> createState() => _CrmLeadRegisterPageState();
}

class _CrmLeadRegisterPageState extends State<CrmLeadRegisterPage> {
  late final String _controllerTag;
  bool _filtersVisible = false;
  bool _isSuperAdmin = false;

  Set<String> _dashboardStatuses() {
    switch ((widget.queryParameters['dashboard_filter'] ?? '').trim()) {
      case 'pending':
        return <String>{'draft', 'in_progress'};
      default:
        return <String>{'draft', 'in_progress'};
    }
  }

  void _applyDashboardFilters(CrmLeadRegisterController controller) {
    controller.searchController.clear();
    controller.dateFromController.clear();
    controller.dateToController.clear();
    controller.setStatuses(_dashboardStatuses());
  }

  List<AppDropdownItem<int>> _employeeItems(
    CrmLeadRegisterController controller,
  ) {
    final employees = <int, String>{};
    for (final row in controller.rows) {
      final assigned = JsonModel.mapOf(row.toJson()['assigned_user']);
      final id = intValue(assigned ?? const <String, dynamic>{}, 'id');
      if (id == null) continue;
      final label = stringValue(assigned!, 'display_name').isNotEmpty
          ? stringValue(assigned, 'display_name')
          : stringValue(assigned, 'username');
      if (label.isNotEmpty) employees[id] = label;
    }
    return employees.entries
        .map(
          (entry) => AppDropdownItem<int>(value: entry.key, label: entry.value),
        )
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'CrmLeadRegisterController',
      scope: <String, Object?>{
        'widget': widget.runtimeType,
        'key': widget.key,
        'state': identityHashCode(this),
      },
    );
    Get.put(
      CrmLeadRegisterController(instanceTag: _controllerTag),
      tag: _controllerTag,
    );
    _loadAccess();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !Get.isRegistered<CrmLeadRegisterController>(tag: _controllerTag)) {
        return;
      }
      _applyDashboardFilters(
        Get.find<CrmLeadRegisterController>(tag: _controllerTag),
      );
    });
  }

  Future<void> _loadAccess() async {
    final currentUser = await SessionStorage.getCurrentUser();
    if (!mounted) return;
    setState(() {
      _isSuperAdmin =
          currentUser?['is_super_admin'] == true ||
          currentUser?['is_super_admin'] == 1 ||
          currentUser?['is_super_admin'] == '1';
    });
  }

  @override
  void didUpdateWidget(covariant CrmLeadRegisterPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mapEquals(oldWidget.queryParameters, widget.queryParameters)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            !Get.isRegistered<CrmLeadRegisterController>(tag: _controllerTag)) {
          return;
        }
        _applyDashboardFilters(
          Get.find<CrmLeadRegisterController>(tag: _controllerTag),
        );
      });
    }
  }

  @override
  void dispose() {
    if (Get.isRegistered<CrmLeadRegisterController>(tag: _controllerTag)) {
      Get.delete<CrmLeadRegisterController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CrmLeadRegisterController>(
      tag: _controllerTag,
      builder: (controller) {
        return PurchaseRegisterPage<CrmLeadModel>(
          title: 'CRM Leads',
          embedded: widget.embedded,
          fullPageStyle: true,
          loading: controller.loading,
          errorMessage: controller.error,
          onRetry: controller.load,
          emptyMessage: 'No CRM leads yet. Create a new lead to get started.',
          actions: [
            AdaptiveShellSearchField(
              controller: controller.searchController,
              hintText: 'Search leads',
            ),
            AdaptiveShellActionButton(
              onPressed: () =>
                  setState(() => _filtersVisible = !_filtersVisible),
              icon: Icons.filter_alt_outlined,
              label: 'Filter',
              filled: _filtersVisible,
            ),
            AdaptiveShellActionButton(
              onPressed: () => _openCrmShellRoute(context, '/crm/leads/new'),
              icon: Icons.add_outlined,
              label: 'New lead',
            ),
          ],
          filters: _filtersVisible
              ? _CrmLeadRegisterFilters(
                  dateFromController: controller.dateFromController,
                  dateToController: controller.dateToController,
                  statuses: controller.statuses,
                  statusItems: CrmLeadRegisterController.statusItems,
                  sort: controller.sort,
                  sortItems: CrmLeadRegisterController.sortItems,
                  employeeItems: _isSuperAdmin
                      ? _employeeItems(controller)
                      : const <AppDropdownItem<int>>[],
                  employeeIds: controller.assignedToIds,
                  onStatusesChanged: controller.setStatuses,
                  onSortChanged: (value) => controller.setSort(value ?? ''),
                  onEmployeeChanged: controller.setAssignedToIds,
                  onClear: () {
                    controller.searchController.clear();
                    controller.dateFromController.clear();
                    controller.dateToController.clear();
                    controller.setStatuses(<String>{'draft', 'in_progress'});
                    controller.setSort('date_desc');
                    controller.setAssignedToIds(<int>{});
                  },
                )
              : null,
          rows: controller.filteredRows,
          columns: [
            PurchaseRegisterColumn<CrmLeadModel>(
              label: 'Lead',
              flex: 3,
              textStyle: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              valueBuilder: (row) => stringValue(row.toJson(), 'lead_name'),
            ),
            PurchaseRegisterColumn<CrmLeadModel>(
              label: 'Company',
              flex: 3,
              valueBuilder: (row) => stringValue(row.toJson(), 'company_name'),
            ),
            PurchaseRegisterColumn<CrmLeadModel>(
              label: 'Mobile',
              valueBuilder: (row) => stringValue(row.toJson(), 'mobile'),
            ),
            PurchaseRegisterColumn<CrmLeadModel>(
              label: 'Source',
              flex: 2,
              valueBuilder: (row) => _sourceLabel(row),
            ),
            PurchaseRegisterColumn<CrmLeadModel>(
              label: 'Probability',
              flex: 2,
              center: true,
              valueBuilder: (row) => '${_probabilityPercent(row).round()}%',
              widgetBuilder: (context, row) => Center(
                child: AppProbabilityIndicator(value: _probabilityPercent(row)),
              ),
            ),
            PurchaseRegisterColumn<CrmLeadModel>(
              label: 'Status',
              center: true,
              valueBuilder: (row) => controller.statusLabel(
                stringValue(row.toJson(), 'lead_status'),
              ),
              widgetBuilder: (context, row) {
                final rawStatus = stringValue(row.toJson(), 'lead_status');
                final label = controller.statusLabel(rawStatus);
                return AppStatusBadge(
                  label: label,
                  color: appStatusColor(rawStatus),
                );
              },
            ),
            PurchaseRegisterColumn<CrmLeadModel>(
              label: 'Assigned to',
              flex: 2,
              valueBuilder: (row) => _assignedLabel(row),
            ),
            if (_isSuperAdmin)
              PurchaseRegisterColumn<CrmLeadModel>(
                label: 'Created by',
                valueBuilder: (row) => _createdByLabel(row.toJson()),
              ),
          ],
          onRowTap: (row) => _openCrmShellRoute(
            context,
            '/crm/leads/${intValue(row.toJson(), 'id')}',
          ),
        );
      },
    );
  }

  String _createdByLabel(Map<String, dynamic> data) {
    final creator =
        JsonModel.mapOf(data['creator']) ?? const <String, dynamic>{};
    final displayName = stringValue(creator, 'display_name');
    return displayName.isNotEmpty
        ? displayName
        : stringValue(creator, 'username');
  }

  String _sourceLabel(CrmLeadModel row) {
    final source = row.source ?? const <String, dynamic>{};
    return stringValue(source, 'source_name').isNotEmpty
        ? stringValue(source, 'source_name')
        : stringValue(source, 'name');
  }

  String _assignedLabel(CrmLeadModel row) {
    final assigned = row.assignedUser ?? const <String, dynamic>{};
    final displayName = stringValue(assigned, 'display_name');
    return displayName.isNotEmpty
        ? displayName
        : stringValue(assigned, 'username');
  }

  double _probabilityPercent(CrmLeadModel row) {
    final explicit = row.probabilityPercent;
    if (explicit != null) return explicit.clamp(0, 100).toDouble();
    switch ((row.leadStatus ?? '').trim().toLowerCase()) {
      case 'converted':
      case 'own':
        return 100;
      case 'lost':
        return 0;
      case 'in_progress':
        return 50;
      case 'new':
      case 'draft':
      default:
        return 10;
    }
  }
}

class _CrmLeadRegisterFilters extends StatelessWidget {
  const _CrmLeadRegisterFilters({
    required this.dateFromController,
    required this.dateToController,
    required this.statuses,
    required this.statusItems,
    required this.sort,
    required this.sortItems,
    required this.onStatusesChanged,
    required this.onSortChanged,
    required this.employeeItems,
    required this.employeeIds,
    required this.onEmployeeChanged,
    required this.onClear,
  });

  final TextEditingController dateFromController;
  final TextEditingController dateToController;
  final Set<String> statuses;
  final List<AppDropdownItem<String>> statusItems;
  final String sort;
  final List<AppDropdownItem<String>> sortItems;
  final ValueChanged<Set<String>> onStatusesChanged;
  final ValueChanged<String?> onSortChanged;
  final List<AppDropdownItem<int>> employeeItems;
  final Set<int> employeeIds;
  final ValueChanged<Set<int>> onEmployeeChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SettingsFormWrap(
        maxWidth: double.infinity,
        maxColumns: 6,
        children: [
          AppDateField(labelText: 'From Date', controller: dateFromController),
          AppDateField(labelText: 'To Date', controller: dateToController),
          AppDropdownField<String>.fromMapped(
            labelText: 'Status',
            mappedItems: statusItems,
            multiInitialValues: statuses,
            multiHintText: 'Select statuses',
            onMultiChanged: onStatusesChanged,
          ),
          AppDropdownField<String>.fromMapped(
            labelText: 'Sort',
            mappedItems: sortItems,
            initialValue: sort,
            onChanged: onSortChanged,
          ),
          if (employeeItems.isNotEmpty)
            AppDropdownField<int>.fromMapped(
              labelText: 'Employee',
              mappedItems: employeeItems,
              multiInitialValues: employeeIds,
              multiHintText: 'Select employees',
              onMultiChanged: onEmployeeChanged,
            ),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.clear_outlined),
              label: const Text('Clear'),
            ),
          ),
        ],
      ),
    );
  }
}

class CrmLeadsPage extends StatefulWidget {
  const CrmLeadsPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.startInNewMode = false,
    this.initialSelectId,
    this.initialLeadName,
    this.initialCompanyId,
  });

  final bool embedded;
  final bool editorOnly;
  final bool startInNewMode;
  final int? initialSelectId;
  final String? initialLeadName;
  final int? initialCompanyId;

  @override
  State<CrmLeadsPage> createState() => _CrmLeadsPageState();
}

class _CrmLeadsPageState extends State<CrmLeadsPage>
    with SingleTickerProviderStateMixin {
  late final String _controllerTag;
  late final CrmLeadsController _controller;
  late final TabController _tabController;
  late final bool _reusedController;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag('CrmLeadsController');
    _reusedController = Get.isRegistered<CrmLeadsController>(
      tag: _controllerTag,
    );
    _controller = Get.put(
      CrmLeadsController(
        startInNewMode: widget.startInNewMode,
        initialSelectId: widget.initialSelectId,
        initialLeadName: widget.initialLeadName,
        initialCompanyId: widget.initialCompanyId,
      ),
      tag: _controllerTag,
      permanent: true,
    );
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _controller.setActiveTabIndex(_tabController.index);
      }
    });
    if (_reusedController) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _syncRouteState();
      });
    }
  }

  @override
  void didUpdateWidget(covariant CrmLeadsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSelectId != widget.initialSelectId ||
        oldWidget.startInNewMode != widget.startInNewMode ||
        oldWidget.initialLeadName != widget.initialLeadName ||
        oldWidget.initialCompanyId != widget.initialCompanyId) {
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
    super.dispose();
  }

  void _syncRouteState() {
    if (widget.startInNewMode) {
      _controller.resetForm(notify: false);
      _controller.applyInitialLeadDraft();
      return;
    }
    if (widget.initialSelectId != null) {
      _controller.loadPage(selectId: widget.initialSelectId);
      return;
    }
    _controller.loadPage();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CrmLeadsController>(
      tag: _controllerTag,
      builder: (controller) {
        final actions = <Widget>[
          AdaptiveShellSearchField(
            controller: controller.searchController,
            hintText: 'Search leads',
          ),
          AdaptiveShellActionButton(
            onPressed: () => _openFilterPanel(context, controller),
            icon: Icons.filter_alt_outlined,
            label: 'Filter',
            filled: false,
          ),
          AdaptiveShellActionButton(
            onPressed: () {
              if (widget.editorOnly && widget.startInNewMode) {
                controller.resetForm(notify: false);
                controller.applyInitialLeadDraft();
                return;
              }
              _openCrmShellRoute(context, '/crm/leads/new');
            },
            icon: Icons.add_outlined,
            label: 'New Lead',
          ),
        ];

        final content = _buildContent(context, controller);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'CRM Leads',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Future<void> _openFilterPanel(
    BuildContext context,
    CrmLeadsController controller,
  ) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 600 ? 12.0 : 24.0;
    final dialogPadding = screenWidth < 600 ? 16.0 : AppUiConstants.cardPadding;
    final Set<int> selectedSourceIds = Set<int>.from(
      controller.filterSourceIds,
    );
    final Set<int> selectedAssignedToIds = Set<int>.from(
      controller.filterAssignedToIds,
    );
    Set<String> selectedStatuses = Set<String>.from(
      controller.filterLeadStatuses,
    );

    final applied = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final appTheme = Theme.of(
          dialogContext,
        ).extension<AppThemeExtension>()!;

        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                              'Filter CRM Leads',
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
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _filterBox(
                            child: AppDropdownField<int>.fromMapped(
                              labelText: 'Source',
                              mappedItems: controller.sources
                                  .where(
                                    (item) =>
                                        intValue(item.toJson(), 'id') != null,
                                  )
                                  .map(
                                    (item) => AppDropdownItem<int>(
                                      value: intValue(item.toJson(), 'id')!,
                                      label: item.toString(),
                                    ),
                                  )
                                  .toList(growable: false),
                              multiInitialValues: selectedSourceIds,
                              multiHintText: 'Select sources',
                              onMultiChanged: (values) {
                                setDialogState(() {
                                  selectedSourceIds
                                    ..clear()
                                    ..addAll(values);
                                });
                              },
                            ),
                          ),
                          _filterBox(
                            child: AppDropdownField<int>.fromMapped(
                              labelText: 'Assigned To',
                              mappedItems: controller.users
                                  .where((item) => item.id != null)
                                  .map(
                                    (item) => AppDropdownItem<int>(
                                      value: item.id!,
                                      label:
                                          item.displayName ??
                                          item.username ??
                                          '',
                                    ),
                                  )
                                  .toList(growable: false),
                              multiInitialValues: selectedAssignedToIds,
                              multiHintText: 'Select assignees',
                              onMultiChanged: (values) {
                                setDialogState(() {
                                  selectedAssignedToIds
                                    ..clear()
                                    ..addAll(values);
                                });
                              },
                            ),
                          ),
                          _filterBox(
                            child: AppDropdownField<String>.fromMapped(
                              labelText: 'Status',
                              mappedItems:
                                  CrmLeadsController.leadFilterStatuses,
                              multiInitialValues: selectedStatuses,
                              multiHintText: 'Select statuses',
                              onMultiChanged: (values) {
                                setDialogState(() {
                                  selectedStatuses = Set<String>.from(values);
                                });
                              },
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
                              controller.setFilterSourceIds(
                                Set<int>.from(selectedSourceIds),
                              );
                              controller.setFilterAssignedToIds(
                                Set<int>.from(selectedAssignedToIds),
                              );
                              controller.setFilterLeadStatuses(
                                Set<String>.from(selectedStatuses),
                              );
                              controller.markFiltersApplied();
                              Navigator.of(dialogContext).pop(true);
                            },
                            icon: const Icon(Icons.search),
                            label: const Text('Apply Filters'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              controller.clearFilters();
                              setDialogState(() {
                                selectedSourceIds.clear();
                                selectedAssignedToIds.clear();
                                selectedStatuses.clear();
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

    if (applied == true) {
      controller.applySearch();
    }
  }

  Widget _buildContent(BuildContext context, CrmLeadsController controller) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading CRM leads...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load CRM leads',
        message: controller.pageError!,
        onRetry: controller.loadPage,
      );
    }

    // Migrated page/form state now lives in CrmLeadsController.
    if (_tabController.index != controller.activeTabIndex) {
      _tabController.index = controller.activeTabIndex;
    }
    return SettingsWorkspace(
      title: 'CRM Leads',
      scrollController: controller.pageScrollController,
      controller: controller.workspaceController,
      editorOnly: widget.editorOnly,
      editorTitle: controller.selectedItem?.toString() ?? 'New Lead',
      list: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAppliedFilters(context, controller),
          if (controller.searchController.text.trim().isNotEmpty ||
              controller.filterCompanyId != null ||
              controller.filterSourceIds.isNotEmpty ||
              controller.filterAssignedToIds.isNotEmpty ||
              controller.filterLeadStatuses.isNotEmpty ||
              controller.filtersApplied)
            const SizedBox(height: AppUiConstants.spacingMd),
          SettingsListCard<CrmLeadModel>(
            showSearchBar: false,
            items: controller.filteredItems,
            selectedItem: controller.selectedItem,
            emptyMessage: 'No CRM leads found.',
            itemBuilder: (item, selected) {
              final data = item.toJson();
              final id = intValue(data, 'id');
              return SettingsListTile(
                title: item.toString(),
                subtitle: [
                  stringValue(data, 'company_name'),
                  stringValue(data, 'mobile'),
                  controller.leadStatusLabel(
                    stringValue(data, 'lead_status', 'new'),
                  ),
                ].where((value) => value.trim().isNotEmpty).join(' • '),
                selected: selected,
                onTap: () {
                  if (id == null) {
                    return;
                  }
                  _openCrmShellRoute(context, '/crm/leads/$id');
                },
                trailing: AppStatusBadge(
                  label: controller.leadStatusLabel(
                    stringValue(data, 'lead_status', 'new'),
                  ),
                  color: appStatusColor(
                    stringValue(data, 'lead_status', 'new'),
                  ),
                ),
              );
            },
          ),
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
              Tab(text: 'Activities'),
            ],
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          if (controller.activeTabIndex == 0)
            _buildPrimaryTab(context, controller)
          else if (controller.selectedItem?.toJson()['id'] == null)
            _buildDependentTabPlaceholder(
              title: 'Activities',
              message:
                  'Save this lead first to manage calls, emails, meetings, and follow-up notes.',
            )
          else
            _buildActivitiesTab(context, controller),
        ],
      ),
    );
  }

  Widget _buildAppliedFilters(
    BuildContext context,
    CrmLeadsController controller,
  ) {
    final chips = <String>[
      if (controller.searchController.text.trim().isNotEmpty)
        'Search: ${controller.searchController.text.trim()}',
      if (controller.filterCompanyId != null)
        'Company: ${controller.companies.cast<CompanyModel?>().firstWhere((item) => item?.id == controller.filterCompanyId, orElse: () => null)?.toString() ?? controller.filterCompanyId}',
      if (controller.filterSourceIds.isNotEmpty || controller.filtersApplied)
        'Source: ${controller.filterSourceIds.isEmpty ? 'All' : controller.filterSourceIds.map((id) => controller.sources.cast<CrmSourceModel?>().firstWhere((item) => intValue(item?.toJson() ?? const {}, "id") == id, orElse: () => null)?.toString() ?? id.toString()).join(', ')}',
      if (controller.filterAssignedToIds.isNotEmpty ||
          controller.filtersApplied)
        'Assigned: ${controller.filterAssignedToIds.isEmpty ? 'All' : controller.filterAssignedToIds.map((id) => controller.users.cast<UserModel?>().firstWhere((item) => item?.id == id, orElse: () => null)?.displayName ?? controller.users.cast<UserModel?>().firstWhere((item) => item?.id == id, orElse: () => null)?.username ?? id.toString()).join(', ')}',
      if (controller.filterLeadStatuses.isNotEmpty || controller.filtersApplied)
        'Status: ${controller.filterLeadStatuses.isEmpty ? 'All' : controller.filterLeadStatuses.map(controller.leadStatusLabel).join(', ')}',
    ];

    if (chips.isEmpty) return const SizedBox.shrink();
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;
    return DecoratedBox(
      decoration: appTheme.cardDecoration(),
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

  Widget _buildPrimaryTab(BuildContext context, CrmLeadsController controller) {
    return Form(
      child: Builder(
        builder: (formContext) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (controller.formError != null) ...[
                AppErrorStateView.inline(message: controller.formError!),
                const SizedBox(height: AppUiConstants.spacingSm),
              ],
              if (intValue(
                    controller.selectedItem?.toJson() ?? const {},
                    'id',
                  ) !=
                  null)
                CrmSalesPipelineBar(
                  data: controller.salesChain,
                  hideLeadChip: true,
                ),
              if (controller.isSelectedLeadReadOnly) ...[
                Text(
                  controller.effectiveLeadStatus() == 'converted'
                      ? 'This lead already has an enquiry. Details are read-only. Open the linked enquiry to continue the sales process.'
                      : 'This lead is lost. Details are read-only.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppUiConstants.spacingSm),
              ],
              IgnorePointer(
                ignoring: controller.isSelectedLeadReadOnly,
                child: SettingsFormWrap(
                  children: [
                    AppFormTextField(
                      controller: controller.leadNameController,
                      labelText: 'Lead Name',
                      enabled: !controller.isSelectedLeadReadOnly,
                      validator: Validators.compose([
                        Validators.required('Lead Name'),
                        Validators.optionalMaxLength(255, 'Lead Name'),
                      ]),
                    ),
                    AppFormTextField(
                      controller: controller.companyNameController,
                      labelText: 'Company Name',
                      enabled: !controller.isSelectedLeadReadOnly,
                    ),
                    AppFormTextField(
                      controller: controller.mobileController,
                      labelText: 'Mobile',
                      enabled: !controller.isSelectedLeadReadOnly,
                    ),
                    AppFormTextField(
                      controller: controller.emailController,
                      labelText: 'Email',
                      enabled: !controller.isSelectedLeadReadOnly,
                    ),
                    AppDropdownField<int>.fromMapped(
                      labelText: 'Source',
                      mappedItems: controller.sources
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
                      initialValue: controller.sourceId,
                      onChanged: controller.setSourceId,
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
                      initialValue: controller.assignedTo,
                      validator: Validators.requiredSelection('Assigned To'),
                      onChanged: controller.setAssignedTo,
                    ),
                    AppFormTextField(
                      key: ValueKey<String>(
                        'lead-status-${controller.effectiveLeadStatus()}',
                      ),
                      labelText: 'Status',
                      initialValue: controller.leadStatusLabel(),
                      readOnly: true,
                      enabled: false,
                    ),
                    AppFormTextField(
                      controller: controller.remarksController,
                      labelText: 'Remarks',
                      maxLines: 3,
                      enabled: !controller.isSelectedLeadReadOnly,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppUiConstants.spacingMd),
              Wrap(
                spacing: AppUiConstants.spacingSm,
                runSpacing: AppUiConstants.spacingSm,
                children: [
                  if (!controller.isSelectedLeadReadOnly)
                    AppActionButton(
                      icon: Icons.save_outlined,
                      label: controller.selectedItem == null
                          ? 'Save Lead'
                          : 'Update Lead',
                      onPressed: () => controller.save(),
                      busy: controller.saving,
                    ),
                  if (controller.canCreateOpportunityForSelectedLead) ...[
                    AppActionButton(
                      icon: Icons.forward_outlined,
                      label: 'Create Enquiry',
                      onPressed: () {
                        final leadId = intValue(
                          controller.selectedItem?.toJson() ??
                              const <String, dynamic>{},
                          'id',
                        );
                        if (leadId == null) {
                          return;
                        }
                        final uri = Uri(
                          path: '/crm/opportunities/new',
                          queryParameters: {
                            'lead_id': '$leadId',
                            if (controller.companyId != null)
                              'company_id': controller.companyId.toString(),
                            if (controller.assignedTo != null)
                              'assigned_to': controller.assignedTo.toString(),
                          },
                        );
                        _openCrmShellRoute(context, uri.toString());
                      },
                    ),
                  ],
                  if (controller.selectedItem != null &&
                      !controller.isSelectedLeadReadOnly) ...[
                    AppActionButton(
                      icon: Icons.cancel_outlined,
                      label: 'Lost',
                      filled: false,
                      onPressed: controller.markLost,
                    ),
                  ],
                  if (controller.selectedItem != null &&
                      controller.isSelectedLeadReadOnly &&
                      (controller.opportunityIdFromSalesChain() ??
                              controller.enquiryIdFromSalesChain()) !=
                          null)
                    AppActionButton(
                      icon: Icons.open_in_new_outlined,
                      label: 'Open Enquiry',
                      onPressed: () => _openCrmShellRoute(
                        context,
                        '/crm/opportunities/${controller.opportunityIdFromSalesChain() ?? controller.enquiryIdFromSalesChain()}',
                      ),
                    ),
                  if (controller.canDeleteSelectedLead)
                    AppActionButton(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      filled: false,
                      onPressed: () async {
                        final deleted = await controller.delete();
                        if (!deleted || !context.mounted) {
                          return;
                        }
                        _openCrmShellRoute(context, '/crm/leads');
                      },
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActivitiesTab(
    BuildContext context,
    CrmLeadsController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Activities',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            AppActionButton(
              icon: Icons.add_outlined,
              label: 'Add Activity',
              filled: false,
              onPressed: controller.isSelectedLeadReadOnly
                  ? null
                  : controller.addActivity,
            ),
          ],
        ),
        const SizedBox(height: AppUiConstants.spacingSm),
        if (controller.activities.isEmpty)
          const SettingsEmptyState(
            icon: Icons.event_note_outlined,
            title: 'No Activities',
            message:
                'Add calls, emails, meetings, notes, and follow-up entries.',
            minHeight: 180,
          )
        else
          ...List<Widget>.generate(controller.activities.length, (index) {
            final activity = controller.activities[index];
            final expanded = controller.expandedActivityIndex == index;
            return Padding(
              key: ValueKey<String>('lead-activity-${activity.draftKey}'),
              padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
              child: SettingsExpandableTile(
                title: activity.activityTypeLabel,
                // Surface activity completion state directly in the collapsed card.
                subtitle: [
                  activity.status.trim().isEmpty
                      ? ''
                      : activity.status.trim().toUpperCase(),
                  activity.activityDateTimeController.text.trim(),
                  activity.nextFollowupController.text.trim(),
                ].where((value) => value.isNotEmpty).join(' • '),
                detail: activity.notesController.text.trim(),
                expanded: expanded,
                highlighted: expanded,
                leadingIcon: Icons.event_note_outlined,
                trailing: IconButton(
                  onPressed: controller.isSelectedLeadReadOnly
                      ? null
                      : () => controller.removeActivity(index),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline),
                ),
                onToggle: () => controller.setExpandedActivityIndex(
                  expanded ? null : index,
                ),
                child: IgnorePointer(
                  ignoring: controller.isSelectedLeadReadOnly,
                  child: PurchaseCompactFieldGrid(
                    children: [
                      AppDropdownField<String>.fromMapped(
                        labelText: 'Type',
                        mappedItems: CrmLeadsController.activityTypes,
                        initialValue: activity.activityType,
                        onChanged: (value) =>
                            controller.setLeadActivityType(activity, value),
                      ),
                      AppDropdownField<String>.fromMapped(
                        labelText: 'Status',
                        mappedItems: CrmLeadsController.activityStatuses,
                        initialValue: activity.status,
                        onChanged: (value) =>
                            controller.setLeadActivityStatus(activity, value),
                      ),
                      AppFormTextField(
                        controller: activity.activityDateTimeController,
                        labelText: 'Activity Date Time',
                        hintText: 'Date and time',
                        keyboardType: TextInputType.datetime,
                        inputFormatters: const [DateTimeInputFormatter()],
                        enabled: !controller.isSelectedLeadReadOnly,
                      ),
                      AppFormTextField(
                        controller: activity.nextFollowupController,
                        labelText: 'Next Follow-up',
                        hintText: 'Date and time',
                        keyboardType: TextInputType.datetime,
                        inputFormatters: const [DateTimeInputFormatter()],
                        enabled: !controller.isSelectedLeadReadOnly,
                      ),
                      AppFormTextField(
                        controller: activity.notesController,
                        labelText: 'Notes',
                        maxLines: 2,
                        enabled: !controller.isSelectedLeadReadOnly,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        if (!controller.isSelectedLeadReadOnly) ...[
          const SizedBox(height: AppUiConstants.spacingMd),
          Wrap(
            spacing: AppUiConstants.spacingSm,
            runSpacing: AppUiConstants.spacingSm,
            children: [
              AppActionButton(
                icon: Icons.save_outlined,
                label: controller.selectedItem == null
                    ? 'Save Lead'
                    : 'Update Lead',
                onPressed: controller.save,
                busy: controller.saving,
              ),
            ],
          ),
        ],
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
