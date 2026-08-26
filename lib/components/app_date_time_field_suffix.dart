import '../screen.dart';

class AppDateTimeFieldSuffix extends StatelessWidget {
  const AppDateTimeFieldSuffix({
    super.key,
    required this.controller,
    required this.onCleared,
  });

  final TextEditingController controller;
  final VoidCallback onCleared;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (controller.text.trim().isNotEmpty)
          IconButton(
            tooltip: 'Clear date',
            onPressed: () {
              controller.clear();
              onCleared();
            },
            icon: const Icon(Icons.clear, size: 18),
          ),
        const Icon(Icons.schedule_outlined, size: 18),
        const SizedBox(width: 12),
      ],
    );
  }
}
