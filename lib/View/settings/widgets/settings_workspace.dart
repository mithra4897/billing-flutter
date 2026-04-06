import '../../../screen.dart';

class SettingsWorkspace extends StatelessWidget {
  const SettingsWorkspace({
    super.key,
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= breakpoint;

        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(AppUiConstants.pagePadding),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: listWidth, child: list),
                    const SizedBox(width: 24),
                    Expanded(child: editor),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [list, const SizedBox(height: 20), editor],
                ),
        );
      },
    );
  }
}

class SettingsListCard<T> extends StatelessWidget {
  const SettingsListCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.searchController,
    required this.searchHint,
    required this.items,
    required this.selectedItem,
    required this.emptyMessage,
    required this.itemBuilder,
  });

  final String title;
  final String subtitle;
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
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).extension<AppThemeExtension>()!.mutedText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
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
  const SettingsEditorCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).extension<AppThemeExtension>()!.mutedText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          child,
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

    return InkWell(
      borderRadius: BorderRadius.circular(AppUiConstants.buttonRadius),
      onTap: onTap,
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
  const SettingsFormWrap({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 16, runSpacing: 16, children: children);
  }
}

double settingsResponsiveFieldWidth(
  BuildContext context, {
  double minWidth = 240,
  double maxWidth = 360,
}) {
  final screenWidth = MediaQuery.sizeOf(context).width;

  if (screenWidth < 640) {
    return screenWidth - 64;
  }

  if (screenWidth < 1100) {
    final width = (screenWidth - 120) / 2;
    return width.clamp(minWidth, maxWidth);
  }

  final width = (screenWidth - 180) / 3;
  return width.clamp(minWidth, maxWidth);
}
