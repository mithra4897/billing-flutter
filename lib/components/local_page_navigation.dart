import 'package:flutter/material.dart';

import '../app/constants/app_ui_constants.dart';

const int kLocalListPageSize = 20;

class LocalPageNavigation extends StatelessWidget {
  const LocalPageNavigation({
    super.key,
    required this.totalItems,
    required this.currentPage,
    this.pageSize = kLocalListPageSize,
    required this.onPageChanged,
  });

  final int totalItems;
  final int currentPage;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    if (totalItems <= pageSize) {
      return const SizedBox.shrink();
    }

    final totalPages = ((totalItems + pageSize) / pageSize).floor();

    return Padding(
      padding: const EdgeInsets.only(top: AppUiConstants.spacingMd),
      child: Row(
        children: [
          const Spacer(),
          TextButton.icon(
            onPressed: currentPage > 1
                ? () => onPageChanged(currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Previous'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppUiConstants.spacingSm,
            ),
            child: Text('Page $currentPage of $totalPages'),
          ),
          TextButton.icon(
            onPressed: currentPage < totalPages
                ? () => onPageChanged(currentPage + 1)
                : null,
            icon: const Text('Next'),
            label: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
