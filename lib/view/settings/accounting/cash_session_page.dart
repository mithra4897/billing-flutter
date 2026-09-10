import '../../../controller/settings/accounting/cash_session_management_controller.dart';
import '../../../screen.dart';

class CashSessionManagementPage extends StatefulWidget {
  const CashSessionManagementPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
    this.startNew = false,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;
  final bool startNew;

  @override
  State<CashSessionManagementPage> createState() =>
      _CashSessionManagementPageState();
}

class _CashSessionManagementPageState extends State<CashSessionManagementPage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'CashSessionManagementController',
      scope: <String, Object?>{
        'identity': identityHashCode(this),
        'embedded': widget.embedded,
      },
    );
    _registerController();
  }

  @override
  void didUpdateWidget(covariant CashSessionManagementPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startNew && !oldWidget.startNew) {
      final controller = Get.find<CashSessionManagementController>(
        tag: _controllerTag,
      );
      controller.startNewSession(isDesktop: true);
      return;
    }
    if (widget.initialId != oldWidget.initialId && widget.initialId != null) {
      final controller = Get.find<CashSessionManagementController>(
        tag: _controllerTag,
      );
      controller.loadPage(selectId: widget.initialId);
    }
  }

  @override
  void dispose() {
    if (Get.isRegistered<CashSessionManagementController>(
      tag: _controllerTag,
    )) {
      Get.delete<CashSessionManagementController>(
        tag: _controllerTag,
        force: true,
      );
    }
    super.dispose();
  }

  void _registerController() {
    if (Get.isRegistered<CashSessionManagementController>(
      tag: _controllerTag,
    )) {
      return;
    }
    Get.put(
      CashSessionManagementController(
        initialId: widget.initialId,
        startNew: widget.startNew,
      ),
      tag: _controllerTag,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CashSessionManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = _buildContent(context, controller);
        final actions = <Widget>[
          if (!widget.editorOnly)
            AdaptiveShellActionButton(
              onPressed: () => controller.startNewSession(
                isDesktop: Responsive.isDesktop(context),
              ),
              icon: Icons.point_of_sale_outlined,
              label: 'Open Session',
            ),
        ];

        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }

        return AppStandaloneShell(
          title: 'Cash Sessions',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    CashSessionManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading cash sessions...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load cash sessions',
        message: controller.pageError!,
        onRetry: controller.loadPage,
      );
    }

    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Cash Sessions',
      editorTitle: controller.selectedSession?.toString(),
      editorOnly: widget.editorOnly,
      scrollController: controller.pageScrollController,
      list: SettingsListCard<CashSessionModel>(
        searchController: controller.searchController,
        searchHint: 'Search cash sessions',
        items: controller.filteredSessions,
        selectedItem: controller.selectedSession,
        emptyMessage: 'No cash sessions found.',
        paginationMeta: controller.paginationMeta,
        onPageChanged: controller.setPage,
        itemBuilder: (item, selected) => SettingsListTile(
          title: item.cashAccountName ?? item.cashAccountCode ?? '',
          subtitle: [
            item.userDisplayName ?? item.username ?? '',
            item.status ?? '',
            item.openingDatetime?.split(' ').first ?? '',
          ].where((value) => value.isNotEmpty).join(' · '),
          selected: selected,
          onTap: () => controller.selectSession(item),
        ),
      ),
      editorBuilder: (_) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.formError != null) ...[
            AppErrorStateView.inline(message: controller.formError!),
            const SizedBox(height: AppUiConstants.spacingSm),
          ],
          Text('Current User', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(controller.currentUserLabel ?? 'Unknown user'),
          const SizedBox(height: AppUiConstants.spacingMd),
          Form(
            key: controller.openFormKey,
            child: SettingsFormWrap(
              children: [
                AppDropdownField<int>.fromMapped(
                  labelText: 'Cash Account',
                  mappedItems: controller.cashAccountOptions
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: controller.cashAccountId,
                  onChanged: controller.setCashAccountId,
                  validator: Validators.requiredSelection('Cash Account'),
                ),
                AppFormTextField(
                  labelText: 'Opening Datetime',
                  controller: controller.openingDatetimeController,
                  hintText: 'Leave blank to use server time',
                  validator: Validators.dateTime('Opening Datetime'),
                ),
                AppFormTextField(
                  labelText: 'Opening Balance',
                  controller: controller.openingBalanceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.compose([
                    Validators.required('Opening Balance'),
                    Validators.optionalNonNegativeNumber('Opening Balance'),
                  ]),
                ),
                AppFormTextField(
                  labelText: 'Remarks',
                  controller: controller.remarksController,
                  maxLines: 3,
                  validator: Validators.optionalMaxLength(1000, 'Remarks'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          Wrap(
            spacing: AppUiConstants.spacingSm,
            runSpacing: AppUiConstants.spacingSm,
            children: [
              if (widget.editorOnly)
                AppActionButton(
                  icon: Icons.close_outlined,
                  label: 'Cancel',
                  filled: false,
                  onPressed: () => Get.back(),
                ),
              AppActionButton(
                icon: Icons.play_circle_outline,
                label: 'Open Session',
                onPressed: controller.openSession,
                busy: controller.saving,
              ),
            ],
          ),
          if (controller.selectedSession != null) ...[
            const SizedBox(height: AppUiConstants.spacingLg),
            Divider(color: Theme.of(context).dividerColor),
            const SizedBox(height: AppUiConstants.spacingMd),
            Text(
              'Close Or Cancel Selected Session',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            Form(
              key: controller.closeFormKey,
              child: SettingsFormWrap(
                children: [
                  AppFormTextField(
                    labelText: 'Closing Datetime',
                    controller: controller.closingDatetimeController,
                    validator: controller.isOpen
                        ? Validators.dateTime('Closing Datetime')
                        : null,
                    hintText: 'Leave blank to use server time',
                  ),
                  AppFormTextField(
                    labelText: 'Expected Closing Balance',
                    controller: controller.expectedClosingController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: controller.isOpen
                        ? Validators.compose([
                            Validators.required('Expected Closing Balance'),
                            Validators.optionalNonNegativeNumber(
                              'Expected Closing Balance',
                            ),
                          ])
                        : null,
                  ),
                  AppFormTextField(
                    labelText: 'Actual Closing Balance',
                    controller: controller.actualClosingController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: controller.isOpen
                        ? Validators.compose([
                            Validators.required('Actual Closing Balance'),
                            Validators.optionalNonNegativeNumber(
                              'Actual Closing Balance',
                            ),
                          ])
                        : null,
                  ),
                  AppFormTextField(
                    labelText: 'Remarks',
                    controller: controller.closingRemarksController,
                    maxLines: 3,
                    validator: Validators.optionalMaxLength(1000, 'Remarks'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            Wrap(
              spacing: AppUiConstants.spacingSm,
              runSpacing: AppUiConstants.spacingSm,
              children: [
                if (widget.editorOnly)
                  AppActionButton(
                    icon: Icons.close_outlined,
                    label: 'Cancel',
                    filled: false,
                    onPressed: () => Get.back(),
                  ),
                if (controller.isOpen)
                  AppActionButton(
                    icon: Icons.stop_circle_outlined,
                    label: 'Close Session',
                    onPressed: controller.closeSession,
                    busy: controller.saving,
                  ),
                if ((controller.selectedSession?.status ?? '') != 'closed')
                  AppActionButton(
                    icon: Icons.cancel_outlined,
                    label: 'Cancel Session',
                    onPressed: controller.cancelSession,
                    busy: controller.saving,
                    filled: false,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
