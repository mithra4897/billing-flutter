import '../screen.dart';

Future<bool?> promptUseSupplierAdvance(
  BuildContext context, {
  required double availableAmount,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
      ),
      title: const Text('Use supplier advance?'),
      content: SizedBox(
        width: 420,
        child: Text(
          'This supplier has ₹${formatAmount(availableAmount)} available from '
          'earlier payments. Do you want to use the oldest advance against '
          'outstanding invoices now?',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('No, keep advance'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Yes, use advance'),
        ),
      ],
    ),
  );
}
