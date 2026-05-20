import '../../../controller/settings/master/uom_conversion_management_controller.dart';
import '../../../screen.dart';

class UomConversionManagementPage extends StatefulWidget {
  const UomConversionManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<UomConversionManagementPage> createState() =>
      _UomConversionManagementPageState();
}

class _UomConversionManagementPageState
    extends State<UomConversionManagementPage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'UomConversionManagementController',
    );
    Get.put(UomConversionManagementController(), tag: _controllerTag);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<UomConversionManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = _buildContent(context, controller);
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () =>
                controller.startNew(isDesktop: Responsive.isDesktop(context)),
            icon: Icons.swap_vert_outlined,
            label: 'New Conversion',
          ),
        ];

        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }

        return AppStandaloneShell(
          title: 'UOM Conversions',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    UomConversionManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading UOM conversions...');
    }

    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load UOM conversions',
        message: controller.pageError!,
        onRetry: controller.loadData,
      );
    }

    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'UOM Conversions',
      editorTitle: controller.selectedItem?.toString(),
      scrollController: controller.pageScrollController,
      list: SettingsListCard<UomConversionModel>(
        searchController: controller.searchController,
        searchHint: 'Search UOM conversions',
        items: controller.filteredItems,
        selectedItem: controller.selectedItem,
        emptyMessage: 'No UOM conversions found.',
        itemBuilder: (item, selected) => SettingsListTile(
          title: '${item.fromDisplay} -> ${item.toDisplay}',
          subtitle: [
            if (item.fromUomSymbol.isNotEmpty) item.fromUomSymbol,
            if (item.toUomSymbol.isNotEmpty) item.toUomSymbol,
            if (item.conversionFactor != null)
              'Factor ${item.conversionFactor}',
          ].join(' · '),
          selected: selected,
          onTap: () => controller.selectItem(item),
        ),
      ),
      editor: AppSectionCard(
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (controller.formError != null) ...[
                AppErrorStateView.inline(message: controller.formError!),
                const SizedBox(height: 12),
              ],
              DropdownButtonFormField<int>(
                initialValue: controller.fromUomId,
                decoration: const InputDecoration(labelText: 'From UOM'),
                items: controller.uoms
                    .where((uom) => uom.id != null)
                    .map(
                      (uom) => DropdownMenuItem<int>(
                        value: uom.id,
                        child: Text(uom.toString()),
                      ),
                    )
                    .toList(growable: false),
                onChanged: controller.setFromUomId,
                validator: (value) =>
                    Validators.requiredSelectionField(value, 'From UOM'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: controller.toUomId,
                decoration: const InputDecoration(labelText: 'To UOM'),
                items: controller.toUomOptions
                    .where((uom) => uom.id != null)
                    .map(
                      (uom) => DropdownMenuItem<int>(
                        value: uom.id,
                        child: Text(uom.toString()),
                      ),
                    )
                    .toList(growable: false),
                onChanged: controller.setToUomId,
                validator: (value) =>
                    Validators.requiredSelectionField(value, 'To UOM'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller.factorController,
                decoration: const InputDecoration(
                  labelText: 'Conversion Factor',
                  hintText: '1 Base = ? Target',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: Validators.compose([
                  Validators.required('Conversion Factor'),
                  Validators.optionalNonNegativeNumber('Conversion Factor'),
                  (value) {
                    final parsed = double.tryParse((value ?? '').trim());
                    if (parsed == null || parsed <= 0) {
                      return 'Conversion Factor must be greater than 0';
                    }
                    return null;
                  },
                ]),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: controller.isActive,
                onChanged: controller.setIsActive,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (controller.selectedItem?.id != null)
                    TextButton(
                      onPressed: controller.saving ? null : controller.delete,
                      child: const Text('Delete'),
                    ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: controller.saving ? null : controller.save,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(controller.saving ? 'Saving...' : 'Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
