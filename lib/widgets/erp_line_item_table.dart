import '../screen.dart';

enum ErpLineItemTableColumn {
  no,
  source,
  item,
  uom,
  warehouse,
  qty,
  rate,
  discount,
  taxCode,
  description,
  remarks,
  amount,
  action,
}

class ErpLineItemCustomColumn {
  const ErpLineItemCustomColumn({
    required this.id,
    required this.label,
    required this.width,
    this.insertAfter = ErpLineItemTableColumn.source,
  });

  final String id;
  final String label;
  final double width;
  final ErpLineItemTableColumn insertAfter;
}

class ErpLineItemCellFrame extends StatelessWidget {
  const ErpLineItemCellFrame({
    super.key,
    required this.child,
    this.height = AppUiConstants.tableCompactFieldHeight,
    this.padding = const EdgeInsets.all(AppUiConstants.tableCompactFieldInset),
  });

  final Widget child;
  final double? height;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    Widget current = child;
    if (height != null) {
      current = SizedBox(height: height, child: current);
    }
    return Padding(padding: padding, child: current);
  }
}

class ErpLineItemTextCell extends StatefulWidget {
  const ErpLineItemTextCell({
    super.key,
    this.controller,
    this.initialValue,
    this.hintText = '',
    this.onChanged,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.readOnly = false,
    this.enabled = true,
    this.height = AppUiConstants.tableCompactFieldHeight,
    this.textAlign,
  }) : assert(
         controller != null || initialValue != null || readOnly,
         'Either a controller, an initialValue, or readOnly mode is required.',
       );

  final TextEditingController? controller;
  final String? initialValue;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool readOnly;
  final bool enabled;
  final double? height;
  final TextAlign? textAlign;

  @override
  State<ErpLineItemTextCell> createState() => _ErpLineItemTextCellState();
}

class _ErpLineItemTextCellState extends State<ErpLineItemTextCell> {
  final NumericFieldFocusBinding _numericBinding = NumericFieldFocusBinding();
  TextEditingController? _internalController;

  bool get _isNumericField =>
      NumericFieldFocusBinding.isNumericKeyboard(widget.keyboardType);

  TextEditingController? get _effectiveController =>
      widget.controller ?? _internalController;

  String _normalizedInitialValue() {
    final raw = (widget.initialValue ?? '').trim();
    if (widget.readOnly && raw == '-') {
      return '';
    }
    return raw;
  }

  @override
  void initState() {
    super.initState();
    _syncInternalController(previousInitialValue: null);
    _syncNumericBinding();
  }

  @override
  void didUpdateWidget(covariant ErpLineItemTextCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncInternalController(previousInitialValue: oldWidget.initialValue);
    _syncNumericBinding();
  }

  void _syncInternalController({required String? previousInitialValue}) {
    if (widget.controller != null) {
      _internalController?.dispose();
      _internalController = null;
      return;
    }

    final nextValue = _normalizedInitialValue();
    _internalController ??= TextEditingController(text: nextValue);
    if (previousInitialValue == widget.initialValue) {
      return;
    }

    final controller = _internalController!;
    if (controller.text == nextValue) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _internalController != controller) {
        return;
      }
      if (controller.text == nextValue) {
        return;
      }
      controller.value = controller.value.copyWith(
        text: nextValue,
        selection: TextSelection.collapsed(offset: nextValue.length),
        composing: TextRange.empty,
      );
    });
  }

  void _syncNumericBinding() {
    final created = _numericBinding.sync(
      enable: _isNumericField,
      controller: _effectiveController,
    );
    if (created) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          NumericFieldFocusBinding.applyFormattedDisplay(_effectiveController);
        }
      });
    }
  }

  @override
  void dispose() {
    _numericBinding.dispose();
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ErpLineItemCellFrame(
      height: widget.height,
      child: TextFormField(
        controller: _effectiveController,
        focusNode: _numericBinding.focusNode,
        readOnly: widget.readOnly,
        enabled: widget.enabled,
        maxLines: widget.maxLines,
        keyboardType: widget.keyboardType,
        onChanged: widget.onChanged,
        validator: widget.validator,
        textAlign:
            widget.textAlign ??
            (_isNumericField ? TextAlign.right : TextAlign.start),
        textAlignVertical: TextAlignVertical.center,
        inputFormatters: widget.keyboardType == null
            ? null
            : <TextInputFormatter>[
                if (_isNumericField) const NumericInputFormatter(),
              ],
        decoration: InputDecoration(
          isDense: true,
          hintText: widget.hintText,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppUiConstants.tableCellPaddingSm,
            vertical: AppUiConstants.tableCellPaddingXs,
          ),
        ),
      ),
    );
  }
}

class ErpLineItemTableRow {
  const ErpLineItemTableRow({
    required this.rowKey,
    this.sourceLineId,
    this.sourceLineOptions = const <AppDropdownItem<int?>>[],
    this.onSourceLineChanged,
    this.itemId,
    this.itemSelection,
    this.itemOptions = const <ErpLinkFieldOption<int>>[],
    this.onItemChanged,
    this.itemValidator,
    this.uomId,
    this.uomOptions = const <AppDropdownItem<int>>[],
    this.onUomChanged,
    this.uomValidator,
    this.warehouseId,
    this.warehouseOptions = const <AppDropdownItem<int>>[],
    this.onWarehouseChanged,
    this.taxCodeId,
    this.taxOptions = const <AppDropdownItem<int>>[],
    this.onTaxCodeChanged,
    this.qtyController,
    this.onQtyChanged,
    this.qtyValidator,
    this.rateController,
    this.onRateChanged,
    this.rateValidator,
    this.discountController,
    this.onDiscountChanged,
    this.discountValidator,
    this.descriptionController,
    this.onDescriptionChanged,
    this.remarksController,
    this.onRemarksChanged,
    required this.amount,
    this.cellWidgets = const <ErpLineItemTableColumn, Widget>{},
    this.customCells = const <String, Widget>{},
    this.deleteEnabled = true,
  });

  final Object rowKey;
  final int? sourceLineId;
  final List<AppDropdownItem<int?>> sourceLineOptions;
  final ValueChanged<int?>? onSourceLineChanged;
  final int? itemId;
  final ErpLinkFieldOption<int>? itemSelection;
  final List<ErpLinkFieldOption<int>> itemOptions;
  final ValueChanged<int?>? onItemChanged;
  final FormFieldValidator<String>? itemValidator;
  final int? uomId;
  final List<AppDropdownItem<int>> uomOptions;
  final ValueChanged<int?>? onUomChanged;
  final FormFieldValidator<int?>? uomValidator;
  final int? warehouseId;
  final List<AppDropdownItem<int>> warehouseOptions;
  final ValueChanged<int?>? onWarehouseChanged;
  final int? taxCodeId;
  final List<AppDropdownItem<int>> taxOptions;
  final ValueChanged<int?>? onTaxCodeChanged;
  final TextEditingController? qtyController;
  final ValueChanged<String>? onQtyChanged;
  final FormFieldValidator<String>? qtyValidator;
  final TextEditingController? rateController;
  final ValueChanged<String>? onRateChanged;
  final FormFieldValidator<String>? rateValidator;
  final TextEditingController? discountController;
  final ValueChanged<String>? onDiscountChanged;
  final FormFieldValidator<String>? discountValidator;
  final TextEditingController? descriptionController;
  final ValueChanged<String>? onDescriptionChanged;
  final TextEditingController? remarksController;
  final ValueChanged<String>? onRemarksChanged;
  final double amount;
  final Map<ErpLineItemTableColumn, Widget> cellWidgets;
  final Map<String, Widget> customCells;
  final bool deleteEnabled;
}

class ErpLineItemTable extends StatefulWidget {
  const ErpLineItemTable({
    super.key,
    required this.lines,
    this.onChanged,
    this.onAddLine,
    this.onDeleteLine,
    this.footer,
    this.addButtonLabel = 'Add Line',
    this.title = 'Line items',
    this.sourceColumnLabel = 'Source line',
    this.columnLabels = const <ErpLineItemTableColumn, String>{},
    this.customColumns = const <ErpLineItemCustomColumn>[],
    this.visibleColumns = const <ErpLineItemTableColumn>{
      ErpLineItemTableColumn.no,
      ErpLineItemTableColumn.source,
      ErpLineItemTableColumn.item,
      ErpLineItemTableColumn.uom,
      ErpLineItemTableColumn.warehouse,
      ErpLineItemTableColumn.qty,
      ErpLineItemTableColumn.rate,
      ErpLineItemTableColumn.discount,
      ErpLineItemTableColumn.taxCode,
      ErpLineItemTableColumn.description,
      ErpLineItemTableColumn.amount,
      ErpLineItemTableColumn.action,
    },
    this.enabled = true,
  });

  final List<ErpLineItemTableRow> lines;
  final ValueChanged<List<ErpLineItemTableRow>>? onChanged;
  final VoidCallback? onAddLine;
  final ValueChanged<int>? onDeleteLine;
  final Widget? footer;
  final String addButtonLabel;
  final String title;
  final String sourceColumnLabel;
  final Map<ErpLineItemTableColumn, String> columnLabels;
  final List<ErpLineItemCustomColumn> customColumns;
  final Set<ErpLineItemTableColumn> visibleColumns;
  final bool enabled;

  @override
  State<ErpLineItemTable> createState() => _ErpLineItemTableState();
}

class _ErpLineItemTableState extends State<ErpLineItemTable> {
  static const double _tableEdgeWhitespaceHeight =
      AppUiConstants.tableCompactFieldHeight +
      (AppUiConstants.tableToolbarHeight * 2);
  static const Map<String, double> _columnWidths = <String, double>{
    'no': 56,
    'source': 184,
    'item': 260,
    'uom': 110,
    'warehouse': 168,
    'qty': 104,
    'rate': 118,
    'discount': 110,
    'tax': 132,
    'description': 240,
    'remarks': 220,
    'amount': 126,
    'action': 76,
  };
  static const Map<ErpLineItemTableColumn, double> _columnGrowWeights =
      <ErpLineItemTableColumn, double>{
        ErpLineItemTableColumn.item: 4.5,
        ErpLineItemTableColumn.source: 2.2,
        ErpLineItemTableColumn.warehouse: 1.8,
        ErpLineItemTableColumn.uom: 1.0,
        ErpLineItemTableColumn.qty: 1.2,
        ErpLineItemTableColumn.rate: 1.2,
        ErpLineItemTableColumn.discount: 1.1,
        ErpLineItemTableColumn.taxCode: 1.3,
        ErpLineItemTableColumn.description: 2.4,
        ErpLineItemTableColumn.remarks: 2.0,
        ErpLineItemTableColumn.amount: 1.4,
      };

  final ScrollController _horizontalController = ScrollController();
  int? _selectedIndex;
  int? _hoveredIndex;

  List<Object> get _orderedColumns {
    final ordered = <Object>[];
    for (final column in ErpLineItemTableColumn.values) {
      if (_activeColumns.contains(column)) {
        ordered.add(column);
      }
      ordered.addAll(
        widget.customColumns.where(
          (custom) =>
              custom.insertAfter == column && _shouldShowCustomColumn(custom),
        ),
      );
    }
    return ordered;
  }

  List<ErpLineItemTableColumn> get _activeColumns => ErpLineItemTableColumn
      .values
      .where(
        (column) =>
            widget.visibleColumns.contains(column) &&
            _shouldShowBuiltInColumn(column),
      )
      .toList(growable: false);

  double get _tableMinWidth => _orderedColumns.fold<double>(0, (sum, column) {
    if (column is ErpLineItemTableColumn) {
      return sum + (_columnWidths[_columnKey(column)] ?? 0);
    }
    return sum + (column as ErpLineItemCustomColumn).width;
  });

  double _extraWidthPerWeight(double availableWidth) {
    final extraWidth = availableWidth - _tableMinWidth;
    if (extraWidth <= 0) {
      return 0;
    }
    final totalWeight = _activeColumns.fold<double>(0, (sum, column) {
      return sum + (_columnGrowWeights[column] ?? 0);
    });
    if (totalWeight <= 0) {
      return 0;
    }
    return extraWidth / totalWeight;
  }

  double _resolvedColumnWidth(
    ErpLineItemTableColumn column,
    double extraWidthPerWeight,
  ) {
    final baseWidth = _columnWidths[_columnKey(column)] ?? 0;
    final growWeight = _columnGrowWeights[column] ?? 0;
    if (growWeight <= 0 || extraWidthPerWeight <= 0) {
      return baseWidth;
    }
    return baseWidth + (growWeight * extraWidthPerWeight);
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  void _notifyChanged() {
    widget.onChanged?.call(widget.lines);
  }

  bool _shouldShowCustomColumn(ErpLineItemCustomColumn column) {
    if (widget.lines.isEmpty) {
      return true;
    }
    return widget.lines.any(
      (row) => !_isHiddenPlaceholderCell(row.customCells[column.id]),
    );
  }

  bool _shouldShowBuiltInColumn(ErpLineItemTableColumn column) {
    if (column == ErpLineItemTableColumn.uom) {
      return false;
    }
    return true;
  }

  bool _isHiddenPlaceholderCell(Widget? cell) {
    if (cell == null || cell is SizedBox) {
      return true;
    }
    if (cell is ErpLineItemCellFrame) {
      return _isHiddenPlaceholderCell(cell.child);
    }
    if (cell is ErpLineItemTextCell) {
      final value = (cell.initialValue ?? '').trim();
      return cell.readOnly &&
          !cell.enabled &&
          (value.isEmpty || value == '-' || value == '—');
    }
    return false;
  }

  String _columnKey(ErpLineItemTableColumn column) {
    switch (column) {
      case ErpLineItemTableColumn.no:
        return 'no';
      case ErpLineItemTableColumn.source:
        return 'source';
      case ErpLineItemTableColumn.item:
        return 'item';
      case ErpLineItemTableColumn.uom:
        return 'uom';
      case ErpLineItemTableColumn.warehouse:
        return 'warehouse';
      case ErpLineItemTableColumn.qty:
        return 'qty';
      case ErpLineItemTableColumn.rate:
        return 'rate';
      case ErpLineItemTableColumn.discount:
        return 'discount';
      case ErpLineItemTableColumn.taxCode:
        return 'tax';
      case ErpLineItemTableColumn.description:
        return 'description';
      case ErpLineItemTableColumn.remarks:
        return 'remarks';
      case ErpLineItemTableColumn.amount:
        return 'amount';
      case ErpLineItemTableColumn.action:
        return 'action';
    }
  }

  String _columnLabel(ErpLineItemTableColumn column) {
    final override = widget.columnLabels[column];
    if (override != null && override.trim().isNotEmpty) {
      return override;
    }
    switch (column) {
      case ErpLineItemTableColumn.no:
        return 'No';
      case ErpLineItemTableColumn.source:
        return widget.sourceColumnLabel;
      case ErpLineItemTableColumn.item:
        return 'Item';
      case ErpLineItemTableColumn.uom:
        return 'UOM';
      case ErpLineItemTableColumn.warehouse:
        return 'Warehouse';
      case ErpLineItemTableColumn.qty:
        return 'Qty';
      case ErpLineItemTableColumn.rate:
        return 'Rate';
      case ErpLineItemTableColumn.discount:
        return 'Discount %';
      case ErpLineItemTableColumn.taxCode:
        return 'Tax code';
      case ErpLineItemTableColumn.description:
        return 'Description';
      case ErpLineItemTableColumn.remarks:
        return 'Remarks';
      case ErpLineItemTableColumn.amount:
        return 'Amount';
      case ErpLineItemTableColumn.action:
        return 'Action';
    }
  }

  TextStyle _tableHeaderStyle(ThemeData theme, AppThemeExtension appTheme) {
    return theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: appTheme.tableTitleText,
          fontSize: 12,
          height: 1.2,
          letterSpacing: 0.5,
        ) ??
        TextStyle(
          fontWeight: FontWeight.w700,
          color: appTheme.tableTitleText,
          fontSize: 12,
          height: 1.2,
          letterSpacing: 0.5,
        );
  }

  TextStyle _tableCellStyle(ThemeData theme, AppThemeExtension appTheme) {
    return theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: appTheme.tableCellText,
          fontSize: 14,
          height: 1.2,
        ) ??
        TextStyle(
          fontWeight: FontWeight.w500,
          color: appTheme.tableCellText,
          fontSize: 14,
          height: 1.2,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppThemeExtension>()!;
    final tableCellStyle =
        theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: appTheme.tableCellText,
          fontSize: 14,
          height: 1.2,
        ) ??
        TextStyle(
          fontWeight: FontWeight.w500,
          color: appTheme.tableCellText,
          fontSize: 14,
          height: 1.2,
        );
    final compactTheme = theme.copyWith(
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: Colors.transparent,
        isDense: true,
        hintStyle: tableCellStyle.copyWith(color: appTheme.mutedText),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppUiConstants.tableCellPaddingSm,
          vertical: AppUiConstants.tableCellPaddingXs,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppUiConstants.tableRadiusXs),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppUiConstants.tableRadiusXs),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppUiConstants.tableRadiusXs),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppUiConstants.tableRadiusXs),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppUiConstants.tableRadiusXs),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 1.5),
        ),
      ),
    );

    // Apply a slightly larger radius for a modern curved look
    final BorderRadius tableCurve = BorderRadius.circular(12.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: appTheme.tableTitleText,
          ),
        ),
        const SizedBox(height: AppUiConstants.spacingXs),
        DecoratedBox(
          decoration: BoxDecoration(
            color: appTheme.cardBackground,
            borderRadius: tableCurve,
            border: Border.all(
              color: appTheme.tableBorder.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: appTheme.cardShadow.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Theme(
            data: compactTheme,
            child: ClipRRect(
              borderRadius:
                  tableCurve, // Clips inner elements to the curved border
              child: Column(
                children: [
                  Container(
                    height: _tableEdgeWhitespaceHeight,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppUiConstants.tableToolbarPadding,
                    ),
                    decoration: BoxDecoration(
                      color: appTheme.cardBackground,
                      border: Border(
                        bottom: BorderSide(color: appTheme.tableBorder),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Spacer(),
                        if (widget.onAddLine != null)
                          TextButton.icon(
                            onPressed: widget.enabled ? widget.onAddLine : null,
                            icon: const Icon(Icons.add, size: 16),
                            label: Text(widget.addButtonLabel),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppUiConstants.tableCellPaddingSm,
                                vertical: AppUiConstants.tableCellPaddingXs,
                              ),
                              foregroundColor: appTheme.tableLinkText,
                            ),
                          ),
                      ],
                    ),
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final extraWidthPerWeight = _extraWidthPerWeight(
                        constraints.maxWidth,
                      );
                      return Scrollbar(
                        controller: _horizontalController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _horizontalController,
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: constraints.maxWidth > _tableMinWidth
                                  ? constraints.maxWidth
                                  : _tableMinWidth,
                            ),
                            child: Column(
                              children: [
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: appTheme.tableHeaderBackground,
                                    border: Border(
                                      bottom: BorderSide(
                                        color: appTheme.tableBorder,
                                      ),
                                    ),
                                  ),
                                  child: _buildHeaderRow(
                                    theme,
                                    appTheme,
                                    extraWidthPerWeight,
                                  ),
                                ),
                                for (
                                  var index = 0;
                                  index < widget.lines.length;
                                  index++
                                )
                                  _buildDataRow(
                                    context,
                                    index,
                                    widget.lines[index],
                                    appTheme,
                                    extraWidthPerWeight,
                                  ),
                                const SizedBox(
                                  height: _tableEdgeWhitespaceHeight,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.footer != null) ...[
          const SizedBox(height: AppUiConstants.spacingSm),
          widget.footer!,
        ],
      ],
    );
  }

  Widget _buildHeaderRow(
    ThemeData theme,
    AppThemeExtension appTheme,
    double extraWidthPerWeight,
  ) {
    final style = _tableHeaderStyle(theme, appTheme);
    final columns = _orderedColumns;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List<Widget>.generate(columns.length, (index) {
        final column = columns[index];
        return _headerCell(
          column is ErpLineItemTableColumn
              ? _columnLabel(column)
              : (column as ErpLineItemCustomColumn).label,
          column is ErpLineItemTableColumn
              ? _resolvedColumnWidth(column, extraWidthPerWeight)
              : (column as ErpLineItemCustomColumn).width,
          style,
          appTheme,
          showRightBorder: index != columns.length - 1,
        );
      }),
    );
  }

  Widget _buildDataRow(
    BuildContext context,
    int index,
    ErpLineItemTableRow row,
    AppThemeExtension appTheme,
    double extraWidthPerWeight,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tableCellStyle = _tableCellStyle(theme, appTheme);
    final columns = _orderedColumns;
    final selected = _selectedIndex == index;
    final hovered = _hoveredIndex == index;
    final background = selected
        ? appTheme.tableRowSelected
        : hovered
        ? appTheme.tableRowHover
        : (index % 2 == 1)
        ? appTheme.subtleFill.withValues(alpha: 0.3)
        : appTheme.cardBackground;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _selectedIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          key: ValueKey<Object>(row.rowKey),
          decoration: BoxDecoration(
            color: background,
            border: Border(
              // Only draw a left border if it is actively selected
              left: selected
                  ? BorderSide(
                      color: colors.primary.withValues(alpha: 0.8),
                      width: 2,
                    )
                  : BorderSide.none,
              bottom: BorderSide(color: appTheme.tableBorder),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List<Widget>.generate(columns.length, (columnIndex) {
              final column = columns[columnIndex];
              if (column is ErpLineItemTableColumn) {
                return _buildDataColumn(
                  context: context,
                  index: index,
                  row: row,
                  appTheme: appTheme,
                  tableCellStyle: tableCellStyle,
                  selected: selected,
                  column: column,
                  extraWidthPerWeight: extraWidthPerWeight,
                  showRightBorder: columnIndex != columns.length - 1,
                );
              }
              return _buildCustomDataColumn(
                row: row,
                appTheme: appTheme,
                column: column as ErpLineItemCustomColumn,
                showRightBorder: columnIndex != columns.length - 1,
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildDataColumn({
    required BuildContext context,
    required int index,
    required ErpLineItemTableRow row,
    required AppThemeExtension appTheme,
    required TextStyle tableCellStyle,
    required bool selected,
    required ErpLineItemTableColumn column,
    required double extraWidthPerWeight,
    required bool showRightBorder,
  }) {
    final theme = Theme.of(context);
    final columnWidth = _resolvedColumnWidth(column, extraWidthPerWeight);
    final overrideCell = row.cellWidgets[column];
    if (overrideCell != null) {
      return _dataCell(
        width: columnWidth,
        borderColor: appTheme.tableBorder,
        showRightBorder: showRightBorder,
        child: overrideCell,
      );
    }
    switch (column) {
      case ErpLineItemTableColumn.no:
        return _dataCell(
          width: columnWidth,
          borderColor: appTheme.tableBorder,
          showRightBorder: showRightBorder,
          child: Padding(
            padding: EdgeInsets.only(
              left: selected
                  ? AppUiConstants.tableCellPaddingSm
                  : AppUiConstants.spacingSm,
              right: AppUiConstants.spacingXs,
              top: AppUiConstants.spacingSm,
              bottom: AppUiConstants.spacingSm,
            ),
            child: Text(
              '${index + 1}',
              style: tableCellStyle.copyWith(
                fontWeight: FontWeight.w600,
                color: appTheme.tableLinkText,
              ),
            ),
          ),
        );
      case ErpLineItemTableColumn.source:
        return _dataCell(
          width: columnWidth,
          borderColor: appTheme.tableBorder,
          showRightBorder: showRightBorder,
          child: _buildSourceCell(row),
        );
      case ErpLineItemTableColumn.item:
        return _dataCell(
          width: columnWidth,
          borderColor: appTheme.tableBorder,
          showRightBorder: showRightBorder,
          child: _compactDropdown<int>(
            child: ErpLinkField<int>(
              labelText: '',
              hintText: 'Select item',
              fieldPadding: EdgeInsets.zero,
              initialSelection: row.itemSelection,
              options: row.itemOptions,
              onChanged: widget.enabled
                  ? (value) {
                      row.onItemChanged?.call(value);
                      _notifyChanged();
                    }
                  : (_) {},
              validator: row.itemValidator == null
                  ? null
                  : (_) =>
                        row.itemValidator!.call(row.itemSelection?.label ?? ''),
              enabled: widget.enabled && row.onItemChanged != null,
            ),
          ),
        );
      case ErpLineItemTableColumn.uom:
        return _dataCell(
          width: columnWidth,
          borderColor: appTheme.tableBorder,
          showRightBorder: showRightBorder,
          child: _compactDropdown<int>(
            child: AppDropdownField<int>.fromMapped(
              labelText: '',
              hintText: 'UOM',
              fieldPadding: EdgeInsets.zero,
              mappedItems: row.uomOptions,
              initialValue: row.uomId,
              onChanged: widget.enabled
                  ? (value) {
                      row.onUomChanged?.call(value);
                      _notifyChanged();
                    }
                  : null,
              validator: row.uomValidator,
              enabled: widget.enabled && row.onUomChanged != null,
            ),
          ),
        );
      case ErpLineItemTableColumn.warehouse:
        return _dataCell(
          width: columnWidth,
          borderColor: appTheme.tableBorder,
          showRightBorder: showRightBorder,
          child: _compactDropdown<int>(
            child: AppDropdownField<int>.fromMapped(
              labelText: '',
              hintText: 'Warehouse',
              fieldPadding: EdgeInsets.zero,
              mappedItems: row.warehouseOptions,
              initialValue: row.warehouseId,
              onChanged: widget.enabled
                  ? (value) {
                      row.onWarehouseChanged?.call(value);
                      _notifyChanged();
                    }
                  : null,
              enabled: widget.enabled && row.onWarehouseChanged != null,
            ),
          ),
        );
      case ErpLineItemTableColumn.qty:
        return _dataCell(
          width: columnWidth,
          borderColor: appTheme.tableBorder,
          showRightBorder: showRightBorder,
          child: row.qtyController == null
              ? const SizedBox.shrink()
              : _compactTextField(
                  controller: row.qtyController!,
                  hintText: _columnLabel(ErpLineItemTableColumn.qty),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: row.qtyValidator,
                  onChanged: (value) {
                    row.onQtyChanged?.call(value);
                    _notifyChanged();
                  },
                ),
        );
      case ErpLineItemTableColumn.rate:
        return _dataCell(
          width: columnWidth,
          borderColor: appTheme.tableBorder,
          showRightBorder: showRightBorder,
          child: row.rateController == null
              ? const SizedBox.shrink()
              : _compactTextField(
                  controller: row.rateController!,
                  hintText: _columnLabel(ErpLineItemTableColumn.rate),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: row.rateValidator,
                  onChanged: (value) {
                    row.onRateChanged?.call(value);
                    _notifyChanged();
                  },
                ),
        );
      case ErpLineItemTableColumn.discount:
        return _dataCell(
          width: columnWidth,
          borderColor: appTheme.tableBorder,
          showRightBorder: showRightBorder,
          child: row.discountController == null
              ? const SizedBox.shrink()
              : _compactTextField(
                  controller: row.discountController!,
                  hintText: '0',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: row.discountValidator,
                  onChanged: (value) {
                    row.onDiscountChanged?.call(value);
                    _notifyChanged();
                  },
                ),
        );
      case ErpLineItemTableColumn.taxCode:
        return _dataCell(
          width: columnWidth,
          borderColor: appTheme.tableBorder,
          showRightBorder: showRightBorder,
          child: _compactDropdown<int>(
            child: AppDropdownField<int>.fromMapped(
              labelText: '',
              hintText: 'Tax',
              fieldPadding: EdgeInsets.zero,
              mappedItems: row.taxOptions,
              initialValue: row.taxCodeId,
              onChanged: widget.enabled
                  ? (value) {
                      row.onTaxCodeChanged?.call(value);
                      _notifyChanged();
                    }
                  : null,
              enabled: widget.enabled && row.onTaxCodeChanged != null,
            ),
          ),
        );
      case ErpLineItemTableColumn.description:
        return _dataCell(
          width: columnWidth,
          borderColor: appTheme.tableBorder,
          showRightBorder: showRightBorder,
          child: row.descriptionController == null
              ? const SizedBox.shrink()
              : _compactTextField(
                  controller: row.descriptionController!,
                  hintText: 'Description',
                  onChanged: (value) {
                    row.onDescriptionChanged?.call(value);
                    _notifyChanged();
                  },
                ),
        );
      case ErpLineItemTableColumn.remarks:
        return _dataCell(
          width: columnWidth,
          borderColor: appTheme.tableBorder,
          showRightBorder: showRightBorder,
          child: row.remarksController == null
              ? const SizedBox.shrink()
              : _compactTextField(
                  controller: row.remarksController!,
                  hintText: 'Remarks',
                  onChanged: (value) {
                    row.onRemarksChanged?.call(value);
                    _notifyChanged();
                  },
                ),
        );
      case ErpLineItemTableColumn.amount:
        return _dataCell(
          width: columnWidth,
          borderColor: appTheme.tableBorder,
          showRightBorder: showRightBorder,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppUiConstants.spacingSm,
              AppUiConstants.spacingMd,
              AppUiConstants.spacingSm,
              AppUiConstants.spacingMd,
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                formatAmount(row.amount),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: appTheme.tableCellText,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      case ErpLineItemTableColumn.action:
        return _dataCell(
          width: columnWidth,
          borderColor: appTheme.tableBorder,
          showRightBorder: showRightBorder,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppUiConstants.tableCompactFieldInset,
              vertical: AppUiConstants.tableCellPaddingSm,
            ),
            child: Center(
              child: IconButton(
                tooltip: 'Delete row',
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  backgroundColor: appTheme.cardBackground,
                  foregroundColor: appTheme.mutedText,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppUiConstants.tableRadiusXs,
                    ),
                    side: BorderSide(color: appTheme.tableBorder),
                  ),
                ),
                onPressed:
                    widget.enabled &&
                        row.deleteEnabled &&
                        widget.onDeleteLine != null
                    ? () {
                        widget.onDeleteLine!(index);
                        _notifyChanged();
                      }
                    : null,
                icon: const Icon(Icons.delete_outline, size: 18),
              ),
            ),
          ),
        );
    }
  }

  Widget _buildCustomDataColumn({
    required ErpLineItemTableRow row,
    required AppThemeExtension appTheme,
    required ErpLineItemCustomColumn column,
    required bool showRightBorder,
  }) {
    return _dataCell(
      width: column.width,
      borderColor: appTheme.tableBorder,
      showRightBorder: showRightBorder,
      child: row.customCells[column.id] ?? const SizedBox.shrink(),
    );
  }

  Widget _buildSourceCell(ErpLineItemTableRow row) {
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppThemeExtension>()!;
    if (row.sourceLineOptions.isEmpty || row.onSourceLineChanged == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppUiConstants.tableToolbarPadding,
          AppUiConstants.spacingSm,
          AppUiConstants.spacingSm,
          AppUiConstants.spacingSm,
        ),
        child: Text(
          '—',
          style: _tableCellStyle(
            theme,
            appTheme,
          ).copyWith(color: appTheme.mutedText, fontWeight: FontWeight.w600),
        ),
      );
    }

    return _compactDropdown<int?>(
      child: AppDropdownField<int?>.fromMapped(
        labelText: '',
        hintText: 'Source',
        fieldPadding: EdgeInsets.zero,
        mappedItems: row.sourceLineOptions,
        initialValue: row.sourceLineId,
        onChanged: widget.enabled
            ? (value) {
                row.onSourceLineChanged?.call(value);
                _notifyChanged();
              }
            : null,
        enabled: widget.enabled,
      ),
    );
  }

  Widget _compactTextField({
    required TextEditingController controller,
    required String hintText,
    ValueChanged<String>? onChanged,
    FormFieldValidator<String>? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    TextAlign? textAlign,
  }) {
    return _ErpCompactTextField(
      controller: controller,
      hintText: hintText,
      onChanged: onChanged,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textAlign: textAlign,
    );
  }

  Widget _compactDropdown<T>({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.all(AppUiConstants.tableCompactFieldInset),
      child: SizedBox(
        height: AppUiConstants.tableCompactFieldHeight,
        child: child,
      ),
    );
  }

  Widget _headerCell(
    String label,
    double width,
    TextStyle? style,
    AppThemeExtension appTheme, {
    bool showRightBorder = true,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(AppUiConstants.spacingSm),
      decoration: BoxDecoration(
        color: appTheme.tableHeaderBackground,
        border: Border(
          right: showRightBorder
              ? BorderSide(color: appTheme.tableBorder)
              : BorderSide.none,
          bottom: BorderSide.none,
        ),
      ),
      child: Center(
        child: Text(label, style: style, textAlign: TextAlign.center),
      ),
    );
  }

  Widget _dataCell({
    required double width,
    required Widget child,
    required Color borderColor,
    bool showRightBorder = true,
  }) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        border: Border(
          right: showRightBorder
              ? BorderSide(color: borderColor)
              : BorderSide.none,
        ),
      ),
      child: child,
    );
  }
}

class _ErpCompactTextField extends StatefulWidget {
  const _ErpCompactTextField({
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.textAlign,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final TextAlign? textAlign;

  @override
  State<_ErpCompactTextField> createState() => _ErpCompactTextFieldState();
}

class _ErpCompactTextFieldState extends State<_ErpCompactTextField> {
  final NumericFieldFocusBinding _numericBinding = NumericFieldFocusBinding();

  bool get _isNumericField =>
      NumericFieldFocusBinding.isNumericKeyboard(widget.keyboardType);

  @override
  void initState() {
    super.initState();
    final created = _numericBinding.sync(
      enable: _isNumericField,
      controller: widget.controller,
    );
    if (created) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          NumericFieldFocusBinding.applyFormattedDisplay(widget.controller);
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant _ErpCompactTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final created = _numericBinding.sync(
      enable: _isNumericField,
      controller: widget.controller,
    );
    if (created) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          NumericFieldFocusBinding.applyFormattedDisplay(widget.controller);
        }
      });
    }
  }

  @override
  void dispose() {
    _numericBinding.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppThemeExtension>()!;
    final tableCellStyle =
        theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: appTheme.tableCellText,
          fontSize: 14,
          height: 1.2,
        ) ??
        TextStyle(
          fontWeight: FontWeight.w500,
          color: appTheme.tableCellText,
          fontSize: 14,
          height: 1.2,
        );
    final compactErrorStyle = theme.textTheme.bodySmall?.copyWith(
      fontSize: 0,
      height: 0.01,
      color: Colors.transparent,
    );

    return Padding(
      padding: const EdgeInsets.all(AppUiConstants.tableCompactFieldInset),
      child: SizedBox(
        height: AppUiConstants.tableCompactFieldHeight,
        child: TextFormField(
          controller: widget.controller,
          focusNode: _numericBinding.focusNode,
          maxLines: widget.maxLines,
          keyboardType: widget.keyboardType,
          onChanged: widget.onChanged,
          validator: widget.validator,
          textAlign:
              widget.textAlign ??
              (_isNumericField ? TextAlign.right : TextAlign.start),
          textAlignVertical: TextAlignVertical.center,
          style: tableCellStyle,
          inputFormatters: widget.keyboardType == null
              ? null
              : <TextInputFormatter>[
                  if (_isNumericField) const NumericInputFormatter(),
                ],
          decoration: InputDecoration(
            isDense: true,
            hintText: widget.hintText,
            errorStyle: compactErrorStyle,
            errorMaxLines: 1,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppUiConstants.tableCellPaddingSm,
              vertical: AppUiConstants.tableCellPaddingXs,
            ),
          ),
        ),
      ),
    );
  }
}
