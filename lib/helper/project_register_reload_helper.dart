import 'dart:async';
import 'package:get/get.dart';
import '../controller/project/project_management_controller.dart';
import '../controller/project/project_task_management_controller.dart';
import '../controller/project/project_billing_management_controller.dart';
import '../controller/project/project_expense_management_controller.dart';
import '../controller/project/project_milestone_management_controller.dart';
import '../controller/project/project_resource_usage_management_controller.dart';
import '../controller/project/project_timesheet_management_controller.dart';
import '../controller/project/project_vendor_work_management_controller.dart';

void reloadProjectRegister() {
  if (Get.isRegistered<ProjectManagementController>(tag: 'ProjectManagementController')) {
    unawaited(Get.find<ProjectManagementController>(tag: 'ProjectManagementController').loadData());
  }
}

void reloadProjectTaskRegister() {
  if (Get.isRegistered<ProjectTaskManagementController>(tag: 'ProjectTaskManagementController')) {
    unawaited(Get.find<ProjectTaskManagementController>(tag: 'ProjectTaskManagementController').loadData());
  }
}

void reloadProjectBillingRegister() {
  if (Get.isRegistered<ProjectBillingManagementController>(tag: 'ProjectBillingManagementController')) {
    unawaited(Get.find<ProjectBillingManagementController>(tag: 'ProjectBillingManagementController').loadData());
  }
}

void reloadProjectExpenseRegister() {
  if (Get.isRegistered<ProjectExpenseManagementController>(tag: 'ProjectExpenseManagementController')) {
    unawaited(Get.find<ProjectExpenseManagementController>(tag: 'ProjectExpenseManagementController').loadData());
  }
}

void reloadProjectMilestoneRegister() {
  if (Get.isRegistered<ProjectMilestoneManagementController>(tag: 'ProjectMilestoneManagementController')) {
    unawaited(Get.find<ProjectMilestoneManagementController>(tag: 'ProjectMilestoneManagementController').loadData());
  }
}

void reloadProjectResourceUsageRegister() {
  if (Get.isRegistered<ProjectResourceUsageManagementController>(tag: 'ProjectResourceUsageManagementController')) {
    unawaited(Get.find<ProjectResourceUsageManagementController>(tag: 'ProjectResourceUsageManagementController').loadData());
  }
}

void reloadProjectTimesheetRegister() {
  if (Get.isRegistered<ProjectTimesheetManagementController>(tag: 'ProjectTimesheetManagementController')) {
    unawaited(Get.find<ProjectTimesheetManagementController>(tag: 'ProjectTimesheetManagementController').loadData());
  }
}

void reloadProjectVendorWorkRegister() {
  if (Get.isRegistered<ProjectVendorWorkManagementController>(tag: 'ProjectVendorWorkManagementController')) {
    unawaited(Get.find<ProjectVendorWorkManagementController>(tag: 'ProjectVendorWorkManagementController').loadData());
  }
}
