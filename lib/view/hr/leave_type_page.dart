import '../../controller/hr/leave_type_management_controller.dart';
import '../../screen.dart';

class LeaveTypeManagementPage extends StatefulWidget {
  const LeaveTypeManagementPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<LeaveTypeManagementPage> createState() =>
      _LeaveTypeManagementPageState();
}

class _LeaveTypeManagementPageState extends State<LeaveTypeManagementPage> {
  late final String _controllerTag;
  final GlobalKey<FormState> _leaveTypeFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag('LeaveTypeManagementController');
    Get.put(
      LeaveTypeManagementController(
        initialSelectId: widget.initialId,
        startInNewMode: widget.editorOnly && widget.initialId == null,
      ),
      tag: _controllerTag,
      permanent: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LeaveTypeManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () =>
                openFormScreenRoute(context, '/hr/leave-types/new'),
            icon: Icons.beach_access_outlined,
            label: 'New Leave Type',
          ),
        ];

        if (!widget.editorOnly) {
          return _buildSharedRegister(controller, actions);
        }

        final content = _buildContent(controller);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }

        return AppStandaloneShell(
          title: 'Leave Types',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildSharedRegister(
    LeaveTypeManagementController controller,
    List<Widget> actions,
  ) {
    return SharedRegisterList<LeaveTypeModel>(
      title: 'Leave Types',
      embedded: widget.embedded,
      loading: controller.initialLoading,
      errorMessage: controller.pageError,
      onRetry: controller.loadLeaveTypes,
      actions: actions,
      rows: controller.filteredLeaveTypes,
      emptyMessage: 'No leave type records found.',
      columns: [
        PurchaseRegisterColumn<LeaveTypeModel>(
          label: 'Leave Type Name',
          flex: 2,
          valueBuilder: (row) => row.leaveName ?? '-',
        ),
        PurchaseRegisterColumn<LeaveTypeModel>(
          label: 'Code',
          valueBuilder: (row) => row.leaveCode ?? '-',
        ),
        PurchaseRegisterColumn<LeaveTypeModel>(
          label: 'Max Days/Year',
          alignRight: true,
          valueBuilder: (row) =>
              row.maxDaysPerYear != null ? formatAmount(row.maxDaysPerYear) : '-',
        ),
        PurchaseRegisterColumn<LeaveTypeModel>(
          label: 'Paid / Unpaid',
          valueBuilder: (row) => row.isPaid ? 'Paid' : 'Unpaid',
        ),
      ],
      onRowTap: (row) {
        final id = row.id;
        if (id != null) {
          openFormScreenRoute(context, '/hr/leave-types/$id');
        }
      },
    );
  }

  Widget _buildContent(LeaveTypeManagementController controller) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading leave types...');
    }

    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load leave types',
        message: controller.pageError!,
        onRetry: controller.loadLeaveTypes,
      );
    }

    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Leave Types',
      editorTitle: controller.selectedLeaveType?.toString(),
      scrollController: controller.pageScrollController,
      editorOnly: widget.editorOnly,
      list: SettingsListCard<LeaveTypeModel>(
        searchController: controller.searchController,
        searchHint: 'Search leave types',
        items: controller.filteredLeaveTypes,
        selectedItem: controller.selectedLeaveType,
        emptyMessage: 'No leave type records found.',
        paginationMeta: controller.paginationMeta,
        onPageChanged: controller.goToPage,
        itemBuilder: (item, selected) => SettingsListTile(
          title: item.leaveName ?? '-',
          subtitle: [
            if (item.maxDaysPerYear != null)
              'Max ${formatAmount(item.maxDaysPerYear)} days',
            item.isPaid ? 'Paid' : 'Unpaid',
          ].join(' • '),
          selected: selected,
          onTap: () {
            final id = item.id;
            if (id != null) {
              openFormScreenRoute(context, '/hr/leave-types/$id');
            }
          },
        ),
      ),
      editorBuilder: (_) => Form(
        key: _leaveTypeFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (controller.formError != null) ...[
              AppErrorStateView.inline(message: controller.formError!),
              const SizedBox(height: AppUiConstants.spacingSm),
            ],
            SettingsFormWrap(
              children: [
                AppFormTextField(
                  labelText: 'Leave Name',
                  controller: controller.leaveNameController,
                  validator: Validators.compose([
                    Validators.required('Leave Name'),
                    Validators.optionalMaxLength(100, 'Leave Name'),
                  ]),
                ),
                AppFormTextField(
                  labelText: 'Max Days Per Year',
                  controller: controller.maxDaysController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.optionalNonNegativeNumber(
                    'Max Days Per Year',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            AppSwitchTile(
              label: 'Paid Leave',
              value: controller.isPaid,
              onChanged: controller.setIsPaid,
            ),
            const SizedBox(height: AppUiConstants.spacingLg),
            Wrap(
              spacing: AppUiConstants.spacingSm,
              runSpacing: AppUiConstants.spacingSm,
              children: [
                AppActionButton(
                  icon: Icons.save_outlined,
                  label: controller.selectedLeaveType == null
                      ? 'Save Leave Type'
                      : 'Update Leave Type',
                  onPressed: controller.saving
                      ? null
                      : () => controller.save(
                          formState: _leaveTypeFormKey.currentState,
                        ),
                  busy: controller.saving,
                ),
                if (controller.selectedLeaveType?.id != null)
                  AppActionButton(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    onPressed: controller.delete,
                    busy: controller.saving,
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
