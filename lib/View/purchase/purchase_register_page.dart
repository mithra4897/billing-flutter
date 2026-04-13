import '../../screen.dart';

class PurchaseRegisterColumn<T> {
  const PurchaseRegisterColumn({
    required this.label,
    required this.valueBuilder,
    this.flex = 2,
  });

  final String label;
  final String Function(T row) valueBuilder;
  final int flex;
}

class PurchaseRegisterPage<T> extends StatelessWidget {
  const PurchaseRegisterPage({
    super.key,
    required this.title,
    required this.loading,
    required this.errorMessage,
    required this.onRetry,
    required this.filters,
    required this.actions,
    required this.rows,
    required this.columns,
    required this.onRowTap,
    required this.emptyMessage,
    this.embedded = false,
  });

  final String title;
  final bool loading;
  final String? errorMessage;
  final Future<void> Function() onRetry;
  final Widget filters;
  final List<Widget> actions;
  final List<T> rows;
  final List<PurchaseRegisterColumn<T>> columns;
  final ValueChanged<T> onRowTap;
  final String emptyMessage;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    if (embedded) {
      return ShellPageActions(actions: actions, child: content);
    }
    return AppStandaloneShell(
      title: title,
      scrollController: ScrollController(),
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent(BuildContext context) {
    if (loading) {
      return AppLoadingView(message: 'Loading $title...');
    }
    if (errorMessage != null) {
      return AppErrorStateView(
        title: 'Unable to load $title',
        message: errorMessage!,
        onRetry: onRetry,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppUiConstants.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionCard(child: filters),
          const SizedBox(height: AppUiConstants.spacingLg),
          AppSectionCard(
            child: rows.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppUiConstants.spacingXl,
                    ),
                    child: Text(emptyMessage),
                  )
                : Column(
                    children: [
                      _RegisterHeader<T>(columns: columns),
                      const Divider(height: 1),
                      ...rows.map(
                        (row) => _RegisterRow<T>(
                          row: row,
                          columns: columns,
                          onTap: () => onRowTap(row),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _RegisterHeader<T> extends StatelessWidget {
  const _RegisterHeader({required this.columns});

  final List<PurchaseRegisterColumn<T>> columns;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppUiConstants.spacingSm,
        vertical: AppUiConstants.spacingXs,
      ),
      child: Row(
        children: columns
            .map(
              (column) => Expanded(
                flex: column.flex,
                child: Text(
                  column.label,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _RegisterRow<T> extends StatelessWidget {
  const _RegisterRow({
    required this.row,
    required this.columns,
    required this.onTap,
  });

  final T row;
  final List<PurchaseRegisterColumn<T>> columns;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppUiConstants.spacingSm,
          vertical: AppUiConstants.spacingSm,
        ),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0x11000000))),
        ),
        child: Row(
          children: columns
              .map(
                (column) => Expanded(
                  flex: column.flex,
                  child: Text(
                    column.valueBuilder(row),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}
