import 'dart:async';

import '../../model/sales/sales_order_model.dart';
import '../../model/sales/sales_quotation_model.dart';
import '../../screen.dart';
import '../crm/crm_sales_pipeline_bar.dart';
import '../purchase/purchase_support.dart';
import 'sales_support.dart';

class SalesOrderPage extends StatefulWidget {
  const SalesOrderPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
    this.initialQuotationId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;
  final int? initialQuotationId;

  @override
  State<SalesOrderPage> createState() => _SalesOrderPageState();
}

class _SalesOrderPageState extends State<SalesOrderPage> {
  static const List<AppDropdownItem<String>>
  _listStatusFilter = <AppDropdownItem<String>>[
    AppDropdownItem(value: '', label: 'All'),
    AppDropdownItem(value: 'draft', label: 'Draft'),
    AppDropdownItem(value: 'confirmed', label: 'Confirmed'),
    AppDropdownItem(value: 'partially_delivered', label: 'Partially delivered'),
    AppDropdownItem(value: 'fully_delivered', label: 'Fully delivered'),
    AppDropdownItem(value: 'partially_invoiced', label: 'Partially invoiced'),
    AppDropdownItem(value: 'fully_invoiced', label: 'Fully invoiced'),
    AppDropdownItem(value: 'closed', label: 'Closed'),
    AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
  ];

  final SalesService _salesService = SalesService();
  final CrmService _crmService = CrmService();
  final MasterService _masterService = MasterService();
  final PartiesService _partiesService = PartiesService();
  final InventoryService _inventoryService = InventoryService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _orderNoController = TextEditingController();
  final TextEditingController _orderDateController = TextEditingController();
  final TextEditingController _expectedDeliveryController =
      TextEditingController();
  final TextEditingController _customerRefNoController =
      TextEditingController();
  final TextEditingController _customerRefDateController =
      TextEditingController();
  final TextEditingController _currencyCodeController = TextEditingController();
  final TextEditingController _exchangeRateController = TextEditingController();
  final TextEditingController _roundOffController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _termsController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  String _statusFilter = '';
  List<SalesOrderModel> _items = const <SalesOrderModel>[];
  List<SalesOrderModel> _filteredItems = const <SalesOrderModel>[];
  List<SalesQuotationModel> _quotationsAll = const <SalesQuotationModel>[];
  List<CompanyModel> _companies = const <CompanyModel>[];
  List<BranchModel> _branches = const <BranchModel>[];
  List<BusinessLocationModel> _locations = const <BusinessLocationModel>[];
  List<FinancialYearModel> _financialYears = const <FinancialYearModel>[];
  List<DocumentSeriesModel> _documentSeries = const <DocumentSeriesModel>[];
  List<PartyModel> _customers = const <PartyModel>[];
  List<ItemModel> _itemsLookup = const <ItemModel>[];
  List<UomModel> _uoms = const <UomModel>[];
  List<UomConversionModel> _uomConversions = const <UomConversionModel>[];
  List<WarehouseModel> _warehouses = const <WarehouseModel>[];
  List<TaxCodeModel> _taxCodes = const <TaxCodeModel>[];
  SalesOrderModel? _selectedItem;
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
  int? _salesQuotationId;
  List<Map<String, dynamic>>? _quotationLinesCache;
  Map<String, dynamic>? _salesChain;
  bool _isActive = true;
  List<_OrderLineDraft> _lines = <_OrderLineDraft>[];

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
    return stringValue(_selectedItem!.toJson(), 'order_status') == 'draft';
  }

  String get _status =>
      stringValue(_selectedItem?.toJson() ?? const {}, 'order_status', 'draft');

  List<BranchModel> get _branchOptions =>
      branchesForCompany(_branches, _companyId);
  List<BusinessLocationModel> get _locationOptions =>
      locationsForBranch(_locations, _branchId);

  List<SalesQuotationModel> get _quotationChoices {
    final companyId = _companyId;
    final cust = _customerPartyId;
    return _quotationsAll
        .where((q) {
          final j = q.toJson();
          if (companyId != null && intValue(j, 'company_id') != companyId) {
            return false;
          }
          if (cust != null && intValue(j, 'customer_party_id') != cust) {
            return false;
          }
          final st = stringValue(j, 'quotation_status');
          return const {'accepted', 'sent', 'draft'}.contains(st);
        })
        .toList(growable: false);
  }

  String _quotationLinePickerLabel(Map<String, dynamic> line) {
    final itemId = intValue(line, 'item_id');
    final item = _itemsLookup.cast<ItemModel?>().firstWhere(
      (i) => i?.id == itemId,
      orElse: () => null,
    );
    final qQty = double.tryParse(line['qty']?.toString() ?? '') ?? 0;
    final lineNo = intValue(line, 'line_no') ?? 0;
    final name = (item?.itemName ?? '').trim().isNotEmpty
        ? item!.itemName
        : 'Item $itemId';
    return 'L$lineNo · $name · quote qty $qQty';
  }

  Future<void> _fetchQuotationLines(int quotationId) async {
    try {
      final r = await _salesService.quotation(quotationId);
      final data = r.data?.toJson() ?? <String, dynamic>{};
      final rawLines = data['lines'] as List<dynamic>?;
      final list = rawLines
          ?.whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (!mounted) {
        return;
      }
      setState(() => _quotationLinesCache = list);
    } catch (_) {
      if (mounted) {
        setState(() => _quotationLinesCache = const <Map<String, dynamic>>[]);
      }
    }
  }

  Future<void> _onHeaderQuotationChanged(int? value) async {
    if (!_canEdit) {
      return;
    }
    setState(() {
      _salesQuotationId = value;
      _quotationLinesCache = value == null
          ? null
          : const <Map<String, dynamic>>[];
      for (final line in _lines) {
        line.salesQuotationLineId = null;
      }
    });
    if (value != null) {
      await _fetchQuotationLines(value);
    } else if (mounted) {
      setState(() => _quotationLinesCache = null);
    }
    await _refreshSalesChain();
  }

  Future<void> _refreshSalesChain() async {
    final oid = intValue(_selectedItem?.toJson() ?? const {}, 'id');
    final qid = _salesQuotationId;
    try {
      if (oid != null) {
        final r = await _crmService.salesChain(orderId: oid);
        if (!mounted) {
          return;
        }
        setState(() => _salesChain = r.data);
        return;
      }
      if (qid != null) {
        final r = await _crmService.salesChain(quotationId: qid);
        if (!mounted) {
          return;
        }
        setState(() => _salesChain = r.data);
        return;
      }
      if (!mounted) {
        return;
      }
      setState(() => _salesChain = null);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _salesChain = null);
    }
  }

  void _applyQuotationLinePick(_OrderLineDraft line, int? quotationLineId) {
    setState(() {
      line.salesQuotationLineId = quotationLineId;
      if (quotationLineId == null) {
        return;
      }
      Map<String, dynamic>? ql;
      for (final m in _quotationLinesCache ?? const <Map<String, dynamic>>[]) {
        if (intValue(m, 'id') == quotationLineId) {
          ql = m;
          break;
        }
      }
      if (ql == null) {
        return;
      }
      line.itemId = intValue(ql, 'item_id');
      line.uomId = intValue(ql, 'uom_id');
      line.warehouseId = intValue(ql, 'warehouse_id');
      line.rateController.text = stringValue(ql, 'rate');
      final qQty = double.tryParse(ql['qty']?.toString() ?? '') ?? 0;
      if (qQty > 0) {
        line.qtyController.text = qQty.toString();
      }
    });
  }

  List<DocumentSeriesModel> _seriesOptions() {
    return _documentSeries
        .where((item) {
          final typeOk =
              item.documentType == null || item.documentType == 'SALES_ORDER';
          final companyOk = _companyId == null || item.companyId == _companyId;
          final fyOk =
              _financialYearId == null ||
              item.financialYearId == _financialYearId;
          return typeOk && companyOk && fyOk;
        })
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    WorkingContextService.version.addListener(_handleWorkingContextChanged);
    _searchController.addListener(_applyFilters);
    _loadPage(selectId: widget.initialId);
  }

  void _handleWorkingContextChanged() {
    _loadPage(selectId: intValue(_selectedItem?.toJson() ?? const {}, 'id'));
  }

  @override
  void dispose() {
    WorkingContextService.version.removeListener(_handleWorkingContextChanged);
    _pageScrollController.dispose();
    _workspaceController.dispose();
    _searchController.dispose();
    _orderNoController.dispose();
    _orderDateController.dispose();
    _expectedDeliveryController.dispose();
    _customerRefNoController.dispose();
    _customerRefDateController.dispose();
    _currencyCodeController.dispose();
    _exchangeRateController.dispose();
    _roundOffController.dispose();
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
        _salesService.orders(
          filters: const {'per_page': 200, 'sort_by': 'order_date'},
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
        _salesService.quotationsAll(
          filters: const {'sort_by': 'quotation_date'},
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

      setState(() {
        _items =
            (responses[0] as PaginatedResponse<SalesOrderModel>).data ??
            const <SalesOrderModel>[];
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
        _itemsLookup =
            ((responses[8] as PaginatedResponse<ItemModel>).data ??
                    const <ItemModel>[])
                .where((item) => item.isActive)
                .toList();
        _uoms =
            ((responses[9] as PaginatedResponse<UomModel>).data ??
                    const <UomModel>[])
                .where((item) => item.isActive)
                .toList();
        _uomConversions =
            ((responses[10] as PaginatedResponse<UomConversionModel>).data ??
                    const <UomConversionModel>[])
                .where((item) => item.isActive)
                .toList();
        _warehouses =
            ((responses[11] as PaginatedResponse<WarehouseModel>).data ??
                    const <WarehouseModel>[])
                .where((item) => item.isActive)
                .toList();
        _taxCodes =
            ((responses[12] as PaginatedResponse<TaxCodeModel>).data ??
                    const <TaxCodeModel>[])
                .where((item) => item.isActive)
                .toList();
        _quotationsAll =
            (responses[13] as ApiResponse<List<SalesQuotationModel>>).data ??
            const <SalesQuotationModel>[];
        _contextCompanyId = contextSelection.companyId;
        _contextBranchId = contextSelection.branchId;
        _contextLocationId = contextSelection.locationId;
        _contextFinancialYearId = contextSelection.financialYearId;
        _initialLoading = false;
      });
      _applyFilters();

      final selected = selectId != null
          ? _items.cast<SalesOrderModel?>().firstWhere(
              (item) => intValue(item?.toJson() ?? const {}, 'id') == selectId,
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
        final qid = widget.initialQuotationId;
        if (qid != null && widget.editorOnly) {
          await _prefillNewOrderFromQuotation(qid);
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

  Future<void> _prefillNewOrderFromQuotation(int quotationId) async {
    try {
      final r = await _salesService.quotation(quotationId);
      final q = r.data;
      if (q == null || !mounted) {
        return;
      }
      final data = q.toJson();
      final lines = (data['lines'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(_OrderLineDraft.fromQuotationLine)
          .toList(growable: true);
      for (final old in _lines) {
        old.dispose();
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _salesQuotationId = quotationId;
        _companyId = intValue(data, 'company_id');
        _branchId = intValue(data, 'branch_id');
        _locationId = intValue(data, 'location_id');
        _financialYearId = intValue(data, 'financial_year_id');
        final series = _seriesOptions();
        _documentSeriesId = series.isNotEmpty
            ? series.first.id
            : intValue(data, 'document_series_id');
        _customerPartyId = intValue(data, 'customer_party_id');
        _orderNoController.clear();
        _orderDateController.text = DateTime.now()
            .toIso8601String()
            .split('T')
            .first;
        _expectedDeliveryController.text = displayDate(
          nullableStringValue(data, 'valid_until'),
        );
        _customerRefNoController.text = stringValue(
          data,
          'customer_reference_no',
        );
        _customerRefDateController.text = displayDate(
          nullableStringValue(data, 'customer_reference_date'),
        );
        _currencyCodeController.text = stringValue(
          data,
          'currency_code',
          'INR',
        );
        _exchangeRateController.text = stringValue(data, 'exchange_rate', '1');
        _roundOffController.clear();
        _notesController.text = stringValue(data, 'notes');
        _termsController.text = stringValue(data, 'terms_conditions');
        _isActive = true;
        _lines = lines.isEmpty ? <_OrderLineDraft>[_OrderLineDraft()] : lines;
        _formError = null;
      });
      await _fetchQuotationLines(quotationId);
      await _refreshSalesChain();
    } catch (e) {
      if (mounted) {
        setState(() => _formError = e.toString());
      }
    }
  }

  Future<void> _selectDocument(SalesOrderModel item) async {
    final id = intValue(item.toJson(), 'id');
    if (id == null) {
      return;
    }
    final response = await _salesService.order(id);
    final full = response.data ?? item;
    final data = full.toJson();
    final lines = (data['lines'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(_OrderLineDraft.fromJson)
        .toList(growable: true);
    for (final old in _lines) {
      old.dispose();
    }
    final qid = intValue(data, 'sales_quotation_id');
    setState(() {
      _selectedItem = full;
      _companyId = intValue(data, 'company_id');
      _branchId = intValue(data, 'branch_id');
      _locationId = intValue(data, 'location_id');
      _financialYearId = intValue(data, 'financial_year_id');
      _documentSeriesId = intValue(data, 'document_series_id');
      _customerPartyId = intValue(data, 'customer_party_id');
      _salesQuotationId = qid == 0 ? null : qid;
      _quotationLinesCache = null;
      _orderNoController.text = stringValue(data, 'order_no');
      _orderDateController.text = displayDate(
        nullableStringValue(data, 'order_date'),
      );
      _expectedDeliveryController.text = displayDate(
        nullableStringValue(data, 'expected_delivery_date'),
      );
      _customerRefNoController.text = stringValue(
        data,
        'customer_reference_no',
      );
      _customerRefDateController.text = displayDate(
        nullableStringValue(data, 'customer_reference_date'),
      );
      _currencyCodeController.text = stringValue(data, 'currency_code', 'INR');
      _exchangeRateController.text = stringValue(data, 'exchange_rate', '1');
      _roundOffController.text =
          stringValue(data, 'round_off_amount').trim().isEmpty
          ? ''
          : stringValue(data, 'round_off_amount');
      _notesController.text = stringValue(data, 'notes');
      _termsController.text = stringValue(data, 'terms_conditions');
      _isActive = boolValue(data, 'is_active', fallback: true);
      _lines = lines.isEmpty ? <_OrderLineDraft>[_OrderLineDraft()] : lines;
      _formError = null;
    });
    if (_salesQuotationId != null) {
      await _fetchQuotationLines(_salesQuotationId!);
    }
    await _refreshSalesChain();
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
      _salesQuotationId = null;
      _quotationLinesCache = null;
      _orderNoController.clear();
      _orderDateController.text = DateTime.now()
          .toIso8601String()
          .split('T')
          .first;
      _expectedDeliveryController.clear();
      _customerRefNoController.clear();
      _customerRefDateController.clear();
      _currencyCodeController.text = 'INR';
      _exchangeRateController.text = '1';
      _roundOffController.clear();
      _notesController.clear();
      _termsController.clear();
      _isActive = true;
      _lines = <_OrderLineDraft>[_OrderLineDraft()];
      _formError = null;
      _salesChain = null;
    });
  }

  void _applyFilters() {
    final search = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredItems = _items
          .where((item) {
            final data = item.toJson();
            final statusOk =
                _statusFilter.isEmpty ||
                stringValue(data, 'order_status') == _statusFilter;
            final cust = quotationCustomerLabel(data);
            final searchOk =
                search.isEmpty ||
                [
                  stringValue(data, 'order_no'),
                  stringValue(data, 'order_status'),
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

  String get _currencyCodeForTaxSummary {
    final currency = _currencyCodeController.text.trim();
    return currency.isEmpty ? 'INR' : currency;
  }

  SalesLineTaxBreakdown _taxBreakdownForLine(_OrderLineDraft line) {
    return computeSalesLineTaxBreakdown(
      qty: double.tryParse(line.qtyController.text.trim()) ?? 0,
      rate: double.tryParse(line.rateController.text.trim()) ?? 0,
      discountPercent:
          double.tryParse(line.discountController.text.trim()) ?? 0,
      taxCode: salesTaxCodeById(_taxCodes, line.taxCodeId),
    );
  }

  SalesDocumentTaxSummary _taxSummary() {
    final roundOff = double.tryParse(_roundOffController.text.trim()) ?? 0;
    return summarizeSalesLineTaxes(
      _lines.map(_taxBreakdownForLine),
      adjustment: roundOff,
    );
  }

  Widget _buildTaxSummaryCard(BuildContext context) {
    final roundOff = double.tryParse(_roundOffController.text.trim()) ?? 0;
    final subtitle = roundOff == 0
        ? null
        : 'Live GST totals for the current lines in $_currencyCodeForTaxSummary · includes round off ${roundOff.toStringAsFixed(2)}';
    final summary = _taxSummary();
    return SalesGstSummaryCard(
      taxable: summary.taxable,
      cgst: summary.cgst,
      sgst: summary.sgst,
      igst: summary.igst,
      cess: summary.cess,
      total: summary.total,
      currencyCode: _currencyCodeForTaxSummary,
      subtitle: subtitle,
    );
  }

  Map<String, dynamic> _linePayload(_OrderLineDraft line) {
    final payload = line.toJson();
    final breakdown = _taxBreakdownForLine(line);
    return <String, dynamic>{
      ...payload,
      'discount_amount': roundToDouble(breakdown.gross - breakdown.taxable, 2),
      'gross_amount': roundToDouble(breakdown.gross, 2),
      'taxable_amount': roundToDouble(breakdown.taxable, 2),
      'tax_percent': roundToDouble(breakdown.taxPercent, 4),
      'cgst_amount': roundToDouble(breakdown.cgst, 2),
      'sgst_amount': roundToDouble(breakdown.sgst, 2),
      'igst_amount': roundToDouble(breakdown.igst, 2),
      'cess_amount': roundToDouble(breakdown.cess, 2),
      'line_total': roundToDouble(breakdown.total, 2),
    };
  }

  void _addLine() {
    setState(() {
      _lines = List<_OrderLineDraft>.from(_lines)..add(_OrderLineDraft());
    });
  }

  void _removeLine(int index) {
    setState(() {
      final next = List<_OrderLineDraft>.from(_lines);
      next.removeAt(index).dispose();
      _lines = next.isEmpty ? <_OrderLineDraft>[_OrderLineDraft()] : next;
    });
  }

  Future<void> _save() async {
    if (!_canEdit) {
      setState(() {
        _formError = 'Only draft orders can be updated.';
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
      setState(() => _formError = 'Each line needs item, UOM, and quantity.');
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    final taxSummary = _taxSummary();
    final payload = <String, dynamic>{
      'company_id': _companyId,
      'branch_id': _branchId,
      'location_id': _locationId,
      'financial_year_id': _financialYearId,
      'document_series_id': _documentSeriesId,
      'sales_quotation_id': _salesQuotationId,
      'order_no': nullIfEmpty(_orderNoController.text),
      'order_date': _orderDateController.text.trim(),
      'expected_delivery_date': nullIfEmpty(_expectedDeliveryController.text),
      'customer_party_id': _customerPartyId,
      'customer_reference_no': nullIfEmpty(_customerRefNoController.text),
      'customer_reference_date': nullIfEmpty(_customerRefDateController.text),
      'currency_code': nullIfEmpty(_currencyCodeController.text) ?? 'INR',
      'exchange_rate':
          double.tryParse(_exchangeRateController.text.trim()) ?? 1,
      'round_off_amount': double.tryParse(_roundOffController.text.trim()) ?? 0,
      'taxable_amount': roundToDouble(taxSummary.taxable, 2),
      'cgst_amount': roundToDouble(taxSummary.cgst, 2),
      'sgst_amount': roundToDouble(taxSummary.sgst, 2),
      'igst_amount': roundToDouble(taxSummary.igst, 2),
      'cess_amount': roundToDouble(taxSummary.cess, 2),
      'total_amount': roundToDouble(taxSummary.total, 2),
      'notes': nullIfEmpty(_notesController.text),
      'terms_conditions': nullIfEmpty(_termsController.text),
      'is_active': _isActive,
      'lines': _lines.map(_linePayload).toList(growable: false),
    };

    try {
      final response = _selectedItem == null
          ? await _salesService.createOrder(SalesOrderModel(payload))
          : await _salesService.updateOrder(
              intValue(_selectedItem!.toJson(), 'id')!,
              SalesOrderModel(payload),
            );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadPage(
        selectId: intValue(response.data?.toJson() ?? const {}, 'id'),
      );
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
    Future<ApiResponse<SalesOrderModel>> Function() action,
  ) async {
    try {
      final response = await action();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadPage(
        selectId: intValue(response.data?.toJson() ?? const {}, 'id'),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _formError = _errorMessage(error));
    }
  }

  Future<void> _delete() async {
    final id = intValue(_selectedItem?.toJson() ?? const {}, 'id');
    if (id == null) {
      return;
    }
    try {
      final response = await _salesService.deleteOrder(id);
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
        label: 'New order',
      ),
    ];
    final content = _buildContent();
    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }
    return AppStandaloneShell(
      title: 'Sales Orders',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading orders...');
    }
    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load orders',
        message: _pageError!,
        onRetry: _loadPage,
      );
    }

    final sel = _selectedItem?.toJson() ?? const {};
    final totalStr = stringValue(sel, 'total_amount');

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Sales Orders',
      editorTitle: _selectedItem == null
          ? 'New order'
          : stringValue(sel, 'order_no', 'Order'),
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: PurchaseListCard<SalesOrderModel>(
        items: _filteredItems,
        selectedItem: _selectedItem,
        emptyMessage: 'No sales orders yet.',
        searchController: _searchController,
        searchHint: 'Search by number or customer',
        statusValue: _statusFilter,
        statusItems: _listStatusFilter,
        onStatusChanged: (value) {
          _statusFilter = value ?? '';
          _applyFilters();
        },
        itemBuilder: (item, selected) {
          final data = item.toJson();
          return SettingsListTile(
            title: stringValue(data, 'order_no', 'Draft'),
            subtitle: [
              displayDate(nullableStringValue(data, 'order_date')),
              stringValue(data, 'order_status'),
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
            CrmSalesPipelineBar(data: _salesChain, hideOrderChip: true),
            if (_selectedItem != null && totalStr.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(
                  bottom: AppUiConstants.spacingSm,
                ),
                child: Text(
                  'Total: $totalStr ${_currencyCodeController.text.trim().isEmpty ? 'INR' : _currencyCodeController.text.trim()} · Status: ${_status.toUpperCase()}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            SettingsFormWrap(
              children: [
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
                      _documentSeriesId = options.isNotEmpty
                          ? options.first.id
                          : null;
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
                  labelText: 'Order No',
                  controller: _orderNoController,
                  hintText: 'Leave blank if your series fills this in',
                  enabled: _canEdit,
                  validator: Validators.optionalMaxLength(100, 'Order No'),
                ),
                AppFormTextField(
                  labelText: 'Order Date',
                  controller: _orderDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  enabled: _canEdit,
                  validator: Validators.compose([
                    Validators.required('Order Date'),
                    Validators.date('Order Date'),
                  ]),
                ),
                AppFormTextField(
                  labelText: 'Expected delivery',
                  controller: _expectedDeliveryController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  enabled: _canEdit,
                  validator: Validators.compose([
                    Validators.optionalDate('Expected delivery'),
                    Validators.optionalDateOnOrAfter(
                      'Expected delivery',
                      () => _orderDateController.text.trim(),
                      startFieldName: 'Order Date',
                    ),
                  ]),
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Customer',
                  doctypeLabel: 'Customer',
                  allowCreate: true,
                  onNavigateToCreateNew: (name) {
                    final uri = Uri(
                      path: '/parties',
                      queryParameters: {
                        'new': '1',
                        if (name.trim().isNotEmpty) 'party_name': name.trim(),
                      },
                    );
                    openModuleShellRoute(context, uri.toString());
                  },
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
                      if (_salesQuotationId != null) {
                        final stillOk = _quotationChoices.any(
                          (q) =>
                              intValue(q.toJson(), 'id') == _salesQuotationId,
                        );
                        if (!stillOk) {
                          _salesQuotationId = null;
                          _quotationLinesCache = null;
                          for (final line in _lines) {
                            line.salesQuotationLineId = null;
                          }
                        }
                      }
                    });
                  },
                  validator: Validators.requiredSelection('Customer'),
                ),
                AppDropdownField<int?>.fromMapped(
                  labelText: 'From quotation (optional)',
                  mappedItems: [
                    const AppDropdownItem<int?>(value: null, label: 'None'),
                    ..._quotationChoices
                        .map((q) => q.toJson())
                        .where((j) => intValue(j, 'id') != null)
                        .map(
                          (j) => AppDropdownItem<int?>(
                            value: intValue(j, 'id'),
                            label: stringValue(j, 'quotation_no', 'Quote'),
                          ),
                        ),
                  ],
                  initialValue: _salesQuotationId,
                  onChanged: (value) =>
                      unawaited(_onHeaderQuotationChanged(value)),
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
                  onChanged: (_) => setState(() {}),
                  validator: Validators.optionalMaxLength(10, 'Currency'),
                ),
                AppFormTextField(
                  labelText: 'Exchange Rate',
                  controller: _exchangeRateController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  enabled: _canEdit,
                  validator: Validators.optionalNonNegativeNumber(
                    'Exchange Rate',
                  ),
                ),
                AppFormTextField(
                  labelText: 'Round off',
                  controller: _roundOffController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  enabled: _canEdit,
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) {
                      return null;
                    }
                    if (double.tryParse(trimmed) == null) {
                      return 'Round off must be a valid number';
                    }
                    return null;
                  },
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
              final breakdown = _taxBreakdownForLine(line);
              return Padding(
                padding: const EdgeInsets.only(
                  bottom: AppUiConstants.spacingSm,
                ),
                child: PurchaseCompactLineCard(
                  index: index,
                  total: _lines.length,
                  removeEnabled: _canEdit && _lines.length > 1,
                  onRemove: _canEdit ? () => _removeLine(index) : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PurchaseCompactFieldGrid(
                        children: [
                          if (_salesQuotationId != null &&
                              (_quotationLinesCache != null &&
                                  _quotationLinesCache!.isNotEmpty))
                            AppDropdownField<int?>.fromMapped(
                              labelText: 'Quotation line',
                              mappedItems: [
                                const AppDropdownItem<int?>(
                                  value: null,
                                  label: 'None',
                                ),
                                ..._quotationLinesCache!
                                    .map((ql) {
                                      final lid = intValue(ql, 'id');
                                      return AppDropdownItem<int?>(
                                        value: lid,
                                        label: _quotationLinePickerLabel(ql),
                                      );
                                    })
                                    .where((it) => it.value != null),
                              ],
                              initialValue: line.salesQuotationLineId,
                              onChanged: (value) {
                                if (!_canEdit) {
                                  return;
                                }
                                _applyQuotationLinePick(line, value);
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
                                line.salesQuotationLineId = null;
                                final item = _itemsLookup
                                    .cast<ItemModel?>()
                                    .firstWhere(
                                      (e) => e?.id == value,
                                      orElse: () => null,
                                    );
                                applySalesLineDefaultsFromItemMaster(
                                  item: item,
                                  uoms: _uoms,
                                  conversions: _uomConversions,
                                  rateController: line.rateController,
                                  setUom: (u) => line.uomId = u,
                                  currentUomId: line.uomId,
                                  setTaxCodeId: (t) => line.taxCodeId = t,
                                  setWarehouseId: (w) => line.warehouseId = w,
                                  currentWarehouseId: line.warehouseId,
                                  warehouses: _warehouses,
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
                            labelText: 'Order qty',
                            controller: line.qtyController,
                            enabled: _canEdit,
                            onChanged: (_) => setState(() {}),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: Validators.compose([
                              Validators.required('Order qty'),
                              Validators.optionalNonNegativeNumber('Order qty'),
                            ]),
                          ),
                          AppFormTextField(
                            labelText: 'Rate',
                            controller: line.rateController,
                            enabled: _canEdit,
                            onChanged: (_) => setState(() {}),
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
                            onChanged: (_) => setState(() {}),
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
                      const SizedBox(height: AppUiConstants.spacingSm),
                      SalesLineTaxPreview(
                        gross: breakdown.gross,
                        taxable: breakdown.taxable,
                        cgst: breakdown.cgst,
                        sgst: breakdown.sgst,
                        igst: breakdown.igst,
                        cess: breakdown.cess,
                        total: breakdown.total,
                        currencyCode: _currencyCodeForTaxSummary,
                        taxCodeLabel: salesTaxCodeById(
                          _taxCodes,
                          line.taxCodeId,
                        )?.toString(),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: AppUiConstants.spacingMd),
            _buildTaxSummaryCard(context),
            const SizedBox(height: AppUiConstants.spacingMd),
            Wrap(
              spacing: AppUiConstants.spacingSm,
              runSpacing: AppUiConstants.spacingSm,
              children: [
                AppActionButton(
                  icon: Icons.save_outlined,
                  label: _selectedItem == null ? 'Save order' : 'Update order',
                  onPressed: _canEdit ? _save : null,
                  busy: _saving,
                ),
                if (_selectedItem != null) ...[
                  if (_status == 'draft') ...[
                    AppActionButton(
                      icon: Icons.check_circle_outline,
                      label: 'Confirm order',
                      filled: false,
                      onPressed: () => _docAction(
                        () => _salesService.confirmOrder(
                          intValue(_selectedItem!.toJson(), 'id')!,
                          SalesOrderModel(const <String, dynamic>{}),
                        ),
                      ),
                    ),
                    AppActionButton(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      filled: false,
                      onPressed: _delete,
                    ),
                  ],
                  if (const {
                    'draft',
                    'confirmed',
                    'partially_delivered',
                    'partially_invoiced',
                  }.contains(_status))
                    AppActionButton(
                      icon: Icons.block_outlined,
                      label: 'Cancel order',
                      filled: false,
                      onPressed: () => _docAction(
                        () => _salesService.cancelOrder(
                          intValue(_selectedItem!.toJson(), 'id')!,
                          SalesOrderModel(const <String, dynamic>{}),
                        ),
                      ),
                    ),
                  if (const {
                    'confirmed',
                    'partially_delivered',
                    'partially_invoiced',
                  }.contains(_status))
                    AppActionButton(
                      icon: Icons.lock_outline,
                      label: 'Close order',
                      filled: false,
                      onPressed: () => _docAction(
                        () => _salesService.closeOrder(
                          intValue(_selectedItem!.toJson(), 'id')!,
                          SalesOrderModel(const <String, dynamic>{}),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderLineDraft {
  _OrderLineDraft({
    this.salesQuotationLineId,
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

  factory _OrderLineDraft.fromJson(Map<String, dynamic> json) {
    final q = json['ordered_qty'] ?? json['qty'];
    return _OrderLineDraft(
      salesQuotationLineId: intValue(json, 'sales_quotation_line_id'),
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

  factory _OrderLineDraft.fromQuotationLine(Map<String, dynamic> json) {
    final q = json['qty'];
    return _OrderLineDraft(
      salesQuotationLineId: intValue(json, 'id'),
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

  int? salesQuotationLineId;
  int? itemId;
  int? warehouseId;
  int? uomId;
  int? taxCodeId;
  final TextEditingController descriptionController;
  final TextEditingController qtyController;
  final TextEditingController rateController;
  final TextEditingController discountController;
  final TextEditingController remarksController;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (salesQuotationLineId != null)
        'sales_quotation_line_id': salesQuotationLineId,
      'item_id': itemId,
      'warehouse_id': warehouseId,
      'uom_id': uomId,
      'tax_code_id': taxCodeId,
      'description': nullIfEmpty(descriptionController.text),
      'ordered_qty': double.tryParse(qtyController.text.trim()) ?? 0,
      'rate': double.tryParse(rateController.text.trim()) ?? 0,
      'discount_percent': double.tryParse(discountController.text.trim()) ?? 0,
      'remarks': nullIfEmpty(remarksController.text),
    };
  }

  void dispose() {
    descriptionController.dispose();
    qtyController.dispose();
    rateController.dispose();
    discountController.dispose();
    remarksController.dispose();
  }
}
