import '../../screen.dart';

class CrmDashboardPage extends StatelessWidget {
  const CrmDashboardPage({
    super.key,
    this.embedded = false,
    this.crmService,
    this.now,
  });

  final bool embedded;
  final CrmService? crmService;
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context) {
    return ErpModuleDashboardPage(
      moduleKey: 'crm',
      embedded: embedded,
      shellTitle: 'CRM Dashboard',
      loader: (trendFilter) => buildCrmDashboardSnapshot(
        crmService: crmService ?? CrmService(),
        now: now ?? DateTime.now,
        trendFilter: trendFilter,
      ),
    );
  }
}
