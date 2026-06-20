import '../../../controller/settings/master/transporter_management_controller.dart';
import '../../../screen.dart';

class TransporterManagementPage extends StatefulWidget {
  const TransporterManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<TransporterManagementPage> createState() =>
      _TransporterManagementPageState();
}

class _TransporterManagementPageState extends State<TransporterManagementPage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag('TransporterManagementController');
    Get.put(TransporterManagementController(), tag: _controllerTag);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TransporterManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = _buildContent(controller);
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () => controller.startNew(
              isDesktop: Responsive.isDesktop(context),
            ),
            icon: Icons.local_shipping_outlined,
            label: 'New Transporter',
          ),
        ];

        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }

        return AppStandaloneShell(
          title: 'Transporters',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(TransporterManagementController controller) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading transporters...');
    }

    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load transporters',
        message: controller.pageError!,
        onRetry: controller.loadTransporters,
      );
    }

    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Transporters',
      editorTitle: controller.selectedTransporter?.toString(),
      scrollController: controller.pageScrollController,
      list: SettingsListCard<TransporterModel>(
        searchController: controller.searchController,
        searchHint: 'Search transporters',
        items: controller.filteredTransporters,
        selectedItem: controller.selectedTransporter,
        emptyMessage: 'No transporter records found.',
        itemBuilder: (transporter, selected) => SettingsListTile(
          title: transporter.name ?? '-',
          subtitle: [
            transporter.transporterTypeLabel,
            transporter.deliveryModeLabel,
          ].where((value) => value.trim().isNotEmpty).join(' - '),
          selected: selected,
          onTap: () => controller.selectTransporter(transporter),
          trailing: SettingsStatusPill(
            label: transporter.isActive ? 'Active' : 'Inactive',
            active: transporter.isActive,
          ),
        ),
      ),
      editorBuilder: (_) => Form(
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
                  labelText: 'Transporter Name',
                  controller: controller.nameController,
                  validator: Validators.compose([
                    Validators.required('Transporter Name'),
                    Validators.optionalMaxLength(150, 'Transporter Name'),
                  ]),
                ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Type',
                  mappedItems: transporterTypeItems,
                  initialValue: controller.transporterType,
                  onChanged: controller.setTransporterType,
                ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Delivery Mode',
                  mappedItems: transporterDeliveryModeItems,
                  initialValue: controller.deliveryMode,
                  onChanged: controller.setDeliveryMode,
                ),
                AppFormTextField(
                  labelText: 'Remarks',
                  controller: controller.remarksController,
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppSwitchTile(
              label: 'Active',
              subtitle:
                  'Inactive transporters stay hidden from normal selection.',
              value: controller.isActive,
              onChanged: controller.setIsActive,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                AppActionButton(
                  icon: Icons.save_outlined,
                  label: controller.selectedTransporter == null
                      ? 'Save Transporter'
                      : 'Update Transporter',
                  onPressed: controller.save,
                  busy: controller.saving,
                ),
                if (controller.selectedTransporter?.id != null)
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
      ),
    );
  }
}
