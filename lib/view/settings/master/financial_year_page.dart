import '../../../controller/settings/master/financial_year_management_controller.dart';
import '../../../screen.dart';

class FinancialYearManagementPage extends StatefulWidget {
  const FinancialYearManagementPage({
    super.key,
    this.embedded = false,
    this.fixedCompanyId,
  });

  final bool embedded;
  final int? fixedCompanyId;

  @override
  State<FinancialYearManagementPage> createState() =>
      _FinancialYearManagementPageState();
}

class _FinancialYearManagementPageState
    extends State<FinancialYearManagementPage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        persistentControllerTag('FinancialYearManagementController');
    Get.put(
      FinancialYearManagementController(
        embedded: widget.embedded,
        fixedCompanyId: widget.fixedCompanyId,
      ),
      tag: _controllerTag,
    permanent: true,
    );
  }

  @override
  void didUpdateWidget(covariant FinancialYearManagementPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fixedCompanyId != widget.fixedCompanyId) {
      Get.find<FinancialYearManagementController>(
        tag: _controllerTag,
      ).updateFixedCompanyId(widget.fixedCompanyId);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FinancialYearManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () => controller.startNewFinancialYear(
              isDesktop: Responsive.isDesktop(context),
            ),
            icon: Icons.add_outlined,
            label: 'New Financial Year',
          ),
        ];
        if (controller.initialLoading) {
          return const AppLoadingView(message: 'Loading financial years...');
        }
        if (controller.pageError != null) {
          return AppErrorStateView(
            title: 'Unable to load financial years',
            message: controller.pageError!,
            onRetry: controller.loadData,
          );
        }

        if (widget.embedded) {
          return ShellPageActions(
            actions: actions,
            child: _buildEmbeddedContent(context, controller),
          );
        }

        return AppStandaloneShell(
          title: 'Financial Years',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: SettingsWorkspace(
            controller: controller.workspaceController,
            title: 'Financial Years',
            editorTitle: controller.selectedFinancialYear?.toString(),
            scrollController: controller.pageScrollController,
            list: _buildListCard(controller),
            editorBuilder: (_) => _buildEditor(context, controller),
          ),
        );
      },
    );
  }

  Widget _buildListCard(FinancialYearManagementController controller) {
    return SettingsListCard<FinancialYearModel>(
      searchController: controller.searchController,
      searchHint: 'Search financial years',
      items: controller.filteredFinancialYears,
      selectedItem: controller.selectedFinancialYear,
      emptyMessage: controller.fixedCompanyId == null
          ? 'No financial years found.'
          : 'No financial years found for this company.',
      itemBuilder: (item, selected) => SettingsListTile(
        title: item.fyName ?? item.fyCode ?? '',
        subtitle: [
          item.fyCode ?? '',
          if (controller.fixedCompanyId == null)
            item.companyName ??
                companyNameById(controller.companies, item.companyId),
          if ((item.startDate ?? '').isNotEmpty ||
              (item.endDate ?? '').isNotEmpty)
            '${item.startDate ?? ''} to ${item.endDate ?? ''}'.trim(),
        ].where((value) => value.trim().isNotEmpty).join(' • '),
        selected: selected,
        trailing: SettingsStatusPill(
          label: item.isCurrent ? 'Current' : (item.isActive ? 'Active' : 'Inactive'),
          active: item.isCurrent || item.isActive,
        ),
        onTap: () => controller.selectFinancialYear(item),
      ),
    );
  }

  Widget _buildEditor(
    BuildContext context,
    FinancialYearManagementController controller,
  ) {
    // Migrated page/form state now lives in FinancialYearManagementController.
    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.formError != null) ...[
            AppErrorStateView.inline(message: controller.formError!),
            const SizedBox(height: 16),
          ],
          SettingsFormWrap(
            children: [
              if (widget.fixedCompanyId == null)
                AppDropdownField<int>.fromMapped(
                  labelText: 'Company',
                  initialValue: controller.companyId,
                  mappedItems: controller.companies
                      .where((company) => company.id != null)
                      .map(
                        (company) => AppDropdownItem<int>(
                          value: company.id!,
                          label: company.toString(),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: controller.setCompanyId,
                  validator: Validators.requiredSelection('Company'),
                ),
              AppFormTextField(
                controller: controller.fyCodeController,
                labelText: 'FY Code',
                readOnly: true,
                validator: Validators.compose([
                  Validators.required('FY code'),
                  Validators.optionalMaxLength(20, 'FY code'),
                ]),
              ),
              AppFormTextField(
                controller: controller.fyNameController,
                labelText: 'FY Name',
                readOnly: true,
                validator: Validators.compose([
                  Validators.required('FY name'),
                  Validators.optionalMaxLength(50, 'FY name'),
                ]),
              ),
              AppFormTextField(
                controller: controller.startDateController,
                labelText: 'Start Date',
                hintText: 'YYYY-MM-DD',
                inputFormatters: const [DateInputFormatter()],
                validator: Validators.compose([
                  Validators.required('Start date'),
                  Validators.optionalDate('Start date'),
                ]),
              ),
              AppFormTextField(
                controller: controller.endDateController,
                labelText: 'End Date',
                hintText: 'YYYY-MM-DD',
                inputFormatters: const [DateInputFormatter()],
                validator: Validators.compose([
                  Validators.required('End date'),
                  Validators.optionalDateOnOrAfter(
                    'End date',
                    () => controller.startDateController.text,
                    startFieldName: 'Start date',
                  ),
                ]),
              ),
              AppFormTextField(
                controller: controller.lockDateController,
                labelText: 'Lock Date',
                hintText: 'YYYY-MM-DD',
                inputFormatters: const [DateInputFormatter()],
                validator: Validators.optionalDate('Lock date'),
              ),
              AppFormTextField(
                controller: controller.remarksController,
                labelText: 'Remarks',
                maxLines: 3,
                validator: Validators.optionalMaxLength(1000, 'Remarks'),
              ),
            ],
          ),
          AppSwitchTile(
            label: 'Current Financial Year',
            subtitle: 'Only one financial year can stay current per company.',
            value: controller.isCurrent,
            onChanged: controller.setIsCurrent,
          ),
          AppSwitchTile(
            label: 'Locked',
            subtitle: 'Use this when entries should no longer be posted.',
            value: controller.isLocked,
            onChanged: controller.setIsLocked,
          ),
          AppSwitchTile(
            label: 'Active',
            value: controller.isCurrent ? true : controller.isActive,
            onChanged: controller.isCurrent ? null : controller.setIsActive,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              AppActionButton(
                icon: Icons.save_outlined,
                label: controller.selectedFinancialYear == null
                    ? 'Create Financial Year'
                    : 'Update Financial Year',
                onPressed: controller.saving ? null : controller.save,
                busy: controller.saving,
              ),
              if (controller.selectedFinancialYear?.id != null &&
                  controller.selectedFinancialYear?.isCurrent != true)
                AppActionButton(
                  icon: Icons.check_circle_outline,
                  label: 'Set Current',
                  onPressed: controller.activating ? null : controller.setAsCurrent,
                  busy: controller.activating,
                  filled: false,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmbeddedContent(
    BuildContext context,
    FinancialYearManagementController controller,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppUiConstants.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.filteredFinancialYears.isEmpty &&
              !controller.showDraftTile &&
              controller.selectedFinancialYear == null)
            const SettingsEmptyState(
              icon: Icons.calendar_month_outlined,
              title: 'No Financial Years',
              message: 'No financial years found for this company yet.',
              minHeight: 160,
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (controller.showDraftTile &&
                    controller.selectedFinancialYear == null) ...[
                  SettingsExpandableTile(
                    key: const ValueKey('fy-draft'),
                    title: 'New Financial Year',
                    subtitle: 'Create a financial year for this company.',
                    expanded: true,
                    highlighted: true,
                    leadingIcon: Icons.add_outlined,
                    onToggle: controller.hideDraftTile,
                    child: _buildEditor(context, controller),
                  ),
                  if (controller.filteredFinancialYears.isNotEmpty)
                    const SizedBox(height: AppUiConstants.spacingSm),
                ],
                ...controller.filteredFinancialYears.map((item) {
                  final expanded = identical(item, controller.selectedFinancialYear);
                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppUiConstants.spacingSm,
                    ),
                    child: SettingsExpandableTile(
                      key: ValueKey('fy-${item.id}-$expanded'),
                      title: item.fyName ?? item.fyCode ?? '-',
                      subtitle: [
                        item.fyCode ?? '',
                        if ((item.startDate ?? '').isNotEmpty ||
                            (item.endDate ?? '').isNotEmpty)
                          '${item.startDate ?? ''} to ${item.endDate ?? ''}'
                              .trim(),
                      ].where((value) => value.trim().isNotEmpty).join(' • '),
                      detail: item.isCurrent
                          ? 'Current'
                          : (item.isActive ? 'Active' : 'Inactive'),
                      expanded: expanded,
                      highlighted: expanded,
                      trailing: SettingsStatusPill(
                        label: item.isCurrent
                            ? 'Current'
                            : (item.isActive ? 'Active' : 'Inactive'),
                        active: item.isCurrent || item.isActive,
                      ),
                      onToggle: () => controller.toggleEmbeddedSelection(item),
                      child: _buildEditor(context, controller),
                    ),
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }
}
