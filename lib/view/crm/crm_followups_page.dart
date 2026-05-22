import '../../screen.dart';

void _openCrmFollowupShellRoute(BuildContext context, String route) {
  final navigate = ShellRouteScope.maybeOf(context);
  if (navigate != null) {
    navigate(route);
    return;
  }
  Navigator.of(context).pushNamed(route);
}

class CrmFollowupsPage extends StatefulWidget {
  const CrmFollowupsPage({
    super.key,
    this.embedded = false,
    this.queryParameters = const <String, String>{},
  });

  final bool embedded;
  final Map<String, String> queryParameters;

  @override
  State<CrmFollowupsPage> createState() => _CrmFollowupsPageState();
}

class _CrmFollowupsPageState extends State<CrmFollowupsPage> {
  final CrmService _crmService = CrmService();
  final ScrollController _scrollController = ScrollController();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _followups = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _nextFollowupRows = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _gaps = const <Map<String, dynamic>>[];
  final Map<int, TextEditingController> _followupDateControllers =
      <int, TextEditingController>{};
  final Map<int, TextEditingController> _nextFollowupControllers =
      <int, TextEditingController>{};
  final Map<int, TextEditingController> _notesControllers =
      <int, TextEditingController>{};
  final Set<int> _savingOpportunityIds = <int>{};

  String get _dashboardFilter =>
      (widget.queryParameters['dashboard_filter'] ?? '').trim();

  bool get _showDueTodayOnly => _dashboardFilter == 'due_today';
  bool get _showOpenFollowupsOnly => _dashboardFilter == 'open_followups';

  DateTime _normalizeDate(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final controller in _followupDateControllers.values) {
      controller.dispose();
    }
    for (final controller in _nextFollowupControllers.values) {
      controller.dispose();
    }
    for (final controller in _notesControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _crmService.opportunityFollowupsBoard();
      final data = response.data ?? const <String, dynamic>{};
      final followups =
          (data['followups'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList(growable: false);
      final nextFollowups =
          (data['next_followups'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList(growable: false);
      final gaps =
          (data['opportunities_without_followups'] as List<dynamic>? ??
                  const <dynamic>[])
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList(growable: false);

      _syncGapControllers(gaps);

      if (!mounted) {
        return;
      }
      setState(() {
        _followups = followups;
        _nextFollowupRows = nextFollowups;
        _gaps = gaps;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  void _syncGapControllers(List<Map<String, dynamic>> gaps) {
    final activeIds = gaps
        .map((item) => intValue(item, 'opportunity_id'))
        .whereType<int>()
        .toSet();

    void disposeMissing(Map<int, TextEditingController> source) {
      final removable = source.keys
          .where((id) => !activeIds.contains(id))
          .toList(growable: false);
      for (final id in removable) {
        source.remove(id)?.dispose();
      }
    }

    disposeMissing(_followupDateControllers);
    disposeMissing(_nextFollowupControllers);
    disposeMissing(_notesControllers);

    for (final gap in gaps) {
      final opportunityId = intValue(gap, 'opportunity_id');
      if (opportunityId == null) {
        continue;
      }
      _followupDateControllers.putIfAbsent(
        opportunityId,
        () => TextEditingController(text: currentDateTimeInput()),
      );
      _nextFollowupControllers.putIfAbsent(
        opportunityId,
        () => TextEditingController(),
      );
      _notesControllers.putIfAbsent(
        opportunityId,
        () => TextEditingController(),
      );
    }
  }

  Future<void> _pickDateTime(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final now = DateTime.now();
    final initial = tryParseCalendarDateTime(controller.text) ?? now;
    final selected = await showAppDateTimePickerDialog(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      dateTitle: 'Select Followup Date',
      timeTitle: 'Select Followup Time',
    );
    if (selected == null) {
      return;
    }
    controller.text = formatCalendarDateTime(selected);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _createFollowup(Map<String, dynamic> gap) async {
    final opportunityId = intValue(gap, 'opportunity_id');
    if (opportunityId == null) {
      return;
    }

    final followupDate =
        _followupDateControllers[opportunityId]?.text.trim() ?? '';
    if (followupDate.isEmpty) {
      appScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Followup date is required.')),
      );
      return;
    }

    setState(() {
      _savingOpportunityIds.add(opportunityId);
    });

    try {
      final response = await _crmService
          .createOpportunityFollowup(opportunityId, {
            'followup_date': followupDate,
            'next_followup': nullIfEmpty(
              _nextFollowupControllers[opportunityId]?.text ?? '',
            ),
            'notes': nullIfEmpty(_notesControllers[opportunityId]?.text ?? ''),
            'status': 'pending',
          });
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await _load();
    } catch (error) {
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingOpportunityIds.remove(opportunityId);
        });
      }
    }
  }

  String _assignedLabel(Map<String, dynamic> row) {
    final user =
        JsonModel.mapOf(row['assigned_user']) ?? const <String, dynamic>{};
    final displayName = stringValue(user, 'display_name');
    if (displayName.isNotEmpty) {
      return displayName;
    }
    return stringValue(user, 'username');
  }

  List<Map<String, dynamic>> get _nextFollowups => _nextFollowupRows
      .where((row) {
        final nextFollowup = (nullableStringValue(row, 'next_followup') ?? '')
            .trim();
        final opportunityStatus = stringValue(
          row,
          'opportunity_status',
        ).trim().toLowerCase();
        return nextFollowup.isNotEmpty && opportunityStatus != 'won';
      })
      .toList(growable: false);

  List<Map<String, dynamic>> get _visiblePendingFollowups {
    final rows = _followups.where((row) {
      final status = nullableStringValue(row, 'status');
      if (crmIsCompletedFollowupStatus(status)) {
        return false;
      }

      if (_showDueTodayOnly) {
        final rawDate = nullableStringValue(row, 'followup_date');
        final parsed = rawDate == null ? null : DateTime.tryParse(rawDate);
        if (parsed == null) {
          return false;
        }
        return _normalizeDate(parsed) == _normalizeDate(DateTime.now());
      }

      return true;
    });
    return rows.toList(growable: false);
  }

  Widget _buildPendingList(BuildContext context) {
    if (_showDueTodayOnly || _showOpenFollowupsOnly) {
      if (_visiblePendingFollowups.isEmpty) {
        return SettingsEmptyState(
          icon: Icons.alarm_off_outlined,
          title: _showDueTodayOnly
              ? 'No Followups Due Today'
              : 'No Open Followups',
          message: _showDueTodayOnly
              ? 'No pending followups are due today.'
              : 'No open followups are assigned right now.',
          minHeight: 180,
        );
      }

      return Column(
        children: _visiblePendingFollowups
            .map((row) {
              final opportunityId = intValue(row, 'opportunity_id');
              final notes = stringValue(row, 'notes');
              final title = [
                stringValue(row, 'opportunity_no'),
                stringValue(row, 'customer_name'),
              ].where((value) => value.trim().isNotEmpty).join(' • ');
              final subtitle = [
                displayDateTime(nullableStringValue(row, 'followup_date')),
                stringValue(row, 'lead_name'),
                _assignedLabel(row),
              ].where((value) => value.trim().isNotEmpty).join(' • ');

              return Padding(
                padding: const EdgeInsets.only(
                  bottom: AppUiConstants.spacingSm,
                ),
                child: AppSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.alarm_outlined),
                          const SizedBox(width: AppUiConstants.spacingSm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title.isEmpty ? 'Pending Followup' : title,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                if (subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    subtitle,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .extension<AppThemeExtension>()!
                                              .mutedText,
                                        ),
                                  ),
                                ],
                                if (notes.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(notes),
                                ],
                              ],
                            ),
                          ),
                          if (opportunityId != null)
                            AppActionButton(
                              icon: Icons.open_in_new_outlined,
                              label: 'Open',
                              filled: false,
                              onPressed: () => _openCrmFollowupShellRoute(
                                context,
                                '/crm/opportunities/$opportunityId',
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            })
            .toList(growable: false),
      );
    }

    if (_visiblePendingFollowups.isEmpty) {
      return SettingsEmptyState(
        icon: Icons.alarm_off_outlined,
        title: _showDueTodayOnly
            ? 'No Followups Due Today'
            : 'No Pending Followups',
        message: _showDueTodayOnly
            ? 'No pending followups are due today.'
            : 'No pending followups are assigned to you right now.',
        minHeight: 180,
      );
    }

    return Column(
      children: _visiblePendingFollowups
          .map((row) {
            final opportunityId = intValue(row, 'opportunity_id');
            final notes = stringValue(row, 'notes');
            final title = [
              stringValue(row, 'opportunity_no'),
              stringValue(row, 'customer_name'),
            ].where((value) => value.trim().isNotEmpty).join(' • ');
            final subtitle = [
              displayDateTime(nullableStringValue(row, 'followup_date')),
              stringValue(row, 'lead_name'),
              _assignedLabel(row),
            ].where((value) => value.trim().isNotEmpty).join(' • ');

            return Padding(
              padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
              child: AppSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.alarm_outlined),
                        const SizedBox(width: AppUiConstants.spacingSm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title.isEmpty ? 'Pending Followup' : title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              if (subtitle.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .extension<AppThemeExtension>()!
                                            .mutedText,
                                      ),
                                ),
                              ],
                              if (notes.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(notes),
                              ],
                            ],
                          ),
                        ),
                        if (opportunityId != null)
                          AppActionButton(
                            icon: Icons.open_in_new_outlined,
                            label: 'Open',
                            filled: false,
                            onPressed: () => _openCrmFollowupShellRoute(
                              context,
                              '/crm/opportunities/$opportunityId',
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }

  Widget _buildNextFollowupList(BuildContext context) {
    if (_nextFollowups.isEmpty) {
      return const SettingsEmptyState(
        icon: Icons.event_repeat_outlined,
        title: 'No Next Followups',
        message: 'No pending followups have a next followup scheduled yet.',
        minHeight: 180,
      );
    }

    return Column(
      children: _nextFollowups
          .map((row) {
            final opportunityId = intValue(row, 'opportunity_id');
            final notes = stringValue(row, 'notes');
            final title = [
              stringValue(row, 'opportunity_no'),
              stringValue(row, 'customer_name'),
            ].where((value) => value.trim().isNotEmpty).join(' • ');
            final nextFollowup = displayDateTime(
              nullableStringValue(row, 'next_followup'),
            );
            final followupDate = displayDateTime(
              nullableStringValue(row, 'followup_date'),
            );
            final subtitle = [
              stringValue(row, 'lead_name'),
              _assignedLabel(row),
            ].where((value) => value.trim().isNotEmpty).join(' • ');

            return Padding(
              padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
              child: AppSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.event_repeat_outlined),
                        const SizedBox(width: AppUiConstants.spacingSm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title.isEmpty ? 'Next Followup' : title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              if (subtitle.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .extension<AppThemeExtension>()!
                                            .mutedText,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (opportunityId != null)
                          AppActionButton(
                            icon: Icons.open_in_new_outlined,
                            label: 'Open',
                            filled: false,
                            onPressed: () => _openCrmFollowupShellRoute(
                              context,
                              '/crm/opportunities/$opportunityId',
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppUiConstants.spacingSm),
                    Wrap(
                      spacing: AppUiConstants.spacingSm,
                      runSpacing: AppUiConstants.spacingSm,
                      children: [
                        _buildNextFollowupDetailCard(
                          context,
                          label: 'Next Followup',
                          value: nextFollowup,
                        ),
                        _buildNextFollowupDetailCard(
                          context,
                          label: 'Followup Date',
                          value: followupDate,
                        ),
                      ],
                    ),
                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: AppUiConstants.spacingSm),
                      _buildNextFollowupDetailCard(
                        context,
                        label: 'Notes',
                        value: notes,
                        expand: true,
                      ),
                    ],
                  ],
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }

  Widget _buildNextFollowupDetailCard(
    BuildContext context, {
    required String label,
    required String value,
    bool expand = false,
  }) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).extension<AppThemeExtension>()!.subtleFill,
        borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppUiConstants.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(value),
          ],
        ),
      ),
    );

    if (expand) {
      return SizedBox(width: double.infinity, child: card);
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 280),
      child: DecoratedBox(decoration: const BoxDecoration(), child: card),
    );
  }

  Widget _buildGapList(BuildContext context) {
    if (_gaps.isEmpty) {
      return const SettingsEmptyState(
        icon: Icons.task_alt_outlined,
        title: 'All Open Opportunities Have Followups',
        message:
            'No open opportunities are waiting for a new pending followup.',
        minHeight: 180,
      );
    }

    return Column(
      children: _gaps
          .map((row) {
            final opportunityId = intValue(row, 'opportunity_id');
            if (opportunityId == null) {
              return const SizedBox.shrink();
            }
            final saving = _savingOpportunityIds.contains(opportunityId);
            return Padding(
              padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
              child: AppSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                [
                                      stringValue(row, 'opportunity_no'),
                                      stringValue(row, 'customer_name'),
                                    ]
                                    .where((value) => value.trim().isNotEmpty)
                                    .join(' • '),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                [
                                      stringValue(row, 'lead_name'),
                                      _assignedLabel(row),
                                    ]
                                    .where((value) => value.trim().isNotEmpty)
                                    .join(' • '),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .extension<AppThemeExtension>()!
                                          .mutedText,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        AppActionButton(
                          icon: Icons.open_in_new_outlined,
                          label: 'Open',
                          filled: false,
                          onPressed: () => _openCrmFollowupShellRoute(
                            context,
                            '/crm/opportunities/$opportunityId',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppUiConstants.spacingSm),
                    SettingsFormWrap(
                      children: [
                        AppDateTimeSelectorField(
                          controller: _followupDateControllers[opportunityId]!,
                          labelText: 'Followup Date',
                          hintText: 'YYYY-MM-DD HH:MM:SS',
                          onTap: () => _pickDateTime(
                            context,
                            _followupDateControllers[opportunityId]!,
                          ),
                        ),
                        AppDateTimeSelectorField(
                          controller: _nextFollowupControllers[opportunityId]!,
                          labelText: 'Next Followup',
                          hintText: 'YYYY-MM-DD HH:MM:SS',
                          onTap: () => _pickDateTime(
                            context,
                            _nextFollowupControllers[opportunityId]!,
                          ),
                        ),
                        AppFormTextField(
                          controller: _notesControllers[opportunityId]!,
                          labelText: 'Notes',
                          maxLines: 2,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppUiConstants.spacingSm),
                    AppActionButton(
                      icon: Icons.save_outlined,
                      label: 'Create Followup',
                      onPressed: saving ? null : () => _createFollowup(row),
                      busy: saving,
                    ),
                  ],
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_loading) {
      return const AppLoadingView(message: 'Loading CRM followups...');
    }
    if (_error != null) {
      return AppErrorStateView(
        title: 'Unable to load CRM followups',
        message: _error!,
        onRetry: _load,
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _showDueTodayOnly ? 'Due Today' : 'Pending Followups',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppUiConstants.spacingSm),
                _buildPendingList(context),
              ],
            ),
          ),
          if (!_showDueTodayOnly && !_showOpenFollowupsOnly) ...[
            const SizedBox(height: AppUiConstants.spacingMd),
            AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next Followup',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppUiConstants.spacingSm),
                  _buildNextFollowupList(context),
                ],
              ),
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Needs Followup',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppUiConstants.spacingSm),
                  _buildGapList(context),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      AdaptiveShellActionButton(
        onPressed: _load,
        icon: Icons.refresh_outlined,
        label: 'Refresh',
        filled: false,
      ),
    ];

    final content = _buildContent(context);
    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }
    return AppStandaloneShell(
      title: 'CRM Follow ups',
      scrollController: _scrollController,
      actions: actions,
      child: content,
    );
  }
}
