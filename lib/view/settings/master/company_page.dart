import '../../../controller/settings/master/company_management_controller.dart';
import '../../../screen.dart';

class CompanyManagementPage extends StatefulWidget {
  const CompanyManagementPage({
    super.key,
    this.embedded = false,
    this.initialTabIndex = 0,
  });

  final bool embedded;
  final int initialTabIndex;

  @override
  State<CompanyManagementPage> createState() => _CompanyManagementPageState();
}

class _CompanyManagementPageState extends State<CompanyManagementPage>
    with SingleTickerProviderStateMixin {
  late final String _controllerTag;
  late final CompanyManagementController _controller;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag('CompanyManagementController');
    _controller =
        Get.isRegistered<CompanyManagementController>(tag: _controllerTag)
        ? Get.find<CompanyManagementController>(tag: _controllerTag)
        : Get.put(
            CompanyManagementController(
              initialTabIndex: widget.initialTabIndex,
            ),
            tag: _controllerTag,
            permanent: true,
          );
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: _controller.activeTabIndex,
    );
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
    return GetBuilder<CompanyManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = _buildContent(context, controller);
        final action = _createAction(context, controller);
        final actions = action == null ? <Widget>[] : <Widget>[action];

        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }

        return AppStandaloneShell(
          title: 'Companies',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget? _createAction(
    BuildContext context,
    CompanyManagementController controller,
  ) {
    if (controller.activeTabIndex == 0) {
      return AdaptiveShellActionButton(
        onPressed: () => controller.startNewCompany(
          isDesktop: Responsive.isDesktop(context),
        ),
        icon: Icons.add_business_outlined,
        label: 'New Company',
      );
    }
    if (controller.activeTabIndex == 1 &&
        controller.selectedCompany?.id != null &&
        controller.canStartNewFinancialYear) {
      return AdaptiveShellActionButton(
        onPressed: controller.startNewFinancialYear,
        icon: Icons.add_outlined,
        label: 'New Financial Year',
      );
    }
    return null;
  }

  Widget _buildContent(
    BuildContext context,
    CompanyManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading companies...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load companies',
        message: controller.pageError!,
        onRetry: controller.loadCompanies,
      );
    }

    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Companies',
      editorTitle: controller.selectedCompany?.toString(),
      scrollController: controller.pageScrollController,
      list: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_createAction(context, controller) != null) ...[
            AppActionButton(
              onPressed: () {
                if (controller.activeTabIndex == 0) {
                  controller.startNewCompany(
                    isDesktop: Responsive.isDesktop(context),
                  );
                } else {
                  controller.startNewFinancialYear();
                }
              },
              icon: controller.activeTabIndex == 0
                  ? Icons.add_business_outlined
                  : Icons.add_outlined,
              label: controller.activeTabIndex == 0
                  ? 'Create Company'
                  : 'New Financial Year',
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
          ],
          SettingsListCard<CompanyModel>(
            searchController: controller.searchController,
            searchHint: 'Search companies',
            items: controller.filteredCompanies,
            selectedItem: controller.selectedCompany,
            emptyMessage: 'No companies found.',
            itemBuilder: (company, selected) => SettingsListTile(
              title: company.legalName ?? '',
              subtitle: [
                company.code ?? '',
                company.city ?? '',
                company.stateName ?? '',
              ].where((item) => item.isNotEmpty).join(' • '),
              selected: selected,
              trailing: SettingsStatusPill(
                label: company.isActive ? 'Active' : 'Inactive',
                active: company.isActive,
              ),
              onTap: () => controller.selectCompany(company),
            ),
          ),
        ],
      ),
      editorBuilder: (_) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            controller: _tabController,
            onTap: controller.setActiveTabIndex,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Primary'),
              Tab(text: 'Financial Years'),
              Tab(text: 'Formats'),
              Tab(text: 'Leave Policy'),
            ],
          ),
          const SizedBox(height: 20),
          KeyedSubtree(
            key: ValueKey<int>(controller.activeTabIndex),
            child: _buildActiveTab(context, controller),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTab(
    BuildContext context,
    CompanyManagementController controller,
  ) {
    switch (controller.activeTabIndex) {
      case 1:
        return controller.selectedCompany?.id == null
            ? _buildDependentTabPlaceholder(
                title: 'Financial Years',
                message:
                    'Select an existing company or save this company first to manage financial years.',
              )
            : FinancialYearManagementPage(
                embedded: true,
                fixedCompanyId: controller.selectedCompany!.id,
                showShellAction: false,
                onNewFinancialYearActionChanged:
                    controller.setNewFinancialYearAction,
              );
      case 2:
        return _buildFormatsTab(context, controller);
      case 3:
        return _buildLeavePolicyTab(context, controller);
      case 0:
      default:
        return _buildPrimaryTab(context, controller);
    }
  }

  Widget _buildPrimaryTab(
    BuildContext context,
    CompanyManagementController controller,
  ) {
    return Form(
      child: Builder(
        builder: (formContext) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsFormWrap(
              children: [
                AppFormTextField(
                  controller: controller.codeController,
                  labelText: 'Code',
                  readOnly: true,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Code is required'
                      : null,
                ),
                AppFormTextField(
                  controller: controller.legalNameController,
                  labelText: 'Legal Name',
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Legal Name is required'
                      : null,
                ),
                AppFormTextField(
                  controller: controller.tradeNameController,
                  labelText: 'Trade Name',
                ),
                AppDropdownField<String>.fromMapped(
                  initialValue: controller.companyType,
                  labelText: 'Company Type',
                  mappedItems: CompanyManagementController.companyTypeItems,
                  onChanged: controller.setCompanyType,
                ),
                AppFormTextField(
                  controller: controller.gstinController,
                  labelText: 'GSTIN',
                ),
                AppFormTextField(
                  controller: controller.panController,
                  labelText: 'PAN',
                ),
                AppFormTextField(
                  controller: controller.phoneController,
                  labelText: 'Phone',
                ),
                AppFormTextField(
                  controller: controller.emailController,
                  labelText: 'Email',
                ),
                AppFormTextField(
                  controller: controller.websiteController,
                  labelText: 'Website',
                ),
                AppFormTextField(
                  controller: controller.addressLine1Controller,
                  labelText: 'Address Line 1',
                ),
                AppFormTextField(
                  controller: controller.addressLine2Controller,
                  labelText: 'Address Line 2',
                ),
                AppFormTextField(
                  controller: controller.areaController,
                  labelText: 'Area',
                ),
                AppFormTextField(
                  controller: controller.cityController,
                  labelText: 'City',
                ),
                AppFormTextField(
                  controller: controller.districtController,
                  labelText: 'District',
                ),
                AppFormTextField(
                  controller: controller.stateController,
                  labelText: 'State Name',
                ),
                AppFormTextField(
                  controller: controller.postalCodeController,
                  labelText: 'Postal Code',
                ),
                AppFormTextField(
                  controller: controller.currencyController,
                  labelText: 'Base Currency',
                ),
              ],
            ),
            const SizedBox(height: 16),
            UploadPathField(
              controller: controller.logoPathController,
              labelText: 'Company Logo',
              isUploading: controller.uploadingLogo,
              onUpload: () => controller.uploadCompanyLogo(context),
              previewUrl: AppConfig.resolvePublicFileUrl(
                controller.logoPathController.text,
              ),
              previewIcon: Icons.business_outlined,
            ),
            const SizedBox(height: 16),
            AppSwitchTile(
              label: 'Active',
              subtitle:
                  'Inactive companies stay visible but should not be used for new work.',
              value: controller.isActive,
              onChanged: controller.setIsActive,
            ),
            const SizedBox(height: 8),
            AppFormTextField(
              controller: controller.remarksController,
              maxLines: 3,
              labelText: 'Remarks',
            ),
            if ((controller.formError ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                controller.formError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                AppActionButton(
                  onPressed: controller.saving
                      ? null
                      : () => controller.save(formState: Form.of(formContext)),
                  icon: controller.selectedCompany == null
                      ? Icons.add
                      : Icons.save_outlined,
                  label: controller.saving ? 'Saving...' : 'Save Company',
                  busy: controller.saving,
                ),
                AppActionButton(
                  onPressed: controller.saving ? null : controller.resetForm,
                  icon: Icons.refresh,
                  label: 'Reset',
                  filled: false,
                ),
              ],
            ),
          ],
        ),
      ),
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

  Widget _buildFormatsTab(
    BuildContext context,
    CompanyManagementController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text(
          'These format settings apply globally across the entire application whenever this company is active.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).extension<AppThemeExtension>()?.mutedText,
          ),
        ),
        const SizedBox(height: 20),
        SettingsFormWrap(
          children: [
            AppDropdownField<String>.fromMapped(
              labelText: 'Date Format',
              mappedItems: AppFormatSettings.dateFormatItems,
              initialValue: controller.formatDate,
              onChanged: controller.setFormatDate,
            ),
            AppDropdownField<String>.fromMapped(
              labelText: 'Amount Format',
              mappedItems: AppFormatSettings.amountGroupingItems,
              initialValue: controller.formatAmountGrouping,
              onChanged: controller.setFormatAmountGrouping,
            ),
            AppDropdownField<int>.fromMapped(
              labelText: 'Decimal Places',
              mappedItems: AppFormatSettings.decimalPlacesItems,
              initialValue: controller.formatDecimalPlaces,
              onChanged: controller.setFormatDecimalPlaces,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _FormatPreviewCard(controller: controller),
        const SizedBox(height: 16),
        if ((controller.formError ?? '').isNotEmpty) ...[
          Text(
            controller.formError!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            AppActionButton(
              onPressed: controller.saving ? null : controller.save,
              icon: Icons.save_outlined,
              label: controller.saving ? 'Saving...' : 'Save Formats',
              busy: controller.saving,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLeavePolicyTab(
    BuildContext context,
    CompanyManagementController controller,
  ) {
    final policies =
        controller.selectedCompany?.leavePolicies ??
        const <CompanyLeavePolicyModel>[];
    if (controller.selectedCompany?.id == null || policies.isEmpty) {
      return _buildDependentTabPlaceholder(
        title: 'Leave Policy',
        message:
            'Save or select a company first. Default policies will be created for every leave type.',
      );
    }

    return Form(
      child: Builder(
        builder: (formContext) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Configure annual entitlement for every leave type. Paid leave beyond the available balance follows the selected excess action.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).extension<AppThemeExtension>()?.mutedText,
              ),
            ),
            const SizedBox(height: AppUiConstants.spacingLg),
            SettingsFormWrap(
              children: <Widget>[
                AppDropdownField<double>.fromMapped(
                  labelText: 'LOP deduction multiplier',
                  initialValue: controller.lopMultiplier,
                  mappedItems: const <AppDropdownItem<double>>[
                    AppDropdownItem(value: 1, label: '1 day'),
                    AppDropdownItem(value: 1.5, label: '1.5 days'),
                    AppDropdownItem(value: 2, label: '2 days'),
                  ],
                  onChanged: controller.setLopMultiplier,
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingLg),
            ...policies.map((policy) {
              final leaveTypeId = policy.leaveTypeId;
              return Padding(
                padding: const EdgeInsets.only(
                  bottom: AppUiConstants.spacingMd,
                ),
                child: AppSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        policy.leaveCode.isEmpty
                            ? policy.leaveName
                            : '${policy.leaveName} (${policy.leaveCode})',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppUiConstants.spacingMd),
                      SettingsFormWrap(
                        children: <Widget>[
                          AppFormTextField(
                            controller: controller.leaveEntitlementController(
                              leaveTypeId,
                            ),
                            labelText: 'Annual entitlement (days)',
                            readOnly: !policy.isPaid,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: Validators.optionalNonNegativeNumber(
                              'Annual entitlement',
                            ),
                          ),
                          AppDropdownField<String>.fromMapped(
                            labelText: 'Leave availability schedule',
                            initialValue:
                                controller.leaveAccrualMethods[leaveTypeId],
                            mappedItems: const <AppDropdownItem<String>>[
                              AppDropdownItem(
                                value: 'annual_upfront',
                                label: 'Yearly',
                              ),
                              AppDropdownItem(
                                value: 'monthly',
                                label: 'Monthly',
                              ),
                            ],
                            onChanged: (value) => controller
                                .setLeaveAccrualMethod(leaveTypeId, value),
                          ),
                          AppDropdownField<String>.fromMapped(
                            labelText: 'When balance is exhausted',
                            initialValue:
                                controller.leaveExcessActions[leaveTypeId],
                            mappedItems: const <AppDropdownItem<String>>[
                              AppDropdownItem(
                                value: 'convert_to_lop',
                                label: 'Convert excess to LOP',
                              ),
                              AppDropdownItem(
                                value: 'reject',
                                label: 'Reject request',
                              ),
                            ],
                            onChanged: (value) => controller
                                .setLeaveExcessAction(leaveTypeId, value),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppUiConstants.spacingSm),
                      AppSwitchTile(
                        label: 'Available for this company',
                        value: controller.activeLeavePolicyIds.contains(
                          leaveTypeId,
                        ),
                        onChanged: (value) =>
                            controller.setLeavePolicyActive(leaveTypeId, value),
                      ),
                    ],
                  ),
                ),
              );
            }),
            if ((controller.formError ?? '').isNotEmpty) ...<Widget>[
              Text(
                controller.formError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: AppUiConstants.spacingSm),
            ],
            AppActionButton(
              onPressed: controller.saving
                  ? null
                  : () {
                      if (Form.of(formContext).validate()) {
                        controller.save(formState: Form.of(formContext));
                      }
                    },
              icon: Icons.save_outlined,
              label: controller.saving ? 'Saving...' : 'Save Leave Policy',
              busy: controller.saving,
            ),
          ],
        ),
      ),
    );
  }
}

class _FormatPreviewCard extends StatelessWidget {
  const _FormatPreviewCard({required this.controller});

  final CompanyManagementController controller;

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>();
    final sampleDate = '2026-07-04';
    final sampleAmount = 123456.789;

    final previewDate = _previewDate(sampleDate, controller.formatDate);
    final previewAmount = _previewAmount(
      sampleAmount,
      controller.formatAmountGrouping,
      controller.formatDecimalPlaces,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appTheme?.subtleFill,
        borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PreviewItem(label: 'Date', value: previewDate),
              ),
              Expanded(
                child: _PreviewItem(label: 'Amount', value: previewAmount),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _previewDate(String raw, String fmt) {
    final parts = raw.split('-');
    if (parts.length != 3) return raw;
    return fmt
        .replaceAll('yyyy', parts[0])
        .replaceAll('MM', parts[1])
        .replaceAll('dd', parts[2]);
  }

  static String _previewAmount(double value, String grouping, int decimals) {
    return formatAmount(value);
  }
}

class _PreviewItem extends StatelessWidget {
  const _PreviewItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).extension<AppThemeExtension>()?.mutedText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
