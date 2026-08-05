import '../../../controller/settings/system/cache_controls_management_controller.dart';
import '../../../screen.dart';

class CacheControlsPage extends StatefulWidget {
  const CacheControlsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<CacheControlsPage> createState() => _CacheControlsPageState();
}

class _CacheControlsPageState extends State<CacheControlsPage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'CacheControlsManagementController',
    );
    Get.put(CacheControlsManagementController(), tag: _controllerTag);
  }

  @override
  void dispose() {
    if (Get.isRegistered<CacheControlsManagementController>(
      tag: _controllerTag,
    )) {
      Get.delete<CacheControlsManagementController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CacheControlsManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = _SystemToolsContent(controller: controller);
        if (widget.embedded) {
          return ShellPageActions(actions: const <Widget>[], child: content);
        }
        return AppStandaloneShell(
          title: 'System Tools',
          scrollController: controller.pageScrollController,
          actions: const <Widget>[],
          child: content,
        );
      },
    );
  }
}

class _SystemToolsContent extends StatelessWidget {
  const _SystemToolsContent({required this.controller});

  final CacheControlsManagementController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppUiConstants.pagePadding),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cards = <Widget>[
              _SystemToolCard(
                title: 'Clear Cache',
                icon: Icons.cleaning_services_outlined,
                description:
                    'Clear browser data kept by this Billing ERP app. The server is not changed.',
                buttonLabel: controller.clearingCache
                    ? 'Clearing...'
                    : 'Clear Cache',
                busy: controller.clearingCache,
                onPressed: () => _confirmClearCache(context),
              ),
              _SystemToolCard(
                title: 'Backup Database',
                icon: Icons.backup_outlined,
                description:
                    'Download an SQL backup of the current Billing ERP database.',
                buttonLabel: controller.downloadingBackup
                    ? 'Preparing...'
                    : 'Download',
                busy: controller.downloadingBackup,
                onPressed: () => _confirmBackup(context),
              ),
            ];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'System Tools',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppUiConstants.spacingSm),
                Text(
                  'Administrative maintenance actions for Billing ERP.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(
                      context,
                    ).extension<AppThemeExtension>()!.mutedText,
                  ),
                ),
                const SizedBox(height: AppUiConstants.spacingXl),
                if (constraints.maxWidth >=
                    AppUiConstants.dashboardSplitBreakpoint)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: cards.first),
                      const SizedBox(width: AppUiConstants.spacingXl),
                      Expanded(child: cards.last),
                    ],
                  )
                else
                  ...cards
                      .expand(
                        (card) => <Widget>[
                          card,
                          const SizedBox(height: AppUiConstants.spacingXl),
                        ],
                      )
                      .toList()
                    ..removeLast(),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmClearCache(BuildContext context) async {
    final confirmed = await _confirm(
      context,
      title: 'Clear cache?',
      message:
          'This clears only browser/app cache. The server and database are not changed.',
      confirmLabel: 'Clear Cache',
    );
    if (confirmed) {
      await controller.clearCache();
    }
  }

  Future<void> _confirmBackup(BuildContext context) async {
    final confirmed = await _confirm(
      context,
      title: 'Download database backup?',
      message: 'The SQL file contains Billing ERP data. Store it securely.',
      confirmLabel: 'Download',
    );
    if (confirmed) {
      await controller.downloadDatabaseBackup();
    }
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _SystemToolCard extends StatelessWidget {
  const _SystemToolCard({
    required this.title,
    required this.icon,
    required this.description,
    required this.buttonLabel,
    required this.busy,
    required this.onPressed,
  });

  final String title;
  final IconData icon;
  final String description;
  final String buttonLabel;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: ExpansionTile(
        leading: Icon(icon),
        title: Text(title),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppUiConstants.spacingLg,
          0,
          AppUiConstants.spacingLg,
          AppUiConstants.spacingLg,
        ),
        children: [
          Align(alignment: Alignment.centerLeft, child: Text(description)),
          const SizedBox(height: AppUiConstants.spacingLg),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: busy ? null : onPressed,
              icon: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(icon),
              label: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}
