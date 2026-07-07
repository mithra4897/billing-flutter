import '../../../controller/settings/accounting/budget_management_controller.dart';
import '../../../screen.dart';

class BudgetManagementPage extends StatefulWidget {
  const BudgetManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<BudgetManagementPage> createState() => _BudgetManagementPageState();
}

class _BudgetManagementPageState extends State<BudgetManagementPage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'BudgetManagementController',
      scope: <String, Object?>{
        'identity': identityHashCode(this),
        'embedded': widget.embedded,
      },
    );
    _registerController();
  }

  @override
  void dispose() {
    if (Get.isRegistered<BudgetManagementController>(tag: _controllerTag)) {
      Get.delete<BudgetManagementController>(tag: _controllerTag, force: true);
    }
    super.dispose();
  }

  void _registerController() {
    if (Get.isRegistered<BudgetManagementController>(tag: _controllerTag)) {
      return;
    }
    Get.put(BudgetManagementController(), tag: _controllerTag);
  }

  Future<void> _showBudgetVsActual(
    BuildContext context,
    BudgetManagementController controller,
  ) async {
    final navigator = Navigator.of(context);
    try {
      final response = await controller.loadBudgetVsActual();
      final data = response?.toJson() ?? const <String, dynamic>{};
      if (!mounted) {
        return;
      }
      final summary = (data['summary'] as Map?) ?? {};
      final lineList = (data['lines'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList(growable: false);
      await showDialog<void>(
        context: navigator.context,
        builder: (dialogContext) {
          final theme = Theme.of(dialogContext);
          final extension = theme.extension<AppThemeExtension>()!;
          return AlertDialog(
            title: const Text('Budget vs actual'),
            content: SizedBox(
              width: AppUiConstants.pagePaddingLarge * 12,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Budget: ${summary['budget_amount']} · Actual: ${summary['actual_amount']} · Variance: ${summary['variance_amount']}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppUiConstants.spacingSm),
                    if (lineList.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppUiConstants.spacingLg,
                        ),
                        child: Text(
                          'No budget lines available for comparison.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: extension.mutedText,
                          ),
                        ),
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowHeight: 52,
                          dataRowMinHeight: 56,
                          dataRowMaxHeight: 64,
                          columns: const [
                            DataColumn(label: Text('Account')),
                            DataColumn(numeric: true, label: Text('Budget')),
                            DataColumn(numeric: true, label: Text('Actual')),
                            DataColumn(numeric: true, label: Text('Variance')),
                            DataColumn(
                              numeric: true,
                              label: Text('Utilization %'),
                            ),
                          ],
                          rows: lineList
                              .map(
                                (row) => DataRow(
                                  cells: [
                                    DataCell(
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          minWidth: 240,
                                          maxWidth: 320,
                                        ),
                                        child: Text(
                                          '${row['account_code'] ?? ''} ${row['account_name'] ?? ''}'
                                              .trim(),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      _BudgetVsAmountCell(
                                        value: '${row['budget_amount'] ?? ''}',
                                      ),
                                    ),
                                    DataCell(
                                      _BudgetVsAmountCell(
                                        value: '${row['actual_amount'] ?? ''}',
                                      ),
                                    ),
                                    DataCell(
                                      _BudgetVsAmountCell(
                                        value:
                                            '${row['variance_amount'] ?? ''}',
                                        emphasizeNegative: true,
                                      ),
                                    ),
                                    DataCell(
                                      _BudgetVsAmountCell(
                                        value:
                                            '${row['utilization_percent'] ?? ''}',
                                        suffix: '%',
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } catch (errorValue) {
      if (!mounted) {
        return;
      }
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(errorValue.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BudgetManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = _buildContent(context, controller);
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () => controller.startNewBudget(
              isDesktop: Responsive.isDesktop(context),
            ),
            icon: Icons.savings_outlined,
            label: 'New Budget',
          ),
        ];

        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }

        return AppStandaloneShell(
          title: 'Budgets',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    BudgetManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading budgets...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load',
        message: controller.pageError!,
        onRetry: controller.loadPage,
      );
    }
    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Budgets',
      editorTitle:
          stringValue(
            controller.json(controller.selectedBudget),
            'budget_name',
          ).isEmpty
          ? null
          : stringValue(
              controller.json(controller.selectedBudget),
              'budget_name',
            ),
      scrollController: controller.pageScrollController,
      list: SettingsListCard<BudgetModel>(
        searchController: controller.searchController,
        searchHint: 'Search budgets',
        items: controller.filteredRows,
        selectedItem: controller.selectedBudget,
        emptyMessage: 'No budgets.',
        itemBuilder: (item, selected) {
          final data = item.toJson();
          return SettingsListTile(
            title: stringValue(data, 'budget_name'),
            subtitle: [
              stringValue(data, 'budget_code'),
              stringValue(data, 'budget_status'),
            ].join(' · '),
            selected: selected,
            onTap: () => controller.selectBudget(item),
          );
        },
      ),
      editorBuilder: (_) => Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (controller.formError != null) ...[
              AppErrorStateView.inline(message: controller.formError!),
              const SizedBox(height: AppUiConstants.spacingSm),
            ],
            SettingsFormWrap(
              children: [
                AppFormTextField(
                  labelText: 'Budget code',
                  controller: controller.codeController,
                  validator: Validators.compose([
                    Validators.required('Code'),
                    Validators.optionalMaxLength(100, 'Code'),
                  ]),
                ),
                AppFormTextField(
                  labelText: 'Budget name',
                  controller: controller.nameController,
                  validator: Validators.compose([
                    Validators.required('Name'),
                    Validators.optionalMaxLength(255, 'Name'),
                  ]),
                ),
                AppFormTextField(
                  labelText: 'Date from',
                  controller: controller.dateFromController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.compose([
                    Validators.required('Date from'),
                    Validators.date('Date from'),
                  ]),
                ),
                AppFormTextField(
                  labelText: 'Date to',
                  controller: controller.dateToController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.compose([
                    Validators.required('Date to'),
                    Validators.date('Date to'),
                    Validators.optionalDateOnOrAfter(
                      'Date to',
                      () => controller.dateFromController.text.trim(),
                      startFieldName: 'Date from',
                    ),
                  ]),
                ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Status',
                  mappedItems: BudgetManagementController.statusItems,
                  initialValue: controller.status,
                  onChanged: controller.setStatus,
                ),
                AppFormTextField(
                  labelText: 'Notes',
                  controller: controller.notesController,
                  maxLines: 3,
                ),
                SizedBox(
                  width: AppUiConstants.switchFieldWidth,
                  child: AppSwitchTile(
                    label: 'Active',
                    value: controller.isActive,
                    onChanged: controller.setIsActive,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            Row(
              children: [
                Text(
                  'Budget lines',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                AppActionButton(
                  icon: Icons.add_outlined,
                  label: 'Add line',
                  onPressed: controller.addLine,
                  filled: false,
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
            ...List<Widget>.generate(controller.lines.length, (index) {
              final line = controller.lines[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Line ${index + 1}'),
                          const Spacer(),
                          IconButton(
                            onPressed: controller.lines.length == 1
                                ? null
                                : () => controller.removeLine(index),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                      AppDropdownField<int>.fromMapped(
                        labelText: 'Account',
                        mappedItems: controller.accounts
                            .where((item) => item.id != null)
                            .map(
                              (item) => AppDropdownItem<int>(
                                value: item.id!,
                                label: item.toString(),
                              ),
                            )
                            .toList(growable: false),
                        initialValue: line.accountId,
                        onChanged: (value) =>
                            controller.setLineAccountId(index, value),
                        validator: Validators.requiredSelection('Account'),
                      ),
                      AppFormTextField(
                        labelText: 'Budget amount',
                        controller: line.amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: Validators.compose([
                          Validators.required('Amount'),
                        ]),
                      ),
                      AppFormTextField(
                        labelText: 'Remarks',
                        controller: line.remarksController,
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: AppUiConstants.spacingLg),
            Wrap(
              spacing: AppUiConstants.spacingSm,
              runSpacing: AppUiConstants.spacingSm,
              children: [
                AppActionButton(
                  icon: Icons.save_outlined,
                  label:
                      intValue(
                            controller.json(controller.selectedBudget),
                            'id',
                          ) ==
                          null
                      ? 'Save'
                      : 'Update',
                  onPressed: controller.saveBudget,
                  busy: controller.saving,
                ),
                if (intValue(
                      controller.json(controller.selectedBudget),
                      'id',
                    ) !=
                    null) ...[
                  AppActionButton(
                    icon: Icons.compare_arrows_outlined,
                    label: 'Vs actual',
                    onPressed: controller.saving
                        ? null
                        : () => _showBudgetVsActual(context, controller),
                    filled: false,
                  ),
                  AppActionButton(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    onPressed: controller.saving
                        ? null
                        : controller.deleteBudget,
                    filled: false,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetVsAmountCell extends StatelessWidget {
  const _BudgetVsAmountCell({
    required this.value,
    this.suffix = '',
    this.emphasizeNegative = false,
  });

  final String value;
  final String suffix;
  final bool emphasizeNegative;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parsed = double.tryParse(value.trim());
    final isNegative = emphasizeNegative && (parsed ?? 0) < 0;
    final displayValue = value.trim().isEmpty
        ? ''
        : suffix.isEmpty
        ? value
        : '$value$suffix';

    return Text(
      displayValue,
      style: theme.textTheme.bodySmall?.copyWith(
        color: isNegative
            ? theme.colorScheme.error
            : theme.colorScheme.onSurface,
        fontWeight: isNegative ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}
