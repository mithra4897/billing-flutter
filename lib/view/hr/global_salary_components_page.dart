import '../../controller/hr/global_salary_component_controller.dart';
import '../../screen.dart';

// ─── Dropdown option lists ──────────────────────────────────────────────────

const List<AppDropdownItem<String>> _componentTypeItems =
    <AppDropdownItem<String>>[
      AppDropdownItem(value: 'earning', label: 'Earning'),
      AppDropdownItem(value: 'deduction', label: 'Deduction'),
    ];

const List<AppDropdownItem<String>> _componentRoleItems =
    <AppDropdownItem<String>>[
      AppDropdownItem(value: 'standard', label: 'Standard component'),
      AppDropdownItem(value: 'derived_gross', label: 'Derived gross (summary)'),
      AppDropdownItem(value: 'derived_net', label: 'Derived net (summary)'),
    ];

const List<AppDropdownItem<String>> _calculationItems =
    <AppDropdownItem<String>>[
      AppDropdownItem(value: 'fixed', label: 'Fixed amount'),
      AppDropdownItem(value: 'percent_basic', label: '% of basic'),
      AppDropdownItem(value: 'percent_gross', label: '% of gross'),
      AppDropdownItem(value: 'percent_ctc', label: '% of CTC'),
      AppDropdownItem(
        value: 'percent_epf_wage',
        label: 'PF: % of EPF wage (configured ceiling)',
      ),
      AppDropdownItem(
        value: 'percent_basic_da_ceil',
        label: 'ESI: % of Basic + DA (configured eligibility limit)',
      ),
    ];

const List<AppDropdownItem<String>> _contributionRoleItems =
    <AppDropdownItem<String>>[
      AppDropdownItem(value: 'employee', label: 'Employee (payslip)'),
      AppDropdownItem(value: 'employer', label: 'Employer (CTC cost)'),
    ];

// ─── Page ──────────────────────────────────────────────────────────────────

class GlobalSalaryComponentsPage extends StatefulWidget {
  const GlobalSalaryComponentsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<GlobalSalaryComponentsPage> createState() =>
      _GlobalSalaryComponentsPageState();
}

class _GlobalSalaryComponentsPageState
    extends State<GlobalSalaryComponentsPage> {
  late final String _controllerTag;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag('GlobalSalaryComponentController');
    if (Get.isRegistered<GlobalSalaryComponentController>(
      tag: _controllerTag,
    )) {
      Get.find<GlobalSalaryComponentController>(
        tag: _controllerTag,
      ).loadComponents();
    } else {
      Get.put(GlobalSalaryComponentController(), tag: _controllerTag);
    }
  }

  @override
  void dispose() {
    if (Get.isRegistered<GlobalSalaryComponentController>(
      tag: _controllerTag,
    )) {
      Get.delete<GlobalSalaryComponentController>(
        tag: _controllerTag,
        force: true,
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<GlobalSalaryComponentController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = _buildContent(controller);
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () =>
                controller.startNew(isDesktop: Responsive.isDesktop(context)),
            icon: Icons.payments_outlined,
            label: 'New Component',
          ),
        ];

        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }

        return AppStandaloneShell(
          title: 'Salary Components',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(GlobalSalaryComponentController controller) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading salary components...');
    }

    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load salary components',
        message: controller.pageError!,
        onRetry: controller.loadComponents,
      );
    }

    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Salary Components',
      editorTitle: controller.selectedComponent?.componentName,
      scrollController: controller.pageScrollController,
      wrapEditorInCard: false,
      list: SettingsListCard<GlobalSalaryComponentModel>(
        searchController: controller.searchController,
        searchHint: 'Search components',
        items: controller.filteredComponents,
        selectedItem: controller.selectedComponent,
        emptyMessage: 'No salary components found.',
        paginationMeta: controller.paginationMeta,
        onPageChanged: controller.goToPage,
        itemBuilder: (item, selected) {
          final detail = _componentDetailLine(item);
          return SettingsListTile(
            title: item.componentName ?? '-',
            subtitle: [
              if ((item.componentType ?? '').isNotEmpty) item.componentType!,
              if ((item.contributionRole ?? '').isNotEmpty)
                item.contributionRole!,
            ].join(' • '),
            detail: detail.isEmpty ? null : detail,
            selected: selected,
            onTap: () => controller.selectComponent(item),
            trailing: SettingsStatusPill(
              label: item.isActive ? 'Active' : 'Inactive',
              active: item.isActive,
            ),
          );
        },
      ),
      editorBuilder: (_) => _buildEditorPanel(controller),
    );
  }

  String _componentDetailLine(GlobalSalaryComponentModel item) {
    final parts = <String>[];
    final calc = item.calculationBasis ?? 'fixed';
    if (calc == 'fixed') {
      final amt = item.amount;
      if (amt != null) parts.add('₹${amt.toStringAsFixed(2)}');
    } else {
      final pct = item.percentValue;
      if (pct != null) parts.add('${pct.toStringAsFixed(2)}%');
    }
    if (item.sortOrder != null) parts.add('Order: ${item.sortOrder}');
    return parts.join(' • ');
  }

  Widget _buildEditorPanel(GlobalSalaryComponentController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Inline error message ──────────────────────────────────
                if (controller.formError != null) ...[
                  AppErrorStateView.inline(message: controller.formError!),
                  const SizedBox(height: AppUiConstants.spacingSm),
                ],

                // ── Info banner: Sort Order guidance ─────────────────────
                _SortOrderInfoBanner(),

                const SizedBox(height: AppUiConstants.spacingMd),

                // ── Form fields ──────────────────────────────────────────
                SettingsFormWrap(
                  children: [
                    AppFormTextField(
                      controller: controller.nameController,
                      labelText: 'Component Name',
                      validator: Validators.compose([
                        Validators.required('Component Name'),
                        Validators.optionalMaxLength(100, 'Component Name'),
                      ]),
                    ),
                    AppDropdownField<String>.fromMapped(
                      labelText: 'Component Type',
                      mappedItems: _componentTypeItems,
                      initialValue: controller.componentType,
                      onChanged: (v) =>
                          controller.setComponentType(v ?? 'earning'),
                    ),
                    AppDropdownField<String>.fromMapped(
                      labelText: 'Component Role',
                      mappedItems: _componentRoleItems,
                      initialValue: controller.componentRole,
                      onChanged: (v) =>
                          controller.setComponentRole(v ?? 'standard'),
                    ),
                    AppDropdownField<String>.fromMapped(
                      labelText: 'Calculation',
                      mappedItems: _calculationItems,
                      initialValue: controller.calculationBasis,
                      onChanged: (v) =>
                          controller.setCalculationBasis(v ?? 'fixed'),
                    ),
                    AppDropdownField<String>.fromMapped(
                      labelText: 'Contribution',
                      mappedItems: _contributionRoleItems,
                      initialValue: controller.contributionRole,
                      onChanged: (v) =>
                          controller.setContributionRole(v ?? 'employee'),
                    ),
                    if (controller.calculationBasis != 'fixed')
                      AppFormTextField(
                        controller: controller.percentController,
                        labelText: 'Default Percentage (%)',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: Validators.compose([
                          Validators.required('Percentage'),
                          Validators.optionalNonNegativeNumber('Percentage'),
                        ]),
                      ),
                    AppFormTextField(
                      controller: controller.amountController,
                      labelText: controller.calculationBasis == 'fixed'
                          ? 'Default Amount'
                          : 'Default Amount (optional)',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: controller.calculationBasis == 'fixed'
                          ? Validators.compose([
                              Validators.required('Amount'),
                              Validators.optionalNonNegativeNumber('Amount'),
                            ])
                          : Validators.optionalNonNegativeNumber('Amount'),
                    ),
                    // ── Sort Order (manual number input) ────────────────
                    AppFormTextField(
                      controller: controller.sortOrderController,
                      labelText: 'Sort Order (Payslip Row Order)',
                      keyboardType: TextInputType.number,
                      validator: Validators.compose([
                        Validators.required('Sort Order'),
                        Validators.optionalNonNegativeInteger('Sort Order'),
                      ]),
                    ),
                  ],
                ),

                const SizedBox(height: AppUiConstants.spacingMd),

                AppSwitchTile(
                  label: 'Active',
                  value: controller.isActive,
                  onChanged: controller.setIsActive,
                ),

                const SizedBox(height: AppUiConstants.spacingLg),

                // ── Action buttons ────────────────────────────────────────
                Wrap(
                  spacing: AppUiConstants.spacingSm,
                  runSpacing: AppUiConstants.spacingSm,
                  children: [
                    AppActionButton(
                      icon: Icons.save_outlined,
                      label: controller.selectedComponent == null
                          ? 'Save Component'
                          : 'Update Component',
                      busy: controller.saving,
                      onPressed: controller.saving
                          ? null
                          : () => controller.save(
                              formState: _formKey.currentState,
                            ),
                    ),
                    if (controller.selectedComponent?.id != null)
                      AppActionButton(
                        icon: Icons.delete_outline,
                        label: 'Delete',
                        onPressed: controller.saving ? null : controller.delete,
                        busy: controller.saving,
                        filled: false,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Informational Banner ──────────────────────────────────────────────────

class _SortOrderInfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppUiConstants.spacingMd),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: colorScheme.primary,
          ),
          const SizedBox(width: AppUiConstants.spacingSm),
          Expanded(
            child: Text(
              'Components defined here apply to all employees. '
              'Set the "Sort Order" number to control the row order on '
              'every payslip (e.g. 1 = first row, 2 = second row). '
              'Percentages are defaults — each employee\'s actual amount '
              'is calculated on payroll.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
