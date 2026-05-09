import '../../screen.dart';
import '../dashboard/erp_module_dashboard_page.dart';

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
