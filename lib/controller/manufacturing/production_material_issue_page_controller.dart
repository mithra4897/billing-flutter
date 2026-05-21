import '../../screen.dart';

class ProductionMaterialIssuePageController extends GetxController {
  ProductionMaterialIssuePageController();

  bool auditLogLoading = false;

  void setAuditLogLoading(bool value) {
    auditLogLoading = value;
    update();
  }
}
