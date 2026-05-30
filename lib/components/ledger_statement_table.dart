import '../screen.dart';

class LedgerStatementRowData {
  const LedgerStatementRowData({
    required this.date,
    required this.code,
    required this.ledgerName,
    required this.cashBankLedger,
    required this.credit,
    required this.debit,
  });

  final String date;
  final String code;
  final String ledgerName;
  final String cashBankLedger;
  final String credit;
  final String debit;
}

class LedgerStatementTable extends StatelessWidget {
  const LedgerStatementTable({
    super.key,
    required this.title,
    required this.rows,
    this.subtitle,
    this.emptyMessage = 'No ledger entries found.',
  });

  final String title;
  final String? subtitle;
  final List<LedgerStatementRowData> rows;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extension = theme.extension<AppThemeExtension>()!;
    const creditColor = Color(0xFF1E8E5A);
    const debitColor = Color(0xFFC0392B);

    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if ((subtitle ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: AppUiConstants.spacingXs),
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: extension.mutedText,
              ),
            ),
          ],
          const SizedBox(height: AppUiConstants.spacingMd),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppUiConstants.spacingLg,
              ),
              child: Text(emptyMessage),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 52,
                dataRowMinHeight: 56,
                dataRowMaxHeight: 64,
                columns: const [
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Code')),
                  DataColumn(label: Text('Ledger Name')),
                  DataColumn(label: Text('Cash / Bank Ledger')),
                  DataColumn(numeric: true, label: Text('Credit')),
                  DataColumn(numeric: true, label: Text('Debit')),
                ],
                rows: rows
                    .map(
                      (row) => DataRow(
                        cells: [
                          DataCell(Text(row.date)),
                          DataCell(Text(row.code)),
                          DataCell(
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 220),
                              child: Text(
                                row.ledgerName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 220),
                              child: Text(
                                row.cashBankLedger,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            _LedgerAmountBadge(
                              value: row.credit,
                              color: creditColor,
                              mutedColor: extension.mutedText,
                            ),
                          ),
                          DataCell(
                            _LedgerAmountBadge(
                              value: row.debit,
                              color: debitColor,
                              mutedColor: extension.mutedText,
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
        ],
      ),
    );
  }
}

class _LedgerAmountBadge extends StatelessWidget {
  const _LedgerAmountBadge({
    required this.value,
    required this.color,
    required this.mutedColor,
  });

  final String value;
  final Color color;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    final inactive = value.trim().isEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: inactive ? Colors.transparent : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: inactive ? mutedColor : color,
          fontWeight: inactive ? FontWeight.w400 : FontWeight.w700,
        ),
      ),
    );
  }
}
