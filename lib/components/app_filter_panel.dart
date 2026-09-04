import '../screen.dart';

Future<T?> showAppFilterPanel<T>({
  required BuildContext context,
  required String title,
  required WidgetBuilder builder,
  double maxWidth = 920,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close filters',
    barrierColor: Colors.black.withValues(alpha: 0.18),
    builder: (dialogContext) => AppDialog(
      title: title,
      maxWidth: maxWidth,
      child: builder(dialogContext),
    ),
  );
}
