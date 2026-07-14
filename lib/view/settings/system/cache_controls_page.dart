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
  Widget build(BuildContext context) {
    return GetBuilder<CacheControlsManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = _buildContent(context, controller);
        if (widget.embedded) {
          return ShellPageActions(actions: const <Widget>[], child: content);
        }

        return AppStandaloneShell(
          title: 'Cache Management',
          scrollController: controller.pageScrollController,
          actions: const <Widget>[],
          child: content,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    CacheControlsManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading cache dashboard...');
    }

    if (controller.error != null) {
      return AppErrorStateView(
        title: 'Unable to load cache dashboard',
        message: controller.error!,
        onRetry: controller.loadCacheSettings,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide =
            constraints.maxWidth >= AppUiConstants.dashboardSplitBreakpoint;
        return SingleChildScrollView(
          controller: controller.pageScrollController,
          padding: const EdgeInsets.all(AppUiConstants.pagePadding),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DashboardHeader(controller: controller),
                  const SizedBox(height: AppUiConstants.spacingXl),
                  _MetricsGrid(controller: controller),
                  const SizedBox(height: AppUiConstants.spacingXl),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 7,
                          child: _ServerCachePanel(
                            controller: controller,
                            onClearAll: () => _clearAllServerCaches(controller),
                          ),
                        ),
                        const SizedBox(width: AppUiConstants.spacingXl),
                        Expanded(
                          flex: 5,
                          child: Column(
                            children: [
                              _ReferenceCachePanel(controller: controller),
                              const SizedBox(height: AppUiConstants.spacingXl),
                              _HttpCachePanel(controller: controller),
                            ],
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _ServerCachePanel(
                      controller: controller,
                      onClearAll: () => _clearAllServerCaches(controller),
                    ),
                    const SizedBox(height: AppUiConstants.spacingXl),
                    _ReferenceCachePanel(controller: controller),
                    const SizedBox(height: AppUiConstants.spacingXl),
                    _HttpCachePanel(controller: controller),
                  ],
                  const SizedBox(height: AppUiConstants.spacingXl),
                  _DangerZone(
                    busy: controller.allCacheClearing,
                    onClear: () => _clearAllLocalCaches(controller),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _clearAllServerCaches(
    CacheControlsManagementController controller,
  ) async {
    final confirmed = await _confirmDestructive(
      title: 'Clear all server caches?',
      message:
          'Permissions, access scopes, and user context will be rebuilt on subsequent requests.',
      confirmLabel: 'Clear server caches',
    );
    if (confirmed) {
      await controller.flushAllServerCaches();
    }
  }

  Future<void> _clearAllLocalCaches(
    CacheControlsManagementController controller,
  ) async {
    final confirmed = await _confirmDestructive(
      title: 'Reset all local caches?',
      message:
          'Reference data and saved HTTP responses will be removed from this app and downloaded again when needed.',
      confirmLabel: 'Reset local caches',
    );
    if (confirmed) {
      await controller.clearAllCaches();
    }
  }

  Future<bool> _confirmDestructive({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(dialogContext).colorScheme.error,
        ),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.controller});

  final CacheControlsManagementController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppUiConstants.spacingXl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primaryContainer,
            colors.primaryContainer.withValues(alpha: 0.55),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
        border: Border.all(color: colors.primary.withValues(alpha: 0.16)),
      ),
      child: Wrap(
        spacing: AppUiConstants.spacingXl,
        runSpacing: AppUiConstants.spacingLg,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cache operations center',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppUiConstants.spacingXs),
                Text(
                  'Monitor server and app caches, refresh stale data, and resolve access or setup changes from one place.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: AppUiConstants.spacingSm,
            runSpacing: AppUiConstants.spacingSm,
            children: [
              AppActionButton(
                icon: Icons.bolt_rounded,
                label: controller.serverWarming
                    ? 'Refreshing access...'
                    : 'Refresh my access',
                onPressed: controller.serverWarming
                    ? null
                    : controller.warmAllServerCaches,
                busy: controller.serverWarming,
              ),
              AppActionButton(
                icon: Icons.refresh_rounded,
                label: controller.serverLoading
                    ? 'Reloading...'
                    : 'Reload status',
                onPressed: controller.serverLoading
                    ? null
                    : controller.loadCacheSettings,
                busy: controller.serverLoading,
                filled: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.controller});

  final CacheControlsManagementController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 4
            : constraints.maxWidth >= 620
            ? 2
            : 1;
        final width =
            (constraints.maxWidth -
                ((columns - 1) * AppUiConstants.spacingMd)) /
            columns;
        return Wrap(
          spacing: AppUiConstants.spacingMd,
          runSpacing: AppUiConstants.spacingMd,
          children: [
            _MetricCard(
              width: width,
              icon: Icons.dns_outlined,
              label: 'Server caches',
              value: controller.serverCacheGroups.length.toString(),
              detail: 'Managed cache groups',
            ),
            _MetricCard(
              width: width,
              icon: Icons.inventory_2_outlined,
              label: 'Reference records',
              value: controller.masterCacheRecordCount.toString(),
              detail: controller.masterCacheStatusLabel(),
              positive: controller.cacheEnabled && controller.masterCacheLoaded,
            ),
            _MetricCard(
              width: width,
              icon: Icons.http_rounded,
              label: 'Saved responses',
              value: controller.apiCacheEntryCount.toString(),
              detail: '${controller.apiCacheHits} reused',
            ),
            _MetricCard(
              width: width,
              icon: Icons.dataset_outlined,
              label: 'Reference datasets',
              value: controller.masterDatasetCounts.length.toString(),
              detail: controller.cacheEnabled
                  ? 'Cache enabled'
                  : 'Cache disabled',
              positive: controller.cacheEnabled,
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    this.positive = false,
  });

  final double width;
  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      child: AppSectionCard(
        padding: const EdgeInsets.all(AppUiConstants.spacingLg),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(
                  AppUiConstants.buttonRadius,
                ),
              ),
              child: Icon(icon, color: colors.primary),
            ),
            const SizedBox(width: AppUiConstants.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: AppUiConstants.spacingXxs),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          value,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (positive) ...[
                        const SizedBox(width: AppUiConstants.spacingXs),
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: colors.primary,
                        ),
                      ],
                    ],
                  ),
                  Text(
                    detail,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServerCachePanel extends StatelessWidget {
  const _ServerCachePanel({required this.controller, required this.onClearAll});

  final CacheControlsManagementController controller;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    return _DashboardPanel(
      icon: Icons.dns_outlined,
      title: 'Server cache',
      subtitle: 'Authorization and user-context data used by the ERP backend.',
      trailing: Wrap(
        spacing: AppUiConstants.spacingXs,
        runSpacing: AppUiConstants.spacingXs,
        children: [
          AppActionButton(
            icon: Icons.bolt_outlined,
            label: controller.serverWarming
                ? 'Refreshing...'
                : 'Refresh my access',
            onPressed: controller.serverWarming
                ? null
                : controller.warmAllServerCaches,
            busy: controller.serverWarming,
          ),
          AppActionButton(
            icon: Icons.delete_sweep_outlined,
            label: controller.serverFlushing ? 'Clearing...' : 'Clear all',
            onPressed: controller.serverFlushing ? null : onClearAll,
            busy: controller.serverFlushing,
            filled: false,
          ),
        ],
      ),
      child: controller.serverCacheGroups.isEmpty
          ? const _EmptyState(
              icon: Icons.storage_outlined,
              message: 'No server cache groups were reported.',
            )
          : Column(
              children: controller.serverCacheGroups
                  .map(
                    (group) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppUiConstants.spacingSm,
                      ),
                      child: _ServerGroupRow(
                        title: controller.serverGroupTitle(_groupKey(group)),
                        description: controller.serverGroupDescription(
                          _groupKey(group),
                        ),
                        status: controller.serverGroupStatusLine(group),
                        lastRefreshed: controller.formatTimestamp(
                          group['last_warmed_at'],
                        ),
                        busy: controller.serverFlushing,
                        onClear: () =>
                            controller.flushServerGroup(_groupKey(group)),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }

  String _groupKey(Map<String, dynamic> group) =>
      group['group']?.toString() ?? group['key']?.toString() ?? '';
}

class _ServerGroupRow extends StatelessWidget {
  const _ServerGroupRow({
    required this.title,
    required this.description,
    required this.status,
    required this.lastRefreshed,
    required this.busy,
    required this.onClear,
  });

  final String title;
  final String description;
  final String status;
  final String lastRefreshed;
  final bool busy;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppUiConstants.spacingMd),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(AppUiConstants.panelRadius),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppUiConstants.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppUiConstants.spacingXxs),
                Text(description, style: theme.textTheme.bodySmall),
                const SizedBox(height: AppUiConstants.spacingSm),
                Wrap(
                  spacing: AppUiConstants.spacingMd,
                  runSpacing: AppUiConstants.spacingXs,
                  children: [
                    _InlineMeta(icon: Icons.tune_rounded, text: status),
                    _InlineMeta(
                      icon: Icons.schedule_rounded,
                      text: 'Refreshed $lastRefreshed',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppUiConstants.spacingSm),
          IconButton(
            tooltip: 'Clear $title',
            onPressed: busy ? null : onClear,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _ReferenceCachePanel extends StatelessWidget {
  const _ReferenceCachePanel({required this.controller});

  final CacheControlsManagementController controller;

  @override
  Widget build(BuildContext context) {
    return _DashboardPanel(
      icon: Icons.inventory_2_outlined,
      title: 'Reference data',
      subtitle: 'Shared setup data for forms, dropdowns, and documents.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSwitchTile(
            label: 'Use shared reference cache',
            subtitle: controller.cacheEnabled
                ? 'Enabled · ${controller.masterCacheRecordCount} records ready'
                : 'Disabled · pages load data directly from the server',
            value: controller.cacheEnabled,
            onChanged: controller.cacheToggleSaving
                ? null
                : controller.setCacheEnabled,
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          _KeyValueRow(
            label: 'Last refreshed',
            value: controller.cacheLastLoadedLabel,
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          Wrap(
            spacing: AppUiConstants.spacingSm,
            runSpacing: AppUiConstants.spacingSm,
            children: [
              AppActionButton(
                icon: Icons.bolt_outlined,
                label: controller.warmingCache
                    ? 'Refreshing...'
                    : 'Refresh data',
                onPressed: controller.warmingCache
                    ? null
                    : controller.warmMasterCache,
                busy: controller.warmingCache,
              ),
              AppActionButton(
                icon: Icons.delete_outline,
                label: controller.masterCacheClearing ? 'Clearing...' : 'Clear',
                onPressed: controller.masterCacheClearing
                    ? null
                    : controller.clearMasterCache,
                busy: controller.masterCacheClearing,
                filled: false,
              ),
            ],
          ),
          if (controller.masterDatasetCounts.isNotEmpty) ...[
            const SizedBox(height: AppUiConstants.spacingLg),
            Text(
              'Cached datasets',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
            Wrap(
              spacing: AppUiConstants.spacingXs,
              runSpacing: AppUiConstants.spacingXs,
              children: controller.masterDatasetCounts
                  .map(
                    (entry) => _CountChip(label: entry.key, count: entry.value),
                  )
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }
}

class _HttpCachePanel extends StatelessWidget {
  const _HttpCachePanel({required this.controller});

  final CacheControlsManagementController controller;

  @override
  Widget build(BuildContext context) {
    return _DashboardPanel(
      icon: Icons.http_rounded,
      title: 'Request cache',
      subtitle: 'Saved responses that reduce repeated network requests.',
      trailing: AppActionButton(
        icon: Icons.delete_outline,
        label: controller.apiCacheClearing ? 'Clearing...' : 'Clear cache',
        onPressed: controller.apiCacheClearing
            ? null
            : controller.clearApiCache,
        busy: controller.apiCacheClearing,
        filled: false,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _KeyValueRow(
            label: 'Last response saved',
            value: controller.apiCacheLastStoredLabel,
          ),
          const SizedBox(height: AppUiConstants.spacingSm),
          _KeyValueRow(
            label: 'Responses reused',
            value: controller.apiCacheReuseLabel,
          ),
          const SizedBox(height: AppUiConstants.spacingSm),
          _KeyValueRow(
            label: 'Memory used',
            value: controller.apiCacheStorageLabel,
          ),
          if (controller.apiFamilyCounts.isNotEmpty) ...[
            const SizedBox(height: AppUiConstants.spacingLg),
            Text(
              'Cached data areas',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppUiConstants.spacingXs),
            ...controller.apiFamilyCounts
                .take(8)
                .map(
                  (entry) => _EndpointRow(
                    label: controller.readableEndpointFamily(entry.key),
                    count: entry.value,
                  ),
                ),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: AppUiConstants.spacingLg),
              child: _EmptyState(
                icon: Icons.cloud_off_outlined,
                message: 'No responses are currently cached.',
              ),
            ),
        ],
      ),
    );
  }
}

class _DashboardPanel extends StatelessWidget {
  const _DashboardPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppUiConstants.spacingMd,
            runSpacing: AppUiConstants.spacingMd,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(
                          AppUiConstants.buttonRadius,
                        ),
                      ),
                      child: Icon(icon, color: colors.primary),
                    ),
                    const SizedBox(width: AppUiConstants.spacingSm),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: AppUiConstants.spacingLg),
          Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
          const SizedBox(height: AppUiConstants.spacingMd),
          child,
        ],
      ),
    );
  }
}

class _DangerZone extends StatelessWidget {
  const _DangerZone({required this.busy, required this.onClear});

  final bool busy;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppUiConstants.spacingLg),
      decoration: BoxDecoration(
        color: colors.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppUiConstants.panelRadius),
        border: Border.all(color: colors.error.withValues(alpha: 0.25)),
      ),
      child: Wrap(
        spacing: AppUiConstants.spacingLg,
        runSpacing: AppUiConstants.spacingMd,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded, color: colors.error),
                const SizedBox(width: AppUiConstants.spacingSm),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reset local app caches',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Use this only when the app must rebuild all local cached data from scratch.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.error,
              side: BorderSide(color: colors.error.withValues(alpha: 0.5)),
            ),
            onPressed: busy ? null : onClear,
            icon: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_forever_outlined),
            label: Text(busy ? 'Resetting...' : 'Reset local caches'),
          ),
        ],
      ),
    );
  }
}

class _InlineMeta extends StatelessWidget {
  const _InlineMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: AppUiConstants.spacingXxs),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        const SizedBox(width: AppUiConstants.spacingSm),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppUiConstants.pillRadius),
      ),
      child: Text(
        '$label  $count',
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _EndpointRow extends StatelessWidget {
  const _EndpointRow({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppUiConstants.spacingXs),
      child: Row(
        children: [
          Icon(
            Icons.cloud_done_outlined,
            size: 17,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AppUiConstants.spacingXs),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.all(AppUiConstants.spacingLg),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppUiConstants.panelRadius),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: AppUiConstants.spacingXs),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
