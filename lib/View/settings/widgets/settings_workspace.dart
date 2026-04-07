import '../../../screen.dart';

class _SettingsWorkspaceController extends ChangeNotifier {
  _SettingsWorkspaceController({required this.openEditorRoute});

  final VoidCallback openEditorRoute;

  void handleItemSelected() {
    openEditorRoute();
  }
}

class _SettingsWorkspaceScope
    extends InheritedNotifier<_SettingsWorkspaceController> {
  const _SettingsWorkspaceScope({
    required _SettingsWorkspaceController controller,
    required super.child,
  }) : super(notifier: controller);

  static _SettingsWorkspaceController? maybeOf(BuildContext context) {
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
  });

  final ScrollController scrollController;
  final Widget list;
  final Widget editor;
  final double breakpoint;
  final double listWidth;
  final String title;

  @override
  State<SettingsWorkspace> createState() => _SettingsWorkspaceState();
}

class _SettingsWorkspaceState extends State<SettingsWorkspace> {
  late final _SettingsWorkspaceController _controller;
  bool _editorRouteOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = _SettingsWorkspaceController(
      openEditorRoute: _scheduleEditorRoutePush,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showInlineEditor = Responsive.isDesktop(context);

        return _SettingsWorkspaceScope(
          controller: _controller,
          child: showInlineEditor
              ? SingleChildScrollView(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.all(AppUiConstants.pagePadding),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: widget.listWidth, child: widget.list),
                      const SizedBox(width: 24),
                      Expanded(child: widget.editor),
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

    _editorRouteOpen = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _editorRouteOpen = false;
        return;
      }

      final routeTitle = _editorRouteTitle(context);

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) =>
              _SettingsEditorRoutePage(title: routeTitle, child: widget.editor),
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

  String _editorRouteTitle(BuildContext context) {
    if (widget.editor is SettingsEditorCard) {
      final title = widget.title.trim();
      return title;
    }

    final currentPath = Uri.parse(
      ModalRoute.of(context)?.settings.name ?? '/dashboard',
    ).path;
    return AppNavigation.findByPath(currentPath)?.title ?? 'Details';
  }
}

class SettingsListCard<T> extends StatelessWidget {
  const SettingsListCard({
    super.key,
    required this.searchController,
    required this.searchHint,
    required this.items,
    required this.selectedItem,
    required this.emptyMessage,
    required this.itemBuilder,
  });

  final TextEditingController searchController;
  final String searchHint;
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
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: searchHint,
              prefixIcon: const Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(emptyMessage),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
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

class SettingsEditorCard extends StatelessWidget {
  const SettingsEditorCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(child: child);
  }
}

class SettingsListTile extends StatelessWidget {
  const SettingsListTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  final String title;
  final String subtitle;
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
          workspaceController?.handleItemSelected();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
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
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.extension<AppThemeExtension>()!.mutedText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
          ],
        ),
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
        borderRadius: BorderRadius.circular(999),
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
  });

  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final double mobileBreakpoint;

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
              .map(
                (child) => SizedBox(
                  width: itemWidth > 0 ? itemWidth : null,
                  child: child,
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}
