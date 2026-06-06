import '../../../controller/settings/master/document_series_management_controller.dart';
import '../../../screen.dart';

class DocumentSeriesManagementPage extends StatefulWidget {
  const DocumentSeriesManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<DocumentSeriesManagementPage> createState() =>
      _DocumentSeriesManagementPageState();
}

class _DocumentSeriesManagementPageState
    extends State<DocumentSeriesManagementPage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'DocumentSeriesManagementController',
    );
    Get.put(DocumentSeriesManagementController(), tag: _controllerTag);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DocumentSeriesManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = _buildContent(context, controller);
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () =>
                controller.startNew(isDesktop: Responsive.isDesktop(context)),
            icon: Icons.confirmation_number_outlined,
            label: 'New Series',
          ),
        ];

        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }

        return AppStandaloneShell(
          title: 'Document Series',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    DocumentSeriesManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading document series...');
    }

    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load document series',
        message: controller.pageError!,
        onRetry: controller.loadData,
      );
    }

    // Migrated page/form state now lives in DocumentSeriesManagementController.
    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Document Series',
      editorTitle: controller.selectedSeries?.toString(),
      scrollController: controller.pageScrollController,
      list: SettingsListCard<DocumentSeriesModel>(
        searchController: controller.searchController,
        searchHint: 'Search document series',
        items: controller.filteredSeries,
        selectedItem: controller.selectedSeries,
        emptyMessage: 'No document series found.',
        itemBuilder: (item, selected) => SettingsListTile(
          title: item.seriesName ?? '',
          subtitle: [
            item.seriesCode ?? '',
            item.documentType ?? '',
            companyNameById(controller.companies, item.companyId),
          ].where((part) => part.trim().isNotEmpty).join(' · '),
          selected: selected,
          onTap: () => controller.selectSeries(item),
        ),
      ),
      editorBuilder: (_) => Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (controller.formError != null) ...[
              Text(
                controller.formError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: controller.nameController,
              decoration: const InputDecoration(labelText: 'Series Name'),
              validator: Validators.compose([
                Validators.required('Series Name'),
                Validators.optionalMaxLength(100, 'Series Name'),
              ]),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controller.documentTypeController,
              decoration: const InputDecoration(labelText: 'Document Type'),
              validator: Validators.compose([
                Validators.required('Document Type'),
                Validators.optionalMaxLength(50, 'Document Type'),
              ]),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller.prefixController,
                    decoration: const InputDecoration(labelText: 'Prefix'),
                    validator: Validators.optionalMaxLength(20, 'Prefix'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: controller.suffixController,
                    decoration: const InputDecoration(labelText: 'Suffix'),
                    validator: Validators.optionalMaxLength(20, 'Suffix'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller.nextNumberController,
                    decoration: const InputDecoration(labelText: 'Next Number'),
                    inputFormatters: const <TextInputFormatter>[
                      NumericInputFormatter(),
                    ],
                    keyboardType: TextInputType.number,
                    validator: Validators.optionalNonNegativeInteger(
                      'Next Number',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: controller.numberLengthController,
                    decoration: const InputDecoration(
                      labelText: 'Number Length',
                    ),
                    inputFormatters: const <TextInputFormatter>[
                      NumericInputFormatter(),
                    ],
                    keyboardType: TextInputType.number,
                    validator: Validators.optionalNonNegativeInteger(
                      'Number Length',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controller.remarksController,
              decoration: const InputDecoration(
                labelText: 'Remarks',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Default Series'),
              value: controller.isDefault,
              onChanged: controller.setIsDefault,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              value: controller.isActive,
              onChanged: controller.setIsActive,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: controller.saving ? null : controller.save,
                icon: const Icon(Icons.save_outlined),
                label: Text(controller.saving ? 'Saving...' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
