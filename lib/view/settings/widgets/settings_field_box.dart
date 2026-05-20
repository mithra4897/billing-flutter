import '../../../screen.dart';

class SettingsFieldBox extends StatelessWidget {
  const SettingsFieldBox({super.key, required this.child, this.width = 260});

  final Widget child;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return AppFieldBox(width: width, child: child);
  }
}
