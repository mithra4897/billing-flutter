import '../../screen.dart';

class ModulePlaceholderPage extends StatelessWidget {
  const ModulePlaceholderPage({
    super.key,
    required this.path,
    this.queryParameters = const <String, String>{},
    this.embedded = false,
  });

  final String path;
  final Map<String, String> queryParameters;
  final bool embedded;

  Future<void> _logout(BuildContext context) async {
    await AppSessionService.instance.clearSession();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final route = AppNavigation.findByPath(path);
    final content = _ModulePlaceholderContent(
      path: path,
      queryParameters: queryParameters,
      title: route?.title ?? 'Module',
    );

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
          title: route?.title ?? 'Module',
          branding: branding,
          onLogout: () => _logout(context),
          child: content,
        );
      },
    );
  }
}

class _ModulePlaceholderContent extends StatelessWidget {
  const _ModulePlaceholderContent({
    required this.path,
    required this.queryParameters,
    required this.title,
  });

  final String path;
  final Map<String, String> queryParameters;
  final String title;

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;
    return Padding(
      padding: const EdgeInsets.all(AppUiConstants.pagePadding),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: appTheme.cardBackground,
          borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
          boxShadow: [
            BoxShadow(
              color: appTheme.cardShadow,
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppUiConstants.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The route shell and permission-aware navigation are ready. This module page can now be built on top of the typed services and models already prepared.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: appTheme.mutedText,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              _InfoRow(label: 'Route Path', value: path),
              if (queryParameters.isNotEmpty) ...[
                const SizedBox(height: 12),
                _InfoRow(
                  label: 'Query Parameters',
                  value: queryParameters.entries
                      .map((entry) => '${entry.key}=${entry.value}')
                      .join(', '),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;

    return RichText(
      text: TextSpan(
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: appTheme.mutedText),
        children: [
          TextSpan(
            text: '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}
