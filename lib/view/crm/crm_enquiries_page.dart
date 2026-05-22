import '../../controller/crm/crm_enquiries_controller.dart';
import '../../screen.dart';

void _openCrmShellRoute(BuildContext context, String route) {
  final navigate = ShellRouteScope.maybeOf(context);
  if (navigate != null) {
    navigate(route);
    return;
  }
  Navigator.of(context).pushNamed(route);
}

class CrmEnquiriesPage extends StatefulWidget {
  const CrmEnquiriesPage({
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
  State<CrmEnquiriesPage> createState() => _CrmEnquiriesPageState();
}

class _CrmEnquiriesPageState extends State<CrmEnquiriesPage>
    with SingleTickerProviderStateMixin {
  late final String _controllerTag;
  late final CrmEnquiriesController _controller;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'CrmEnquiriesController',
      scope: <String, Object?>{
        'widget': widget.runtimeType,
        'key': widget.key,
        'state': identityHashCode(this),
      },
    );
    _controller = Get.put(
      CrmEnquiriesController(
        startInNewMode: widget.startInNewMode,
        initialSelectId: widget.initialSelectId,
      ),
      tag: _controllerTag,
    );
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _controller.setActiveTabIndex(_tabController.index);
      }
    });
  }

  @override
  void didUpdateWidget(covariant CrmEnquiriesPage oldWidget) {
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
    if (Get.isRegistered<CrmEnquiriesController>(tag: _controllerTag)) {
      Get.delete<CrmEnquiriesController>(tag: _controllerTag);
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
    return GetBuilder<CrmEnquiriesController>(
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
            onPressed: () =>
                _openCrmShellRoute(context, '/crm/opportunities/new'),
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
    CrmEnquiriesController controller,
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
                          labelText: 'Customer',
                          initialValue:
                              controller.filterCustomerPartyId ??
                              CrmEnquiriesController.allFilterIntValue,
                          mappedItems: <AppDropdownItem<int>>[
                            const AppDropdownItem<int>(
                              value: CrmEnquiriesController.allFilterIntValue,
                              label: 'All',
                            ),
                            ...controller.customers
                                .where((item) => item.id != null)
                                .map(
                                  (item) => AppDropdownItem<int>(
                                    value: item.id!,
                                    label: item.toString(),
                                  ),
                                ),
                          ],
                          onChanged: controller.setFilterCustomerPartyId,
                        ),
                      ),
                      _filterBox(
                        child: AppDropdownField<int>.fromMapped(
                          labelText: 'Stage',
                          initialValue:
                              controller.filterStageId ??
                              CrmEnquiriesController.allFilterIntValue,
                          mappedItems: <AppDropdownItem<int>>[
                            const AppDropdownItem<int>(
                              value: CrmEnquiriesController.allFilterIntValue,
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
                        child: AppDropdownField<int>.fromMapped(
                          labelText: 'Assigned To',
                          initialValue:
                              controller.filterAssignedTo ??
                              CrmEnquiriesController.allFilterIntValue,
                          mappedItems: <AppDropdownItem<int>>[
                            const AppDropdownItem<int>(
                              value: CrmEnquiriesController.allFilterIntValue,
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
                              controller.filterEnquiryStatus ??
                              CrmEnquiriesController.allFilterStringValue,
                          mappedItems: <AppDropdownItem<String>>[
                            const AppDropdownItem<String>(
                              value:
                                  CrmEnquiriesController.allFilterStringValue,
                              label: 'All',
                            ),
                            ...CrmEnquiriesController.filterStatusItems,
                          ],
                          onChanged: controller.setFilterEnquiryStatus,
                        ),
                      ),
                      _filterBox(
                        child: AppFormTextField(
                          controller: controller.filterDateFromController,
                          labelText: 'Date From',
                          hintText: 'YYYY-MM-DD',
                          keyboardType: TextInputType.datetime,
                          inputFormatters: const [DateInputFormatter()],
                        ),
                      ),
                      _filterBox(
                        child: AppFormTextField(
                          controller: controller.filterDateToController,
                          labelText: 'Date To',
                          hintText: 'YYYY-MM-DD',
                          keyboardType: TextInputType.datetime,
                          inputFormatters: const [DateInputFormatter()],
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
    if (applied == true) controller.applySearch();
  }

  Future<void> _pickEnquiryDate(
    BuildContext context,
    CrmEnquiriesController controller,
  ) async {
    final now = DateTime.now();
    final selected = await showAppDatePickerDialog(
      context: context,
      title: 'Select Opportunity Date',
      initialDate:
          tryParseCalendarDate(controller.enquiryDateController.text) ?? now,
      firstDate: DateTime(now.year - 5, 1, 1),
      lastDate: DateTime(now.year + 5, 12, 31),
    );
    if (selected == null) return;
    controller.enquiryDateController.text = formatCalendarDate(selected);
    controller.update();
  }

  Future<void> _pickFollowupDate(
    BuildContext context,
    CrmEnquiriesController controller,
    FollowupDraft followup,
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
    CrmEnquiriesController controller,
    FollowupDraft followup,
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

  void _openNewLeadForm(
    BuildContext context,
    CrmEnquiriesController controller,
    String query,
  ) {
    final leadName = query.trim();
    final route = Uri(
      path: '/crm/leads/new',
      queryParameters: <String, String>{
        if (leadName.isNotEmpty) 'lead_name': leadName,
        if (controller.companyId != null)
          'company_id': controller.companyId.toString(),
      },
    ).toString();
    _openCrmShellRoute(context, route);
  }

  Widget _buildContent(
    BuildContext context,
    CrmEnquiriesController controller,
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

    // Migrated page/form state now lives in CrmEnquiriesController.
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
              controller.filterCustomerPartyId != null ||
              controller.filterStageId != null ||
              controller.filterAssignedTo != null ||
              (controller.filterEnquiryStatus ?? '').isNotEmpty ||
              controller.filtersApplied ||
              controller.filterDateFromController.text.trim().isNotEmpty ||
              controller.filterDateToController.text.trim().isNotEmpty)
            const SizedBox(height: AppUiConstants.spacingMd),
          SettingsListCard<CrmEnquiryModel>(
            searchController: controller.searchController,
            searchHint: 'Search opportunities',
            items: controller.filteredItems,
            selectedItem: controller.selectedItem,
            emptyMessage: 'No CRM opportunities found.',
            itemBuilder: (item, selected) {
              final data = item.toJson();
              final id = intValue(data, 'id');
              return SettingsListTile(
                title: item.toString(),
                subtitle: [
                  displayDate(nullableStringValue(data, 'enquiry_date')),
                  controller.lifecycleStatusLabel(
                    stringValue(data, 'status') == 'won'
                        ? 'won'
                        : stringValue(data, 'enquiry_status'),
                  ),
                ].where((value) => value.isNotEmpty).join(' • '),
                selected: selected,
                onTap: () {
                  if (id == null) {
                    return;
                  }
                  _openCrmShellRoute(context, '/crm/opportunities/$id');
                },
                detail: stringValue(data, 'remarks'),
                trailing: SettingsStatusPill(
                  label: controller.lifecycleStatusLabel(
                    stringValue(data, 'status') == 'won'
                        ? 'won'
                        : stringValue(data, 'enquiry_status', 'open'),
                  ),
                  active:
                      (stringValue(data, 'status') == 'won'
                          ? 'won'
                          : stringValue(data, 'enquiry_status', 'open')) !=
                      'lost',
                ),
              );
            },
          ),
        ],
      ),
      editor: Form(
        child: Builder(
          builder: (formContext) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TabBar(
                controller: _tabController,
                onTap: controller.setActiveTabIndex,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Primary'),
                  Tab(text: 'Lines'),
                  Tab(text: 'Followups'),
                ],
              ),
              const SizedBox(height: AppUiConstants.spacingMd),
              IndexedStack(
                index: controller.activeTabIndex,
                children: [
                  _buildPrimaryTab(context, controller, formContext),
                  controller.selectedItem?.toJson()['id'] == null
                      ? _buildDependentTabPlaceholder(
                          title: 'Lines',
                          message:
                              'Save this opportunity first to manage requested items and descriptions.',
                        )
                      : _buildLinesTab(context, controller, formContext),
                  controller.selectedItem?.toJson()['id'] == null
                      ? _buildDependentTabPlaceholder(
                          title: 'Followups',
                          message:
                              'Save this opportunity first to manage follow-up dates, notes, and next actions.',
                        )
                      : _buildFollowupsTab(context, controller, formContext),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppliedFilters(
    BuildContext context,
    CrmEnquiriesController controller,
  ) {
    final chips = <String>[
      if (controller.searchController.text.trim().isNotEmpty)
        'Search: ${controller.searchController.text.trim()}',
      if (controller.filterCustomerPartyId != null || controller.filtersApplied)
        'Customer: ${controller.filterCustomerPartyId == null ? 'All' : controller.customers.cast<PartyModel?>().firstWhere((item) => item?.id == controller.filterCustomerPartyId, orElse: () => null)?.toString() ?? controller.filterCustomerPartyId}',
      if (controller.filterStageId != null || controller.filtersApplied)
        'Stage: ${controller.filterStageId == null ? 'All' : controller.stages.cast<CrmStageModel?>().firstWhere((item) => intValue(item?.toJson() ?? const {}, "id") == controller.filterStageId, orElse: () => null)?.toString() ?? controller.filterStageId}',
      if (controller.filterAssignedTo != null || controller.filtersApplied)
        'Assigned: ${controller.filterAssignedTo == null ? 'All' : controller.users.cast<UserModel?>().firstWhere((item) => item?.id == controller.filterAssignedTo, orElse: () => null)?.displayName ?? controller.users.cast<UserModel?>().firstWhere((item) => item?.id == controller.filterAssignedTo, orElse: () => null)?.username ?? controller.filterAssignedTo}',
      if ((controller.filterEnquiryStatus ?? '').isNotEmpty ||
          controller.filtersApplied)
        'Status: ${(controller.filterEnquiryStatus ?? CrmEnquiriesController.allFilterStringValue) == CrmEnquiriesController.allFilterStringValue ? 'All' : controller.filterEnquiryStatus}',
      if (controller.filterDateFromController.text.trim().isNotEmpty)
        'From: ${controller.filterDateFromController.text.trim()}',
      if (controller.filterDateToController.text.trim().isNotEmpty)
        'To: ${controller.filterDateToController.text.trim()}',
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

  Widget _buildPrimaryTab(
    BuildContext context,
    CrmEnquiriesController controller,
    BuildContext formContext,
  ) {
    final isLocked = controller.isSelectedEnquiryLocked();
    final lifecycleStatus = controller.effectiveLifecycleStatus();
    final canWin =
        controller.selectedItem != null &&
        !isLocked &&
        lifecycleStatus == 'in_progress' &&
        controller.opportunityStatus != 'won';
    final canLose = controller.selectedItem != null && !isLocked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          if (controller.formError != null) ...[
            AppErrorStateView.inline(message: controller.formError!),
            const SizedBox(height: AppUiConstants.spacingSm),
          ],
          if (intValue(controller.selectedItem?.toJson() ?? const {}, 'id') !=
              null) ...[
            CrmSalesPipelineBar(
              data: controller.salesChain,
              hideEnquiryChip: true,
              hideOpportunityChip: true,
            ),
            if (!isLocked && controller.pipelineOpportunityId() != null) ...[
              AppActionButton(
                icon: Icons.request_quote_outlined,
                label: 'New quotation (this deal)',
                filled: false,
                onPressed: () => openModuleShellRoute(
                  context,
                  '/sales/quotations/new?crm_opportunity_id=${controller.pipelineOpportunityId()}',
                ),
              ),
              const SizedBox(height: AppUiConstants.spacingSm),
            ],
          ],
          AbsorbPointer(
            absorbing: isLocked,
            child: SettingsFormWrap(
              children: [
                AppFormTextField(
                  controller: controller.enquiryNoController,
                  labelText: 'Opportunity No',
                  hintText: 'Leave blank - we assign a number for you',
                ),
                AppDateSelectorField(
                  controller: controller.enquiryDateController,
                  labelText: 'Opportunity Date',
                  onTap: () => _pickEnquiryDate(context, controller),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: ErpLinkField<int>(
                    labelText: 'Lead',
                    doctypeLabel: 'Lead',
                    allowCreate: true,
                    hintText: 'Search or create lead',
                    initialSelection: controller.selectedLeadOption(),
                    search: controller.searchLeadOptions,
                    onNavigateToCreateNew: (query) =>
                        _openNewLeadForm(context, controller, query),
                    onChanged: controller.setLeadId,
                  ),
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
                  onChanged: controller.setAssignedTo,
                ),
                AppFormTextField(
                  key: ValueKey<String>(
                    'opportunity-status-${controller.effectiveLifecycleStatus()}',
                  ),
                  labelText: 'Status',
                  initialValue: controller.lifecycleStatusLabel(),
                  readOnly: true,
                  enabled: false,
                ),
                AppFormTextField(
                  controller: controller.remarksController,
                  labelText: 'Remarks',
                  maxLines: 3,
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
                  onPressed: () => controller.save(formContext),
                  busy: controller.saving,
                ),
              if (controller.selectedItem != null) ...[
                if (!isLocked)
                  AppActionButton(
                    icon: Icons.trending_up_outlined,
                    label: 'Won',
                    filled: false,
                    onPressed: canWin ? controller.win : null,
                  ),
                if (!isLocked)
                  AppActionButton(
                    icon: Icons.cancel_outlined,
                    label: 'Lost',
                    filled: false,
                    onPressed: canLose ? controller.lose : null,
                  ),
                AppActionButton(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  filled: false,
                  onPressed: controller.delete,
                ),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildLinesTab(
    BuildContext context,
    CrmEnquiriesController controller,
    BuildContext formContext,
  ) {
    final isLocked = controller.isSelectedEnquiryLocked();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Requested Items',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            AppActionButton(
              icon: Icons.add_outlined,
              label: 'Add Line',
              filled: false,
              onPressed: isLocked ? null : controller.addLine,
            ),
          ],
        ),
        const SizedBox(height: AppUiConstants.spacingSm),
        if (controller.lines.isEmpty)
          const SettingsEmptyState(
            icon: Icons.playlist_add_check_outlined,
            title: 'No Lines',
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
                      : () => controller.removeLine(index),
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
        if (!isLocked) ...[
          const SizedBox(height: AppUiConstants.spacingMd),
          AppActionButton(
            icon: Icons.save_outlined,
            label: controller.selectedItem == null
                ? 'Save Opportunity'
                : 'Update Opportunity',
            onPressed: () => controller.save(formContext),
            busy: controller.saving,
          ),
        ],
      ],
    );
  }

  Widget _buildFollowupsTab(
    BuildContext context,
    CrmEnquiriesController controller,
    BuildContext formContext,
  ) {
    final isLocked = controller.isSelectedEnquiryLocked();
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
                      : () => controller.removeFollowup(index),
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
                        mappedItems: CrmEnquiriesController.followupStatuses,
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
        if (!isLocked) ...[
          const SizedBox(height: AppUiConstants.spacingMd),
          AppActionButton(
            icon: Icons.save_outlined,
            label: controller.selectedItem == null
                ? 'Save Opportunity'
                : 'Update Opportunity',
            onPressed: () => controller.save(formContext),
            busy: controller.saving,
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
