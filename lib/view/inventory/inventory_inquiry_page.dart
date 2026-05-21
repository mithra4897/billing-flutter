import '../../controller/inventory/inventory_inquiry_management_controller.dart';
import '../../screen.dart';

class InventoryInquiryPage extends StatefulWidget {
  const InventoryInquiryPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<InventoryInquiryPage> createState() => _InventoryInquiryPageState();
}

class _InventoryInquiryPageState extends State<InventoryInquiryPage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'InventoryInquiryManagementController',
    );
    Get.put(InventoryInquiryManagementController(), tag: _controllerTag);
  }

  List<Widget> _shellActions(InventoryInquiryManagementController controller) {
    return [
      AdaptiveShellActionButton(
        onPressed: controller.running ? null : controller.run,
        icon: Icons.play_arrow_outlined,
        label: 'Run inquiry',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<InventoryInquiryManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final body = _buildBody(context, controller);
        if (widget.embedded) {
          return ShellPageActions(
            actions: _shellActions(controller),
            child: body,
          );
        }
        return AppStandaloneShell(
          title: 'Inventory inquiry',
          scrollController: controller.pageScrollController,
          actions: _shellActions(controller),
          child: body,
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    InventoryInquiryManagementController controller,
  ) {
    if (controller.loadingLookups) {
      return const AppLoadingView(message: 'Loading inquiry data...');
    }
    if (controller.error != null && controller.items.isEmpty) {
      return AppErrorStateView(
        title: 'Unable to load inquiry',
        message: controller.error!,
        onRetry: controller.bootstrap,
      );
    }

    final companyItems = controller.companies
        .map(
          (CompanyModel company) => AppDropdownItem<int?>(
            value: company.id,
            label: company.toString(),
          ),
        )
        .toList(growable: false);

    final warehouseItems = <AppDropdownItem<int?>>[
      const AppDropdownItem<int?>(value: null, label: 'All warehouses'),
      ...controller.warehouses.map(
        (WarehouseModel warehouse) => AppDropdownItem<int?>(
          value: warehouse.id,
          label: warehouse.toString(),
        ),
      ),
    ];

    return SingleChildScrollView(
      controller: controller.pageScrollController,
      padding: const EdgeInsets.all(AppUiConstants.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.error != null) ...[
            AppErrorStateView.inline(message: controller.error!),
            const SizedBox(height: AppUiConstants.spacingMd),
          ],
          AppSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Parameters',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppUiConstants.spacingSm),
                Text(
                  'Inquiries are scoped to an item. Optional company and warehouse '
                  'filters apply to the APIs that support them.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppUiConstants.spacingMd),
                Wrap(
                  spacing: AppUiConstants.spacingMd,
                  runSpacing: AppUiConstants.spacingMd,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    AppDropdownField<String>.fromMapped(
                      labelText: 'Inquiry',
                      mappedItems:
                          InventoryInquiryManagementController.inquiryModes,
                      initialValue: controller.mode,
                      width: 240,
                      onChanged: controller.setMode,
                    ),
                    AppDropdownField<int?>.fromMapped(
                      labelText: 'Company (optional)',
                      mappedItems: <AppDropdownItem<int?>>[
                        const AppDropdownItem<int?>(
                          value: null,
                          label: 'Any / default',
                        ),
                        ...companyItems,
                      ],
                      initialValue: controller.companyId,
                      width: 260,
                      onChanged: controller.setCompanyId,
                    ),
                    AppSearchPickerField<int>(
                      labelText: 'Item',
                      selectedLabel: controller.items
                          .cast<ItemModel?>()
                          .firstWhere(
                            (item) => item?.id == controller.itemId,
                            orElse: () => null,
                          )
                          ?.toString(),
                      options: controller.items
                          .where((item) => item.id != null)
                          .map(
                            (item) => AppSearchPickerOption<int>(
                              value: item.id!,
                              label: item.toString(),
                              subtitle: item.itemCode,
                            ),
                          )
                          .toList(growable: false),
                      width: 320,
                      onChanged: controller.setItemId,
                    ),
                    if (controller.mode == 'batch' ||
                        controller.mode == 'serials')
                      AppDropdownField<int?>.fromMapped(
                        labelText: 'Warehouse',
                        mappedItems: warehouseItems,
                        initialValue: controller.warehouseId,
                        width: 240,
                        onChanged: controller.setWarehouseId,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          AppSectionCard(
            child: controller.running
                ? const AppLoadingView(message: 'Running inquiry...')
                : controller.resultText == null
                ? const Text('Run an inquiry to see JSON results here.')
                : SelectableText(controller.resultText!),
          ),
        ],
      ),
    );
  }
}
