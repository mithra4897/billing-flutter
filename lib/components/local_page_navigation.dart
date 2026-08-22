import '../screen.dart';

const int kLocalListPageSize = 20;

int localListTotalPages(int totalItems, {int pageSize = kLocalListPageSize}) {
  assert(pageSize > 0, 'pageSize must be greater than zero');
  if (totalItems <= 0) {
    return 1;
  }
  return (totalItems + pageSize - 1) ~/ pageSize;
}

class LocalPageNavigation extends StatelessWidget {
  const LocalPageNavigation({
    super.key,
    required this.totalItems,
    required this.currentPage,
    this.pageSize = kLocalListPageSize,
    required this.onPageChanged,
  });

  final int totalItems;
  final int currentPage;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    if (totalItems <= pageSize) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final appTheme = theme.extension<AppThemeExtension>()!;
    final totalPages = localListTotalPages(totalItems, pageSize: pageSize);
    final firstVisibleItem = ((currentPage - 1) * pageSize) + 1;
    final lastVisibleItem = (currentPage * pageSize) > totalItems
        ? totalItems
        : currentPage * pageSize;

    return Padding(
      padding: const EdgeInsets.only(top: AppUiConstants.spacingMd),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Showing $firstVisibleItem-$lastVisibleItem of $totalItems',
              style: theme.textTheme.bodySmall?.copyWith(
                color: appTheme.mutedText,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: appTheme.tableBorder),
              borderRadius: BorderRadius.circular(AppUiConstants.fieldRadius),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppUiConstants.fieldRadius),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PageNavigationButton(
                    icon: Icons.first_page,
                    tooltip: 'First page',
                    onPressed: currentPage > 1 ? () => onPageChanged(1) : null,
                  ),
                  _PageNavigationButton(
                    icon: Icons.chevron_left,
                    tooltip: 'Previous page',
                    onPressed: currentPage > 1
                        ? () => onPageChanged(currentPage - 1)
                        : null,
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    color: theme.colorScheme.primary,
                    child: Text(
                      '$currentPage',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  _PageNavigationButton(
                    icon: Icons.chevron_right,
                    tooltip: 'Next page',
                    onPressed: currentPage < totalPages
                        ? () => onPageChanged(currentPage + 1)
                        : null,
                  ),
                  _PageNavigationButton(
                    icon: Icons.last_page,
                    tooltip: 'Last page',
                    onPressed: currentPage < totalPages
                        ? () => onPageChanged(totalPages)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageNavigationButton extends StatelessWidget {
  const _PageNavigationButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        shape: const RoundedRectangleBorder(),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
