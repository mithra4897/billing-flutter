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

class PurchaseRegisterPage<T> extends StatefulWidget {
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
  State<PurchaseRegisterPage<T>> createState() =>
      _PurchaseRegisterPageState<T>();
}

class _PurchaseRegisterPageState<T> extends State<PurchaseRegisterPage<T>> {
  int _currentPage = 1;

  @override
  void didUpdateWidget(covariant PurchaseRegisterPage<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.rows, widget.rows)) {
      _currentPage = 1;
    }

    final totalPages = _totalPages(widget.rows.length);
    if (_currentPage > totalPages) {
      _currentPage = totalPages;
    }
  }

  int _totalPages(int itemCount) {
    if (itemCount <= 0) {
      return 1;
    }
    return ((itemCount + kLocalListPageSize - 1) / kLocalListPageSize).floor();
  }

  List<T> _pagedRows() {
    if (widget.rows.isEmpty) {
      return <T>[];
    }

    final start = (_currentPage - 1) * kLocalListPageSize;
    if (start >= widget.rows.length) {
      return <T>[];
    }

    final end = (start + kLocalListPageSize) > widget.rows.length
        ? widget.rows.length
        : (start + kLocalListPageSize);
    return widget.rows.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    if (widget.embedded) {
      return ShellPageActions(actions: widget.actions, child: content);
    }
    return AppStandaloneShell(
      title: widget.title,
      scrollController: ScrollController(),
      actions: widget.actions,
      child: content,
    );
  }

  Widget _buildContent(BuildContext context) {
    final visibleRows = _pagedRows();

    if (widget.loading) {
      return AppLoadingView(message: 'Loading ${widget.title}...');
    }
    if (widget.errorMessage != null) {
      return AppErrorStateView(
        title: 'Unable to load ${widget.title}',
        message: widget.errorMessage!,
        onRetry: widget.onRetry,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppUiConstants.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionCard(child: widget.filters),
          const SizedBox(height: AppUiConstants.spacingLg),
          AppSectionCard(
            child: widget.rows.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppUiConstants.spacingXl,
                    ),
                    child: Text(widget.emptyMessage),
                  )
                : Column(
                    children: [
                      _RegisterHeader<T>(columns: widget.columns),
                      const Divider(height: 1),
                      ...visibleRows.map(
                        (row) => _RegisterRow<T>(
                          row: row,
                          columns: widget.columns,
                          onTap: () => widget.onRowTap(row),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppUiConstants.spacingSm,
                          0,
                          AppUiConstants.spacingSm,
                          AppUiConstants.spacingSm,
                        ),
                        child: LocalPageNavigation(
                          totalItems: widget.rows.length,
                          currentPage: _currentPage,
                          onPageChanged: (page) =>
                              setState(() => _currentPage = page),
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
