import '../screen.dart';

class GstSummaryCard extends StatelessWidget {
  const GstSummaryCard({
    super.key,
    required this.taxable,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.cess,
    required this.total,
    required this.currencyCode,
    this.subtitle,
  });

  final double taxable;
  final double cgst;
  final double sgst;
  final double igst;
  final double cess;
  final double total;
  final String currencyCode;
  final String? subtitle;

  static const List<String> _ones = <String>[
    'Zero',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
    'Eleven',
    'Twelve',
    'Thirteen',
    'Fourteen',
    'Fifteen',
    'Sixteen',
    'Seventeen',
    'Eighteen',
    'Nineteen',
  ];

  static const List<String> _tens = <String>[
    '',
    '',
    'Twenty',
    'Thirty',
    'Forty',
    'Fifty',
    'Sixty',
    'Seventy',
    'Eighty',
    'Ninety',
  ];

  String _twoDigitWords(int value) {
    if (value < 20) {
      return _ones[value];
    }
    final tensPart = _tens[value ~/ 10];
    final onesPart = value % 10;
    if (onesPart == 0) {
      return tensPart;
    }
    return '$tensPart ${_ones[onesPart]}';
  }

  String _threeDigitWords(int value) {
    if (value < 100) {
      return _twoDigitWords(value);
    }
    final hundreds = value ~/ 100;
    final remainder = value % 100;
    if (remainder == 0) {
      return '${_ones[hundreds]} Hundred';
    }
    return '${_ones[hundreds]} Hundred ${_twoDigitWords(remainder)}';
  }

  String _integerToWords(int value) {
    if (value == 0) {
      return _ones[0];
    }

    final parts = <String>[];
    final crore = value ~/ 10000000;
    final lakh = (value ~/ 100000) % 100;
    final thousand = (value ~/ 1000) % 100;
    final hundred = value % 1000;

    if (crore > 0) {
      parts.add('${_integerToWords(crore)} Crore');
    }
    if (lakh > 0) {
      parts.add('${_twoDigitWords(lakh)} Lakh');
    }
    if (thousand > 0) {
      parts.add('${_twoDigitWords(thousand)} Thousand');
    }
    if (hundred > 0) {
      parts.add(_threeDigitWords(hundred));
    }
    return parts.join(' ');
  }

  String _amountInWords(double amount) {
    final normalized = amount.isNegative
        ? 0
        : double.parse(amount.toStringAsFixed(2));
    var whole = normalized.floor();
    var fraction = ((normalized - whole) * 100).round();
    if (fraction == 100) {
      whole += 1;
      fraction = 0;
    }
    final code = currencyCode.trim().toUpperCase();
    final majorUnit = code == 'INR' ? 'Rupees' : code;
    final minorUnit = code == 'INR' ? 'Paise' : 'Cents';
    final wholeWords = _integerToWords(whole);
    if (fraction == 0) {
      return '$wholeWords $majorUnit Only';
    }
    return '$wholeWords $majorUnit and ${_integerToWords(fraction)} $minorUnit Only';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppThemeExtension>()!;
    final colorScheme = theme.colorScheme;

    Widget metric(String label, double value, {bool emphasize = false}) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: emphasize
              ? colorScheme.primary.withValues(alpha: 0.12)
              : appTheme.subtleFill.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
          border: Border.all(
            color: emphasize
                ? colorScheme.primary.withValues(alpha: 0.24)
                : colorScheme.outline.withValues(alpha: 0.10),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppUiConstants.spacingMd,
            vertical: AppUiConstants.spacingMd,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                textAlign: TextAlign.right,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: appTheme.mutedText,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: AppUiConstants.spacingSm),
              Text(
                value.toStringAsFixed(2),
                textAlign: TextAlign.right,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: emphasize ? FontWeight.w800 : FontWeight.w700,
                  color: emphasize ? colorScheme.primary : null,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: AppSectionCard(
        padding: const EdgeInsets.fromLTRB(
          AppUiConstants.cardPadding,
          AppUiConstants.spacingLg,
          AppUiConstants.cardPadding,
          AppUiConstants.cardPadding,
        ),
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
                        'GST Summary',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: appTheme.tableTitleText,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppUiConstants.spacingSm,
                    vertical: AppUiConstants.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    color: appTheme.subtleFill.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(
                      AppUiConstants.pillRadius,
                    ),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Text(
                    currencyCode.trim().toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: appTheme.mutedText,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final columns = width >= 1080
                    ? 6
                    : width >= 860
                    ? 3
                    : width >= 560
                    ? 2
                    : 1;
                final gap = AppUiConstants.spacingSm;
                final tileWidth = columns == 1
                    ? width
                    : (width - (gap * (columns - 1))) / columns;

                final tiles = <Widget>[
                  metric('Taxable', taxable),
                  metric('CGST', cgst),
                  metric('SGST', sgst),
                  metric('IGST', igst),
                  metric('CESS', cess),
                  metric('Grand Total', total, emphasize: true),
                ];

                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: tiles
                      .map(
                        (tile) => SizedBox(
                          width: tileWidth,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 86),
                            child: tile,
                          ),
                        ),
                      )
                      .toList(growable: false),
                );
              },
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppUiConstants.spacingMd,
                vertical: AppUiConstants.spacingSm,
              ),
              decoration: BoxDecoration(
                color: appTheme.subtleFill.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
              ),
              child: Text(
                _amountInWords(total),
                textAlign: TextAlign.right,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: appTheme.mutedText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GstLineTaxPreview extends StatelessWidget {
  const GstLineTaxPreview({
    super.key,
    required this.gross,
    required this.taxable,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.cess,
    required this.total,
    required this.currencyCode,
    this.taxCodeLabel,
  });

  final double gross;
  final double taxable;
  final double cgst;
  final double sgst;
  final double igst;
  final double cess;
  final double total;
  final String currencyCode;
  final String? taxCodeLabel;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
