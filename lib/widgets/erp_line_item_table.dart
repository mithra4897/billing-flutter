import '../screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    required this.qtyController,
    this.onQtyChanged,
    this.qtyValidator,
    required this.rateController,
    this.onRateChanged,
    this.rateValidator,
    required this.discountController,
    this.onDiscountChanged,
    this.discountValidator,
    required this.descriptionController,
    this.onDescriptionChanged,
    required this.remarksController,
    this.onRemarksChanged,
    required this.amount,
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
  final TextEditingController qtyController;
  final ValueChanged<String>? onQtyChanged;
  final FormFieldValidator<String>? qtyValidator;
  final TextEditingController rateController;
  final ValueChanged<String>? onRateChanged;
  final FormFieldValidator<String>? rateValidator;
  final TextEditingController discountController;
  final ValueChanged<String>? onDiscountChanged;
  final FormFieldValidator<String>? discountValidator;
  final TextEditingController descriptionController;
  final ValueChanged<String>? onDescriptionChanged;
  final TextEditingController remarksController;
  final ValueChanged<String>? onRemarksChanged;
  final double amount;
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
    this.sourceColumnLabel = 'Source line',
    this.enabled = true,
  });

  final List<ErpLineItemTableRow> lines;
  final ValueChanged<List<ErpLineItemTableRow>>? onChanged;
  final VoidCallback? onAddLine;
  final ValueChanged<int>? onDeleteLine;
  final Widget? footer;
  final String addButtonLabel;
  final String sourceColumnLabel;
  final bool enabled;

  @override
  State<ErpLineItemTable> createState() => _ErpLineItemTableState();
}

class _ErpLineItemTableState extends State<ErpLineItemTable> {
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
    'action': 64,
  };

  final ScrollController _horizontalController = ScrollController();
  int? _selectedIndex;
  int? _hoveredIndex;

  double get _tableMinWidth =>
      _columnWidths.values.fold<double>(0, (sum, width) => sum + width);

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  void _notifyChanged() {
    widget.onChanged?.call(widget.lines);
  }

  TextStyle _tableHeaderStyle(ThemeData theme, AppThemeExtension appTheme) {
    return theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: appTheme.tableMutedText,
      fontSize: 14,
      height: 1.2,
      letterSpacing: 0.1,
    ) ??
        TextStyle(
          fontWeight: FontWeight.w700,
          color: appTheme.tableMutedText,
          fontSize: 14,
          height: 1.2,
          letterSpacing: 0.1,
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
    final tableCellStyle = _tableCellStyle(theme, appTheme);
    final compactTheme = theme.copyWith(
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: appTheme.cardBackground,
        isDense: true,
        hintStyle: tableCellStyle.copyWith(
          color: appTheme.mutedText,
        ),
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
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppUiConstants.tableRadiusXs),
          borderSide: BorderSide.none,
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppUiConstants.tableRadiusXs),
          borderSide: BorderSide.none,
        ),
      ),
    );

    // Apply a slightly larger radius for a modern curved look
    final BorderRadius tableCurve = BorderRadius.circular(12.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Line items',
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
            border: Border.all(color: appTheme.tableBorder), // Outer border handles edges
          ),
          child: Theme(
            data: compactTheme,
            child: ClipRRect(
              borderRadius: tableCurve, // Clips inner elements to the curved border
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(
                      AppUiConstants.tableToolbarPadding,
                      AppUiConstants.tableToolbarHeight,
                      AppUiConstants.tableToolbarPadding,
                      AppUiConstants.tableToolbarHeight,
                    ),
                    decoration: BoxDecoration(
                      color: appTheme.cardBackground,
                      border: Border(
                        bottom: BorderSide(color: appTheme.tableBorder),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppUiConstants.spacingSm,
                            vertical: AppUiConstants.spacingXs,
                          ),
                          decoration: BoxDecoration(
                            color: appTheme.tableHeaderBackground,
                            borderRadius: BorderRadius.circular(
                              AppUiConstants.pillRadius,
                            ),
                            border: Border.all(color: appTheme.tableBorder),
                          ),
                          child: Text(
                            '${widget.lines.length} row${widget.lines.length == 1 ? '' : 's'}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: appTheme.tableMutedText,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              height: 1.1,
                            ),
                          ),
                        ),
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
                  Scrollbar(
                    controller: _horizontalController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _horizontalController,
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: _tableMinWidth),
                        child: Column(
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: appTheme.tableHeaderBackground,
                                border: Border(
                                  bottom: BorderSide(color: appTheme.tableBorder),
                                ),
                              ),
                              child: _buildHeaderRow(theme, appTheme),
                            ),
                            for (var index = 0; index < widget.lines.length; index++)
                              _buildDataRow(
                                context,
                                index,
                                widget.lines[index],
                                appTheme,
                              ),
                          ],
                        ),
                      ),
                    ),
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

  Widget _buildHeaderRow(ThemeData theme, AppThemeExtension appTheme) {
    final style = _tableHeaderStyle(theme, appTheme);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _headerCell('No', _columnWidths['no']!, style, appTheme),
        _headerCell(widget.sourceColumnLabel, _columnWidths['source']!, style, appTheme),
        _headerCell('Item', _columnWidths['item']!, style, appTheme),
        _headerCell('UOM', _columnWidths['uom']!, style, appTheme),
        _headerCell('Warehouse', _columnWidths['warehouse']!, style, appTheme),
        _headerCell('Qty', _columnWidths['qty']!, style, appTheme),
        _headerCell('Rate', _columnWidths['rate']!, style, appTheme),
        _headerCell('Discount %', _columnWidths['discount']!, style, appTheme),
        _headerCell('Tax code', _columnWidths['tax']!, style, appTheme),
        _headerCell('Description', _columnWidths['description']!, style, appTheme),
        _headerCell('Remarks', _columnWidths['remarks']!, style, appTheme),
        _headerCell('Amount', _columnWidths['amount']!, style, appTheme),
        // Hide right border on the last column to prevent double-border overlap
        _headerCell('Action', _columnWidths['action']!, style, appTheme, showRightBorder: false),
      ],
    );
  }

  Widget _buildDataRow(
      BuildContext context,
      int index,
      ErpLineItemTableRow row,
      AppThemeExtension appTheme,
      ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tableCellStyle = _tableCellStyle(theme, appTheme);
    final selected = _selectedIndex == index;
    final hovered = _hoveredIndex == index;
    final background = selected
        ? appTheme.tableRowSelected
        : hovered
        ? appTheme.tableRowHover
        : appTheme.cardBackground;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _selectedIndex = index),
        child: DecoratedBox(
          key: ObjectKey(row.rowKey),
          decoration: BoxDecoration(
            color: background,
            border: Border(
              // Only draw a left border if it is actively selected
              left: selected
                  ? BorderSide(color: colors.primary.withValues(alpha: 0.8), width: 2)
                  : BorderSide.none,
              bottom: BorderSide(color: appTheme.tableBorder),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dataCell(
                width: _columnWidths['no']!,
                borderColor: appTheme.tableBorder,
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
              ),
              _dataCell(
                width: _columnWidths['source']!,
                borderColor: appTheme.tableBorder,
                child: _buildSourceCell(row),
              ),
              _dataCell(
                width: _columnWidths['item']!,
                borderColor: appTheme.tableBorder,
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
              ),
              _dataCell(
                width: _columnWidths['uom']!,
                borderColor: appTheme.tableBorder,
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
              ),
              _dataCell(
                width: _columnWidths['warehouse']!,
                borderColor: appTheme.tableBorder,
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
              ),
              _dataCell(
                width: _columnWidths['qty']!,
                borderColor: appTheme.tableBorder,
                child: _compactTextField(
                  controller: row.qtyController,
                  hintText: 'Qty',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: row.qtyValidator,
                  onChanged: (value) {
                    row.onQtyChanged?.call(value);
                    _notifyChanged();
                  },
                ),
              ),
              _dataCell(
                width: _columnWidths['rate']!,
                borderColor: appTheme.tableBorder,
                child: _compactTextField(
                  controller: row.rateController,
                  hintText: 'Rate',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: row.rateValidator,
                  onChanged: (value) {
                    row.onRateChanged?.call(value);
                    _notifyChanged();
                  },
                ),
              ),
              _dataCell(
                width: _columnWidths['discount']!,
                borderColor: appTheme.tableBorder,
                child: _compactTextField(
                  controller: row.discountController,
                  hintText: '0',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: row.discountValidator,
                  onChanged: (value) {
                    row.onDiscountChanged?.call(value);
                    _notifyChanged();
                  },
                ),
              ),
              _dataCell(
                width: _columnWidths['tax']!,
                borderColor: appTheme.tableBorder,
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
              ),
              _dataCell(
                width: _columnWidths['description']!,
                borderColor: appTheme.tableBorder,
                child: _compactTextField(
                  controller: row.descriptionController,
                  hintText: 'Description',
                  onChanged: (value) {
                    row.onDescriptionChanged?.call(value);
                    _notifyChanged();
                  },
                ),
              ),
              _dataCell(
                width: _columnWidths['remarks']!,
                borderColor: appTheme.tableBorder,
                child: _compactTextField(
                  controller: row.remarksController,
                  hintText: 'Remarks',
                  onChanged: (value) {
                    row.onRemarksChanged?.call(value);
                    _notifyChanged();
                  },
                ),
              ),
              _dataCell(
                width: _columnWidths['amount']!,
                borderColor: appTheme.tableBorder,
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
                      row.amount.toStringAsFixed(2),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: appTheme.tableCellText,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              _dataCell(
                width: _columnWidths['action']!,
                borderColor: appTheme.tableBorder,
                showRightBorder: false, // Prevent double right border
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
              ),
            ],
          ),
        ),
      ),
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
          style: _tableCellStyle(theme, appTheme).copyWith(
            color: appTheme.mutedText,
            fontWeight: FontWeight.w600,
          ),
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
  }) {
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppThemeExtension>()!;
    final tableCellStyle = _tableCellStyle(theme, appTheme);
    return Padding(
      padding: const EdgeInsets.all(AppUiConstants.tableCompactFieldInset),
      child: SizedBox(
        height: AppUiConstants.tableCompactFieldHeight,
        child: TextFormField(
          key: ObjectKey(controller),
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
          validator: validator,
          textAlignVertical: TextAlignVertical.center,
          style: tableCellStyle,
          inputFormatters: keyboardType == null
              ? null
              : <TextInputFormatter>[
            if (NumericFieldFocusBinding.isNumericKeyboard(keyboardType))
              const NumericInputFormatter(),
          ],
          decoration: InputDecoration(
            isDense: true,
            hintText: hintText,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppUiConstants.tableCellPaddingSm,
              vertical: AppUiConstants.tableCellPaddingXs,
            ),
          ),
        ),
      ),
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
      child: Text(label, style: style),
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
          right: showRightBorder ? BorderSide(color: borderColor) : BorderSide.none,
        ),
      ),
      child: child,
    );
  }
}