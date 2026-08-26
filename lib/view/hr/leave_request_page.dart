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
  bool _filtersVisible = false;

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

  Widget _buildInlineLeaveFilters(LeaveRequestManagementController controller) {
    return HrInlineFilterBar(
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
            child: AppDropdownField<int>.fromMapped(
              labelText: 'Employee',
              mappedItems: controller.employees
                  .where(
                    (e) =>
                        e.companyId == controller.sessionCompanyId &&
                        e.id != null,
                  )
                  .map(
                    (e) =>
                        AppDropdownItem<int>(value: e.id!, label: e.toString()),
                  )
                  .toList(growable: false),
              multiInitialValues: controller.listFilterEmployeeIds,
              multiHintText: 'Select employees',
              onMultiChanged: controller.setListFilterEmployeeIds,
            ),
          ),
          hrListFilterBox(
            child: AppDropdownField<String>.fromMapped(
              labelText: 'Status',
              mappedItems: LeaveRequestManagementController
                  .listStatusFilterItems
                  .where((item) => item.value != null)
                  .map(
                    (item) => AppDropdownItem<String>(
                      value: item.value!,
                      label: item.label,
                    ),
                  )
                  .toList(growable: false),
              multiInitialValues: controller.listFilterStatuses,
              multiHintText: 'Select statuses',
              onMultiChanged: controller.setListFilterStatuses,
            ),
          ),
        ],
        hrListFilterBox(
          child: AppFormTextField(
            controller: controller.listDateFromController,
            labelText: 'From date',
            keyboardType: TextInputType.datetime,
            inputFormatters: const [DateInputFormatter()],
          ),
        ),
        hrListFilterBox(
          child: AppFormTextField(
            controller: controller.listDateToController,
            labelText: 'To date',
            keyboardType: TextInputType.datetime,
            inputFormatters: const [DateInputFormatter()],
          ),
        ),
      ],
      onClear: () {
        controller.clearLeaveListFilters();
        unawaited(controller.loadData());
      },
    );
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
            filled: _filtersVisible,
            onPressed: () => setState(() => _filtersVisible = !_filtersVisible),
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
      fullWidthHeader: _filtersVisible
          ? _buildInlineLeaveFilters(controller)
          : null,
      list: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsListCard<LeaveRequestModel>(
            searchController: controller.searchController,
            searchHint: 'Search leave requests',
            showSearchBar: false,
            items: controller.filteredLeaveRequests,
            selectedItem: controller.selectedLeaveRequest,
            emptyMessage: 'No leave requests found.',
            paginationMeta: controller.paginationMeta,
            onPageChanged: controller.goToPage,
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
      editorBuilder: (_) => Form(
        child: Builder(
          builder: (formContext) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (controller.formError != null) ...[
                AppErrorStateView.inline(message: controller.formError!),
                const SizedBox(height: AppUiConstants.spacingSm),
              ],
              SettingsFormWrap(
                children: [
                  AppFormTextField(
                    labelText: 'Employee',
                    initialValue:
                        controller.formEmployee?.toString() ??
                        'No employee linked to this user',
                    readOnly: true,
                  ),
                  AppDropdownField<int>.fromMapped(
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
                  AppFormTextField(
                    labelText: 'Status',
                    initialValue:
                        controller.selectedLeaveRequest?.status ?? 'pending',
                    readOnly: true,
                  ),
                  AppFormTextField(
                    controller: controller.reasonController,
                    labelText: 'Reason',
                    maxLines: 3,
                    validator: Validators.optionalMaxLength(1000, 'Reason'),
                  ),
                  if (controller.activeLeaveType != null) ...[
                    const SizedBox(height: AppUiConstants.spacingSm),
                    Text(
                      'Paid entitlement and accrual follow your company leave policy. '
                      'If the balance is insufficient, excess days become LOP or the '
                      'request is rejected according to that policy. The split is '
                      'recalculated when HR approves.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (controller.selectedLeaveRequest != null &&
                      ((controller.selectedLeaveRequest!.paidLeaveDays ??
                                  controller
                                      .selectedLeaveRequest!
                                      .clApprovedDays ??
                                  0) >
                              0 ||
                          (controller.selectedLeaveRequest!.lopDays ?? 0) >
                              0)) ...[
                    const SizedBox(height: AppUiConstants.spacingSm),
                    Text(
                      'Paid leave days: ${controller.selectedLeaveRequest!.paidLeaveDays ?? controller.selectedLeaveRequest!.clApprovedDays ?? 0} · '
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
                        : () =>
                              controller.save(formState: Form.of(formContext)),
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
                  if (controller.canApproveSelectedLeaveRequest) ...[
                    AppActionButton(
                      icon: Icons.check_circle_outline,
                      label: 'Approve',
                      onPressed: controller.saving
                          ? null
                          : controller.approveSelectedLeaveRequest,
                      busy: controller.saving,
                    ),
                    AppActionButton(
                      icon: Icons.cancel_outlined,
                      label: 'Reject',
                      onPressed: controller.saving
                          ? null
                          : controller.rejectSelectedLeaveRequest,
                      busy: controller.saving,
                      filled: false,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
