import 'dart:async';

import '../../model/sales/sales_delivery_model.dart';
import '../../model/sales/sales_invoice_line_model.dart';
import '../../model/sales/sales_order_model.dart';
import '../../screen.dart';
import '../purchase/purchase_support.dart';
import 'sales_support.dart';

class SalesInvoicePage extends StatefulWidget {
  const SalesInvoicePage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
    this.initialQuotationId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;
  /// Prefills a **standalone** invoice from a quotation (API has no `sales_quotation_id` on invoices).
  final int? initialQuotationId;

  @override
  State<SalesInvoicePage> createState() => _SalesInvoicePageState();
}

class _SalesInvoicePageState extends State<SalesInvoicePage> {
  static const List<AppDropdownItem<String>> _listStatusFilter =
      <AppDropdownItem<String>>[
    AppDropdownItem(value: '', label: 'All'),
    AppDropdownItem(value: 'draft', label: 'Draft'),
    AppDropdownItem(value: 'posted', label: 'Posted'),
    AppDropdownItem(value: 'partially_paid', label: 'Partially paid'),
    AppDropdownItem(value: 'paid', label: 'Paid'),
    AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
  ];

  final SalesService _salesService = SalesService();
  final MasterService _masterService = MasterService();
  final PartiesService _partiesService = PartiesService();
  final AccountsService _accountsService = AccountsService();
  final InventoryService _inventoryService = InventoryService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _invoiceNoController = TextEditingController();
  final TextEditingController _invoiceDateController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  final TextEditingController _customerRefNoController =
      TextEditingController();
  final TextEditingController _customerRefDateController =
      TextEditingController();
  final TextEditingController _currencyCodeController = TextEditingController();
  final TextEditingController _exchangeRateController = TextEditingController();
  final TextEditingController _adjustmentAmountController =
      TextEditingController();
  final TextEditingController _adjustmentRemarksController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _termsController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  String _statusFilter = '';
  List<SalesInvoiceModel> _items = const <SalesInvoiceModel>[];
  List<SalesInvoiceModel> _filteredItems = const <SalesInvoiceModel>[];
  List<CompanyModel> _companies = const <CompanyModel>[];
  List<BranchModel> _branches = const <BranchModel>[];
  List<BusinessLocationModel> _locations = const <BusinessLocationModel>[];
  List<FinancialYearModel> _financialYears = const <FinancialYearModel>[];
  List<DocumentSeriesModel> _documentSeries = const <DocumentSeriesModel>[];
  List<PartyModel> _customers = const <PartyModel>[];
  List<AccountModel> _accounts = const <AccountModel>[];
  List<ItemModel> _itemsLookup = const <ItemModel>[];
  List<UomModel> _uoms = const <UomModel>[];
  List<UomConversionModel> _uomConversions = const <UomConversionModel>[];
  List<WarehouseModel> _warehouses = const <WarehouseModel>[];
  List<TaxCodeModel> _taxCodes = const <TaxCodeModel>[];
  List<SalesOrderModel> _ordersAll = const <SalesOrderModel>[];
  List<SalesDeliveryModel> _deliveriesAll = const <SalesDeliveryModel>[];
  List<Map<String, dynamic>>? _orderLinesCache;
  List<Map<String, dynamic>>? _deliveryLinesCache;
  int? _salesOrderId;
  int? _salesDeliveryId;
  SalesInvoiceModel? _selectedItem;
  int? _contextCompanyId;
  int? _contextBranchId;
  int? _contextLocationId;
  int? _contextFinancialYearId;
  int? _companyId;
  int? _branchId;
  int? _locationId;
  int? _financialYearId;
  int? _documentSeriesId;
  int? _customerPartyId;
  int? _adjustmentAccountId;
  bool _isActive = true;
  List<_InvoiceLineDraft> _lines = <_InvoiceLineDraft>[];

  String _errorMessage(Object error) {
    if (error is ApiException) {
      return error.displayMessage;
    }
    if (error is ApiResponse) {
      return error.message;
    }
    return error.toString();
  }

  bool get _canEdit {
    if (_selectedItem == null) {
      return true;
    }
    return _selectedItem!.invoiceStatus == 'draft';
  }

  String get _status =>
      _selectedItem?.invoiceStatus ?? 'draft';

  List<BranchModel> get _branchOptions =>
      branchesForCompany(_branches, _companyId);
  List<BusinessLocationModel> get _locationOptions =>
      locationsForBranch(_locations, _branchId);

  List<DocumentSeriesModel> _seriesOptions() {
    return _documentSeries
        .where((item) {
          final typeOk =
              item.documentType == null ||
              item.documentType == 'SALES_INVOICE';
          final companyOk = _companyId == null || item.companyId == _companyId;
          final fyOk =
              _financialYearId == null ||
              item.financialYearId == _financialYearId;
          return typeOk && companyOk && fyOk;
        })
        .toList(growable: false);
  }

  List<AccountModel> get _accountOptions {
    final companyId = _companyId;
    if (companyId == null) {
      return _accounts;
    }
    return _accounts
        .where((a) => a.companyId == null || a.companyId == companyId)
        .toList(growable: false);
  }

  Map<String, dynamic> _rowJson(SalesInvoiceModel row) =>
      row.raw ?? <String, dynamic>{};

  List<SalesOrderModel> get _orderChoices {
    final companyId = _companyId;
    final cust = _customerPartyId;
    return _ordersAll.where((o) {
      final j = o.toJson();
      if (companyId != null && intValue(j, 'company_id') != companyId) {
        return false;
      }
      if (cust != null && intValue(j, 'customer_party_id') != cust) {
        return false;
      }
      final st = stringValue(j, 'order_status');
      return const {
        'confirmed',
        'partially_delivered',
        'fully_delivered',
        'partially_invoiced',
      }.contains(st);
    }).toList(growable: false);
  }

  List<SalesDeliveryModel> get _deliveryChoices {
    final companyId = _companyId;
    final cust = _customerPartyId;
    final orderId = _salesOrderId;
    return _deliveriesAll.where((d) {
      final j = d.toJson();
      if (companyId != null && intValue(j, 'company_id') != companyId) {
        return false;
      }
      if (cust != null && intValue(j, 'customer_party_id') != cust) {
        return false;
      }
      final st = stringValue(j, 'delivery_status');
      if (!const {'posted', 'partially_invoiced'}.contains(st)) {
        return false;
      }
      if (orderId != null) {
        final dSo = intValue(j, 'sales_order_id');
        if (dSo != null && dSo != 0 && dSo != orderId) {
          return false;
        }
      }
      return true;
    }).toList(growable: false);
  }

  Map<String, dynamic>? _deliveryJsonById(int? id) {
    if (id == null) {
      return null;
    }
    for (final d in _deliveriesAll) {
      final j = d.toJson();
      if (intValue(j, 'id') == id) {
        return j;
      }
    }
    return null;
  }

  String _orderLinePickerLabel(Map<String, dynamic> line) {
    final itemId = intValue(line, 'item_id');
    final item = _itemsLookup.cast<ItemModel?>().firstWhere(
      (i) => i?.id == itemId,
      orElse: () => null,
    );
    final ordered =
        double.tryParse(line['ordered_qty']?.toString() ?? '') ?? 0;
    final invoiced =
        double.tryParse(line['invoiced_qty']?.toString() ?? '') ?? 0;
    final rem = ordered - invoiced;
    final lineNo = intValue(line, 'line_no') ?? 0;
    final name = (item?.itemName ?? '').trim().isNotEmpty
        ? item!.itemName
        : 'Item $itemId';
    return 'L$lineNo · $name · rem $rem';
  }

  String _deliveryLinePickerLabel(Map<String, dynamic> line) {
    final itemId = intValue(line, 'item_id');
    final item = _itemsLookup.cast<ItemModel?>().firstWhere(
      (i) => i?.id == itemId,
      orElse: () => null,
    );
    final pend =
        double.tryParse(line['pending_invoice_qty']?.toString() ?? '') ?? 0;
    final lineNo = intValue(line, 'line_no') ?? 0;
    final name = (item?.itemName ?? '').trim().isNotEmpty
        ? item!.itemName
        : 'Item $itemId';
    return 'L$lineNo · $name · pending $pend';
  }

  Future<void> _reloadSourceDocumentsForCompany(int? companyId) async {
    if (companyId == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _ordersAll = const <SalesOrderModel>[];
        _deliveriesAll = const <SalesDeliveryModel>[];
      });
      return;
    }
    try {
      final src = await Future.wait<dynamic>([
        _salesService.ordersAll(filters: <String, dynamic>{
          'company_id': companyId,
          'is_active': 1,
          'sort_by': 'order_date',
        }),
        _salesService.deliveriesAll(filters: <String, dynamic>{
          'company_id': companyId,
          'is_active': 1,
          'sort_by': 'delivery_date',
        }),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _ordersAll = (src[0] as ApiResponse<List<SalesOrderModel>>).data ??
            const <SalesOrderModel>[];
        _deliveriesAll =
            (src[1] as ApiResponse<List<SalesDeliveryModel>>).data ??
                const <SalesDeliveryModel>[];
      });
    } catch (_) {}
  }

  Future<void> _fetchOrderLines(int orderId) async {
    try {
      final r = await _salesService.order(orderId);
      final j = r.data?.toJson() ?? <String, dynamic>{};
      final rawLines = j['lines'] as List<dynamic>?;
      final list = rawLines
          ?.whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (!mounted) {
        return;
      }
      setState(() => _orderLinesCache = list);
    } catch (_) {
      if (mounted) {
        setState(() => _orderLinesCache = const <Map<String, dynamic>>[]);
      }
    }
  }

  Future<void> _fetchDeliveryLines(int deliveryId) async {
    try {
      final r = await _salesService.delivery(deliveryId);
      final j = r.data?.toJson() ?? <String, dynamic>{};
      final rawLines = j['lines'] as List<dynamic>?;
      final list = rawLines
          ?.whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (!mounted) {
        return;
      }
      setState(() => _deliveryLinesCache = list);
    } catch (_) {
      if (mounted) {
        setState(
          () => _deliveryLinesCache = const <Map<String, dynamic>>[],
        );
      }
    }
  }

  Future<void> _hydrateSourceCaches() async {
    if (_salesOrderId != null) {
      await _fetchOrderLines(_salesOrderId!);
    } else if (mounted) {
      setState(() => _orderLinesCache = null);
    }
    if (_salesDeliveryId != null) {
      await _fetchDeliveryLines(_salesDeliveryId!);
    } else if (mounted) {
      setState(() => _deliveryLinesCache = null);
    }
  }

  void _pruneSourcesForCustomer() {
    final cust = _customerPartyId;
    if (_salesOrderId != null) {
      final ok = _ordersAll.any((o) {
        final j = o.toJson();
        return intValue(j, 'id') == _salesOrderId &&
            (cust == null || intValue(j, 'customer_party_id') == cust);
      });
      if (!ok) {
        _salesOrderId = null;
        _orderLinesCache = null;
        for (final line in _lines) {
          line.salesOrderLineId = null;
        }
      }
    }
    if (_salesDeliveryId != null) {
      final ok = _deliveriesAll.any((d) {
        final j = d.toJson();
        return intValue(j, 'id') == _salesDeliveryId &&
            (cust == null || intValue(j, 'customer_party_id') == cust);
      });
      if (!ok) {
        _salesDeliveryId = null;
        _deliveryLinesCache = null;
        for (final line in _lines) {
          line.salesDeliveryLineId = null;
        }
      }
    }
  }

  Future<void> _onHeaderSalesOrderChanged(int? value) async {
    if (!_canEdit) {
      return;
    }
    setState(() {
      _salesOrderId = value;
      _orderLinesCache = value == null ? null : const <Map<String, dynamic>>[];
      for (final line in _lines) {
        line.salesOrderLineId = null;
        line.salesDeliveryLineId = null;
      }
      if (_salesDeliveryId != null && value != null) {
        final dj = _deliveryJsonById(_salesDeliveryId);
        final dSo = intValue(dj ?? <String, dynamic>{}, 'sales_order_id');
        if (dSo != null && dSo != 0 && dSo != value) {
          _salesDeliveryId = null;
          _deliveryLinesCache = null;
        }
      }
    });
    if (value != null) {
      await _fetchOrderLines(value);
    } else if (mounted) {
      setState(() => _orderLinesCache = null);
    }
  }

  Future<void> _onHeaderSalesDeliveryChanged(int? value) async {
    if (!_canEdit) {
      return;
    }
    setState(() {
      _salesDeliveryId = value;
      _deliveryLinesCache =
          value == null ? null : const <Map<String, dynamic>>[];
      for (final line in _lines) {
        line.salesDeliveryLineId = null;
      }
    });
    if (value != null) {
      final dj = _deliveryJsonById(value);
      final dOrd = intValue(dj ?? <String, dynamic>{}, 'sales_order_id');
      if (dOrd != null && dOrd != 0 && _salesOrderId == null) {
        setState(() => _salesOrderId = dOrd);
        await _fetchOrderLines(dOrd);
      }
      await _fetchDeliveryLines(value);
    } else if (mounted) {
      setState(() => _deliveryLinesCache = null);
    }
  }

  void _applyOrderLinePick(_InvoiceLineDraft line, int? orderLineId) {
    setState(() {
      line.salesOrderLineId = orderLineId;
      line.salesDeliveryLineId = null;
      if (orderLineId == null) {
        return;
      }
      Map<String, dynamic>? ol;
      for (final m in _orderLinesCache ?? const <Map<String, dynamic>>[]) {
        if (intValue(m, 'id') == orderLineId) {
          ol = m;
          break;
        }
      }
      if (ol == null) {
        return;
      }
      line.itemId = intValue(ol, 'item_id');
      line.uomId = intValue(ol, 'uom_id');
      line.warehouseId = intValue(ol, 'warehouse_id');
      line.rateController.text = stringValue(ol, 'rate');
      final ordered =
          double.tryParse(ol['ordered_qty']?.toString() ?? '') ?? 0;
      final invoiced =
          double.tryParse(ol['invoiced_qty']?.toString() ?? '') ?? 0;
      final rem = ordered - invoiced;
      if (rem > 0) {
        line.qtyController.text = rem.toString();
      }
    });
  }

  void _applyDeliveryLinePick(_InvoiceLineDraft line, int? deliveryLineId) {
    setState(() {
      line.salesDeliveryLineId = deliveryLineId;
      if (deliveryLineId == null) {
        return;
      }
      Map<String, dynamic>? dl;
      for (final m in _deliveryLinesCache ?? const <Map<String, dynamic>>[]) {
        if (intValue(m, 'id') == deliveryLineId) {
          dl = m;
          break;
        }
      }
      if (dl == null) {
        return;
      }
      final sol = intValue(dl, 'sales_order_line_id');
      line.salesOrderLineId = sol == 0 ? null : sol;
      line.itemId = intValue(dl, 'item_id');
      line.uomId = intValue(dl, 'uom_id');
      line.warehouseId = intValue(dl, 'warehouse_id');
      line.rateController.text = stringValue(dl, 'rate');
      final pend =
          double.tryParse(dl['pending_invoice_qty']?.toString() ?? '') ?? 0;
      if (pend > 0) {
        line.qtyController.text = pend.toString();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilters);
    _loadPage(selectId: widget.initialId);
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _workspaceController.dispose();
    _searchController.dispose();
    _invoiceNoController.dispose();
    _invoiceDateController.dispose();
    _dueDateController.dispose();
    _customerRefNoController.dispose();
    _customerRefDateController.dispose();
    _currencyCodeController.dispose();
    _exchangeRateController.dispose();
    _adjustmentAmountController.dispose();
    _adjustmentRemarksController.dispose();
    _notesController.dispose();
    _termsController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPage({int? selectId}) async {
    setState(() {
      _initialLoading = _items.isEmpty;
      _pageError = null;
    });

    try {
      final responses = await Future.wait<dynamic>([
        _salesService.invoices(
          filters: const {'per_page': 200, 'sort_by': 'invoice_date'},
        ),
        _masterService.companies(
          filters: const {'per_page': 100, 'sort_by': 'legal_name'},
        ),
        _masterService.branches(
          filters: const {'per_page': 200, 'sort_by': 'name'},
        ),
        _masterService.businessLocations(
          filters: const {'per_page': 200, 'sort_by': 'name'},
        ),
        _masterService.financialYears(
          filters: const {'per_page': 100, 'sort_by': 'fy_name'},
        ),
        _masterService.documentSeries(
          filters: const {'per_page': 200, 'sort_by': 'series_name'},
        ),
        _partiesService.partyTypes(filters: const {'per_page': 100}),
        _partiesService.parties(
          filters: const {'per_page': 400, 'sort_by': 'party_name'},
        ),
        _accountsService.accountsAll(
          filters: const {'sort_by': 'account_name'},
        ),
        _inventoryService.items(
          filters: const {'per_page': 400, 'sort_by': 'item_name'},
        ),
        _inventoryService.uoms(
          filters: const {'per_page': 200, 'sort_by': 'name'},
        ),
        _inventoryService.uomConversionsAll(
          filters: const {'per_page': 500, 'sort_by': 'from_uom_id'},
        ),
        _masterService.warehouses(
          filters: const {'per_page': 200, 'sort_by': 'name'},
        ),
        _inventoryService.taxCodes(
          filters: const {'per_page': 200, 'sort_by': 'name'},
        ),
      ]);

      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies:
                ((responses[1] as PaginatedResponse<CompanyModel>).data ??
                        const <CompanyModel>[])
                    .where((item) => item.isActive)
                    .toList(growable: false),
            branches:
                ((responses[2] as PaginatedResponse<BranchModel>).data ??
                        const <BranchModel>[])
                    .where((item) => item.isActive)
                    .toList(growable: false),
            locations:
                ((responses[3] as PaginatedResponse<BusinessLocationModel>)
                            .data ??
                        const <BusinessLocationModel>[])
                    .where((item) => item.isActive)
                    .toList(growable: false),
            financialYears:
                ((responses[4] as PaginatedResponse<FinancialYearModel>).data ??
                        const <FinancialYearModel>[])
                    .where((item) => item.isActive)
                    .toList(growable: false),
          );

      if (!mounted) {
        return;
      }

      List<SalesOrderModel> ordersAll = const <SalesOrderModel>[];
      List<SalesDeliveryModel> deliveriesAll = const <SalesDeliveryModel>[];
      final sourceCompanyId = contextSelection.companyId;
      if (sourceCompanyId != null) {
        try {
          final src = await Future.wait<dynamic>([
            _salesService.ordersAll(filters: <String, dynamic>{
              'company_id': sourceCompanyId,
              'is_active': 1,
              'sort_by': 'order_date',
            }),
            _salesService.deliveriesAll(filters: <String, dynamic>{
              'company_id': sourceCompanyId,
              'is_active': 1,
              'sort_by': 'delivery_date',
            }),
          ]);
          ordersAll = (src[0] as ApiResponse<List<SalesOrderModel>>).data ??
              const <SalesOrderModel>[];
          deliveriesAll =
              (src[1] as ApiResponse<List<SalesDeliveryModel>>).data ??
                  const <SalesDeliveryModel>[];
        } catch (_) {}
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _items =
            (responses[0] as PaginatedResponse<SalesInvoiceModel>).data ??
            const <SalesInvoiceModel>[];
        _companies =
            (responses[1] as PaginatedResponse<CompanyModel>).data ??
            const <CompanyModel>[];
        _branches =
            (responses[2] as PaginatedResponse<BranchModel>).data ??
            const <BranchModel>[];
        _locations =
            (responses[3] as PaginatedResponse<BusinessLocationModel>).data ??
            const <BusinessLocationModel>[];
        _financialYears =
            (responses[4] as PaginatedResponse<FinancialYearModel>).data ??
            const <FinancialYearModel>[];
        _documentSeries =
            ((responses[5] as PaginatedResponse<DocumentSeriesModel>).data ??
                    const <DocumentSeriesModel>[])
                .where((item) => item.isActive)
                .toList();
        _customers = salesCustomersOrFallback(
          parties:
              ((responses[7] as PaginatedResponse<PartyModel>).data ??
              const <PartyModel>[]),
          partyTypes:
              (responses[6] as PaginatedResponse<PartyTypeModel>).data ??
              const <PartyTypeModel>[],
        );
        _accounts =
            ((responses[8] as ApiResponse<List<AccountModel>>).data ??
                    const <AccountModel>[])
                .where((item) => item.isActive)
                .toList();
        _itemsLookup =
            ((responses[9] as PaginatedResponse<ItemModel>).data ??
                    const <ItemModel>[])
                .where((item) => item.isActive)
                .toList();
        _uoms =
            ((responses[10] as PaginatedResponse<UomModel>).data ??
                    const <UomModel>[])
                .where((item) => item.isActive)
                .toList();
        _uomConversions =
            ((responses[11] as PaginatedResponse<UomConversionModel>).data ??
                    const <UomConversionModel>[])
                .where((item) => item.isActive)
                .toList();
        _warehouses =
            ((responses[12] as PaginatedResponse<WarehouseModel>).data ??
                    const <WarehouseModel>[])
                .where((item) => item.isActive)
                .toList();
        _taxCodes =
            ((responses[13] as PaginatedResponse<TaxCodeModel>).data ??
                    const <TaxCodeModel>[])
                .where((item) => item.isActive)
                .toList();
        _contextCompanyId = contextSelection.companyId;
        _contextBranchId = contextSelection.branchId;
        _contextLocationId = contextSelection.locationId;
        _contextFinancialYearId = contextSelection.financialYearId;
        _ordersAll = ordersAll;
        _deliveriesAll = deliveriesAll;
        _initialLoading = false;
      });
      _applyFilters();

      final selected = selectId != null
          ? _items.cast<SalesInvoiceModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (widget.editorOnly
                ? null
                : (_selectedItem == null
                      ? (_items.isNotEmpty ? _items.first : null)
                      : null));

      if (selected != null) {
        await _selectDocument(selected);
      } else {
        _resetForm();
        final qPref = widget.initialQuotationId;
        if (qPref != null && widget.editorOnly) {
          await _prefillNewInvoiceFromQuotation(qPref);
        }
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _pageError = _errorMessage(error);
        _initialLoading = false;
      });
    }
  }

  Future<void> _prefillNewInvoiceFromQuotation(int quotationId) async {
    try {
      final r = await _salesService.quotation(quotationId);
      final q = r.data;
      if (q == null || !mounted) {
        return;
      }
      final data = q.toJson();
      final lines = (data['lines'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(_InvoiceLineDraft.fromQuotationLine)
          .toList(growable: true);
      for (final old in _lines) {
        old.dispose();
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _companyId = intValue(data, 'company_id');
        _branchId = intValue(data, 'branch_id');
        _locationId = intValue(data, 'location_id');
        _financialYearId = intValue(data, 'financial_year_id');
        final series = _seriesOptions();
        _documentSeriesId =
            series.isNotEmpty ? series.first.id : intValue(data, 'document_series_id');
        _customerPartyId = intValue(data, 'customer_party_id');
        _salesOrderId = null;
        _salesDeliveryId = null;
        _orderLinesCache = null;
        _deliveryLinesCache = null;
        _invoiceNoController.clear();
        _invoiceDateController.text =
            DateTime.now().toIso8601String().split('T').first;
        _dueDateController.text = displayDate(
          nullableStringValue(data, 'valid_until'),
        );
        _customerRefNoController.text =
            stringValue(data, 'customer_reference_no');
        _customerRefDateController.text = displayDate(
          nullableStringValue(data, 'customer_reference_date'),
        );
        _currencyCodeController.text =
            stringValue(data, 'currency_code', 'INR');
        _exchangeRateController.text =
            stringValue(data, 'exchange_rate', '1');
        _adjustmentAmountController.clear();
        _adjustmentRemarksController.clear();
        _adjustmentAccountId = null;
        _notesController.text = stringValue(data, 'notes');
        _termsController.text = stringValue(data, 'terms_conditions');
        _isActive = true;
        _lines = lines.isEmpty ? <_InvoiceLineDraft>[_InvoiceLineDraft()] : lines;
        _formError = null;
      });
      await _reloadSourceDocumentsForCompany(_companyId);
    } catch (e) {
      if (mounted) {
        setState(() => _formError = e.toString());
      }
    }
  }

  Future<void> _selectDocument(SalesInvoiceModel item) async {
    final id = item.id;
    if (id == 0) {
      return;
    }
    final response = await _salesService.invoice(id);
    final full = response.data ?? item;
    final lines = full.lines
        .map(_InvoiceLineDraft.fromLine)
        .toList(growable: true);
    for (final old in _lines) {
      old.dispose();
    }
    setState(() {
      _selectedItem = full;
      _companyId = full.companyId;
      _branchId = full.branchId;
      _locationId = full.locationId;
      _financialYearId = full.financialYearId;
      _documentSeriesId = full.documentSeriesId;
      _customerPartyId = full.customerPartyId;
      _salesOrderId = full.salesOrderId;
      _salesDeliveryId = full.salesDeliveryId;
      _orderLinesCache = null;
      _deliveryLinesCache = null;
      _invoiceNoController.text = full.invoiceNo ?? '';
      _invoiceDateController.text = displayDate(
        full.invoiceDate.isEmpty ? null : full.invoiceDate,
      );
      _dueDateController.text = displayDate(full.dueDate);
      _customerRefNoController.text = full.customerReferenceNo ?? '';
      _customerRefDateController.text = displayDate(full.customerReferenceDate);
      _currencyCodeController.text = full.currencyCode ?? 'INR';
      _exchangeRateController.text =
          (full.exchangeRate ?? 1).toString();
      _adjustmentAmountController.text =
          full.adjustmentAmount == null || full.adjustmentAmount == 0
          ? ''
          : full.adjustmentAmount.toString();
      _adjustmentRemarksController.text = full.adjustmentRemarks ?? '';
      _adjustmentAccountId = full.adjustmentAccountId;
      _notesController.text = full.notes ?? '';
      _termsController.text = full.termsConditions ?? '';
      _isActive = full.isActive ?? true;
      _lines = lines.isEmpty ? <_InvoiceLineDraft>[_InvoiceLineDraft()] : lines;
      _formError = null;
    });
    await _hydrateSourceCaches();
    if (!mounted) {
      return;
    }
    await _reloadSourceDocumentsForCompany(_companyId);
  }

  void _resetForm() {
    for (final line in _lines) {
      line.dispose();
    }
    final series = _seriesOptions();
    setState(() {
      _selectedItem = null;
      _companyId = _contextCompanyId;
      _branchId = _contextBranchId;
      _locationId = _contextLocationId;
      _financialYearId = _contextFinancialYearId;
      _documentSeriesId = series.isNotEmpty ? series.first.id : null;
      _customerPartyId = null;
      _salesOrderId = null;
      _salesDeliveryId = null;
      _orderLinesCache = null;
      _deliveryLinesCache = null;
      _invoiceNoController.clear();
      _invoiceDateController.text = DateTime.now()
          .toIso8601String()
          .split('T')
          .first;
      _dueDateController.clear();
      _customerRefNoController.clear();
      _customerRefDateController.clear();
      _currencyCodeController.text = 'INR';
      _exchangeRateController.text = '1';
      _adjustmentAmountController.clear();
      _adjustmentRemarksController.clear();
      _adjustmentAccountId = null;
      _notesController.clear();
      _termsController.clear();
      _isActive = true;
      _lines = <_InvoiceLineDraft>[_InvoiceLineDraft()];
      _formError = null;
    });
  }

  void _applyFilters() {
    final search = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredItems = _items
          .where((item) {
            final data = _rowJson(item);
            final status = item.invoiceStatus ?? '';
            final statusOk =
                _statusFilter.isEmpty || status == _statusFilter;
            final cust = quotationCustomerLabel(data);
            final searchOk =
                search.isEmpty ||
                [
                  item.invoiceNo ?? '',
                  status,
                  cust,
                ].join(' ').toLowerCase().contains(search);
            return statusOk && searchOk;
          })
          .toList(growable: false);
    });
  }

  List<UomModel> _uomOptionsForItem(int? itemId) {
    final item = _itemsLookup.cast<ItemModel?>().firstWhere(
      (entry) => entry?.id == itemId,
      orElse: () => null,
    );
    return allowedUomsForItem(item, _uoms, _uomConversions);
  }

  int? _resolveDefaultUom(int? itemId, int? currentUomId) {
    final item = _itemsLookup.cast<ItemModel?>().firstWhere(
      (entry) => entry?.id == itemId,
      orElse: () => null,
    );
    return defaultSalesUomIdForItem(
      item,
      _uoms,
      _uomConversions,
      current: currentUomId,
    );
  }

  void _addLine() {
    setState(() {
      _lines = List<_InvoiceLineDraft>.from(_lines)..add(_InvoiceLineDraft());
    });
  }

  void _removeLine(int index) {
    setState(() {
      final next = List<_InvoiceLineDraft>.from(_lines);
      next.removeAt(index).dispose();
      _lines = next.isEmpty ? <_InvoiceLineDraft>[_InvoiceLineDraft()] : next;
    });
  }

  List<SalesInvoiceLineModel> _linesForSave() {
    return _lines
        .map((line) {
          final qty = double.tryParse(line.qtyController.text.trim()) ?? 0;
          final rate = double.tryParse(line.rateController.text.trim()) ?? 0;
          final disc =
              double.tryParse(line.discountController.text.trim()) ?? 0;
          return SalesInvoiceLineModel(
            salesOrderLineId: line.salesOrderLineId,
            salesDeliveryLineId: line.salesDeliveryLineId,
            itemId: line.itemId ?? 0,
            uomId: line.uomId ?? 0,
            invoicedQty: qty,
            rate: rate,
            warehouseId: line.warehouseId,
            taxCodeId: line.taxCodeId,
            description: nullIfEmpty(line.descriptionController.text),
            discountPercent: disc == 0 ? null : disc,
            remarks: nullIfEmpty(line.remarksController.text),
          );
        })
        .toList(growable: false);
  }

  Future<void> _save() async {
    if (!_canEdit) {
      setState(() {
        _formError = 'Only draft invoices can be updated.';
      });
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_lines.any(
      (line) =>
          line.itemId == null ||
          line.uomId == null ||
          (double.tryParse(line.qtyController.text.trim()) ?? 0) <= 0,
    )) {
      setState(
        () => _formError = 'Each line needs item, UOM, and quantity.',
      );
      return;
    }

    final adjAmt =
        double.tryParse(_adjustmentAmountController.text.trim()) ?? 0;
    if (adjAmt != 0 && _adjustmentAccountId == null) {
      setState(
        () => _formError =
            'Choose an adjustment account when adjustment amount is not zero.',
      );
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    final invoice = SalesInvoiceModel(
      id: _selectedItem?.id ?? 0,
      companyId: _companyId ?? 0,
      branchId: _branchId ?? 0,
      locationId: _locationId ?? 0,
      financialYearId: _financialYearId ?? 0,
      customerPartyId: _customerPartyId ?? 0,
      invoiceDate: _invoiceDateController.text.trim(),
      documentSeriesId: _documentSeriesId,
      salesOrderId: _salesOrderId,
      salesDeliveryId: _salesDeliveryId,
      invoiceNo: nullIfEmpty(_invoiceNoController.text),
      dueDate: nullIfEmpty(_dueDateController.text),
      currencyCode: nullIfEmpty(_currencyCodeController.text) ?? 'INR',
      exchangeRate:
          double.tryParse(_exchangeRateController.text.trim()) ?? 1,
      notes: nullIfEmpty(_notesController.text),
      termsConditions: nullIfEmpty(_termsController.text),
      customerReferenceNo: nullIfEmpty(_customerRefNoController.text),
      customerReferenceDate: nullIfEmpty(_customerRefDateController.text),
      isActive: _isActive,
      adjustmentAmount: adjAmt == 0 ? null : adjAmt,
      adjustmentAccountId: adjAmt == 0 ? null : _adjustmentAccountId,
      adjustmentRemarks: nullIfEmpty(_adjustmentRemarksController.text),
      lines: _linesForSave(),
    );

    try {
      final response = _selectedItem == null
          ? await _salesService.createInvoice(invoice)
          : await _salesService.updateInvoice(_selectedItem!.id, invoice);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadPage(selectId: response.data?.id);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _formError = _errorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _docAction(
    Future<ApiResponse<SalesInvoiceModel>> Function() action,
  ) async {
    try {
      final response = await action();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadPage(selectId: response.data?.id);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _formError = _errorMessage(error));
    }
  }

  Future<void> _delete() async {
    final id = _selectedItem?.id;
    if (id == null || id == 0) {
      return;
    }
    try {
      final response = await _salesService.deleteInvoice(id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadPage();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _formError = _errorMessage(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      AdaptiveShellActionButton(
        onPressed: () {
          _resetForm();
          if (!Responsive.isDesktop(context)) {
            _workspaceController.openEditor();
          }
        },
        icon: Icons.add_outlined,
        label: 'New invoice',
      ),
    ];
    final content = _buildContent();
    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }
    return AppStandaloneShell(
      title: 'Sales Invoices',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading invoices...');
    }
    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load invoices',
        message: _pageError!,
        onRetry: _loadPage,
      );
    }

    final totalStr = _selectedItem?.totalAmount?.toString() ?? '';

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Sales Invoices',
      editorTitle: _selectedItem == null
          ? 'New invoice'
          : (_selectedItem!.invoiceNo?.trim().isNotEmpty == true
                ? _selectedItem!.invoiceNo!
                : 'Invoice #${_selectedItem!.id}'),
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: PurchaseListCard<SalesInvoiceModel>(
        items: _filteredItems,
        selectedItem: _selectedItem,
        emptyMessage: 'No invoices yet.',
        searchController: _searchController,
        searchHint: 'Search by number or customer',
        statusValue: _statusFilter,
        statusItems: _listStatusFilter,
        onStatusChanged: (value) {
          _statusFilter = value ?? '';
          _applyFilters();
        },
        itemBuilder: (item, selected) {
          final data = _rowJson(item);
          return SettingsListTile(
            title: (item.invoiceNo?.trim().isNotEmpty == true)
                ? item.invoiceNo!
                : 'Draft #${item.id}',
            subtitle: [
              displayDate(
                item.invoiceDate.isEmpty ? null : item.invoiceDate,
              ),
              item.invoiceStatus ?? '',
            ].where((value) => value.isNotEmpty).join(' · '),
            detail: quotationCustomerLabel(data),
            selected: selected,
            onTap: () => _selectDocument(item),
          );
        },
      ),
      editor: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_formError != null) ...[
              AppErrorStateView.inline(message: _formError!),
              const SizedBox(height: AppUiConstants.spacingSm),
            ],
            if (_selectedItem != null && totalStr.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
                child: Text(
                  'Total: $totalStr ${_currencyCodeController.text.trim().isEmpty ? 'INR' : _currencyCodeController.text.trim()} · Status: ${_status.toUpperCase()}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            SettingsFormWrap(
              children: [
                AppDropdownField<int>.fromMapped(
                  labelText: 'Company',
                  mappedItems: _companies
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: _companyId,
                  onChanged: (value) {
                    if (!_canEdit) {
                      return;
                    }
                    setState(() {
                      _companyId = value;
                      _branchId = null;
                      _locationId = null;
                      final options = _seriesOptions();
                      _documentSeriesId =
                          options.isNotEmpty ? options.first.id : null;
                      _salesOrderId = null;
                      _salesDeliveryId = null;
                      _orderLinesCache = null;
                      _deliveryLinesCache = null;
                      for (final line in _lines) {
                        line.salesOrderLineId = null;
                        line.salesDeliveryLineId = null;
                      }
                    });
                    unawaited(_reloadSourceDocumentsForCompany(value));
                  },
                  validator: Validators.requiredSelection('Company'),
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Branch',
                  mappedItems: _branchOptions
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: _branchId,
                  onChanged: (value) {
                    if (!_canEdit) {
                      return;
                    }
                    setState(() {
                      _branchId = value;
                      _locationId = null;
                    });
                  },
                  validator: Validators.requiredSelection('Branch'),
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Location',
                  mappedItems: _locationOptions
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: _locationId,
                  onChanged: (value) {
                    if (!_canEdit) {
                      return;
                    }
                    setState(() => _locationId = value);
                  },
                  validator: Validators.requiredSelection('Location'),
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Financial Year',
                  mappedItems: _financialYears
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: _financialYearId,
                  onChanged: (value) {
                    if (!_canEdit) {
                      return;
                    }
                    setState(() {
                      _financialYearId = value;
                      final options = _seriesOptions();
                      _documentSeriesId =
                          options.isNotEmpty ? options.first.id : null;
                    });
                  },
                  validator: Validators.requiredSelection('Financial Year'),
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Document Series',
                  mappedItems: _seriesOptions()
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: _documentSeriesId,
                  onChanged: (value) {
                    if (!_canEdit) {
                      return;
                    }
                    setState(() => _documentSeriesId = value);
                  },
                ),
                AppFormTextField(
                  labelText: 'Invoice No',
                  controller: _invoiceNoController,
                  hintText: 'Leave blank if your series fills this in',
                  enabled: _canEdit,
                  validator: Validators.optionalMaxLength(100, 'Invoice No'),
                ),
                AppFormTextField(
                  labelText: 'Invoice Date',
                  controller: _invoiceDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  enabled: _canEdit,
                  validator: Validators.compose([
                    Validators.required('Invoice Date'),
                    Validators.date('Invoice Date'),
                  ]),
                ),
                AppFormTextField(
                  labelText: 'Due Date',
                  controller: _dueDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  enabled: _canEdit,
                  validator: Validators.optionalDate('Due Date'),
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Customer',
                  mappedItems: _customers
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: _customerPartyId,
                  onChanged: (value) {
                    if (!_canEdit) {
                      return;
                    }
                    setState(() {
                      _customerPartyId = value;
                      _pruneSourcesForCustomer();
                    });
                  },
                  validator: Validators.requiredSelection('Customer'),
                ),
                AppDropdownField<int?>.fromMapped(
                  labelText: 'Sales order (optional)',
                  mappedItems: [
                    const AppDropdownItem<int?>(
                      value: null,
                      label: 'None',
                    ),
                    ..._orderChoices
                        .map((o) => o.toJson())
                        .where((j) => intValue(j, 'id') != null)
                        .map(
                          (j) => AppDropdownItem<int?>(
                            value: intValue(j, 'id'),
                            label: stringValue(j, 'order_no', 'Order'),
                          ),
                        ),
                  ],
                  initialValue: _salesOrderId,
                  onChanged: (value) => unawaited(_onHeaderSalesOrderChanged(value)),
                ),
                AppDropdownField<int?>.fromMapped(
                  labelText: 'Sales delivery (optional)',
                  mappedItems: [
                    const AppDropdownItem<int?>(
                      value: null,
                      label: 'None',
                    ),
                    ..._deliveryChoices
                        .map((d) => d.toJson())
                        .where((j) => intValue(j, 'id') != null)
                        .map(
                          (j) => AppDropdownItem<int?>(
                            value: intValue(j, 'id'),
                            label: stringValue(j, 'delivery_no', 'Delivery'),
                          ),
                        ),
                  ],
                  initialValue: _salesDeliveryId,
                  onChanged: (value) =>
                      unawaited(_onHeaderSalesDeliveryChanged(value)),
                ),
                AppFormTextField(
                  labelText: 'Customer PO / Ref',
                  controller: _customerRefNoController,
                  enabled: _canEdit,
                  validator: Validators.optionalMaxLength(100, 'Reference'),
                ),
                AppFormTextField(
                  labelText: 'Customer Ref Date',
                  controller: _customerRefDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  enabled: _canEdit,
                  validator: Validators.optionalDate('Customer Ref Date'),
                ),
                AppFormTextField(
                  labelText: 'Currency',
                  controller: _currencyCodeController,
                  enabled: _canEdit,
                  validator: Validators.optionalMaxLength(10, 'Currency'),
                ),
                AppFormTextField(
                  labelText: 'Exchange Rate',
                  controller: _exchangeRateController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  enabled: _canEdit,
                  validator: Validators.optionalNonNegativeNumber('Exchange Rate'),
                ),
                AppFormTextField(
                  labelText: 'Adjustment amount',
                  controller: _adjustmentAmountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  enabled: _canEdit,
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) {
                      return null;
                    }
                    if (double.tryParse(trimmed) == null) {
                      return 'Adjustment amount must be a valid number';
                    }
                    return null;
                  },
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Adjustment account',
                  mappedItems: _accountOptions
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: _adjustmentAccountId,
                  onChanged: (value) {
                    if (!_canEdit) {
                      return;
                    }
                    setState(() => _adjustmentAccountId = value);
                  },
                ),
                AppFormTextField(
                  labelText: 'Adjustment remarks',
                  controller: _adjustmentRemarksController,
                  enabled: _canEdit,
                  maxLines: 2,
                ),
                AppFormTextField(
                  labelText: 'Notes (shown to customer)',
                  controller: _notesController,
                  maxLines: 3,
                  enabled: _canEdit,
                ),
                AppFormTextField(
                  labelText: 'Terms & Conditions',
                  controller: _termsController,
                  maxLines: 3,
                  enabled: _canEdit,
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            AppSwitchTile(
              label: 'Active',
              value: _isActive,
              onChanged: _canEdit
                  ? (value) => setState(() => _isActive = value)
                  : null,
            ),
            const SizedBox(height: AppUiConstants.spacingLg),
            Row(
              children: [
                Text(
                  'Line items',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                AppActionButton(
                  icon: Icons.add_outlined,
                  label: 'Add line',
                  onPressed: _canEdit ? _addLine : null,
                  filled: false,
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
            ...List<Widget>.generate(_lines.length, (index) {
              final line = _lines[index];
              return Padding(
                padding: const EdgeInsets.only(
                  bottom: AppUiConstants.spacingSm,
                ),
                child: PurchaseCompactLineCard(
                  index: index,
                  total: _lines.length,
                  removeEnabled: _canEdit && _lines.length > 1,
                  onRemove: _canEdit ? () => _removeLine(index) : null,
                  child: PurchaseCompactFieldGrid(
                    children: [
                      if (_salesOrderId != null &&
                          (_orderLinesCache != null &&
                              _orderLinesCache!.isNotEmpty))
                        AppDropdownField<int?>.fromMapped(
                          labelText: 'Order line',
                          mappedItems: [
                            const AppDropdownItem<int?>(
                              value: null,
                              label: 'None',
                            ),
                            ..._orderLinesCache!.map((ol) {
                              final id = intValue(ol, 'id');
                              return AppDropdownItem<int?>(
                                value: id,
                                label: _orderLinePickerLabel(ol),
                              );
                            }).where((it) => it.value != null),
                          ],
                          initialValue: line.salesOrderLineId,
                          onChanged: (value) {
                            if (!_canEdit) {
                              return;
                            }
                            _applyOrderLinePick(line, value);
                          },
                        ),
                      if (_salesDeliveryId != null &&
                          (_deliveryLinesCache != null &&
                              _deliveryLinesCache!.isNotEmpty))
                        AppDropdownField<int?>.fromMapped(
                          labelText: 'Delivery line',
                          mappedItems: [
                            const AppDropdownItem<int?>(
                              value: null,
                              label: 'None',
                            ),
                            ..._deliveryLinesCache!.map((dl) {
                              final id = intValue(dl, 'id');
                              return AppDropdownItem<int?>(
                                value: id,
                                label: _deliveryLinePickerLabel(dl),
                              );
                            }).where((it) => it.value != null),
                          ],
                          initialValue: line.salesDeliveryLineId,
                          onChanged: (value) {
                            if (!_canEdit) {
                              return;
                            }
                            _applyDeliveryLinePick(line, value);
                          },
                        ),
                      AppSearchPickerField<int>(
                        labelText: 'Item',
                        selectedLabel: _itemsLookup
                            .cast<ItemModel?>()
                            .firstWhere(
                              (item) => item?.id == line.itemId,
                              orElse: () => null,
                            )
                            ?.toString(),
                        options: _itemsLookup
                            .where((item) => item.id != null)
                            .map(
                              (item) => AppSearchPickerOption<int>(
                                value: item.id!,
                                label: item.toString(),
                                subtitle: item.itemCode,
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (!_canEdit) {
                            return;
                          }
                          setState(() {
                            line.itemId = value;
                            line.salesOrderLineId = null;
                            line.salesDeliveryLineId = null;
                            line.uomId = _resolveDefaultUom(
                              value,
                              line.uomId,
                            );
                          });
                        },
                        validator: (_) =>
                            line.itemId == null ? 'Item is required' : null,
                      ),
                      Builder(
                        builder: (context) {
                          final options = _uomOptionsForItem(line.itemId);
                          if (_canEdit && options.length == 1) {
                            final onlyId = options.first.id;
                            if (line.uomId != onlyId) {
                              line.uomId = onlyId;
                            }
                          }
                          return AppDropdownField<int>.fromMapped(
                            labelText: 'UOM',
                            mappedItems: options
                                .where((item) => item.id != null)
                                .map(
                                  (item) => AppDropdownItem(
                                    value: item.id!,
                                    label: item.toString(),
                                  ),
                                )
                                .toList(growable: false),
                            initialValue: line.uomId,
                            onChanged: (value) {
                              if (!_canEdit) {
                                return;
                              }
                              setState(() => line.uomId = value);
                            },
                            validator: (_) {
                              if (line.itemId == null) {
                                return 'Select item first';
                              }
                              return line.uomId == null
                                  ? 'UOM is required'
                                  : null;
                            },
                          );
                        },
                      ),
                      AppDropdownField<int>.fromMapped(
                        labelText: 'Warehouse',
                        mappedItems: _warehouses
                            .where((item) => item.id != null)
                            .map(
                              (item) => AppDropdownItem(
                                value: item.id!,
                                label: item.toString(),
                              ),
                            )
                            .toList(growable: false),
                        initialValue: line.warehouseId,
                        onChanged: (value) {
                          if (!_canEdit) {
                            return;
                          }
                          setState(() => line.warehouseId = value);
                        },
                      ),
                      AppFormTextField(
                        labelText: 'Qty',
                        controller: line.qtyController,
                        enabled: _canEdit,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: Validators.compose([
                          Validators.required('Qty'),
                          Validators.optionalNonNegativeNumber('Qty'),
                        ]),
                      ),
                      AppFormTextField(
                        labelText: 'Rate',
                        controller: line.rateController,
                        enabled: _canEdit,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: Validators.compose([
                          Validators.required('Rate'),
                          Validators.optionalNonNegativeNumber('Rate'),
                        ]),
                      ),
                      AppFormTextField(
                        labelText: 'Discount %',
                        controller: line.discountController,
                        enabled: _canEdit,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: Validators.optionalNonNegativeNumber(
                          'Discount %',
                        ),
                      ),
                      AppDropdownField<int>.fromMapped(
                        labelText: 'Tax code',
                        mappedItems: _taxCodes
                            .where((item) => item.id != null)
                            .map(
                              (item) => AppDropdownItem(
                                value: item.id!,
                                label: item.toString(),
                              ),
                            )
                            .toList(growable: false),
                        initialValue: line.taxCodeId,
                        onChanged: (value) {
                          if (!_canEdit) {
                            return;
                          }
                          setState(() => line.taxCodeId = value);
                        },
                      ),
                      AppFormTextField(
                        labelText: 'Description',
                        controller: line.descriptionController,
                        enabled: _canEdit,
                      ),
                      AppFormTextField(
                        labelText: 'Remarks',
                        controller: line.remarksController,
                        enabled: _canEdit,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: AppUiConstants.spacingMd),
            Wrap(
              spacing: AppUiConstants.spacingSm,
              runSpacing: AppUiConstants.spacingSm,
              children: [
                AppActionButton(
                  icon: Icons.save_outlined,
                  label: _selectedItem == null ? 'Save invoice' : 'Update invoice',
                  onPressed: _canEdit ? _save : null,
                  busy: _saving,
                ),
                if (_selectedItem != null) ...[
                  if (_status == 'draft') ...[
                    AppActionButton(
                      icon: Icons.publish_outlined,
                      label: 'Post',
                      filled: false,
                      onPressed: () => _docAction(
                        () => _salesService.postInvoice(_selectedItem!.id),
                      ),
                    ),
                    AppActionButton(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      filled: false,
                      onPressed: _delete,
                    ),
                    AppActionButton(
                      icon: Icons.block_outlined,
                      label: 'Cancel invoice',
                      filled: false,
                      onPressed: () => _docAction(
                        () => _salesService.cancelInvoice(_selectedItem!.id),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceLineDraft {
  _InvoiceLineDraft({
    this.salesOrderLineId,
    this.salesDeliveryLineId,
    this.itemId,
    this.warehouseId,
    this.uomId,
    this.taxCodeId,
    String? description,
    String? qty,
    String? rate,
    String? discountPercent,
    String? remarks,
  }) : descriptionController = TextEditingController(text: description ?? ''),
       qtyController = TextEditingController(text: qty ?? ''),
       rateController = TextEditingController(text: rate ?? ''),
       discountController = TextEditingController(text: discountPercent ?? ''),
       remarksController = TextEditingController(text: remarks ?? '');

  factory _InvoiceLineDraft.fromLine(SalesInvoiceLineModel line) {
    return _InvoiceLineDraft(
      salesOrderLineId: line.salesOrderLineId,
      salesDeliveryLineId: line.salesDeliveryLineId,
      itemId: line.itemId,
      warehouseId: line.warehouseId,
      uomId: line.uomId,
      taxCodeId: line.taxCodeId,
      description: line.description,
      qty: line.invoicedQty == 0 ? '' : line.invoicedQty.toString(),
      rate: line.rate == 0 ? '' : line.rate.toString(),
      discountPercent: line.discountPercent == null || line.discountPercent == 0
          ? ''
          : line.discountPercent.toString(),
      remarks: line.remarks,
    );
  }

  factory _InvoiceLineDraft.fromQuotationLine(Map<String, dynamic> json) {
    final q = json['qty'];
    return _InvoiceLineDraft(
      itemId: intValue(json, 'item_id'),
      warehouseId: intValue(json, 'warehouse_id'),
      uomId: intValue(json, 'uom_id'),
      taxCodeId: intValue(json, 'tax_code_id'),
      description: stringValue(json, 'description'),
      qty: q?.toString() ?? '',
      rate: stringValue(json, 'rate'),
      discountPercent: stringValue(json, 'discount_percent'),
      remarks: stringValue(json, 'remarks'),
    );
  }

  int? salesOrderLineId;
  int? salesDeliveryLineId;
  int? itemId;
  int? warehouseId;
  int? uomId;
  int? taxCodeId;
  final TextEditingController descriptionController;
  final TextEditingController qtyController;
  final TextEditingController rateController;
  final TextEditingController discountController;
  final TextEditingController remarksController;

  void dispose() {
    descriptionController.dispose();
    qtyController.dispose();
    rateController.dispose();
    discountController.dispose();
    remarksController.dispose();
  }
}
