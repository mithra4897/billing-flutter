import '../screen.dart';

Future<bool?> promptUseSupplierAdvance(
  BuildContext context, {
  required double availableAmount,
}) {
  return _promptUseAdvance(
    context,
    title: 'Use supplier advance?',
    message:
        'This supplier has ₹${formatAmount(availableAmount)} available from '
        'earlier payments. Use the oldest advance for this invoice?',
    keepLabel: 'No, keep advance',
    useLabel: 'Yes, use advance',
  );
}

Future<bool?> promptUseCustomerAdvance(
  BuildContext context, {
  required double availableAmount,
}) {
  return _promptUseAdvance(
    context,
    title: 'Use customer advance?',
    message:
        'This customer has ₹${formatAmount(availableAmount)} available from '
        'earlier receipts. Use the oldest advance for this invoice?',
    keepLabel: 'No, keep advance',
    useLabel: 'Yes, use advance',
  );
}

Future<bool?> _promptUseAdvance(
  BuildContext context, {
  required String title,
  required String message,
  required String keepLabel,
  required String useLabel,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
      ),
      title: Text(title),
      content: SizedBox(width: 420, child: Text(message)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(keepLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(useLabel),
        ),
      ],
    ),
  );
}
