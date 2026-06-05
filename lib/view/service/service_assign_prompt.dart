import '../../screen.dart';

typedef ServiceAssignResult = ({bool submitted, int? assignedToUserId});

/// [submitted] is false when the dialog was dismissed without confirming.
/// When confirmed with "Assign to myself", [assignedToUserId] is null.
Future<ServiceAssignResult> promptServiceAssigneeUserId(
  BuildContext context,
  List<UserModel> users, {
  int? initialUserId,
}) async {
  var selectedUserId = initialUserId;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Assign'),
      content: SizedBox(
        width: 400,
        child: AppDropdownField<int?>.fromMapped(
          labelText: 'Assign to',
          mappedItems: [
            const AppDropdownItem<int?>(value: null, label: 'Assign to myself'),
            ...users
                .where((user) => user.id != null)
                .map(
                  (user) => AppDropdownItem<int?>(
                    value: user.id!,
                    label: user.toString(),
                  ),
                ),
          ],
          initialValue: selectedUserId,
          onChanged: (value) {
            selectedUserId = value;
          },
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
  return (submitted: true, assignedToUserId: selectedUserId);
}
