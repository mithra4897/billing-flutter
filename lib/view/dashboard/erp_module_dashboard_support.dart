import '../../screen.dart';

const List<Color> _dashboardPalette = <Color>[
  Color(0xFF2F6FED),
  Color(0xFF1FA971),
  Color(0xFFE67E22),
  Color(0xFF8E5CFF),
  Color(0xFFDA4D78),
  Color(0xFF19A7B8),
];

class ErpDashboardGraphRange {
  const ErpDashboardGraphRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

enum ErpDashboardTrendPreset { monthly, weekly, yearly, custom }

class ErpDashboardTrendFilter {
  const ErpDashboardTrendFilter({required this.preset, this.customRange});

  final ErpDashboardTrendPreset preset;
  final ErpDashboardGraphRange? customRange;
}

Future<ErpDashboardSnapshot> loadErpDashboardSnapshot(
  String moduleKey, {
  ErpDashboardTrendFilter? trendFilter,
}) {
  switch (moduleKey) {
    case 'crm':
      return buildCrmDashboardSnapshot(
        crmService: CrmService(),
        now: DateTime.now,
        trendFilter: trendFilter,
      );
    case 'accounting':
      return _loadAccountingDashboard(trendFilter: trendFilter);
    case 'assets':
      return _loadAssetsDashboard(trendFilter: trendFilter);
    case 'sales':
      return _loadSalesDashboard(trendFilter: trendFilter);
    case 'purchase':
      return _loadPurchaseDashboard(trendFilter: trendFilter);
    case 'inventory':
      return _loadInventoryDashboard(trendFilter: trendFilter);
    case 'planning':
      return _loadPlanningDashboard(trendFilter: trendFilter);
    case 'manufacturing':
      return _loadManufacturingDashboard(trendFilter: trendFilter);
    case 'quality':
      return _loadQualityDashboard(trendFilter: trendFilter);
    case 'jobwork':
      return _loadJobworkDashboard(trendFilter: trendFilter);
    case 'service':
      return _loadServiceDashboard(trendFilter: trendFilter);
    case 'projects':
      return _loadProjectsDashboard(trendFilter: trendFilter);
    case 'maintenance':
      return _loadMaintenanceDashboard(trendFilter: trendFilter);
    case 'hr':
      return _loadHrDashboard(trendFilter: trendFilter);
    case 'parties':
      return _loadPartiesDashboard(trendFilter: trendFilter);
    default:
      return Future.value(
        ErpDashboardSnapshot(
          title: 'Module dashboard',
          subtitle: 'No dashboard definition found for this module.',
        ),
      );
  }
}

bool _crmIsCompletedBoardFollowupStatus(String? status) {
  return crmIsCompletedFollowupStatus(status);
}

bool _crmIsBoardFollowupDueToday(
  Map<String, dynamic> row,
  DateTime currentDate,
) {
  return _crmBoardFollowupBucket(row, currentDate) ==
      CrmFollowupTimingBucket.today;
}

bool _crmIsBoardFollowupOverdue(
  Map<String, dynamic> row,
  DateTime currentDate,
) {
  return _crmBoardFollowupBucket(row, currentDate) ==
      CrmFollowupTimingBucket.overdue;
}

bool _crmIsBoardFollowupUpcoming(
  Map<String, dynamic> row,
  DateTime currentDate,
) {
  return _crmBoardFollowupBucket(row, currentDate) ==
      CrmFollowupTimingBucket.upcoming;
}

CrmFollowupTimingBucket? _crmBoardFollowupBucket(
  Map<String, dynamic> row,
  DateTime currentDate,
) {
  final rawDate = nullableStringValue(row, 'followup_date');
  final parsed = rawDate == null ? null : DateTime.tryParse(rawDate);
  if (parsed == null) {
    return null;
  }

  final localParsed = parsed.isUtc ? parsed.toLocal() : parsed;

  final normalizedCurrent = DateTime(
    currentDate.year,
    currentDate.month,
    currentDate.day,
  );
  final normalizedParsed = DateTime(
    localParsed.year,
    localParsed.month,
    localParsed.day,
  );
  if (normalizedParsed == normalizedCurrent) {
    return CrmFollowupTimingBucket.today;
  }
  if (normalizedParsed.isBefore(normalizedCurrent)) {
    return CrmFollowupTimingBucket.overdue;
  }
  return CrmFollowupTimingBucket.upcoming;
}

Future<ErpDashboardSnapshot> buildCrmDashboardSnapshot({
  required CrmService crmService,
  required DateTime Function() now,
  ErpDashboardTrendFilter? trendFilter,
}) async {
  final activeFilter =
      trendFilter ??
      const ErpDashboardTrendFilter(preset: ErpDashboardTrendPreset.monthly);
  final currentDate = now();
  final pendingLeadResponses = await Future.wait(
    <Future<PaginatedResponse<CrmLeadModel>>>[
      crmService.leads(
        filters: const <String, dynamic>{'per_page': 1, 'lead_status': 'new'},
      ),
      crmService.leads(
        filters: const <String, dynamic>{
          'per_page': 1,
          'lead_status': 'in_progress',
        },
      ),
    ],
  );
  final pendingLeadCount = pendingLeadResponses.fold<int>(
    0,
    (sum, response) =>
        sum + (response.meta?.total ?? response.data?.length ?? 0),
  );
  final openOpportunityResponse = await crmService.opportunities(
    filters: const <String, dynamic>{'per_page': 1, 'status': 'open'},
  );
  final followupBoardResponse = await crmService.opportunityFollowupsBoard();
  final followupBoardData =
      followupBoardResponse.data ?? const <String, dynamic>{};
  final followupBoardRows =
      (followupBoardData['followups'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .where(
            (row) => !_crmIsCompletedBoardFollowupStatus(
              nullableStringValue(row, 'status'),
            ),
          )
          .toList(growable: false);
  final completedFollowupRows =
      (followupBoardData['completed_followups'] as List<dynamic>? ??
              const <dynamic>[])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
  final followupItems = followupBoardRows
      .map(CrmPendingFollowupItem.fromJson)
      .where(
        (item) =>
            _crmMatchesTrendFilter(item, activeFilter, today: currentDate),
      )
      .toList(growable: false);
  final completedCount = completedFollowupRows
      .map(CrmPendingFollowupItem.fromJson)
      .where(
        (item) =>
            _crmMatchesTrendFilter(item, activeFilter, today: currentDate),
      )
      .length;

  final pendingItems = sortCrmPendingFollowups(
    followupItems,
    today: currentDate,
  );
  final pendingTodayCount = pendingItems
      .where(
        (item) =>
            crmFollowupBucket(item, today: currentDate) ==
            CrmFollowupTimingBucket.today,
      )
      .length;
  final pendingOverdueCount = pendingItems
      .where(
        (item) =>
            crmFollowupBucket(item, today: currentDate) ==
            CrmFollowupTimingBucket.overdue,
      )
      .length;
  final pendingUpcomingCount = pendingItems
      .where(
        (item) =>
            crmFollowupBucket(item, today: currentDate) ==
            CrmFollowupTimingBucket.upcoming,
      )
      .length;

  final todayCount = followupBoardRows
      .where((row) => _crmIsBoardFollowupDueToday(row, currentDate))
      .length;
  final overdueCount = followupBoardRows
      .where((row) => _crmIsBoardFollowupOverdue(row, currentDate))
      .length;
  final upcomingCount = followupBoardRows
      .where((row) => _crmIsBoardFollowupUpcoming(row, currentDate))
      .length;
  final highPriority = pendingItems
      .where((item) => crmNormalizePriority(item.priority) == 'high')
      .length;
  final mediumPriority = pendingItems
      .where((item) => crmNormalizePriority(item.priority) == 'medium')
      .length;
  final lowPriority = pendingItems
      .where((item) => crmNormalizePriority(item.priority) == 'low')
      .length;

  return ErpDashboardSnapshot(
    title: 'CRM Dashboard',
    subtitle:
        'Live lead, enquiry, and follow-up activity in a reusable ERP dashboard layout.',
    actions: const <ErpDashboardAction>[
      ErpDashboardAction(
        label: 'New lead',
        icon: Icons.person_add_alt_1_outlined,
        route: '/crm/leads',
      ),
      ErpDashboardAction(
        label: 'New enquiry',
        icon: Icons.add_comment_outlined,
        route: '/crm/opportunities',
      ),
    ],
    stats: <ErpDashboardStat>[
      ErpDashboardStat(
        label: 'Total Pending Leads',
        value: _formatInt(pendingLeadCount),
        helper: 'Open CRM leads in new and in progress stages',
        icon: Icons.groups_2_outlined,
        color: const Color(0xFF2F6FED),
        route: '/crm/leads?dashboard_filter=pending',
      ),
      ErpDashboardStat(
        label: 'Total Pending Enquiries',
        value: _formatInt(
          openOpportunityResponse.meta?.total ??
              openOpportunityResponse.data?.length ??
              0,
        ),
        helper: 'Tracked across the sales pipeline',
        icon: Icons.mark_email_unread_outlined,
        color: const Color(0xFF19A7B8),
        route: '/crm/opportunities?dashboard_filter=open_pending',
      ),
      ErpDashboardStat(
        label: 'Due Today',
        value: _formatInt(todayCount),
        helper: 'Follow-ups scheduled for today',
        icon: Icons.today_outlined,
        color: const Color(0xFFE67E22),
        route: '/crm/follow-ups?dashboard_filter=due_today',
      ),
      ErpDashboardStat(
        label: 'Open Follow-ups',
        value: _formatInt(followupBoardRows.length),
        helper: 'Pending calls, emails, and next steps',
        icon: Icons.assignment_late_outlined,
        color: const Color(0xFFDA4D78),
        route: '/crm/follow-ups?dashboard_filter=open_followups',
      ),
    ],
    primarySections: <ErpDashboardListSection>[
      ErpDashboardListSection(
        title: 'Pending Follow-ups',
        subtitle: 'Prioritized from live CRM follow-up records.',
        icon: Icons.task_alt_outlined,
        items: pendingItems
            .take(6)
            .map((item) {
              final opportunityName = (item.opportunityName ?? '').trim();
              final customerName = (item.customerName ?? '').trim();
              final leadName = (item.leadName ?? '').trim();
              final title = customerName.isNotEmpty
                  ? customerName
                  : opportunityName.isNotEmpty
                  ? opportunityName
                  : (item.subjectName.trim().isNotEmpty &&
                        item.subjectName.trim().toLowerCase() !=
                            'pending followup')
                  ? item.subjectName.trim()
                  : item.id != null
                  ? 'Follow-up #${item.id}'
                  : 'CRM Follow-up';
              final subtitleParts = <String>[
                if ((item.enquiryNo ?? '').trim().isNotEmpty) item.enquiryNo!,
                item.followupDateLabel.isEmpty
                    ? 'No follow-up date'
                    : 'Due ${item.followupDateLabel}',
                'Priority ${crmPriorityLabel(item.priority)}',
                if ((item.assignedUserName ?? '').trim().isNotEmpty)
                  'Assigned ${item.assignedUserName!}',
              ];
              final detailParts = <String>[
                if (opportunityName.isNotEmpty &&
                    opportunityName.toLowerCase() != customerName.toLowerCase())
                  opportunityName,
                if (leadName.isNotEmpty) 'Lead $leadName',
                if (_crmHasValue(item.expectedValue))
                  'Expected ${_crmFormatExpectedValue(item.expectedValue!)}',
                if ((item.summary ?? '').trim().isNotEmpty) item.summary!,
              ];

              return ErpDashboardListItem(
                title: title,
                subtitle: subtitleParts.join(' • '),
                detail: detailParts.isEmpty ? null : detailParts.join(' • '),
                statusLabel: item.status.toUpperCase(),
                statusColor: crmPriorityColor(item.priority),
                route: item.enquiryId == null
                    ? '/crm/opportunities'
                    : '/crm/opportunities/${item.enquiryId}',
              );
            })
            .toList(growable: false),
        emptyTitle: 'No pending CRM follow-ups',
        emptyMessage:
            'The follow-up board will populate when pending CRM tasks exist.',
      ),
    ],
    trend: ErpDashboardTrendCardData(
      title: 'Follow-up Status',
      subtitle:
          'Completion and timing breakdown for ${_crmFilterLabel(activeFilter, currentDate)}.',
      points: <ErpDashboardTrendPoint>[
        ErpDashboardTrendPoint(
          label: 'Completed',
          value: completedCount.toDouble(),
          color: const Color(0xFF1FA971),
        ),
        ErpDashboardTrendPoint(
          label: 'Pending',
          value: pendingItems.length.toDouble(),
          color: const Color(0xFFD84C4C),
        ),
        ErpDashboardTrendPoint(
          label: 'Due Today',
          value: pendingTodayCount.toDouble(),
          color: const Color(0xFFE67E22),
        ),
        ErpDashboardTrendPoint(
          label: 'Overdue',
          value: pendingOverdueCount.toDouble(),
          color: const Color(0xFFDA4D78),
        ),
        ErpDashboardTrendPoint(
          label: 'Upcoming',
          value: pendingUpcomingCount.toDouble(),
          color: const Color(0xFF2F6FED),
        ),
      ],
      color: const Color(0xFF1FA971),
      chartStyle: ErpDashboardTrendChartStyle.bar,
    ),
    distribution: ErpDashboardDistributionCardData(
      title: 'Priority Distribution',
      subtitle: 'Grouped by current CRM follow-up priority.',
      segments: <ErpDashboardDistributionSegment>[
        ErpDashboardDistributionSegment(
          label: 'High',
          value: highPriority.toDouble(),
          color: const Color(0xFFDA4D78),
        ),
        ErpDashboardDistributionSegment(
          label: 'Medium',
          value: mediumPriority.toDouble(),
          color: const Color(0xFFE67E22),
        ),
        ErpDashboardDistributionSegment(
          label: 'Low',
          value: lowPriority.toDouble(),
          color: const Color(0xFF1FA971),
        ),
      ],
    ),
    highlights: ErpDashboardHighlightsCardData(
      title: 'Pipeline Signals',
      subtitle: 'Quick CRM workload indicators.',
      entries: <ErpDashboardHighlightEntry>[
        ErpDashboardHighlightEntry(
          label: 'Today',
          value: _formatInt(todayCount),
          helper: 'Needs same-day attention',
          color: const Color(0xFFE67E22),
          route: '/crm/follow-ups?dashboard_filter=due_today',
        ),
        ErpDashboardHighlightEntry(
          label: 'Overdue',
          value: _formatInt(overdueCount),
          helper: 'Past target follow-ups',
          color: const Color(0xFFDA4D78),
          route: '/crm/follow-ups?dashboard_filter=overdue',
        ),
        ErpDashboardHighlightEntry(
          label: 'Upcoming',
          value: _formatInt(upcomingCount),
          helper: 'Planned next actions',
          color: const Color(0xFF2F6FED),
          route: '/crm/follow-ups?dashboard_filter=upcoming',
        ),
      ],
    ),
  );
}

bool _crmMatchesTrendFilter(
  CrmPendingFollowupItem item,
  ErpDashboardTrendFilter filter, {
  required DateTime today,
}) {
  final followupDate = item.followupDate;
  if (followupDate == null) {
    return false;
  }

  final range = _crmTrendRange(filter, today: today);
  if (range == null) {
    return true;
  }

  final normalizedDate = DateTime(
    followupDate.year,
    followupDate.month,
    followupDate.day,
  );
  return !normalizedDate.isBefore(range.start) &&
      !normalizedDate.isAfter(range.end);
}

ErpDashboardGraphRange? _crmTrendRange(
  ErpDashboardTrendFilter filter, {
  required DateTime today,
}) {
  switch (filter.preset) {
    case ErpDashboardTrendPreset.monthly:
      return ErpDashboardGraphRange(
        start: DateTime(today.year, today.month, 1),
        end: DateTime(today.year, today.month + 1, 0),
      );
    case ErpDashboardTrendPreset.weekly:
      final start = _weekStart(today);
      return ErpDashboardGraphRange(
        start: start,
        end: start.add(const Duration(days: 6)),
      );
    case ErpDashboardTrendPreset.yearly:
      return ErpDashboardGraphRange(
        start: DateTime(today.year, 1, 1),
        end: DateTime(today.year, 12, 31),
      );
    case ErpDashboardTrendPreset.custom:
      return filter.customRange;
  }
}

String _crmFilterLabel(ErpDashboardTrendFilter filter, DateTime today) {
  switch (filter.preset) {
    case ErpDashboardTrendPreset.monthly:
      return _monthLabel(today);
    case ErpDashboardTrendPreset.weekly:
      final range = _crmTrendRange(filter, today: today)!;
      return '${_compactDateLabel(range.start)} - ${_compactDateLabel(range.end)}';
    case ErpDashboardTrendPreset.yearly:
      return today.year.toString();
    case ErpDashboardTrendPreset.custom:
      final range = filter.customRange;
      if (range == null) {
        return 'selected range';
      }
      return '${_compactDateLabel(range.start)} - ${_compactDateLabel(range.end)}';
  }
}

String _compactDateLabel(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')} ${_monthLabel(date)} ${date.year}';
}

Future<ErpDashboardSnapshot> _loadAccountingDashboard({
  ErpDashboardTrendFilter? trendFilter,
}) async {
  final service = AccountsService();
  final responses = await Future.wait<dynamic>([
    service.accounts(filters: const {'per_page': 1}),
    service.vouchers(
      filters: const {'per_page': 100, 'sort_by': 'voucher_date'},
    ),
    service.cashSessions(filters: const {'per_page': 20}),
    service.bankReconciliation(filters: const {'per_page': 20}),
    service.budgets(filters: const {'per_page': 6}),
  ]);

  final accounts = responses[0] as PaginatedResponse<AccountModel>;
  final vouchers = responses[1] as PaginatedResponse<VoucherModel>;
  final cashSessions =
      (responses[2] as ApiResponse<List<CashSessionModel>>).data ??
      const <CashSessionModel>[];
  final reconciliation =
      (responses[3] as ApiResponse<List<BankReconciliationModel>>).data ??
      const <BankReconciliationModel>[];
  final budgets = responses[4] as PaginatedResponse<BudgetModel>;

  final voucherRows = vouchers.data ?? const <VoucherModel>[];
  final openCashSessions = cashSessions
      .where(
        (item) =>
            !_isClosedStatus(item.toJson(), const ['status', 'session_status']),
      )
      .length;
  final pendingReconciliation = reconciliation
      .where(
        (item) => !_isClosedStatus(item.toJson(), const [
          'status',
          'reconciliation_status',
        ]),
      )
      .length;
  return ErpDashboardSnapshot(
    title: 'Accounting Dashboard',
    subtitle: 'Live accounting records in the shared ERP dashboard layout.',
    actions: const <ErpDashboardAction>[
      ErpDashboardAction(
        label: 'Open vouchers',
        icon: Icons.receipt_long_outlined,
        route: '/accounting/vouchers',
      ),
      ErpDashboardAction(
        label: 'Open reports',
        icon: Icons.assessment_outlined,
        route: '/accounting/reports',
      ),
    ],
    stats: <ErpDashboardStat>[
      ErpDashboardStat(
        label: 'Total Invoices',
        value: _formatInt(_totalFromPaginated(vouchers)),
        helper: 'Based on live voucher records',
        icon: Icons.description_outlined,
      ),
      ErpDashboardStat(
        label: 'Pending Payments',
        value: _formatInt(pendingReconciliation),
        helper: 'Live bank reconciliation queue',
        icon: Icons.payments_outlined,
        color: const Color(0xFFE67E22),
      ),
      ErpDashboardStat(
        label: 'Open Cash Sessions',
        value: _formatInt(openCashSessions),
        helper: 'Live cashier sessions awaiting closure',
        icon: Icons.point_of_sale_outlined,
        color: const Color(0xFFDA4D78),
      ),
      ErpDashboardStat(
        label: 'Active Budgets',
        value: _formatInt(_totalFromPaginated(budgets)),
        helper: 'Budget definitions from live accounting data',
        icon: Icons.account_tree_outlined,
        color: const Color(0xFF1FA971),
      ),
    ],
    primarySections: <ErpDashboardListSection>[
      ErpDashboardListSection(
        title: 'Recent Transactions',
        subtitle: 'Latest voucher activity from the live accounting service.',
        icon: Icons.swap_horiz_outlined,
        items: voucherRows
            .take(6)
            .map(
              (voucher) => ErpDashboardListItem(
                title: stringValue(voucher.toJson(), 'voucher_no', 'Voucher'),
                subtitle: [
                  displayDate(
                    nullableStringValue(voucher.toJson(), 'voucher_date'),
                  ),
                  stringValue(voucher.toJson(), 'voucher_type_name'),
                ].where((part) => part.trim().isNotEmpty).join(' • '),
                detail: nullableStringValue(voucher.toJson(), 'remarks'),
                statusLabel: _statusLabel(voucher.toJson(), const [
                  'status',
                  'voucher_status',
                ]),
                route: '/accounting/vouchers',
              ),
            )
            .toList(growable: false),
        emptyTitle: 'No accounting entries yet',
        emptyMessage:
            'Recent accounting transactions will appear here once vouchers are posted.',
      ),
      ErpDashboardListSection(
        title: 'Control Queue',
        subtitle:
            'Live operational items pulled from cash sessions and reconciliation.',
        icon: Icons.rule_outlined,
        items: <ErpDashboardListItem>[
          ...cashSessions
              .take(3)
              .map(
                (session) => ErpDashboardListItem(
                  title: stringValue(
                    session.toJson(),
                    'session_name',
                    'Cash session',
                  ),
                  subtitle: stringValue(
                    session.toJson(),
                    'session_status',
                    stringValue(session.toJson(), 'status', 'open'),
                  ),
                  detail: nullableStringValue(session.toJson(), 'opened_at'),
                  statusLabel: _statusLabel(session.toJson(), const [
                    'session_status',
                    'status',
                  ]),
                  route: '/accounting/cash-sessions',
                ),
              ),
          ...reconciliation
              .take(3)
              .map(
                (entry) => ErpDashboardListItem(
                  title: stringValue(
                    entry.toJson(),
                    'statement_ref',
                    'Bank reconciliation',
                  ),
                  subtitle: stringValue(
                    entry.toJson(),
                    'bank_name',
                    stringValue(entry.toJson(), 'status'),
                  ),
                  detail: nullableStringValue(entry.toJson(), 'statement_date'),
                  statusLabel: _statusLabel(entry.toJson(), const [
                    'reconciliation_status',
                    'status',
                  ]),
                  route: '/accounting/bank-reconciliation',
                ),
              ),
        ],
        emptyTitle: 'No live control queue items',
        emptyMessage:
            'Cash sessions and reconciliation records will surface here.',
      ),
    ],
    trend: _buildMonthlyTrendCard(
      title: 'Monthly Billing Trend',
      subtitle: 'Total transaction value (₹) per period from live vouchers.',
      trendFilter: trendFilter,
      isCurrency: true,
      sources: <_TrendSource>[
        _TrendSource(
          records: voucherRows.map((item) => item.toJson()),
          dateKeys: const ['voucher_date', 'posting_date', 'created_at'],
          amountKey: 'total_debit',
        ),
      ],
    ),
    distribution: ErpDashboardDistributionCardData(
      title: 'Payment Distribution',
      subtitle: 'Split between open operational accounting queues.',
      segments: _segmentsFromCounts(<String, int>{
        'Open cash sessions': openCashSessions,
        'Pending reconciliation': pendingReconciliation,
        'Active budgets': _totalFromPaginated(budgets),
      }),
    ),
    highlights: ErpDashboardHighlightsCardData(
      title: 'Accounting Pulse',
      subtitle: 'Quick enterprise checks for the finance team.',
      entries: <ErpDashboardHighlightEntry>[
        ErpDashboardHighlightEntry(
          label: 'Chart of accounts',
          value: _formatInt(_totalFromPaginated(accounts)),
          helper: 'Live ledger masters',
        ),
        ErpDashboardHighlightEntry(
          label: 'Open sessions',
          value: _formatInt(openCashSessions),
          helper: 'Needs cashier closure',
          color: const Color(0xFFE67E22),
        ),
        ErpDashboardHighlightEntry(
          label: 'Budgets',
          value: _formatInt(_totalFromPaginated(budgets)),
          helper: 'Budget definitions available',
          color: const Color(0xFF1FA971),
        ),
      ],
    ),
  );
}

Future<ErpDashboardSnapshot> _loadAssetsDashboard({
  ErpDashboardTrendFilter? trendFilter,
}) async {
  final service = AssetsService();
  final responses = await Future.wait<dynamic>([
    service.assets(filters: const {'per_page': 100}),
    service.depreciationRuns(filters: const {'per_page': 100}),
    service.transfers(filters: const {'per_page': 100}),
    service.disposals(filters: const {'per_page': 100}),
  ]);

  final assets = responses[0] as PaginatedResponse<AssetModel>;
  final depreciationRuns =
      responses[1] as PaginatedResponse<AssetDepreciationRunModel>;
  final transfers = responses[2] as PaginatedResponse<AssetTransferModel>;
  final disposals = responses[3] as PaginatedResponse<AssetDisposalModel>;

  final assetRows = assets.data ?? const <AssetModel>[];
  final activeAssets = assetRows
      .where(
        (item) => _looksActive(item.toJson(), const ['asset_status', 'status']),
      )
      .length;
  final maintenanceAssets = assetRows
      .where(
        (item) => _statusContains(
          item.toJson(),
          const ['asset_status', 'status'],
          const ['maintenance', 'repair'],
        ),
      )
      .length;
  final depreciationDue =
      (depreciationRuns.data ?? const <AssetDepreciationRunModel>[])
          .where(
            (item) =>
                !_isClosedStatus(item.toJson(), const ['run_status', 'status']),
          )
          .length;

  return ErpDashboardSnapshot(
    title: 'Assets Dashboard',
    subtitle: 'Live fixed-asset records with shared ERP dashboard analytics.',
    actions: const <ErpDashboardAction>[
      ErpDashboardAction(
        label: 'Open assets',
        icon: Icons.devices_other_outlined,
        route: '/assets/register',
      ),
      ErpDashboardAction(
        label: 'Depreciation runs',
        icon: Icons.trending_down_outlined,
        route: '/assets/depreciation-runs',
      ),
    ],
    stats: <ErpDashboardStat>[
      ErpDashboardStat(
        label: 'Total Assets',
        value: _formatInt(_totalFromPaginated(assets)),
        helper: 'Live asset register count',
        icon: Icons.inventory_2_outlined,
      ),
      ErpDashboardStat(
        label: 'Active Assets',
        value: _formatInt(activeAssets),
        helper: 'Pulled from current asset status',
        icon: Icons.check_circle_outline,
        color: const Color(0xFF1FA971),
      ),
      ErpDashboardStat(
        label: 'Under Maintenance',
        value: _formatInt(maintenanceAssets),
        helper: 'Status-based live estimate',
        icon: Icons.build_outlined,
        color: const Color(0xFFE67E22),
      ),
      ErpDashboardStat(
        label: 'Depreciation Due',
        value: _formatInt(depreciationDue),
        helper: 'Open depreciation run queue',
        icon: Icons.av_timer_outlined,
        color: const Color(0xFFDA4D78),
      ),
    ],
    primarySections: <ErpDashboardListSection>[
      ErpDashboardListSection(
        title: 'Asset Maintenance Tasks',
        subtitle: 'Live assets plus open downstream asset operations.',
        icon: Icons.assignment_turned_in_outlined,
        items: <ErpDashboardListItem>[
          ...assetRows
              .take(4)
              .map(
                (asset) => ErpDashboardListItem(
                  title: stringValue(asset.toJson(), 'asset_name', 'Asset'),
                  subtitle: [
                    stringValue(asset.toJson(), 'asset_code'),
                    stringValue(asset.toJson(), 'asset_status'),
                  ].where((part) => part.trim().isNotEmpty).join(' • '),
                  detail: nullableStringValue(
                    asset.toJson(),
                    'department_name',
                  ),
                  statusLabel: _statusLabel(asset.toJson(), const [
                    'asset_status',
                    'status',
                  ]),
                  route: '/assets/register',
                ),
              ),
          ...(transfers.data ?? const <AssetTransferModel>[])
              .take(2)
              .map(
                (transfer) => ErpDashboardListItem(
                  title: stringValue(
                    transfer.toJson(),
                    'transfer_no',
                    'Asset transfer',
                  ),
                  subtitle: stringValue(
                    transfer.toJson(),
                    'transfer_status',
                    stringValue(transfer.toJson(), 'status'),
                  ),
                  detail: nullableStringValue(
                    transfer.toJson(),
                    'transfer_date',
                  ),
                  statusLabel: _statusLabel(transfer.toJson(), const [
                    'transfer_status',
                    'status',
                  ]),
                  route: '/assets/transfers',
                ),
              ),
        ],
      ),
    ],
    trend: _buildMonthlyTrendCard(
      title: 'Asset Value Trend',
      subtitle:
          'Live monthly fixed-asset activity from assets, transfers, depreciation, and disposals.',
      color: const Color(0xFF1FA971),
      trendFilter: trendFilter,
      sources: <_TrendSource>[
        _TrendSource(
          records: assetRows.map((item) => item.toJson()),
          dateKeys: const [
            'asset_date',
            'purchase_date',
            'capitalization_date',
            'created_at',
          ],
        ),
        _TrendSource(
          records: (transfers.data ?? const <AssetTransferModel>[]).map(
            (item) => item.toJson(),
          ),
          dateKeys: const ['transfer_date', 'created_at'],
        ),
        _TrendSource(
          records:
              (depreciationRuns.data ?? const <AssetDepreciationRunModel>[])
                  .map((item) => item.toJson()),
          dateKeys: const ['run_date', 'posting_date', 'created_at'],
        ),
        _TrendSource(
          records: (disposals.data ?? const <AssetDisposalModel>[]).map(
            (item) => item.toJson(),
          ),
          dateKeys: const ['disposal_date', 'posting_date', 'created_at'],
        ),
      ],
    ),
    distribution: ErpDashboardDistributionCardData(
      title: 'Asset Status Distribution',
      subtitle: 'Live operational split across asset operations.',
      segments: _segmentsFromCounts(<String, int>{
        'Active': activeAssets,
        'Maintenance': maintenanceAssets,
        'Transfers': _totalFromPaginated(transfers),
        'Disposals': _totalFromPaginated(disposals),
      }),
    ),
    highlights: ErpDashboardHighlightsCardData(
      title: 'Asset Signals',
      subtitle: 'Enterprise-ready fixed asset checkpoints.',
      entries: <ErpDashboardHighlightEntry>[
        ErpDashboardHighlightEntry(
          label: 'Transfers',
          value: _formatInt(_totalFromPaginated(transfers)),
          helper: 'Live movement documents',
        ),
        ErpDashboardHighlightEntry(
          label: 'Disposals',
          value: _formatInt(_totalFromPaginated(disposals)),
          helper: 'Retirement workflow count',
          color: const Color(0xFFDA4D78),
        ),
        ErpDashboardHighlightEntry(
          label: 'Depreciation runs',
          value: _formatInt(_totalFromPaginated(depreciationRuns)),
          helper: 'Run history and queue',
          color: const Color(0xFFE67E22),
        ),
      ],
    ),
  );
}

Future<ErpDashboardSnapshot> _loadSalesDashboard({
  ErpDashboardTrendFilter? trendFilter,
}) async {
  try {
    final service = SalesService();
    final responses = await Future.wait<dynamic>([
      _safeCollection(
        () => service.ordersAll(filters: const {'sort_by': 'order_date'}),
      ),
      _safeCollection(
        () => service.invoicesAll(filters: const {'sort_by': 'invoice_date'}),
      ),
      _safeCollection(
        () => service.receiptsAll(filters: const {'sort_by': 'receipt_date'}),
      ),
      _safeCollection(
        () =>
            service.quotationsAll(filters: const {'sort_by': 'quotation_date'}),
      ),
    ]);

    final orders = responses[0] as ApiResponse<List<SalesOrderModel>>;
    final invoices = responses[1] as ApiResponse<List<SalesInvoiceModel>>;
    final receipts = responses[2] as ApiResponse<List<SalesReceiptModel>>;
    final quotations = responses[3] as ApiResponse<List<SalesQuotationModel>>;

    final orderRows = orders.data ?? const <SalesOrderModel>[];
    final orderJsonRows = orderRows
        .map((item) => _safeMap(item.toJson))
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    final invoiceRows = invoices.data ?? const <SalesInvoiceModel>[];
    final invoiceJsonRows = invoiceRows
        .map((item) => _safeMap(() => item.toJson()))
        .toList(growable: false);
    final pendingOrders = orderJsonRows
        .where(
          (item) => !_isClosedStatus(item, const ['order_status', 'status']),
        )
        .length;

    final outstandingAmount = invoiceRows.fold<double>(0.0, (sum, item) {
      final status = (item.invoiceStatus ?? '').trim().toLowerCase();
      if (status == 'cancelled' || status == 'paid') {
        return sum;
      }
      return sum + (item.balanceAmount ?? item.totalAmount ?? 0.0);
    });

    final pipelineValue = (quotations.data ?? const <SalesQuotationModel>[])
        .fold<double>(0.0, (sum, item) {
          final status = (item.quotationStatus ?? '').trim().toLowerCase();
          if (const <String>{
            'accepted',
            'rejected',
            'expired',
            'cancelled',
          }.contains(status)) {
            return sum;
          }
          return sum + (item.totalAmount ?? 0.0);
        });

    final thisMonthSales = invoiceRows.fold<double>(0.0, (sum, item) {
      final dateStr = item.invoiceDate;
      final date = DateTime.tryParse(dateStr);
      if (date == null) return sum;
      final now = DateTime.now();
      if (date.year == now.year && date.month == now.month) {
        final status = (item.invoiceStatus ?? '').trim().toLowerCase();
        if (status == 'cancelled') return sum;
        return sum + (item.totalAmount ?? 0.0);
      }
      return sum;
    });

    final bookedValue = orderRows.fold<double>(0.0, (sum, item) {
      final status = (item.orderStatus ?? '').trim().toLowerCase();
      if (status == 'cancelled' ||
          status == 'completed' ||
          status == 'closed') {
        return sum;
      }
      return sum + (item.totalAmount ?? 0.0);
    });

    final collectedValue = (receipts.data ?? const <SalesReceiptModel>[])
        .fold<double>(0.0, (sum, item) {
          final status = (item.receiptStatus ?? '').trim().toLowerCase();
          if (status == 'cancelled') {
            return sum;
          }
          return sum + (item.paidAmount ?? 0.0);
        });

    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    final overdueInvoicesCount = invoiceRows.where((item) {
      final status = (item.invoiceStatus ?? '').trim().toLowerCase();
      if (status == 'cancelled' || status == 'paid') return false;
      final dueDate = DateTime.tryParse(item.dueDate ?? '');
      if (dueDate == null) return false;
      final normalizedDue = DateTime(dueDate.year, dueDate.month, dueDate.day);
      return normalizedDue.isBefore(normalizedToday);
    }).length;

    final overdueInvoicesAmount = invoiceRows.fold<double>(0.0, (sum, item) {
      final status = (item.invoiceStatus ?? '').trim().toLowerCase();
      if (status == 'cancelled' || status == 'paid') return sum;
      final dueDate = DateTime.tryParse(item.dueDate ?? '');
      if (dueDate == null) return sum;
      final normalizedDue = DateTime(dueDate.year, dueDate.month, dueDate.day);
      if (normalizedDue.isBefore(normalizedToday)) {
        return sum + (item.balanceAmount ?? item.totalAmount ?? 0.0);
      }
      return sum;
    });

    final delayedOrdersCount = orderRows.where((item) {
      final status = (item.orderStatus ?? '').trim().toLowerCase();
      if (status == 'cancelled' ||
          status == 'completed' ||
          status == 'closed') {
        return false;
      }
      final deliveryDate = DateTime.tryParse(item.expectedDeliveryDate ?? '');
      if (deliveryDate == null) {
        return false;
      }
      final normalizedDelivery = DateTime(
        deliveryDate.year,
        deliveryDate.month,
        deliveryDate.day,
      );
      return normalizedDelivery.isBefore(normalizedToday);
    }).length;

    final draftInvoicesCount = invoiceRows.where((item) {
      final status = (item.invoiceStatus ?? '').trim().toLowerCase();
      return status == 'draft';
    }).length;

    return ErpDashboardSnapshot(
      title: 'Sales Dashboard',
      subtitle: 'Shared ERP dashboard layout backed by live sales documents.',
      actions: const <ErpDashboardAction>[
        ErpDashboardAction(
          label: 'Open orders',
          icon: Icons.shopping_cart_checkout_outlined,
          route: '/sales/orders',
        ),
        ErpDashboardAction(
          label: 'Open invoices',
          icon: Icons.receipt_long_outlined,
          route: '/sales/invoices',
        ),
      ],
      stats: <ErpDashboardStat>[
        ErpDashboardStat(
          label: 'Pending Orders',
          value: _formatInt(pendingOrders),
          helper: 'Orders still to be fulfilled',
          icon: Icons.pending_actions_outlined,
          color: const Color(0xFFE67E22),
          route: '/sales/orders?dashboard_filter=pending',
        ),
        ErpDashboardStat(
          label: 'Outstanding Balance',
          value: _formatCurrency(outstandingAmount),
          helper: 'Awaiting customer payments',
          icon: Icons.payments_outlined,
          color: const Color(0xFFDA4D78),
          route: '/sales/invoices?dashboard_filter=open',
        ),
        ErpDashboardStat(
          label: 'Active Pipeline',
          value: _formatCurrency(pipelineValue),
          helper: 'Active sales quotations',
          icon: Icons.request_quote_outlined,
          color: const Color(0xFF2F6FED),
          route: '/sales/quotations?dashboard_filter=open',
        ),
        ErpDashboardStat(
          label: 'Monthly Sales',
          value: _formatCurrency(thisMonthSales),
          helper: 'Total invoiced this month',
          icon: Icons.trending_up_outlined,
          color: const Color(0xFF1FA971),
          route: '/sales/invoices',
        ),
      ],
      primarySections: <ErpDashboardListSection>[
        ErpDashboardListSection(
          title: 'Recent Sales Tasks',
          subtitle: 'Live sales orders and invoices to keep the team moving.',
          icon: Icons.fact_check_outlined,
          items: <ErpDashboardListItem>[
            ...orderJsonRows
                .take(4)
                .map(
                  (order) => ErpDashboardListItem(
                    title: () {
                      final no = stringValue(order, 'order_no', '');
                      return no.isEmpty ? 'Sales Order' : 'Sales Order - $no';
                    }(),
                    subtitle: [
                      displayDate(nullableStringValue(order, 'order_date')),
                      _customerName(order),
                    ].where((part) => part.trim().isNotEmpty).join(' • '),
                    detail: nullableStringValue(order, 'remarks'),
                    statusLabel: _statusLabel(order, const [
                      'order_status',
                      'status',
                    ]),
                    route: _recordRoute('/sales/orders', order),
                  ),
                ),
            ...invoiceJsonRows.take(2).map((json) {
              return ErpDashboardListItem(
                title: () {
                  final no = stringValue(json, 'invoice_no', '');
                  return no.isEmpty ? 'Sales Invoice' : 'Sales Invoice - $no';
                }(),
                subtitle: [
                  displayDate(nullableStringValue(json, 'invoice_date')),
                  _customerName(json),
                ].where((part) => part.trim().isNotEmpty).join(' • '),
                detail:
                    nullableStringValue(json, 'grand_total') ??
                    nullableStringValue(json, 'total_amount'),
                statusLabel: _statusLabel(json, const [
                  'invoice_status',
                  'status',
                ]),
                route: _recordRoute('/sales/invoices', json),
              );
            }),
          ],
        ),
      ],
      trend: _buildMonthlyTrendCard(
        title: 'Monthly Sales Revenue',
        subtitle:
            'Total invoiced amount (₹) per period from live sales invoices.',
        trendFilter: trendFilter,
        isCurrency: true,
        sources: <_TrendSource>[
          _TrendSource(
            records: invoiceJsonRows,
            dateKeys: const ['invoice_date', 'due_date', 'created_at'],
            amountKey: 'total_amount',
          ),
        ],
      ),
      distribution: ErpDashboardDistributionCardData(
        title: 'Sales Cycle Value Distribution',
        subtitle: 'Financial value split across sales lifecycle stages.',
        segments: <ErpDashboardDistributionSegment>[
          ErpDashboardDistributionSegment(
            label: 'Pipeline (Quotes)',
            value: pipelineValue,
            color: const Color(0xFF2F6FED),
          ),
          ErpDashboardDistributionSegment(
            label: 'Booked (Orders)',
            value: bookedValue,
            color: const Color(0xFFE67E22),
          ),
          ErpDashboardDistributionSegment(
            label: 'Billed (Unpaid)',
            value: outstandingAmount,
            color: const Color(0xFFDA4D78),
          ),
          ErpDashboardDistributionSegment(
            label: 'Collected (Receipts)',
            value: collectedValue,
            color: const Color(0xFF1FA971),
          ),
        ],
      ),
      highlights: ErpDashboardHighlightsCardData(
        title: 'Sales Focus',
        subtitle: 'Key operational pressure points for the sales desk.',
        entries: <ErpDashboardHighlightEntry>[
          ErpDashboardHighlightEntry(
            label: 'Overdue Invoices',
            value: _formatCurrency(overdueInvoicesAmount),
            helper: '$overdueInvoicesCount invoices past due',
            color: const Color(0xFFDA4D78),
            route: '/sales/invoices?dashboard_filter=overdue',
          ),
          ErpDashboardHighlightEntry(
            label: 'Delayed Orders',
            value: _formatInt(delayedOrdersCount),
            helper: 'Orders past expected delivery',
            color: const Color(0xFFE67E22),
            route: '/sales/orders?dashboard_filter=delayed',
          ),
          ErpDashboardHighlightEntry(
            label: 'Draft Invoices',
            value: _formatInt(draftInvoicesCount),
            helper: 'Not yet posted/sent',
            color: const Color(0xFF1FA971),
            route: '/sales/invoices?dashboard_filter=draft',
          ),
        ],
      ),
    );
  } catch (_) {
    return const ErpDashboardSnapshot(
      title: 'Sales Dashboard',
      subtitle: 'Sales dashboard is available with partial live data.',
      actions: <ErpDashboardAction>[
        ErpDashboardAction(
          label: 'Open orders',
          icon: Icons.shopping_cart_checkout_outlined,
          route: '/sales/orders',
        ),
        ErpDashboardAction(
          label: 'Open invoices',
          icon: Icons.receipt_long_outlined,
          route: '/sales/invoices',
        ),
      ],
      emptyTitle: 'Sales dashboard data is loading',
      emptyMessage:
          'One or more live sales feeds returned an unexpected format. The dashboard shell is still available while the data refreshes.',
    );
  }
}

Future<ErpDashboardSnapshot> _loadPurchaseDashboard({
  ErpDashboardTrendFilter? trendFilter,
}) async {
  final service = PurchaseService();
  final inventoryService = InventoryService();
  final responses = await Future.wait<dynamic>([
    _safePaginated(
      () => service.requisitions(
        filters: const {'per_page': 100, 'sort_by': 'requisition_date'},
      ),
    ),
    _safePaginated(
      () => service.orders(
        filters: const {'per_page': 100, 'sort_by': 'order_date'},
      ),
    ),
    _safePaginated(
      () => service.receipts(
        filters: const {'per_page': 100, 'sort_by': 'receipt_date'},
      ),
    ),
    _safePaginated(
      () => service.invoices(
        filters: const {'per_page': 100, 'sort_by': 'invoice_date'},
      ),
    ),
    _safePaginated(
      () => inventoryService.stockBalances(
        filters: const {'per_page': 100, 'sort_by': 'item_name'},
      ),
    ),
  ]);

  final requisitions =
      responses[0] as PaginatedResponse<PurchaseRequisitionModel>;
  final orders = responses[1] as PaginatedResponse<PurchaseOrderModel>;
  final receipts = responses[2] as PaginatedResponse<PurchaseReceiptModel>;
  final invoices = responses[3] as PaginatedResponse<PurchaseInvoiceModel>;
  final stockBalances = responses[4] as PaginatedResponse<StockBalanceModel>;

  final requisitionRows =
      requisitions.data ?? const <PurchaseRequisitionModel>[];
  final orderRows = orders.data ?? const <PurchaseOrderModel>[];
  final receiptRows = receipts.data ?? const <PurchaseReceiptModel>[];
  final invoiceRows = invoices.data ?? const <PurchaseInvoiceModel>[];
  final stockRows = stockBalances.data ?? const <StockBalanceModel>[];

  final requisitionJsonRows = requisitionRows
      .map((item) => _safeMap(item.toJson))
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
  final orderJsonRows = orderRows
      .map((item) => _safeMap(item.toJson))
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
  final receiptJsonRows = receiptRows
      .map((item) => _safeMap(item.toJson))
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
  final invoiceJsonRows = invoiceRows
      .map((item) => _safeMap(item.toJson))
      .where((item) => item.isNotEmpty)
      .toList(growable: false);

  final thisMonthPurchaseValue = orderRows
      .where((item) => _isInCurrentMonth(item.toJson(), const ['order_date']))
      .fold<double>(0, (sum, item) => sum + (item.totalAmount ?? 0));
  final pendingOrders = orderJsonRows
      .where((item) => !_isClosedStatus(item, const ['order_status', 'status']))
      .length;
  final vendorPayables = invoiceRows.fold<double>(
    0,
    (sum, item) => sum + ((item.balanceAmount ?? item.totalAmount) ?? 0),
  );
  final delayedDeliveries = orderRows.where((item) {
    final json = item.toJson();
    final status = _statusLabel(json, const [
      'order_status',
      'status',
    ]).toLowerCase();
    if (_statusIndicatesDelivered(status) ||
        _statusIndicatesCancelled(status)) {
      return false;
    }
    return _isOverdue(json, const ['expected_receipt_date']);
  }).length;
  final lowStockItems = stockRows.where(_isLowStockBalance).length;

  final prPendingCount = requisitionJsonRows.where((item) {
    final status = _statusLabel(item, const [
      'requisition_status',
      'status',
    ]).toLowerCase();
    return !_statusIndicatesClosed(status) && !status.contains('approved');
  }).length;
  final poOpenCount = pendingOrders;
  final grnPendingCount = orderRows.where((item) {
    final status = _statusLabel(item.toJson(), const [
      'order_status',
      'status',
    ]).toLowerCase();
    return !_statusIndicatesClosed(status) &&
        !_statusIndicatesDelivered(status);
  }).length;
  final billsPendingCount = invoiceRows.where((item) {
    final status = (item.invoiceStatus ?? '').trim().toLowerCase();
    final balance = item.balanceAmount ?? item.totalAmount ?? 0;
    return !_statusIndicatesCancelled(status) && balance > 0;
  }).length;
  final paymentPendingCount = billsPendingCount;
  final lowStockRows = stockRows
      .where(_isLowStockBalance)
      .take(4)
      .map(
        (item) => ErpDashboardListItem(
          title: item.toString(),
          subtitle: [
            if (item.warehouseName?.trim().isNotEmpty == true)
              item.warehouseName!,
            'Current ${_formatQuantity(item.qtyAvailable ?? item.qtyOnHand ?? 0)}',
          ].join(' • '),
          detail: _buildSuggestedReorderDetail(item),
          statusLabel: 'LOW STOCK',
          statusColor: const Color(0xFFDA4D78),
          route: '/inventory/stock-balance',
        ),
      )
      .toList(growable: false);
  final overdueOrders = orderRows
      .where(
        (item) => _isOverdue(item.toJson(), const ['expected_receipt_date']),
      )
      .take(4)
      .map(
        (item) => ErpDashboardListItem(
          title: item.orderNo ?? 'Purchase order',
          subtitle: [
            _supplierName(item.toJson()),
            displayDate(item.expectedReceiptDate),
          ].where((part) => part.trim().isNotEmpty).join(' • '),
          detail: _formatCurrency(item.totalAmount),
          statusLabel: 'DELAYED',
          statusColor: const Color(0xFFDA4D78),
          route: _recordRoute('/purchase/orders', item.toJson()),
        ),
      )
      .toList(growable: false);
  final recentPurchases = <ErpDashboardListItem>[
    ...orderRows
        .take(3)
        .map(
          (item) => ErpDashboardListItem(
            title: item.orderNo ?? 'Purchase order',
            subtitle: [
              _supplierName(item.toJson()),
              displayDate(item.orderDate),
            ].where((part) => part.trim().isNotEmpty).join(' • '),
            detail: _formatCurrency(item.totalAmount),
            statusLabel: _statusLabel(item.toJson(), const [
              'order_status',
              'status',
            ]),
            route: _recordRoute('/purchase/orders', item.toJson()),
          ),
        ),
    ...invoiceRows
        .take(2)
        .map(
          (item) => ErpDashboardListItem(
            title: item.invoiceNo ?? 'Purchase bill',
            subtitle: [
              _supplierName(item.toJson()),
              displayDate(item.invoiceDate),
            ].where((part) => part.trim().isNotEmpty).join(' • '),
            detail: _formatCurrency(item.totalAmount),
            statusLabel: _statusLabel(item.toJson(), const [
              'invoice_status',
              'status',
            ]),
            route: _recordRoute('/purchase/invoices', item.toJson()),
          ),
        ),
  ];
  final alerts = <ErpDashboardListItem>[
    if (delayedDeliveries > 0)
      ErpDashboardListItem(
        title: 'Delayed deliveries need supplier follow-up',
        subtitle:
            '$delayedDeliveries purchase orders are past expected receipt date.',
        detail: 'Escalate delayed suppliers and reschedule receipts.',
        statusLabel: 'HIGH',
        statusColor: const Color(0xFFDA4D78),
        route: '/purchase/orders?dashboard_filter=delayed',
      ),
    if (lowStockItems > 0)
      ErpDashboardListItem(
        title: 'Low stock items may require urgent buying',
        subtitle:
            '$lowStockItems items are at or below available stock threshold.',
        detail: 'Review inventory and raise new requisitions or orders.',
        statusLabel: 'MEDIUM',
        statusColor: const Color(0xFFE67E22),
        route: '/inventory/stock-balance',
      ),
    if (paymentPendingCount > 0)
      ErpDashboardListItem(
        title: 'Vendor bills are pending payment',
        subtitle:
            '$paymentPendingCount supplier invoices still have open balances.',
        detail: 'Outstanding payables: ${_formatCurrency(vendorPayables)}',
        statusLabel: 'PAYABLE',
        statusColor: const Color(0xFF19A7B8),
        route: '/purchase/invoices',
      ),
  ];

  return ErpDashboardSnapshot(
    title: 'Purchase Dashboard',
    subtitle: 'Crisp purchase view for fast daily analysis.',
    actions: const <ErpDashboardAction>[
      ErpDashboardAction(
        label: 'Create Purchase Order',
        icon: Icons.shopping_bag_outlined,
        route: '/purchase/orders',
      ),
      ErpDashboardAction(
        label: 'Record GRN',
        icon: Icons.move_to_inbox_outlined,
        route: '/purchase/receipts',
      ),
      ErpDashboardAction(
        label: 'Upload Bill',
        icon: Icons.receipt_long_outlined,
        route: '/purchase/invoices',
      ),
    ],
    stats: <ErpDashboardStat>[
      ErpDashboardStat(
        label: 'This Month Purchase',
        value: _formatCurrency(thisMonthPurchaseValue),
        helper: 'Monthly purchase amount',
        icon: Icons.calendar_month_outlined,
      ),
      ErpDashboardStat(
        label: 'Pending PO',
        value: _formatInt(pendingOrders),
        helper: 'Ordered but not fully received',
        icon: Icons.pending_actions_outlined,
        color: const Color(0xFFE67E22),
      ),
      ErpDashboardStat(
        label: 'Pending GRN',
        value: _formatInt(grnPendingCount),
        helper: 'Deliveries waiting to be recorded',
        icon: Icons.move_to_inbox_outlined,
        color: const Color(0xFF8E5CFF),
      ),
      ErpDashboardStat(
        label: 'Vendor Payables',
        value: _formatCurrency(vendorPayables),
        helper: 'Open amount to be paid',
        icon: Icons.account_balance_wallet_outlined,
        color: const Color(0xFFDA4D78),
      ),
      ErpDashboardStat(
        label: 'Low Stock Items',
        value: _formatInt(lowStockItems),
        helper: 'Need urgent purchase review',
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFFE67E22),
      ),
    ],
    primarySections: <ErpDashboardListSection>[
      ErpDashboardListSection(
        title: 'Purchase Flow Status',
        subtitle: 'Only the core operational counts that need daily attention.',
        icon: Icons.account_tree_outlined,
        items: <ErpDashboardListItem>[
          ErpDashboardListItem(
            title: 'Purchase Request Pending',
            subtitle: '$prPendingCount requests still need action.',
            statusLabel: _formatInt(prPendingCount),
            statusColor: const Color(0xFFE67E22),
            route: '/purchase/requisitions',
          ),
          ErpDashboardListItem(
            title: 'Purchase Orders Open',
            subtitle: '$poOpenCount orders are still active.',
            statusLabel: _formatInt(poOpenCount),
            statusColor: const Color(0xFF19A7B8),
            route: '/purchase/orders',
          ),
          ErpDashboardListItem(
            title: 'GRN Pending',
            subtitle: '$grnPendingCount orders are still awaiting receipts.',
            statusLabel: _formatInt(grnPendingCount),
            statusColor: const Color(0xFFDA4D78),
            route: '/purchase/receipts',
          ),
          ErpDashboardListItem(
            title: 'Bills Pending',
            subtitle:
                '$billsPendingCount supplier invoices still have open balance.',
            statusLabel: _formatInt(billsPendingCount),
            statusColor: const Color(0xFFE67E22),
            route: '/purchase/invoices',
          ),
          ErpDashboardListItem(
            title: 'Payment Pending',
            subtitle: '$paymentPendingCount supplier payments remain open.',
            statusLabel: _formatInt(paymentPendingCount),
            statusColor: const Color(0xFF2F6FED),
            route: '/purchase/invoices',
          ),
        ],
      ),
      ErpDashboardListSection(
        title: 'Pending Actions',
        subtitle: 'What the purchase team should act on today.',
        icon: Icons.assignment_late_outlined,
        items: <ErpDashboardListItem>[
          ...overdueOrders,
          ...invoiceRows
              .where(
                (item) => (item.balanceAmount ?? item.totalAmount ?? 0) > 0,
              )
              .take(3)
              .map(
                (item) => ErpDashboardListItem(
                  title: item.invoiceNo ?? 'Supplier bill pending',
                  subtitle: [
                    _supplierName(item.toJson()),
                    if ((item.dueDate ?? '').trim().isNotEmpty)
                      'Due ${displayDate(item.dueDate)}',
                  ].join(' • '),
                  detail:
                      'Open ${_formatCurrency(item.balanceAmount ?? item.totalAmount)}',
                  statusLabel: _invoicePaymentStatus(item),
                  statusColor: _invoicePaymentStatusColor(item),
                  route: _recordRoute('/purchase/invoices', item.toJson()),
                ),
              ),
        ],
        emptyTitle: 'No pending purchase actions',
        emptyMessage: 'All current purchase tasks look under control.',
      ),
      ErpDashboardListSection(
        title: 'Recent Purchases',
        subtitle: 'Latest orders and bills raised with suppliers.',
        icon: Icons.history_toggle_off_outlined,
        items: recentPurchases,
        emptyTitle: 'No recent purchases yet',
        emptyMessage: 'Recent purchase documents will appear here.',
      ),
      ErpDashboardListSection(
        title: 'Low Stock Focus',
        subtitle: 'Urgent stock items that may need new buying.',
        icon: Icons.inventory_2_outlined,
        items: lowStockRows.isNotEmpty ? lowStockRows : alerts.take(2).toList(),
        emptyTitle: 'No stock or delivery alerts right now',
        emptyMessage: 'Purchase and inventory look under control.',
      ),
    ],
    trend: _buildMonthlyTrendCard(
      title: 'Monthly Purchase Trend',
      subtitle:
          'Procurement flow over time from requisitions, orders, receipts, and bills.',
      color: const Color(0xFF19A7B8),
      trendFilter: trendFilter,
      sources: <_TrendSource>[
        _TrendSource(
          records: requisitionJsonRows,
          dateKeys: const ['requisition_date', 'required_date', 'created_at'],
        ),
        _TrendSource(
          records: orderJsonRows,
          dateKeys: const ['order_date', 'expected_receipt_date', 'created_at'],
        ),
        _TrendSource(
          records: receiptJsonRows,
          dateKeys: const [
            'receipt_date',
            'supplier_invoice_date',
            'created_at',
          ],
        ),
        _TrendSource(
          records: invoiceJsonRows,
          dateKeys: const ['invoice_date', 'due_date', 'created_at'],
        ),
      ],
    ),
  );
}

Future<ErpDashboardSnapshot> _loadInventoryDashboard({
  ErpDashboardTrendFilter? trendFilter,
}) async {
  final service = InventoryService();
  final responses = await Future.wait<dynamic>([
    service.items(filters: const {'per_page': 20}),
    service.stockBalances(filters: const {'per_page': 50}),
    service.stockMovements(filters: const {'per_page': 100}),
  ]);

  final items = responses[0] as PaginatedResponse<ItemModel>;
  final balances = responses[1] as PaginatedResponse<StockBalanceModel>;
  final movements = responses[2] as PaginatedResponse<StockMovementModel>;

  final balanceRows = balances.data ?? const <StockBalanceModel>[];
  final movementRows = movements.data ?? const <StockMovementModel>[];

  final lowStock = balanceRows.where(_isLowStockBalance).length;
  final stockIn = movementRows.where((row) {
    return _statusContains(
      row.toJson(),
      const ['stock_effect', 'movement_type'],
      const ['in', 'receipt', 'add'],
    );
  }).length;
  final stockOut = movementRows.where((row) {
    return _statusContains(
      row.toJson(),
      const ['stock_effect', 'movement_type'],
      const ['out', 'issue', 'consume'],
    );
  }).length;

  return ErpDashboardSnapshot(
    title: 'Inventory Dashboard',
    subtitle:
        'Live item, balance, and movement records using the shared ERP analytics layout.',
    actions: const <ErpDashboardAction>[
      ErpDashboardAction(
        label: 'Open items',
        icon: Icons.inventory_2_outlined,
        route: '/inventory/items',
      ),
      ErpDashboardAction(
        label: 'Open movements',
        icon: Icons.sync_alt_outlined,
        route: '/inventory/stock-movements',
      ),
    ],
    stats: <ErpDashboardStat>[
      ErpDashboardStat(
        label: 'Total Items',
        value: _formatInt(_totalFromPaginated(items)),
        helper: 'Live item master count',
        icon: Icons.inventory_outlined,
      ),
      ErpDashboardStat(
        label: 'Low Stock',
        value: _formatInt(lowStock),
        helper: 'Detected from current balance snapshot',
        icon: Icons.warning_amber_outlined,
        color: const Color(0xFFE67E22),
      ),
      ErpDashboardStat(
        label: 'Stock In',
        value: _formatInt(stockIn),
        helper: 'Recent inbound movement records',
        icon: Icons.south_west_outlined,
        color: const Color(0xFF1FA971),
      ),
      ErpDashboardStat(
        label: 'Stock Out',
        value: _formatInt(stockOut),
        helper: 'Recent outbound movement records',
        icon: Icons.north_east_outlined,
        color: const Color(0xFFDA4D78),
      ),
    ],
    primarySections: <ErpDashboardListSection>[
      ErpDashboardListSection(
        title: 'Stock Alerts',
        subtitle: 'Live low-stock balances plus recent movement queue.',
        icon: Icons.notification_important_outlined,
        items: <ErpDashboardListItem>[
          ...balanceRows
              .where(_isLowStockBalance)
              .take(4)
              .map(
                (balance) => ErpDashboardListItem(
                  title: stringValue(
                    balance.toJson(),
                    'item_name',
                    'Inventory item',
                  ),
                  subtitle: [
                    stringValue(balance.toJson(), 'warehouse_name'),
                    stringValue(balance.toJson(), 'item_code'),
                  ].where((part) => part.trim().isNotEmpty).join(' • '),
                  detail:
                      'Qty ${stringValue(balance.toJson(), 'available_qty', stringValue(balance.toJson(), 'qty_on_hand'))}',
                  statusLabel: 'LOW',
                  statusColor: const Color(0xFFE67E22),
                  route: '/inventory/stock-balances',
                ),
              ),
          ...movementRows
              .take(2)
              .map(
                (movement) => ErpDashboardListItem(
                  title: stringValue(
                    movement.toJson(),
                    'reference_no',
                    'Stock movement',
                  ),
                  subtitle: [
                    displayDate(
                      nullableStringValue(movement.toJson(), 'movement_date'),
                    ),
                    stringValue(movement.toJson(), 'movement_type'),
                  ].where((part) => part.trim().isNotEmpty).join(' • '),
                  detail: stringValue(movement.toJson(), 'stock_effect'),
                  statusLabel: _statusLabel(movement.toJson(), const [
                    'stock_effect',
                    'movement_type',
                  ]),
                  route: '/inventory/stock-movements',
                ),
              ),
        ],
      ),
    ],
    trend: _buildMonthlyTrendCard(
      title: 'Inventory Movement Trend',
      subtitle: 'Live monthly inventory movement activity.',
      color: const Color(0xFF19A7B8),
      trendFilter: trendFilter,
      sources: <_TrendSource>[
        _TrendSource(
          records: movementRows.map((item) => item.toJson()),
          dateKeys: const ['movement_date', 'posting_date', 'created_at'],
        ),
      ],
    ),
    distribution: ErpDashboardDistributionCardData(
      title: 'Stock Distribution',
      subtitle:
          'Current split between low stock, inflow, and outflow activity.',
      segments: _segmentsFromCounts(<String, int>{
        'Low stock': lowStock,
        'Stock in': stockIn,
        'Stock out': stockOut,
        'Balance rows': _totalFromPaginated(balances),
      }),
    ),
  );
}

Future<ErpDashboardSnapshot> _loadPlanningDashboard({
  ErpDashboardTrendFilter? trendFilter,
}) async {
  final service = PlanningService();
  final responses = await Future.wait<dynamic>([
    service.mrpRuns(filters: const {'per_page': 100}),
    service.mrpRecommendations(filters: const {'per_page': 100}),
    service.stockReservations(filters: const {'per_page': 100}),
    service.mrpDemands(filters: const {'per_page': 100}),
  ]);

  final runs = responses[0] as PaginatedResponse<MrpRunModel>;
  final recommendations =
      responses[1] as PaginatedResponse<MrpRecommendationModel>;
  final reservations = responses[2] as PaginatedResponse<StockReservationModel>;
  final demands = responses[3] as PaginatedResponse<MrpDemandModel>;

  return _buildGenericLiveDashboard(
    title: 'Planning Dashboard',
    subtitle:
        'Live MRP, reservation, and recommendation workload in the shared dashboard frame.',
    actions: const <ErpDashboardAction>[
      ErpDashboardAction(
        label: 'Open MRP runs',
        icon: Icons.play_circle_outline,
        route: '/planning/mrp-runs',
      ),
      ErpDashboardAction(
        label: 'Recommendations',
        icon: Icons.tips_and_updates_outlined,
        route: '/planning/mrp-recommendations',
      ),
    ],
    statSpecs: <_DashboardStatSpec>[
      _DashboardStatSpec(
        'MRP Runs',
        _totalFromPaginated(runs),
        Icons.route_outlined,
      ),
      _DashboardStatSpec(
        'Recommendations',
        _totalFromPaginated(recommendations),
        Icons.lightbulb_outline,
      ),
      _DashboardStatSpec(
        'Reservations',
        _totalFromPaginated(reservations),
        Icons.bookmark_outline,
        color: const Color(0xFFE67E22),
      ),
      _DashboardStatSpec(
        'Demand Rows',
        _totalFromPaginated(demands),
        Icons.trending_up_outlined,
        color: const Color(0xFF19A7B8),
      ),
    ],
    primarySection: ErpDashboardListSection(
      title: 'Planning Queue',
      subtitle: 'Recent MRP runs and recommendations from live planning APIs.',
      icon: Icons.fact_check_outlined,
      items: <ErpDashboardListItem>[
        ...(runs.data ?? const <MrpRunModel>[])
            .take(3)
            .map(
              (item) => _genericListItem(
                data: item.toJson(),
                fallbackTitle: 'MRP Run',
                titleKeys: const ['run_no', 'name'],
                subtitleKeys: const ['run_status', 'status'],
                routeBase: '/planning/mrp-runs',
              ),
            ),
        ...(recommendations.data ?? const <MrpRecommendationModel>[])
            .take(3)
            .map(
              (item) => _genericListItem(
                data: item.toJson(),
                fallbackTitle: 'Recommendation',
                titleKeys: const ['recommendation_no', 'name'],
                subtitleKeys: const ['recommendation_status', 'status'],
                routeBase: '/planning/mrp-recommendations',
              ),
            ),
      ],
    ),
    trend: _buildMonthlyTrendCard(
      title: 'Planning Trend',
      subtitle: 'Live monthly MRP and planning activity.',
      trendFilter: trendFilter,
      sources: <_TrendSource>[
        _TrendSource(
          records: (runs.data ?? const <MrpRunModel>[]).map(
            (item) => item.toJson(),
          ),
          dateKeys: const ['run_date', 'planned_date', 'created_at'],
        ),
        _TrendSource(
          records: (recommendations.data ?? const <MrpRecommendationModel>[])
              .map((item) => item.toJson()),
          dateKeys: const [
            'recommendation_date',
            'required_date',
            'created_at',
          ],
        ),
        _TrendSource(
          records: (reservations.data ?? const <StockReservationModel>[]).map(
            (item) => item.toJson(),
          ),
          dateKeys: const ['reservation_date', 'required_date', 'created_at'],
        ),
        _TrendSource(
          records: (demands.data ?? const <MrpDemandModel>[]).map(
            (item) => item.toJson(),
          ),
          dateKeys: const ['demand_date', 'required_date', 'created_at'],
        ),
      ],
    ),
    distributionCounts: <String, int>{
      'Runs': _totalFromPaginated(runs),
      'Recommendations': _totalFromPaginated(recommendations),
      'Reservations': _totalFromPaginated(reservations),
      'Demands': _totalFromPaginated(demands),
    },
  );
}

Future<ErpDashboardSnapshot> _loadManufacturingDashboard({
  ErpDashboardTrendFilter? trendFilter,
}) async {
  final service = ManufacturingService();
  final responses = await Future.wait<dynamic>([
    service.productionOrders(filters: const {'per_page': 100}),
    service.productionMaterialIssues(filters: const {'per_page': 100}),
    service.productionReceipts(filters: const {'per_page': 100}),
    service.boms(filters: const {'per_page': 100}),
  ]);

  final orders = responses[0] as PaginatedResponse<ProductionOrderModel>;
  final issues =
      responses[1] as PaginatedResponse<ProductionMaterialIssueModel>;
  final receipts = responses[2] as PaginatedResponse<ProductionReceiptModel>;
  final boms = responses[3] as PaginatedResponse<BomModel>;

  return _buildGenericLiveDashboard(
    title: 'Manufacturing Dashboard',
    subtitle:
        'Live production flow surfaced through the reusable ERP module dashboard.',
    actions: const <ErpDashboardAction>[
      ErpDashboardAction(
        label: 'Open production orders',
        icon: Icons.precision_manufacturing_outlined,
        route: '/manufacturing/production-orders',
      ),
      ErpDashboardAction(
        label: 'Open receipts',
        icon: Icons.download_done_outlined,
        route: '/manufacturing/production-receipts',
      ),
    ],
    statSpecs: <_DashboardStatSpec>[
      _DashboardStatSpec(
        'Production Orders',
        _totalFromPaginated(orders),
        Icons.factory_outlined,
      ),
      _DashboardStatSpec(
        'Material Issues',
        _totalFromPaginated(issues),
        Icons.upload_file_outlined,
        color: const Color(0xFFE67E22),
      ),
      _DashboardStatSpec(
        'Production Receipts',
        _totalFromPaginated(receipts),
        Icons.download_done_outlined,
        color: const Color(0xFF1FA971),
      ),
      _DashboardStatSpec(
        'BOMs',
        _totalFromPaginated(boms),
        Icons.list_alt_outlined,
        color: const Color(0xFF19A7B8),
      ),
    ],
    primarySection: ErpDashboardListSection(
      title: 'Manufacturing Queue',
      subtitle: 'Recent production orders and material issues from live APIs.',
      icon: Icons.assignment_outlined,
      items: <ErpDashboardListItem>[
        ...(orders.data ?? const <ProductionOrderModel>[])
            .take(3)
            .map(
              (item) => _genericListItem(
                data: item.toJson(),
                fallbackTitle: 'Production Order',
                titleKeys: const ['production_order_no', 'order_no'],
                subtitleKeys: const ['order_status', 'status'],
                routeBase: '/manufacturing/production-orders',
              ),
            ),
        ...(issues.data ?? const <ProductionMaterialIssueModel>[])
            .take(3)
            .map(
              (item) => _genericListItem(
                data: item.toJson(),
                fallbackTitle: 'Material Issue',
                titleKeys: const ['issue_no', 'reference_no'],
                subtitleKeys: const ['issue_status', 'status'],
                routeBase: '/manufacturing/production-material-issues',
              ),
            ),
      ],
    ),
    trend: _buildMonthlyTrendCard(
      title: 'Manufacturing Trend',
      subtitle: 'Live monthly production activity.',
      trendFilter: trendFilter,
      sources: <_TrendSource>[
        _TrendSource(
          records: (orders.data ?? const <ProductionOrderModel>[]).map(
            (item) => item.toJson(),
          ),
          dateKeys: const [
            'production_date',
            'order_date',
            'planned_start_date',
            'created_at',
          ],
        ),
        _TrendSource(
          records: (issues.data ?? const <ProductionMaterialIssueModel>[]).map(
            (item) => item.toJson(),
          ),
          dateKeys: const ['issue_date', 'posting_date', 'created_at'],
        ),
        _TrendSource(
          records: (receipts.data ?? const <ProductionReceiptModel>[]).map(
            (item) => item.toJson(),
          ),
          dateKeys: const ['receipt_date', 'posting_date', 'created_at'],
        ),
        _TrendSource(
          records: (boms.data ?? const <BomModel>[]).map(
            (item) => item.toJson(),
          ),
          dateKeys: const ['created_at', 'effective_from'],
        ),
      ],
    ),
    distributionCounts: <String, int>{
      'Orders': _totalFromPaginated(orders),
      'Issues': _totalFromPaginated(issues),
      'Receipts': _totalFromPaginated(receipts),
      'BOMs': _totalFromPaginated(boms),
    },
  );
}

Future<ErpDashboardSnapshot> _loadQualityDashboard({
  ErpDashboardTrendFilter? trendFilter,
}) async {
  final service = QualityService();
  final responses = await Future.wait<dynamic>([
    service.qcPlans(filters: const {'per_page': 100}),
    service.qcInspections(filters: const {'per_page': 100}),
    service.qcResultActions(filters: const {'per_page': 100}),
    service.qcNonConformanceLogs(filters: const {'per_page': 100}),
  ]);

  final plans = responses[0] as PaginatedResponse<QcPlanModel>;
  final inspections = responses[1] as PaginatedResponse<QcInspectionModel>;
  final actions = responses[2] as PaginatedResponse<QcResultActionModel>;
  final ncr = responses[3] as PaginatedResponse<QcNonConformanceLogModel>;

  return _buildGenericLiveDashboard(
    title: 'Quality Dashboard',
    subtitle:
        'Live inspections, plans, and non-conformance activity using the shared dashboard design.',
    actions: const <ErpDashboardAction>[
      ErpDashboardAction(
        label: 'Open inspections',
        icon: Icons.fact_check_outlined,
        route: '/quality/qc-inspections',
      ),
      ErpDashboardAction(
        label: 'Open actions',
        icon: Icons.assignment_turned_in_outlined,
        route: '/quality/qc-result-actions',
      ),
    ],
    statSpecs: <_DashboardStatSpec>[
      _DashboardStatSpec(
        'QC Plans',
        _totalFromPaginated(plans),
        Icons.rule_outlined,
      ),
      _DashboardStatSpec(
        'Inspections',
        _totalFromPaginated(inspections),
        Icons.fact_check_outlined,
        color: const Color(0xFF19A7B8),
      ),
      _DashboardStatSpec(
        'Result Actions',
        _totalFromPaginated(actions),
        Icons.task_alt_outlined,
        color: const Color(0xFF1FA971),
      ),
      _DashboardStatSpec(
        'Non Conformance',
        _totalFromPaginated(ncr),
        Icons.report_problem_outlined,
        color: const Color(0xFFDA4D78),
      ),
    ],
    primarySection: ErpDashboardListSection(
      title: 'Quality Control Queue',
      subtitle: 'Recent inspections and non-conformance logs from live APIs.',
      icon: Icons.verified_outlined,
      items: <ErpDashboardListItem>[
        ...(inspections.data ?? const <QcInspectionModel>[])
            .take(3)
            .map(
              (item) => _genericListItem(
                data: item.toJson(),
                fallbackTitle: 'QC Inspection',
                titleKeys: const ['inspection_no', 'reference_no'],
                subtitleKeys: const ['inspection_status', 'status'],
                routeBase: '/quality/qc-inspections',
              ),
            ),
        ...(ncr.data ?? const <QcNonConformanceLogModel>[])
            .take(3)
            .map(
              (item) => _genericListItem(
                data: item.toJson(),
                fallbackTitle: 'Non Conformance',
                titleKeys: const ['log_no', 'reference_no'],
                subtitleKeys: const ['status', 'ncr_status'],
                routeBase: '/quality/qc-non-conformance-logs',
              ),
            ),
      ],
    ),
    trend: _buildMonthlyTrendCard(
      title: 'Quality Trend',
      subtitle: 'Live monthly quality control activity.',
      trendFilter: trendFilter,
      sources: <_TrendSource>[
        _TrendSource(
          records: (plans.data ?? const <QcPlanModel>[]).map(
            (item) => item.toJson(),
          ),
          dateKeys: const ['plan_date', 'effective_from', 'created_at'],
        ),
        _TrendSource(
          records: (inspections.data ?? const <QcInspectionModel>[]).map(
            (item) => item.toJson(),
          ),
          dateKeys: const ['inspection_date', 'created_at'],
        ),
        _TrendSource(
          records: (actions.data ?? const <QcResultActionModel>[]).map(
            (item) => item.toJson(),
          ),
          dateKeys: const ['action_date', 'due_date', 'created_at'],
        ),
        _TrendSource(
          records: (ncr.data ?? const <QcNonConformanceLogModel>[]).map(
            (item) => item.toJson(),
          ),
          dateKeys: const ['log_date', 'reported_date', 'created_at'],
        ),
      ],
    ),
    distributionCounts: <String, int>{
      'Plans': _totalFromPaginated(plans),
      'Inspections': _totalFromPaginated(inspections),
      'Actions': _totalFromPaginated(actions),
      'NCR': _totalFromPaginated(ncr),
    },
  );
}

Future<ErpDashboardSnapshot> _loadJobworkDashboard({
  ErpDashboardTrendFilter? trendFilter,
}) async {
  final service = JobworkService();
  final responses = await Future.wait<dynamic>([
    service.orders(filters: const {'per_page': 100}),
    service.dispatches(filters: const {'per_page': 100}),
    service.receipts(filters: const {'per_page': 100}),
    service.charges(filters: const {'per_page': 100}),
  ]);

  final orders = responses[0] as PaginatedResponse<JobworkOrderModel>;
  final dispatches = responses[1] as PaginatedResponse<JobworkDispatchModel>;
  final receipts = responses[2] as PaginatedResponse<JobworkReceiptModel>;
  final charges = responses[3] as PaginatedResponse<JobworkChargeModel>;

  return _buildGenericLiveDashboard(
    title: 'Jobwork Dashboard',
    subtitle:
        'Live order, dispatch, and receipt flow using the shared ERP dashboard layout.',
    actions: const <ErpDashboardAction>[
      ErpDashboardAction(
        label: 'Open orders',
        icon: Icons.assignment_outlined,
        route: '/jobwork/orders',
      ),
      ErpDashboardAction(
        label: 'Open dispatches',
        icon: Icons.local_shipping_outlined,
        route: '/jobwork/dispatches',
      ),
    ],
    statSpecs: <_DashboardStatSpec>[
      _DashboardStatSpec(
        'Orders',
        _totalFromPaginated(orders),
        Icons.assignment_outlined,
      ),
      _DashboardStatSpec(
        'Dispatches',
        _totalFromPaginated(dispatches),
        Icons.local_shipping_outlined,
        color: const Color(0xFF19A7B8),
      ),
      _DashboardStatSpec(
        'Receipts',
        _totalFromPaginated(receipts),
        Icons.inventory_outlined,
        color: const Color(0xFF1FA971),
      ),
      _DashboardStatSpec(
        'Charges',
        _totalFromPaginated(charges),
        Icons.currency_rupee_outlined,
        color: const Color(0xFFE67E22),
      ),
    ],
    primarySection: ErpDashboardListSection(
      title: 'Jobwork Queue',
      subtitle: 'Recent live jobwork transactions.',
      icon: Icons.handyman_outlined,
      items: <ErpDashboardListItem>[
        ...(orders.data ?? const <JobworkOrderModel>[])
            .take(3)
            .map(
              (item) => _genericListItem(
                data: item.toJson(),
                fallbackTitle: 'Jobwork Order',
                titleKeys: const ['order_no', 'jobwork_order_no'],
                subtitleKeys: const ['status', 'order_status'],
                routeBase: '/jobwork/orders',
              ),
            ),
        ...(dispatches.data ?? const <JobworkDispatchModel>[])
            .take(3)
            .map(
              (item) => _genericListItem(
                data: item.toJson(),
                fallbackTitle: 'Dispatch',
                titleKeys: const ['dispatch_no', 'reference_no'],
                subtitleKeys: const ['status', 'dispatch_status'],
                routeBase: '/jobwork/dispatches',
              ),
            ),
      ],
    ),
    trend: _buildMonthlyTrendCard(
      title: 'Jobwork Trend',
      subtitle: 'Live monthly jobwork activity.',
      trendFilter: trendFilter,
      sources: <_TrendSource>[
        _TrendSource(
          records: (orders.data ?? const <JobworkOrderModel>[]).map(
            (item) => item.toJson(),
          ),
          dateKeys: const ['order_date', 'jobwork_date', 'created_at'],
        ),
        _TrendSource(
          records: (dispatches.data ?? const <JobworkDispatchModel>[]).map(
            (item) => item.toJson(),
          ),
          dateKeys: const ['dispatch_date', 'posting_date', 'created_at'],
        ),
        _TrendSource(
          records: (receipts.data ?? const <JobworkReceiptModel>[]).map(
            (item) => item.toJson(),
          ),
          dateKeys: const ['receipt_date', 'posting_date', 'created_at'],
        ),
        _TrendSource(
          records: (charges.data ?? const <JobworkChargeModel>[]).map(
            (item) => item.toJson(),
          ),
          dateKeys: const ['charge_date', 'posting_date', 'created_at'],
        ),
      ],
    ),
    distributionCounts: <String, int>{
      'Orders': _totalFromPaginated(orders),
      'Dispatches': _totalFromPaginated(dispatches),
      'Receipts': _totalFromPaginated(receipts),
      'Charges': _totalFromPaginated(charges),
    },
  );
}

Future<ErpDashboardSnapshot> _loadServiceDashboard({
  ErpDashboardTrendFilter? trendFilter,
}) async {
  final service = ServiceModuleService();
  final responses = await Future.wait<dynamic>([
    service.tickets(filters: const {'per_page': 100}),
    service.workOrders(filters: const {'per_page': 100}),
    service.contracts(filters: const {'per_page': 100}),
    service.feedbacks(filters: const {'per_page': 100}),
  ]);

  final tickets = responses[0] as PaginatedResponse<ServiceTicketModel>;
  final workOrders = responses[1] as PaginatedResponse<ServiceWorkOrderModel>;
  final contracts = responses[2] as PaginatedResponse<ServiceContractModel>;
  final feedbacks = responses[3] as PaginatedResponse<ServiceFeedbackModel>;

  return _buildGenericLiveDashboard(
    title: 'Service Dashboard',
    subtitle:
        'Live service operations surfaced through the shared module dashboard component.',
    actions: const <ErpDashboardAction>[
      ErpDashboardAction(
        label: 'Open tickets',
        icon: Icons.support_outlined,
        route: '/service/tickets',
      ),
      ErpDashboardAction(
        label: 'Open work orders',
        icon: Icons.assignment_outlined,
        route: '/service/work-orders',
      ),
    ],
    statSpecs: <_DashboardStatSpec>[
      _DashboardStatSpec(
        'Tickets',
        _totalFromPaginated(tickets),
        Icons.support_outlined,
      ),
      _DashboardStatSpec(
        'Work Orders',
        _totalFromPaginated(workOrders),
        Icons.assignment_outlined,
        color: const Color(0xFF19A7B8),
      ),
      _DashboardStatSpec(
        'Contracts',
        _totalFromPaginated(contracts),
        Icons.description_outlined,
        color: const Color(0xFF1FA971),
      ),
      _DashboardStatSpec(
        'Feedbacks',
        _totalFromPaginated(feedbacks),
        Icons.feedback_outlined,
        color: const Color(0xFFE67E22),
      ),
    ],
    primarySection: ErpDashboardListSection(
      title: 'Service Queue',
      subtitle: 'Recent tickets and work orders from live service APIs.',
      icon: Icons.miscellaneous_services_outlined,
      items: <ErpDashboardListItem>[
        ...(tickets.data ?? const <ServiceTicketModel>[])
            .take(3)
            .map(
              (item) => _genericListItem(
                data: item.toJson(),
                fallbackTitle: 'Service Ticket',
                titleKeys: const ['ticket_no', 'reference_no'],
                subtitleKeys: const ['ticket_status', 'status'],
                routeBase: '/service/tickets',
              ),
            ),
        ...(workOrders.data ?? const <ServiceWorkOrderModel>[])
            .take(3)
            .map(
              (item) => _genericListItem(
                data: item.toJson(),
                fallbackTitle: 'Work Order',
                titleKeys: const ['work_order_no', 'reference_no'],
                subtitleKeys: const ['status', 'work_order_status'],
                routeBase: '/service/work-orders',
              ),
            ),
      ],
    ),
    trend: _buildMonthlyTrendCard(
      title: 'Service Trend',
      subtitle: 'Live monthly service activity.',
      trendFilter: trendFilter,
      sources: <_TrendSource>[
        _TrendSource(
          records: (tickets.data ?? const <ServiceTicketModel>[]).map(
            (item) => item.toJson(),
          ),
          dateKeys: const ['ticket_date', 'reported_date', 'created_at'],
        ),
        _TrendSource(
          records: (workOrders.data ?? const <ServiceWorkOrderModel>[]).map(
            (item) => item.toJson(),
          ),
          dateKeys: const ['work_order_date', 'created_at'],
        ),
        _TrendSource(
          records: (contracts.data ?? const <ServiceContractModel>[]).map(
            (item) => item.toJson(),
          ),
          dateKeys: const ['contract_date', 'start_date', 'created_at'],
        ),
        _TrendSource(
          records: (feedbacks.data ?? const <ServiceFeedbackModel>[]).map(
            (item) => item.toJson(),
          ),
          dateKeys: const ['feedback_date', 'created_at'],
        ),
      ],
    ),
    distributionCounts: <String, int>{
      'Tickets': _totalFromPaginated(tickets),
      'Work Orders': _totalFromPaginated(workOrders),
      'Contracts': _totalFromPaginated(contracts),
      'Feedbacks': _totalFromPaginated(feedbacks),
    },
  );
}

Future<ErpDashboardSnapshot> _loadProjectsDashboard({
  ErpDashboardTrendFilter? trendFilter,
}) async {
  final service = ProjectService();
  final projectsResponse = await service.projects(
    filters: const {'per_page': 100, 'sort_by': 'project_name'},
  );
  final projects = projectsResponse.data ?? const <ProjectModel>[];
  final tasks = projects
      .expand((project) => project.tasks)
      .toList(growable: false);
  final milestones = projects
      .expand((project) => project.milestones)
      .toList(growable: false);
  final activeProjects = projects
      .where(
        (project) =>
            _looksActive(project.toJson(), const ['project_status', 'status']),
      )
      .length;
  final dueMilestones = milestones
      .where((milestone) => _isToday(milestone.toJson(), const ['target_date']))
      .length;

  return ErpDashboardSnapshot(
    title: 'Projects Dashboard',
    subtitle:
        'Live projects, tasks, and milestones in the shared ERP dashboard experience.',
    actions: const <ErpDashboardAction>[
      ErpDashboardAction(
        label: 'Open projects',
        icon: Icons.folder_outlined,
        route: '/projects',
      ),
      ErpDashboardAction(
        label: 'Open tasks',
        icon: Icons.task_outlined,
        route: '/projects/tasks',
      ),
    ],
    stats: <ErpDashboardStat>[
      ErpDashboardStat(
        label: 'Projects',
        value: _formatInt(_totalFromPaginated(projectsResponse)),
        helper: 'Live project count',
        icon: Icons.folder_special_outlined,
      ),
      ErpDashboardStat(
        label: 'Active Projects',
        value: _formatInt(activeProjects),
        helper: 'Status-based active view',
        icon: Icons.play_circle_outline,
        color: const Color(0xFF1FA971),
      ),
      ErpDashboardStat(
        label: 'Tasks',
        value: _formatInt(tasks.length),
        helper: 'Nested project task records',
        icon: Icons.task_alt_outlined,
        color: const Color(0xFF19A7B8),
      ),
      ErpDashboardStat(
        label: 'Due Milestones',
        value: _formatInt(dueMilestones),
        helper: 'Milestones due today',
        icon: Icons.flag_outlined,
        color: const Color(0xFFE67E22),
      ),
    ],
    primarySections: <ErpDashboardListSection>[
      ErpDashboardListSection(
        title: 'Recent Project Tasks',
        subtitle:
            'Live project and task data from the current project service.',
        icon: Icons.calendar_today_outlined,
        items: tasks
            .take(6)
            .map((task) {
              return ErpDashboardListItem(
                title: task.taskName ?? task.taskCode ?? 'Task',
                subtitle: [
                  task.taskCode ?? '',
                  task.taskStatus ?? '',
                ].where((part) => part.trim().isNotEmpty).join(' • '),
                detail: task.plannedEndDate ?? task.plannedStartDate,
                statusLabel: (task.taskStatus ?? 'open').toUpperCase(),
                statusColor: appStatusColor(task.taskStatus),
                route: '/projects/tasks',
              );
            })
            .toList(growable: false),
      ),
    ],
    trend: _buildMonthlyTrendCard(
      title: 'Project Delivery Trend',
      subtitle: 'Live monthly project, task, and milestone activity.',
      color: const Color(0xFF8E5CFF),
      trendFilter: trendFilter,
      sources: <_TrendSource>[
        _TrendSource(
          records: projects.map((item) => item.toJson()),
          dateKeys: const ['project_date', 'start_date', 'created_at'],
        ),
        _TrendSource(
          records: tasks.map((item) => item.toJson()),
          dateKeys: const [
            'planned_start_date',
            'planned_end_date',
            'created_at',
          ],
        ),
        _TrendSource(
          records: milestones.map((item) => item.toJson()),
          dateKeys: const ['target_date', 'created_at'],
        ),
      ],
    ),
    distribution: ErpDashboardDistributionCardData(
      title: 'Project Distribution',
      subtitle: 'Live operational spread across project entities.',
      segments: _segmentsFromCounts(<String, int>{
        'Projects': projects.length,
        'Tasks': tasks.length,
        'Milestones': milestones.length,
        'Active': activeProjects,
      }),
    ),
    highlights: ErpDashboardHighlightsCardData(
      title: 'Project Signals',
      subtitle: 'High-level delivery indicators for the PMO.',
      entries: <ErpDashboardHighlightEntry>[
        ErpDashboardHighlightEntry(
          label: 'Milestones',
          value: _formatInt(milestones.length),
          helper: 'All tracked milestones',
        ),
        ErpDashboardHighlightEntry(
          label: 'Due today',
          value: _formatInt(dueMilestones),
          helper: 'Needs immediate review',
          color: const Color(0xFFE67E22),
        ),
      ],
    ),
  );
}

Future<ErpDashboardSnapshot> _loadMaintenanceDashboard({
  ErpDashboardTrendFilter? trendFilter,
}) async {
  final service = MaintenanceService();
  final responses = await Future.wait<dynamic>([
    service.requests(filters: const {'per_page': 100}),
    service.workOrders(filters: const {'per_page': 100}),
    service.plans(filters: const {'per_page': 100}),
    service.downtimeLogs(filters: const {'per_page': 100}),
  ]);

  final requests = responses[0] as PaginatedResponse<MaintenanceRequestModel>;
  final workOrders =
      responses[1] as PaginatedResponse<MaintenanceWorkOrderModel>;
  final plans = responses[2] as PaginatedResponse<MaintenancePlanModel>;
  final downtime = responses[3] as PaginatedResponse<AssetDowntimeLogModel>;

  return _buildGenericLiveDashboard(
    title: 'Maintenance Dashboard',
    subtitle:
        'Live requests, plans, and work orders using the reusable ERP dashboard component.',
    actions: const <ErpDashboardAction>[
      ErpDashboardAction(
        label: 'Open requests',
        icon: Icons.assignment_outlined,
        route: '/maintenance/requests',
      ),
      ErpDashboardAction(
        label: 'Open work orders',
        icon: Icons.work_history_outlined,
        route: '/maintenance/work-orders',
      ),
    ],
    statSpecs: <_DashboardStatSpec>[
      _DashboardStatSpec(
        'Requests',
        _totalFromPaginated(requests),
        Icons.assignment_outlined,
      ),
      _DashboardStatSpec(
        'Work Orders',
        _totalFromPaginated(workOrders),
        Icons.work_history_outlined,
        color: const Color(0xFF19A7B8),
      ),
      _DashboardStatSpec(
        'Plans',
        _totalFromPaginated(plans),
        Icons.event_repeat_outlined,
        color: const Color(0xFF1FA971),
      ),
      _DashboardStatSpec(
        'Downtime Logs',
        _totalFromPaginated(downtime),
        Icons.timer_off_outlined,
        color: const Color(0xFFE67E22),
      ),
    ],
    primarySection: ErpDashboardListSection(
      title: 'Maintenance Queue',
      subtitle: 'Recent live maintenance requests and work orders.',
      icon: Icons.build_circle_outlined,
      items: <ErpDashboardListItem>[
        ...(requests.data ?? const <MaintenanceRequestModel>[])
            .take(3)
            .map(
              (item) => _genericListItem(
                data: item.toJson(),
                fallbackTitle: 'Maintenance Request',
                titleKeys: const ['request_no', 'reference_no'],
                subtitleKeys: const ['status', 'request_status'],
                routeBase: '/maintenance/requests',
              ),
            ),
        ...(workOrders.data ?? const <MaintenanceWorkOrderModel>[])
            .take(3)
            .map(
              (item) => _genericListItem(
                data: item.toJson(),
                fallbackTitle: 'Maintenance Work Order',
                titleKeys: const ['work_order_no', 'reference_no'],
                subtitleKeys: const ['status', 'work_order_status'],
                routeBase: '/maintenance/work-orders',
              ),
            ),
      ],
    ),
    trend: _buildMonthlyTrendCard(
      title: 'Maintenance Trend',
      subtitle: 'Live monthly maintenance activity.',
      trendFilter: trendFilter,
      sources: <_TrendSource>[
        _TrendSource(
          records: (requests.data ?? const <MaintenanceRequestModel>[]).map(
            (item) => item.toJson(),
          ),
          dateKeys: const ['request_date', 'created_at', 'reported_date'],
        ),
        _TrendSource(
          records: (workOrders.data ?? const <MaintenanceWorkOrderModel>[]).map(
            (item) => item.toJson(),
          ),
          dateKeys: const ['work_order_date', 'created_at'],
        ),
        _TrendSource(
          records: (plans.data ?? const <MaintenancePlanModel>[]).map(
            (item) => item.toJson(),
          ),
          dateKeys: const ['plan_date', 'start_date', 'created_at'],
        ),
        _TrendSource(
          records: (downtime.data ?? const <AssetDowntimeLogModel>[]).map(
            (item) => item.toJson(),
          ),
          dateKeys: const ['downtime_start', 'log_date', 'created_at'],
        ),
      ],
    ),
    distributionCounts: <String, int>{
      'Requests': _totalFromPaginated(requests),
      'Work Orders': _totalFromPaginated(workOrders),
      'Plans': _totalFromPaginated(plans),
      'Downtime': _totalFromPaginated(downtime),
    },
  );
}

Future<ErpDashboardSnapshot> _loadHrDashboard({
  ErpDashboardTrendFilter? trendFilter,
}) async {
  final service = HrService();
  final responses = await Future.wait<dynamic>([
    service.employees(filters: const {'per_page': 100}),
    service.attendance(filters: const {'per_page': 100}),
    service.departments(filters: const {'per_page': 100}),
    service.designations(filters: const {'per_page': 100}),
  ]);

  final employees = responses[0] as PaginatedResponse<EmployeeModel>;
  final attendance = responses[1] as PaginatedResponse<AttendanceRecordModel>;
  final departments = responses[2] as PaginatedResponse<DepartmentModel>;
  final designations = responses[3] as PaginatedResponse<DesignationModel>;

  return _buildGenericLiveDashboard(
    title: 'HR Dashboard',
    subtitle:
        'Live people operations in the same ERP dashboard design language.',
    actions: const <ErpDashboardAction>[
      ErpDashboardAction(
        label: 'Open employees',
        icon: Icons.groups_2_outlined,
        route: '/hr/employees',
      ),
      ErpDashboardAction(
        label: 'Open attendance',
        icon: Icons.fact_check_outlined,
        route: '/hr/attendance',
      ),
    ],
    statSpecs: <_DashboardStatSpec>[
      _DashboardStatSpec(
        'Employees',
        _totalFromPaginated(employees),
        Icons.groups_2_outlined,
      ),
      _DashboardStatSpec(
        'Attendance',
        _totalFromPaginated(attendance),
        Icons.fact_check_outlined,
        color: const Color(0xFF19A7B8),
      ),
      _DashboardStatSpec(
        'Departments',
        _totalFromPaginated(departments),
        Icons.apartment_outlined,
        color: const Color(0xFF1FA971),
      ),
      _DashboardStatSpec(
        'Designations',
        _totalFromPaginated(designations),
        Icons.workspace_premium_outlined,
        color: const Color(0xFFE67E22),
      ),
    ],
    primarySection: ErpDashboardListSection(
      title: 'HR Activity',
      subtitle: 'Recent employee and attendance records from live HR APIs.',
      icon: Icons.badge_outlined,
      items: <ErpDashboardListItem>[
        ...(employees.data ?? const <EmployeeModel>[])
            .take(3)
            .map(
              (item) => _genericListItem(
                data: item.toJson(),
                fallbackTitle: 'Employee',
                titleKeys: const [
                  'employee_name',
                  'employee_code',
                  'full_name',
                ],
                subtitleKeys: const ['designation_name', 'department_name'],
                routeBase: '/hr/employees',
              ),
            ),
        ...(attendance.data ?? const <AttendanceRecordModel>[])
            .take(3)
            .map(
              (item) => _genericListItem(
                data: item.toJson(),
                fallbackTitle: 'Attendance Record',
                titleKeys: const ['employee_name', 'attendance_no'],
                subtitleKeys: const ['attendance_status', 'status'],
                routeBase: '/hr/attendance',
              ),
            ),
      ],
    ),
    trend: _buildMonthlyTrendCard(
      title: 'HR Trend',
      subtitle: 'Live monthly HR activity.',
      trendFilter: trendFilter,
      sources: <_TrendSource>[
        _TrendSource(
          records: (employees.data ?? const <EmployeeModel>[]).map(
            (item) => item.toJson(),
          ),
          dateKeys: const ['joining_date', 'date_of_joining', 'created_at'],
        ),
        _TrendSource(
          records: (attendance.data ?? const <AttendanceRecordModel>[]).map(
            (item) => item.toJson(),
          ),
          dateKeys: const ['attendance_date', 'date', 'created_at'],
        ),
        _TrendSource(
          records: (departments.data ?? const <DepartmentModel>[]).map(
            (item) => item.toJson(),
          ),
          dateKeys: const ['created_at'],
        ),
        _TrendSource(
          records: (designations.data ?? const <DesignationModel>[]).map(
            (item) => item.toJson(),
          ),
          dateKeys: const ['created_at'],
        ),
      ],
    ),
    distributionCounts: <String, int>{
      'Employees': _totalFromPaginated(employees),
      'Attendance': _totalFromPaginated(attendance),
      'Departments': _totalFromPaginated(departments),
      'Designations': _totalFromPaginated(designations),
    },
  );
}

Future<ErpDashboardSnapshot> _loadPartiesDashboard({
  ErpDashboardTrendFilter? trendFilter,
}) async {
  final service = PartiesService();
  final responses = await Future.wait<dynamic>([
    service.parties(filters: const {'per_page': 100}),
    service.partyTypes(filters: const {'per_page': 100}),
  ]);

  final parties = responses[0] as PaginatedResponse<PartyModel>;
  final types = responses[1] as PaginatedResponse<PartyTypeModel>;
  final partyRows = parties.data ?? const <PartyModel>[];
  final activeParties = partyRows
      .where(
        (item) => _looksActive(item.toJson(), const ['is_active', 'status']),
      )
      .length;

  return ErpDashboardSnapshot(
    title: 'Parties Dashboard',
    subtitle:
        'Live customer, supplier, and master-party visibility in the shared dashboard design.',
    actions: const <ErpDashboardAction>[
      ErpDashboardAction(
        label: 'Open parties',
        icon: Icons.handshake_outlined,
        route: '/parties',
      ),
      ErpDashboardAction(
        label: 'Party accounts',
        icon: Icons.link_outlined,
        route: '/parties/accounts',
      ),
    ],
    stats: <ErpDashboardStat>[
      ErpDashboardStat(
        label: 'Total Parties',
        value: _formatInt(_totalFromPaginated(parties)),
        helper: 'Live party master count',
        icon: Icons.business_outlined,
      ),
      ErpDashboardStat(
        label: 'Active Parties',
        value: _formatInt(activeParties),
        helper: 'From current list snapshot',
        icon: Icons.check_circle_outline,
        color: const Color(0xFF1FA971),
      ),
      ErpDashboardStat(
        label: 'Party Types',
        value: _formatInt(_totalFromPaginated(types)),
        helper: 'Configured relationship types',
        icon: Icons.category_outlined,
        color: const Color(0xFF19A7B8),
      ),
      ErpDashboardStat(
        label: 'Inactive Parties',
        value: _formatInt(
          partyRows.length > activeParties
              ? partyRows.length - activeParties
              : 0,
        ),
        helper: 'Derived from the current live party list',
        icon: Icons.person_off_outlined,
        color: const Color(0xFFE67E22),
      ),
    ],
    primarySections: <ErpDashboardListSection>[
      ErpDashboardListSection(
        title: 'Recent Parties',
        subtitle: 'Latest live party records from the master API.',
        icon: Icons.people_alt_outlined,
        items: partyRows
            .take(6)
            .map(
              (item) => ErpDashboardListItem(
                title: item.toString(),
                subtitle: [
                  stringValue(item.toJson(), 'party_code'),
                  stringValue(item.toJson(), 'party_type_name'),
                ].where((part) => part.trim().isNotEmpty).join(' • '),
                detail: nullableStringValue(item.toJson(), 'mobile'),
                statusLabel:
                    _looksActive(item.toJson(), const ['is_active', 'status'])
                    ? 'ACTIVE'
                    : 'INACTIVE',
                statusColor: appStatusColor(
                  _looksActive(item.toJson(), const ['is_active', 'status'])
                      ? 'active'
                      : 'inactive',
                ),
                route: '/parties',
              ),
            )
            .toList(growable: false),
      ),
    ],
    trend: _buildMonthlyTrendCard(
      title: 'Relationship Growth',
      subtitle: 'Live monthly party master activity.',
      color: const Color(0xFF8E5CFF),
      trendFilter: trendFilter,
      sources: <_TrendSource>[
        _TrendSource(
          records: partyRows.map((item) => item.toJson()),
          dateKeys: const ['created_at', 'party_date', 'registered_on'],
        ),
      ],
    ),
    distribution: ErpDashboardDistributionCardData(
      title: 'Party Distribution',
      subtitle: 'Live split between active parties and configured types.',
      segments: _segmentsFromCounts(<String, int>{
        'Active': activeParties,
        'Inactive': partyRows.length > activeParties
            ? partyRows.length - activeParties
            : 0,
        'Party types': _totalFromPaginated(types),
      }),
    ),
  );
}

ErpDashboardSnapshot _buildGenericLiveDashboard({
  required String title,
  required String subtitle,
  required List<ErpDashboardAction> actions,
  required List<_DashboardStatSpec> statSpecs,
  required ErpDashboardListSection primarySection,
  ErpDashboardTrendCardData? trend,
  required Map<String, int> distributionCounts,
}) {
  return ErpDashboardSnapshot(
    title: title,
    subtitle: subtitle,
    actions: actions,
    stats: statSpecs
        .map(
          (spec) => ErpDashboardStat(
            label: spec.label,
            value: _formatInt(spec.value),
            helper: 'Live module record count',
            icon: spec.icon,
            color: spec.color,
          ),
        )
        .toList(growable: false),
    primarySections: <ErpDashboardListSection>[primarySection],
    trend: trend,
    distribution: ErpDashboardDistributionCardData(
      title: 'Operational Distribution',
      subtitle: 'Live split across this module’s core record groups.',
      segments: _segmentsFromCounts(distributionCounts),
    ),
  );
}

class _DashboardStatSpec {
  const _DashboardStatSpec(
    this.label,
    this.value,
    this.icon, {
    this.color = const Color(0xFF2F6FED),
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
}

class _TrendSource {
  const _TrendSource({
    required this.records,
    required this.dateKeys,
    this.amountKey,
  });

  final Iterable<Map<String, dynamic>> records;
  final List<String> dateKeys;

  /// If set, the trend will sum this field's numeric value instead of counting records.
  final String? amountKey;
}

ErpDashboardListItem _genericListItem({
  required Map<String, dynamic> data,
  required String fallbackTitle,
  required List<String> titleKeys,
  required List<String> subtitleKeys,
  required String routeBase,
}) {
  final subtitle = subtitleKeys
      .map((key) => stringValue(data, key))
      .where((value) => value.trim().isNotEmpty)
      .join(' • ');
  return ErpDashboardListItem(
    title: _firstString(data, titleKeys, fallback: fallbackTitle),
    subtitle: subtitle.isEmpty ? 'Live module record' : subtitle,
    detail:
        nullableStringValue(data, 'remarks') ??
        nullableStringValue(data, 'notes'),
    statusLabel: _statusLabel(data, const ['status']),
    route: _recordRoute(routeBase, data),
  );
}

List<ErpDashboardDistributionSegment> _segmentsFromCounts(
  Map<String, int> counts,
) {
  final entries = counts.entries
      .where((entry) => entry.value > 0)
      .toList(growable: false);
  if (entries.isEmpty) {
    return const <ErpDashboardDistributionSegment>[];
  }
  return List<ErpDashboardDistributionSegment>.generate(entries.length, (
    index,
  ) {
    final entry = entries[index];
    return ErpDashboardDistributionSegment(
      label: entry.key,
      value: entry.value.toDouble(),
      color: _dashboardPalette[index % _dashboardPalette.length],
    );
  }, growable: false);
}

ErpDashboardTrendCardData _buildMonthlyTrendCard({
  required String title,
  required String subtitle,
  required List<_TrendSource> sources,
  ErpDashboardTrendFilter? trendFilter,
  String emptyMessage = 'No real trend data is available yet for this module.',
  Color color = const Color(0xFF2F6FED),
  bool isCurrency = false,
}) {
  return ErpDashboardTrendCardData(
    title: title,
    subtitle: subtitle,
    points: _trendPointsFromSources(sources, trendFilter: trendFilter),
    emptyMessage: emptyMessage,
    color: color,
    isCurrency: isCurrency,
  );
}

List<ErpDashboardTrendPoint> _trendPointsFromSources(
  List<_TrendSource> sources, {
  ErpDashboardTrendFilter? trendFilter,
}) {
  final activeFilter =
      trendFilter ??
      const ErpDashboardTrendFilter(preset: ErpDashboardTrendPreset.monthly);
  final buckets = _buildTrendBuckets(activeFilter);
  if (buckets.isEmpty) {
    return const <ErpDashboardTrendPoint>[];
  }
  final totals = List<double>.filled(buckets.length, 0);
  final rangeStart = buckets.first.start;
  final rangeEnd = buckets.last.endExclusive;

  for (final source in sources) {
    for (final record in source.records) {
      final parsed = _firstMatchingDate(record, source.dateKeys);
      if (parsed == null) {
        continue;
      }
      if (parsed.isBefore(rangeStart) || !parsed.isBefore(rangeEnd)) {
        continue;
      }
      for (var index = 0; index < buckets.length; index++) {
        final bucket = buckets[index];
        if (!parsed.isBefore(bucket.start) &&
            parsed.isBefore(bucket.endExclusive)) {
          final amountKey = source.amountKey;
          if (amountKey != null) {
            final rawAmount = record[amountKey];
            final amount = rawAmount is num
                ? rawAmount.toDouble()
                : double.tryParse(rawAmount?.toString() ?? '') ?? 0;
            totals[index] += amount;
          } else {
            totals[index] += 1;
          }
          break;
        }
      }
    }
  }

  return List<ErpDashboardTrendPoint>.generate(buckets.length, (index) {
    return ErpDashboardTrendPoint(
      label: buckets[index].label,
      value: totals[index],
    );
  }, growable: false);
}

class _TrendBucket {
  const _TrendBucket({
    required this.label,
    required this.start,
    required this.endExclusive,
  });

  final String label;
  final DateTime start;
  final DateTime endExclusive;
}

List<_TrendBucket> _buildTrendBuckets(ErpDashboardTrendFilter filter) {
  switch (filter.preset) {
    case ErpDashboardTrendPreset.monthly:
      return _monthlyTrendBuckets(6);
    case ErpDashboardTrendPreset.weekly:
      return _weeklyTrendBuckets(8);
    case ErpDashboardTrendPreset.yearly:
      return _yearlyTrendBuckets(5);
    case ErpDashboardTrendPreset.custom:
      final range = filter.customRange;
      if (range == null || range.end.isBefore(range.start)) {
        return const <_TrendBucket>[];
      }
      return _customTrendBuckets(range);
  }
}

List<_TrendBucket> _monthlyTrendBuckets(int months) {
  final now = DateTime.now();
  return List<_TrendBucket>.generate(months, (index) {
    final offset = months - index - 1;
    final start = DateTime(now.year, now.month - offset, 1);
    final end = DateTime(start.year, start.month + 1, 1);
    return _TrendBucket(
      label: _monthLabel(start),
      start: start,
      endExclusive: end,
    );
  }, growable: false);
}

List<_TrendBucket> _weeklyTrendBuckets(int weeks) {
  final now = DateTime.now();
  final thisWeekStart = _weekStart(now);
  return List<_TrendBucket>.generate(weeks, (index) {
    final offset = weeks - index - 1;
    final start = thisWeekStart.subtract(Duration(days: offset * 7));
    final end = start.add(const Duration(days: 7));
    return _TrendBucket(
      label: 'W${_weekOfYear(start)}',
      start: start,
      endExclusive: end,
    );
  }, growable: false);
}

List<_TrendBucket> _yearlyTrendBuckets(int years) {
  final now = DateTime.now();
  return List<_TrendBucket>.generate(years, (index) {
    final year = now.year - (years - index - 1);
    final start = DateTime(year, 1, 1);
    final end = DateTime(year + 1, 1, 1);
    return _TrendBucket(
      label: year.toString(),
      start: start,
      endExclusive: end,
    );
  }, growable: false);
}

List<_TrendBucket> _customTrendBuckets(ErpDashboardGraphRange range) {
  final normalizedStart = DateTime(
    range.start.year,
    range.start.month,
    range.start.day,
  );
  final normalizedEndExclusive = DateTime(
    range.end.year,
    range.end.month,
    range.end.day + 1,
  );
  final daySpan = normalizedEndExclusive.difference(normalizedStart).inDays;

  if (daySpan <= 31) {
    final buckets = <_TrendBucket>[];
    var cursor = normalizedStart;
    while (cursor.isBefore(normalizedEndExclusive)) {
      final end = cursor.add(const Duration(days: 1));
      buckets.add(
        _TrendBucket(
          label: _dayMonthLabel(cursor),
          start: cursor,
          endExclusive: end,
        ),
      );
      cursor = end;
    }
    return buckets;
  }

  if (daySpan <= 180) {
    final buckets = <_TrendBucket>[];
    var cursor = _weekStart(normalizedStart);
    while (cursor.isBefore(normalizedEndExclusive)) {
      final end = cursor.add(const Duration(days: 7));
      buckets.add(
        _TrendBucket(
          label: 'W${_weekOfYear(cursor)}',
          start: cursor,
          endExclusive: end,
        ),
      );
      cursor = end;
    }
    return buckets;
  }

  if (daySpan <= 730) {
    final buckets = <_TrendBucket>[];
    var cursor = DateTime(normalizedStart.year, normalizedStart.month, 1);
    while (cursor.isBefore(normalizedEndExclusive)) {
      final end = DateTime(cursor.year, cursor.month + 1, 1);
      buckets.add(
        _TrendBucket(
          label: _monthLabel(cursor),
          start: cursor,
          endExclusive: end,
        ),
      );
      cursor = end;
    }
    return buckets;
  }

  final buckets = <_TrendBucket>[];
  var cursor = DateTime(normalizedStart.year, 1, 1);
  final limit = DateTime(normalizedEndExclusive.year, 1, 1);
  while (!cursor.isAfter(limit)) {
    final end = DateTime(cursor.year + 1, 1, 1);
    buckets.add(
      _TrendBucket(
        label: cursor.year.toString(),
        start: cursor,
        endExclusive: end,
      ),
    );
    cursor = end;
  }
  return buckets;
}

DateTime? _firstMatchingDate(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final raw = nullableStringValue(data, key);
    if (raw == null || raw.trim().isEmpty) {
      continue;
    }
    final parsed = DateTime.tryParse(raw.trim());
    if (parsed != null) {
      return parsed;
    }
  }
  return null;
}

String _monthLabel(DateTime date) {
  const monthNames = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return monthNames[date.month - 1];
}

String _dayMonthLabel(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')} ${_monthLabel(date)}';
}

DateTime _weekStart(DateTime value) {
  final normalized = DateTime(value.year, value.month, value.day);
  return normalized.subtract(Duration(days: normalized.weekday - 1));
}

int _weekOfYear(DateTime value) {
  final startOfYear = DateTime(value.year, 1, 1);
  final firstWeekStart = _weekStart(startOfYear);
  return ((value.difference(firstWeekStart).inDays) ~/ 7) + 1;
}

int _totalFromPaginated(PaginatedResponse<dynamic> response) {
  return response.meta?.total ?? response.data?.length ?? 0;
}

String _recordRoute(String baseRoute, Map<String, dynamic> data) {
  final id = intValue(data, 'id');
  if (id == null) {
    return baseRoute;
  }
  return '$baseRoute/$id';
}

Future<PaginatedResponse<T>> _safePaginated<T>(
  Future<PaginatedResponse<T>> Function() loader,
) async {
  try {
    return await loader();
  } catch (_) {
    return PaginatedResponse<T>(
      success: false,
      message: '',
      data: <T>[],
      meta: const PaginationMeta(
        currentPage: 1,
        lastPage: 1,
        perPage: 0,
        total: 0,
      ),
    );
  }
}

Future<ApiResponse<List<T>>> _safeCollection<T>(
  Future<ApiResponse<List<T>>> Function() loader,
) async {
  try {
    return await loader();
  } catch (_) {
    return ApiResponse<List<T>>(success: false, message: '', data: <T>[]);
  }
}

Map<String, dynamic> _safeMap(Map<String, dynamic> Function() builder) {
  try {
    return builder();
  } catch (_) {
    return <String, dynamic>{};
  }
}

String _statusLabel(Map<String, dynamic> data, List<String> keys) {
  final value = _firstString(data, keys, fallback: 'Open').trim();
  if (value.isEmpty) {
    return 'Open';
  }
  if (value.toLowerCase() == 'posted') {
    return 'Finished';
  }
  return value.replaceAll('_', ' ').titleCase;
}

String _supplierName(Map<String, dynamic> data) {
  final supplier = data['supplier'];
  if (supplier is Map) {
    return stringValue(Map<String, dynamic>.from(supplier), 'party_name');
  }
  return _firstString(data, const ['supplier_name', 'vendor_name']);
}

String _customerName(Map<String, dynamic> data) {
  final customer = data['customer'];
  if (customer is Map) {
    return stringValue(Map<String, dynamic>.from(customer), 'party_name');
  }
  return stringValue(data, 'customer_name');
}

String _firstString(
  Map<String, dynamic> data,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final value = stringValue(data, key).trim();
    if (value.isNotEmpty) {
      return value;
    }
  }
  return fallback;
}

bool _looksActive(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final raw = data[key];
    if (raw is bool) {
      return raw;
    }
    if (raw is num) {
      return raw != 0;
    }
    final value = stringValue(data, key).trim().toLowerCase();
    if (value.isEmpty) {
      continue;
    }
    if (const <String>{
      'active',
      'open',
      'working',
      'approved',
      'released',
    }.contains(value)) {
      return true;
    }
    if (const <String>{
      'inactive',
      'closed',
      'cancelled',
      'obsolete',
    }.contains(value)) {
      return false;
    }
  }
  return false;
}

bool _isClosedStatus(Map<String, dynamic> data, List<String> keys) {
  final value = _firstString(data, keys).toLowerCase();
  if (value.isEmpty) {
    return false;
  }
  return const <String>{
    'closed',
    'cancelled',
    'completed',
    'fully_invoiced',
    'fully_delivered',
    'posted',
    'reconciled',
    'inactive',
  }.contains(value);
}

bool _statusIndicatesClosed(String status) {
  return const <String>{
    'closed',
    'cancelled',
    'completed',
    'fully_invoiced',
    'fully_delivered',
    'posted',
    'reconciled',
    'inactive',
  }.contains(status);
}

bool _statusIndicatesDelivered(String status) {
  return status.contains('delivered') ||
      status.contains('received') ||
      status.contains('completed') ||
      status.contains('posted');
}

bool _statusIndicatesCancelled(String status) {
  return status.contains('cancelled') || status.contains('void');
}

bool _isOverdue(Map<String, dynamic> data, List<String> keys) {
  final parsed = _firstMatchingDate(data, keys);
  if (parsed == null) {
    return false;
  }
  final today = DateTime.now();
  final normalizedToday = DateTime(today.year, today.month, today.day);
  final normalizedParsed = DateTime(parsed.year, parsed.month, parsed.day);
  return normalizedParsed.isBefore(normalizedToday);
}

bool _isInCurrentMonth(Map<String, dynamic> data, List<String> keys) {
  final parsed = _firstMatchingDate(data, keys);
  if (parsed == null) {
    return false;
  }
  final now = DateTime.now();
  return parsed.year == now.year && parsed.month == now.month;
}

String _formatCurrency(double? value) {
  if (value == null || value == 0) {
    return '';
  }
  return _crmFormatExpectedValue(value);
}

String _formatQuantity(double value) {
  return formatAmount(value);
}

String _buildSuggestedReorderDetail(StockBalanceModel item) {
  final current = item.qtyAvailable ?? item.qtyOnHand ?? 0.0;
  final reorder =
      double.tryParse(stringValue(item.toJson(), 'reorder_level', '0')) ?? 0.0;
  final suggested = reorder > current ? reorder - current : 0.0;
  if (suggested > 0) {
    return 'Suggested qty ${_formatQuantity(suggested)}';
  }
  return 'Review replenishment immediately';
}

String _invoicePaymentStatus(PurchaseInvoiceModel item) {
  final dueDate = DateTime.tryParse(item.dueDate ?? '');
  if (dueDate == null) {
    return 'OPEN';
  }
  final today = DateTime.now();
  final normalizedToday = DateTime(today.year, today.month, today.day);
  final normalizedDue = DateTime(dueDate.year, dueDate.month, dueDate.day);
  if (normalizedDue.isBefore(normalizedToday)) {
    return 'OVERDUE';
  }
  if (normalizedDue.difference(normalizedToday).inDays <= 3) {
    return 'DUE SOON';
  }
  return 'OPEN';
}

Color _invoicePaymentStatusColor(PurchaseInvoiceModel item) {
  switch (_invoicePaymentStatus(item)) {
    case 'OVERDUE':
      return const Color(0xFFDA4D78);
    case 'DUE SOON':
      return const Color(0xFFE67E22);
    default:
      return const Color(0xFF19A7B8);
  }
}

bool _statusContains(
  Map<String, dynamic> data,
  List<String> keys,
  List<String> values,
) {
  final current = _firstString(data, keys).toLowerCase();
  if (current.isEmpty) {
    return false;
  }
  return values.any(current.contains);
}

bool _isToday(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final raw = nullableStringValue(data, key);
    if (raw == null || raw.trim().isEmpty) {
      continue;
    }
    final parsed = DateTime.tryParse(raw.trim());
    if (parsed == null) {
      continue;
    }
    final today = DateTime.now();
    if (parsed.year == today.year &&
        parsed.month == today.month &&
        parsed.day == today.day) {
      return true;
    }
  }
  return false;
}

bool _isLowStockBalance(StockBalanceModel item) {
  final data = item.toJson();
  final qty = double.tryParse(
    stringValue(data, 'available_qty', stringValue(data, 'qty_on_hand', '0')),
  );
  final reorder = double.tryParse(stringValue(data, 'reorder_level', '0'));
  if (qty == null) {
    return false;
  }
  if (reorder != null && reorder > 0) {
    return qty <= reorder;
  }
  return qty <= 0;
}

String _formatInt(int value) => value.toString();

bool _crmHasValue(double? value) => value != null && value != 0;

String _crmFormatExpectedValue(double value) {
  final formatted = formatAmount(value.abs());
  return value < 0 ? 'Rs ($formatted)' : 'Rs $formatted';
}
