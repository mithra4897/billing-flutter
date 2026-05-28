import '../../controller/hr/leave_request_management_controller.dart';
import '../../screen.dart';

class LeaveRequestManagementPage extends StatefulWidget {
  const LeaveRequestManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<LeaveRequestManagementPage> createState() =>
      _LeaveRequestManagementPageState();
}

class _LeaveRequestManagementPageState
    extends State<LeaveRequestManagementPage> {
  late final String _controllerTag;
  final GlobalKey<FormState> _leaveRequestFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'LeaveRequestManagementController',
    );
    Get.put(
      LeaveRequestManagementController(),
      tag: _controllerTag,
      permanent: true,
    );
  }

  Future<void> _openCreateLeaveTypeDialog() async {
    final controller = Get.find<LeaveRequestManagementController>(
      tag: _controllerTag,
    );
    final nameController = TextEditingController();
    final maxDaysController = TextEditingController();
    var isPaid = true;
    String? errorText;

    final created = await showDialog<LeaveTypeModel>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Create Leave Type'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppFormTextField(
                    controller: nameController,
                    labelText: 'Leave Name',
                  ),
                  const SizedBox(height: AppUiConstants.spacingSm),
                  AppFormTextField(
                    controller: maxDaysController,
                    labelText: 'Max Days Per Year',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: AppUiConstants.spacingSm),
                  AppSwitchTile(
                    label: 'Paid Leave',
                    value: isPaid,
                    onChanged: (value) => setDialogState(() => isPaid = value),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: AppUiConstants.spacingSm),
                    Text(
                      errorText!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final leaveName = nameController.text.trim();
                    if (leaveName.isEmpty) {
                      setDialogState(() {
                        errorText = 'Leave Name is required.';
                      });
                      return;
                    }
                    try {
                      final response = await controller.createLeaveType(
                        leaveName: leaveName,
                        maxDays: maxDaysController.text,
                        isPaidValue: isPaid,
                      );
                      if (!dialogContext.mounted) return;
                      Navigator.of(dialogContext).pop(response);
                    } catch (error) {
                      setDialogState(() {
                        errorText = error.toString();
                      });
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    if (created?.id == null || !mounted) {
      return;
    }
  }

  Future<void> _openLeaveListFilterPanel() async {
    final controller = Get.find<LeaveRequestManagementController>(
      tag: _controllerTag,
    );
    final applied = await showHrListFilterDialog(
      context: context,
      title: 'Filter Leave Requests',
      header: controller.companyBanner == null
          ? null
          : Text(
              'Session company: ${controller.companyBanner}. Change via the header '
              'session button.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
      filterFields: [
        hrListFilterBox(
          child: AppFormTextField(
            controller: controller.searchController,
            labelText: 'Search',
            hintText: 'Search leave requests',
          ),
        ),
        if (controller.canViewAllHr) ...[
          hrListFilterBox(
            child: AppDropdownField<int?>.fromMapped(
              labelText: 'Employee filter',
              mappedItems: <AppDropdownItem<int?>>[
                const AppDropdownItem<int?>(
                  value: null,
                  label: 'All employees',
                ),
                ...controller.employees
                    .where(
                      (e) =>
                          e.companyId == controller.sessionCompanyId &&
                          e.id != null,
                    )
                    .map(
                      (e) => AppDropdownItem<int?>(
                        value: e.id,
                        label: e.toString(),
                      ),
                    ),
              ],
              initialValue: controller.listFilterEmployeeId,
              onChanged: controller.setListFilterEmployeeId,
            ),
          ),
          hrListFilterBox(
            child: AppDropdownField<String?>.fromMapped(
              labelText: 'Status filter',
              mappedItems:
                  LeaveRequestManagementController.listStatusFilterItems,
              initialValue: controller.listFilterStatus,
              onChanged: controller.setListFilterStatus,
            ),
          ),
        ],
        hrListFilterBox(
          child: AppFormTextField(
            controller: controller.listDateFromController,
            labelText: 'List from date',
            hintText: 'Filter overlapping from…',
            keyboardType: TextInputType.datetime,
            inputFormatters: const [DateInputFormatter()],
          ),
        ),
        hrListFilterBox(
          child: AppFormTextField(
            controller: controller.listDateToController,
            labelText: 'List to date',
            hintText: 'Filter overlapping to…',
            keyboardType: TextInputType.datetime,
            inputFormatters: const [DateInputFormatter()],
          ),
        ),
      ],
      onClear: controller.clearLeaveListFilters,
    );
    if (applied == true && mounted) {
      await controller.loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LeaveRequestManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = _buildContent(controller);
        final actions = <Widget>[
          AdaptiveShellActionButton(
            icon: Icons.filter_alt_outlined,
            label: 'Filter',
            filled: false,
            onPressed: _openLeaveListFilterPanel,
          ),
          AdaptiveShellActionButton(
            onPressed: () =>
                controller.startNew(isDesktop: Responsive.isDesktop(context)),
            icon: Icons.event_available_outlined,
            label: 'New Leave Request',
          ),
        ];

        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }

        return AppStandaloneShell(
          title: 'Leave Requests',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(LeaveRequestManagementController controller) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading leave requests...');
    }

    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load leave requests',
        message: controller.pageError!,
        onRetry: controller.loadData,
      );
    }

    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Leave Requests',
      editorTitle: controller.selectedLeaveRequest?.toString(),
      scrollController: controller.pageScrollController,
      list: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          hrListAppliedFiltersCard(
            context,
            controller.leaveListAppliedFilterChips(),
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          SettingsListCard<LeaveRequestModel>(
            searchController: controller.searchController,
            searchHint: 'Search leave requests',
            showSearchBar: false,
            items: controller.filteredLeaveRequests,
            selectedItem: controller.selectedLeaveRequest,
            emptyMessage: 'No leave requests found.',
            itemBuilder: (LeaveRequestModel item, bool selected) =>
                SettingsListTile(
                  title: item.employeeName ?? item.employeeCode ?? '-',
                  subtitle: [
                    item.leaveTypeName ?? '',
                    item.fromDate ?? '',
                    item.toDate ?? '',
                    item.status ?? '',
                  ].where((String value) => value.isNotEmpty).join(' • '),
                  detail: item.reason ?? '',
                  selected: selected,
                  onTap: () => controller.selectLeaveRequest(item),
                ),
          ),
        ],
      ),
      editor: Form(
        key: _leaveRequestFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (controller.formError != null) ...[
              AppErrorStateView.inline(message: controller.formError!),
              const SizedBox(height: AppUiConstants.spacingSm),
            ],
            SettingsFormWrap(
              children: [
                AppDropdownField<int>.fromMapped(
                  labelText: 'Employee',
                  mappedItems: controller.formEmployees
                      .where((EmployeeModel item) => item.id != null)
                      .map(
                        (EmployeeModel item) => AppDropdownItem<int>(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: controller.employeeId,
                  onChanged: controller.setEmployeeId,
                  validator: Validators.requiredSelection('Employee'),
                ),
                InlineFieldAction(
                  actionTooltip: 'Create leave type',
                  onAddNew: _openCreateLeaveTypeDialog,
                  field: AppDropdownField<int>.fromMapped(
                    labelText: 'Leave Type',
                    mappedItems: controller.leaveTypes
                        .where((item) => item.id != null)
                        .map(
                          (item) => AppDropdownItem(
                            value: item.id!,
                            label: item.toString(),
                          ),
                        )
                        .toList(growable: false),
                    initialValue: controller.leaveTypeId,
                    onChanged: controller.setLeaveTypeId,
                    validator: Validators.requiredSelection('Leave Type'),
                  ),
                ),
                AppFormTextField(
                  controller: controller.fromDateController,
                  labelText: 'From Date',
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.compose([
                    Validators.required('From Date'),
                    Validators.date('From Date'),
                  ]),
                ),
                AppFormTextField(
                  controller: controller.toDateController,
                  labelText: 'To Date',
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.compose([
                    Validators.required('To Date'),
                    Validators.date('To Date'),
                    Validators.optionalDateOnOrAfter(
                      'To Date',
                      () => controller.fromDateController.text.trim(),
                      startFieldName: 'From Date',
                    ),
                  ]),
                ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Status',
                  mappedItems: LeaveRequestManagementController.statusItems,
                  initialValue: controller.status,
                  onChanged: controller.setStatus,
                ),
                AppFormTextField(
                  controller: controller.reasonController,
                  labelText: 'Reason',
                  maxLines: 3,
                  validator: Validators.optionalMaxLength(1000, 'Reason'),
                ),
                if (controller.isCasualLeaveType(
                  controller.activeLeaveType,
                )) ...[
                  const SizedBox(height: AppUiConstants.spacingSm),
                  Text(
                    'Casual leave uses 1 accrued CL day per elapsed month in the '
                    'calendar year (max 12). Any days above your CL balance are '
                    'recorded as LOP (unpaid). Split is calculated when you save '
                    'and recalculated again when HR approves (using balances as of '
                    'that day). Payroll deducts LOP when the monthly run is processed.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (controller.selectedLeaveRequest != null &&
                    ((controller.selectedLeaveRequest!.clApprovedDays ?? 0) >
                            0 ||
                        (controller.selectedLeaveRequest!.lopDays ?? 0) >
                            0)) ...[
                  const SizedBox(height: AppUiConstants.spacingSm),
                  Text(
                    'CL days (paid): ${controller.selectedLeaveRequest!.clApprovedDays ?? 0} · '
                    'LOP days (unpaid): ${controller.selectedLeaveRequest!.lopDays ?? 0}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingLg),
            Wrap(
              spacing: AppUiConstants.spacingSm,
              runSpacing: AppUiConstants.spacingSm,
              children: [
                AppActionButton(
                  icon: Icons.save_outlined,
                  label: controller.selectedLeaveRequest == null
                      ? 'Save Leave Request'
                      : 'Update Leave Request',
                  onPressed: controller.saving
                      ? null
                      : () => controller.save(
                          formState: _leaveRequestFormKey.currentState,
                        ),
                  busy: controller.saving,
                ),
                if (controller.selectedLeaveRequest?.id != null)
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
