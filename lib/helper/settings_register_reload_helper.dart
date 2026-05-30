import 'dart:async';
import 'package:get/get.dart';
import '../controller/settings/accounting/account_group_management_controller.dart';
import '../controller/settings/accounting/bank_reconciliation_management_controller.dart';
import '../controller/settings/accounting/budget_management_controller.dart';
import '../controller/settings/accounting/cash_session_management_controller.dart';
import '../controller/settings/accounting/document_posting_management_controller.dart';
import '../controller/settings/accounting/party_account_register_controller.dart';
import '../controller/settings/accounting/posting_rule_group_management_controller.dart';
import '../controller/settings/accounting/posting_rule_management_controller.dart';
import '../controller/settings/accounting/voucher_management_controller.dart';
import '../controller/settings/accounting/voucher_type_management_controller.dart';

void reloadPartyAccountRegister() {
  if (Get.isRegistered<PartyAccountRegisterController>(
    tag: 'PartyAccountRegisterController',
  )) {
    unawaited(
      Get.find<PartyAccountRegisterController>(
        tag: 'PartyAccountRegisterController',
      ).load(),
    );
  }
}

void reloadVoucherRegister() {
  if (Get.isRegistered<VoucherManagementController>(
    tag: 'VoucherManagementController',
  )) {
    unawaited(
      Get.find<VoucherManagementController>(
        tag: 'VoucherManagementController',
      ).loadPage(),
    );
  }
}

void reloadDocumentPostingRegister() {
  if (Get.isRegistered<DocumentPostingManagementController>(
    tag: 'DocumentPostingManagementController',
  )) {
    unawaited(
      Get.find<DocumentPostingManagementController>(
        tag: 'DocumentPostingManagementController',
      ).loadPage(),
    );
  }
}

void reloadPostingRuleGroupRegister() {
  if (Get.isRegistered<PostingRuleGroupManagementController>(
    tag: 'PostingRuleGroupManagementController',
  )) {
    unawaited(
      Get.find<PostingRuleGroupManagementController>(
        tag: 'PostingRuleGroupManagementController',
      ).load(),
    );
  }
}

void reloadPostingRuleRegister() {
  if (Get.isRegistered<PostingRuleManagementController>(
    tag: 'PostingRuleManagementController',
  )) {
    unawaited(
      Get.find<PostingRuleManagementController>(
        tag: 'PostingRuleManagementController',
      ).load(),
    );
  }
}

void reloadBudgetRegister() {
  if (Get.isRegistered<BudgetManagementController>(
    tag: 'BudgetManagementController',
  )) {
    unawaited(
      Get.find<BudgetManagementController>(
        tag: 'BudgetManagementController',
      ).loadPage(),
    );
  }
}

void reloadCashSessionRegister() {
  if (Get.isRegistered<CashSessionManagementController>(
    tag: 'CashSessionManagementController',
  )) {
    unawaited(
      Get.find<CashSessionManagementController>(
        tag: 'CashSessionManagementController',
      ).loadPage(),
    );
  }
}

void reloadVoucherTypeRegister() {
  if (Get.isRegistered<VoucherTypeManagementController>(
    tag: 'VoucherTypeManagementController',
  )) {
    unawaited(
      Get.find<VoucherTypeManagementController>(
        tag: 'VoucherTypeManagementController',
      ).loadTypes(),
    );
  }
}

void reloadAccountGroupRegister() {
  if (Get.isRegistered<AccountGroupManagementController>(
    tag: 'AccountGroupManagementController',
  )) {
    unawaited(
      Get.find<AccountGroupManagementController>(
        tag: 'AccountGroupManagementController',
      ).loadGroups(),
    );
  }
}

void reloadBankReconciliationRegister() {
  if (Get.isRegistered<BankReconciliationManagementController>(
    tag: 'BankReconciliationManagementController',
  )) {
    unawaited(
      Get.find<BankReconciliationManagementController>(
        tag: 'BankReconciliationManagementController',
      ).loadPage(),
    );
  }
}
