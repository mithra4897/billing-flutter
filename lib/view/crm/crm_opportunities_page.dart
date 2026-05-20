import '../../controller/crm/crm_opportunities_controller.dart';
import '../../screen.dart';

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
    _controllerTag =
        persistentControllerTag('CrmOpportunitiesController');
    _controller = Get.put(
      CrmOpportunitiesController(
        startInNewMode: widget.startInNewMode,
        initialSelectId: widget.initialSelectId,
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
              controller.resetForm();
              if (!Responsive.isDesktop(context)) {
                controller.workspaceController.openEditor();
              }
            },
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
                          initialValue: controller.filterStageId ??
                              CrmOpportunitiesController.allFilterIntValue,
                          mappedItems: <AppDropdownItem<int>>[
                            const AppDropdownItem<int>(
                              value: CrmOpportunitiesController.allFilterIntValue,
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
                          initialValue: controller.filterStatus ??
                              CrmOpportunitiesController.allFilterStringValue,
                          mappedItems: <AppDropdownItem<String>>[
                            const AppDropdownItem<String>(
                              value: CrmOpportunitiesController.allFilterStringValue,
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
              controller.filterEnquiryId != null ||
              controller.filterStageId != null ||
              (controller.filterStatus ?? '').isNotEmpty ||
              controller.filtersApplied ||
              controller.filterCloseFromController.text.trim().isNotEmpty ||
              controller.filterCloseToController.text.trim().isNotEmpty)
            const SizedBox(height: AppUiConstants.spacingMd),
          SettingsListCard<CrmOpportunityModel>(
            searchController: controller.searchController,
            searchHint: 'Search opportunities',
            items: controller.filteredItems,
            selectedItem: controller.selectedItem,
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
                onTap: () => controller.selectItem(item),
                trailing: SettingsStatusPill(
                  label: stringValue(data, 'status', 'open'),
                  active: stringValue(data, 'status', 'open') != 'lost',
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
            tabs: const [Tab(text: 'Primary'), Tab(text: 'Products')],
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          IndexedStack(
            index: controller.activeTabIndex,
            children: [
              _buildPrimaryTab(context, controller),
              controller.selectedItem?.toJson()['id'] == null
                  ? _buildDependentTabPlaceholder(
                      title: 'Products',
                      message:
                          'Save this opportunity first to manage item-wise products, quantities, and prices.',
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
      if (controller.filterEnquiryId != null)
        'Enquiry: ${controller.enquiries.cast<CrmEnquiryModel?>().firstWhere((item) => intValue(item?.toJson() ?? const {}, "id") == controller.filterEnquiryId, orElse: () => null)?.toString() ?? controller.filterEnquiryId}',
      if (controller.filterStageId != null || controller.filtersApplied)
        'Stage: ${controller.filterStageId == null ? 'All' : controller.stages.cast<CrmStageModel?>().firstWhere((item) => intValue(item?.toJson() ?? const {}, "id") == controller.filterStageId, orElse: () => null)?.toString() ?? controller.filterStageId}',
      if ((controller.filterStatus ?? '').isNotEmpty || controller.filtersApplied)
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

  Widget _filterBox({required Widget child}) => SizedBox(width: 240, child: child);

  Widget _buildPrimaryTab(
    BuildContext context,
    CrmOpportunitiesController controller,
  ) {
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
            CrmSalesPipelineBar(data: controller.salesChain, hideOpportunityChip: true),
            AppActionButton(
              icon: Icons.request_quote_outlined,
              label: 'New quotation (this deal)',
              filled: false,
              onPressed: () => openModuleShellRoute(
                context,
                '/sales/quotations/new?crm_opportunity_id=${controller.selectedOpportunityId()}',
              ),
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
          ],
          SettingsFormWrap(
            children: [
              AppDropdownField<int>.fromMapped(
                labelText: 'Enquiry',
                mappedItems: controller.enquiries
                    .where((item) => intValue(item.toJson(), 'id') != null)
                    .map(
                      (item) => AppDropdownItem(
                        value: intValue(item.toJson(), 'id')!,
                        label: item.toString(),
                      ),
                    )
                    .toList(growable: false),
                initialValue: controller.enquiryId,
                onChanged: controller.setEnquiryId,
              ),
              AppFormTextField(
                controller: controller.nameController,
                labelText: 'Opportunity Name',
                validator: Validators.required('Opportunity Name'),
              ),
              AppFormTextField(
                controller: controller.expectedValueController,
                labelText: 'Expected Value',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              AppFormTextField(
                controller: controller.expectedCloseDateController,
                labelText: 'Expected Close Date',
                keyboardType: TextInputType.datetime,
                inputFormatters: const [DateInputFormatter()],
              ),
              AppFormTextField(
                labelText: 'Status',
                initialValue: controller.status.replaceAll('_', ' '),
                readOnly: true,
                enabled: false,
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
                label: controller.selectedItem == null
                    ? 'Save Opportunity'
                    : 'Update Opportunity',
                onPressed: controller.save,
                busy: controller.saving,
              ),
              if (controller.selectedItem != null) ...[
                AppActionButton(
                  icon: Icons.emoji_events_outlined,
                  label: 'Won',
                  filled: false,
                  onPressed: controller.win,
                ),
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
                  onPressed: controller.delete,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab(
    BuildContext context,
    CrmOpportunitiesController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Products',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            AppActionButton(
              icon: Icons.add_outlined,
              label: 'Add Product',
              filled: false,
              onPressed: controller.addProduct,
            ),
          ],
        ),
        const SizedBox(height: AppUiConstants.spacingSm),
        if (controller.products.isEmpty)
          const SettingsEmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'No Products',
            message: 'Add item-wise deal products, quantity, and estimated price.',
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
                  onPressed: () => controller.removeProduct(index),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline),
                ),
                onToggle: () =>
                    controller.setExpandedProductIndex(expanded ? null : index),
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
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    AppFormTextField(
                      controller: product.estimatedPriceController,
                      labelText: 'Estimated Price',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
              label: controller.selectedItem == null
                  ? 'Save Opportunity'
                  : 'Update Opportunity',
              onPressed: controller.save,
              busy: controller.saving,
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
