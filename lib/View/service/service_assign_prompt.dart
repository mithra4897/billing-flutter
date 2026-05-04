import '../../screen.dart';

typedef ServiceAssignResult = ({bool submitted, int? assignedToUserId});

/// [submitted] is false when the dialog was dismissed without confirming.
/// When confirmed with an empty user id field, [assignedToUserId] is null (assign to self).
Future<ServiceAssignResult> promptServiceAssigneeUserId(
  BuildContext context,
) async {
  final controller = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Assign'),
      content: SizedBox(
        width: 400,
        child: AppFormTextField(
          labelText: 'Assign to user ID',
          controller: controller,
          hintText: 'Leave blank to assign to yourself',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Assign'),
        ),
      ],
    ),
  );
  if (ok != true) {
    return (submitted: false, assignedToUserId: null);
  }
  final raw = controller.text.trim();
  if (raw.isEmpty) {
    return (submitted: true, assignedToUserId: null);
  }
  return (
    submitted: true,
    assignedToUserId: int.tryParse(raw),
  );
}
