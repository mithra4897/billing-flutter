import 'package:flutter/material.dart';

import '../../app/constants/app_ui_constants.dart';
import '../../app/theme/app_theme_extension.dart';
import '../../components/adaptive_shell.dart';
import '../../core/storage/session_storage.dart';
import '../../model/app/public_branding_model.dart';
import '../../service/app/app_session_service.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, this.embedded = false});

  final bool embedded;

  Future<void> _logout(BuildContext context) async {
    await AppSessionService.instance.clearSession();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

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
          onLogout: () => _logout(context),
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
                'Welcome',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Responsive shell, routing, branding, and session bootstrap are now in place. Module screens can plug into this layout next.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: appTheme.mutedText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
