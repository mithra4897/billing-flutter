import '../../../controller/settings/accounting/financial_reports_controller.dart';
import '../../../screen.dart';

class FinancialReportsPage extends StatefulWidget {
  const FinancialReportsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<FinancialReportsPage> createState() => _FinancialReportsPageState();
}

class _FinancialReportsPageState extends State<FinancialReportsPage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag('FinancialReportsController');
    Get.put(FinancialReportsController(), tag: _controllerTag);
  }

  Future<void> _openFilterPanel(
    BuildContext context,
    FinancialReportsController controller,
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
              child: Form(
                key: controller.reportFilterFormKey,
                child: GetBuilder<FinancialReportsController>(
                  tag: _controllerTag,
                  builder: (dialogController) => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Filter Financial Reports',
                              style: Theme.of(dialogContext).textTheme.titleLarge
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
                      _buildFilterFields(dialogContext, dialogController),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            onPressed: () {
                              if (dialogController.reportFilterFormKey
                                      .currentState
                                      ?.validate() !=
                                  true) {
                                return;
                              }
                              Navigator.of(dialogContext).pop(true);
                            },
                            icon: const Icon(Icons.play_arrow_outlined),
                            label: const Text('Run Report'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              dialogController.clearFilters();
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
            ),
          ),
        );
      },
    );

    if (applied == true) {
      controller.runReport();
    }
  }

  List<Widget> _buildShellActions(
    BuildContext context,
    FinancialReportsController controller,
  ) {
    return [
      AdaptiveShellActionButton(
        onPressed: controller.loading
            ? null
            : () => _openFilterPanel(context, controller),
        icon: Icons.filter_alt_outlined,
        label: 'Filter',
        filled: false,
      ),
      AdaptiveShellActionButton(
        onPressed: controller.loading || controller.report == null
            ? null
            : controller.copyReportTsv,
        icon: Icons.copy_outlined,
        label: 'Copy TSV',
        filled: false,
      ),
      AdaptiveShellActionButton(
        onPressed: controller.loading ? null : controller.runReport,
        icon: Icons.assessment_outlined,
        label: 'Run Report',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FinancialReportsController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = _buildContent(context, controller);
        if (widget.embedded) {
          return ShellPageActions(
            actions: _buildShellActions(context, controller),
            child: content,
          );
        }

        return AppStandaloneShell(
          title: 'Financial Reports',
          scrollController: controller.pageScrollController,
          actions: _buildShellActions(context, controller),
          child: content,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    FinancialReportsController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading report lookups...');
    }
    if (controller.error != null && controller.report == null) {
      return AppErrorStateView(
        title: 'Unable to prepare reports',
        message: controller.error!,
        onRetry: controller.loadLookups,
      );
    }

    return SingleChildScrollView(
      controller: controller.pageScrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.error != null) ...[
            AppErrorStateView.inline(message: controller.error!),
            const SizedBox(height: AppUiConstants.spacingMd),
          ],
          AppSectionCard(
            child: controller.report == null
                ? const SettingsEmptyState(
                    icon: Icons.bar_chart_outlined,
                    title: 'Run a report',
                    message:
                        'Choose report filters above and run the report to see accounting output.',
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        FinancialReportsController.reportItems
                            .firstWhere(
                              (item) => item.value == controller.reportType,
                              orElse: () => const AppDropdownItem(
                                value: '',
                                label: 'Report',
                              ),
                            )
                            .label,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppUiConstants.spacingMd),
                      FinancialReportViews.buildBody(
                        context,
                        controller.reportType,
                        controller.report!.data,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterFields(
    BuildContext context,
    FinancialReportsController controller,
  ) {
    return SettingsFormWrap(
      children: [
        AppDropdownField<String>.fromMapped(
          labelText: 'Report',
          mappedItems: FinancialReportsController.reportItems,
          initialValue: controller.reportType,
          onChanged: controller.setReportType,
        ),
        if (controller.needsDayBookBranch)
          AppDropdownField<int?>.fromMapped(
            labelText: 'Branch (optional)',
            mappedItems: controller.branchFilterItems,
            initialValue: controller.dayBookBranchId,
            onChanged: controller.setDayBookBranchId,
          ),
        if (controller.needsAccount)
          AppDropdownField<int>.fromMapped(
            labelText: 'Account',
            mappedItems: controller.accountOptions
                .where((item) => item.id != null)
                .map((item) {
                  final subtitle = <String>[
                    if ((item.accountCode ?? '').trim().isNotEmpty)
                      item.accountCode!.trim(),
                    if ((item.accountType ?? '').trim().isNotEmpty)
                      item.accountType!.trim(),
                    if ((item.accountGroupName ?? '').trim().isNotEmpty)
                      item.accountGroupName!.trim(),
                  ].join(' | ');
                  final searchText = <String>[
                    item.accountName ?? '',
                    item.accountCode ?? '',
                    item.accountType ?? '',
                    item.accountGroupName ?? '',
                  ].join(' ');
                  return AppDropdownItem(
                    value: item.id!,
                    label: item.accountName?.trim().isNotEmpty == true
                        ? item.accountName!.trim()
                        : item.toString(),
                    subtitle: subtitle.isEmpty ? null : subtitle,
                    searchText: searchText,
                  );
                })
                .toList(growable: false),
            initialValue: controller.accountId,
            onChanged: controller.setAccountId,
          ),
        if (controller.needsParty)
          AppDropdownField<int?>.fromMapped(
            labelText: 'Party',
            mappedItems: controller.partyFilterItems,
            initialValue: controller.partyId,
            onChanged: controller.setPartyId,
          ),
        if (controller.usesDateRange)
          AppFormTextField(
            labelText: 'Date From',
            controller: controller.dateFromController,
            keyboardType: TextInputType.datetime,
            inputFormatters: const [DateInputFormatter()],
            validator: controller.usesStrictReportDateRange
                ? Validators.compose([
                    Validators.required('Date From'),
                    Validators.date('Date From'),
                  ])
                : Validators.optionalDate('Date From'),
          ),
        if (controller.usesDateRange)
          AppFormTextField(
            labelText: 'Date To',
            controller: controller.dateToController,
            keyboardType: TextInputType.datetime,
            inputFormatters: const [DateInputFormatter()],
            validator: Validators.compose([
              Validators.optionalDate('Date To'),
              Validators.optionalDateOnOrAfter(
                'Date To',
                () => controller.dateFromController.text.trim(),
                startFieldName: 'Date From',
              ),
            ]),
          ),
        if (controller.usesAsOfDate)
          AppFormTextField(
            labelText: 'As Of Date',
            controller: controller.asOfDateController,
            keyboardType: TextInputType.datetime,
            inputFormatters: const [DateInputFormatter()],
            validator: Validators.optionalDate('As Of Date'),
          ),
      ],
    );
  }
}
