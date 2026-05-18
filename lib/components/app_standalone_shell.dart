import '../screen.dart';

class AppStandaloneShell extends StatelessWidget {
  const AppStandaloneShell({
    super.key,
    required this.title,
    required this.scrollController,
    required this.actions,
    required this.child,
  });

  final String title;
  final ScrollController scrollController;
  final List<Widget> actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PublicBrandingModel?>(
      future: SessionStorage.getBranding(),
      builder: (context, snapshot) {
        final branding =
            snapshot.data ??
            const PublicBrandingModel(companyName: 'Billing ERP');

        return AdaptiveShell(
          title: title,
          branding: branding,
          scrollController: scrollController,
          actions: actions,
          child: child,
        );
      },
    );
  }
}
