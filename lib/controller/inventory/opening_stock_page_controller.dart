import '../../screen.dart';

class OpeningStockPageController extends GetxController {
  OpeningStockPageController();

  bool showDraftTile = false;

  void setShowDraftTile(bool value) {
    showDraftTile = value;
    update();
  }
}
