import '../../../screen.dart';
import '../../../components/app_checkbox_filter.dart';

class SettingsWorkspaceController extends ChangeNotifier {
  VoidCallback? _openEditorRoute;

  void bindEditorRoute(VoidCallback openEditorRoute) {
    _openEditorRoute = openEditorRoute;
  }

  void unbindEditorRoute() {
    _openEditorRoute = null;
  }

  void openEditor() {
    _openEditorRoute?.call();
  }
}

class _SettingsWorkspaceScope
    extends InheritedNotifier<SettingsWorkspaceController> {
  const _SettingsWorkspaceScope({
    required SettingsWorkspaceController controller,
    required super.child,
  }) : super(notifier: controller);

  static SettingsWorkspaceController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_SettingsWorkspaceScope>()
        ?.notifier;
  }
}

class SettingsWorkspace extends StatefulWidget {
  const SettingsWorkspace({
    super.key,
    required this.title,
    required this.scrollController,
    required this.list,
    this.editor,
    this.editorBuilder,
    this.breakpoint = 1120,
    this.listWidth = 360,
    this.editorTitle,
    this.controller,
    this.editorOnly = false,
    this.wrapEditorInCard = true,
  }) : assert(
         editor != null || editorBuilder != null,
         'Either editor or editorBuilder must be provided.',
       );

  final ScrollController scrollController;
  final Widget list;
  final Widget? editor;
  final WidgetBuilder? editorBuilder;
  final double breakpoint;
  final double listWidth;
  final String title;
  final String? editorTitle;
  final SettingsWorkspaceController? controller;
  final bool editorOnly;
  final bool wrapEditorInCard;

  @override
  State<SettingsWorkspace> createState() => _SettingsWorkspaceState();
}

/// Shown in the main workspace while the same editor is presented on a pushed
/// route, so [SettingsWorkspace] never mounts [SettingsWorkspace.editor] twice.
class _EditorRoutePlaceholder extends StatelessWidget {
  const _EditorRoutePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          'This form is open in a full-screen page. Close it to continue here.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _SettingsWorkspaceRouteController extends GetxController {
  bool editorRouteOpen = false;

  void setEditorRouteOpen(bool value) {
    if (editorRouteOpen == value) {
      return;
    }
    editorRouteOpen = value;
    update();
  }
}

class _SettingsWorkspaceState extends State<SettingsWorkspace> {
  late final SettingsWorkspaceController _controller;
  late final bool _ownsController;
  late final String _routeControllerTag;

  _SettingsWorkspaceRouteController get _routeController =>
      Get.find<_SettingsWorkspaceRouteController>(tag: _routeControllerTag);

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? SettingsWorkspaceController();
    _routeControllerTag = persistentControllerTag(
      'SettingsWorkspaceRouteController',
      scope: <String, Object?>{'identity': identityHashCode(widget)},
    );
    Get.put(_SettingsWorkspaceRouteController(), tag: _routeControllerTag);
    _controller.bindEditorRoute(_scheduleEditorRoutePush);
  }

  @override
  void dispose() {
    _controller.unbindEditorRoute();
    Get.delete<_SettingsWorkspaceRouteController>(
      tag: _routeControllerTag,
      force: true,
    );
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<_SettingsWorkspaceRouteController>(
      tag: _routeControllerTag,
      builder: (routeController) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final showInlineEditor = Responsive.isDesktop(context);
            final theme = Theme.of(context).textTheme;
            final showEditorTitle =
                widget.editorTitle != null && Responsive.isNotMobile(context);
            final editorContent = routeController.editorRouteOpen
                ? _buildEditorContent(
                    textTheme: theme,
                    showEditorTitle: showEditorTitle,
                    key: const ValueKey<String>(
                      'settings-workspace-editor-placeholder',
                    ),
                    child: const _EditorRoutePlaceholder(),
                  )
                : _buildEditorContent(
                    textTheme: theme,
                    showEditorTitle: showEditorTitle,
                    key: const ValueKey<String>(
                      'settings-workspace-editor-content',
                    ),
                    child: _buildEditorInstance(context),
                  );

            return _SettingsWorkspaceScope(
              controller: _controller,
              child: widget.editorOnly
                  ? SingleChildScrollView(
                      controller: widget.scrollController,
                      padding: const EdgeInsets.all(AppUiConstants.pagePadding),
                      child: editorContent,
                    )
                  : showInlineEditor
                  ? SingleChildScrollView(
                      controller: widget.scrollController,
                      padding: const EdgeInsets.all(AppUiConstants.pagePadding),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: widget.listWidth, child: widget.list),
                          const SizedBox(width: AppUiConstants.spacingXl),
                          Expanded(child: editorContent),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      controller: widget.scrollController,
                      padding: const EdgeInsets.all(AppUiConstants.pagePadding),
                      child: widget.list,
                    ),
            );
          },
        );
      },
    );
  }

  Widget _buildEditorContent({
    required TextTheme textTheme,
    required bool showEditorTitle,
    required Key key,
    required Widget child,
  }) {
    final content = Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showEditorTitle) ...[
          Text(widget.editorTitle!, style: textTheme.headlineSmall),
          const SizedBox(height: AppUiConstants.spacingXs),
        ],
        child,
      ],
    );

    if (!widget.wrapEditorInCard) {
      return content;
    }

    return AppSectionCard(child: content);
  }

  Widget _buildEditorInstance(BuildContext context) {
    return widget.editorBuilder?.call(context) ?? widget.editor!;
  }

  void _scheduleEditorRoutePush() {
    if (_routeController.editorRouteOpen) {
      return;
    }

    _routeController.setEditorRouteOpen(true);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _routeController.setEditorRouteOpen(false);
        return;
      }

      // Let the placeholder-only frame finish before the route mounts the
      // editor, which avoids temporary duplicate GlobalKey ownership during
      // responsive transitions.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) {
        _routeController.setEditorRouteOpen(false);
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => _SettingsEditorRoutePage(
            title: widget.editorTitle ?? widget.title,
            child: _buildEditorInstance(context),
          ),
        ),
      );

      if (mounted) {
        // Wait until the route has fully torn down before remounting the
        // inline editor, so keyed form subtrees cannot overlap for a frame.
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) {
          _routeController.setEditorRouteOpen(false);
          return;
        }
        _routeController.setEditorRouteOpen(false);
      } else {
        _routeController.setEditorRouteOpen(false);
      }
    });
  }
}

class SettingsListCard<T> extends StatefulWidget {
  const SettingsListCard({
    super.key,
    this.searchController,
    this.searchHint,
    this.showSearchBar = true,
    required this.items,
    required this.selectedItem,
    required this.emptyMessage,
    required this.itemBuilder,
  });

  final TextEditingController? searchController;
  final String? searchHint;

  /// When false, the search field is not shown (e.g. search lives in the shell header).
  final bool showSearchBar;
  final List<T> items;
  final T? selectedItem;
  final String emptyMessage;
  final Widget Function(T item, bool selected) itemBuilder;

  static const double listViewportHeight = 520;

  @override
  State<SettingsListCard<T>> createState() => _SettingsListCardState<T>();
}

class _SettingsListCardController extends GetxController {
  int currentPage = 1;

  int totalPages(int itemCount) {
    if (itemCount <= 0) {
      return 1;
    }
    return ((itemCount + kLocalListPageSize - 1) / kLocalListPageSize).floor();
  }

  void syncItemCountChange(int itemCount) {
    final total = totalPages(itemCount);
    if (currentPage > total) {
      currentPage = total;
      update();
    }
  }

  void resetToFirstPage() {
    if (currentPage != 1) {
      currentPage = 1;
      update();
    }
  }

  void setPage(int page) {
    if (currentPage == page) {
      return;
    }
    currentPage = page;
    update();
  }
}

class _SettingsListCardState<T> extends State<SettingsListCard<T>> {
  late final String _controllerTag;

  _SettingsListCardController _ensureController() {
    if (Get.isRegistered<_SettingsListCardController>(tag: _controllerTag)) {
      return Get.find<_SettingsListCardController>(tag: _controllerTag);
    }
    return Get.put(_SettingsListCardController(), tag: _controllerTag);
  }

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'SettingsListCardController',
      scope: <String, Object?>{'identity': identityHashCode(widget)},
    );
    _ensureController();
  }

  @override
  void dispose() {
    if (Get.isRegistered<_SettingsListCardController>(tag: _controllerTag)) {
      Get.delete<_SettingsListCardController>(tag: _controllerTag, force: true);
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SettingsListCard<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final controller = _ensureController();
    if (!identical(oldWidget.items, widget.items)) {
      controller.resetToFirstPage();
    }
    controller.syncItemCountChange(widget.items.length);
    controller.update();
  }

  List<T> _pagedItems(int currentPage) {
    if (widget.items.isEmpty) {
      return <T>[];
    }

    final start = (currentPage - 1) * kLocalListPageSize;
    if (start >= widget.items.length) {
      return <T>[];
    }

    final end = (start + kLocalListPageSize) > widget.items.length
        ? widget.items.length
        : (start + kLocalListPageSize);
    return widget.items.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    _ensureController();
    return GetBuilder<_SettingsListCardController>(
      tag: _controllerTag,
      builder: (controller) {
        final visibleItems = _pagedItems(controller.currentPage);

        return AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.showSearchBar &&
                  widget.searchController != null &&
                  (widget.searchHint?.isNotEmpty ?? false)) ...[
                TextField(
                  controller: widget.searchController,
                  decoration: InputDecoration(
                    hintText: widget.searchHint,
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: AppUiConstants.spacingMd),
              ],
              if (widget.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppUiConstants.spacingXl,
                  ),
                  child: Text(widget.emptyMessage),
                )
              else
                SizedBox(
                  height: SettingsListCard.listViewportHeight,
                  child: ListView.separated(
                    primary: false,
                    itemCount: visibleItems.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppUiConstants.spacingXs),
                    itemBuilder: (context, index) => widget.itemBuilder(
                      visibleItems[index],
                      visibleItems[index] == widget.selectedItem,
                    ),
                  ),
                ),
              LocalPageNavigation(
                totalItems: widget.items.length,
                currentPage: controller.currentPage,
                onPageChanged: controller.setPage,
              ),
            ],
          ),
        );
      },
    );
  }
}

class SettingsListTile extends StatelessWidget {
  const SettingsListTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.detail,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final String? detail;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final workspaceController = _SettingsWorkspaceScope.maybeOf(context);

    return InkWell(
      borderRadius: BorderRadius.circular(AppUiConstants.buttonRadius),
      onTap: () {
        onTap();
        if (!Responsive.isDesktop(context)) {
          workspaceController?.openEditor();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(AppUiConstants.tilePadding),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary.withValues(alpha: 0.08) : null,
          borderRadius: BorderRadius.circular(AppUiConstants.buttonRadius),
          border: Border.all(
            color: selected
                ? colorScheme.primary.withValues(alpha: 0.28)
                : theme.dividerColor.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: AppUiConstants.spacingXxs),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.extension<AppThemeExtension>()!.mutedText,
                      ),
                    ),
                  ],
                  if ((detail ?? '').isNotEmpty) ...[
                    const SizedBox(height: AppUiConstants.spacingXxs),
                    Text(
                      detail!,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.extension<AppThemeExtension>()!.mutedText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppUiConstants.spacingSm),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class SettingsExpandableTile extends StatelessWidget {
  const SettingsExpandableTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.expanded,
    required this.onToggle,
    required this.child,
    this.detail,
    this.leadingIcon,
    this.trailing,
    this.highlighted = false,
  });

  final String title;
  final String subtitle;
  final String? detail;
  final bool expanded;
  final bool highlighted;
  final VoidCallback onToggle;
  final Widget child;
  final IconData? leadingIcon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = highlighted || expanded;

    return Container(
      decoration: BoxDecoration(
        color: accent ? colorScheme.primary.withValues(alpha: 0.01) : null,
        borderRadius: BorderRadius.circular(AppUiConstants.buttonRadius),
        border: Border.all(
          color: accent
              ? colorScheme.primary.withValues(alpha: 0.24)
              : theme.dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppUiConstants.buttonRadius),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(AppUiConstants.tilePadding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (leadingIcon != null) ...[
                    Icon(
                      leadingIcon,
                      size: 20,
                      color: accent ? colorScheme.primary : null,
                    ),
                    const SizedBox(width: AppUiConstants.spacingSm),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: AppUiConstants.spacingXxs),
                          Text(
                            subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme
                                  .extension<AppThemeExtension>()!
                                  .mutedText,
                            ),
                          ),
                        ],
                        if ((detail ?? '').isNotEmpty) ...[
                          const SizedBox(height: AppUiConstants.spacingXxs),
                          Text(
                            detail!,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme
                                  .extension<AppThemeExtension>()!
                                  .mutedText,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: AppUiConstants.spacingSm),
                    trailing!,
                  ],
                  const SizedBox(width: AppUiConstants.spacingXs),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: accent ? colorScheme.primary : null,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            Divider(
              height: 1,
              thickness: 1,
              color: theme.dividerColor.withValues(alpha: 0.12),
            ),
            Padding(
              padding: const EdgeInsets.all(AppUiConstants.tilePadding),
              child: child,
            ),
          ],
        ],
      ),
    );
  }
}

class _SettingsEditorRoutePage extends StatelessWidget {
  const _SettingsEditorRoutePage({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppUiConstants.pagePadding),
          child: child,
        ),
      ),
    );
  }
}

class SettingsStatusPill extends StatelessWidget {
  const SettingsStatusPill({
    super.key,
    required this.label,
    required this.active,
  });

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = active
        ? colorScheme.primary.withValues(alpha: 0.12)
        : colorScheme.error.withValues(alpha: 0.10);
    final foreground = active ? colorScheme.primary : colorScheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppUiConstants.pillRadius),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class SettingsFormWrap extends StatelessWidget {
  const SettingsFormWrap({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
    this.mobileBreakpoint = 640,
    this.maxWidth = 300,
  });

  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final double mobileBreakpoint;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final isMobile = availableWidth < mobileBreakpoint;
        final itemWidth = isMobile
            ? availableWidth
            : (availableWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children
              .map((child) {
                if (child is AppDropdownField ||
                    child is DocumentSeriesSelector ||
                    child is AppFormTextField ||
                    child is AppCheckboxFilter ||
                    child is AppDateSelectorField ||
                    child is AppDateTimeSelectorField ||
                    child is ErpLinkField ||
                    child is AppSearchPickerField ||
                    child is InlineFieldAction ||
                    child is UploadPathField ||
                    child is AppSwitchTile) {
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: maxWidth < itemWidth
                          ? maxWidth
                          : itemWidth > 0
                          ? itemWidth
                          : double.infinity,
                    ),
                    child: child,
                  );
                } else {
                  return child;
                }
              })
              .toList(growable: false),
        );
      },
    );
  }
}
