import '../../controller/purchase/purchase_register_page_controller.dart';
import '../../screen.dart';

class PurchaseRegisterColumn<T> {
  const PurchaseRegisterColumn({
    required this.label,
    required this.valueBuilder,
    this.widgetBuilder,
    this.flex = 2,
  });

  final String label;
  final String Function(T row) valueBuilder;
  final Widget Function(BuildContext context, T row)? widgetBuilder;
  final int flex;
}

class PurchaseRegisterPage<T> extends StatefulWidget {
  const PurchaseRegisterPage({
    super.key,
    required this.title,
    required this.loading,
    required this.errorMessage,
    required this.onRetry,
    required this.actions,
    required this.rows,
    required this.columns,
    required this.onRowTap,
    required this.emptyMessage,
    this.filters,
    this.embedded = false,
    this.fullPageStyle = false,
  });

  final String title;
  final bool loading;
  final String? errorMessage;
  final Future<void> Function() onRetry;
  final Widget? filters;
  final List<Widget> actions;
  final List<T> rows;
  final List<PurchaseRegisterColumn<T>> columns;
  final ValueChanged<T> onRowTap;
  final String emptyMessage;
  final bool embedded;
  final bool fullPageStyle;

  static const double listViewportHeight = 560;

  @override
  State<PurchaseRegisterPage<T>> createState() =>
      _PurchaseRegisterPageState<T>();
}

class _PurchaseRegisterPageState<T> extends State<PurchaseRegisterPage<T>> {
  late final String _controllerTag;
  late final PurchaseRegisterPageController _controller;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'PurchaseRegisterPageController',
      scope: <String, Object?>{
        'widget': widget.runtimeType,
        'key': widget.key,
        'state': identityHashCode(this),
      },
    );
    _controller = Get.put(
      PurchaseRegisterPageController(),
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    if (Get.isRegistered<PurchaseRegisterPageController>(tag: _controllerTag)) {
      Get.delete<PurchaseRegisterPageController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PurchaseRegisterPage<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.rows, widget.rows)) {
      _controller.resetPage();
    }

    final totalPages = _totalPages(widget.rows.length);
    _controller.clampToTotalPages(totalPages);
    _controller.update();
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

    final start = (_controller.currentPage - 1) * kLocalListPageSize;
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
    return GetBuilder<PurchaseRegisterPageController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = _buildContent(context, controller);
        if (widget.embedded) {
          return ShellPageActions(actions: widget.actions, child: content);
        }
        return AppStandaloneShell(
          title: widget.title,
          scrollController: controller.pageScrollController,
          actions: widget.actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    PurchaseRegisterPageController controller,
  ) {
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

    if (widget.fullPageStyle) {
      return _buildFullPageContent(context, controller, visibleRows);
    }

    return SingleChildScrollView(
      controller: controller.pageScrollController,
      padding: const EdgeInsets.all(AppUiConstants.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.filters != null) ...[
            SizedBox(
              width: double.infinity,
              child: AppSectionCard(child: widget.filters!),
            ),
            const SizedBox(height: AppUiConstants.spacingLg),
          ],
          SizedBox(
            width: double.infinity,
            child: AppSectionCard(
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
                        SizedBox(
                          height: PurchaseRegisterPage.listViewportHeight,
                          child: ListView.builder(
                            primary: false,
                            itemCount: visibleRows.length,
                            itemBuilder: (context, index) {
                              final row = visibleRows[index];
                              return _RegisterRow<T>(
                                row: row,
                                columns: widget.columns,
                                onTap: () => widget.onRowTap(row),
                              );
                            },
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
                            currentPage: controller.currentPage,
                            onPageChanged: controller.setPage,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullPageContent(
    BuildContext context,
    PurchaseRegisterPageController controller,
    List<T> visibleRows,
  ) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;
    final useTable = MediaQuery.of(context).size.width >= 900;

    return SingleChildScrollView(
      controller: controller.pageScrollController,
      padding: const EdgeInsets.all(AppUiConstants.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.filters != null) ...[
            AppSectionCard(child: widget.filters!),
            const SizedBox(height: AppUiConstants.spacingLg),
          ],
          if (widget.rows.isEmpty)
            Container(
              constraints: const BoxConstraints(minHeight: 280),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: appTheme.cardBackground,
                borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
                boxShadow: [
                  BoxShadow(
                    color: appTheme.cardShadow,
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Text(
                widget.emptyMessage,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: appTheme.mutedText),
                textAlign: TextAlign.center,
              ),
            )
          else
            DecoratedBox(
              decoration: BoxDecoration(
                color: appTheme.cardBackground,
                borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
                boxShadow: [
                  BoxShadow(
                    color: appTheme.cardShadow,
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppUiConstants.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (useTable)
                      _buildDesktopTable(context, visibleRows)
                    else
                      _buildMobileCards(context, visibleRows, appTheme),
                    const SizedBox(height: AppUiConstants.spacingMd),
                    LocalPageNavigation(
                      totalItems: widget.rows.length,
                      currentPage: controller.currentPage,
                      onPageChanged: controller.setPage,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(BuildContext context, List<T> visibleRows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppUiConstants.spacingSm,
            vertical: AppUiConstants.spacingXs,
          ),
          child: Row(
            children: widget.columns
                .map(
                  (column) => Expanded(
                    flex: column.flex,
                    child: Text(
                      column.label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        const Divider(height: 1),
        ...visibleRows.map(
          (row) => InkWell(
            onTap: () => widget.onRowTap(row),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppUiConstants.spacingSm,
                vertical: AppUiConstants.spacingMd,
              ),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0x11000000))),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.columns
                    .map(
                  (column) => Expanded(
                    flex: column.flex,
                    child: column.widgetBuilder != null 
                        ? Align(
                            alignment: Alignment.centerLeft,
                            child: column.widgetBuilder!(context, row),
                          )
                        : Text(
                            column.valueBuilder(row).trim().isEmpty
                                ? '-'
                                : column.valueBuilder(row),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),
                    )
                    .toList(growable: false),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileCards(
    BuildContext context,
    List<T> visibleRows,
    AppThemeExtension appTheme,
  ) {
    return Column(
      children: visibleRows
          .map((row) {
            final primaryText = widget.columns.isEmpty
                ? ''
                : widget.columns.first.valueBuilder(row);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: appTheme.subtleFill,
                borderRadius: BorderRadius.circular(
                  AppUiConstants.buttonRadius,
                ),
              ),
              child: InkWell(
                onTap: () => widget.onRowTap(row),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (primaryText.trim().isNotEmpty)
                      Text(
                        primaryText,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    if (primaryText.trim().isNotEmpty)
                      const SizedBox(height: AppUiConstants.spacingSm),
                    ...widget.columns
                        .skip(primaryText.trim().isNotEmpty ? 1 : 0)
                        .map(
                          (column) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppUiConstants.spacingXs,
                            ),
                            child: Text(
                              '${column.label}: ${column.valueBuilder(row).trim().isEmpty ? '-' : column.valueBuilder(row)}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            );
          })
          .toList(growable: false),
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
                  child: column.widgetBuilder != null
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: column.widgetBuilder!(context, row),
                        )
                      : Text(
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
