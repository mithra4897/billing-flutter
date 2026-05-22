import '../screen.dart';

class AppCheckboxFilterOption<T> {
  const AppCheckboxFilterOption({required this.value, required this.label});

  final T value;
  final String label;
}

class AppCheckboxFilter<T> extends StatefulWidget {
  const AppCheckboxFilter({
    super.key,
    required this.label,
    required this.selectedValues,
    required this.options,
    required this.onChanged,
    this.width,
    this.emptyLabel = 'All',
    this.hintText,
    this.allValue,
  });

  final String label;
  final Set<T> selectedValues;
  final List<AppCheckboxFilterOption<T>> options;
  final ValueChanged<T> onChanged;
  final double? width;
  final String emptyLabel;
  final String? hintText;
  final T? allValue;

  @override
  State<AppCheckboxFilter<T>> createState() => _AppCheckboxFilterState<T>();
}

class _AppCheckboxFilterState<T> extends State<AppCheckboxFilter<T>> {
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _fieldKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  late Set<T> _currentValues;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _currentValues = Set<T>.from(widget.selectedValues);
  }

  @override
  void didUpdateWidget(covariant AppCheckboxFilter<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _currentValues = Set<T>.from(widget.selectedValues);
    if (_overlayEntry != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _overlayEntry?.markNeedsBuild();
      });
    }
  }

  @override
  void dispose() {
    _dismissOverlay(notify: false);
    super.dispose();
  }

  void _toggleOverlay() {
    if (_isOpen) {
      _dismissOverlay();
      return;
    }
    _showOverlay();
  }

  void _showOverlay() {
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(builder: _buildOverlay);
    overlay.insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
  }

  void _removeOverlay() => _dismissOverlay();

  void _dismissOverlay({bool notify = true}) {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (notify && mounted) {
      setState(() {
        _isOpen = false;
      });
    } else {
      _isOpen = false;
    }
  }

  Widget _buildOverlay(BuildContext context) {
    final renderBox =
        _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    final fieldSize = renderBox?.size ?? const Size(240, 0);
    final theme = Theme.of(context);

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _removeOverlay,
          ),
        ),
        CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, 4),
          child: Material(
            elevation: 8,
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppUiConstants.fieldRadius),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: fieldSize.width,
                maxWidth: fieldSize.width,
                maxHeight: 260,
              ),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                children: widget.options.map(_buildOptionTile).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionTile(AppCheckboxFilterOption<T> item) {
    final theme = Theme.of(context);
    final isAllOption =
        widget.allValue != null && item.value == widget.allValue;
    final selected = isAllOption
        ? _currentValues.isEmpty
        : _currentValues.contains(item.value);
    return InkWell(
      onTap: () {
        _toggleValue(item.value, isAllOption: isAllOption);
        _overlayEntry?.markNeedsBuild();
      },
      borderRadius: BorderRadius.circular(AppUiConstants.fieldRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            IgnorePointer(
              child: SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: selected,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (_) {},
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleValue(T value, {bool isAllOption = false}) {
    final nextValues = isAllOption ? <T>{} : Set<T>.from(_currentValues);
    if (!isAllOption) {
      if (!nextValues.add(value)) {
        nextValues.remove(value);
      }
    }
    setState(() {
      _currentValues = nextValues;
    });
    widget.onChanged(value);
  }

  String _displayText() {
    if (_currentValues.isEmpty) {
      return widget.hintText ?? widget.emptyLabel;
    }

    final labels = widget.options
        .where((item) => _currentValues.contains(item.value))
        .map((item) => item.label)
        .toList(growable: false);

    if (labels.isEmpty) {
      return widget.hintText ?? widget.emptyLabel;
    }

    return labels.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppFieldBox(
      width: widget.width,
      child: CompositedTransformTarget(
        link: _layerLink,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleOverlay,
          child: AbsorbPointer(
            child: InputDecorator(
              key: _fieldKey,
              decoration: InputDecoration(
                labelText: widget.label,
                suffixIcon: Icon(
                  _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                ),
              ),
              child: Text(
                _displayText(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _currentValues.isEmpty
                    ? theme.textTheme.bodyLarge?.copyWith(
                        color: theme.hintColor,
                      )
                    : theme.textTheme.bodyLarge,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
