import '../screen.dart';

Future<String?> promptCancellationReason(
  BuildContext context, {
  required String title,
  required String subjectLabel,
  String? warningMessage,
  String confirmLabel = 'Confirm cancel',
}) async {
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);

      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
        ),
        title: Text(title),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter the cancellation reason for $subjectLabel.',
                  style: theme.textTheme.bodyMedium,
                ),
                if (warningMessage != null && warningMessage.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: AppUiConstants.spacingMd,
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppUiConstants.spacingSm),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(
                          AppUiConstants.fieldRadius,
                        ),
                      ),
                      child: Text(
                        warningMessage,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: AppUiConstants.spacingMd),
                AppFormTextField(
                  labelText: 'Cancellation Reason',
                  controller: controller,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  validator: Validators.compose([
                    Validators.required('Cancellation Reason'),
                    Validators.optionalMaxLength(500, 'Cancellation Reason'),
                  ]),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () {
              final form = formKey.currentState;
              if (form == null || !form.validate()) {
                return;
              }
              Navigator.of(dialogContext).pop(controller.text.trim());
            },
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );

  return result;
}
