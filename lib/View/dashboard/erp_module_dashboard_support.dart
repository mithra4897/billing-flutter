import '../../Model/sales/sales_order_model.dart';
import '../../Model/sales/sales_quotation_model.dart';
import '../../Model/sales/sales_receipt_model.dart';
import '../../screen.dart';
import '../purchase/purchase_support.dart';
import 'crm_dashboard_support.dart';

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

Future<ErpDashboardSnapshot> buildCrmDashboardSnapshot({
  required CrmService crmService,
  required DateTime Function() now,
  ErpDashboardTrendFilter? trendFilter,
}) async {
  final activeFilter =
      trendFilter ??
      const ErpDashboardTrendFilter(preset: ErpDashboardTrendPreset.monthly);
  final currentDate = now();
  final pendingLeadResponses = await Future.wait(<Future<PaginatedResponse<CrmLeadModel>>>[
    crmService.leads(
      filters: const <String, dynamic>{'per_page': 1, 'lead_status': 'new'},
    ),
    crmService.leads(
      filters: const <String, dynamic>{
        'per_page': 1,
        'lead_status': 'contacted',
      },
    ),
    crmService.leads(
      filters: const <String, dynamic>{
        'per_page': 1,
        'lead_status': 'qualified',
      },
    ),
  ]);
  final pendingLeadCount = pendingLeadResponses.fold<int>(
    0,
    (sum, response) => sum + (response.meta?.total ?? response.data?.length ?? 0),
  );
  final enquiryResponse = await crmService.enquiries(
    filters: const <String, dynamic>{'per_page': 1},
  );
  final pendingFollowupResponse = await crmService.pendingFollowups();
  final followupItems = (pendingFollowupResponse.data ??
          const <CrmFollowupModel>[])
      .map((item) => CrmPendingFollowupItem.fromJson(item.toJson()))
      .where(
        (item) => _crmMatchesTrendFilter(
          item,
          activeFilter,
          today: currentDate,
        ),
      )
      .toList(growable: false);
  final completedCount = followupItems
      .where((item) => crmIsCompletedFollowupStatus(item.status))
      .length;

  final pendingItems = sortCrmPendingFollowups(
    followupItems.where((item) => !crmIsCompletedFollowupStatus(item.status)),
    today: currentDate,
  );

  final todayCount = pendingItems
      .where(
        (item) =>
            crmFollowupBucket(item, today: currentDate) ==
            CrmFollowupTimingBucket.today,
      )
      .length;
  final overdueCount = pendingItems
      .where(
        (item) =>
            crmFollowupBucket(item, today: currentDate) ==
            CrmFollowupTimingBucket.overdue,
      )
      .length;
  final upcomingCount = pendingItems
      .where(
        (item) =>
            crmFollowupBucket(item, today: currentDate) ==
            CrmFollowupTimingBucket.upcoming,
      )
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
        route: '/crm/enquiries',
      ),
    ],
    stats: <ErpDashboardStat>[
      ErpDashboardStat(
        label: 'Total Pending Leads',
        value: _formatInt(pendingLeadCount),
        helper: 'Open CRM leads in new, contacted, and qualified stages',
        icon: Icons.groups_2_outlined,
        color: const Color(0xFF2F6FED),
        route: '/crm/leads',
      ),
      ErpDashboardStat(
        label: 'Total Enquiries',
        value: _formatInt(
          enquiryResponse.meta?.total ?? enquiryResponse.data?.length ?? 0,
        ),
        helper: 'Tracked across the sales pipeline',
        icon: Icons.mark_email_unread_outlined,
        color: const Color(0xFF19A7B8),
        route: '/crm/enquiries',
      ),
      ErpDashboardStat(
        label: 'Due Today',
        value: _formatInt(todayCount),
        helper: 'Follow-ups scheduled for today',
        icon: Icons.today_outlined,
        color: const Color(0xFFE67E22),
        route: '/crm/enquiries',
      ),
      ErpDashboardStat(
        label: 'Open Follow-ups',
        value: _formatInt(pendingItems.length),
        helper: 'Pending calls, emails, and next steps',
        icon: Icons.assignment_late_outlined,
        color: const Color(0xFFDA4D78),
        route: '/crm/enquiries',
      ),
    ],
    primarySections: <ErpDashboardListSection>[
      ErpDashboardListSection(
        title: 'Pending Follow-ups',
        subtitle: 'Prioritized from live CRM follow-up records.',
        icon: Icons.task_alt_outlined,
        items: pendingItems
            .take(6)
            .map(
              (item) => ErpDashboardListItem(
                title: item.subjectName,
                subtitle: [
                  crmPriorityLabel(item.priority),
                  item.followupDateLabel.isEmpty
                      ? 'No follow-up date'
                      : item.followupDateLabel,
                ].join(' • '),
                detail: item.summary ?? item.assignedUserName,
                statusLabel: item.status.toUpperCase(),
                statusColor: crmPriorityColor(item.priority),
                route: item.enquiryId == null
                    ? '/crm/enquiries'
                    : '/crm/enquiries?select_id=${item.enquiryId}',
              ),
            )
            .toList(growable: false),
        emptyTitle: 'No pending CRM follow-ups',
        emptyMessage:
            'The follow-up board will populate when pending CRM tasks exist.',
      ),
    ],
    trend: ErpDashboardTrendCardData(
      title: 'Follow-up Status',
      subtitle:
          'Completed and not completed follow-ups for ${_crmFilterLabel(activeFilter, currentDate)}.',
      points: <ErpDashboardTrendPoint>[
        ErpDashboardTrendPoint(
          label: 'Completed',
          value: completedCount.toDouble(),
          color: const Color(0xFF1FA971),
        ),
        ErpDashboardTrendPoint(
          label: 'Not Completed',
          value: pendingItems.length.toDouble(),
          color: const Color(0xFFD84C4C),
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
        ),
        ErpDashboardHighlightEntry(
          label: 'Overdue',
          value: _formatInt(overdueCount),
          helper: 'Past target follow-ups',
          color: const Color(0xFFDA4D78),
        ),
        ErpDashboardHighlightEntry(
          label: 'Upcoming',
          value: _formatInt(upcomingCount),
          helper: 'Planned next actions',
          color: const Color(0xFF2F6FED),
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

String _crmFilterLabel(
  ErpDashboardTrendFilter filter,
  DateTime today,
) {
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
      subtitle: 'Live monthly voucher activity from accounting records.',
      trendFilter: trendFilter,
      sources: <_TrendSource>[
        _TrendSource(
          records: voucherRows.map((item) => item.toJson()),
          dateKeys: const ['voucher_date', 'posting_date', 'created_at'],
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
      _safePaginated(
        () => service.orders(
          filters: const {'per_page': 100, 'sort_by': 'order_date'},
        ),
      ),
      _safePaginated(
        () => service.invoices(
          filters: const {'per_page': 100, 'sort_by': 'invoice_date'},
        ),
      ),
      _safePaginated(
        () => service.receipts(
          filters: const {'per_page': 100, 'sort_by': 'receipt_date'},
        ),
      ),
      _safePaginated(
        () => service.quotations(
          filters: const {'per_page': 100, 'sort_by': 'quotation_date'},
        ),
      ),
    ]);

    final orders = responses[0] as PaginatedResponse<SalesOrderModel>;
    final invoices = responses[1] as PaginatedResponse<SalesInvoiceModel>;
    final receipts = responses[2] as PaginatedResponse<SalesReceiptModel>;
    final quotations = responses[3] as PaginatedResponse<SalesQuotationModel>;

    final orderRows = orders.data ?? const <SalesOrderModel>[];
    final orderJsonRows = orderRows
        .map((item) => _safeMap(item.toJson))
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    final invoiceJsonRows = (invoices.data ?? const <SalesInvoiceModel>[])
        .map((item) => _safeMap(() => _salesInvoiceJson(item)))
        .toList(growable: false);
    final receiptJsonRows = (receipts.data ?? const <SalesReceiptModel>[])
        .map((item) => _safeMap(item.toJson))
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    final quotationJsonRows = (quotations.data ?? const <SalesQuotationModel>[])
        .map((item) => _safeMap(item.toJson))
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    final pendingOrders = orderJsonRows
        .where(
          (item) => !_isClosedStatus(item, const ['order_status', 'status']),
        )
        .length;
    final dueToday = orderJsonRows
        .where((item) => _isToday(item, const ['order_date', 'delivery_date']))
        .length;
    final openFollowUps = quotationJsonRows
        .where(
          (item) =>
              !_isClosedStatus(item, const ['quotation_status', 'status']),
        )
        .length;

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
          label: 'Total Orders',
          value: _formatInt(_totalFromPaginated(orders)),
          helper: 'Live order volume',
          icon: Icons.shopping_bag_outlined,
        ),
        ErpDashboardStat(
          label: 'Pending Orders',
          value: _formatInt(pendingOrders),
          helper: 'Status-driven live count',
          icon: Icons.pending_actions_outlined,
          color: const Color(0xFFE67E22),
        ),
        ErpDashboardStat(
          label: 'Due Today',
          value: _formatInt(dueToday),
          helper: 'Document dates falling today',
          icon: Icons.today_outlined,
          color: const Color(0xFFDA4D78),
        ),
        ErpDashboardStat(
          label: 'Open Follow-ups',
          value: _formatInt(openFollowUps),
          helper: 'Open quotations used as pipeline proxy',
          icon: Icons.forum_outlined,
          color: const Color(0xFF19A7B8),
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
                    title: stringValue(order, 'order_no', 'Sales order'),
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
                title: stringValue(json, 'invoice_no', 'Sales invoice'),
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
        title: 'Monthly Sales Trend',
        subtitle:
            'Live monthly sales activity from quotations, orders, invoices, and receipts.',
        trendFilter: trendFilter,
        sources: <_TrendSource>[
          _TrendSource(
            records: orderJsonRows,
            dateKeys: const ['order_date', 'delivery_date', 'created_at'],
          ),
          _TrendSource(
            records: invoiceJsonRows,
            dateKeys: const ['invoice_date', 'due_date', 'created_at'],
          ),
          _TrendSource(
            records: receiptJsonRows,
            dateKeys: const ['receipt_date', 'created_at'],
          ),
          _TrendSource(
            records: quotationJsonRows,
            dateKeys: const ['quotation_date', 'valid_until', 'created_at'],
          ),
        ],
      ),
      distribution: ErpDashboardDistributionCardData(
        title: 'Sales Distribution',
        subtitle: 'Live split across current order, invoice, and receipt load.',
        segments: _segmentsFromCounts(<String, int>{
          'Orders': _totalFromPaginated(orders),
          'Invoices': _totalFromPaginated(invoices),
          'Receipts': _totalFromPaginated(receipts),
          'Quotations': _totalFromPaginated(quotations),
        }),
      ),
      highlights: ErpDashboardHighlightsCardData(
        title: 'Sales Focus',
        subtitle: 'Key operational pressure points for the sales desk.',
        entries: <ErpDashboardHighlightEntry>[
          ErpDashboardHighlightEntry(
            label: 'Invoices',
            value: _formatInt(_totalFromPaginated(invoices)),
            helper: 'Live billing documents',
          ),
          ErpDashboardHighlightEntry(
            label: 'Receipts',
            value: _formatInt(_totalFromPaginated(receipts)),
            helper: 'Collections recorded',
            color: const Color(0xFF1FA971),
          ),
          ErpDashboardHighlightEntry(
            label: 'Quotations',
            value: _formatInt(_totalFromPaginated(quotations)),
            helper: 'Pipeline estimation',
            color: const Color(0xFF19A7B8),
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
  final responses = await Future.wait<dynamic>([
    service.requisitions(filters: const {'per_page': 100}),
    service.orders(filters: const {'per_page': 100}),
    service.receipts(filters: const {'per_page': 100}),
    service.invoices(filters: const {'per_page': 100}),
  ]);

  final requisitions =
      responses[0] as PaginatedResponse<PurchaseRequisitionModel>;
  final orders = responses[1] as PaginatedResponse<PurchaseOrderModel>;
  final receipts = responses[2] as PaginatedResponse<PurchaseReceiptModel>;
  final invoices = responses[3] as PaginatedResponse<PurchaseInvoiceModel>;

  final orderRows = orders.data ?? const <PurchaseOrderModel>[];
  final pendingOrders = orderRows
      .where(
        (item) =>
            !_isClosedStatus(item.toJson(), const ['order_status', 'status']),
      )
      .length;
  final dueToday = orderRows
      .where(
        (item) =>
            _isToday(item.toJson(), const ['order_date', 'expected_date']),
      )
      .length;
  final requisitionRows =
      requisitions.data ?? const <PurchaseRequisitionModel>[];

  return ErpDashboardSnapshot(
    title: 'Purchase Dashboard',
    subtitle: 'Live procurement flow with the shared ERP dashboard layout.',
    actions: const <ErpDashboardAction>[
      ErpDashboardAction(
        label: 'Open requisitions',
        icon: Icons.playlist_add_check_outlined,
        route: '/purchase/requisitions',
      ),
      ErpDashboardAction(
        label: 'Open orders',
        icon: Icons.shopping_bag_outlined,
        route: '/purchase/orders',
      ),
    ],
    stats: <ErpDashboardStat>[
      ErpDashboardStat(
        label: 'Total Requisitions',
        value: _formatInt(_totalFromPaginated(requisitions)),
        helper: 'Live purchasing demand',
        icon: Icons.inventory_outlined,
      ),
      ErpDashboardStat(
        label: 'Pending Orders',
        value: _formatInt(pendingOrders),
        helper: 'Purchase orders not yet closed',
        icon: Icons.pending_actions_outlined,
        color: const Color(0xFFE67E22),
      ),
      ErpDashboardStat(
        label: 'Due Today',
        value: _formatInt(dueToday),
        helper: 'Expected or scheduled today',
        icon: Icons.today_outlined,
        color: const Color(0xFFDA4D78),
      ),
      ErpDashboardStat(
        label: 'Open Receipts',
        value: _formatInt(_totalFromPaginated(receipts)),
        helper: 'Receiving workload snapshot',
        icon: Icons.move_to_inbox_outlined,
        color: const Color(0xFF19A7B8),
      ),
    ],
    primarySections: <ErpDashboardListSection>[
      ErpDashboardListSection(
        title: 'Recent Procurement Tasks',
        subtitle: 'Latest requisitions and orders from live purchase APIs.',
        icon: Icons.assignment_outlined,
        items: <ErpDashboardListItem>[
          ...requisitionRows
              .take(3)
              .map(
                (requisition) => ErpDashboardListItem(
                  title: stringValue(
                    requisition.toJson(),
                    'requisition_no',
                    'Purchase requisition',
                  ),
                  subtitle: displayDate(
                    nullableStringValue(
                      requisition.toJson(),
                      'requisition_date',
                    ),
                  ),
                  detail: nullableStringValue(requisition.toJson(), 'remarks'),
                  statusLabel: _statusLabel(requisition.toJson(), const [
                    'requisition_status',
                    'status',
                  ]),
                  route: _recordRoute(
                    '/purchase/requisitions',
                    requisition.toJson(),
                  ),
                ),
              ),
          ...orderRows
              .take(3)
              .map(
                (order) => ErpDashboardListItem(
                  title: stringValue(
                    order.toJson(),
                    'order_no',
                    'Purchase order',
                  ),
                  subtitle: displayDate(
                    nullableStringValue(order.toJson(), 'order_date'),
                  ),
                  detail: nullableStringValue(order.toJson(), 'remarks'),
                  statusLabel: _statusLabel(order.toJson(), const [
                    'order_status',
                    'status',
                  ]),
                  route: _recordRoute('/purchase/orders', order.toJson()),
                ),
              ),
        ],
      ),
    ],
    trend: _buildMonthlyTrendCard(
      title: 'Monthly Purchase Trend',
      subtitle:
          'Live monthly procurement activity from requisitions, orders, receipts, and invoices.',
      color: const Color(0xFF19A7B8),
      trendFilter: trendFilter,
      sources: <_TrendSource>[
        _TrendSource(
          records: requisitionRows.map((item) => item.toJson()),
          dateKeys: const ['requisition_date', 'created_at'],
        ),
        _TrendSource(
          records: orderRows.map((item) => item.toJson()),
          dateKeys: const ['order_date', 'expected_date', 'created_at'],
        ),
        _TrendSource(
          records: (receipts.data ?? const <PurchaseReceiptModel>[]).map(
            (item) => item.toJson(),
          ),
          dateKeys: const ['receipt_date', 'created_at'],
        ),
        _TrendSource(
          records: (invoices.data ?? const <PurchaseInvoiceModel>[]).map(
            _purchaseInvoiceJson,
          ),
          dateKeys: const ['invoice_date', 'due_date', 'created_at'],
        ),
      ],
    ),
    distribution: ErpDashboardDistributionCardData(
      title: 'Purchase Distribution',
      subtitle:
          'Live split across requisitions, orders, receipts, and invoices.',
      segments: _segmentsFromCounts(<String, int>{
        'Requisitions': _totalFromPaginated(requisitions),
        'Orders': _totalFromPaginated(orders),
        'Receipts': _totalFromPaginated(receipts),
        'Invoices': _totalFromPaginated(invoices),
      }),
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
                statusColor:
                    _looksActive(item.toJson(), const ['is_active', 'status'])
                    ? const Color(0xFF1FA971)
                    : const Color(0xFFE67E22),
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
  const _TrendSource({required this.records, required this.dateKeys});

  final Iterable<Map<String, dynamic>> records;
  final List<String> dateKeys;
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
}) {
  return ErpDashboardTrendCardData(
    title: title,
    subtitle: subtitle,
    points: _trendPointsFromSources(sources, trendFilter: trendFilter),
    emptyMessage: emptyMessage,
    color: color,
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
  final counts = List<int>.filled(buckets.length, 0);
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
          counts[index] += 1;
          break;
        }
      }
    }
  }

  return List<ErpDashboardTrendPoint>.generate(buckets.length, (index) {
    return ErpDashboardTrendPoint(
      label: buckets[index].label,
      value: counts[index].toDouble(),
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

Map<String, dynamic> _salesInvoiceJson(SalesInvoiceModel invoice) {
  return invoice.raw ??
      <String, dynamic>{
        'id': invoice.id,
        'invoice_no': invoice.invoiceNo,
        'invoice_date': invoice.invoiceDate,
        'due_date': invoice.dueDate,
        'invoice_status': invoice.invoiceStatus,
        'grand_total': invoice.totalAmount,
        'balance_amount': invoice.balanceAmount,
      };
}

Map<String, dynamic> _purchaseInvoiceJson(PurchaseInvoiceModel invoice) {
  return invoice.raw ??
      <String, dynamic>{
        'id': invoice.id,
        'invoice_no': invoice.invoiceNo,
        'invoice_date': invoice.invoiceDate,
        'due_date': invoice.dueDate,
        'invoice_status': invoice.invoiceStatus,
        'total_amount': invoice.totalAmount,
      };
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

Map<String, dynamic> _safeMap(Map<String, dynamic> Function() builder) {
  try {
    return builder();
  } catch (_) {
    return <String, dynamic>{};
  }
}

String _statusLabel(Map<String, dynamic> data, List<String> keys) {
  final value = _firstString(data, keys, fallback: 'Open');
  return value.trim().isEmpty ? 'OPEN' : value.toUpperCase();
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
