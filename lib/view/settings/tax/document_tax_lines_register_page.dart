import '../../../controller/settings/tax/document_tax_lines_register_management_controller.dart';
import '../../../screen.dart';

class DocumentTaxLinesRegisterPage extends StatefulWidget {
  const DocumentTaxLinesRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<DocumentTaxLinesRegisterPage> createState() =>
      _DocumentTaxLinesRegisterPageState();
}

class _DocumentTaxLinesRegisterPageState
    extends State<DocumentTaxLinesRegisterPage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'DocumentTaxLinesRegisterManagementController',
    );
    Get.put(
      DocumentTaxLinesRegisterManagementController(),
      tag: _controllerTag,
    );
  }

  Future<void> _openFilterPanel(
    DocumentTaxLinesRegisterManagementController controller,
  ) async {
    final fyItems = <AppDropdownItem<int?>>[
      const AppDropdownItem<int?>(value: null, label: 'All financial years'),
      ...controller.financialYearOptions.map(
        (FinancialYearModel year) => AppDropdownItem<int?>(
          value: year.id,
          label: year.fyName?.isNotEmpty == true
              ? year.fyName!
              : (year.fyCode ?? 'FY'),
        ),
      ),
    ];

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
                builder: (context, setDialogState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Filter Document Tax Lines',
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
                            child: AppDropdownField<int?>.fromMapped(
                              labelText: 'Financial year',
                              mappedItems: fyItems,
                              initialValue: controller.financialYearId,
                              onChanged: (value) => setDialogState(
                                () => controller.setFinancialYearId(value),
                              ),
                            ),
                          ),
                          _filterBox(
                            child: AppFormTextField(
                              controller: controller.dateFromController,
                              labelText: 'From',
                              hintText: 'YYYY-MM-DD',
                              keyboardType: TextInputType.datetime,
                              inputFormatters: const [DateInputFormatter()],
                            ),
                          ),
                          _filterBox(
                            child: AppFormTextField(
                              controller: controller.dateToController,
                              labelText: 'To',
                              hintText: 'YYYY-MM-DD',
                              keyboardType: TextInputType.datetime,
                              inputFormatters: const [DateInputFormatter()],
                            ),
                          ),
                          _filterBox(
                            child: AppFormTextField(
                              controller: controller.searchController,
                              labelText: 'Search',
                              hintText: 'Document no. / HSN',
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
      await controller.fetch(resetPage: true);
    }
  }

  List<Widget> _buildShellActions(
    DocumentTaxLinesRegisterManagementController controller,
  ) {
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
        onPressed: controller.loading
            ? null
            : () => controller.fetch(resetPage: true),
        icon: Icons.refresh_outlined,
        label: 'Refresh',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DocumentTaxLinesRegisterManagementController>(
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
          title: 'Document tax lines',
          scrollController: controller.pageScrollController,
          actions: _buildShellActions(controller),
          child: content,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    DocumentTaxLinesRegisterManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading tax lines...');
    }
    if (controller.pageError != null &&
        controller.rows.isEmpty &&
        !controller.loading) {
      return AppErrorStateView(
        title: 'Unable to load document tax lines',
        message: controller.pageError!,
        onRetry: controller.bootstrap,
      );
    }

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
          ReportPaginationBar(
            meta: controller.effectiveMeta,
            onPerPageChanged: (value) {
              controller.setPerPage(value);
              controller.fetch(resetPage: true);
            },
            onPageChanged: (value) {
              controller.setPage(value);
              controller.fetch();
            },
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          AppSectionCard(
            child: controller.loading && controller.rows.isEmpty
                ? const AppLoadingView(message: 'Loading...')
                : controller.rows.isEmpty
                ? const SettingsEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No tax lines',
                    message:
                        'No document tax lines match the filters for this company.',
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
                            dataRowMaxHeight: 64,
                            columns: const [
                              DataColumn(label: Text('Date')),
                              DataColumn(label: Text('Document')),
                              DataColumn(label: Text('Module')),
                              DataColumn(label: Text('Taxable')),
                              DataColumn(label: Text('CGST')),
                              DataColumn(label: Text('SGST')),
                              DataColumn(label: Text('IGST')),
                              DataColumn(label: Text('CESS')),
                              DataColumn(label: Text('Item')),
                              DataColumn(label: Text('Tax code')),
                            ],
                            rows: controller.rows
                                .map((DocumentTaxLineModel row) {
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          controller.cell(row, 'document_date'),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          controller.cell(row, 'document_no'),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          controller.cell(
                                            row,
                                            'document_module',
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          controller.cell(
                                            row,
                                            'taxable_amount',
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          controller.cell(row, 'cgst_amount'),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          controller.cell(row, 'sgst_amount'),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          controller.cell(row, 'igst_amount'),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          controller.cell(row, 'cess_amount'),
                                        ),
                                      ),
                                      DataCell(Text(controller.itemLabel(row))),
                                      DataCell(Text(controller.taxLabel(row))),
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
