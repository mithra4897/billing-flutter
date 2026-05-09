import '../../screen.dart';
import 'erp_module_dashboard_support.dart';

class ErpModuleDashboardPage extends StatefulWidget {
  const ErpModuleDashboardPage({
    super.key,
    required this.moduleKey,
    this.embedded = false,
    this.loader,
    this.shellTitle,
  });

  final String moduleKey;
  final bool embedded;
  final Future<ErpDashboardSnapshot> Function()? loader;
  final String? shellTitle;

  @override
  State<ErpModuleDashboardPage> createState() => _ErpModuleDashboardPageState();
}

class _ErpModuleDashboardPageState extends State<ErpModuleDashboardPage> {
  late Future<ErpDashboardSnapshot> _snapshotFuture;

  @override
  void initState() {
    super.initState();
    _snapshotFuture = _loadSnapshot();
  }

  @override
  void didUpdateWidget(covariant ErpModuleDashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.moduleKey != widget.moduleKey ||
        oldWidget.loader != widget.loader) {
      _snapshotFuture = _loadSnapshot();
    }
  }

  Future<ErpDashboardSnapshot> _loadSnapshot() {
    return widget.loader?.call() ?? loadErpDashboardSnapshot(widget.moduleKey);
  }

  void _reload() {
    setState(() {
      _snapshotFuture = _loadSnapshot();
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = FutureBuilder<ErpDashboardSnapshot>(
      future: _snapshotFuture,
      builder: (context, snapshot) {
        final body = switch (snapshot.connectionState) {
          ConnectionState.waiting || ConnectionState.active => AppLoadingView(
            message: 'Loading ${widget.shellTitle ?? "module"} dashboard...',
          ),
          _ when snapshot.hasError => AppErrorStateView(
            title: 'Unable to load dashboard',
            message: snapshot.error.toString(),
            onRetry: _reload,
          ),
          _ => SingleChildScrollView(
            padding: const EdgeInsets.all(AppUiConstants.pagePadding),
            child: ErpModuleDashboard(
              snapshot:
                  snapshot.data ??
                  ErpDashboardSnapshot(
                    title: widget.shellTitle ?? 'Module Dashboard',
                    subtitle: 'No dashboard data available.',
                  ),
            ),
          ),
        };

        return body;
      },
    );

    if (widget.embedded) {
      return content;
    }

    return FutureBuilder<PublicBrandingModel?>(
      future: SessionStorage.getBranding(),
      builder: (context, snapshot) {
        final branding =
            snapshot.data ??
            const PublicBrandingModel(companyName: 'Billing ERP');
        return AdaptiveShell(
          title: widget.shellTitle ?? 'Dashboard',
          branding: branding,
          child: content,
        );
      },
    );
  }
}
