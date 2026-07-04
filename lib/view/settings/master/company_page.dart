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
    _controllerTag =
        persistentControllerTag('CompanyManagementController');
    _controller = Get.put(
      CompanyManagementController(initialTabIndex: widget.initialTabIndex),
      tag: _controllerTag,
    permanent: true,
    );
    _tabController = TabController(length: 3, vsync: this);
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
        final actions = [
          AdaptiveShellActionButton(
            onPressed: () => controller.startNewCompany(
              isDesktop: Responsive.isDesktop(context),
            ),
            icon: Icons.add_business_outlined,
            label: 'New Company',
          ),
        ];

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

    // Migrated page/form state now lives in CompanyManagementController.
    if (_tabController.index != controller.activeTabIndex) {
      _tabController.index = controller.activeTabIndex;
    }

    return SettingsWorkspace(
        controller: controller.workspaceController,
        title: 'Companies',
        editorTitle: controller.selectedCompany?.toString(),
        scrollController: controller.pageScrollController,
        list: SettingsListCard<CompanyModel>(
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
              ],
            ),
            const SizedBox(height: 20),
            IndexedStack(
              index: controller.activeTabIndex,
              children: [
                _buildPrimaryTab(context, controller),
                controller.selectedCompany?.id == null
                    ? _buildDependentTabPlaceholder(
                        title: 'Financial Years',
                        message:
                            'Select an existing company or save this company first to manage financial years.',
                      )
                    : FinancialYearManagementPage(
                        embedded: true,
                        fixedCompanyId: controller.selectedCompany!.id,
                      ),
                _buildFormatsTab(context, controller),
              ],
            ),
          ],
        ),
    );
  }

  Widget _buildPrimaryTab(
    BuildContext context,
    CompanyManagementController controller,
  ) {
    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsFormWrap(
            children: [
              AppFormTextField(
                controller: controller.codeController,
                labelText: 'Code',
                readOnly: true,
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Code is required' : null,
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
                controller: controller.cityController,
                labelText: 'City',
              ),
              AppFormTextField(
                controller: controller.stateController,
                labelText: 'State Name',
              ),
              AppFormTextField(
                controller: controller.currencyController,
                labelText: 'Base Currency',
              ),
            ],
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
                onPressed: controller.saving ? null : controller.save,
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
            color: Theme.of(context)
                .extension<AppThemeExtension>()
                ?.mutedText,
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
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
            ),
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
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PreviewItem(
                  label: 'Date',
                  value: previewDate,
                ),
              ),
              Expanded(
                child: _PreviewItem(
                  label: 'Amount',
                  value: previewAmount,
                ),
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
            color: Theme.of(
              context,
            ).extension<AppThemeExtension>()?.mutedText,
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
