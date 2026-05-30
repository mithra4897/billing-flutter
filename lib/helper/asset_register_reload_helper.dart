import 'dart:async';
import 'package:get/get.dart';
import '../model/assets/asset_category_model.dart';
import '../model/assets/cost_center_model.dart';
import '../model/assets/asset_model.dart';
import '../model/assets/asset_depreciation_run_model.dart';
import '../model/assets/asset_transfer_model.dart';
import '../model/assets/asset_disposal_model.dart';
import '../view/assets/asset_registers.dart';

void reloadAssetCategoryRegister() {
  if (Get.isRegistered<AssetRegisterController<AssetCategoryModel>>(tag: 'AssetCategoryRegisterController')) {
    unawaited(Get.find<AssetRegisterController<AssetCategoryModel>>(tag: 'AssetCategoryRegisterController').load());
  }
}

void reloadAssetCostCenterRegister() {
  if (Get.isRegistered<AssetRegisterController<CostCenterModel>>(tag: 'AssetCostCenterRegisterController')) {
    unawaited(Get.find<AssetRegisterController<CostCenterModel>>(tag: 'AssetCostCenterRegisterController').load());
  }
}

void reloadFixedAssetRegister() {
  if (Get.isRegistered<AssetRegisterController<AssetModel>>(tag: 'FixedAssetRegisterController')) {
    unawaited(Get.find<AssetRegisterController<AssetModel>>(tag: 'FixedAssetRegisterController').load());
  }
}

void reloadAssetDepreciationRunRegister() {
  if (Get.isRegistered<AssetRegisterController<AssetDepreciationRunModel>>(tag: 'AssetDepreciationRunRegisterController')) {
    unawaited(Get.find<AssetRegisterController<AssetDepreciationRunModel>>(tag: 'AssetDepreciationRunRegisterController').load());
  }
}

void reloadAssetTransferRegister() {
  if (Get.isRegistered<AssetRegisterController<AssetTransferModel>>(tag: 'AssetTransferRegisterController')) {
    unawaited(Get.find<AssetRegisterController<AssetTransferModel>>(tag: 'AssetTransferRegisterController').load());
  }
}

void reloadAssetDisposalRegister() {
  if (Get.isRegistered<AssetRegisterController<AssetDisposalModel>>(tag: 'AssetDisposalRegisterController')) {
    unawaited(Get.find<AssetRegisterController<AssetDisposalModel>>(tag: 'AssetDisposalRegisterController').load());
  }
}

