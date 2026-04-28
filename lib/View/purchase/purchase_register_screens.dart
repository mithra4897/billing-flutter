import '../../screen.dart';
import 'purchase_register_page.dart';
import 'purchase_support.dart';

void _openShellRoute(BuildContext context, String route) {
  final navigate = ShellRouteScope.maybeOf(context);
  if (navigate != null) {
    navigate(route);
    return;
  }
  Navigator.of(context).pushNamed(route);
}

String _nestedName(
  Map<String, dynamic> data,
  String flatKey,
  String relationKey,
  String nestedKey,
) {
  final flat = stringValue(data, flatKey);
  if (flat.isNotEmpty) {
    return flat;
  }
  final relation = data[relationKey];
  if (relation is Map<String, dynamic>) {
    return stringValue(relation, nestedKey);
  }
  return '';
}

class PurchaseRequisitionRegisterPage extends StatefulWidget {
  const PurchaseRequisitionRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<PurchaseRequisitionRegisterPage> createState() =>
      _PurchaseRequisitionRegisterPageState();
}

class _PurchaseRequisitionRegisterPageState
    extends State<PurchaseRequisitionRegisterPage> {
  static const _statusItems = <AppDropdownItem<String>>[
    AppDropdownItem(value: '', label: 'All Status'),
    AppDropdownItem(value: 'draft', label: 'Draft'),
    AppDropdownItem(value: 'approved', label: 'Approved'),
    AppDropdownItem(value: 'partially_ordered', label: 'Partially Ordered'),
    AppDropdownItem(value: 'fully_ordered', label: 'Fully Ordered'),
    AppDropdownItem(value: 'closed', label: 'Closed'),
    AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
  ];

  final PurchaseService _service = PurchaseService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String _status = '';
  List<PurchaseRequisitionModel> _rows = const <PurchaseRequisitionModel>[];

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
      final response = await _service.requisitions(
        filters: {'per_page': 200, 'sort_by': 'requisition_date'},
      );
      if (!mounted) return;
      setState(() {
        _rows = response.data ?? const <PurchaseRequisitionModel>[];
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  List<PurchaseRequisitionModel> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    return _rows
        .where((row) {
          final data = row.toJson();
          final statusOk =
              _status.isEmpty ||
              stringValue(data, 'requisition_status') == _status;
          final searchOk =
              query.isEmpty ||
              [
                stringValue(data, 'requisition_no'),
                stringValue(data, 'requisition_status'),
                stringValue(data, 'purpose'),
                stringValue(data, 'department'),
              ].join(' ').toLowerCase().contains(query);
          return statusOk && searchOk;
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<PurchaseRequisitionModel>(
      title: 'Purchase Requisitions',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No purchase requisitions found.',
      actions: [
        AdaptiveShellActionButton(
          onPressed: () =>
              _openShellRoute(context, '/purchase/requisitions/new'),
          icon: Icons.add_outlined,
          label: 'New Requisition',
        ),
      ],
      filters: _RegisterFilters(
        searchController: _searchController,
        searchHint: 'Search requisitions',
        status: _status,
        statusItems: _statusItems,
        onStatusChanged: (value) => setState(() => _status = value ?? ''),
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn(
          label: 'No',
          valueBuilder: (row) => stringValue(row.toJson(), 'requisition_no'),
        ),
        PurchaseRegisterColumn(
          label: 'Date',
          valueBuilder: (row) => displayDate(
            nullableStringValue(row.toJson(), 'requisition_date'),
          ),
        ),
        PurchaseRegisterColumn(
          label: 'Department',
          valueBuilder: (row) => stringValue(row.toJson(), 'department'),
        ),
        PurchaseRegisterColumn(
          label: 'Purpose',
          flex: 3,
          valueBuilder: (row) => stringValue(row.toJson(), 'purpose'),
        ),
        PurchaseRegisterColumn(
          label: 'Status',
          valueBuilder: (row) =>
              stringValue(row.toJson(), 'requisition_status'),
        ),
      ],
      onRowTap: (row) => _openShellRoute(
        context,
        '/purchase/requisitions/${intValue(row.toJson(), 'id')}',
      ),
    );
  }
}

class PurchaseOrderRegisterPage extends StatefulWidget {
  const PurchaseOrderRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<PurchaseOrderRegisterPage> createState() =>
      _PurchaseOrderRegisterPageState();
}

class _PurchaseOrderRegisterPageState extends State<PurchaseOrderRegisterPage> {
  static const _statusItems = <AppDropdownItem<String>>[
    AppDropdownItem(value: '', label: 'All Status'),
    AppDropdownItem(value: 'draft', label: 'Draft'),
    AppDropdownItem(value: 'confirmed', label: 'Confirmed'),
    AppDropdownItem(value: 'partially_received', label: 'Partially Received'),
    AppDropdownItem(value: 'fully_received', label: 'Fully Received'),
    AppDropdownItem(value: 'partially_invoiced', label: 'Partially Invoiced'),
    AppDropdownItem(value: 'fully_invoiced', label: 'Fully Invoiced'),
    AppDropdownItem(value: 'closed', label: 'Closed'),
    AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
  ];

  final PurchaseService _service = PurchaseService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String _status = '';
  List<PurchaseOrderModel> _rows = const <PurchaseOrderModel>[];

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
      final response = await _service.orders(
        filters: {'per_page': 200, 'sort_by': 'order_date'},
      );
      if (!mounted) return;
      setState(() {
        _rows = response.data ?? const <PurchaseOrderModel>[];
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  List<PurchaseOrderModel> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    return _rows
        .where((row) {
          final data = row.toJson();
          final statusOk =
              _status.isEmpty || stringValue(data, 'order_status') == _status;
          final searchOk =
              query.isEmpty ||
              [
                stringValue(data, 'order_no'),
                stringValue(data, 'supplier_name'),
                stringValue(data, 'order_status'),
              ].join(' ').toLowerCase().contains(query);
          return statusOk && searchOk;
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<PurchaseOrderModel>(
      title: 'Purchase Orders',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No purchase orders found.',
      actions: [
        AdaptiveShellActionButton(
          onPressed: () => _openShellRoute(context, '/purchase/orders/new'),
          icon: Icons.add_outlined,
          label: 'New Order',
        ),
      ],
      filters: _RegisterFilters(
        searchController: _searchController,
        searchHint: 'Search orders',
        status: _status,
        statusItems: _statusItems,
        onStatusChanged: (value) => setState(() => _status = value ?? ''),
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn(
          label: 'No',
          valueBuilder: (row) => stringValue(row.toJson(), 'order_no'),
        ),
        PurchaseRegisterColumn(
          label: 'Date',
          valueBuilder: (row) =>
              displayDate(nullableStringValue(row.toJson(), 'order_date')),
        ),
        PurchaseRegisterColumn(
          label: 'Supplier',
          flex: 3,
          valueBuilder: (row) => _nestedName(
            row.toJson(),
            'supplier_name',
            'supplier',
            'party_name',
          ),
        ),
        PurchaseRegisterColumn(
          label: 'Expected Receipt',
          valueBuilder: (row) => displayDate(
            nullableStringValue(row.toJson(), 'expected_receipt_date'),
          ),
        ),
        PurchaseRegisterColumn(
          label: 'Status',
          valueBuilder: (row) => stringValue(row.toJson(), 'order_status'),
        ),
      ],
      onRowTap: (row) => _openShellRoute(
        context,
        '/purchase/orders/${intValue(row.toJson(), 'id')}',
      ),
    );
  }
}

class PurchaseReceiptRegisterPage extends StatefulWidget {
  const PurchaseReceiptRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<PurchaseReceiptRegisterPage> createState() =>
      _PurchaseReceiptRegisterPageState();
}

class _PurchaseReceiptRegisterPageState
    extends State<PurchaseReceiptRegisterPage> {
  static const _statusItems = <AppDropdownItem<String>>[
    AppDropdownItem(value: '', label: 'All Status'),
    AppDropdownItem(value: 'draft', label: 'Draft'),
    AppDropdownItem(value: 'posted', label: 'Posted'),
    AppDropdownItem(value: 'partially_invoiced', label: 'Partially Invoiced'),
    AppDropdownItem(value: 'fully_invoiced', label: 'Fully Invoiced'),
    AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
  ];

  final PurchaseService _service = PurchaseService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String _status = '';
  List<PurchaseReceiptModel> _rows = const <PurchaseReceiptModel>[];

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
      final response = await _service.receipts(
        filters: {'per_page': 200, 'sort_by': 'receipt_date'},
      );
      if (!mounted) return;
      setState(() {
        _rows = response.data ?? const <PurchaseReceiptModel>[];
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  List<PurchaseReceiptModel> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    return _rows
        .where((row) {
          final data = row.toJson();
          final statusOk =
              _status.isEmpty || stringValue(data, 'receipt_status') == _status;
          final searchOk =
              query.isEmpty ||
              [
                stringValue(data, 'receipt_no'),
                stringValue(data, 'supplier_name'),
                stringValue(data, 'receipt_status'),
              ].join(' ').toLowerCase().contains(query);
          return statusOk && searchOk;
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<PurchaseReceiptModel>(
      title: 'Purchase Receipts',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No purchase receipts found.',
      actions: [
        AdaptiveShellActionButton(
          onPressed: () => _openShellRoute(context, '/purchase/receipts/new'),
          icon: Icons.add_outlined,
          label: 'New Receipt',
        ),
      ],
      filters: _RegisterFilters(
        searchController: _searchController,
        searchHint: 'Search receipts',
        status: _status,
        statusItems: _statusItems,
        onStatusChanged: (value) => setState(() => _status = value ?? ''),
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn(
          label: 'No',
          valueBuilder: (row) => stringValue(row.toJson(), 'receipt_no'),
        ),
        PurchaseRegisterColumn(
          label: 'Date',
          valueBuilder: (row) =>
              displayDate(nullableStringValue(row.toJson(), 'receipt_date')),
        ),
        PurchaseRegisterColumn(
          label: 'Supplier',
          flex: 3,
          valueBuilder: (row) => _nestedName(
            row.toJson(),
            'supplier_name',
            'supplier',
            'party_name',
          ),
        ),
        PurchaseRegisterColumn(
          label: 'Supplier Invoice',
          valueBuilder: (row) =>
              stringValue(row.toJson(), 'supplier_invoice_no'),
        ),
        PurchaseRegisterColumn(
          label: 'Status',
          valueBuilder: (row) => stringValue(row.toJson(), 'receipt_status'),
        ),
      ],
      onRowTap: (row) => _openShellRoute(
        context,
        '/purchase/receipts/${intValue(row.toJson(), 'id')}',
      ),
    );
  }
}

class PurchaseInvoiceRegisterPage extends StatefulWidget {
  const PurchaseInvoiceRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<PurchaseInvoiceRegisterPage> createState() =>
      _PurchaseInvoiceRegisterPageState();
}

class _PurchaseInvoiceRegisterPageState
    extends State<PurchaseInvoiceRegisterPage> {
  static const _statusItems = <AppDropdownItem<String>>[
    AppDropdownItem(value: '', label: 'All Status'),
    AppDropdownItem(value: 'draft', label: 'Draft'),
    AppDropdownItem(value: 'posted', label: 'Posted'),
    AppDropdownItem(value: 'partially_paid', label: 'Partially Paid'),
    AppDropdownItem(value: 'paid', label: 'Paid'),
    AppDropdownItem(value: 'partially_returned', label: 'Partially Returned'),
    AppDropdownItem(value: 'returned', label: 'Returned'),
    AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
  ];

  final PurchaseService _service = PurchaseService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String _status = '';
  List<PurchaseInvoiceModel> _rows = const <PurchaseInvoiceModel>[];

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
      final response = await _service.invoices(
        filters: {'per_page': 200, 'sort_by': 'invoice_date'},
      );
      if (!mounted) return;
      setState(() {
        _rows = response.data ?? const <PurchaseInvoiceModel>[];
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  List<PurchaseInvoiceModel> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    return _rows
        .where((row) {
          final statusOk = _status.isEmpty || row.invoiceStatus == _status;
          final searchOk =
              query.isEmpty ||
              [
                row.invoiceNo ?? '',
                row.invoiceStatus ?? '',
                _nestedName(
                  row.raw ?? const <String, dynamic>{},
                  'supplier_name',
                  'supplier',
                  'party_name',
                ),
              ].join(' ').toLowerCase().contains(query);
          return statusOk && searchOk;
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<PurchaseInvoiceModel>(
      title: 'Purchase Invoices',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No purchase invoices found.',
      actions: [
        AdaptiveShellActionButton(
          onPressed: () => _openShellRoute(context, '/purchase/invoices/new'),
          icon: Icons.add_outlined,
          label: 'New Invoice',
        ),
      ],
      filters: _RegisterFilters(
        searchController: _searchController,
        searchHint: 'Search invoices',
        status: _status,
        statusItems: _statusItems,
        onStatusChanged: (value) => setState(() => _status = value ?? ''),
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn(
          label: 'No',
          valueBuilder: (row) => row.invoiceNo ?? '',
        ),
        PurchaseRegisterColumn(
          label: 'Date',
          valueBuilder: (row) => displayDate(row.invoiceDate),
        ),
        PurchaseRegisterColumn(
          label: 'Supplier',
          flex: 3,
          valueBuilder: (row) => _nestedName(
            row.raw ?? const <String, dynamic>{},
            'supplier_name',
            'supplier',
            'party_name',
          ),
        ),
        PurchaseRegisterColumn(
          label: 'Due',
          valueBuilder: (row) => displayDate(row.dueDate),
        ),
        PurchaseRegisterColumn(
          label: 'Status',
          valueBuilder: (row) => row.invoiceStatus ?? '',
        ),
      ],
      onRowTap: (row) =>
          _openShellRoute(context, '/purchase/invoices/${row.id}'),
    );
  }
}

class PurchasePaymentRegisterPage extends StatefulWidget {
  const PurchasePaymentRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<PurchasePaymentRegisterPage> createState() =>
      _PurchasePaymentRegisterPageState();
}

class _PurchasePaymentRegisterPageState
    extends State<PurchasePaymentRegisterPage> {
  static const _statusItems = <AppDropdownItem<String>>[
    AppDropdownItem(value: '', label: 'All Status'),
    AppDropdownItem(value: 'draft', label: 'Draft'),
    AppDropdownItem(value: 'posted', label: 'Posted'),
    AppDropdownItem(value: 'partially_allocated', label: 'Partially Allocated'),
    AppDropdownItem(value: 'fully_allocated', label: 'Fully Allocated'),
    AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
  ];

  final PurchaseService _service = PurchaseService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String _status = '';
  List<PurchasePaymentModel> _rows = const <PurchasePaymentModel>[];

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
      final response = await _service.payments(
        filters: {'per_page': 200, 'sort_by': 'payment_date'},
      );
      if (!mounted) return;
      setState(() {
        _rows = response.data ?? const <PurchasePaymentModel>[];
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  List<PurchasePaymentModel> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    return _rows
        .where((row) {
          final data = row.toJson();
          final statusOk =
              _status.isEmpty || stringValue(data, 'payment_status') == _status;
          final searchOk =
              query.isEmpty ||
              [
                stringValue(data, 'payment_no'),
                stringValue(data, 'supplier_name'),
                stringValue(data, 'reference_no'),
                stringValue(data, 'payment_status'),
              ].join(' ').toLowerCase().contains(query);
          return statusOk && searchOk;
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<PurchasePaymentModel>(
      title: 'Purchase Payments',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No purchase payments found.',
      actions: [
        AdaptiveShellActionButton(
          onPressed: () => _openShellRoute(context, '/purchase/payments/new'),
          icon: Icons.add_outlined,
          label: 'New Payment',
        ),
      ],
      filters: _RegisterFilters(
        searchController: _searchController,
        searchHint: 'Search payments',
        status: _status,
        statusItems: _statusItems,
        onStatusChanged: (value) => setState(() => _status = value ?? ''),
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn(
          label: 'No',
          valueBuilder: (row) => stringValue(row.toJson(), 'payment_no'),
        ),
        PurchaseRegisterColumn(
          label: 'Date',
          valueBuilder: (row) =>
              displayDate(nullableStringValue(row.toJson(), 'payment_date')),
        ),
        PurchaseRegisterColumn(
          label: 'Supplier',
          flex: 3,
          valueBuilder: (row) => _nestedName(
            row.toJson(),
            'supplier_name',
            'supplier',
            'party_name',
          ),
        ),
        PurchaseRegisterColumn(
          label: 'Mode',
          valueBuilder: (row) => stringValue(row.toJson(), 'payment_mode'),
        ),
        PurchaseRegisterColumn(
          label: 'Status',
          valueBuilder: (row) => stringValue(row.toJson(), 'payment_status'),
        ),
      ],
      onRowTap: (row) => _openShellRoute(
        context,
        '/purchase/payments/${intValue(row.toJson(), 'id')}',
      ),
    );
  }
}

class PurchaseReturnRegisterPage extends StatefulWidget {
  const PurchaseReturnRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<PurchaseReturnRegisterPage> createState() =>
      _PurchaseReturnRegisterPageState();
}

class _PurchaseReturnRegisterPageState
    extends State<PurchaseReturnRegisterPage> {
  static const _statusItems = <AppDropdownItem<String>>[
    AppDropdownItem(value: '', label: 'All Status'),
    AppDropdownItem(value: 'draft', label: 'Draft'),
    AppDropdownItem(value: 'posted', label: 'Posted'),
    AppDropdownItem(value: 'debited', label: 'Debited'),
    AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
  ];

  final PurchaseService _service = PurchaseService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String _status = '';
  List<PurchaseReturnModel> _rows = const <PurchaseReturnModel>[];

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
      final response = await _service.returns(
        filters: {'per_page': 200, 'sort_by': 'return_date'},
      );
      if (!mounted) return;
      setState(() {
        _rows = response.data ?? const <PurchaseReturnModel>[];
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  List<PurchaseReturnModel> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    return _rows
        .where((row) {
          final data = row.toJson();
          final statusOk =
              _status.isEmpty || stringValue(data, 'return_status') == _status;
          final searchOk =
              query.isEmpty ||
              [
                stringValue(data, 'return_no'),
                stringValue(data, 'return_reason'),
                stringValue(data, 'return_status'),
              ].join(' ').toLowerCase().contains(query);
          return statusOk && searchOk;
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<PurchaseReturnModel>(
      title: 'Purchase Returns',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No purchase returns found.',
      actions: [
        AdaptiveShellActionButton(
          onPressed: () => _openShellRoute(context, '/purchase/returns/new'),
          icon: Icons.add_outlined,
          label: 'New Return',
        ),
      ],
      filters: _RegisterFilters(
        searchController: _searchController,
        searchHint: 'Search returns',
        status: _status,
        statusItems: _statusItems,
        onStatusChanged: (value) => setState(() => _status = value ?? ''),
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn(
          label: 'No',
          valueBuilder: (row) => stringValue(row.toJson(), 'return_no'),
        ),
        PurchaseRegisterColumn(
          label: 'Date',
          valueBuilder: (row) =>
              displayDate(nullableStringValue(row.toJson(), 'return_date')),
        ),
        PurchaseRegisterColumn(
          label: 'Purchase Invoice',
          valueBuilder: (row) => _nestedName(
            row.toJson(),
            'purchase_invoice_no',
            'purchase_invoice',
            'invoice_no',
          ),
        ),
        PurchaseRegisterColumn(
          label: 'Reason',
          flex: 3,
          valueBuilder: (row) => stringValue(row.toJson(), 'return_reason'),
        ),
        PurchaseRegisterColumn(
          label: 'Status',
          valueBuilder: (row) => stringValue(row.toJson(), 'return_status'),
        ),
      ],
      onRowTap: (row) => _openShellRoute(
        context,
        '/purchase/returns/${intValue(row.toJson(), 'id')}',
      ),
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
    return SettingsFormWrap(
      children: [
        AppFormTextField(
          labelText: 'Search',
          controller: searchController,
          hintText: searchHint,
        ),
        AppDropdownField<String>.fromMapped(
          labelText: 'Status',
          mappedItems: statusItems,
          initialValue: status,
          onChanged: onStatusChanged,
        ),
      ],
    );
  }
}
