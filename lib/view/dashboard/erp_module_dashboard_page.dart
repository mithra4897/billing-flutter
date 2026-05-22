import '../../controller/dashboard/erp_module_dashboard_controller.dart';
import '../../screen.dart';

class ErpModuleDashboardPage extends StatefulWidget {
  const ErpModuleDashboardPage({
    super.key,
    required this.moduleKey,
    this.embedded = false,
    this.loader,
    this.shellTitle,
  });

  final String moduleKey;
  final bool embedded;
  final Future<ErpDashboardSnapshot> Function(ErpDashboardTrendFilter? filter)?
  loader;
  final String? shellTitle;

  @override
  State<ErpModuleDashboardPage> createState() => _ErpModuleDashboardPageState();
}

class _ErpModuleDashboardPageState extends State<ErpModuleDashboardPage> {
  late final String _controllerTag;
  late final ErpModuleDashboardController _controller;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'ErpModuleDashboardController-${widget.moduleKey}',
    );
    _controller = Get.put(
      ErpModuleDashboardController(
        moduleKey: widget.moduleKey,
        loader: widget.loader,
        shellTitle: widget.shellTitle,
      ),
      tag: _controllerTag,
      permanent: true,
    );
  }

  @override
  void didUpdateWidget(covariant ErpModuleDashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.moduleKey == widget.moduleKey &&
        oldWidget.loader == widget.loader &&
        oldWidget.shellTitle == widget.shellTitle) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _controller.updateConfig(
        nextModuleKey: widget.moduleKey,
        nextLoader: widget.loader,
        nextShellTitle: widget.shellTitle,
      );
    });
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final initialRange = _controller.trendFilter.customRange == null
        ? DateTimeRange(start: DateTime(now.year, now.month - 1, 1), end: now)
        : DateTimeRange(
            start: _controller.trendFilter.customRange!.start,
            end: _controller.trendFilter.customRange!.end,
          );
    final selected = await showDialog<DateTimeRange>(
      context: context,
      builder: (context) => _CustomRangeDialog(
        initialRange: initialRange,
        firstDate: DateTime(now.year - 5, 1, 1),
        lastDate: DateTime(now.year + 1, 12, 31),
      ),
    );

    if (selected == null) {
      return;
    }

    _controller.setCustomRange(selected);
    await _controller.refreshTrendSnapshot();
  }

  Future<void> _handleTrendControlChanged(
    ErpDashboardTrendControlValue value,
  ) async {
    switch (value) {
      case ErpDashboardTrendControlValue.monthly:
        await _controller.handleTrendControlChanged(value);
      case ErpDashboardTrendControlValue.weekly:
        await _controller.handleTrendControlChanged(value);
      case ErpDashboardTrendControlValue.yearly:
        await _controller.handleTrendControlChanged(value);
      case ErpDashboardTrendControlValue.custom:
        await _pickCustomRange();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ErpModuleDashboardController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = FutureBuilder<ErpDashboardSnapshot>(
          future: controller.snapshotFuture,
          builder: (context, snapshot) {
            final data = snapshot.data ?? controller.snapshotCache;
            final body = switch (snapshot.connectionState) {
              ConnectionState.waiting ||
              ConnectionState.active when data == null => AppLoadingView(
                message:
                    'Loading ${widget.shellTitle ?? "module"} dashboard...',
              ),
              _ when snapshot.hasError => AppErrorStateView(
                title: 'Unable to load dashboard',
                message: snapshot.error.toString(),
                onRetry: controller.reload,
              ),
              _ => SingleChildScrollView(
                padding: const EdgeInsets.all(AppUiConstants.pagePadding),
                child: ErpModuleDashboard(
                  snapshot:
                      data ??
                      ErpDashboardSnapshot(
                        title: widget.shellTitle ?? 'Module Dashboard',
                        subtitle: 'No dashboard data available.',
                      ),
                  showTrendControls: data?.trend != null,
                  trendControlValue: _mapTrendControlValue(
                    controller.trendFilter.preset,
                  ),
                  onTrendControlChanged: _handleTrendControlChanged,
                  trendLoading: controller.isTrendReloading,
                ),
              ),
            };

            return body;
          },
        );

        if (widget.embedded) {
          return content;
        }

        return FutureBuilder<PublicBrandingModel?>(
          future: SessionStorage.getBranding(),
          builder: (context, snapshot) {
            final branding =
                snapshot.data ??
                const PublicBrandingModel(companyName: 'Billing ERP');
            return AdaptiveShell(
              title: widget.shellTitle ?? 'Dashboard',
              branding: branding,
              child: content,
            );
          },
        );
      },
    );
  }
}

ErpDashboardTrendControlValue _mapTrendControlValue(
  ErpDashboardTrendPreset preset,
) {
  return switch (preset) {
    ErpDashboardTrendPreset.monthly => ErpDashboardTrendControlValue.monthly,
    ErpDashboardTrendPreset.weekly => ErpDashboardTrendControlValue.weekly,
    ErpDashboardTrendPreset.yearly => ErpDashboardTrendControlValue.yearly,
    ErpDashboardTrendPreset.custom => ErpDashboardTrendControlValue.custom,
  };
}

class _CustomRangeDialog extends StatefulWidget {
  const _CustomRangeDialog({
    required this.initialRange,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTimeRange initialRange;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_CustomRangeDialog> createState() => _CustomRangeDialogState();
}

class _CustomRangeDialogState extends State<_CustomRangeDialog> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'ErpDashboardCustomRangeController',
      scope: <String, Object?>{
        'start': widget.initialRange.start.toIso8601String(),
        'end': widget.initialRange.end.toIso8601String(),
      },
    );
    Get.put(
      _CustomRangeDialogController(initialRange: widget.initialRange),
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    Get.delete<_CustomRangeDialogController>(tag: _controllerTag, force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<_CustomRangeDialogController>(
      tag: _controllerTag,
      builder: (controller) {
        final isCompact = MediaQuery.of(context).size.width < 980;

        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Padding(
              padding: const EdgeInsets.all(AppUiConstants.cardPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Custom Range',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppUiConstants.spacingXs),
                  Text(
                    '${_formatDate(controller.start)} - ${_formatDate(controller.end)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppUiConstants.spacingMd),
                  Flexible(
                    child: isCompact
                        ? SingleChildScrollView(
                            child: Column(
                              children: [
                                _CustomRangeCalendar(
                                  label: 'Start Date',
                                  selectedDate: controller.start,
                                  firstDate: widget.firstDate,
                                  lastDate: widget.lastDate,
                                  onChanged: controller.setStart,
                                ),
                                const SizedBox(
                                  height: AppUiConstants.spacingMd,
                                ),
                                _CustomRangeCalendar(
                                  label: 'End Date',
                                  selectedDate: controller.end,
                                  firstDate: widget.firstDate,
                                  lastDate: widget.lastDate,
                                  onChanged: controller.setEnd,
                                ),
                              ],
                            ),
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _CustomRangeCalendar(
                                label: 'Start Date',
                                selectedDate: controller.start,
                                firstDate: widget.firstDate,
                                lastDate: widget.lastDate,
                                onChanged: controller.setStart,
                              ),
                              const SizedBox(width: AppUiConstants.spacingMd),
                              _CustomRangeCalendar(
                                label: 'End Date',
                                selectedDate: controller.end,
                                firstDate: widget.firstDate,
                                lastDate: widget.lastDate,
                                onChanged: controller.setEnd,
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: AppUiConstants.spacingMd),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: AppUiConstants.spacingSm),
                      FilledButton(
                        onPressed: () =>
                            Navigator.of(context).pop(controller.selectedRange),
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}

class _CustomRangeDialogController extends GetxController {
  _CustomRangeDialogController({required DateTimeRange initialRange})
    : start = initialRange.start,
      end = initialRange.end;

  DateTime start;
  DateTime end;

  DateTimeRange get selectedRange => DateTimeRange(start: start, end: end);

  void setStart(DateTime value) {
    start = value;
    if (end.isBefore(start)) {
      end = start;
    }
    update();
  }

  void setEnd(DateTime value) {
    end = value.isBefore(start) ? start : value;
    update();
  }
}

class _CustomRangeCalendar extends StatelessWidget {
  const _CustomRangeCalendar({
    required this.label,
    required this.selectedDate,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
  });

  final String label;
  final DateTime selectedDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppUiConstants.spacingSm),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppUiConstants.buttonRadius),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.16),
              ),
            ),
            padding: const EdgeInsets.all(AppUiConstants.spacingSm),
            child: CalendarDatePicker(
              initialDate: selectedDate,
              firstDate: firstDate,
              lastDate: lastDate,
              onDateChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
