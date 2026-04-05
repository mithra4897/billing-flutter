import 'package:flutter/material.dart';

import '../app/constants/app_ui_constants.dart';
import '../app/theme/app_theme_extension.dart';
import '../model/app/public_branding_model.dart';
import 'app_branding_logo.dart';

class AdaptiveShell extends StatefulWidget {
  const AdaptiveShell({
    super.key,
    required this.title,
    required this.branding,
    required this.child,
    required this.onLogout,
  });

  final String title;
  final PublicBrandingModel branding;
  final Widget child;
  final VoidCallback onLogout;

  @override
  State<AdaptiveShell> createState() => _AdaptiveShellState();
}

class _AdaptiveShellState extends State<AdaptiveShell> {
  bool _drawerExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppThemeExtension>()!;
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1100;
    final isTablet = width >= 768;
    final showPermanentDrawer = isTablet || isDesktop;

    return Scaffold(
      drawer: showPermanentDrawer
          ? null
          : Drawer(
              backgroundColor: appTheme.mobileDrawerBackground,
              surfaceTintColor: Colors.transparent,
              child: _buildDrawer(
                showPermanentDrawer: false,
                backgroundColor: appTheme.mobileDrawerBackground,
                foregroundColor: appTheme.mobileDrawerForeground,
                mutedColor: appTheme.mobileDrawerMuted,
              ),
            ),
      body: Row(
        children: [
          if (showPermanentDrawer)
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: _drawerExpanded
                  ? AppUiConstants.shellExpandedDrawerWidth
                  : AppUiConstants.shellCollapsedDrawerWidth,
              child: Material(
                color: appTheme.desktopDrawerBackground,
                child: _buildDrawer(
                  collapsed: !_drawerExpanded,
                  showPermanentDrawer: true,
                  backgroundColor: appTheme.desktopDrawerBackground,
                  foregroundColor: appTheme.desktopDrawerForeground,
                  mutedColor: appTheme.desktopDrawerMuted,
                ),
              ),
            ),
          Expanded(
            child: Column(
              children: [
                Material(
                  color: appTheme.shellHeaderBackground,
                  elevation: 1,
                  child: SafeArea(
                    bottom: false,
                    child: SizedBox(
                      height: AppUiConstants.shellHeaderHeight,
                      child: Row(
                        children: [
                          if (!showPermanentDrawer)
                            Builder(
                              builder: (context) => IconButton(
                                icon: const Icon(Icons.menu),
                                onPressed: () =>
                                    Scaffold.of(context).openDrawer(),
                              ),
                            )
                          else
                            IconButton(
                              icon: Icon(
                                _drawerExpanded ? Icons.menu_open : Icons.menu,
                              ),
                              onPressed: () {
                                setState(() {
                                  _drawerExpanded = !_drawerExpanded;
                                });
                              },
                            ),
                          Expanded(
                            child: Text(
                              widget.title,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Text(
                              '${widget.branding.currentYear ?? DateTime.now().year} ${widget.branding.companyName}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer({
    bool collapsed = false,
    required bool showPermanentDrawer,
    required Color backgroundColor,
    required Color foregroundColor,
    required Color mutedColor,
  }) {
    final items = <({IconData icon, String label, String route})>[
      (icon: Icons.dashboard_outlined, label: 'Dashboard', route: '/dashboard'),
    ];

    return ColoredBox(
      color: backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: collapsed
                  ? Center(
                      child: AppBrandingLogo(
                        branding: widget.branding,
                        showName: false,
                        size: 42,
                        textColor: foregroundColor,
                      ),
                    )
                  : AppBrandingLogo(
                      branding: widget.branding,
                      size: 42,
                      textColor: foregroundColor,
                    ),
            ),
          ),
          const SizedBox(height: 12),
          for (final item in items)
            ListTile(
              leading: Icon(item.icon, color: foregroundColor),
              title: collapsed
                  ? null
                  : Text(
                      item.label,
                      style: TextStyle(
                        color: foregroundColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
              subtitle: collapsed
                  ? null
                  : Text(
                      item.route,
                      style: TextStyle(color: mutedColor, fontSize: 12),
                    ),
              onTap: () => _handleRouteTap(
                item.route,
                showPermanentDrawer: showPermanentDrawer,
              ),
            ),
          const Spacer(),
          ListTile(
            leading: Icon(Icons.logout, color: foregroundColor),
            title: collapsed
                ? null
                : Text(
                    'Logout',
                    style: TextStyle(
                      color: foregroundColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
            onTap: widget.onLogout,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _handleRouteTap(String route, {required bool showPermanentDrawer}) {
    final currentName = ModalRoute.of(context)?.settings.name;
    final currentUri = currentName == null ? null : Uri.parse(currentName);
    final targetUri = Uri.parse(route);
    final isSameRoute =
        currentUri?.path == targetUri.path &&
        currentUri?.query == targetUri.query;

    if (!showPermanentDrawer) {
      Navigator.of(context).pop();
    }

    if (isSameRoute) {
      return;
    }

    Navigator.of(context).pushReplacementNamed(route);
  }
}
