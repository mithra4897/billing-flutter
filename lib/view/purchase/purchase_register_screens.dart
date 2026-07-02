import '../../screen.dart';
import '../../controller/purchase/purchase_module_refresh_controller.dart';

typedef PurchaseRegisterLoader<T> =
    Future<dynamic> Function(PurchaseService service);
typedef PurchaseRegisterMatcher<T> =
    bool Function(T row, String query, String status);

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

class PurchaseListRegisterController<T> extends GetxController {
  PurchaseListRegisterController({required this.loader, required this.matches});

  final PurchaseRegisterLoader<T> loader;
  final PurchaseRegisterMatcher<T> matches;
  final PurchaseService _service = PurchaseService();
  final PurchaseModuleRefreshController _refreshController =
      PurchaseModuleRefreshController.ensureRegistered();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController dateFromController = TextEditingController();
  final TextEditingController dateToController = TextEditingController();

  bool loading = true;
  String? error;
  String status = '';
  Map<String, dynamic> customFilters = <String, dynamic>{};
  List<T> rows = <T>[];
  Worker? _refreshWorker;

  List<T> get filteredRows {
    final query = searchController.text.trim().toLowerCase();
    return rows
        .where((row) => matches(row, query, status))
        .toList(growable: false);
  }

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(update);
    dateFromController.addListener(update);
    dateToController.addListener(update);
    _refreshWorker = ever<PurchaseModuleRefreshEvent?>(
      _refreshController.lastEvent,
      (event) {
        if (event == null) {
          return;
        }
        unawaited(load());
      },
    );
    unawaited(load());
  }

  @override
  void onClose() {
    _refreshWorker?.dispose();
    searchController
      ..removeListener(update)
      ..dispose();
    dateFromController
      ..removeListener(update)
      ..dispose();
    dateToController
      ..removeListener(update)
      ..dispose();
    super.onClose();
  }

  void setStatus(String value) {
    status = value;
    update();
  }

  void setCustomFilter(String key, dynamic value) {
    customFilters[key] = value;
    update();
  }

  Future<void> load() async {
    loading = true;
    error = null;
    update();
    try {
      final response = await loader(_service);
      final data = response.data;
      rows = data is List<T>
          ? data
          : data is List
          ? data.whereType<T>().toList(growable: false)
          : <T>[];
      loading = false;
      update();
    } catch (err) {
      error = err.toString();
      loading = false;
      update();
    }
  }
}

class _PurchaseRegisterShell<T> extends StatefulWidget {
  const _PurchaseRegisterShell({
    required this.controllerName,
    required this.title,
    required this.embedded,
    required this.loader,
    required this.matches,
    required this.emptyMessage,
    required this.newRoute,
    required this.newLabel,
    required this.searchHint,
    required this.statusItems,
    required this.columns,
    required this.rowRoute,
    this.customFiltersBuilder,
    this.extraActionsBuilder,
    this.filterFieldsBuilder,
    this.filterTrailingActionsBuilder,
    this.filtersMaxWidth,
  });

  final String controllerName;
  final String title;
  final bool embedded;
  final PurchaseRegisterLoader<T> loader;
  final PurchaseRegisterMatcher<T> matches;
  final String emptyMessage;
  final String newRoute;
  final String newLabel;
  final String searchHint;
  final List<AppDropdownItem<String>> statusItems;
  final List<PurchaseRegisterColumn<T>> columns;
  final String Function(T row) rowRoute;
  final Widget Function(
    BuildContext context,
    PurchaseListRegisterController<T> controller,
  )?
  customFiltersBuilder;
  final List<Widget> Function(
    BuildContext context,
    PurchaseListRegisterController<T> controller,
  )?
  extraActionsBuilder;
  final List<Widget> Function(
    BuildContext context,
    PurchaseListRegisterController<T> controller,
  )?
  filterFieldsBuilder;
  final List<Widget> Function(
    BuildContext context,
    PurchaseListRegisterController<T> controller,
  )?
  filterTrailingActionsBuilder;
  final double? filtersMaxWidth;

  @override
  State<_PurchaseRegisterShell<T>> createState() =>
      _PurchaseRegisterShellState<T>();
}

class _PurchaseRegisterShellState<T> extends State<_PurchaseRegisterShell<T>> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(widget.controllerName);
    if (!Get.isRegistered<PurchaseListRegisterController<T>>(
      tag: _controllerTag,
    )) {
      Get.put(
        PurchaseListRegisterController<T>(
          loader: widget.loader,
          matches: widget.matches,
        ),
        tag: _controllerTag,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PurchaseListRegisterController<T>>(
      tag: _controllerTag,
      builder: (controller) {
        return PurchaseRegisterPage<T>(
          title: widget.title,
          embedded: widget.embedded,
          loading: controller.loading,
          errorMessage: controller.error,
          onRetry: controller.load,
          emptyMessage: widget.emptyMessage,
          actions: [
            if (widget.extraActionsBuilder != null)
              ...widget.extraActionsBuilder!(context, controller),
            AdaptiveShellActionButton(
              onPressed: () => _openShellRoute(context, widget.newRoute),
              icon: Icons.add_outlined,
              label: widget.newLabel,
            ),
          ],
          filters:
              widget.customFiltersBuilder?.call(context, controller) ??
              _RegisterFilters(
                searchController: controller.searchController,
                searchHint: widget.searchHint,
                filterFields: widget.filterFieldsBuilder?.call(
                  context,
                  controller,
                ),
                trailingActions: widget.filterTrailingActionsBuilder?.call(
                  context,
                  controller,
                ),
                maxWidth: widget.filtersMaxWidth,
                status: controller.status,
                statusItems: widget.statusItems,
                onStatusChanged: (value) => controller.setStatus(value ?? ''),
              ),
          rows: controller.filteredRows,
          columns: widget.columns,
          onRowTap: (row) => _openShellRoute(context, widget.rowRoute(row)),
        );
      },
    );
  }
}

class PurchaseRequisitionRegisterPage extends StatelessWidget {
  const PurchaseRequisitionRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  static const _statusItems = <AppDropdownItem<String>>[
    AppDropdownItem(value: '', label: 'All Status'),
    AppDropdownItem(value: 'draft', label: 'Draft'),
    AppDropdownItem(value: 'approved', label: 'Approved'),
    AppDropdownItem(value: 'partially_ordered', label: 'Partially Ordered'),
    AppDropdownItem(value: 'fully_ordered', label: 'Fully Ordered'),
    AppDropdownItem(value: 'closed', label: 'Closed'),
    AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
  ];

  @override
  Widget build(BuildContext context) {
    return _PurchaseRegisterShell<PurchaseRequisitionModel>(
      controllerName: 'PurchaseRequisitionRegisterController',
      title: 'Purchase Requisitions',
      embedded: embedded,
      loader: (service) => service.requisitions(
        filters: {'per_page': 200, 'sort_by': 'requisition_date'},
      ),
      matches: (row, query, status) {
        final controller =
            Get.find<PurchaseListRegisterController<PurchaseRequisitionModel>>(
              tag: persistentControllerTag(
                'PurchaseRequisitionRegisterController',
              ),
            );
        final data = row.toJson();
        final statusOk =
            status.isEmpty || stringValue(data, 'requisition_status') == status;
        final searchOk =
            query.isEmpty ||
            [
              stringValue(data, 'requisition_no'),
              purchaseStatusLabel(
                nullableStringValue(data, 'requisition_status'),
              ),
              stringValue(data, 'purpose'),
              stringValue(data, 'department'),
            ].join(' ').toLowerCase().contains(query);
        final dateOk = matchesDateValueRange(
          nullableStringValue(data, 'requisition_date'),
          fromValue: controller.dateFromController.text,
          toValue: controller.dateToController.text,
        );
        return statusOk && searchOk && dateOk;
      },
      emptyMessage: 'No purchase requisitions found.',
      customFiltersBuilder: (context, controller) => _PurchaseRegisterFilters(
        controller: controller,
        statusItems: _statusItems,
        title: 'Find Requisitions',
        searchHint: 'Requisition no, purpose, department',
      ),
      newRoute: '/purchase/requisitions/new',
      newLabel: 'New Requisition',
      searchHint: 'Search requisitions',
      statusItems: _statusItems,
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
          valueBuilder: (row) => purchaseStatusLabel(
            nullableStringValue(row.toJson(), 'requisition_status'),
          ),
          widgetBuilder: (context, row) => purchaseStatusBadge(
            context,
            nullableStringValue(row.toJson(), 'requisition_status'),
          ),
        ),
      ],
      rowRoute: (row) =>
          '/purchase/requisitions/${intValue(row.toJson(), 'id')}',
    );
  }
}

class PurchaseOrderRegisterPage extends StatelessWidget {
  const PurchaseOrderRegisterPage({super.key, this.embedded = false});

  final bool embedded;

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

  @override
  Widget build(BuildContext context) {
    return _PurchaseRegisterShell<PurchaseOrderModel>(
      controllerName: 'PurchaseOrderRegisterController',
      title: 'Purchase Orders',
      embedded: embedded,
      loader: (service) =>
          service.ordersAll(filters: {'sort_by': 'order_date'}),
      matches: (row, query, status) {
        final controller =
            Get.find<PurchaseListRegisterController<PurchaseOrderModel>>(
              tag: persistentControllerTag('PurchaseOrderRegisterController'),
            );
        final data = row.toJson();
        final statusOk =
            status.isEmpty || stringValue(data, 'order_status') == status;
        final searchOk =
            query.isEmpty ||
            [
              stringValue(data, 'order_no'),
              stringValue(data, 'supplier_name'),
              purchaseStatusLabel(nullableStringValue(data, 'order_status')),
            ].join(' ').toLowerCase().contains(query);
        final filterSupplierId =
            controller.customFilters['supplier_id'] as int?;
        final supplierOk =
            filterSupplierId == null ||
            intValue(data, 'supplier_party_id') == filterSupplierId;
        final dateOk = matchesDateValueRange(
          nullableStringValue(data, 'order_date'),
          fromValue: controller.dateFromController.text,
          toValue: controller.dateToController.text,
        );
        return statusOk && searchOk && supplierOk && dateOk;
      },
      emptyMessage: 'No purchase orders found.',
      customFiltersBuilder: (context, controller) => _PurchaseRegisterFilters(
        controller: controller,
        statusItems: _statusItems,
        title: 'Find Orders',
        searchHint: 'Order no or supplier name',
        supplierItemsBuilder: _mappedSupplierItems,
      ),
      newRoute: '/purchase/orders/new',
      newLabel: 'New Order',
      searchHint: 'Search orders',
      statusItems: _statusItems,
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
          valueBuilder: (row) => purchaseStatusLabel(
            nullableStringValue(row.toJson(), 'order_status'),
          ),
          widgetBuilder: (context, row) => purchaseStatusBadge(
            context,
            nullableStringValue(row.toJson(), 'order_status'),
          ),
        ),
      ],
      rowRoute: (row) => '/purchase/orders/${intValue(row.toJson(), 'id')}',
    );
  }
}

class PurchaseReceiptRegisterPage extends StatelessWidget {
  const PurchaseReceiptRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  static const _statusItems = <AppDropdownItem<String>>[
    AppDropdownItem(value: '', label: 'All Status'),
    AppDropdownItem(value: 'draft', label: 'Draft'),
    AppDropdownItem(value: 'posted', label: 'Posted'),
    AppDropdownItem(value: 'partially_invoiced', label: 'Partially Invoiced'),
    AppDropdownItem(value: 'fully_invoiced', label: 'Fully Invoiced'),
    AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
  ];

  @override
  Widget build(BuildContext context) {
    return _PurchaseRegisterShell<PurchaseReceiptModel>(
      controllerName: 'PurchaseReceiptRegisterController',
      title: 'Purchase Receipts',
      embedded: embedded,
      loader: (service) => service.receipts(
        filters: {'per_page': 200, 'sort_by': 'receipt_date'},
      ),
      matches: (row, query, status) {
        final controller =
            Get.find<PurchaseListRegisterController<PurchaseReceiptModel>>(
              tag: persistentControllerTag('PurchaseReceiptRegisterController'),
            );
        final data = row.toJson();
        final statusOk =
            status.isEmpty || stringValue(data, 'receipt_status') == status;
        final searchOk =
            query.isEmpty ||
            [
              stringValue(data, 'receipt_no'),
              stringValue(data, 'supplier_name'),
              purchaseStatusLabel(nullableStringValue(data, 'receipt_status')),
            ].join(' ').toLowerCase().contains(query);
        final filterSupplierId =
            controller.customFilters['supplier_id'] as int?;
        final supplierOk =
            filterSupplierId == null ||
            intValue(data, 'supplier_party_id') == filterSupplierId;
        final dateOk = matchesDateValueRange(
          nullableStringValue(data, 'receipt_date'),
          fromValue: controller.dateFromController.text,
          toValue: controller.dateToController.text,
        );
        return statusOk && searchOk && supplierOk && dateOk;
      },
      emptyMessage: 'No purchase receipts found.',
      customFiltersBuilder: (context, controller) => _PurchaseRegisterFilters(
        controller: controller,
        statusItems: _statusItems,
        title: 'Find Receipts',
        searchHint: 'Receipt no or supplier name',
        supplierItemsBuilder: _mappedSupplierItems,
      ),
      newRoute: '/purchase/receipts/new',
      newLabel: 'New Receipt',
      searchHint: 'Search receipts',
      statusItems: _statusItems,
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
          valueBuilder: (row) => purchaseStatusLabel(
            nullableStringValue(row.toJson(), 'receipt_status'),
          ),
          widgetBuilder: (context, row) => purchaseStatusBadge(
            context,
            nullableStringValue(row.toJson(), 'receipt_status'),
          ),
        ),
      ],
      rowRoute: (row) => '/purchase/receipts/${intValue(row.toJson(), 'id')}',
    );
  }
}

class PurchaseInvoiceRegisterPage extends StatelessWidget {
  const PurchaseInvoiceRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  static const _statusItems = <AppDropdownItem<String>>[
    AppDropdownItem(value: '', label: 'All Status'),
    AppDropdownItem(value: 'draft', label: 'Draft'),
    AppDropdownItem(value: 'posted', label: 'Posted'),
    AppDropdownItem(value: 'overdue', label: 'Overdue'),
    AppDropdownItem(value: 'partially_paid', label: 'Partially Paid'),
    AppDropdownItem(value: 'paid', label: 'Paid'),
    AppDropdownItem(value: 'partially_returned', label: 'Partially Returned'),
    AppDropdownItem(value: 'returned', label: 'Returned'),
    AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
  ];

  @override
  Widget build(BuildContext context) {
    return _PurchaseRegisterShell<PurchaseInvoiceModel>(
      controllerName: 'PurchaseInvoiceRegisterController',
      title: 'Purchase Invoices',
      embedded: embedded,
      loader: (service) => service.invoices(
        filters: {'per_page': 200, 'sort_by': 'invoice_date'},
      ),
      matches: (row, query, status) {
        final statusOk = status.isEmpty || row.invoiceStatus == status;
        final searchOk =
            query.isEmpty ||
            [
              row.invoiceNo ?? '',
              _nestedName(
                row.toJson(),
                'supplier_name',
                'supplier',
                'party_name',
              ),
            ].join(' ').toLowerCase().contains(query);
        final controller =
            Get.find<PurchaseListRegisterController<PurchaseInvoiceModel>>(
              tag: persistentControllerTag('PurchaseInvoiceRegisterController'),
            );

        final filterSupplierId =
            controller.customFilters['supplier_id'] as int?;

        final supplierOk =
            filterSupplierId == null || row.supplierPartyId == filterSupplierId;

        final dateOk = matchesDateValueRange(
          row.invoiceDate,
          fromValue: controller.dateFromController.text,
          toValue: controller.dateToController.text,
        );

        return statusOk && searchOk && supplierOk && dateOk;
      },
      emptyMessage: 'No purchase invoices found.',
      customFiltersBuilder: (context, controller) => _PurchaseInvoiceFilters(
        controller: controller,
        statusItems: _statusItems,
      ),
      newRoute: '/purchase/invoices/new',
      newLabel: 'New Invoice',
      searchHint: 'Search invoices',
      statusItems: _statusItems,
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
            row.toJson(),
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
          valueBuilder: (row) => purchaseStatusLabel(row.invoiceStatus),
          widgetBuilder: (context, row) => purchaseStatusBadge(
            context,
            row.invoiceStatus,
            dueDate: row.dueDate,
          ),
        ),
      ],
      rowRoute: (row) => '/purchase/invoices/${row.id}',
    );
  }
}

class PurchasePaymentRegisterPage extends StatelessWidget {
  const PurchasePaymentRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  static const _statusItems = <AppDropdownItem<String>>[
    AppDropdownItem(value: '', label: 'All Status'),
    AppDropdownItem(value: 'draft', label: 'Draft'),
    AppDropdownItem(value: 'posted', label: 'Posted'),
    AppDropdownItem(value: 'partially_allocated', label: 'Partially Allocated'),
    AppDropdownItem(value: 'fully_allocated', label: 'Fully Allocated'),
    AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
  ];

  @override
  Widget build(BuildContext context) {
    return _PurchaseRegisterShell<PurchasePaymentModel>(
      controllerName: 'PurchasePaymentRegisterController',
      title: 'Purchase Payments',
      embedded: embedded,
      loader: (service) => service.payments(
        filters: {'per_page': 200, 'sort_by': 'payment_date'},
      ),
      matches: (row, query, status) {
        final controller =
            Get.find<PurchaseListRegisterController<PurchasePaymentModel>>(
              tag: persistentControllerTag('PurchasePaymentRegisterController'),
            );
        final data = row.toJson();
        final statusOk =
            status.isEmpty || stringValue(data, 'payment_status') == status;
        final searchOk =
            query.isEmpty ||
            [
              stringValue(data, 'payment_no'),
              stringValue(data, 'supplier_name'),
              stringValue(data, 'reference_no'),
              purchaseStatusLabel(nullableStringValue(data, 'payment_status')),
            ].join(' ').toLowerCase().contains(query);
        final filterSupplierId =
            controller.customFilters['supplier_id'] as int?;
        final supplierOk =
            filterSupplierId == null ||
            intValue(data, 'supplier_party_id') == filterSupplierId;
        final dateOk = matchesDateValueRange(
          nullableStringValue(data, 'payment_date'),
          fromValue: controller.dateFromController.text,
          toValue: controller.dateToController.text,
        );
        return statusOk && searchOk && supplierOk && dateOk;
      },
      emptyMessage: 'No purchase payments found.',
      customFiltersBuilder: (context, controller) => _PurchaseRegisterFilters(
        controller: controller,
        statusItems: _statusItems,
        title: 'Find Payments',
        searchHint: 'Payment no, reference no, supplier',
        supplierItemsBuilder: _mappedSupplierItems,
      ),
      newRoute: '/purchase/payments/new',
      newLabel: 'New Payment',
      searchHint: 'Search payments',
      statusItems: _statusItems,
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
          valueBuilder: (row) => purchaseStatusLabel(
            nullableStringValue(row.toJson(), 'payment_status'),
          ),
          widgetBuilder: (context, row) => purchaseStatusBadge(
            context,
            nullableStringValue(row.toJson(), 'payment_status'),
          ),
        ),
      ],
      rowRoute: (row) => '/purchase/payments/${intValue(row.toJson(), 'id')}',
    );
  }
}

class PurchaseReturnRegisterPage extends StatelessWidget {
  const PurchaseReturnRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  static const _statusItems = <AppDropdownItem<String>>[
    AppDropdownItem(value: '', label: 'All Status'),
    AppDropdownItem(value: 'draft', label: 'Draft'),
    AppDropdownItem(value: 'posted', label: 'Posted'),
    AppDropdownItem(value: 'debited', label: 'Debited'),
    AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
  ];

  @override
  Widget build(BuildContext context) {
    return _PurchaseRegisterShell<PurchaseReturnModel>(
      controllerName: 'PurchaseReturnRegisterController',
      title: 'Purchase Returns',
      embedded: embedded,
      loader: (service) =>
          service.returns(filters: {'per_page': 200, 'sort_by': 'return_date'}),
      matches: (row, query, status) {
        final controller =
            Get.find<PurchaseListRegisterController<PurchaseReturnModel>>(
              tag: persistentControllerTag('PurchaseReturnRegisterController'),
            );
        final data = row.toJson();
        final statusOk =
            status.isEmpty || stringValue(data, 'return_status') == status;
        final searchOk =
            query.isEmpty ||
            [
              stringValue(data, 'return_no'),
              stringValue(data, 'supplier_name'),
              stringValue(data, 'return_reason'),
              purchaseStatusLabel(nullableStringValue(data, 'return_status')),
            ].join(' ').toLowerCase().contains(query);
        final filterSupplierId =
            controller.customFilters['supplier_id'] as int?;
        final supplierOk =
            filterSupplierId == null ||
            intValue(data, 'supplier_party_id') == filterSupplierId;
        final dateOk = matchesDateValueRange(
          nullableStringValue(data, 'return_date'),
          fromValue: controller.dateFromController.text,
          toValue: controller.dateToController.text,
        );
        return statusOk && searchOk && supplierOk && dateOk;
      },
      emptyMessage: 'No purchase returns found.',
      customFiltersBuilder: (context, controller) => _PurchaseRegisterFilters(
        controller: controller,
        statusItems: _statusItems,
        title: 'Find Returns',
        searchHint: 'Return no or supplier name',
        supplierItemsBuilder: _mappedSupplierItems,
      ),
      newRoute: '/purchase/returns/new',
      newLabel: 'New Return',
      searchHint: 'Search returns',
      statusItems: _statusItems,
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
          valueBuilder: (row) => purchaseStatusLabel(
            nullableStringValue(row.toJson(), 'return_status'),
          ),
          widgetBuilder: (context, row) => purchaseStatusBadge(
            context,
            nullableStringValue(row.toJson(), 'return_status'),
          ),
        ),
      ],
      rowRoute: (row) => '/purchase/returns/${intValue(row.toJson(), 'id')}',
    );
  }
}

class _RegisterFilters extends StatelessWidget {
  const _RegisterFilters({
    required this.searchController,
    required this.searchHint,
    this.filterFields,
    this.trailingActions,
    this.maxWidth,
    required this.status,
    required this.statusItems,
    required this.onStatusChanged,
  });

  final TextEditingController searchController;
  final String searchHint;
  final List<Widget>? filterFields;
  final List<Widget>? trailingActions;
  final double? maxWidth;
  final String status;
  final List<AppDropdownItem<String>> statusItems;
  final ValueChanged<String?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return SettingsFormWrap(
      maxWidth: maxWidth ?? 300,
      children: [
        ...(filterFields ??
            <Widget>[
              AppFormTextField(
                labelText: 'Search',
                controller: searchController,
                hintText: searchHint,
              ),
            ]),
        AppDropdownField<String>.fromMapped(
          labelText: 'Status',
          mappedItems: statusItems,
          initialValue: status,
          onChanged: onStatusChanged,
        ),
        ...?trailingActions,
      ],
    );
  }
}

List<AppDropdownItem<int?>> _mappedSupplierItems<T>(
  PurchaseListRegisterController<T> controller,
) {
  final uniqueSuppliers = <int, String>{};
  for (final row in controller.rows) {
    if (row is! JsonModel) {
      continue;
    }
    final data = row.toJson();
    final id = intValue(data, 'supplier_party_id');
    final name = _nestedName(data, 'supplier_name', 'supplier', 'party_name');
    if (id != null && name.isNotEmpty) {
      uniqueSuppliers[id] = name;
    }
  }
  return <AppDropdownItem<int?>>[
    const AppDropdownItem<int?>(value: null, label: 'All Suppliers'),
    ...uniqueSuppliers.entries.map(
      (entry) => AppDropdownItem<int?>(value: entry.key, label: entry.value),
    ),
  ];
}

class _PurchaseRegisterFilters<T> extends StatelessWidget {
  const _PurchaseRegisterFilters({
    required this.controller,
    required this.statusItems,
    required this.title,
    required this.searchHint,
    this.supplierItemsBuilder,
  });

  final PurchaseListRegisterController<T> controller;
  final List<AppDropdownItem<String>> statusItems;
  final String title;
  final String searchHint;
  final List<AppDropdownItem<int?>> Function(
    PurchaseListRegisterController<T> controller,
  )?
  supplierItemsBuilder;

  void _clearFilters() {
    controller.searchController.clear();
    controller.dateFromController.clear();
    controller.dateToController.clear();
    controller.setCustomFilter('supplier_id', null);
    controller.setStatus('');
  }

  Widget _searchField() {
    return AppFormTextField(
      labelText: 'Search',
      controller: controller.searchController,
      hintText: searchHint,
    );
  }

  Widget _statusField() {
    return AppDropdownField<String>.fromMapped(
      labelText: 'Status',
      mappedItems: statusItems,
      initialValue: controller.status,
      onChanged: (value) => controller.setStatus(value ?? ''),
    );
  }

  Widget _supplierField() {
    return AppDropdownField<int?>.fromMapped(
      labelText: 'Supplier',
      mappedItems: supplierItemsBuilder!(controller),
      initialValue: controller.customFilters['supplier_id'] as int?,
      onChanged: (value) => controller.setCustomFilter('supplier_id', value),
    );
  }

  Widget _dateField({
    required String label,
    required TextEditingController textController,
  }) {
    return AppFormTextField(
      labelText: label,
      controller: textController,
      hintText: 'YYYY-MM-DD',
      keyboardType: TextInputType.datetime,
      inputFormatters: const [DateInputFormatter()],
      validator: Validators.optionalDate(label),
    );
  }

  Widget _actionField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppUiConstants.spacingXs),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _clearFilters,
            icon: const Icon(Icons.clear_outlined),
            label: const Text('Clear'),
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppUiConstants.buttonRadius,
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
    final hasSupplier = supplierItemsBuilder != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isWide = width >= 1320;
        final isMedium = width >= 920 && width < 1320;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _searchField()),
              const SizedBox(width: AppUiConstants.spacingMd),
              if (hasSupplier) ...[
                Expanded(child: _supplierField()),
                const SizedBox(width: AppUiConstants.spacingMd),
              ],
              Expanded(child: _statusField()),
              const SizedBox(width: AppUiConstants.spacingMd),
              Expanded(
                child: _dateField(
                  label: 'Date From',
                  textController: controller.dateFromController,
                ),
              ),
              const SizedBox(width: AppUiConstants.spacingMd),
              Expanded(
                child: _dateField(
                  label: 'Date To',
                  textController: controller.dateToController,
                ),
              ),
              const SizedBox(width: AppUiConstants.spacingMd),
              SizedBox(width: 160, child: _actionField(context)),
            ],
          );
        }

        if (isMedium) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppUiConstants.spacingMd),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _searchField()),
                  const SizedBox(width: AppUiConstants.spacingMd),
                  if (hasSupplier) ...[
                    Expanded(child: _supplierField()),
                    const SizedBox(width: AppUiConstants.spacingMd),
                  ],
                  Expanded(child: _statusField()),
                ],
              ),
              const SizedBox(height: AppUiConstants.spacingMd),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _dateField(
                      label: 'Date From',
                      textController: controller.dateFromController,
                    ),
                  ),
                  const SizedBox(width: AppUiConstants.spacingMd),
                  Expanded(
                    child: _dateField(
                      label: 'Date To',
                      textController: controller.dateToController,
                    ),
                  ),
                  const SizedBox(width: AppUiConstants.spacingMd),
                  Expanded(child: _actionField(context)),
                ],
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            SettingsFormWrap(
              maxWidth: double.infinity,
              children: [
                _searchField(),
                if (hasSupplier) _supplierField(),
                _statusField(),
                _dateField(
                  label: 'Date From',
                  textController: controller.dateFromController,
                ),
                _dateField(
                  label: 'Date To',
                  textController: controller.dateToController,
                ),
                _actionField(context),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _PurchaseInvoiceFilters extends StatelessWidget {
  const _PurchaseInvoiceFilters({
    required this.controller,
    required this.statusItems,
  });

  final PurchaseListRegisterController<PurchaseInvoiceModel> controller;
  final List<AppDropdownItem<String>> statusItems;

  List<AppDropdownItem<int?>> _supplierItems() {
    final Map<int, String> uniqueSuppliers = <int, String>{};
    for (final row in controller.rows) {
      final name = _nestedName(
        row.toJson(),
        'supplier_name',
        'supplier',
        'party_name',
      );
      if (name.isNotEmpty) {
        uniqueSuppliers[row.supplierPartyId] = name;
      }
    }

    return <AppDropdownItem<int?>>[
      const AppDropdownItem<int?>(value: null, label: 'All Suppliers'),
      ...uniqueSuppliers.entries.map(
        (entry) => AppDropdownItem<int?>(value: entry.key, label: entry.value),
      ),
    ];
  }

  void _clearFilters() {
    controller.searchController.clear();
    controller.dateFromController.clear();
    controller.dateToController.clear();
    controller.setCustomFilter('supplier_id', null);
    controller.setStatus('');
  }

  Widget _actionField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppUiConstants.spacingXs),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _clearFilters,
            icon: const Icon(Icons.clear_outlined),
            label: const Text('Clear'),
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppUiConstants.buttonRadius,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _searchField() {
    return AppFormTextField(
      labelText: 'Search',
      controller: controller.searchController,
      hintText: 'Bill no or supplier name',
    );
  }

  Widget _supplierField() {
    return AppDropdownField<int?>.fromMapped(
      labelText: 'Supplier',
      mappedItems: _supplierItems(),
      initialValue: controller.customFilters['supplier_id'] as int?,
      onChanged: (value) => controller.setCustomFilter('supplier_id', value),
    );
  }

  Widget _statusField() {
    return AppDropdownField<String>.fromMapped(
      labelText: 'Status',
      mappedItems: statusItems,
      initialValue: controller.status,
      onChanged: (value) => controller.setStatus(value ?? ''),
    );
  }

  Widget _dateFromField() {
    return AppFormTextField(
      labelText: 'Date From',
      controller: controller.dateFromController,
      hintText: 'YYYY-MM-DD',
      keyboardType: TextInputType.datetime,
      inputFormatters: const [DateInputFormatter()],
      validator: Validators.optionalDate('Date From'),
    );
  }

  Widget _dateToField() {
    return AppFormTextField(
      labelText: 'Date To',
      controller: controller.dateToController,
      hintText: 'YYYY-MM-DD',
      keyboardType: TextInputType.datetime,
      inputFormatters: const [DateInputFormatter()],
      validator: Validators.optionalDate('Date To'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isWide = width >= 1320;
        final isMedium = width >= 920 && width < 1320;

        if (isWide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _searchField()),
                  const SizedBox(width: AppUiConstants.spacingMd),
                  Expanded(child: _supplierField()),
                  const SizedBox(width: AppUiConstants.spacingMd),
                  Expanded(child: _statusField()),
                  const SizedBox(width: AppUiConstants.spacingMd),
                  Expanded(child: _dateFromField()),
                  const SizedBox(width: AppUiConstants.spacingMd),
                  Expanded(child: _dateToField()),
                  const SizedBox(width: AppUiConstants.spacingMd),
                  SizedBox(width: 160, child: _actionField(context)),
                ],
              ),
            ],
          );
        }

        if (isMedium) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Find Invoices',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppUiConstants.spacingMd),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _searchField()),
                  const SizedBox(width: AppUiConstants.spacingMd),
                  Expanded(child: _supplierField()),
                  const SizedBox(width: AppUiConstants.spacingMd),
                  Expanded(child: _statusField()),
                ],
              ),
              const SizedBox(height: AppUiConstants.spacingMd),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _dateFromField()),
                  const SizedBox(width: AppUiConstants.spacingMd),
                  Expanded(child: _dateToField()),
                  const SizedBox(width: AppUiConstants.spacingMd),
                  Expanded(child: _actionField(context)),
                ],
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Find Invoices',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            SettingsFormWrap(
              maxWidth: double.infinity,
              children: [
                _searchField(),
                _supplierField(),
                _statusField(),
                _dateFromField(),
                _dateToField(),
                _actionField(context),
              ],
            ),
          ],
        );
      },
    );
  }
}
