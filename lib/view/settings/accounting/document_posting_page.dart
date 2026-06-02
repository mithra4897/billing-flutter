import '../../../controller/settings/accounting/document_posting_management_controller.dart';
import '../../../screen.dart';

class DocumentPostingManagementPage extends StatefulWidget {
  const DocumentPostingManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<DocumentPostingManagementPage> createState() =>
      _DocumentPostingManagementPageState();
}

class _DocumentPostingManagementPageState
    extends State<DocumentPostingManagementPage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'DocumentPostingManagementController',
    );
    Get.put(DocumentPostingManagementController(), tag: _controllerTag);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DocumentPostingManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = _buildContent(context, controller);
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () => controller.startNewPosting(
              isDesktop: Responsive.isDesktop(context),
            ),
            icon: Icons.post_add_outlined,
            label: 'New Posting',
          ),
        ];

        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }

        return AppStandaloneShell(
          title: 'Document Postings',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    DocumentPostingManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading document postings...');
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
      title: 'Document Postings',
      editorTitle:
          stringValue(
            controller.json(controller.selectedPosting),
            'document_no',
          ).isEmpty
          ? null
          : stringValue(
              controller.json(controller.selectedPosting),
              'document_no',
            ),
      scrollController: controller.pageScrollController,
      list: SettingsListCard<DocumentPostingModel>(
        searchController: controller.searchController,
        searchHint: 'Search postings',
        items: controller.filteredRows,
        selectedItem: controller.selectedPosting,
        emptyMessage: 'No document postings.',
        itemBuilder: (item, selected) {
          final data = item.toJson();
          return SettingsListTile(
            title:
                '${stringValue(data, 'document_module')}.${stringValue(data, 'document_table')} #${stringValue(data, 'document_id')}',
            subtitle: [
              stringValue(data, 'document_no'),
              stringValue(data, 'posting_status'),
            ].join(' · '),
            selected: selected,
            onTap: () => controller.selectPosting(item),
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
            Text(
              'For advanced setup and testing. Most postings are created by the system from operational documents.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            SettingsFormWrap(
              children: [
                AppDropdownField<String>.fromMapped(
                  labelText: 'Document module',
                  mappedItems: controller.documentModuleItems,
                  initialValue: nullIfEmpty(controller.moduleController.text),
                  onChanged: controller.setDocumentModule,
                  validator: Validators.requiredSelection('Module'),
                ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Document table',
                  mappedItems: controller.documentTableItems,
                  initialValue: nullIfEmpty(controller.tableController.text),
                  onChanged: controller.setDocumentTable,
                  validator: Validators.requiredSelection('Table'),
                ),
                AppFormTextField(
                  labelText: 'Document ID',
                  controller: controller.documentIdController,
                  keyboardType: TextInputType.number,
                  validator: Validators.required('Document ID'),
                ),
                AppFormTextField(
                  labelText: 'Document no. (optional)',
                  controller: controller.documentNoController,
                ),
                AppFormTextField(
                  labelText: 'Document date',
                  controller: controller.documentDateController,
                  validator: Validators.optionalDate('Document date'),
                ),
                AppDropdownField<int?>.fromMapped(
                  labelText: 'Posting rule group (optional)',
                  mappedItems: <AppDropdownItem<int?>>[
                    const AppDropdownItem<int?>(value: null, label: 'None'),
                    ...controller.groups
                        .map(
                          (item) => AppDropdownItem<int?>(
                            value: intValue(item.toJson(), 'id'),
                            label:
                                stringValue(item.toJson(), 'group_name').isEmpty
                                ? stringValue(item.toJson(), 'group_code')
                                : stringValue(item.toJson(), 'group_name'),
                          ),
                        )
                        .where((item) => item.value != null),
                  ],
                  initialValue: controller.postingRuleGroupId,
                  onChanged: controller.setPostingRuleGroupId,
                ),
                AppFormTextField(
                  labelText: 'Voucher ID (optional)',
                  controller: controller.voucherIdController,
                  keyboardType: TextInputType.number,
                ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Posting status',
                  mappedItems: DocumentPostingManagementController.statusItems,
                  initialValue: controller.postingStatus,
                  onChanged: controller.setPostingStatus,
                ),
                AppFormTextField(
                  labelText: 'Remarks',
                  controller: controller.remarksController,
                  maxLines: 2,
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            Row(
              children: [
                Text(
                  'Lines (optional)',
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
                      ),
                      AppDropdownField<String>.fromMapped(
                        labelText: 'Side',
                        mappedItems:
                            DocumentPostingManagementController.entryItems,
                        initialValue: line.entrySide,
                        onChanged: (value) =>
                            controller.setLineEntrySide(index, value),
                      ),
                      AppFormTextField(
                        labelText: 'Amount',
                        controller: line.amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      AppFormTextField(
                        labelText: 'Narration',
                        controller: line.narrationController,
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
                            controller.json(controller.selectedPosting),
                            'id',
                          ) ==
                          null
                      ? 'Save'
                      : 'Update',
                  onPressed: controller.savePosting,
                  busy: controller.saving,
                ),
                if (intValue(
                      controller.json(controller.selectedPosting),
                      'id',
                    ) !=
                    null)
                  AppActionButton(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    onPressed: controller.saving
                        ? null
                        : controller.deletePosting,
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
