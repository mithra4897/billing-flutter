import 'dart:convert';

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
        _tsvLines(
          b,
          [
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
          ],
          _asList(data['lines']),
        );
        break;
      case 'general_ledger':
        _tsvLines(
          b,
          [
            'voucher_no',
            'voucher_date',
            'voucher_type',
            'party_name',
            'narration',
            'debit',
            'credit',
            'running_balance',
          ],
          _asList(data['lines']),
        );
        break;
      case 'trial_balance':
        _tsvLines(
          b,
          ['account_code', 'account_name', 'group_name', 'debit', 'credit'],
          _asList(data['lines']),
        );
        break;
      case 'balance_sheet':
        for (final section in ['assets', 'liabilities', 'equity']) {
          b.writeln('# $section');
          _tsvLines(
            b,
            ['account_code', 'account_name', 'group_name', 'amount'],
            _asList(data[section]),
          );
          b.writeln();
        }
        break;
      case 'profit_and_loss':
        b.writeln('# income');
        _tsvLines(
          b,
          ['account_code', 'account_name', 'group_name', 'amount'],
          _asList(data['income']),
        );
        b.writeln('# expense');
        _tsvLines(
          b,
          ['account_code', 'account_name', 'group_name', 'amount'],
          _asList(data['expense']),
        );
        break;
      case 'cash_flow':
        _tsvLines(
          b,
          ['voucher_no', 'voucher_date', 'account_name', 'narration', 'inflow', 'outflow'],
          _asList(data['lines']),
        );
        break;
      case 'accounts_receivable_aging':
      case 'accounts_payable_aging':
        _tsvLines(
          b,
          [
            'invoice_no',
            'invoice_date',
            'due_date',
            'age_days',
            'outstanding_amount',
            'bucket',
          ],
          _asList(data['lines']),
        );
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
      b.writeln(
        headers.map((h) => _csvCell(row[h])).join('\t'),
      );
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
    Widget section(String title, Map<String, dynamic> payload, String innerType) {
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
          _asList(data['lines']).map((raw) {
            final r = _mapDynamic(raw);
            return [
              r['voucher_date']?.toString() ?? '',
              r['voucher_no']?.toString() ?? '',
              r['voucher_type']?.toString() ?? '',
              r['line_no']?.toString() ?? '',
              '${r['account_code'] ?? ''} ${r['account_name'] ?? ''}'.trim(),
              r['party_name']?.toString() ?? '',
              r['narration']?.toString() ?? '',
              _money(r['debit']),
              _money(r['credit']),
            ];
          }).toList(growable: false),
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
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppUiConstants.spacingSm),
        Wrap(
          children: [
            _meta(theme, 'From', period['date_from']?.toString() ?? ''),
            _meta(theme, 'To', period['date_to']?.toString() ?? ''),
            _meta(theme, 'Opening', _money(summary['opening_balance'])),
            _meta(theme, 'Closing', _money(summary['closing_balance'])),
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
          _asList(data['lines']).map((raw) {
            final r = _mapDynamic(raw);
            return [
              r['voucher_date']?.toString() ?? '',
              r['voucher_no']?.toString() ?? '',
              r['voucher_type']?.toString() ?? '',
              r['party_name']?.toString() ?? '',
              r['narration']?.toString() ?? '',
              _money(r['debit']),
              _money(r['credit']),
              _money(r['running_balance']),
            ];
          }).toList(growable: false),
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
          _asList(data['lines']).map((raw) {
            final r = _mapDynamic(raw);
            return [
              r['account_code']?.toString() ?? '',
              r['account_name']?.toString() ?? '',
              r['group_name']?.toString() ?? '',
              r['group_nature']?.toString() ?? '',
              _money(r['debit']),
              _money(r['credit']),
            ];
          }).toList(growable: false),
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
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppUiConstants.spacingXs),
          _table(
            theme,
            const ['Code', 'Account', 'Group', 'Amount'],
            lines.map((raw) {
              final r = _mapDynamic(raw);
              return [
                r['account_code']?.toString() ?? '',
                r['account_name']?.toString() ?? '',
                r['group_name']?.toString() ?? '',
                _money(r['amount']),
              ];
            }).toList(growable: false),
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
            _meta(theme, 'Net profit', _money(totals['net_profit'])),
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
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppUiConstants.spacingXs),
          _table(
            theme,
            const ['Code', 'Account', 'Group', 'Category', 'Amount'],
            lines.map((raw) {
              final r = _mapDynamic(raw);
              return [
                r['account_code']?.toString() ?? '',
                r['account_name']?.toString() ?? '',
                r['group_name']?.toString() ?? '',
                r['group_category']?.toString() ?? '',
                _money(r['amount']),
              ];
            }).toList(growable: false),
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
            _meta(theme, 'Inflows', _money(summary['operating_inflows'])),
            _meta(theme, 'Outflows', _money(summary['operating_outflows'])),
            _meta(theme, 'Net', _money(summary['net_cash_flow'])),
          ],
        ),
        const SizedBox(height: AppUiConstants.spacingMd),
        _table(
          theme,
          const ['Date', 'Voucher', 'Account', 'Narration', 'Inflow', 'Outflow'],
          _asList(data['lines']).map((raw) {
            final r = _mapDynamic(raw);
            return [
              r['voucher_date']?.toString() ?? '',
              r['voucher_no']?.toString() ?? '',
              r['account_name']?.toString() ?? '',
              r['narration']?.toString() ?? '',
              _money(r['inflow']),
              _money(r['outflow']),
            ];
          }).toList(growable: false),
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
          _asList(data['lines']).map((raw) {
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
          }).toList(growable: false),
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
    final borderColor = theme.dividerColor.withValues(alpha: 0.5);
    final headerStyle = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w700,
    );
    final cellStyle = theme.textTheme.bodySmall;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        border: TableBorder.all(color: borderColor, width: 0.5),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.4,
              ),
            ),
            children: headers
                .map(
                  (h) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Text(h, style: headerStyle),
                  ),
                )
                .toList(growable: false),
          ),
          ...rows.map(
            (cells) => TableRow(
              children: cells
                  .map(
                    (c) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text(c, style: cellStyle),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ],
      ),
    );
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
