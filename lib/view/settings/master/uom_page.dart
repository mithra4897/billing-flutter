import '../../../controller/settings/master/uom_management_controller.dart';
import '../../../screen.dart';

class UomManagementPage extends StatefulWidget {
  const UomManagementPage({
    super.key,
    this.embedded = false,
    this.initialTabIndex = 0,
  });

  final bool embedded;
  final int initialTabIndex;

  @override
  State<UomManagementPage> createState() => _UomManagementPageState();
}

class _UomManagementPageState extends State<UomManagementPage>
    with SingleTickerProviderStateMixin {
  late final String _controllerTag;
  late final UomManagementController _controller;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag('UomManagementController');
    _controller = Get.put(
      UomManagementController(initialTabIndex: widget.initialTabIndex),
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
    return GetBuilder<UomManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = _buildContent(context, controller);
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () =>
                controller.startNewUom(isDesktop: Responsive.isDesktop(context)),
            icon: Icons.add_circle_outline,
            label: 'New UOM',
          ),
        ];

        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }

        return AppStandaloneShell(
          title: 'UOM',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, UomManagementController controller) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading UOM...');
    }

    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load UOM',
        message: controller.pageError!,
        onRetry: controller.loadData,
      );
    }

    // Migrated page/form state now lives in UomManagementController.
    if (_tabController.index != controller.activeTabIndex) {
      _tabController.index = controller.activeTabIndex;
    }

    return SettingsWorkspace(
        controller: controller.workspaceController,
        title: 'UOM',
        editorTitle: controller.selectedUom?.toString(),
        scrollController: controller.pageScrollController,
        list: SettingsListCard<UomModel>(
          searchController: controller.searchController,
          searchHint: 'Search UOM',
          items: controller.filteredUoms,
          selectedItem: controller.selectedUom,
          emptyMessage: 'No UOM records found.',
          itemBuilder: (uom, selected) => SettingsListTile(
            title: uom.uomName ?? '-',
            subtitle: [
              uom.symbol ?? '',
              uom.uomCode ?? '',
            ].where((value) => value.trim().isNotEmpty).join(' · '),
            selected: selected,
            onTap: () => controller.selectUom(uom),
            trailing: SettingsStatusPill(
              label: uom.isActive ? 'Active' : 'Inactive',
              active: uom.isActive,
            ),
          ),
        ),
        editorBuilder: (_) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TabBar(
              controller: _tabController,
              onTap: controller.setActiveTabIndex,
              isScrollable: true,
              tabs: const [Tab(text: 'Primary'), Tab(text: 'Conversions')],
            ),
            const SizedBox(height: 20),
            IndexedStack(
              index: controller.activeTabIndex,
              children: [
                _buildPrimaryTab(controller),
                _buildConversionsTab(context, controller),
              ],
            ),
          ],
        ),
    );
  }

  Widget _buildPrimaryTab(UomManagementController controller) {
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
              AppFormTextField(
                labelText: 'UOM Code',
                controller: controller.codeController,
                validator: Validators.required('UOM code'),
              ),
              AppFormTextField(
                labelText: 'UOM Name',
                controller: controller.nameController,
                validator: Validators.required('UOM name'),
              ),
              AppFormTextField(
                labelText: 'Symbol',
                controller: controller.symbolController,
                validator: Validators.required('Symbol'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              SizedBox(
                child: AppSwitchTile(
                  label: 'Fraction Allowed',
                  subtitle: 'Enable decimal quantity for this unit.',
                  value: controller.isFractionAllowed,
                  onChanged: controller.setIsFractionAllowed,
                ),
              ),
              SizedBox(
                child: AppSwitchTile(
                  label: 'Active',
                  subtitle: 'Inactive UOMs stay hidden from normal use.',
                  value: controller.isActive,
                  onChanged: controller.setIsActive,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              AppActionButton(
                icon: Icons.save_outlined,
                label:
                    controller.selectedUom == null ? 'Save UOM' : 'Update UOM',
                onPressed: controller.save,
                busy: controller.saving,
              ),
              if (controller.selectedUom?.id != null)
                AppActionButton(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  onPressed: controller.saving ? null : controller.delete,
                  filled: false,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConversionsTab(
    BuildContext context,
    UomManagementController controller,
  ) {
    final selectedUom = controller.selectedUom;
    if (selectedUom?.id == null) {
      return const SettingsEmptyState(
        icon: Icons.straighten_outlined,
        title: 'Save UOM First',
        message: 'Conversions become available after the UOM is saved.',
      );
    }
    final currentUom = selectedUom!;

    final targetOptions = controller.uoms
        .where((uom) => uom.id != null && uom.id != currentUom.id)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Conversions for ${currentUom.uomName ?? currentUom.uomCode}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        if (controller.displayConversions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No conversions defined for this UOM.'),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.displayConversions.length,
            separatorBuilder: (_, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = controller.displayConversions[index];
              return SettingsListTile(
                title: item.otherLabel,
                subtitle: [
                  if (item.displayFactor != null) 'Factor ${item.displayFactor}',
                  if (item.reversed) 'Reverse view',
                  if (item.isActive) 'Active',
                ].join(' · '),
                selected:
                    identical(item.record, controller.selectedConversionRecord),
                onTap: () => controller.selectConversion(item),
              );
            },
          ),
        const SizedBox(height: 20),
        Form(
          key: controller.conversionFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (controller.conversionError != null) ...[
                AppErrorStateView.inline(message: controller.conversionError!),
                const SizedBox(height: 12),
              ],
              SettingsFormWrap(
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: controller.conversionTargetUomId,
                    decoration: const InputDecoration(labelText: 'To UOM'),
                    items: targetOptions
                        .map(
                          (uom) => DropdownMenuItem<int>(
                            value: uom.id,
                            child: Text(uom.toString()),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: controller.setConversionTargetUomId,
                    validator: Validators.requiredSelection('To UOM'),
                  ),
                  AppFormTextField(
                    labelText: 'Conversion Factor',
                    controller: controller.conversionFactorController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: Validators.compose([
                      Validators.required('Conversion factor'),
                      Validators.optionalNonNegativeNumber('Conversion factor'),
                    ]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Factor is from the selected UOM to the target UOM. Reverse view is calculated automatically.',
              ),
              const SizedBox(height: 12),
              AppSwitchTile(
                label: 'Active',
                value: controller.conversionActive,
                onChanged: controller.setConversionActive,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  AppActionButton(
                    icon: Icons.save_outlined,
                    label: controller.selectedConversionRecord == null
                        ? 'Save Conversion'
                        : 'Update Conversion',
                    onPressed: controller.saveConversion,
                    busy: controller.savingConversion,
                  ),
                  AppActionButton(
                    icon: Icons.refresh_outlined,
                    label: 'New',
                    filled: false,
                    onPressed: controller.savingConversion
                        ? null
                        : controller.resetConversionForm,
                  ),
                  if (controller.selectedConversionRecord?.id != null)
                    AppActionButton(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      filled: false,
                      onPressed: controller.savingConversion
                          ? null
                          : controller.deleteConversion,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
