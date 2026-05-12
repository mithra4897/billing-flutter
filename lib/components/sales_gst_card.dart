import 'package:flutter/material.dart';

import '../app/constants/app_ui_constants.dart';
import '../app/theme/app_theme_extension.dart';
import 'app_section_card.dart';

class SalesGstSummaryCard extends StatelessWidget {
  const SalesGstSummaryCard({
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppThemeExtension>()!;

    Widget metric(String label, double value, {bool emphasize = false}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: appTheme.mutedText,
            ),
          ),
          const SizedBox(height: AppUiConstants.spacingXs),
          Text(
            value.toStringAsFixed(2),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w700,
              color: emphasize ? theme.colorScheme.primary : null,
            ),
          ),
        ],
      );
    }

    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GST Summary',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppUiConstants.spacingXs),
          Text(
            subtitle == null || subtitle!.trim().isEmpty
                ? 'Live GST totals for the current lines in $currencyCode'
                : subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: appTheme.mutedText,
            ),
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          Wrap(
            spacing: AppUiConstants.spacingLg,
            runSpacing: AppUiConstants.spacingMd,
            children: [
              metric('Taxable', taxable),
              metric('CGST', cgst),
              metric('SGST', sgst),
              metric('IGST', igst),
              metric('CESS', cess),
              metric('Total', total, emphasize: true),
            ],
          ),
        ],
      ),
    );
  }
}

class SalesLineTaxPreview extends StatelessWidget {
  const SalesLineTaxPreview({
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
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppThemeExtension>()!;
    final pieces = <String>[
      'Gross ${gross.toStringAsFixed(2)}',
      'Taxable ${taxable.toStringAsFixed(2)}',
      if (cgst > 0) 'CGST ${cgst.toStringAsFixed(2)}',
      if (sgst > 0) 'SGST ${sgst.toStringAsFixed(2)}',
      if (igst > 0) 'IGST ${igst.toStringAsFixed(2)}',
      if (cess > 0) 'CESS ${cess.toStringAsFixed(2)}',
      'Line total ${total.toStringAsFixed(2)}',
      currencyCode,
    ];
    if (taxCodeLabel != null && taxCodeLabel!.trim().isNotEmpty) {
      pieces.insert(0, taxCodeLabel!.trim());
    }

    return Text(
      pieces.join(' · '),
      style: theme.textTheme.bodySmall?.copyWith(color: appTheme.mutedText),
    );
  }
}
