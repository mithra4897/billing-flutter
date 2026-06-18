import '../../../screen.dart';

/// Renders structured tables for accounting API report payloads (replacing raw JSON).
class FinancialReportViews {
  const FinancialReportViews._();

  static Widget buildBody(
    BuildContext context,
    String reportType,
    Map<String, dynamic> data,
  ) {
    final theme = Theme.of(context);
    switch (reportType) {
      case 'day_book':
        return _dayBook(data, theme);
      case 'general_ledger':
        return _generalLedger(data, theme);
      case 'trial_balance':
        return _trialBalance(data, theme);
      case 'balance_sheet':
        return _balanceSheet(data, theme);
      case 'profit_and_loss':
        return _profitAndLoss(data, theme);
      case 'cash_flow':
        return _cashFlow(data, theme);
      case 'accounts_receivable_aging':
      case 'accounts_payable_aging':
        return _aging(data, theme);
      case 'financial_statement_pack':
        return _statementPack(context, data, theme);
      default:
        return _fallbackJson(data, theme);
    }
  }

  /// Tab-separated values for spreadsheets (no locale-specific decimals).
  static String toTsv(String reportType, Map<String, dynamic> data) {
    final b = StringBuffer();
    switch (reportType) {
      case 'day_book':
        _tsvLines(b, [
          'voucher_no',
          'voucher_date',
          'voucher_type',
          'line_no',
          'account_code',
          'account_name',
          'party_name',
          'narration',
          'debit',
          'credit',
        ], _asList(data['lines']));
        break;
      case 'general_ledger':
        _tsvLines(b, [
          'voucher_no',
          'voucher_date',
          'voucher_type',
          'party_name',
          'narration',
          'debit',
          'credit',
          'running_balance',
        ], _asList(data['lines']));
        break;
      case 'trial_balance':
        _tsvLines(b, [
          'account_code',
          'account_name',
          'group_name',
          'debit',
          'credit',
        ], _asList(data['lines']));
        break;
      case 'balance_sheet':
        for (final section in ['assets', 'liabilities', 'equity']) {
          b.writeln('# $section');
          _tsvLines(b, [
            'account_code',
            'account_name',
            'group_name',
            'amount',
          ], _asList(data[section]));
          b.writeln();
        }
        break;
      case 'profit_and_loss':
        b.writeln('# income');
        _tsvLines(b, [
          'account_code',
          'account_name',
          'group_name',
          'amount',
        ], _asList(data['income']));
        b.writeln('# expense');
        _tsvLines(b, [
          'account_code',
          'account_name',
          'group_name',
          'amount',
        ], _asList(data['expense']));
        break;
      case 'cash_flow':
        _tsvLines(b, [
          'voucher_no',
          'voucher_date',
          'classification',
          'cash_accounts',
          'counterparty_accounts',
          'narration',
          'inflow',
          'outflow',
        ], _asList(data['lines']));
        break;
      case 'accounts_receivable_aging':
      case 'accounts_payable_aging':
        _tsvLines(b, [
          'invoice_no',
          'invoice_date',
          'due_date',
          'age_days',
          'outstanding_amount',
          'bucket',
        ], _asList(data['lines']));
        break;
      case 'financial_statement_pack':
        b.writeln(const JsonEncoder.withIndent('  ').convert(data));
        break;
      default:
        b.writeln(const JsonEncoder.withIndent('  ').convert(data));
    }
    return b.toString();
  }

  static void _tsvLines(
    StringBuffer b,
    List<String> headers,
    List<dynamic> rows,
  ) {
    b.writeln(headers.join('\t'));
    for (final raw in rows) {
      final row = _mapDynamic(raw);
      b.writeln(headers.map((h) => _csvCell(row[h])).join('\t'));
    }
  }

  static String _csvCell(dynamic v) {
    if (v == null) {
      return '';
    }
    final s = v.toString().replaceAll('\t', ' ');
    return s;
  }

  static Widget _statementPack(
    BuildContext context,
    Map<String, dynamic> data,
    ThemeData theme,
  ) {
    Widget section(
      String title,
      Map<String, dynamic> payload,
      String innerType,
    ) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppUiConstants.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
            buildBody(context, innerType, payload),
          ],
        ),
      );
    }

    final tb = _mapDynamic(data['trial_balance']);
    final pl = _mapDynamic(data['profit_and_loss']);
    final bs = _mapDynamic(data['balance_sheet']);
    final cf = _mapDynamic(data['cash_flow']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        section('Trial balance', tb, 'trial_balance'),
        section('Profit & loss', pl, 'profit_and_loss'),
        section('Balance sheet', bs, 'balance_sheet'),
        section('Cash flow', cf, 'cash_flow'),
      ],
    );
  }

  static Widget _dayBook(Map<String, dynamic> data, ThemeData theme) {
    final period = _mapDynamic(data['period']);
    final summary = _mapDynamic(data['summary']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          children: [
            _meta(theme, 'From', period['date_from']?.toString() ?? ''),
            _meta(theme, 'To', period['date_to']?.toString() ?? ''),
            _meta(theme, 'Total debit', _money(summary['total_debit'])),
            _meta(theme, 'Total credit', _money(summary['total_credit'])),
          ],
        ),
        const SizedBox(height: AppUiConstants.spacingMd),
        _table(
          theme,
          const [
            'Date',
            'Voucher',
            'Type',
            'Ln',
            'Account',
            'Party',
            'Narration',
            'Debit',
            'Credit',
          ],
          _asList(data['lines'])
              .map((raw) {
                final r = _mapDynamic(raw);
                return [
                  r['voucher_date']?.toString() ?? '',
                  r['voucher_no']?.toString() ?? '',
                  r['voucher_type']?.toString() ?? '',
                  r['line_no']?.toString() ?? '',
                  '${r['account_code'] ?? ''} ${r['account_name'] ?? ''}'
                      .trim(),
                  r['party_name']?.toString() ?? '',
                  r['narration']?.toString() ?? '',
                  _money(r['debit']),
                  _money(r['credit']),
                ];
              })
              .toList(growable: false),
        ),
      ],
    );
  }

  static Widget _generalLedger(Map<String, dynamic> data, ThemeData theme) {
    final account = _mapDynamic(data['account']);
    final period = _mapDynamic(data['period']);
    final summary = _mapDynamic(data['summary']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${account['account_code'] ?? ''} · ${account['account_name'] ?? ''}',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppUiConstants.spacingSm),
        Wrap(
          children: [
            _meta(theme, 'From', period['date_from']?.toString() ?? ''),
            _meta(theme, 'To', period['date_to']?.toString() ?? ''),
            _meta(
              theme,
              'Opening',
              _balance(
                summary['opening_balance'],
                summary['opening_balance_side'],
              ),
            ),
            _meta(
              theme,
              'Closing',
              _balance(
                summary['closing_balance'],
                summary['closing_balance_side'],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppUiConstants.spacingMd),
        _table(
          theme,
          const [
            'Date',
            'Voucher',
            'Type',
            'Party',
            'Narration',
            'Debit',
            'Credit',
            'Balance',
          ],
          _asList(data['lines'])
              .map((raw) {
                final r = _mapDynamic(raw);
                return [
                  r['voucher_date']?.toString() ?? '',
                  r['voucher_no']?.toString() ?? '',
                  r['voucher_type']?.toString() ?? '',
                  r['party_name']?.toString() ?? '',
                  r['narration']?.toString() ?? '',
                  _money(r['debit']),
                  _money(r['credit']),
                  _balance(r['running_balance'], r['running_balance_side']),
                ];
              })
              .toList(growable: false),
        ),
      ],
    );
  }

  static Widget _trialBalance(Map<String, dynamic> data, ThemeData theme) {
    final totals = _mapDynamic(data['totals']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          children: [
            _meta(theme, 'As of', data['as_of_date']?.toString() ?? ''),
            _meta(theme, 'Total debit', _money(totals['debit'])),
            _meta(theme, 'Total credit', _money(totals['credit'])),
          ],
        ),
        const SizedBox(height: AppUiConstants.spacingMd),
        _table(
          theme,
          const ['Code', 'Account', 'Group', 'Nature', 'Debit', 'Credit'],
          _asList(data['lines'])
              .map((raw) {
                final r = _mapDynamic(raw);
                return [
                  r['account_code']?.toString() ?? '',
                  r['account_name']?.toString() ?? '',
                  r['group_name']?.toString() ?? '',
                  r['group_nature']?.toString() ?? '',
                  _money(r['debit']),
                  _money(r['credit']),
                ];
              })
              .toList(growable: false),
        ),
      ],
    );
  }

  static Widget _balanceSheet(Map<String, dynamic> data, ThemeData theme) {
    final totals = _mapDynamic(data['totals']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _meta(theme, 'As of', data['as_of_date']?.toString() ?? ''),
        const SizedBox(height: AppUiConstants.spacingMd),
        _bsSection(theme, 'Assets', _asList(data['assets'])),
        _bsSection(theme, 'Liabilities', _asList(data['liabilities'])),
        _bsSection(theme, 'Equity', _asList(data['equity'])),
        const SizedBox(height: AppUiConstants.spacingSm),
        Wrap(
          children: [
            _meta(theme, 'Assets total', _money(totals['assets'])),
            _meta(theme, 'Liabilities', _money(totals['liabilities'])),
            _meta(theme, 'Equity', _money(totals['equity'])),
          ],
        ),
      ],
    );
  }

  static Widget _bsSection(ThemeData theme, String title, List<dynamic> lines) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppUiConstants.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppUiConstants.spacingXs),
          _table(
            theme,
            const ['Code', 'Account', 'Group', 'Amount'],
            lines
                .map((raw) {
                  final r = _mapDynamic(raw);
                  return [
                    r['account_code']?.toString() ?? '',
                    r['account_name']?.toString() ?? '',
                    r['group_name']?.toString() ?? '',
                    _balance(r['amount'], r['balance_side']),
                  ];
                })
                .toList(growable: false),
          ),
        ],
      ),
    );
  }

  static Widget _profitAndLoss(Map<String, dynamic> data, ThemeData theme) {
    final period = _mapDynamic(data['period']);
    final totals = _mapDynamic(data['totals']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          children: [
            _meta(theme, 'From', period['date_from']?.toString() ?? ''),
            _meta(theme, 'To', period['date_to']?.toString() ?? ''),
            _meta(
              theme,
              totals['net_label']?.toString() ?? 'Net Profit',
              _balance(totals['net_amount'], totals['net_side']),
            ),
          ],
        ),
        const SizedBox(height: AppUiConstants.spacingMd),
        _plSection(theme, 'Income', _asList(data['income'])),
        _plSection(theme, 'Expense', _asList(data['expense'])),
      ],
    );
  }

  static Widget _plSection(ThemeData theme, String title, List<dynamic> lines) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppUiConstants.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppUiConstants.spacingXs),
          _table(
            theme,
            const ['Code', 'Account', 'Group', 'Category', 'Amount'],
            lines
                .map((raw) {
                  final r = _mapDynamic(raw);
                  return [
                    r['account_code']?.toString() ?? '',
                    r['account_name']?.toString() ?? '',
                    r['group_name']?.toString() ?? '',
                    r['group_category']?.toString() ?? '',
                    _balance(r['amount'], r['balance_side']),
                  ];
                })
                .toList(growable: false),
          ),
        ],
      ),
    );
  }

  static Widget _cashFlow(Map<String, dynamic> data, ThemeData theme) {
    final period = _mapDynamic(data['period']);
    final summary = _mapDynamic(data['summary']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          children: [
            _meta(theme, 'From', period['date_from']?.toString() ?? ''),
            _meta(theme, 'To', period['date_to']?.toString() ?? ''),
            _meta(theme, 'Inflows', _money(summary['cash_inflows'])),
            _meta(theme, 'Outflows', _money(summary['cash_outflows'])),
            _meta(theme, 'Net', _money(summary['net_cash_flow'])),
            _meta(theme, 'Operating', _money(_net(summary, 'operating'))),
            _meta(theme, 'Investing', _money(_net(summary, 'investing'))),
            _meta(theme, 'Financing', _money(_net(summary, 'financing'))),
            _meta(
              theme,
              'Internal transfer',
              _money(_net(summary, 'internal_transfer')),
            ),
          ],
        ),
        const SizedBox(height: AppUiConstants.spacingMd),
        _table(
          theme,
          const [
            'Date',
            'Voucher',
            'Class',
            'Cash Account',
            'Counterparty',
            'Narration',
            'Inflow',
            'Outflow',
          ],
          _asList(data['lines'])
              .map((raw) {
                final r = _mapDynamic(raw);
                return [
                  r['voucher_date']?.toString() ?? '',
                  r['voucher_no']?.toString() ?? '',
                  r['classification']?.toString() ?? '',
                  r['cash_accounts']?.toString() ?? '',
                  r['counterparty_accounts']?.toString() ?? '',
                  r['narration']?.toString() ?? '',
                  _money(r['inflow']),
                  _money(r['outflow']),
                ];
              })
              .toList(growable: false),
        ),
      ],
    );
  }

  static Widget _aging(Map<String, dynamic> data, ThemeData theme) {
    final totals = _mapDynamic(data['totals']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _meta(theme, 'As of', data['as_of_date']?.toString() ?? ''),
        const SizedBox(height: AppUiConstants.spacingSm),
        Wrap(
          children: [
            _meta(theme, 'Current', _money(totals['current'])),
            _meta(theme, '1–30', _money(totals['1_30'])),
            _meta(theme, '31–60', _money(totals['31_60'])),
            _meta(theme, '61–90', _money(totals['61_90'])),
            _meta(theme, '91+', _money(totals['91_plus'])),
            _meta(theme, 'Grand total', _money(totals['grand_total'])),
          ],
        ),
        const SizedBox(height: AppUiConstants.spacingMd),
        _table(
          theme,
          const [
            'Party',
            'Invoice',
            'Inv date',
            'Due',
            'Days',
            'Outstanding',
            'Bucket',
          ],
          _asList(data['lines'])
              .map((raw) {
                final r = _mapDynamic(raw);
                final partyName =
                    r['customer_name']?.toString() ??
                    r['supplier_name']?.toString() ??
                    '';
                return [
                  partyName,
                  r['invoice_no']?.toString() ?? '',
                  r['invoice_date']?.toString() ?? '',
                  r['due_date']?.toString() ?? '',
                  r['age_days']?.toString() ?? '',
                  _money(r['outstanding_amount']),
                  r['bucket']?.toString() ?? '',
                ];
              })
              .toList(growable: false),
        ),
      ],
    );
  }

  static Widget _fallbackJson(Map<String, dynamic> data, ThemeData theme) {
    return SelectableText(
      const JsonEncoder.withIndent('  ').convert(data),
      style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
    );
  }

  static Widget _meta(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 16, bottom: 8),
      child: Text(
        '$label: $value',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  static Widget _table(
    ThemeData theme,
    List<String> headers,
    List<List<String>> rows,
  ) {
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppUiConstants.spacingLg),
        child: Text(
          'No rows available.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.extension<AppThemeExtension>()!.mutedText,
          ),
        ),
      );
    }

    return _ReportDataTable(theme: theme, headers: headers, rows: rows);
  }

  static bool _isNumericHeader(String header) {
    const numericHeaders = <String>{
      'Debit',
      'Credit',
      'Balance',
      'Amount',
      'Outstanding',
      'Inflows',
      'Outflows',
      'Inflow',
      'Outflow',
      'Net',
      'Days',
      'Ln',
      'Utilization %',
      'Budget',
      'Actual',
      'Variance',
    };
    return numericHeaders.contains(header);
  }

  static String _money(dynamic v) {
    if (v == null) {
      return '';
    }
    final n = double.tryParse(v.toString());
    if (n == null) {
      return v.toString();
    }
    if (n == 0) {
      return '';
    }
    return n.toStringAsFixed(2);
  }

  static String _balance(dynamic amount, dynamic side) {
    final numericAmount = double.tryParse(amount?.toString() ?? '');
    final absoluteAmount = numericAmount == null ? amount : numericAmount.abs();
    final value = _money(absoluteAmount);
    if (value.isEmpty && numericAmount == null) {
      return '';
    }
    var sideValue = side?.toString().trim().toLowerCase();
    if ((sideValue == null || sideValue.isEmpty) && numericAmount != null) {
      if (numericAmount < 0) {
        sideValue = 'credit';
      } else if (numericAmount > 0) {
        sideValue = 'debit';
      }
    }
    if (sideValue == 'debit') {
      return '$value Dr';
    }
    if (sideValue == 'credit') {
      return '$value Cr';
    }
    return value;
  }

  static double _num(dynamic value) => double.tryParse(value.toString()) ?? 0;

  static double _net(Map<String, dynamic> summary, String prefix) {
    return _num(summary['${prefix}_inflows']) -
        _num(summary['${prefix}_outflows']);
  }

  static Map<String, dynamic> _mapDynamic(dynamic v) {
    if (v is Map<String, dynamic>) {
      return v;
    }
    if (v is Map) {
      return v.map((k, x) => MapEntry(k.toString(), x));
    }
    return <String, dynamic>{};
  }

  static List<dynamic> _asList(dynamic v) {
    if (v is! List) {
      return const <dynamic>[];
    }
    return v;
  }
}

class _ReportTableCell extends StatelessWidget {
  const _ReportTableCell({required this.text, required this.alignEnd});

  final String text;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final child = Text(
      text.trim().isEmpty ? '-' : text,
      overflow: TextOverflow.ellipsis,
      textAlign: alignEnd ? TextAlign.end : TextAlign.start,
      style: Theme.of(context).textTheme.bodySmall,
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: alignEnd ? 96 : 120,
        maxWidth: alignEnd ? 140 : 260,
      ),
      child: alignEnd
          ? Align(alignment: Alignment.centerRight, child: child)
          : child,
    );
  }
}

class _ReportDataTable extends StatefulWidget {
  const _ReportDataTable({
    required this.theme,
    required this.headers,
    required this.rows,
  });

  final ThemeData theme;
  final List<String> headers;
  final List<List<String>> rows;

  @override
  State<_ReportDataTable> createState() => _ReportDataTableState();
}

class _ReportDataTableState extends State<_ReportDataTable> {
  late final ScrollController _horizontalScrollController;

  @override
  void initState() {
    super.initState();
    _horizontalScrollController = ScrollController();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final estimatedWidth = widget.headers.fold<double>(
          0,
          (sum, header) =>
              sum +
              (FinancialReportViews._isNumericHeader(header) ? 140.0 : 220.0),
        );

        return Scrollbar(
          controller: _horizontalScrollController,
          thumbVisibility: true,
          notificationPredicate: (notification) =>
              notification.metrics.axis == Axis.horizontal,
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
                maxWidth: estimatedWidth > constraints.maxWidth
                    ? estimatedWidth
                    : constraints.maxWidth,
              ),
              child: DataTable(
                headingRowHeight: 52,
                dataRowMinHeight: 56,
                dataRowMaxHeight: 64,
                columnSpacing: AppUiConstants.spacingLg,
                horizontalMargin: AppUiConstants.spacingSm,
                columns: widget.headers
                    .map(
                      (header) => DataColumn(
                        numeric: FinancialReportViews._isNumericHeader(header),
                        label: Text(header),
                      ),
                    )
                    .toList(growable: false),
                rows: widget.rows
                    .map(
                      (cells) => DataRow(
                        cells: cells
                            .asMap()
                            .entries
                            .map(
                              (entry) => DataCell(
                                _ReportTableCell(
                                  text: entry.value,
                                  alignEnd: FinancialReportViews
                                      ._isNumericHeader(
                                        widget.headers[entry.key],
                                      ),
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ),
        );
      },
    );
  }
}
