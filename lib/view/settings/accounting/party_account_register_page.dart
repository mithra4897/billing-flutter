import '../../../controller/settings/accounting/party_account_register_controller.dart';
import '../../../screen.dart';

class PartyAccountRegisterPage extends StatefulWidget {
  const PartyAccountRegisterPage({
    super.key,
    this.embedded = false,
    this.initialPartyId,
  });

  final bool embedded;
  final int? initialPartyId;

  @override
  State<PartyAccountRegisterPage> createState() =>
      _PartyAccountRegisterPageState();
}

class _PartyAccountRegisterPageState extends State<PartyAccountRegisterPage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag('PartyAccountRegisterController');
    Get.put(
      PartyAccountRegisterController(initialPartyId: widget.initialPartyId),
      tag: _controllerTag,
    );
  }

  @override
  void didUpdateWidget(covariant PartyAccountRegisterPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPartyId != widget.initialPartyId) {
      Get.find<PartyAccountRegisterController>(
        tag: _controllerTag,
      ).syncInitialPartyId(widget.initialPartyId);
    }
  }

  List<Widget> _buildShellActions(PartyAccountRegisterController controller) {
    return [
      AdaptiveShellActionButton(
        onPressed: controller.loading
            ? null
            : () => _openFilterPanel(controller),
        icon: Icons.filter_alt_outlined,
        label: 'Filter',
        filled: false,
      ),
      AdaptiveShellActionButton(
        onPressed: controller.saving
            ? null
            : () => controller.startNewMapping(
                preferredPartyId: widget.initialPartyId,
              ),
        icon: Icons.add_outlined,
        label: 'New mapping',
        filled: false,
      ),
      AdaptiveShellActionButton(
        onPressed: controller.loading
            ? null
            : () => controller.fetch(resetPage: true),
        icon: Icons.refresh_outlined,
        label: 'Refresh',
        filled: false,
      ),
    ];
  }

  Future<void> _openFilterPanel(
    PartyAccountRegisterController controller,
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
              child: StatefulBuilder(
                builder: (filterContext, setDialogState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Filter Party Accounts',
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
                            child: AppFormTextField(
                              controller: controller.searchController,
                              labelText: 'Search',
                              hintText: 'Party or account',
                            ),
                          ),
                          _filterBox(
                            child: AppDropdownField<String?>.fromMapped(
                              labelText: 'Purpose',
                              mappedItems: PartyAccountRegisterController
                                  .accountPurposeFilterItems,
                              initialValue: controller.filterPurpose,
                              onChanged: (value) => setDialogState(
                                () => controller.setFilterPurpose(value),
                              ),
                            ),
                          ),
                          _filterBox(
                            child: AppDropdownField<bool?>.fromMapped(
                              labelText: 'Active',
                              mappedItems: PartyAccountRegisterController
                                  .activeFilterItems,
                              initialValue: controller.filterActive,
                              onChanged: (value) => setDialogState(
                                () => controller.setFilterActive(value),
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
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(true),
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
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    if (applied == true) {
      await controller.loadAccountsForCompany();
      await controller.fetch(resetPage: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PartyAccountRegisterController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = _buildContent(context, controller);
        if (widget.embedded) {
          return ShellPageActions(
            actions: _buildShellActions(controller),
            child: content,
          );
        }
        return AppStandaloneShell(
          title: 'Party account register',
          scrollController: controller.pageScrollController,
          actions: _buildShellActions(controller),
          child: content,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    PartyAccountRegisterController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading party accounts...');
    }
    if (controller.pageError != null && controller.rows.isEmpty) {
      return AppErrorStateView(
        title: 'Unable to load party accounts',
        message: controller.pageError!,
        onRetry: controller.bootstrap,
      );
    }

    final partyItems = controller.parties
        .where((item) => item.id != null)
        .map(
          (item) => AppDropdownItem<int>(
            value: item.id!,
            label: [
              item.displayName ?? item.partyName ?? '',
              if ((item.partyCode ?? '').isNotEmpty) item.partyCode!,
            ].where((value) => value.isNotEmpty).join(' · '),
          ),
        )
        .toList(growable: false);

    final accountItems = controller.accounts
        .map(
          (item) => AppDropdownItem<int>(
            value: item.id!,
            label: [
              item.accountName ?? '',
              if ((item.accountCode ?? '').isNotEmpty) item.accountCode!,
            ].where((value) => value.isNotEmpty).join(' · '),
          ),
        )
        .toList(growable: false);

    return SingleChildScrollView(
      controller: controller.pageScrollController,
      padding: const EdgeInsets.all(AppUiConstants.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.pageError != null) ...[
            AppErrorStateView.inline(message: controller.pageError!),
            const SizedBox(height: AppUiConstants.spacingMd),
          ],
          AppSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.editing == null ? 'New mapping' : 'Edit mapping',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppUiConstants.spacingSm),
                Text(
                  'Choose a company in filters so the correct ledgers appear. Mappings are saved against the selected party and account.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (controller.formError != null) ...[
                  const SizedBox(height: AppUiConstants.spacingMd),
                  AppErrorStateView.inline(message: controller.formError!),
                ],
                const SizedBox(height: AppUiConstants.spacingMd),
                if (controller.companyId == null)
                  const Text(
                    'Select a company to enable account selection and saving.',
                  )
                else if (!controller.canEdit)
                  const Text('You do not have permission to change mappings.')
                else
                  Form(
                    key: controller.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SettingsFormWrap(
                          children: [
                            AppDropdownField<int>.fromMapped(
                              labelText: 'Party',
                              mappedItems: partyItems,
                              initialValue: controller.formPartyId,
                              onChanged: controller.setFormPartyId,
                              validator: Validators.requiredSelection('Party'),
                            ),
                            AppDropdownField<int>.fromMapped(
                              labelText: 'Account',
                              mappedItems: accountItems,
                              initialValue: controller.formAccountId,
                              onChanged: controller.setFormAccountId,
                              validator: Validators.requiredSelection(
                                'Account',
                              ),
                            ),
                            AppDropdownField<String>.fromMapped(
                              labelText: 'Purpose',
                              mappedItems: PartyAccountRegisterController
                                  .accountPurposeItems,
                              initialValue: controller.formPurpose,
                              onChanged: controller.setFormPurpose,
                              validator: Validators.requiredSelection(
                                'Purpose',
                              ),
                            ),
                            AppFormTextField(
                              labelText: 'Remarks',
                              controller: controller.remarksController,
                              maxLines: 3,
                              validator: Validators.optionalMaxLength(
                                1000,
                                'Remarks',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppUiConstants.spacingMd),
                        Wrap(
                          spacing: AppUiConstants.spacingMd,
                          runSpacing: AppUiConstants.spacingSm,
                          children: [
                            AppSwitchTile(
                              label: 'Default for purpose',
                              value: controller.formDefault,
                              onChanged: controller.setFormDefault,
                            ),
                            AppSwitchTile(
                              label: 'Active',
                              value: controller.formActive,
                              onChanged: controller.setFormActive,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppUiConstants.spacingLg),
                        Row(
                          children: [
                            if (controller.editing?.id != null &&
                                controller.canDelete)
                              TextButton(
                                onPressed: controller.saving
                                    ? null
                                    : controller.deleteMapping,
                                child: const Text('Delete'),
                              ),
                            const Spacer(),
                            FilledButton.icon(
                              onPressed:
                                  (controller.saving || !controller.canEdit)
                                  ? null
                                  : controller.saveMapping,
                              icon: const Icon(Icons.save_outlined),
                              label: Text(
                                controller.saving ? 'Saving…' : 'Save',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          ReportPaginationBar(
            meta: controller.effectiveMeta,
            onPerPageChanged: controller.setPerPage,
            onPageChanged: controller.setPage,
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          AppSectionCard(
            child: controller.loading && controller.rows.isEmpty
                ? const AppLoadingView(message: 'Loading...')
                : controller.rows.isEmpty
                ? const SettingsEmptyState(
                    icon: Icons.link_outlined,
                    title: 'No mappings',
                    message:
                        'No rows match the filters. Add a mapping with the form above.',
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: constraints.maxWidth,
                          ),
                          child: DataTable(
                            headingRowHeight: 40,
                            dataRowMinHeight: 40,
                            dataRowMaxHeight: 56,
                            columns: const [
                              DataColumn(label: Text('Party')),
                              DataColumn(label: Text('Account')),
                              DataColumn(label: Text('Purpose')),
                              DataColumn(label: Text('Default')),
                              DataColumn(label: Text('Active')),
                              DataColumn(label: Text('')),
                            ],
                            rows: controller.rows
                                .map((row) {
                                  final partyLabel =
                                      row.partyName?.isNotEmpty == true
                                      ? row.partyName!
                                      : (row.partyCode ?? '-');
                                  final accountLabel =
                                      row.accountName?.isNotEmpty == true
                                      ? row.accountName!
                                      : (row.accountCode ?? '-');
                                  final selected =
                                      controller.editing?.id == row.id;
                                  return DataRow(
                                    selected: selected,
                                    cells: [
                                      DataCell(Text(partyLabel)),
                                      DataCell(Text(accountLabel)),
                                      DataCell(Text(row.accountPurpose ?? '-')),
                                      DataCell(
                                        Text(row.isDefault ? 'Yes' : 'No'),
                                      ),
                                      DataCell(
                                        Text(row.isActive ? 'Yes' : 'No'),
                                      ),
                                      DataCell(
                                        IconButton(
                                          tooltip: 'Edit',
                                          icon: const Icon(Icons.edit_outlined),
                                          onPressed: () =>
                                              controller.editRow(row),
                                        ),
                                      ),
                                    ],
                                  );
                                })
                                .toList(growable: false),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterBox({required Widget child}) {
    return SizedBox(width: 240, child: child);
  }
}
