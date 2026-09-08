import '../../../controller/settings/accounting/financial_reports_controller.dart';
import '../../../screen.dart';

class FinancialReportsPage extends StatefulWidget {
  const FinancialReportsPage({
    super.key,
    this.embedded = false,
    this.initialReportType,
  });

  final bool embedded;
  final String? initialReportType;

  @override
  State<FinancialReportsPage> createState() => _FinancialReportsPageState();
}

class _FinancialReportsPageState extends State<FinancialReportsPage> {
  late final String _controllerTag;
  late final TextEditingController _searchController;
  bool _filtersVisible = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController()..addListener(_onSearchChanged);
    _controllerTag = persistentControllerTag(
      'FinancialReportsController',
      scope: <String, Object?>{
        'identity': identityHashCode(this),
        'embedded': widget.embedded,
      },
    );
    _registerController();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    if (Get.isRegistered<FinancialReportsController>(tag: _controllerTag)) {
      Get.delete<FinancialReportsController>(tag: _controllerTag, force: true);
    }
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  void _registerController() {
    if (Get.isRegistered<FinancialReportsController>(tag: _controllerTag)) {
      return;
    }
    Get.put(
      FinancialReportsController(initialReportType: widget.initialReportType),
      tag: _controllerTag,
    );
  }

  List<Widget> _buildShellActions(
    BuildContext context,
    FinancialReportsController controller,
  ) {
    return [
      AdaptiveShellSearchField(
        controller: _searchController,
        hintText: 'Search report rows',
      ),
      AdaptiveShellActionButton(
        onPressed: controller.loading
            ? null
            : () => setState(() => _filtersVisible = !_filtersVisible),
        icon: Icons.filter_alt_outlined,
        label: 'Filter',
        filled: _filtersVisible,
      ),
      AdaptiveShellActionButton(
        onPressed: controller.loading || controller.report == null
            ? null
            : controller.copyReportTsv,
        icon: Icons.copy_outlined,
        label: 'Copy TSV',
        filled: false,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FinancialReportsController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = _buildContent(context, controller);
        if (widget.embedded) {
          return ShellPageActions(
            actions: _buildShellActions(context, controller),
            child: content,
          );
        }

        return AppStandaloneShell(
          title: 'Financial Reports',
          scrollController: controller.pageScrollController,
          actions: _buildShellActions(context, controller),
          child: content,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    FinancialReportsController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading report lookups...');
    }
    if (controller.error != null && controller.report == null) {
      return AppErrorStateView(
        title: 'Unable to prepare reports',
        message: controller.error!,
        onRetry: controller.loadLookups,
      );
    }
    return _buildRegisterReport(context, controller);
  }

  Widget _buildRegisterReport(
    BuildContext context,
    FinancialReportsController controller,
  ) {
    final actions = _buildShellActions(context, controller);
    final columns = _registerColumns(controller.reportType);
    final rows = _filterRegisterRows(
      _registerRows(controller.reportType, controller.report?.data),
    );
    return PurchaseRegisterPage<_FinancialReportRegisterRow>(
      title: _reportTitle(controller.reportType),
      embedded: true,
      fullPageStyle: true,
      loading: controller.loading,
      errorMessage: controller.error,
      onRetry: controller.loadLookups,
      actions: actions,
      filters: _filtersVisible
          ? _buildRegisterFilters(context, controller)
          : null,
      rows: rows,
      columns: columns,
      onRowTap: (_) {},
      emptyMessage: 'No report entries for the selected filters.',
      footerBuilder: (_, currentPage) => _buildTotalsFooter(
        reportType: controller.reportType,
        rows: rows,
        columns: columns,
        currentPage: currentPage,
      ),
    );
  }

  Widget _buildTotalsFooter({
    required String reportType,
    required List<_FinancialReportRegisterRow> rows,
    required List<PurchaseRegisterColumn<_FinancialReportRegisterRow>> columns,
    required int currentPage,
  }) {
    final start = (currentPage - 1) * kLocalListPageSize;
    final pageEnd = (start + kLocalListPageSize) > rows.length
        ? rows.length
        : start + kLocalListPageSize;
    final pageRows = start >= rows.length
        ? const <_FinancialReportRegisterRow>[]
        : rows.sublist(start, pageEnd);
    final totalFields = _totalFieldsForReport(reportType);
    final pageTotals = _sumReportFields(pageRows, totalFields);
    final overallTotals = _sumReportFields(rows, totalFields);
    return PurchaseRegisterSummaryFooter(
      cells: columns
          .map((column) {
            final label = column.label;
            final value = totalFields.contains(label)
                ? '${formatAmount(pageTotals[label])}\n${formatAmount(overallTotals[label])}'
                : '';
            return PurchaseRegisterSummaryFooterCell(
              flex: column.flex,
              text: label == columns.first.label ? 'Total' : value,
              alignRight: column.alignRight,
            );
          })
          .toList(growable: false),
    );
  }

  Set<String> _totalFieldsForReport(String reportType) {
    return switch (reportType) {
      'day_book' ||
      'general_ledger' ||
      'trial_balance' => const {'Debit', 'Credit'},
      'balance_sheet' ||
      'profit_and_loss' ||
      'financial_statement_pack' => const {'Amount'},
      'cash_flow' => const {'Inflow', 'Outflow'},
      'accounts_receivable_aging' ||
      'accounts_payable_aging' => const {'Outstanding'},
      _ => const <String>{},
    };
  }

  Map<String, double> _sumReportFields(
    List<_FinancialReportRegisterRow> rows,
    Set<String> fields,
  ) {
    final totals = <String, double>{for (final field in fields) field: 0};
    for (final row in rows) {
      for (final field in fields) {
        totals[field] =
            (totals[field] ?? 0) + (_reportAmount(row.values[field]) ?? 0);
      }
    }
    return totals;
  }

  Widget _buildRegisterFilters(
    BuildContext context,
    FinancialReportsController controller,
  ) {
    return AppRegisterFilters(
      additionalFields: _buildReportFilterFields(controller),
      dateFromController: controller.dateFromController,
      dateToController: controller.dateToController,
      asOfDateController: controller.usesAsOfDate
          ? controller.asOfDateController
          : null,
      showDateFilters: controller.usesDateRange,
      onClear: () {
        _searchController.clear();
        controller.clearCurrentReportFilters();
        unawaited(controller.runReport());
      },
    );
  }

  List<_FinancialReportRegisterRow> _filterRegisterRows(
    List<_FinancialReportRegisterRow> rows,
  ) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return rows;
    return rows
        .where(
          (row) => row.values.values.any(
            (value) => value.toLowerCase().contains(query),
          ),
        )
        .toList(growable: false);
  }

  String _reportTitle(String reportType) {
    return FinancialReportsController.reportItems
        .firstWhere(
          (item) => item.value == reportType,
          orElse: () =>
              const AppDropdownItem(value: '', label: 'Financial Report'),
        )
        .label;
  }

  List<PurchaseRegisterColumn<_FinancialReportRegisterRow>> _registerColumns(
    String reportType,
  ) {
    final headers = switch (reportType) {
      'day_book' => const [
        'Date',
        'Branch',
        'Ledger',
        'Description',
        'Debit',
        'Credit',
      ],
      'general_ledger' => const [
        'Date',
        'Voucher',
        'Type',
        'Party',
        'Narration',
        'Debit',
        'Credit',
        'Balance',
      ],
      'trial_balance' => const [
        'Code',
        'Account',
        'Group',
        'Nature',
        'Debit',
        'Credit',
      ],
      'balance_sheet' => const [
        'Section',
        'Code',
        'Account',
        'Group',
        'Status',
        'Amount',
      ],
      'profit_and_loss' => const [
        'Section',
        'Code',
        'Account',
        'Group',
        'Category',
        'Status',
        'Amount',
      ],
      'cash_flow' => const [
        'Date',
        'Voucher',
        'Class',
        'Cash Account',
        'Counterparty',
        'Narration',
        'Inflow',
        'Outflow',
      ],
      'accounts_receivable_aging' || 'accounts_payable_aging' => const [
        'Invoice',
        'Invoice Date',
        'Due Date',
        'Age Days',
        'Bucket',
        'Outstanding',
      ],
      'financial_statement_pack' => const [
        'Section',
        'Code',
        'Account',
        'Group',
        'Category',
        'Status',
        'Amount',
      ],
      _ => const ['Value'],
    };
    return headers
        .map(
          (header) => PurchaseRegisterColumn<_FinancialReportRegisterRow>(
            label: header,
            flex: _registerColumnFlex(header),
            alignRight: _registerNumericHeader(header),
            padding: header == 'Bucket'
                ? const EdgeInsets.only(left: AppUiConstants.spacingMd)
                : null,
            valueBuilder: (row) => row.values[header] ?? '',
            widgetBuilder: switch (header) {
              'Status' => (context, row) => _balanceStatusBadge(
                context,
                row.values[header] ?? '',
              ),
              'Bucket' => (context, row) => _agingBucketBadge(
                context,
                row.values[header] ?? '',
              ),
              _ => null,
            },
          ),
        )
        .toList(growable: false);
  }

  int _registerColumnFlex(String header) {
    if (_registerNumericHeader(header)) return 2;
    if (header == 'Description' || header == 'Narration') return 4;
    if (header == 'Account' || header == 'Counterparty') return 3;
    return 2;
  }

  bool _registerNumericHeader(String header) {
    return const {
      'Debit',
      'Credit',
      'Balance',
      'Amount',
      'Outstanding',
      'Inflow',
      'Outflow',
      'Age Days',
    }.contains(header);
  }

  List<_FinancialReportRegisterRow> _registerRows(
    String reportType,
    Map<String, dynamic>? data,
  ) {
    if (data == null) return const <_FinancialReportRegisterRow>[];
    switch (reportType) {
      case 'day_book':
        return _mapReportLines(
          data['lines'],
          (line) => {
            'Date': displayDate(line['voucher_date']?.toString()),
            'Branch': line['branch_name']?.toString() ?? '-',
            'Ledger': _joinedValues(line, ['account_code', 'account_name']),
            'Description': line['narration']?.toString() ?? '',
            'Debit': formatAmount(_reportAmount(line['debit'])),
            'Credit': formatAmount(_reportAmount(line['credit'])),
          },
        );
      case 'general_ledger':
        return _mapReportLines(
          data['lines'],
          (line) => {
            'Date': displayDate(line['voucher_date']?.toString()),
            'Voucher': line['voucher_no']?.toString() ?? '',
            'Type': line['voucher_type']?.toString() ?? '',
            'Party': line['party_name']?.toString() ?? '',
            'Narration': line['narration']?.toString() ?? '',
            'Debit': formatAmount(_reportAmount(line['debit'])),
            'Credit': formatAmount(_reportAmount(line['credit'])),
            'Balance': _balanceText(
              line['running_balance'],
              line['running_balance_side'],
            ),
          },
        );
      case 'trial_balance':
        return _mapReportLines(
          data['lines'],
          (line) => {
            'Code': line['account_code']?.toString() ?? '',
            'Account': line['account_name']?.toString() ?? '',
            'Group': line['group_name']?.toString() ?? '',
            'Nature': line['group_nature']?.toString() ?? '',
            'Debit': formatAmount(_reportAmount(line['debit'])),
            'Credit': formatAmount(_reportAmount(line['credit'])),
          },
        );
      case 'balance_sheet':
        return _sectionRows(data, const ['assets', 'liabilities', 'equity']);
      case 'profit_and_loss':
        return _sectionRows(data, const ['income', 'expense']);
      case 'cash_flow':
        return _mapReportLines(
          data['lines'],
          (line) => {
            'Date': displayDate(line['voucher_date']?.toString()),
            'Voucher': line['voucher_no']?.toString() ?? '',
            'Class': line['classification']?.toString() ?? '',
            'Cash Account': line['cash_accounts']?.toString() ?? '',
            'Counterparty': line['counterparty_accounts']?.toString() ?? '',
            'Narration': line['narration']?.toString() ?? '',
            'Inflow': formatAmount(_reportAmount(line['inflow'])),
            'Outflow': formatAmount(_reportAmount(line['outflow'])),
          },
        );
      case 'accounts_receivable_aging':
      case 'accounts_payable_aging':
        return _mapReportLines(
          data['lines'],
          (line) => {
            'Invoice': line['invoice_no']?.toString() ?? '',
            'Invoice Date': displayDate(line['invoice_date']?.toString()),
            'Due Date': displayDate(line['due_date']?.toString()),
            'Age Days': _agingDaysText(line['age_days']),
            'Outstanding': formatAmount(
              _reportAmount(line['outstanding_amount']),
            ),
            'Bucket': _agingBucketLabel(line['bucket']),
          },
        );
      case 'financial_statement_pack':
        return _statementPackRows(data);
      default:
        return const <_FinancialReportRegisterRow>[];
    }
  }

  List<_FinancialReportRegisterRow> _sectionRows(
    Map<String, dynamic> data,
    List<String> sections,
  ) {
    final rows = <_FinancialReportRegisterRow>[];
    for (final section in sections) {
      final sectionPayload = data[section];
      final rawLines = sectionPayload is Map
          ? sectionPayload['lines']
          : sectionPayload;
      if (rawLines is! List) continue;
      for (final rawLine in rawLines.whereType<Map>()) {
        final line = Map<String, dynamic>.from(rawLine);
        rows.add(
          _FinancialReportRegisterRow(<String, String>{
            'Section': _sectionLabel(section),
            'Code': line['account_code']?.toString() ?? '',
            'Account': line['account_name']?.toString() ?? '',
            'Group': line['group_name']?.toString() ?? '',
            'Category': line['group_category']?.toString() ?? '',
            'Nature': line['group_nature']?.toString() ?? '',
            'Status': _balanceSide(line['balance_side']),
            'Amount': formatAmount(_reportAmount(line['amount'])),
            'Debit': formatAmount(_reportAmount(line['debit'])),
            'Credit': formatAmount(_reportAmount(line['credit'])),
          }),
        );
      }
    }
    return rows;
  }

  List<_FinancialReportRegisterRow> _statementPackRows(
    Map<String, dynamic> data,
  ) {
    final rows = <_FinancialReportRegisterRow>[];
    final trialBalance = data['trial_balance'];
    if (trialBalance is Map) {
      rows.addAll(
        _sectionRows(
          <String, dynamic>{'trial_balance': trialBalance},
          const ['trial_balance'],
        ),
      );
    }
    final profitAndLoss = data['profit_and_loss'];
    if (profitAndLoss is Map) {
      for (final section in const ['income', 'expense']) {
        final lines = profitAndLoss[section];
        if (lines is List) {
          rows.addAll(
            _sectionRows(<String, dynamic>{section: lines}, <String>[section]),
          );
        }
      }
    }
    final balanceSheet = data['balance_sheet'];
    if (balanceSheet is Map) {
      for (final section in const ['assets', 'liabilities', 'equity']) {
        final lines = balanceSheet[section];
        if (lines is List) {
          rows.addAll(
            _sectionRows(<String, dynamic>{section: lines}, <String>[section]),
          );
        }
      }
    }
    final cashFlow = data['cash_flow'];
    if (cashFlow is Map) {
      rows.addAll(
        _mapReportLines(
          cashFlow['lines'],
          (line) => {
            'Section': 'Cash Flow',
            'Date': displayDate(line['voucher_date']?.toString()),
            'Code': line['voucher_no']?.toString() ?? '',
            'Account': line['cash_accounts']?.toString() ?? '',
            'Group': line['counterparty_accounts']?.toString() ?? '',
            'Category': line['classification']?.toString() ?? '',
            'Status': '',
            'Amount': formatAmount(_reportAmount(line['inflow'])),
          },
        ),
      );
    }
    return rows;
  }

  List<_FinancialReportRegisterRow> _mapReportLines(
    dynamic rawLines,
    Map<String, String> Function(Map<String, dynamic>) mapLine,
  ) {
    if (rawLines is! List) return const <_FinancialReportRegisterRow>[];
    return rawLines
        .whereType<Map>()
        .map(
          (rawLine) => _FinancialReportRegisterRow(
            mapLine(Map<String, dynamic>.from(rawLine)),
          ),
        )
        .toList(growable: false);
  }

  String _joinedValues(Map<String, dynamic> line, List<String> keys) {
    return keys
        .map((key) => line[key]?.toString() ?? '')
        .where((value) => value.trim().isNotEmpty)
        .join(' ');
  }

  String _balanceSide(dynamic value) {
    final side = value?.toString().trim() ?? '';
    if (side.isEmpty) return '';
    return '${side[0].toUpperCase()}${side.substring(1).toLowerCase()}';
  }

  String _balanceText(dynamic amount, dynamic side) {
    final numericValue = formatAmount(_reportAmount(amount));
    final balanceSide = _balanceSide(side);
    return balanceSide.isEmpty ? numericValue : '$numericValue $balanceSide';
  }

  Widget _balanceStatusBadge(BuildContext context, String side) {
    if (side.isEmpty) return const SizedBox.shrink();
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;
    final color = switch (side.toLowerCase()) {
      'credit' => appTheme.success,
      'debit' => appTheme.warning,
      _ => appTheme.mutedText,
    };
    return AppStatusBadge(label: side, color: color);
  }

  String _agingBucketLabel(dynamic value) {
    return switch (value?.toString().trim()) {
      '1_30' => '1-30 days',
      '31_60' => '31-60 days',
      '61_90' => '61-90 days',
      '91_plus' => '91+ days',
      'current' => 'Current',
      _ => value?.toString() ?? '',
    };
  }

  String _agingDaysText(dynamic value) {
    final days = _reportAmount(value);
    return days == 0 ? '-' : value?.toString() ?? '';
  }

  Widget _agingBucketBadge(BuildContext context, String bucket) {
    if (bucket.isEmpty) return const SizedBox.shrink();
    final color = switch (bucket) {
      'Current' => Theme.of(context).colorScheme.primary,
      '1-30 days' => const Color(0xFF2E7D6B),
      '31-60 days' => const Color(0xFFB8871F),
      '61-90 days' => const Color(0xFFBE5A38),
      '91+ days' => const Color(0xFFB23A48),
      _ => Theme.of(context).extension<AppThemeExtension>()!.mutedText,
    };
    return AppStatusBadge(label: bucket, color: color);
  }

  String _sectionLabel(String value) {
    return value
        .split('_')
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  List<Widget> _buildReportFilterFields(FinancialReportsController controller) {
    return [
      AppDropdownField<String>.fromMapped(
        labelText: 'Report',
        mappedItems: FinancialReportsController.reportItems,
        initialValue: controller.reportType,
        onChanged: controller.setReportType,
      ),
      if (controller.needsDayBookBranch)
        AppDropdownField<int>.fromMapped(
          labelText: 'Branch',
          mappedItems: controller.branchFilterItems,
          multiInitialValues: controller.dayBookBranchIds,
          multiHintText: 'Select branches',
          onMultiChanged: controller.setDayBookBranchIds,
        ),
      if (controller.needsAccount)
        AppDropdownField<int>.fromMapped(
          labelText: 'Account',
          isRequired: true,
          mappedItems: controller.accountOptions
              .where((item) => item.id != null)
              .map((item) {
                final subtitle = <String>[
                  if ((item.accountCode ?? '').trim().isNotEmpty)
                    item.accountCode!.trim(),
                  if ((item.accountType ?? '').trim().isNotEmpty)
                    item.accountType!.trim(),
                  if ((item.accountGroupName ?? '').trim().isNotEmpty)
                    item.accountGroupName!.trim(),
                ].join(' | ');
                final searchText = <String>[
                  item.accountName ?? '',
                  item.accountCode ?? '',
                  item.accountType ?? '',
                  item.accountGroupName ?? '',
                ].join(' ');
                return AppDropdownItem(
                  value: item.id!,
                  label: item.accountName?.trim().isNotEmpty == true
                      ? item.accountName!.trim()
                      : item.toString(),
                  subtitle: subtitle.isEmpty ? null : subtitle,
                  searchText: searchText,
                );
              })
              .toList(growable: false),
          initialValue: controller.accountId,
          onChanged: controller.setAccountId,
        ),
      if (controller.needsParty)
        AppDropdownField<int>.fromMapped(
          labelText: 'Party',
          mappedItems: controller.partyOptions
              .where((party) => party.id != null)
              .map(
                (party) => AppDropdownItem<int>(
                  value: party.id!,
                  label: party.toString(),
                ),
              )
              .toList(growable: false),
          multiInitialValues: controller.partyIds,
          multiHintText: 'Select parties',
          onMultiChanged: controller.setPartyIds,
          onClear: controller.partyIds.isEmpty
              ? null
              : () => controller.setPartyIds(<int>{}),
        ),
    ];
  }
}

class _FinancialReportRegisterRow {
  const _FinancialReportRegisterRow(this.values);

  final Map<String, String> values;
}

double? _reportAmount(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  final formattedValue = value?.toString().trim() ?? '';
  if (formattedValue.isEmpty) {
    return null;
  }
  final numericToken = RegExp(
    r'\(?-?[\d,]+(?:\.\d+)?\)?',
  ).firstMatch(formattedValue)?.group(0);
  if (numericToken == null) {
    return null;
  }
  final normalized = numericToken
      .replaceAll(',', '')
      .replaceAll('(', '-')
      .replaceAll(')', '');
  return double.tryParse(normalized);
}
