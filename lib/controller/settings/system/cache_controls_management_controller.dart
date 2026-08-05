import '../../../screen.dart';

class CacheControlsManagementController extends GetxController {
  final AdminService _adminService = AdminService();
  final ScrollController pageScrollController = ScrollController();

  bool clearingCache = false;
  bool downloadingBackup = false;

  @override
  void onClose() {
    pageScrollController.dispose();
    super.onClose();
  }

  Future<void> clearCache() async {
    if (clearingCache) {
      return;
    }

    clearingCache = true;
    update();
    try {
      MasterDataCache.ensureRegistered().clearAllCaches();
      appScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Browser cache cleared.')),
      );
    } catch (error) {
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Could not clear cache: $error')),
      );
    } finally {
      clearingCache = false;
      update();
    }
  }

  Future<void> downloadDatabaseBackup() async {
    if (downloadingBackup) {
      return;
    }

    downloadingBackup = true;
    update();
    try {
      final backup = await _adminService.downloadDatabaseBackup();
      final saved = await saveBytesFile(
        suggestedName:
            'billing_database_${DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first}.sql',
        bytes: backup,
        mimeType: 'application/sql',
      );
      if (saved) {
        appScaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Database backup downloaded.')),
        );
      }
    } catch (error) {
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Could not download backup: $error')),
      );
    } finally {
      downloadingBackup = false;
      update();
    }
  }
}
