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
  const CrmLeadRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<CrmLeadRegisterPage> createState() => _CrmLeadRegisterPageState();
}

class _CrmLeadRegisterPageState extends State<CrmLeadRegisterPage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag('CrmLeadRegisterController');
    Get.put(CrmLeadRegisterController(), tag: _controllerTag);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CrmLeadRegisterController>(
      tag: _controllerTag,
      builder: (controller) {
        return PurchaseRegisterPage<CrmLeadModel>(
          title: 'CRM Leads',
          embedded: widget.embedded,
          loading: controller.loading,
          errorMessage: controller.error,
          onRetry: controller.load,
          emptyMessage: 'No CRM leads yet. Create a new lead to get started.',
          actions: [
            AdaptiveShellActionButton(
              onPressed: () => _openCrmShellRoute(context, '/crm/leads/new'),
              icon: Icons.add_outlined,
              label: 'New lead',
            ),
          ],
          filters: _CrmLeadRegisterFilters(
            searchController: controller.searchController,
            status: controller.status,
            statusItems: CrmLeadRegisterController.statusItems,
            onStatusChanged: controller.setStatus,
          ),
          rows: controller.filteredRows,
          columns: [
            PurchaseRegisterColumn<CrmLeadModel>(
              label: 'Lead',
              flex: 3,
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
              label: 'Email',
              flex: 3,
              valueBuilder: (row) => stringValue(row.toJson(), 'email'),
            ),
            PurchaseRegisterColumn<CrmLeadModel>(
              label: 'Status',
              valueBuilder: (row) => controller.statusLabel(
                stringValue(row.toJson(), 'lead_status'),
              ),
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
}

class _CrmLeadRegisterFilters extends StatelessWidget {
  const _CrmLeadRegisterFilters({
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
          hintText: 'Search lead, company, mobile, or email',
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

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag('CrmLeadsController');
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CrmLeadsController>(
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
            onPressed: () => _openCrmShellRoute(context, '/crm/leads/new'),
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
                          'Filter CRM Leads',
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
                          labelText: 'Source',
                          initialValue:
                              controller.filterSourceId ??
                              CrmLeadsController.allFilterIntValue,
                          mappedItems: <AppDropdownItem<int>>[
                            const AppDropdownItem<int>(
                              value: CrmLeadsController.allFilterIntValue,
                              label: 'All',
                            ),
                            ...controller.sources
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
                          onChanged: controller.setFilterSourceId,
                        ),
                      ),
                      _filterBox(
                        child: AppDropdownField<int>.fromMapped(
                          labelText: 'Assigned To',
                          initialValue:
                              controller.filterAssignedTo ??
                              CrmLeadsController.allFilterIntValue,
                          mappedItems: <AppDropdownItem<int>>[
                            const AppDropdownItem<int>(
                              value: CrmLeadsController.allFilterIntValue,
                              label: 'All',
                            ),
                            ...controller.users
                                .where((item) => item.id != null)
                                .map(
                                  (item) => AppDropdownItem<int>(
                                    value: item.id!,
                                    label:
                                        item.displayName ?? item.username ?? '',
                                  ),
                                ),
                          ],
                          onChanged: controller.setFilterAssignedTo,
                        ),
                      ),
                      _filterBox(
                        child: AppDropdownField<String>.fromMapped(
                          labelText: 'Status',
                          initialValue:
                              controller.filterLeadStatus ??
                              CrmLeadsController.allFilterStringValue,
                          mappedItems: <AppDropdownItem<String>>[
                            const AppDropdownItem<String>(
                              value: CrmLeadsController.allFilterStringValue,
                              label: 'All',
                            ),
                            ...CrmLeadsController.leadFilterStatuses,
                          ],
                          onChanged: controller.setFilterLeadStatus,
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
              controller.filterSourceId != null ||
              controller.filterAssignedTo != null ||
              (controller.filterLeadStatus ?? '').isNotEmpty ||
              controller.filtersApplied)
            const SizedBox(height: AppUiConstants.spacingMd),
          SettingsListCard<CrmLeadModel>(
            searchController: controller.searchController,
            searchHint: 'Search leads',
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
                trailing: SettingsStatusPill(
                  label: controller.leadStatusLabel(
                    stringValue(data, 'lead_status', 'new'),
                  ),
                  active: stringValue(data, 'lead_status', 'new') != 'lost',
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
          IndexedStack(
            index: controller.activeTabIndex,
            children: [
              _buildPrimaryTab(context, controller),
              controller.selectedItem?.toJson()['id'] == null
                  ? _buildDependentTabPlaceholder(
                      title: 'Activities',
                      message:
                          'Save this lead first to manage calls, emails, meetings, and follow-up notes.',
                    )
                  : _buildActivitiesTab(context, controller),
            ],
          ),
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
      if (controller.filterSourceId != null || controller.filtersApplied)
        'Source: ${controller.filterSourceId == null ? 'All' : controller.sources.cast<CrmSourceModel?>().firstWhere((item) => intValue(item?.toJson() ?? const {}, "id") == controller.filterSourceId, orElse: () => null)?.toString() ?? controller.filterSourceId}',
      if (controller.filterAssignedTo != null || controller.filtersApplied)
        'Assigned: ${controller.filterAssignedTo == null ? 'All' : controller.users.cast<UserModel?>().firstWhere((item) => item?.id == controller.filterAssignedTo, orElse: () => null)?.displayName ?? controller.users.cast<UserModel?>().firstWhere((item) => item?.id == controller.filterAssignedTo, orElse: () => null)?.username ?? controller.filterAssignedTo}',
      if ((controller.filterLeadStatus ?? '').isNotEmpty ||
          controller.filtersApplied)
        'Status: ${(controller.filterLeadStatus ?? CrmLeadsController.allFilterStringValue) == CrmLeadsController.allFilterStringValue ? 'All' : controller.leadStatusLabel(controller.filterLeadStatus)}',
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
                      ? 'This lead is converted. Details are read-only. Open the linked opportunity to continue the sales process.'
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
                  if (controller.selectedItem != null &&
                      !controller.isSelectedLeadReadOnly) ...[
                    AppActionButton(
                      icon: Icons.forward_outlined,
                      label: 'Create Opportunity',
                      onPressed: () async {
                        final existing =
                            controller.opportunityIdFromSalesChain() ??
                            controller.enquiryIdFromSalesChain();
                        if (existing != null) {
                          _openCrmShellRoute(
                            context,
                            '/crm/opportunities/$existing',
                          );
                          return;
                        }
                        final created = await controller.convert(
                          createEnquiry: true,
                        );
                        if (created != null && context.mounted) {
                          _openCrmShellRoute(
                            context,
                            '/crm/opportunities/$created',
                          );
                        }
                      },
                    ),
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
                      label: 'Open Opportunity',
                      onPressed: () => _openCrmShellRoute(
                        context,
                        '/crm/opportunities/${controller.opportunityIdFromSalesChain() ?? controller.enquiryIdFromSalesChain()}',
                      ),
                    ),
                  if (controller.selectedItem != null)
                    AppActionButton(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      filled: false,
                      onPressed: controller.delete,
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
              padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
              child: SettingsExpandableTile(
                title: activity.activityTypeLabel,
                subtitle: [
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
                      AppFormTextField(
                        controller: activity.activityDateTimeController,
                        labelText: 'Activity Date Time',
                        hintText: 'YYYY-MM-DD HH:MM:SS',
                        keyboardType: TextInputType.datetime,
                        inputFormatters: const [DateTimeInputFormatter()],
                        enabled: !controller.isSelectedLeadReadOnly,
                      ),
                      AppFormTextField(
                        controller: activity.nextFollowupController,
                        labelText: 'Next Follow-up',
                        hintText: 'YYYY-MM-DD HH:MM:SS',
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
