import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_field_box.dart';

class ErpLinkFieldOption<T> {
  const ErpLinkFieldOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.searchText,
  });

  final T value;
  final String label;
  final String? subtitle;
  final String? searchText;

  @override
  String toString() => label;
}

class ErpLinkField<T> extends StatefulWidget {
  const ErpLinkField({
    super.key,
    required this.labelText,
    required this.onChanged,
    this.initialSelection,
    this.options,
    this.search,
    this.onCreateNew,
    this.onNavigateToCreateNew,
    this.allowCreate = false,
    this.validator,
    this.hintText,
    this.doctypeLabel,
    this.width,
    this.enabled = true,
    this.autofocus = false,
    this.loadingMessageBuilder,
    this.emptyMessageBuilder,
    this.createNewLabelBuilder,
  });

  final String labelText;
  final ValueChanged<T?> onChanged;
  final ErpLinkFieldOption<T>? initialSelection;
  final List<ErpLinkFieldOption<T>>? options;
  final Future<List<ErpLinkFieldOption<T>>> Function(String query)? search;
  final Future<ErpLinkFieldOption<T>?> Function(String query)? onCreateNew;
  final ValueChanged<String>? onNavigateToCreateNew;
  final bool allowCreate;
  final FormFieldValidator<T?>? validator;
  final String? hintText;
  final String? doctypeLabel;
  final double? width;
  final bool enabled;
  final bool autofocus;
  final String Function(String query, String doctypeLabel)?
  loadingMessageBuilder;
  final String Function(String query, String doctypeLabel)? emptyMessageBuilder;
  final String Function(String query, String doctypeLabel)?
  createNewLabelBuilder;

  @override
  State<ErpLinkField<T>> createState() => _ErpLinkFieldState<T>();
}

class _ErpLinkFieldState<T> extends State<ErpLinkField<T>> {
  static const Duration _debounceDuration = Duration(milliseconds: 300);
  static const double _dropdownOffset = 4;
  static const double _dropdownMaxHeight = 250;

  final LayerLink _layerLink = LayerLink();
  final GlobalKey _fieldKey = GlobalKey();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _controller = TextEditingController();

  OverlayEntry? _overlayEntry;
  FormFieldState<T?>? _fieldState;
  Timer? _debounceTimer;
  Timer? _blurTimer;
  List<ErpLinkFieldOption<T>> _results = <ErpLinkFieldOption<T>>[];
  ErpLinkFieldOption<T>? _selected;
  bool _loading = false;
  bool _creating = false;
  int _requestToken = 0;
  int _highlightedIndex = -1;

  String get _doctypeLabel =>
      (widget.doctypeLabel ?? widget.labelText).trim().isEmpty
      ? 'record'
      : (widget.doctypeLabel ?? widget.labelText).trim();

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelection;
    _controller.text = widget.initialSelection?.label ?? '';
    _focusNode.addListener(_handleFocusChange);
    _controller.addListener(_handleTextChanged);
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.enabled) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant ErpLinkField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSelection?.value != widget.initialSelection?.value) {
      _selected = widget.initialSelection;
      if (!_focusNode.hasFocus) {
        _setControllerText(widget.initialSelection?.label ?? '');
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _blurTimer?.cancel();
    _removeOverlay();
    _focusNode.removeListener(_handleFocusChange);
    _controller.removeListener(_handleTextChanged);
    _focusNode.dispose();
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      _blurTimer?.cancel();
      _openDropdown();
      _scheduleSearch(
        _selected == null ? _controller.text : '',
        immediate: true,
      );
      return;
    }

    _blurTimer?.cancel();
    _blurTimer = Timer(const Duration(milliseconds: 120), () {
      if (!_focusNode.hasFocus) {
        _closeDropdown();
      }
    });
  }

  void _handleTextChanged() {
    if (!_focusNode.hasFocus || !widget.enabled) {
      return;
    }
    final typed = _controller.text.trim();
    if (_selected != null && typed != _selected!.label.trim()) {
      _selected = null;
      _fieldState?.didChange(null);
      widget.onChanged(null);
    }
    _openDropdown();
    _markOverlayNeedsBuild();
    _scheduleSearch(typed);
  }

  void _setControllerText(String text) {
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _openDropdown() {
    if (!widget.enabled) {
      return;
    }
    if (_overlayEntry != null) {
      _markOverlayNeedsBuild();
      return;
    }
    _overlayEntry = OverlayEntry(builder: (context) => _buildOverlay());
    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
  }

  void _closeDropdown() {
    _debounceTimer?.cancel();
    _loading = false;
    _creating = false;
    _highlightedIndex = -1;
    _removeOverlay();
    if (_selected != null && !_focusNode.hasFocus) {
      _setControllerText(_selected!.label);
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _markOverlayNeedsBuild() {
    _overlayEntry?.markNeedsBuild();
  }

  void _scheduleSearch(String query, {bool immediate = false}) {
    _debounceTimer?.cancel();
    if (immediate) {
      _performSearch(query);
      return;
    }
    _debounceTimer = Timer(_debounceDuration, () => _performSearch(query));
  }

  Future<void> _performSearch(String query) async {
    final token = ++_requestToken;
    setState(() {
      _loading = true;
    });
    _markOverlayNeedsBuild();

    try {
      final results = widget.search != null
          ? await widget.search!(query)
          : _filterLocalOptions(query);
      if (!mounted || token != _requestToken) {
        return;
      }
      setState(() {
        _results = results;
        _loading = false;
        _highlightedIndex = _firstSelectableIndex();
      });
      _markOverlayNeedsBuild();
    } catch (_) {
      if (!mounted || token != _requestToken) {
        return;
      }
      setState(() {
        _results = <ErpLinkFieldOption<T>>[];
        _loading = false;
        _highlightedIndex = _firstSelectableIndex();
      });
      _markOverlayNeedsBuild();
    }
  }

  List<ErpLinkFieldOption<T>> _filterLocalOptions(String query) {
    final normalized = query.trim().toLowerCase();
    final options = widget.options ?? <ErpLinkFieldOption<T>>[];
    if (normalized.isEmpty) {
      return List<ErpLinkFieldOption<T>>.from(options);
    }
    return options
        .where((option) {
          final haystack = [
            option.label,
            option.subtitle ?? '',
            option.searchText ?? '',
          ].join(' ').toLowerCase();
          return haystack.contains(normalized);
        })
        .toList(growable: false);
  }

  bool _hasExactMatch(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return false;
    }
    return _results.any(
      (item) => item.label.trim().toLowerCase() == normalized,
    );
  }

  List<_ErpMenuEntry<T>> _buildEntries() {
    final query = _controller.text.trim();
    if (_loading || _creating) {
      return <_ErpMenuEntry<T>>[
        _ErpMenuEntry<T>.loading(
          widget.loadingMessageBuilder?.call(query, _doctypeLabel) ??
              'Loading $_doctypeLabel...',
        ),
      ];
    }

    final entries = _results
        .map(_ErpMenuEntry<T>.result)
        .toList(growable: true);
    final canCreate =
        widget.allowCreate &&
        query.isNotEmpty &&
        !_hasExactMatch(query);

    if (entries.isEmpty) {
      entries.add(
        _ErpMenuEntry<T>.empty(
          widget.emptyMessageBuilder?.call(query, _doctypeLabel) ??
              (query.isEmpty ? 'No $_doctypeLabel found' : 'No results found'),
        ),
      );
    }

    if (canCreate) {
      entries.add(
        _ErpMenuEntry<T>.create(
          query,
          widget.createNewLabelBuilder?.call(query, _doctypeLabel) ??
              'Create a new $_doctypeLabel "$query"',
        ),
      );
    }

    return entries;
  }

  int _firstSelectableIndex() {
    final entries = _buildEntries();
    for (var index = 0; index < entries.length; index++) {
      if (entries[index].selectable) {
        return index;
      }
    }
    return -1;
  }

  void _moveHighlight(int delta) {
    final entries = _buildEntries();
    final selectableIndexes = <int>[];
    for (var index = 0; index < entries.length; index++) {
      if (entries[index].selectable) {
        selectableIndexes.add(index);
      }
    }
    if (selectableIndexes.isEmpty) {
      return;
    }

    final currentPosition = selectableIndexes.indexOf(_highlightedIndex);
    final nextPosition = currentPosition < 0
        ? 0
        : (currentPosition + delta + selectableIndexes.length) %
              selectableIndexes.length;
    setState(() {
      _highlightedIndex = selectableIndexes[nextPosition];
    });
    _markOverlayNeedsBuild();
  }

  Future<void> _submitHighlighted(FormFieldState<T?> field) async {
    final entries = _buildEntries();
    if (_highlightedIndex < 0 || _highlightedIndex >= entries.length) {
      return;
    }
    final entry = entries[_highlightedIndex];
    if (!entry.selectable) {
      return;
    }
    await _selectEntry(entry, field);
  }

  Future<void> _selectEntry(
    _ErpMenuEntry<T> entry,
    FormFieldState<T?> field,
  ) async {
    switch (entry.kind) {
      case _ErpMenuEntryKind.result:
        final option = entry.option;
        if (option == null) {
          return;
        }
        setState(() {
          _selected = option;
        });
        _setControllerText(option.label);
        field.didChange(option.value);
        widget.onChanged(option.value);
        _focusNode.unfocus();
        _closeDropdown();
        return;
      case _ErpMenuEntryKind.create:
        final navigateToCreate = widget.onNavigateToCreateNew;
        if (navigateToCreate != null) {
          navigateToCreate(entry.query);
          _focusNode.unfocus();
          _closeDropdown();
          return;
        }
        final create = widget.onCreateNew;
        if (create == null || _creating) {
          return;
        }
        setState(() {
          _creating = true;
        });
        _markOverlayNeedsBuild();
        try {
          final created = await create(entry.query);
          if (!mounted) {
            return;
          }
          if (created != null) {
            setState(() {
              _selected = created;
              _results = <ErpLinkFieldOption<T>>[created];
            });
            _setControllerText(created.label);
            field.didChange(created.value);
            widget.onChanged(created.value);
            _focusNode.unfocus();
            _closeDropdown();
          }
        } finally {
          if (mounted) {
            setState(() {
              _creating = false;
            });
            _markOverlayNeedsBuild();
          }
        }
        return;
      case _ErpMenuEntryKind.loading:
      case _ErpMenuEntryKind.empty:
        return;
    }
  }

  KeyEventResult _handleKeyEvent(FormFieldState<T?> field, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _moveHighlight(1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _moveHighlight(-1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _submitHighlighted(field);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _focusNode.unfocus();
      _closeDropdown();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _buildOverlay() {
    final fieldContext = _fieldKey.currentContext;
    if (fieldContext == null) {
      return const SizedBox.shrink();
    }
    final renderBox = fieldContext.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) {
      return const SizedBox.shrink();
    }

    final size = renderBox.size;
    final entries = _buildEntries();
    final theme = Theme.of(context);

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              _focusNode.unfocus();
              _closeDropdown();
            },
          ),
        ),
        CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + _dropdownOffset),
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: size.width,
              child: Container(
                constraints: const BoxConstraints(
                  maxHeight: _dropdownMaxHeight,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.55),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: entries.isEmpty
                    ? const SizedBox.shrink()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        shrinkWrap: true,
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return _ErpDropdownRow<T>(
                            entry: entry,
                            highlighted: index == _highlightedIndex,
                            onTap: entry.selectable && _fieldState != null
                                ? () => _selectEntry(entry, _fieldState!)
                                : null,
                          );
                        },
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppFieldBox(
      width: widget.width,
      child: FormField<T?>(
        initialValue: widget.initialSelection?.value,
        validator: widget.validator,
        builder: (field) {
          _fieldState = field;
          return CompositedTransformTarget(
            link: _layerLink,
            child: Focus(
              onKeyEvent: (node, event) => _handleKeyEvent(field, event),
              child: TextFormField(
                key: _fieldKey,
                controller: _controller,
                focusNode: _focusNode,
                enabled: widget.enabled,
                decoration: InputDecoration(
                  labelText: widget.labelText,
                  hintText: widget.hintText ?? 'Search $_doctypeLabel',
                  errorText: field.errorText,
                  suffixIconConstraints: const BoxConstraints(
                    minWidth: 30,
                    minHeight: 30,
                  ),
                  suffixIcon: _loading || _creating
                      ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : const Icon(Icons.arrow_drop_down, size: 18),
                ),
                onTap: () {
                  if (_selected != null) {
                    _controller.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: _controller.text.length,
                    );
                  }
                  _openDropdown();
                  _scheduleSearch(
                    _selected == null ? _controller.text : '',
                    immediate: true,
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

enum _ErpMenuEntryKind { result, empty, loading, create }

class _ErpMenuEntry<T> {
  const _ErpMenuEntry._({
    required this.kind,
    required this.label,
    this.option,
    this.query = '',
  });

  _ErpMenuEntry.result(ErpLinkFieldOption<T> option)
    : this._(
        kind: _ErpMenuEntryKind.result,
        label: option.label,
        option: option,
      );

  const _ErpMenuEntry.empty(String label)
    : this._(kind: _ErpMenuEntryKind.empty, label: label);

  const _ErpMenuEntry.loading(String label)
    : this._(kind: _ErpMenuEntryKind.loading, label: label);

  const _ErpMenuEntry.create(String query, String label)
    : this._(kind: _ErpMenuEntryKind.create, label: label, query: query);

  final _ErpMenuEntryKind kind;
  final String label;
  final ErpLinkFieldOption<T>? option;
  final String query;

  bool get selectable =>
      kind == _ErpMenuEntryKind.result || kind == _ErpMenuEntryKind.create;
}

class _ErpDropdownRow<T> extends StatelessWidget {
  const _ErpDropdownRow({
    required this.entry,
    required this.highlighted,
    this.onTap,
  });

  final _ErpMenuEntry<T> entry;
  final bool highlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = highlighted
        ? theme.colorScheme.primary.withValues(alpha: 0.08)
        : Colors.transparent;
    final textColor = entry.kind == _ErpMenuEntryKind.empty
        ? theme.colorScheme.onSurface.withValues(alpha: 0.58)
        : theme.colorScheme.onSurface;
    final weight = entry.kind == _ErpMenuEntryKind.create
        ? FontWeight.w600
        : FontWeight.w400;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: background,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            if (entry.kind == _ErpMenuEntryKind.create) ...[
              Icon(Icons.add, size: 14, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                entry.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: weight,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
