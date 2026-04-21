import 'dart:convert';

import '../../screen.dart';
import '../purchase/purchase_register_page.dart';
import '../purchase/purchase_support.dart';

Future<void> _showJsonModelDialog<T extends JsonModel>(
  BuildContext context,
  String title,
  Future<ApiResponse<T>> Function() fetch,
) async {
  try {
    final response = await fetch();
    if (!context.mounted) {
      return;
    }
    if (response.success != true || response.data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      return;
    }
    final text = const JsonEncoder.withIndent(
      '  ',
    ).convert(response.data!.toJson());
    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(child: SelectableText(text)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class OpeningStockRegisterPage extends StatefulWidget {
  const OpeningStockRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<OpeningStockRegisterPage> createState() =>
      _OpeningStockRegisterPageState();
}

class _OpeningStockRegisterPageState extends State<OpeningStockRegisterPage> {
  final InventoryService _service = InventoryService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  List<OpeningStockModel> _rows = const <OpeningStockModel>[];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _service.openingStocks(
        filters: const {'per_page': 200, 'sort_by': 'opening_date'},
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _rows = response.data ?? const <OpeningStockModel>[];
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  List<OpeningStockModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((OpeningStockModel row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'opening_no'),
            stringValue(data, 'opening_status'),
            stringValue(data, 'remarks'),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<OpeningStockModel>(
      title: 'Opening stock',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No opening stock documents found.',
      actions: const <Widget>[],
      filters: _RegisterFilters(
        searchController: _searchController,
        searchHint: 'Search opening stock',
        status: '',
        statusItems: const <AppDropdownItem<String>>[],
        onStatusChanged: (_) {},
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<OpeningStockModel>(
          label: 'No',
          valueBuilder: (OpeningStockModel row) =>
              stringValue(row.toJson(), 'opening_no'),
        ),
        PurchaseRegisterColumn<OpeningStockModel>(
          label: 'Date',
          valueBuilder: (OpeningStockModel row) => displayDate(
            nullableStringValue(row.toJson(), 'opening_date'),
          ),
        ),
        PurchaseRegisterColumn<OpeningStockModel>(
          label: 'Status',
          valueBuilder: (OpeningStockModel row) =>
              stringValue(row.toJson(), 'opening_status'),
        ),
      ],
      onRowTap: (OpeningStockModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        _showJsonModelDialog<OpeningStockModel>(
          context,
          'Opening stock #$id',
          () => _service.openingStock(id),
        );
      },
    );
  }
}

class _RegisterFilters extends StatelessWidget {
  const _RegisterFilters({
    required this.searchController,
    required this.searchHint,
    required this.status,
    required this.statusItems,
    required this.onStatusChanged,
  });

  final TextEditingController searchController;
  final String searchHint;
  final String status;
  final List<AppDropdownItem<String>> statusItems;
  final ValueChanged<String?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppFormTextField(
          labelText: 'Search',
          controller: searchController,
          hintText: searchHint,
        ),
        if (statusItems.isNotEmpty) ...[
          const SizedBox(height: AppUiConstants.spacingMd),
          AppDropdownField<String>.fromMapped(
            labelText: 'Status',
            mappedItems: statusItems,
            initialValue: status.isEmpty ? null : status,
            onChanged: onStatusChanged,
          ),
        ],
      ],
    );
  }
}

class StockIssueRegisterPage extends StatefulWidget {
  const StockIssueRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<StockIssueRegisterPage> createState() => _StockIssueRegisterPageState();
}

class _StockIssueRegisterPageState extends State<StockIssueRegisterPage> {
  final InventoryService _service = InventoryService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  List<StockIssueModel> _rows = const <StockIssueModel>[];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _service.stockIssues(
        filters: const {'per_page': 200, 'sort_by': 'issue_date'},
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _rows = response.data ?? const <StockIssueModel>[];
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  List<StockIssueModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((StockIssueModel row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'issue_no'),
            stringValue(data, 'issue_status'),
            stringValue(data, 'issue_purpose'),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<StockIssueModel>(
      title: 'Stock issues',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No stock issues found.',
      actions: const <Widget>[],
      filters: _RegisterFilters(
        searchController: _searchController,
        searchHint: 'Search issues',
        status: '',
        statusItems: const <AppDropdownItem<String>>[],
        onStatusChanged: (_) {},
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<StockIssueModel>(
          label: 'No',
          valueBuilder: (StockIssueModel row) =>
              stringValue(row.toJson(), 'issue_no'),
        ),
        PurchaseRegisterColumn<StockIssueModel>(
          label: 'Date',
          valueBuilder: (StockIssueModel row) => displayDate(
            nullableStringValue(row.toJson(), 'issue_date'),
          ),
        ),
        PurchaseRegisterColumn<StockIssueModel>(
          label: 'Purpose',
          valueBuilder: (StockIssueModel row) =>
              stringValue(row.toJson(), 'issue_purpose'),
        ),
        PurchaseRegisterColumn<StockIssueModel>(
          label: 'Status',
          valueBuilder: (StockIssueModel row) =>
              stringValue(row.toJson(), 'issue_status'),
        ),
      ],
      onRowTap: (StockIssueModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        _showJsonModelDialog<StockIssueModel>(
          context,
          'Stock issue #$id',
          () => _service.stockIssue(id),
        );
      },
    );
  }
}

class InternalStockReceiptRegisterPage extends StatefulWidget {
  const InternalStockReceiptRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<InternalStockReceiptRegisterPage> createState() =>
      _InternalStockReceiptRegisterPageState();
}

class _InternalStockReceiptRegisterPageState
    extends State<InternalStockReceiptRegisterPage> {
  final InventoryService _service = InventoryService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  List<InternalStockReceiptModel> _rows =
      const <InternalStockReceiptModel>[];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _service.internalStockReceipts(
        filters: const {'per_page': 200, 'sort_by': 'receipt_date'},
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _rows = response.data ?? const <InternalStockReceiptModel>[];
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  List<InternalStockReceiptModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((InternalStockReceiptModel row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'receipt_no'),
            stringValue(data, 'receipt_status'),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<InternalStockReceiptModel>(
      title: 'Internal stock receipts',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No internal receipts found.',
      actions: const <Widget>[],
      filters: _RegisterFilters(
        searchController: _searchController,
        searchHint: 'Search receipts',
        status: '',
        statusItems: const <AppDropdownItem<String>>[],
        onStatusChanged: (_) {},
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<InternalStockReceiptModel>(
          label: 'No',
          valueBuilder: (InternalStockReceiptModel row) =>
              stringValue(row.toJson(), 'receipt_no'),
        ),
        PurchaseRegisterColumn<InternalStockReceiptModel>(
          label: 'Date',
          valueBuilder: (InternalStockReceiptModel row) => displayDate(
            nullableStringValue(row.toJson(), 'receipt_date'),
          ),
        ),
        PurchaseRegisterColumn<InternalStockReceiptModel>(
          label: 'Status',
          valueBuilder: (InternalStockReceiptModel row) =>
              stringValue(row.toJson(), 'receipt_status'),
        ),
      ],
      onRowTap: (InternalStockReceiptModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        _showJsonModelDialog<InternalStockReceiptModel>(
          context,
          'Internal receipt #$id',
          () => _service.internalStockReceipt(id),
        );
      },
    );
  }
}

class StockTransferRegisterPage extends StatefulWidget {
  const StockTransferRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<StockTransferRegisterPage> createState() =>
      _StockTransferRegisterPageState();
}

class _StockTransferRegisterPageState extends State<StockTransferRegisterPage> {
  final InventoryService _service = InventoryService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  List<StockTransferModel> _rows = const <StockTransferModel>[];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _service.stockTransfers(
        filters: const {'per_page': 200, 'sort_by': 'transfer_date'},
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _rows = response.data ?? const <StockTransferModel>[];
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  List<StockTransferModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((StockTransferModel row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'transfer_no'),
            stringValue(data, 'transfer_status'),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<StockTransferModel>(
      title: 'Stock transfers',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No stock transfers found.',
      actions: const <Widget>[],
      filters: _RegisterFilters(
        searchController: _searchController,
        searchHint: 'Search transfers',
        status: '',
        statusItems: const <AppDropdownItem<String>>[],
        onStatusChanged: (_) {},
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<StockTransferModel>(
          label: 'No',
          valueBuilder: (StockTransferModel row) =>
              stringValue(row.toJson(), 'transfer_no'),
        ),
        PurchaseRegisterColumn<StockTransferModel>(
          label: 'Date',
          valueBuilder: (StockTransferModel row) => displayDate(
            nullableStringValue(row.toJson(), 'transfer_date'),
          ),
        ),
        PurchaseRegisterColumn<StockTransferModel>(
          label: 'Status',
          valueBuilder: (StockTransferModel row) =>
              stringValue(row.toJson(), 'transfer_status'),
        ),
      ],
      onRowTap: (StockTransferModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        _showJsonModelDialog<StockTransferModel>(
          context,
          'Stock transfer #$id',
          () => _service.stockTransfer(id),
        );
      },
    );
  }
}

class StockDamageRegisterPage extends StatefulWidget {
  const StockDamageRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<StockDamageRegisterPage> createState() =>
      _StockDamageRegisterPageState();
}

class _StockDamageRegisterPageState extends State<StockDamageRegisterPage> {
  final InventoryService _service = InventoryService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  List<StockDamageEntryModel> _rows = const <StockDamageEntryModel>[];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _service.stockDamageEntries(
        filters: const {'per_page': 200, 'sort_by': 'damage_date'},
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _rows = response.data ?? const <StockDamageEntryModel>[];
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  List<StockDamageEntryModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((StockDamageEntryModel row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'damage_no'),
            stringValue(data, 'damage_status'),
            stringValue(data, 'damage_type'),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<StockDamageEntryModel>(
      title: 'Stock damage',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No stock damage entries found.',
      actions: const <Widget>[],
      filters: _RegisterFilters(
        searchController: _searchController,
        searchHint: 'Search damage entries',
        status: '',
        statusItems: const <AppDropdownItem<String>>[],
        onStatusChanged: (_) {},
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<StockDamageEntryModel>(
          label: 'No',
          valueBuilder: (StockDamageEntryModel row) =>
              stringValue(row.toJson(), 'damage_no'),
        ),
        PurchaseRegisterColumn<StockDamageEntryModel>(
          label: 'Date',
          valueBuilder: (StockDamageEntryModel row) => displayDate(
            nullableStringValue(row.toJson(), 'damage_date'),
          ),
        ),
        PurchaseRegisterColumn<StockDamageEntryModel>(
          label: 'Type',
          valueBuilder: (StockDamageEntryModel row) =>
              stringValue(row.toJson(), 'damage_type'),
        ),
        PurchaseRegisterColumn<StockDamageEntryModel>(
          label: 'Status',
          valueBuilder: (StockDamageEntryModel row) =>
              stringValue(row.toJson(), 'damage_status'),
        ),
      ],
      onRowTap: (StockDamageEntryModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        _showJsonModelDialog<StockDamageEntryModel>(
          context,
          'Stock damage #$id',
          () => _service.stockDamageEntry(id),
        );
      },
    );
  }
}

class InventoryAdjustmentRegisterPage extends StatefulWidget {
  const InventoryAdjustmentRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<InventoryAdjustmentRegisterPage> createState() =>
      _InventoryAdjustmentRegisterPageState();
}

class _InventoryAdjustmentRegisterPageState
    extends State<InventoryAdjustmentRegisterPage> {
  final InventoryService _service = InventoryService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  List<InventoryAdjustmentModel> _rows =
      const <InventoryAdjustmentModel>[];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _service.inventoryAdjustments(
        filters: const {'per_page': 200, 'sort_by': 'adjustment_date'},
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _rows = response.data ?? const <InventoryAdjustmentModel>[];
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  List<InventoryAdjustmentModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((InventoryAdjustmentModel row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'adjustment_no'),
            stringValue(data, 'adjustment_status'),
            stringValue(data, 'adjustment_type'),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<InventoryAdjustmentModel>(
      title: 'Inventory adjustments',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No inventory adjustments found.',
      actions: const <Widget>[],
      filters: _RegisterFilters(
        searchController: _searchController,
        searchHint: 'Search adjustments',
        status: '',
        statusItems: const <AppDropdownItem<String>>[],
        onStatusChanged: (_) {},
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<InventoryAdjustmentModel>(
          label: 'No',
          valueBuilder: (InventoryAdjustmentModel row) =>
              stringValue(row.toJson(), 'adjustment_no'),
        ),
        PurchaseRegisterColumn<InventoryAdjustmentModel>(
          label: 'Date',
          valueBuilder: (InventoryAdjustmentModel row) => displayDate(
            nullableStringValue(row.toJson(), 'adjustment_date'),
          ),
        ),
        PurchaseRegisterColumn<InventoryAdjustmentModel>(
          label: 'Type',
          valueBuilder: (InventoryAdjustmentModel row) =>
              stringValue(row.toJson(), 'adjustment_type'),
        ),
        PurchaseRegisterColumn<InventoryAdjustmentModel>(
          label: 'Status',
          valueBuilder: (InventoryAdjustmentModel row) =>
              stringValue(row.toJson(), 'adjustment_status'),
        ),
      ],
      onRowTap: (InventoryAdjustmentModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        _showJsonModelDialog<InventoryAdjustmentModel>(
          context,
          'Adjustment #$id',
          () => _service.inventoryAdjustment(id),
        );
      },
    );
  }
}

class StockMovementRegisterPage extends StatefulWidget {
  const StockMovementRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<StockMovementRegisterPage> createState() =>
      _StockMovementRegisterPageState();
}

class _StockMovementRegisterPageState extends State<StockMovementRegisterPage> {
  final InventoryService _service = InventoryService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  List<StockMovementModel> _rows = const <StockMovementModel>[];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _service.stockMovements(
        filters: const {'per_page': 200, 'sort_by': 'movement_date'},
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _rows = response.data ?? const <StockMovementModel>[];
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  List<StockMovementModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((StockMovementModel row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'movement_type'),
            stringValue(data, 'reference_no'),
            stringValue(data, 'reference_module'),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<StockMovementModel>(
      title: 'Stock movements',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No stock movements found.',
      actions: const <Widget>[],
      filters: _RegisterFilters(
        searchController: _searchController,
        searchHint: 'Search movements',
        status: '',
        statusItems: const <AppDropdownItem<String>>[],
        onStatusChanged: (_) {},
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<StockMovementModel>(
          label: 'Date',
          flex: 2,
          valueBuilder: (StockMovementModel row) => displayDate(
            nullableStringValue(row.toJson(), 'movement_date'),
          ),
        ),
        PurchaseRegisterColumn<StockMovementModel>(
          label: 'Type',
          valueBuilder: (StockMovementModel row) =>
              stringValue(row.toJson(), 'movement_type'),
        ),
        PurchaseRegisterColumn<StockMovementModel>(
          label: 'Reference',
          flex: 3,
          valueBuilder: (StockMovementModel row) =>
              stringValue(row.toJson(), 'reference_no'),
        ),
        PurchaseRegisterColumn<StockMovementModel>(
          label: 'Qty',
          valueBuilder: (StockMovementModel row) =>
              stringValue(row.toJson(), 'qty'),
        ),
      ],
      onRowTap: (StockMovementModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        _showJsonModelDialog<StockMovementModel>(
          context,
          'Movement #$id',
          () => _service.stockMovement(id),
        );
      },
    );
  }
}

class StockBatchRegisterPage extends StatefulWidget {
  const StockBatchRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<StockBatchRegisterPage> createState() => _StockBatchRegisterPageState();
}

class _StockBatchRegisterPageState extends State<StockBatchRegisterPage> {
  final InventoryService _service = InventoryService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  List<StockBatchModel> _rows = const <StockBatchModel>[];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _service.stockBatches(
        filters: const {'per_page': 200, 'sort_by': 'batch_no'},
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _rows = response.data ?? const <StockBatchModel>[];
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  List<StockBatchModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((StockBatchModel row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'batch_no'),
            stringValue(data, 'item_code'),
            stringValue(data, 'item_name'),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<StockBatchModel>(
      title: 'Stock batches',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No stock batches found.',
      actions: const <Widget>[],
      filters: _RegisterFilters(
        searchController: _searchController,
        searchHint: 'Search batches',
        status: '',
        statusItems: const <AppDropdownItem<String>>[],
        onStatusChanged: (_) {},
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<StockBatchModel>(
          label: 'Batch',
          valueBuilder: (StockBatchModel row) =>
              stringValue(row.toJson(), 'batch_no'),
        ),
        PurchaseRegisterColumn<StockBatchModel>(
          label: 'Balance',
          valueBuilder: (StockBatchModel row) =>
              stringValue(row.toJson(), 'balance_qty'),
        ),
        PurchaseRegisterColumn<StockBatchModel>(
          label: 'Expiry',
          valueBuilder: (StockBatchModel row) => displayDate(
            nullableStringValue(row.toJson(), 'expiry_date'),
          ),
        ),
      ],
      onRowTap: (StockBatchModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        _showJsonModelDialog<StockBatchModel>(
          context,
          'Batch #$id',
          () => _service.stockBatch(id),
        );
      },
    );
  }
}

class StockSerialRegisterPage extends StatefulWidget {
  const StockSerialRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<StockSerialRegisterPage> createState() =>
      _StockSerialRegisterPageState();
}

class _StockSerialRegisterPageState extends State<StockSerialRegisterPage> {
  final InventoryService _service = InventoryService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  List<StockSerialModel> _rows = const <StockSerialModel>[];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _service.stockSerials(
        filters: const {'per_page': 200, 'sort_by': 'serial_no'},
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _rows = response.data ?? const <StockSerialModel>[];
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  List<StockSerialModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((StockSerialModel row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'serial_no'),
            stringValue(data, 'status'),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<StockSerialModel>(
      title: 'Stock serials',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No stock serials found.',
      actions: const <Widget>[],
      filters: _RegisterFilters(
        searchController: _searchController,
        searchHint: 'Search serials',
        status: '',
        statusItems: const <AppDropdownItem<String>>[],
        onStatusChanged: (_) {},
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<StockSerialModel>(
          label: 'Serial',
          valueBuilder: (StockSerialModel row) =>
              stringValue(row.toJson(), 'serial_no'),
        ),
        PurchaseRegisterColumn<StockSerialModel>(
          label: 'Status',
          valueBuilder: (StockSerialModel row) =>
              stringValue(row.toJson(), 'status'),
        ),
        PurchaseRegisterColumn<StockSerialModel>(
          label: 'Warehouse',
          valueBuilder: (StockSerialModel row) =>
              stringValue(row.toJson(), 'warehouse_id'),
        ),
      ],
      onRowTap: (StockSerialModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        _showJsonModelDialog<StockSerialModel>(
          context,
          'Serial #$id',
          () => _service.stockSerial(id),
        );
      },
    );
  }
}
