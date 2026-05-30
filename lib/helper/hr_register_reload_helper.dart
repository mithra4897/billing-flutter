import 'dart:async';
import 'package:get/get.dart';
import '../controller/hr/expense_claims_management_controller.dart';
import '../controller/hr/hr_statutory_settings_controller.dart';
import '../view/hr/hr_registers.dart';

void reloadAttendanceRegister() {
  if (Get.isRegistered<AttendanceRegisterController>(
    tag: 'AttendanceRegisterController',
  )) {
    unawaited(
      Get.find<AttendanceRegisterController>(
        tag: 'AttendanceRegisterController',
      ).load(),
    );
  }
}

void reloadPayrollRunRegister() {
  if (Get.isRegistered<PayrollRunRegisterController>(
    tag: 'PayrollRunRegisterController',
  )) {
    unawaited(
      Get.find<PayrollRunRegisterController>(
        tag: 'PayrollRunRegisterController',
      ).load(),
    );
  }
}

void reloadPayslipRegister() {
  if (Get.isRegistered<PayslipRegisterController>(
    tag: 'PayslipRegisterController',
  )) {
    unawaited(
      Get.find<PayslipRegisterController>(
        tag: 'PayslipRegisterController',
      ).load(),
    );
  }
}

void reloadExpenseClaimRegister() {
  if (Get.isRegistered<ExpenseClaimsManagementController>(
    tag: 'ExpenseClaimsManagementController',
  )) {
    unawaited(
      Get.find<ExpenseClaimsManagementController>(
        tag: 'ExpenseClaimsManagementController',
      ).loadPage(),
    );
  }
}

void reloadHrStatutorySettingsRegister() {
  if (Get.isRegistered<HrStatutorySettingsController>(
    tag: 'HrStatutorySettingsController',
  )) {
    unawaited(
      Get.find<HrStatutorySettingsController>(
        tag: 'HrStatutorySettingsController',
      ).load(),
    );
  }
}
