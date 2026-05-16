import 'package:flutter/material.dart';

import '../app/constants/app_ui_constants.dart';
import '../app/theme/app_theme_extension.dart';
import 'app_section_card.dart';

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
    final normalized = amount.isNegative ? 0 : amount;
    final whole = normalized.floor();
    final fraction = ((normalized - whole) * 100).round();
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
              ? colorScheme.primary.withValues(alpha: 0.08)
              : appTheme.subtleFill.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(AppUiConstants.spacingSm),
          border: Border.all(
            color: emphasize
                ? colorScheme.primary.withValues(alpha: 0.18)
                : colorScheme.outline.withValues(alpha: 0.12),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppUiConstants.spacingMd,
            vertical: AppUiConstants.spacingSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                textAlign: TextAlign.right,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: appTheme.mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppUiConstants.spacingXs),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final columns = width >= 900
                    ? 3
                    : width >= 560
                    ? 2
                    : 1;
                final ratio = width >= 900
                    ? 3.3
                    : width >= 560
                    ? 2.9
                    : 4.2;

                return GridView.count(
                  crossAxisCount: columns,
                  crossAxisSpacing: AppUiConstants.spacingSm,
                  mainAxisSpacing: AppUiConstants.spacingSm,
                  childAspectRatio: ratio,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    metric('Taxable', taxable),
                    metric('CGST', cgst),
                    metric('SGST', sgst),
                    metric('IGST', igst),
                    metric('CESS', cess),
                    metric('Grand Total', total, emphasize: true),
                  ],
                );
              },
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
            Text(
              _amountInWords(total),
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: appTheme.mutedText,
                fontWeight: FontWeight.w600,
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
