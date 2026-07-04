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
        return _dayBook(context, data, theme);
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
          ['voucher_date', 'ledger', 'narration', 'debit', 'credit'],
          _asList(data['lines'])
              .map((raw) {
                final r = _mapDynamic(raw);
                return <String, dynamic>{
                  'voucher_date': r['voucher_date'],
                  'ledger':
                      '${r['account_code'] ?? ''} ${r['account_name'] ?? ''}'
                          .trim(),
                  'narration': r['narration'],
                  'debit': r['debit'],
                  'credit': r['credit'],
                };
              })
              .toList(growable: false),
        );
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

  static Widget _dayBook(
    BuildContext context,
    Map<String, dynamic> data,
    ThemeData theme,
  ) {
    final period = _mapDynamic(data['period']);
    final summary = _mapDynamic(data['summary']);
    final rows = _asList(data['lines'])
        .map((raw) {
          final r = _mapDynamic(raw);
          return <String>[
            _displayDate(r['voucher_date']),
            '${r['account_code'] ?? ''} ${r['account_name'] ?? ''}'.trim(),
            r['narration']?.toString() ?? '',
            _money(r['debit']),
            _money(r['credit']),
          ];
        })
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppUiConstants.spacingSm,
          runSpacing: AppUiConstants.spacingSm,
          children: [
            _reportMetaCard(
              theme: theme,
              label: 'From',
              value: _displayDate(period['date_from']),
            ),
            _reportMetaCard(
              theme: theme,
              label: 'To',
              value: _displayDate(period['date_to']),
            ),
            _reportMetaCard(
              theme: theme,
              label: 'Total Debit',
              value: _money(summary['total_debit']),
              emphasized: true,
            ),
            _reportMetaCard(
              theme: theme,
              label: 'Total Credit',
              value: _money(summary['total_credit']),
              emphasized: true,
            ),
          ],
        ),
        const SizedBox(height: AppUiConstants.spacingMd),
        Responsive.isMobile(context)
            ? _dayBookMobileList(theme, rows)
            : _table(theme, const [
                'Date',
                'Ledger',
                'Description',
                'Debit',
                'Credit',
              ], rows),
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
            _meta(theme, 'From', _displayDate(period['date_from'])),
            _meta(theme, 'To', _displayDate(period['date_to'])),
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
                  _displayDate(r['voucher_date']),
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
            _meta(theme, 'As of', _displayDate(data['as_of_date'])),
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
        _meta(theme, 'As of', _displayDate(data['as_of_date'])),
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
            _meta(theme, 'From', _displayDate(period['date_from'])),
            _meta(theme, 'To', _displayDate(period['date_to'])),
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
            _meta(theme, 'From', _displayDate(period['date_from'])),
            _meta(theme, 'To', _displayDate(period['date_to'])),
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
                  _displayDate(r['voucher_date']),
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
    final appTheme = theme.extension<AppThemeExtension>()!;
    final totals = _mapDynamic(data['totals']);
    final lines = _asList(data['lines']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppUiConstants.spacingLg),
          decoration: BoxDecoration(
            color: appTheme.subtleFill,
            borderRadius: BorderRadius.circular(AppUiConstants.panelRadius),
            border: Border.all(color: appTheme.tableBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aging overview',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppUiConstants.spacingXs),
              Text(
                'As of ${_displayDate(data['as_of_date'])}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: appTheme.mutedText,
                ),
              ),
              const SizedBox(height: AppUiConstants.spacingMd),
              Wrap(
                spacing: AppUiConstants.spacingSm,
                runSpacing: AppUiConstants.spacingSm,
                children: [
                  _agingStatCard(
                    theme: theme,
                    label: 'Current',
                    value: _money(totals['current']),
                    accent: theme.colorScheme.primary,
                  ),
                  _agingStatCard(
                    theme: theme,
                    label: '1-30 days',
                    value: _money(totals['1_30']),
                    accent: const Color(0xFF2E7D6B),
                  ),
                  _agingStatCard(
                    theme: theme,
                    label: '31-60 days',
                    value: _money(totals['31_60']),
                    accent: const Color(0xFFB8871F),
                  ),
                  _agingStatCard(
                    theme: theme,
                    label: '61-90 days',
                    value: _money(totals['61_90']),
                    accent: const Color(0xFFBE5A38),
                  ),
                  _agingStatCard(
                    theme: theme,
                    label: '91+ days',
                    value: _money(totals['91_plus']),
                    accent: const Color(0xFFB23A48),
                  ),
                  _agingStatCard(
                    theme: theme,
                    label: 'Grand total',
                    value: _money(totals['grand_total']),
                    accent: const Color(0xFF244C7A),
                    emphasized: true,
                  ),
                ],
              ),
              const SizedBox(height: AppUiConstants.spacingMd),
              Text(
                '${lines.length} open invoice${lines.length == 1 ? '' : 's'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: appTheme.mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
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
                  _displayDate(r['invoice_date']),
                  _displayDate(r['due_date']),
                  r['age_days']?.toString() ?? '',
                  _money(r['outstanding_amount']),
                  _bucketLabel(r['bucket']),
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

  static Widget _agingStatCard({
    required ThemeData theme,
    required String label,
    required String value,
    required Color accent,
    bool emphasized = false,
  }) {
    final appTheme = theme.extension<AppThemeExtension>()!;
    return Container(
      width: 168,
      padding: const EdgeInsets.all(AppUiConstants.spacingMd),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
        border: Border.all(
          color: emphasized
              ? accent.withValues(alpha: 0.30)
              : appTheme.tableBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: appTheme.cardShadow.withValues(
              alpha: emphasized ? 0.10 : 0.05,
            ),
            blurRadius: emphasized ? 22 : 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(height: AppUiConstants.spacingSm),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: appTheme.mutedText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppUiConstants.spacingXs),
          Text(
            value.isEmpty ? '-' : value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _reportMetaCard({
    required ThemeData theme,
    required String label,
    required String value,
    bool emphasized = false,
  }) {
    final appTheme = theme.extension<AppThemeExtension>()!;
    return Container(
      constraints: const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.symmetric(
        horizontal: AppUiConstants.spacingMd,
        vertical: AppUiConstants.spacingSm,
      ),
      decoration: BoxDecoration(
        color: emphasized
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
        border: Border.all(
          color: emphasized
              ? theme.colorScheme.primary.withValues(alpha: 0.18)
              : appTheme.tableBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: appTheme.mutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppUiConstants.spacingXxs),
          Text(
            value.isEmpty ? '-' : value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _dayBookMobileList(ThemeData theme, List<List<String>> rows) {
    if (rows.isEmpty) {
      return _table(theme, const ['Date'], rows);
    }
    final appTheme = theme.extension<AppThemeExtension>()!;
    return Column(
      children: rows
          .map((cells) {
            final date = cells[0];
            final ledger = cells[1];
            final description = cells[2];
            final debit = cells[3];
            final credit = cells[4];
            return Container(
              margin: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
              padding: const EdgeInsets.all(AppUiConstants.spacingMd),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
                border: Border.all(color: appTheme.tableBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    date,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: appTheme.mutedText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppUiConstants.spacingXs),
                  Text(
                    ledger.isEmpty ? '-' : ledger,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (description.trim().isNotEmpty) ...[
                    const SizedBox(height: AppUiConstants.spacingXs),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: appTheme.tableCellText,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppUiConstants.spacingSm),
                  Row(
                    children: [
                      Expanded(
                        child: _reportMetaCard(
                          theme: theme,
                          label: 'Debit',
                          value: debit,
                        ),
                      ),
                      const SizedBox(width: AppUiConstants.spacingSm),
                      Expanded(
                        child: _reportMetaCard(
                          theme: theme,
                          label: 'Credit',
                          value: credit,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          })
          .toList(growable: false),
    );
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
    return formatAmount(n);
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

  static String _displayDate(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty || raw == '-') {
      return '-';
    }
    final displayed = displayDate(raw);
    return displayed.isEmpty ? raw : displayed;
  }

  static String _bucketLabel(dynamic value) {
    switch (value?.toString().trim()) {
      case '1_30':
        return '1-30 days';
      case '31_60':
        return '31-60 days';
      case '61_90':
        return '61-90 days';
      case '91_plus':
        return '91+ days';
      case 'current':
        return 'Current';
      default:
        return value?.toString() ?? '';
    }
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
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppThemeExtension>()!;
    final displayText = text.trim().isEmpty ? '-' : text;
    final isBucket =
        !alignEnd &&
        displayText != '-' &&
        (displayText.endsWith('days') || displayText == 'Current');

    if (isBucket) {
      final Color accent = switch (displayText) {
        'Current' => theme.colorScheme.primary,
        '1-30 days' => const Color(0xFF2E7D6B),
        '31-60 days' => const Color(0xFFB8871F),
        '61-90 days' => const Color(0xFFBE5A38),
        '91+ days' => const Color(0xFFB23A48),
        _ => appTheme.mutedText,
      };
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppUiConstants.spacingSm,
            vertical: AppUiConstants.spacingXs,
          ),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppUiConstants.pillRadius),
            border: Border.all(color: accent.withValues(alpha: 0.22)),
          ),
          child: Text(
            displayText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    final child = Text(
      displayText,
      overflow: TextOverflow.ellipsis,
      textAlign: alignEnd ? TextAlign.end : TextAlign.start,
      style: theme.textTheme.bodySmall?.copyWith(
        color: alignEnd ? theme.colorScheme.onSurface : appTheme.tableCellText,
      ),
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
    final appTheme = widget.theme.extension<AppThemeExtension>()!;
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppUiConstants.tableRadiusSm),
              child: Container(
                decoration: BoxDecoration(
                  color: widget.theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(
                    AppUiConstants.tableRadiusSm,
                  ),
                  border: Border.all(color: appTheme.tableBorder),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: constraints.maxWidth,
                    maxWidth: estimatedWidth > constraints.maxWidth
                        ? estimatedWidth
                        : constraints.maxWidth,
                  ),
                  child: Theme(
                    data: widget.theme.copyWith(
                      dividerColor: appTheme.tableBorder,
                      dataTableTheme: DataTableThemeData(
                        headingRowColor: WidgetStatePropertyAll(
                          appTheme.tableHeaderBackground,
                        ),
                        headingTextStyle: widget.theme.textTheme.titleSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: appTheme.tableTitleText,
                            ),
                        dataTextStyle: widget.theme.textTheme.bodySmall
                            ?.copyWith(color: appTheme.tableCellText),
                      ),
                    ),
                    child: DataTable(
                      headingRowHeight: 56,
                      dataRowMinHeight: 58,
                      dataRowMaxHeight: 66,
                      columnSpacing: AppUiConstants.spacingLg,
                      horizontalMargin: AppUiConstants.spacingMd,
                      columns: widget.headers
                          .map(
                            (header) => DataColumn(
                              numeric: FinancialReportViews._isNumericHeader(
                                header,
                              ),
                              label: Text(header),
                            ),
                          )
                          .toList(growable: false),
                      rows: widget.rows
                          .map(
                            (cells) => DataRow(
                              color: WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.hovered)) {
                                  return appTheme.tableRowHover;
                                }
                                return null;
                              }),
                              cells: cells
                                  .asMap()
                                  .entries
                                  .map(
                                    (entry) => DataCell(
                                      _ReportTableCell(
                                        text: entry.value,
                                        alignEnd:
                                            FinancialReportViews._isNumericHeader(
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
              ),
            ),
          ),
        );
      },
    );
  }
}
