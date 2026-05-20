import '../../screen.dart';

class PurchaseRegisterPageController extends GetxController {
  PurchaseRegisterPageController();

  final ScrollController pageScrollController = ScrollController();
  int currentPage = 1;

  @override
  void onClose() {
    pageScrollController.dispose();
    super.onClose();
  }

  void resetPage() {
    currentPage = 1;
    update();
  }

  void setPage(int page) {
    currentPage = page;
    update();
  }

  void clampToTotalPages(int totalPages) {
    final clamped = totalPages <= 0 ? 1 : totalPages;
    if (currentPage > clamped) {
      currentPage = clamped;
      update();
    }
  }
}
