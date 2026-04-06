import 'package:flutter/material.dart';

import '../app/constants/app_ui_constants.dart';
import '../app/theme/app_theme_extension.dart';
import '../core/models/pagination_meta.dart';

class ReportPaginationBar extends StatefulWidget {
  const ReportPaginationBar({
    super.key,
    required this.meta,
    required this.onPerPageChanged,
    required this.onPageChanged,
    this.perPageOptions = const <int>[10, 20, 50],
  });

  final PaginationMeta meta;
  final ValueChanged<int> onPerPageChanged;
  final ValueChanged<int> onPageChanged;
  final List<int> perPageOptions;

  @override
  State<ReportPaginationBar> createState() => _ReportPaginationBarState();
}

class _ReportPaginationBarState extends State<ReportPaginationBar> {
  late final TextEditingController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = TextEditingController(
      text: widget.meta.currentPage.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant ReportPaginationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.meta.currentPage != widget.meta.currentPage) {
      _pageController.text = widget.meta.currentPage.toString();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final preferSingleRow = !isMobile;
    final start = widget.meta.total == 0
        ? 0
        : ((widget.meta.currentPage - 1) * widget.meta.perPage) + 1;
    final end = widget.meta.total == 0
        ? 0
        : (widget.meta.currentPage * widget.meta.perPage) > widget.meta.total
        ? widget.meta.total
        : (widget.meta.currentPage * widget.meta.perPage);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: appTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
        boxShadow: [
          BoxShadow(
            color: appTheme.cardShadow,
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final controls = _buildControlsRow(context, isMobile: isMobile);
            final summary = Text(
              'Showing $start-$end of ${widget.meta.total}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: appTheme.mutedText),
            );

            if (preferSingleRow && constraints.maxWidth >= 840) {
              return Row(children: [summary, const Spacer(), controls]);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                summary,
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: controls,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildControlsRow(BuildContext context, {required bool isMobile}) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;

    return Row(
      children: [
        SizedBox(
          width: isMobile ? 86 : 100,
          child: DropdownButtonFormField<int>(
            initialValue: widget.perPageOptions.contains(widget.meta.perPage)
                ? widget.meta.perPage
                : widget.perPageOptions.first,
            decoration: const InputDecoration(labelText: 'Rows', isDense: true),
            items: widget.perPageOptions
                .map(
                  (value) => DropdownMenuItem<int>(
                    value: value,
                    child: Text('$value'),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value != null) {
                widget.onPerPageChanged(value);
              }
            },
          ),
        ),
        const SizedBox(width: 10),
        _navButton(
          context,
          icon: Icons.first_page,
          label: 'First',
          enabled: widget.meta.currentPage > 1,
          onTap: () => widget.onPageChanged(1),
          compact: isMobile,
        ),
        const SizedBox(width: 8),
        _navButton(
          context,
          icon: Icons.chevron_left,
          label: 'Previous',
          enabled: widget.meta.currentPage > 1,
          onTap: () => widget.onPageChanged(widget.meta.currentPage - 1),
          compact: isMobile,
        ),
        const SizedBox(width: 10),
        Container(
          width: isMobile ? 74 : 84,
          constraints: const BoxConstraints(minHeight: 44),
          child: TextField(
            controller: _pageController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(labelText: 'Page', isDense: true),
            onSubmitted: (_) => _jumpToPage(),
          ),
        ),
        if (!isMobile) ...[
          const SizedBox(width: 12),
          Text(
            '${widget.meta.currentPage} / ${widget.meta.lastPage}',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: appTheme.mutedText),
          ),
        ],
        const SizedBox(width: 12),
        _navButton(
          context,
          icon: Icons.chevron_right,
          label: 'Next',
          enabled: widget.meta.currentPage < widget.meta.lastPage,
          onTap: () => widget.onPageChanged(widget.meta.currentPage + 1),
          compact: isMobile,
        ),
        const SizedBox(width: 8),
        _navButton(
          context,
          icon: Icons.last_page,
          label: 'Last',
          enabled: widget.meta.currentPage < widget.meta.lastPage,
          onTap: () => widget.onPageChanged(widget.meta.lastPage),
          compact: isMobile,
        ),
      ],
    );
  }

  Widget _navButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onTap,
    required bool compact,
  }) {
    final button = compact
        ? IconButton.outlined(
            onPressed: enabled ? onTap : null,
            icon: Icon(icon),
            tooltip: label,
          )
        : OutlinedButton.icon(
            onPressed: enabled ? onTap : null,
            icon: Icon(icon),
            label: Text(label),
          );

    return Tooltip(message: label, child: button);
  }

  void _jumpToPage() {
    final value = int.tryParse(_pageController.text.trim());
    if (value == null) {
      _pageController.text = widget.meta.currentPage.toString();
      return;
    }

    final target = value.clamp(
      1,
      widget.meta.lastPage == 0 ? 1 : widget.meta.lastPage,
    );
    widget.onPageChanged(target);
  }
}
