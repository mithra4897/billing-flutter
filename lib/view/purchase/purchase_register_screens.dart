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
    this.extraActionsBuilder,
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
  final List<Widget> Function(
    BuildContext context,
    PurchaseListRegisterController<T> controller,
  )?
  extraActionsBuilder;

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
          filters: _RegisterFilters(
            searchController: controller.searchController,
            searchHint: widget.searchHint,
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
        return statusOk && searchOk;
      },
      emptyMessage: 'No purchase requisitions found.',
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
        return statusOk && searchOk;
      },
      emptyMessage: 'No purchase orders found.',
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
        return statusOk && searchOk;
      },
      emptyMessage: 'No purchase receipts found.',
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
              purchaseStatusLabel(row.invoiceStatus),
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
        final filterOverdue =
            controller.customFilters['overdue'] as bool? ?? false;

        final supplierOk =
            filterSupplierId == null || row.supplierPartyId == filterSupplierId;

        var overdueOk = true;
        if (filterOverdue) {
          if (row.invoiceStatus == 'draft' ||
              row.invoiceStatus == 'paid' ||
              row.invoiceStatus == 'cancelled') {
            overdueOk = false;
          } else {
            final dueDateStr = row.dueDate;
            if (dueDateStr == null || dueDateStr.isEmpty) {
              overdueOk = false;
            } else {
              final parsed = DateTime.tryParse(dueDateStr);
              if (parsed == null) {
                overdueOk = false;
              } else {
                final today = DateTime.now();
                final normalizedToday = DateTime(
                  today.year,
                  today.month,
                  today.day,
                );
                final normalizedParsed = DateTime(
                  parsed.year,
                  parsed.month,
                  parsed.day,
                );
                overdueOk = normalizedParsed.isBefore(normalizedToday);
              }
            }
          }
        }

        return statusOk && searchOk && supplierOk && overdueOk;
      },
      emptyMessage: 'No purchase invoices found.',
      extraActionsBuilder: (context, controller) {
        final hasFilters =
            controller.customFilters['supplier_id'] != null ||
            (controller.customFilters['overdue'] == true);
        return [
          AdaptiveShellActionButton(
            onPressed: () => _openFilterPanel(context, controller),
            icon: Icons.filter_alt_outlined,
            label: 'Filter',
            filled: hasFilters,
          ),
        ];
      },
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
        ),
      ],
      rowRoute: (row) => '/purchase/invoices/${row.id}',
    );
  }

  Future<void> _openFilterPanel(
    BuildContext context,
    PurchaseListRegisterController<PurchaseInvoiceModel> controller,
  ) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 600
        ? 16.0
        : screenWidth > 800
        ? (screenWidth - 760) / 2
        : 24.0;
    final dialogPadding = screenWidth < 600 ? 16.0 : AppUiConstants.cardPadding;

    final Map<int, String> uniqueSuppliers = {};
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

    final supplierOptions = [
      const AppDropdownItem<int?>(value: null, label: 'All Suppliers'),
      ...uniqueSuppliers.entries.map(
        (e) => AppDropdownItem<int?>(value: e.key, label: e.value),
      ),
    ];

    await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final appTheme = Theme.of(
          dialogContext,
        ).extension<AppThemeExtension>()!;

        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 20,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                dialogPadding,
                dialogPadding,
                dialogPadding,
                MediaQuery.of(dialogContext).viewInsets.bottom + dialogPadding,
              ),
              child:
                  GetBuilder<
                    PurchaseListRegisterController<PurchaseInvoiceModel>
                  >(
                    tag: persistentControllerTag(
                      'PurchaseInvoiceRegisterController',
                    ),
                    builder: (dialogController) => Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Filter Invoices',
                                style: Theme.of(dialogContext)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(false),
                              tooltip: 'Close',
                              icon: const Icon(Icons.close),
                              color: appTheme.mutedText,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SettingsFormWrap(
                          children: [
                            AppDropdownField<int?>.fromMapped(
                              labelText: 'Supplier',
                              mappedItems: supplierOptions,
                              initialValue:
                                  dialogController.customFilters['supplier_id']
                                      as int?,
                              onChanged: (val) => dialogController
                                  .setCustomFilter('supplier_id', val),
                            ),
                            AppSwitchTile(
                              label: 'Overdue Invoices Only',
                              subtitle:
                                  'Show posted/partially paid invoices past their due date',
                              value:
                                  dialogController.customFilters['overdue']
                                      as bool? ??
                                  false,
                              onChanged: (val) => dialogController
                                  .setCustomFilter('overdue', val),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            FilledButton.icon(
                              onPressed: () {
                                Navigator.of(dialogContext).pop(true);
                              },
                              icon: const Icon(Icons.check),
                              label: const Text('Apply Filter'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () {
                                dialogController.setCustomFilter(
                                  'supplier_id',
                                  null,
                                );
                                dialogController.setCustomFilter(
                                  'overdue',
                                  false,
                                );
                                dialogController.searchController.clear();
                                dialogController.setStatus('');
                                Navigator.of(dialogContext).pop(true);
                              },
                              icon: const Icon(Icons.clear),
                              label: const Text('Clear Filters'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
            ),
          ),
        );
      },
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
        return statusOk && searchOk;
      },
      emptyMessage: 'No purchase payments found.',
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
        final data = row.toJson();
        final statusOk =
            status.isEmpty || stringValue(data, 'return_status') == status;
        final searchOk =
            query.isEmpty ||
            [
              stringValue(data, 'return_no'),
              stringValue(data, 'return_reason'),
              purchaseStatusLabel(nullableStringValue(data, 'return_status')),
            ].join(' ').toLowerCase().contains(query);
        return statusOk && searchOk;
      },
      emptyMessage: 'No purchase returns found.',
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
