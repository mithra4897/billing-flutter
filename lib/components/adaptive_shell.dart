import 'package:flutter/material.dart';

import '../app/constants/app_ui_constants.dart';
import '../app/navigation/app_navigation.dart';
import '../app/theme/app_theme_extension.dart';
import '../core/storage/session_storage.dart';
import '../model/app/public_branding_model.dart';
import '../model/auth/module_model.dart';
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
  bool _isSuperAdmin = false;
  Set<String> _permissionCodes = const <String>{};
  List<ModuleModel> _orderedModules = const <ModuleModel>[];
  final Set<String> _expandedGroups = <String>{};

  @override
  void initState() {
    super.initState();
    _loadAccess();
  }

  Future<void> _loadAccess() async {
    final permissionCodes = await SessionStorage.getPermissionCodes();
    final currentUser = await SessionStorage.getCurrentUser();
    final authContext = await SessionStorage.getAuthContext();

    if (!mounted) {
      return;
    }

    setState(() {
      _permissionCodes = permissionCodes.toSet();
      _isSuperAdmin =
          currentUser?['is_super_admin'] == true ||
          currentUser?['is_super_admin'] == 1;
      _orderedModules = authContext?.menuModules ?? const <ModuleModel>[];
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appTheme = theme.extension<AppThemeExtension>()!;
    final width = MediaQuery.of(context).size.width;
    final showPermanentDrawer = width >= 768;
    final currentPath = _currentPath;
    final visibleMenu = AppNavigation.visibleMenu(
      permissionCodes: _permissionCodes,
      isSuperAdmin: _isSuperAdmin,
      orderedModules: _orderedModules,
    );

    return Scaffold(
      drawer: showPermanentDrawer
          ? null
          : Drawer(
              backgroundColor: appTheme.mobileDrawerBackground,
              surfaceTintColor: Colors.transparent,
              child: _buildDrawer(
                items: visibleMenu,
                currentPath: currentPath,
                showPermanentDrawer: false,
                backgroundColor: appTheme.mobileDrawerBackground,
                foregroundColor: appTheme.mobileDrawerForeground,
                mutedColor: appTheme.mobileDrawerMuted,
                selectedBackground: colorScheme.primary.withValues(alpha: 0.12),
                selectedForeground: colorScheme.primary,
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
                  items: visibleMenu,
                  currentPath: currentPath,
                  collapsed: !_drawerExpanded,
                  showPermanentDrawer: true,
                  backgroundColor: appTheme.desktopDrawerBackground,
                  foregroundColor: appTheme.desktopDrawerForeground,
                  mutedColor: appTheme.desktopDrawerMuted,
                  selectedBackground: Colors.white.withValues(alpha: 0.12),
                  selectedForeground: appTheme.desktopDrawerForeground,
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
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Text(
                              '${widget.branding.currentYear ?? DateTime.now().year} ${widget.branding.companyName}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: appTheme.mutedText,
                              ),
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

  String get _currentPath {
    final routeName = ModalRoute.of(context)?.settings.name ?? '/dashboard';
    return Uri.parse(routeName).path;
  }

  Widget _buildDrawer({
    required List<AppNavigationItem> items,
    required String currentPath,
    bool collapsed = false,
    required bool showPermanentDrawer,
    required Color backgroundColor,
    required Color foregroundColor,
    required Color mutedColor,
    required Color selectedBackground,
    required Color selectedForeground,
  }) {
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
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              children: [
                for (final item in items)
                  _buildNavigationItem(
                    item: item,
                    currentPath: currentPath,
                    collapsed: collapsed,
                    showPermanentDrawer: showPermanentDrawer,
                    foregroundColor: foregroundColor,
                    mutedColor: mutedColor,
                    selectedBackground: selectedBackground,
                    selectedForeground: selectedForeground,
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: _buildLeafTile(
              icon: Icons.logout,
              label: 'Logout',
              collapsed: collapsed,
              foregroundColor: foregroundColor,
              mutedColor: mutedColor,
              selected: false,
              selectedBackground: selectedBackground,
              selectedForeground: selectedForeground,
              onTap: widget.onLogout,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItem({
    required AppNavigationItem item,
    required String currentPath,
    required bool collapsed,
    required bool showPermanentDrawer,
    required Color foregroundColor,
    required Color mutedColor,
    required Color selectedBackground,
    required Color selectedForeground,
  }) {
    final isSelected = item.path != null && item.path == currentPath;

    if (!item.hasChildren) {
      return _buildLeafTile(
        icon: item.icon,
        label: item.title,
        collapsed: collapsed,
        foregroundColor: foregroundColor,
        mutedColor: mutedColor,
        selected: isSelected,
        selectedBackground: selectedBackground,
        selectedForeground: selectedForeground,
        onTap: () => _handleRouteTap(
          item.path!,
          showPermanentDrawer: showPermanentDrawer,
        ),
      );
    }

    final containsCurrentPath = AppNavigation.containsPath(item, currentPath);
    final isExpanded =
        !collapsed &&
        (_expandedGroups.contains(item.key) || containsCurrentPath);

    if (collapsed) {
      return _buildLeafTile(
        icon: item.icon,
        label: item.title,
        collapsed: true,
        foregroundColor: foregroundColor,
        mutedColor: mutedColor,
        selected: containsCurrentPath,
        selectedBackground: selectedBackground,
        selectedForeground: selectedForeground,
        onTap: () {
          setState(() {
            _drawerExpanded = true;
            _expandedGroups.add(item.key);
          });
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppUiConstants.buttonRadius),
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedGroups.remove(item.key);
                  } else {
                    _expandedGroups.add(item.key);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: containsCurrentPath ? selectedBackground : null,
                  borderRadius: BorderRadius.circular(
                    AppUiConstants.buttonRadius,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      item.icon,
                      size: 20,
                      color: containsCurrentPath
                          ? selectedForeground
                          : foregroundColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: containsCurrentPath
                              ? selectedForeground
                              : foregroundColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: containsCurrentPath
                          ? selectedForeground
                          : mutedColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 14, top: 4),
              child: Column(
                children: [
                  for (final child in item.children)
                    _buildLeafTile(
                      icon: child.icon,
                      label: child.title,
                      collapsed: false,
                      dense: true,
                      foregroundColor: foregroundColor,
                      mutedColor: mutedColor,
                      selected: child.path == currentPath,
                      selectedBackground: selectedBackground,
                      selectedForeground: selectedForeground,
                      onTap: () => _handleRouteTap(
                        child.path!,
                        showPermanentDrawer: showPermanentDrawer,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLeafTile({
    required IconData icon,
    required String label,
    required bool collapsed,
    required Color foregroundColor,
    required Color mutedColor,
    required bool selected,
    required Color selectedBackground,
    required Color selectedForeground,
    required VoidCallback onTap,
    bool dense = false,
  }) {
    final color = selected ? selectedForeground : foregroundColor;

    return Padding(
      padding: EdgeInsets.only(bottom: dense ? 2 : 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppUiConstants.buttonRadius),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: dense ? 10 : 12,
            ),
            decoration: BoxDecoration(
              color: selected ? selectedBackground : null,
              borderRadius: BorderRadius.circular(AppUiConstants.buttonRadius),
            ),
            child: Row(
              children: [
                Icon(icon, size: dense ? 18 : 20, color: color),
                if (!collapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: color,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                if (collapsed)
                  const SizedBox(width: 0, height: 0)
                else if (dense)
                  Icon(Icons.chevron_right, size: 16, color: mutedColor),
              ],
            ),
          ),
        ),
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
