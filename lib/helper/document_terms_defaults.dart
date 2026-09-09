import 'package:get/get.dart';

import 'master_data_cache.dart';

String documentTermsDefault(String documentType) {
  if (!Get.isRegistered<MasterDataCache>()) {
    return '';
  }
  return MasterDataCache.to.documentTermsFor(documentType);
}

String documentTermsOrDefault(String? terms, String documentType) {
  final normalized = terms?.trim() ?? '';
  if (normalized.isNotEmpty) {
    return terms!;
  }
  return documentTermsDefault(documentType);
}
