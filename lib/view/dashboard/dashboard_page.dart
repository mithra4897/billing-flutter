import '../../screen.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final content = _DashboardContent();
    if (embedded) {
      return content;
    }

    return FutureBuilder<PublicBrandingModel?>(
      future: SessionStorage.getBranding(),
      builder: (context, snapshot) {
        final branding =
            snapshot.data ??
            const PublicBrandingModel(companyName: 'Billing ERP');

        return AdaptiveShell(
          title: 'Dashboard',
          branding: branding,
          child: content,
        );
      },
    );
  }
}

class _DashboardContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;

    return Padding(
      padding: const EdgeInsets.all(AppUiConstants.pagePadding),
      child: AppSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
            Text(
              'Responsive shell, routing, branding, and session bootstrap are now in place. Module screens can plug into this layout next.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: appTheme.mutedText),
            ),
          ],
        ),
      ),
    );
  }
}
