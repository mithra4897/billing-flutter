import '../../screen.dart';

class ProjectDashboardPage extends StatelessWidget {
  const ProjectDashboardPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return ErpModuleDashboardPage(
      moduleKey: 'projects',
      embedded: embedded,
      shellTitle: 'Projects Dashboard',
    );
  }
}
