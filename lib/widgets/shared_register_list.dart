import 'package:flutter/material.dart';

import '../view/purchase/purchase_register_page.dart';

class SharedRegisterList<T> extends StatelessWidget {
  const SharedRegisterList({
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
    this.onRefresh,
    this.filters,
    this.embedded = false,
    this.fullPageStyle = false,
    this.contentSized = false,
    this.emphasizeRows = false,
    this.footer,
    this.footerBuilder,
    this.rowColorBuilder,
    this.remoteTotalItems,
    this.remoteCurrentPage,
    this.remotePerPage,
    this.onRemotePageChanged,
  });

  final String title;
  final bool loading;
  final String? errorMessage;
  final Future<void> Function() onRetry;
  final Future<void> Function()? onRefresh;
  final Widget? filters;
  final List<Widget> actions;
  final List<T> rows;
  final List<PurchaseRegisterColumn<T>> columns;
  final ValueChanged<T> onRowTap;
  final String emptyMessage;
  final bool embedded;
  final bool fullPageStyle;
  final bool contentSized;
  final bool emphasizeRows;
  final Widget? footer;
  final Widget? Function(BuildContext context, int currentPage)? footerBuilder;
  final Color? Function(BuildContext context, T row)? rowColorBuilder;
  final int? remoteTotalItems;
  final int? remoteCurrentPage;
  final int? remotePerPage;
  final ValueChanged<int>? onRemotePageChanged;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh ?? onRetry,
      child: PurchaseRegisterPage<T>(
        title: title,
        loading: loading,
        errorMessage: errorMessage,
        onRetry: onRetry,
        actions: actions,
        rows: rows,
        columns: columns,
        onRowTap: onRowTap,
        emptyMessage: emptyMessage,
        filters: filters,
        embedded: embedded,
        fullPageStyle: fullPageStyle,
        contentSized: contentSized,
        emphasizeRows: emphasizeRows,
        footer: footer,
        footerBuilder: footerBuilder,
        rowColorBuilder: rowColorBuilder,
        remoteTotalItems: remoteTotalItems,
        remoteCurrentPage: remoteCurrentPage,
        remotePerPage: remotePerPage,
        onRemotePageChanged: onRemotePageChanged,
      ),
    );
  }
}
