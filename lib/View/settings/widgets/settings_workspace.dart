import '../../../screen.dart';

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
    required this.editor,
    this.breakpoint = 1120,
    this.listWidth = 360,
    this.editorTitle,
    this.controller,
    this.editorOnly = false,
    this.wrapEditorInCard = true,
  });

  final ScrollController scrollController;
  final Widget list;
  final Widget editor;
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

class _SettingsWorkspaceState extends State<SettingsWorkspace> {
  late final SettingsWorkspaceController _controller;
  late final bool _ownsController;
  bool _editorRouteOpen = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? SettingsWorkspaceController();
    _controller.bindEditorRoute(_scheduleEditorRoutePush);
  }

  @override
  void dispose() {
    _controller.unbindEditorRoute();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showInlineEditor = Responsive.isDesktop(context);
        final theme = Theme.of(context).textTheme;
        final editorBody = _editorRouteOpen
            ? const _EditorRoutePlaceholder()
            : widget.editor;
        final editorContent = widget.wrapEditorInCard
            ? AppSectionCard(
                child: Column(
                  children: [
                    if (widget.editorTitle != null &&
                        Responsive.isNotMobile(context)) ...[
                      Text(widget.editorTitle!, style: theme.headlineSmall),
                      const SizedBox(height: AppUiConstants.spacingXs),
                    ],
                    editorBody,
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.editorTitle != null &&
                      Responsive.isNotMobile(context)) ...[
                    Text(widget.editorTitle!, style: theme.headlineSmall),
                    const SizedBox(height: AppUiConstants.spacingXs),
                  ],
                  editorBody,
                ],
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
  }

  void _scheduleEditorRoutePush() {
    if (_editorRouteOpen) {
      return;
    }

    setState(() {
      _editorRouteOpen = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _editorRouteOpen = false;
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => _SettingsEditorRoutePage(
            title: widget.editorTitle ?? widget.title,
            child: widget.editor,
          ),
        ),
      );

      if (mounted) {
        setState(() {
          _editorRouteOpen = false;
        });
      } else {
        _editorRouteOpen = false;
      }
    });
  }
}

class SettingsListCard<T> extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showSearchBar &&
              searchController != null &&
              (searchHint?.isNotEmpty ?? false)) ...[
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: searchHint,
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
          ],
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppUiConstants.spacingXl,
              ),
              child: Text(emptyMessage),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppUiConstants.spacingXs),
              itemBuilder: (context, index) => itemBuilder(
                items[index],
                identical(items[index], selectedItem),
              ),
            ),
        ],
      ),
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
                    child is AppFormTextField ||
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
