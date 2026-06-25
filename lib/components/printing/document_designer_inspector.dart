import 'dart:math' as math;

import '../../screen.dart';

const double _designerInspectorSectionGap = 8;
const double _designerInspectorRowPadding = 5;
const double _designerInspectorFieldPadding = 4;

class DocumentDesignerPageInspector extends StatelessWidget {
  const DocumentDesignerPageInspector({
    super.key,
    required this.template,
    required this.onChanged,
    required this.isUploadingBackground,
    required this.onUploadBackground,
  });

  final DocumentPrintTemplate template;
  final ValueChanged<DocumentPrintTemplate> onChanged;
  final bool isUploadingBackground;
  final Future<void> Function() onUploadBackground;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Page', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: _designerInspectorSectionGap),
        DocumentDesignerPropertyGrid(
          rows: [
            DocumentDesignerPropertyGridRow(
              label: 'Paper',
              child: _CompactDropdownField<String>(
                value: template.mediaPreset,
                items: const [
                  DropdownMenuItem(value: 'A4', child: Text('A4')),
                  DropdownMenuItem(value: 'A5', child: Text('A5')),
                  DropdownMenuItem(value: 'LETTER', child: Text('Letter')),
                  DropdownMenuItem(value: 'CUSTOM', child: Text('Custom')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    onChanged(
                      applyPrintPagePreset(template, mediaPreset: value),
                    );
                  }
                },
              ),
            ),
            DocumentDesignerPropertyGridRow(
              label: 'Orientation',
              child: _CompactDropdownField<String>(
                value: template.orientation,
                items: const [
                  DropdownMenuItem(value: 'portrait', child: Text('Portrait')),
                  DropdownMenuItem(
                    value: 'landscape',
                    child: Text('Landscape'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    onChanged(
                      applyPrintPagePreset(template, orientation: value),
                    );
                  }
                },
              ),
            ),
            DocumentDesignerPropertyGridRow(
              label: 'Width',
              child: DocumentDesignerNumberField(
                label: '',
                value: template.pageWidth,
                onChanged: (value) => onChanged(
                  template.copyWith(
                    pageWidth: math.max(320, value),
                    mediaPreset: 'CUSTOM',
                  ),
                ),
              ),
            ),
            DocumentDesignerPropertyGridRow(
              label: 'Height',
              child: DocumentDesignerNumberField(
                label: '',
                value: template.pageHeight,
                onChanged: (value) => onChanged(
                  template.copyWith(
                    pageHeight: math.max(400, value),
                    mediaPreset: 'CUSTOM',
                  ),
                ),
              ),
            ),
            DocumentDesignerPropertyGridRow(
              label: 'Font Family',
              child: _CompactDropdownField<String>(
                value: template.fontFamily,
                items: documentPrintFontFamilyOptions
                    .map(
                      (value) => DropdownMenuItem<String>(
                        value: value,
                        child: Text(documentPrintFontFamilyLabel(value)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) {
                    onChanged(template.copyWith(fontFamily: value));
                  }
                },
              ),
            ),
            DocumentDesignerPropertyGridRow(
              label: 'Show Grid',
              child: Align(
                alignment: Alignment.centerLeft,
                child: Switch(
                  value: template.showGrid,
                  onChanged: (value) =>
                      onChanged(template.copyWith(showGrid: value)),
                ),
              ),
            ),
            DocumentDesignerPropertyGridRow(
              label: 'Grid Size',
              child: DocumentDesignerNumberField(
                label: '',
                value: template.gridSize,
                onChanged: (value) => onChanged(
                  template.copyWith(gridSize: value.clamp(4, 64).toDouble()),
                ),
              ),
            ),
            DocumentDesignerPropertyGridRow(
              label: 'Watermark',
              child: DocumentDesignerBackgroundImageField(
                value: template.backgroundImagePath ?? '',
                isUploading: isUploadingBackground,
                onChanged: (value) => onChanged(
                  template.copyWith(
                    backgroundImagePath: value.trim().isEmpty ? null : value,
                  ),
                ),
                onUpload: onUploadBackground,
              ),
            ),
            DocumentDesignerPropertyGridRow(
              label: 'Watermark Opacity',
              child: DocumentDesignerNumberField(
                label: '',
                value: template.backgroundOpacity,
                fractionDigits: 2,
                onChanged: (value) => onChanged(
                  template.copyWith(
                    backgroundOpacity: value.clamp(0.0, 1.0).toDouble(),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: _designerInspectorSectionGap),
        Text(
          'Select a shape on the page to edit it.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class DocumentDesignerShapeInspector extends StatelessWidget {
  const DocumentDesignerShapeInspector({
    super.key,
    required this.shape,
    required this.bindings,
    required this.listBindings,
    required this.rowBindings,
    required this.isUploadingImage,
    required this.onChanged,
    required this.onUploadImage,
    required this.onDelete,
    required this.onBringForward,
    required this.onSendBackward,
    required this.onBringToFront,
    required this.onSendToBack,
    required this.onDuplicate,
  });

  final DocumentPrintShape shape;
  final List<String> bindings;
  final List<String> listBindings;
  final List<String> rowBindings;
  final bool isUploadingImage;
  final ValueChanged<DocumentPrintShape> onChanged;
  final Future<void> Function() onUploadImage;
  final VoidCallback onDelete;
  final VoidCallback onBringForward;
  final VoidCallback onSendBackward;
  final VoidCallback onBringToFront;
  final VoidCallback onSendToBack;
  final VoidCallback onDuplicate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                shape.typeLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              tooltip: 'Send backward',
              onPressed: onSendBackward,
              icon: const Icon(Icons.arrow_downward_outlined),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            ),
            IconButton(
              tooltip: 'Bring forward',
              onPressed: onBringForward,
              icon: const Icon(Icons.arrow_upward_outlined),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            ),
            IconButton(
              tooltip: 'Send to back',
              onPressed: onSendToBack,
              icon: const Icon(Icons.vertical_align_bottom_outlined),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            ),
            IconButton(
              tooltip: 'Bring to front',
              onPressed: onBringToFront,
              icon: const Icon(Icons.vertical_align_top_outlined),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            ),
            IconButton(
              tooltip: 'Duplicate',
              onPressed: onDuplicate,
              icon: const Icon(Icons.copy_outlined),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            ),
            IconButton(
              tooltip: 'Delete',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            ),
          ],
        ),
        const SizedBox(height: _designerInspectorSectionGap),
        DocumentDesignerPropertyGrid(
          rows: [
            DocumentDesignerPropertyGridRow(
              label: 'X',
              child: DocumentDesignerNumberField(
                label: '',
                value: shape.x,
                onChanged: (value) =>
                    onChanged(shape.copyWith(x: math.max(0, value))),
              ),
            ),
            DocumentDesignerPropertyGridRow(
              label: 'Y',
              child: DocumentDesignerNumberField(
                label: '',
                value: shape.y,
                onChanged: (value) =>
                    onChanged(shape.copyWith(y: math.max(0, value))),
              ),
            ),
            DocumentDesignerPropertyGridRow(
              label: 'Width',
              child: DocumentDesignerNumberField(
                label: '',
                value: shape.width,
                onChanged: (value) =>
                    onChanged(shape.copyWith(width: math.max(24, value))),
              ),
            ),
            DocumentDesignerPropertyGridRow(
              label: 'Height',
              child: DocumentDesignerNumberField(
                label: '',
                value: shape.height,
                onChanged: (value) =>
                    onChanged(shape.copyWith(height: math.max(16, value))),
              ),
            ),
            DocumentDesignerPropertyGridRow(
              label: 'Stroke Width',
              child: DocumentDesignerNumberField(
                label: '',
                value: shape.strokeWidth,
                fractionDigits: 2,
                onChanged: (value) =>
                    onChanged(shape.copyWith(strokeWidth: math.max(0, value))),
              ),
            ),
            DocumentDesignerPropertyGridRow(
              label: switch (shape.type) {
                'text' => 'Text Color',
                'rectangle' => 'Border Color',
                'ellipse' => 'Border Color',
                'polygon' => 'Border Color',
                'line' => 'Line Color',
                'table' => 'Grid Color',
                'barcode' => 'Barcode Color',
                _ => 'Stroke Color',
              },
              child: DocumentDesignerColorField(
                label: '',
                value: shape.strokeColor,
                onChanged: (value) =>
                    onChanged(shape.copyWith(strokeColor: value)),
              ),
            ),
            DocumentDesignerPropertyGridRow(
              label: shape.type == 'table' ? 'Background Color' : 'Fill Color',
              child: DocumentDesignerColorField(
                label: '',
                value: shape.fillColor,
                onChanged: (value) {
                  var next = shape.copyWith(fillColor: value);
                  if (value != 0xFFFFFFFF && shape.fillAlpha == 0) {
                    next = next.copyWith(fillAlpha: 1.0);
                  }
                  onChanged(next);
                },
              ),
            ),
            DocumentDesignerPropertyGridRow(
              label: 'Fill Alpha',
              child: DocumentDesignerNumberField(
                label: '',
                value: shape.fillAlpha,
                fractionDigits: 2,
                onChanged: (value) => onChanged(
                  shape.copyWith(fillAlpha: value.clamp(0, 1).toDouble()),
                ),
              ),
            ),
          ],
        ),
        if (shape.type == 'table') ...[
          const SizedBox(height: _designerInspectorSectionGap),
          DocumentDesignerPropertyGrid(
            rows: [
              DocumentDesignerPropertyGridRow(
                label: 'Body Text Color',
                child: DocumentDesignerColorField(
                  label: '',
                  value: shape.bodyTextColor,
                  onChanged: (value) =>
                      onChanged(shape.copyWith(bodyTextColor: value)),
                ),
              ),
              DocumentDesignerPropertyGridRow(
                label: 'Header Fill Color',
                child: DocumentDesignerColorField(
                  label: '',
                  value: shape.headerColor,
                  onChanged: (value) =>
                      onChanged(shape.copyWith(headerColor: value)),
                ),
              ),
              DocumentDesignerPropertyGridRow(
                label: 'Header Text Color',
                child: DocumentDesignerColorField(
                  label: '',
                  value: shape.headerTextColor,
                  onChanged: (value) =>
                      onChanged(shape.copyWith(headerTextColor: value)),
                ),
              ),
            ],
          ),
          const SizedBox(height: _designerInspectorSectionGap),
          AppSwitchTile(
            label: 'Print Header',
            value: shape.printHeader,
            onChanged: (value) => onChanged(shape.copyWith(printHeader: value)),
          ),
          const SizedBox(height: _designerInspectorSectionGap),
          AppSwitchTile(
            label: 'Print Total Row',
            value: shape.printTotal,
            onChanged: (value) => onChanged(shape.copyWith(printTotal: value)),
          ),
        ],
        if (shape.type == 'text') ...[
          const SizedBox(height: _designerInspectorSectionGap),
          DocumentDesignerStringField(
            label: 'Text',
            value: shape.text,
            maxLines: 4,
            onChanged: (value) =>
                onChanged(shape.copyWith(text: value, multiline: true)),
          ),
          const SizedBox(height: _designerInspectorSectionGap),
          DocumentDesignerNumberField(
            label: 'Font Size',
            value: shape.fontSize,
            onChanged: (value) =>
                onChanged(shape.copyWith(fontSize: math.max(1, value))),
          ),
          const SizedBox(height: _designerInspectorSectionGap),
          _CompactDropdownField<String>(
            value: shape.align,
            items: const [
              DropdownMenuItem(value: 'left', child: Text('Left')),
              DropdownMenuItem(value: 'center', child: Text('Center')),
              DropdownMenuItem(value: 'right', child: Text('Right')),
            ],
            onChanged: (value) {
              if (value != null) {
                onChanged(shape.copyWith(align: value));
              }
            },
          ),
          const SizedBox(height: _designerInspectorSectionGap),
          AppSwitchTile(
            label: 'Bold',
            value: shape.bold,
            onChanged: (value) => onChanged(shape.copyWith(bold: value)),
          ),
          const SizedBox(height: _designerInspectorSectionGap),
          AppSwitchTile(
            label: 'Italic',
            value: shape.italic,
            onChanged: (value) => onChanged(shape.copyWith(italic: value)),
          ),
          const SizedBox(height: _designerInspectorSectionGap),
          AppSwitchTile(
            label: 'Underline',
            value: shape.underline,
            onChanged: (value) => onChanged(shape.copyWith(underline: value)),
          ),
          const SizedBox(height: _designerInspectorSectionGap),
          Text('Bindings', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppUiConstants.spacingXs),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: bindings
                .map(
                  (binding) => ActionChip(
                    label: Text('{{$binding}}'),
                    onPressed: () => onChanged(
                      shape.copyWith(
                        text: shape.text.isEmpty
                            ? '{{$binding}}'
                            : '${shape.text} {{$binding}}',
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
        if (shape.type == 'rectangle') ...[
          const SizedBox(height: _designerInspectorSectionGap),
          DocumentDesignerNumberField(
            label: 'Border Radius',
            value: shape.borderRadius,
            onChanged: (value) =>
                onChanged(shape.copyWith(borderRadius: math.max(0, value))),
          ),
        ],
        if (shape.type == 'polygon') ...[
          const SizedBox(height: _designerInspectorSectionGap),
          DocumentDesignerNumberField(
            label: 'Sides',
            value: shape.sides.toDouble(),
            onChanged: (value) =>
                onChanged(shape.copyWith(sides: value.round().clamp(3, 12))),
          ),
        ],
        if (shape.type == 'table') ...[
          const SizedBox(height: _designerInspectorSectionGap),
          DocumentDesignerStringField(
            label: 'Rows Path',
            value: shape.dataPath,
            onChanged: (value) => onChanged(shape.copyWith(dataPath: value)),
          ),
          if (listBindings.isNotEmpty) ...[
            const SizedBox(height: AppUiConstants.spacingXs),
            Text(
              'Available list paths',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppUiConstants.spacingXs),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: listBindings
                  .map(
                    (binding) => ActionChip(
                      label: Text(binding),
                      onPressed: () =>
                          onChanged(shape.copyWith(dataPath: binding)),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          const SizedBox(height: _designerInspectorSectionGap),
          DocumentDesignerNumberField(
            label: 'Row Height',
            value: shape.rowHeight,
            onChanged: (value) =>
                onChanged(shape.copyWith(rowHeight: math.max(20, value))),
          ),
          const SizedBox(height: _designerInspectorSectionGap),
          DocumentDesignerNumberField(
            label: 'Title Height',
            value: shape.titleHeight,
            onChanged: (value) =>
                onChanged(shape.copyWith(titleHeight: math.max(20, value))),
          ),
          const SizedBox(height: _designerInspectorSectionGap),
          DocumentDesignerNumberField(
            label: 'Cell Gap',
            value: shape.cellGap,
            onChanged: (value) => onChanged(
              shape.copyWith(cellGap: value.clamp(1, 24).toDouble()),
            ),
          ),
          const SizedBox(height: _designerInspectorSectionGap),
          DocumentDesignerTableColumnInspector(
            columns: shape.columns,
            availableKeys: rowBindings,
            onChanged: (columns) => onChanged(shape.copyWith(columns: columns)),
          ),
        ],
        if (shape.type == 'image') ...[
          const SizedBox(height: _designerInspectorSectionGap),
          DocumentDesignerImageShapeUploadField(
            value: shape.assetPath,
            isUploading: isUploadingImage,
            onChanged: (value) => onChanged(shape.copyWith(assetPath: value)),
            onUpload: onUploadImage,
          ),
        ],
        if (shape.type == 'barcode') ...[
          const SizedBox(height: _designerInspectorSectionGap),
          DocumentDesignerStringField(
            label: 'Barcode Value',
            value: shape.text,
            onChanged: (value) => onChanged(shape.copyWith(text: value)),
          ),
          const SizedBox(height: _designerInspectorSectionGap),
          _CompactDropdownField<String>(
            value: shape.barcodeType,
            items: const [
              DropdownMenuItem(value: 'code128', child: Text('CODE128')),
              DropdownMenuItem(value: 'qr', child: Text('QR')),
            ],
            onChanged: (value) {
              if (value != null) {
                onChanged(shape.copyWith(barcodeType: value));
              }
            },
          ),
          const SizedBox(height: _designerInspectorSectionGap),
          DocumentDesignerNumberField(
            label: 'Font Size',
            value: shape.fontSize,
            onChanged: (value) =>
                onChanged(shape.copyWith(fontSize: math.max(1, value))),
          ),
        ],
      ],
    );
  }
}

class DocumentDesignerStringField extends StatefulWidget {
  const DocumentDesignerStringField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.maxLines = 1,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final int maxLines;

  @override
  State<DocumentDesignerStringField> createState() =>
      _DocumentDesignerStringFieldState();
}

class _DocumentDesignerStringFieldState
    extends State<DocumentDesignerStringField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _controller.addListener(_handleChanged);
  }

  @override
  void didUpdateWidget(DocumentDesignerStringField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleChanged() {
    if (_controller.text != widget.value) {
      widget.onChanged(_controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFormTextField(
      labelText: widget.label.isEmpty ? ' ' : widget.label,
      hintText: widget.label.isEmpty ? null : widget.label,
      controller: _controller,
      maxLines: widget.maxLines,
      width: double.infinity,
    );
  }
}

class DocumentDesignerPropertyGrid extends StatelessWidget {
  const DocumentDesignerPropertyGrid({super.key, required this.rows});

  final List<DocumentDesignerPropertyGridRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: rows
            .asMap()
            .entries
            .map((entry) {
              final row = entry.value;
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 112,
                      padding: const EdgeInsets.symmetric(
                        horizontal: _designerInspectorRowPadding,
                        vertical: 2,
                      ),
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.35),
                      alignment: Alignment.center,
                      child: Text(
                        row.label,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: _designerInspectorFieldPadding,
                          vertical: 1,
                        ),
                        child: row.child,
                      ),
                    ),
                  ],
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class DocumentDesignerPropertyGridRow {
  const DocumentDesignerPropertyGridRow({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;
}

class DocumentDesignerNumberField extends StatefulWidget {
  const DocumentDesignerNumberField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.fractionDigits = 0,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final int fractionDigits;

  @override
  State<DocumentDesignerNumberField> createState() =>
      _DocumentDesignerNumberFieldState();
}

class _DocumentDesignerNumberFieldState
    extends State<DocumentDesignerNumberField> {
  late final TextEditingController _controller;

  String _formatValue(double value) {
    return widget.fractionDigits == 0
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(widget.fractionDigits);
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatValue(widget.value));
  }

  @override
  void didUpdateWidget(DocumentDesignerNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final text = _formatValue(widget.value);
    if (text != _controller.text &&
        double.tryParse(_controller.text) != widget.value) {
      _controller.text = text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppFormTextField(
      labelText: widget.label.isEmpty ? ' ' : widget.label,
      hintText: widget.label.isEmpty ? null : widget.label,
      controller: _controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      width: double.infinity,
      onChanged: (next) {
        final parsed = double.tryParse(next.trim());
        if (parsed != null) {
          widget.onChanged(parsed);
        }
      },
    );
  }
}

class DocumentDesignerColorField extends StatelessWidget {
  const DocumentDesignerColorField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  static const palette = <String, int>{
    'Transparent': 0x00000000,
    'White': 0xFFFFFFFF,
    'Default Gray': 0xFFF1F5F9,
    'Slate': 0xFF475569,
    'Black': 0xFF111827,
    'Blue': 0xFF2563EB,
    'Sky Blue': 0xFFADD0F0,
    'Green': 0xFF059669,
    'Red': 0xFFDC2626,
    'Amber': 0xFFF59E0B,
    'Orange': 0xFFEA580C,
    'Gray': 0xFFD1D5DB,
  };

  @override
  Widget build(BuildContext context) {
    final current = palette.values.contains(value)
        ? value
        : palette.values.first;
    return AppDropdownField<int>.fromMapped(
      labelText: ' ',
      width: double.infinity,
      initialValue: current,
      mappedItems: palette.entries
          .map(
            (entry) =>
                AppDropdownItem<int>(value: entry.value, label: entry.key),
          )
          .toList(growable: false),
      onChanged: (next) {
        if (next != null) {
          onChanged(next);
        }
      },
    );
  }
}

class DocumentDesignerTableColumnInspector extends StatelessWidget {
  const DocumentDesignerTableColumnInspector({
    super.key,
    required this.columns,
    required this.availableKeys,
    required this.onChanged,
  });

  final List<DocumentPrintColumn> columns;
  final List<String> availableKeys;
  final ValueChanged<List<DocumentPrintColumn>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Columns',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            IconButton(
              tooltip: 'Add column',
              onPressed: () {
                onChanged([
                  ...columns,
                  const DocumentPrintColumn(
                    key: 'new_key',
                    label: 'New Column',
                    widthFactor: 1.0,
                  ),
                ]);
              },
              icon: const Icon(Icons.add_circle_outline),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (availableKeys.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: availableKeys
                .map(
                  (key) => ActionChip(
                    label: Text(key),
                    onPressed: () {
                      if (columns.any((column) => column.key == key)) {
                        return;
                      }
                      onChanged([
                        ...columns,
                        DocumentPrintColumn(
                          key: key,
                          label: printColumnLabelFromKey(key),
                          widthFactor: 1.0,
                        ),
                      ]);
                    },
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: _designerInspectorSectionGap),
        ],
        ...columns.asMap().entries.map((entry) {
          final index = entry.key;
          final column = entry.value;
          return Padding(
            padding: const EdgeInsets.only(
              bottom: _designerInspectorSectionGap,
            ),
            child: AppSectionCard(
              padding: const EdgeInsets.all(_designerInspectorRowPadding),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Move up',
                        onPressed: index > 0
                            ? () => _moveColumn(index, -1)
                            : null,
                        icon: const Icon(Icons.arrow_upward),
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        tooltip: 'Move down',
                        onPressed: index < columns.length - 1
                            ? () => _moveColumn(index, 1)
                            : null,
                        icon: const Icon(Icons.arrow_downward),
                        visualDensity: VisualDensity.compact,
                      ),
                      Expanded(
                        child: DocumentDesignerStringField(
                          key: ValueKey('col-$index-label'),
                          label: 'Label',
                          value: column.label,
                          onChanged: (val) =>
                              _updateColumn(index, column.copyWith(label: val)),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _deleteColumn(index),
                        icon: const Icon(Icons.remove_circle_outline),
                        color: Theme.of(context).colorScheme.error,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: DocumentDesignerStringField(
                          key: ValueKey('col-$index-key'),
                          label: 'Key',
                          value: column.key,
                          onChanged: (val) =>
                              _updateColumn(index, column.copyWith(key: val)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 80,
                        child: DocumentDesignerNumberField(
                          key: ValueKey('col-$index-weight'),
                          label: 'Weight',
                          value: column.widthFactor,
                          onChanged: (val) => _updateColumn(
                            index,
                            column.copyWith(widthFactor: val),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _CompactDropdownField<String>(
                    value: column.align,
                    items: const [
                      DropdownMenuItem(value: 'left', child: Text('Left')),
                      DropdownMenuItem(value: 'center', child: Text('Center')),
                      DropdownMenuItem(value: 'right', child: Text('Right')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        _updateColumn(index, column.copyWith(align: val));
                      }
                    },
                  ),
                  const SizedBox(height: 4),
                  _CompactDropdownField<String>(
                    value: column.titleAlign,
                    items: const [
                      DropdownMenuItem(value: 'left', child: Text('Left')),
                      DropdownMenuItem(value: 'center', child: Text('Center')),
                      DropdownMenuItem(value: 'right', child: Text('Right')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        _updateColumn(index, column.copyWith(titleAlign: val));
                      }
                    },
                  ),
                  const SizedBox(height: 4),
                  _CompactDropdownField<String>(
                    value: column.numberFormat,
                    items: const [
                      DropdownMenuItem(
                        value: 'default',
                        child: Text('Default Format'),
                      ),
                      DropdownMenuItem(value: 'auto', child: Text('Auto')),
                      DropdownMenuItem(
                        value: 'fixed_2',
                        child: Text('2 Decimals'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        _updateColumn(
                          index,
                          column.copyWith(numberFormat: val),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 4),
                  AppSwitchTile(
                    label: 'Total Column',
                    value: column.totalColumn,
                    onChanged: (value) => _updateColumn(
                      index,
                      column.copyWith(totalColumn: value),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  void _updateColumn(int index, DocumentPrintColumn next) {
    final list = [...columns];
    list[index] = next;
    onChanged(list);
  }

  void _deleteColumn(int index) {
    final list = [...columns];
    list.removeAt(index);
    onChanged(list);
  }

  void _moveColumn(int index, int offset) {
    final targetIndex = index + offset;
    if (targetIndex < 0 || targetIndex >= columns.length) {
      return;
    }
    final list = [...columns];
    final column = list.removeAt(index);
    list.insert(targetIndex, column);
    onChanged(list);
  }
}

class DocumentDesignerImageShapeUploadField extends StatefulWidget {
  const DocumentDesignerImageShapeUploadField({
    super.key,
    required this.value,
    required this.isUploading,
    required this.onChanged,
    required this.onUpload,
  });

  final String value;
  final bool isUploading;
  final ValueChanged<String> onChanged;
  final Future<void> Function() onUpload;

  @override
  State<DocumentDesignerImageShapeUploadField> createState() =>
      _DocumentDesignerImageShapeUploadFieldState();
}

class _DocumentDesignerImageShapeUploadFieldState
    extends State<DocumentDesignerImageShapeUploadField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(
    covariant DocumentDesignerImageShapeUploadField oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UploadPathField(
      controller: _controller,
      labelText: 'Image Source',
      isUploading: widget.isUploading,
      previewUrl: resolvePrintImageSource(widget.value),
      previewIcon: Icons.image_outlined,
      onUpload: widget.onUpload,
    );
  }
}

class DocumentDesignerBackgroundImageField extends StatefulWidget {
  const DocumentDesignerBackgroundImageField({
    super.key,
    required this.value,
    required this.isUploading,
    required this.onChanged,
    required this.onUpload,
  });

  final String value;
  final bool isUploading;
  final ValueChanged<String> onChanged;
  final Future<void> Function() onUpload;

  @override
  State<DocumentDesignerBackgroundImageField> createState() =>
      _DocumentDesignerBackgroundImageFieldState();
}

class _DocumentDesignerBackgroundImageFieldState
    extends State<DocumentDesignerBackgroundImageField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(
    covariant DocumentDesignerBackgroundImageField oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UploadPathField(
          controller: _controller,
          labelText: 'Background Image',
          isUploading: widget.isUploading,
          previewUrl: resolvePrintImageSource(widget.value),
          previewIcon: Icons.layers_outlined,
          onUpload: widget.onUpload,
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: () => widget.onChanged(_controller.text),
                label: const Text('Apply'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {
                  _controller.clear();
                  widget.onChanged('');
                },
                label: const Text('Clear'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompactDropdownField<T> extends StatelessWidget {
  const _CompactDropdownField({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppDropdownField<T>(
      labelText: ' ',
      items: items,
      initialValue: value,
      width: double.infinity,
      onChanged: onChanged,
    );
  }
}
