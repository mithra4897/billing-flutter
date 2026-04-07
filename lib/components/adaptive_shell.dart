import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';

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
    this.actions = const <Widget>[],
    this.actionsListenable,
    this.scrollController,
    this.mobileAutoHideHeader = true,
    this.onNavigate,
    this.currentPath,
  });

  final String title;
  final PublicBrandingModel branding;
  final Widget child;
  final VoidCallback onLogout;
  final List<Widget> actions;
  final ValueListenable<List<Widget>>? actionsListenable;
  final ScrollController? scrollController;
  final bool mobileAutoHideHeader;
  final ValueChanged<String>? onNavigate;
  final String? currentPath;

  @override
  State<AdaptiveShell> createState() => _AdaptiveShellState();
}

class AdaptiveShellActionButton extends StatelessWidget {
  const AdaptiveShellActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 600;
    final child = compact
        ? Icon(icon, size: 20)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(label),
            ],
          );

    final button = filled
        ? FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              minimumSize: const Size(44, 44),
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 0 : 14,
                vertical: 10,
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppUiConstants.buttonRadius,
                ),
              ),
            ),
            child: child,
          )
        : OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(44, 44),
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 0 : 14,
                vertical: 10,
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppUiConstants.buttonRadius,
                ),
              ),
            ),
            child: child,
          );

    return Tooltip(message: label, child: button);
  }
}

class AdaptiveShellMenuAction<T> extends StatelessWidget {
  const AdaptiveShellMenuAction({
    super.key,
    required this.icon,
    required this.label,
    required this.itemBuilder,
    required this.onSelected,
    this.filled = false,
    this.tooltip,
  });

  final IconData icon;
  final String label;
  final PopupMenuItemBuilder<T> itemBuilder;
  final PopupMenuItemSelected<T> onSelected;
  final bool filled;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 600;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appTheme = theme.extension<AppThemeExtension>()!;

    final child = Container(
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 14, vertical: 10),
      decoration: BoxDecoration(
        color: filled ? colorScheme.primary : colorScheme.surface,
        borderRadius: BorderRadius.circular(AppUiConstants.buttonRadius),
        border: filled
            ? null
            : Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
        boxShadow: filled
            ? [
                BoxShadow(
                  color: appTheme.cardShadow,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: filled ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
          if (!compact) ...[
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: filled ? colorScheme.onPrimary : colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );

    return Tooltip(
      message: tooltip ?? label,
      child: PopupMenuButton<T>(
        tooltip: tooltip ?? label,
        onSelected: onSelected,
        itemBuilder: itemBuilder,
        child: child,
      ),
    );
  }
}

class _AdaptiveShellState extends State<AdaptiveShell> {
  bool _drawerExpanded = true;
  bool _isSuperAdmin = false;
  Set<String> _permissionCodes = const <String>{};
  List<ModuleModel> _orderedModules = const <ModuleModel>[];
  final Map<String, bool> _groupExpansionOverrides = <String, bool>{};
  final ScrollController _drawerScrollController = ScrollController();
  final GlobalKey _drawerListKey = GlobalKey();
  final Map<String, GlobalKey> _menuKeys = <String, GlobalKey>{};
  final Map<String, GlobalKey> _groupKeys = <String, GlobalKey>{};
  String? _lastSyncedPath;
  bool _showMobileHeader = true;

  @override
  void initState() {
    super.initState();
    _loadAccess();
    _bindScrollController(widget.scrollController);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMenuStateForCurrentRoute();
  }

  @override
  void dispose() {
    _unbindScrollController(widget.scrollController);
    _drawerScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AdaptiveShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      _unbindScrollController(oldWidget.scrollController);
      _bindScrollController(widget.scrollController);
    }
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
    final actionBar = widget.actionsListenable == null
        ? _buildHeaderActions(widget.actions)
        : ValueListenableBuilder<List<Widget>>(
            valueListenable: widget.actionsListenable!,
            builder: (context, actions, _) => _buildHeaderActions(actions),
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
                ClipRect(
                  child: AnimatedSlide(
                    offset:
                        !showPermanentDrawer &&
                            widget.mobileAutoHideHeader &&
                            !_showMobileHeader
                        ? const Offset(0, -1)
                        : Offset.zero,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height:
                          !showPermanentDrawer &&
                              widget.mobileAutoHideHeader &&
                              !_showMobileHeader
                          ? 0
                          : AppUiConstants.shellHeaderHeight +
                                MediaQuery.of(context).padding.top,
                      child: Material(
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
                                      _drawerExpanded
                                          ? Icons.menu_open
                                          : Icons.menu,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _drawerExpanded = !_drawerExpanded;
                                      });
                                    },
                                  ),
                                Expanded(
                                  child: _AdaptiveShellTitle(
                                    title: widget.title,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                actionBar,
                              ],
                            ),
                          ),
                        ),
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
    if ((widget.currentPath ?? '').isNotEmpty) {
      return Uri.parse(widget.currentPath!).path;
    }
    final routeName = ModalRoute.of(context)?.settings.name ?? '/dashboard';
    return Uri.parse(routeName).path;
  }

  Widget _buildHeaderActions(List<Widget> actions) {
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: actions
              .map(
                (action) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: action,
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
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
              key: _drawerListKey,
              controller: _drawerScrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              children: [
                for (final item in items)
                  _buildNavigationItem(
                    item: item,
                    currentPath: currentPath,
                    depth: 0,
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
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildNavigationItem({
    required AppNavigationItem item,
    required String currentPath,
    required int depth,
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
        key: _menuKey(item.key),
        icon: item.icon,
        label: item.title,
        depth: depth,
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
        (_groupExpansionOverrides[item.key] ?? containsCurrentPath);

    if (collapsed) {
      return _buildLeafTile(
        key: _menuKey(item.key),
        icon: item.icon,
        label: item.title,
        depth: depth,
        collapsed: true,
        foregroundColor: foregroundColor,
        mutedColor: mutedColor,
        selected: containsCurrentPath,
        selectedBackground: selectedBackground,
        selectedForeground: selectedForeground,
        onTap: () {
          setState(() {
            _drawerExpanded = true;
            _expandGroup(item.key, currentPath: currentPath);
          });
          _scheduleExpandedGroupVisibility(item.key);
        },
      );
    }

    return Padding(
      key: _groupKey(item.key),
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            key: _menuKey(item.key),
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppUiConstants.buttonRadius),
              onTap: () {
                final nextExpanded = !isExpanded;
                setState(() {
                  if (nextExpanded) {
                    _expandGroup(item.key, currentPath: currentPath);
                  } else {
                    _groupExpansionOverrides[item.key] = false;
                  }
                });
                if (nextExpanded) {
                  _scheduleExpandedGroupVisibility(item.key);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                margin: EdgeInsets.only(left: depth * 12.0),
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
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                children: [
                  for (final child in item.children)
                    _buildNavigationItem(
                      item: child,
                      currentPath: currentPath,
                      depth: depth + 1,
                      collapsed: false,
                      showPermanentDrawer: showPermanentDrawer,
                      foregroundColor: foregroundColor,
                      mutedColor: mutedColor,
                      selectedBackground: selectedBackground,
                      selectedForeground: selectedForeground,
                    ),
                  if (item.key == 'settings')
                    _buildLeafTile(
                      key: _menuKey('settings-logout'),
                      icon: Icons.logout,
                      label: 'Logout',
                      depth: depth + 1,
                      collapsed: false,
                      foregroundColor: foregroundColor,
                      mutedColor: mutedColor,
                      selected: false,
                      selectedBackground: selectedBackground,
                      selectedForeground: selectedForeground,
                      onTap: widget.onLogout,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLeafTile({
    Key? key,
    required IconData icon,
    required String label,
    required int depth,
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
        key: key,
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppUiConstants.buttonRadius),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: dense ? 10 : 12,
            ),
            margin: EdgeInsets.only(left: collapsed ? 0 : depth * 12.0),
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
    final currentUri = (widget.currentPath ?? '').isNotEmpty
        ? Uri.parse(widget.currentPath!)
        : (currentName == null ? null : Uri.parse(currentName));
    final targetUri = Uri.parse(route);
    final isSameRoute =
        currentUri?.path == targetUri.path &&
        currentUri?.query == targetUri.query;

    _syncExpandedParentsForRoute(targetUri.path);

    if (!showPermanentDrawer) {
      Navigator.of(context).pop();
    }

    if (isSameRoute) {
      return;
    }

    if (widget.onNavigate != null) {
      widget.onNavigate!(route);
      return;
    }

    Navigator.of(context).pushReplacementNamed(route);
  }

  void _syncExpandedParentsForRoute(String path) {
    final ancestorKeys = AppNavigation.ancestorKeysForPath(path);

    setState(() {
      _replaceExpandedOverrides(ancestorKeys);
    });
  }

  void _syncMenuStateForCurrentRoute() {
    final currentPath = _currentPath;
    if (_lastSyncedPath == currentPath) {
      return;
    }

    _replaceExpandedOverrides(AppNavigation.ancestorKeysForPath(currentPath));

    _lastSyncedPath = currentPath;
  }

  void _expandGroup(String key, {required String currentPath}) {
    final keysToKeep = <String>{
      ...AppNavigation.ancestorKeysForPath(currentPath),
      ...AppNavigation.ancestorKeysForItemKey(key),
      key,
    };

    _replaceExpandedOverrides(keysToKeep);
  }

  void _replaceExpandedOverrides(Iterable<String> expandedKeys) {
    _groupExpansionOverrides
      ..clear()
      ..addEntries(
        expandedKeys.map((key) => MapEntry<String, bool>(key, true)),
      );
  }

  GlobalKey _menuKey(String key) {
    return _menuKeys.putIfAbsent(key, GlobalKey.new);
  }

  GlobalKey _groupKey(String key) {
    return _groupKeys.putIfAbsent(key, GlobalKey.new);
  }

  void _scheduleExpandedGroupVisibility(String key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _ensureExpandedGroupVisible(key);
    });
  }

  void _ensureExpandedGroupVisible(String key) {
    if (!_drawerScrollController.hasClients) {
      return;
    }

    final viewportContext = _drawerListKey.currentContext;
    final headerContext = _menuKeys[key]?.currentContext;
    final groupContext = _groupKeys[key]?.currentContext;
    if (viewportContext == null ||
        headerContext == null ||
        groupContext == null) {
      return;
    }

    final viewportBox = viewportContext.findRenderObject() as RenderBox?;
    final headerBox = headerContext.findRenderObject() as RenderBox?;
    final groupBox = groupContext.findRenderObject() as RenderBox?;
    if (viewportBox == null || headerBox == null || groupBox == null) {
      return;
    }

    const edgePadding = 12.0;
    final viewportHeight = viewportBox.size.height;
    final headerTop = headerBox
        .localToGlobal(Offset.zero, ancestor: viewportBox)
        .dy;
    final groupTop = groupBox
        .localToGlobal(Offset.zero, ancestor: viewportBox)
        .dy;
    final groupHeight = groupBox.size.height;
    final groupBottom = groupTop + groupHeight;
    final visibleHeight = viewportHeight - (edgePadding * 2);

    double targetOffset = _drawerScrollController.offset;

    if (groupHeight > visibleHeight) {
      targetOffset += headerTop - edgePadding;
    } else {
      if (headerTop < edgePadding) {
        targetOffset += headerTop - edgePadding;
      } else if (groupBottom > viewportHeight - edgePadding) {
        targetOffset += groupBottom - (viewportHeight - edgePadding);
      }
    }

    final clampedOffset = targetOffset.clamp(
      _drawerScrollController.position.minScrollExtent,
      _drawerScrollController.position.maxScrollExtent,
    );

    if ((clampedOffset - _drawerScrollController.offset).abs() < 6) {
      return;
    }

    _drawerScrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }

  void _bindScrollController(ScrollController? controller) {
    controller?.addListener(_handleShellScroll);
  }

  void _unbindScrollController(ScrollController? controller) {
    controller?.removeListener(_handleShellScroll);
  }

  void _handleShellScroll() {
    final controller = widget.scrollController;
    if (!mounted ||
        controller == null ||
        !controller.hasClients ||
        !widget.mobileAutoHideHeader) {
      return;
    }

    final direction = controller.position.userScrollDirection;
    final offset = controller.offset;
    final shouldShow = direction == ScrollDirection.forward || offset <= 8;

    if (_showMobileHeader != shouldShow) {
      setState(() {
        _showMobileHeader = shouldShow;
      });
    }
  }
}

class _AdaptiveShellTitle extends StatefulWidget {
  const _AdaptiveShellTitle({required this.title, this.style});

  final String title;
  final TextStyle? style;

  @override
  State<_AdaptiveShellTitle> createState() => _AdaptiveShellTitleState();
}

class _AdaptiveShellTitleState extends State<_AdaptiveShellTitle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final textStyle = widget.style;

    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: widget.title, style: textStyle),
          maxLines: 1,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: double.infinity);

        final overflow = textPainter.width > constraints.maxWidth;

        if (!isMobile || !overflow) {
          return Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          );
        }

        final travel = textPainter.width - constraints.maxWidth;

        return ClipRect(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(-travel * _controller.value, 0),
                child: child,
              );
            },
            child: Text(widget.title, maxLines: 1, style: textStyle),
          ),
        );
      },
    );
  }
}
