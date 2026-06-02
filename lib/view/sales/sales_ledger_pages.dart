import '../../screen.dart';

void _openSalesLedgerRoute(BuildContext context, String route) {
  final navigate = ShellRouteScope.maybeOf(context);
  if (navigate != null) {
    navigate(route);
    return;
  }
  Navigator.of(context).pushNamed(route);
}

class SalesLedgerRegisterPage extends StatefulWidget {
  const SalesLedgerRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<SalesLedgerRegisterPage> createState() =>
      _SalesLedgerRegisterPageState();
}

class _SalesLedgerRegisterPageState extends State<SalesLedgerRegisterPage> {
  static const List<AppDropdownItem<String>> _statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: '', label: 'All status'),
        AppDropdownItem(value: 'active', label: 'Active'),
        AppDropdownItem(value: 'inactive', label: 'Inactive'),
      ];
  static const List<AppDropdownItem<String>> _balanceItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: '', label: 'All balances'),
        AppDropdownItem(value: 'receivable', label: 'Receivable'),
        AppDropdownItem(value: 'advance', label: 'Advance'),
        AppDropdownItem(value: 'settled', label: 'Settled'),
      ];

  final AccountsService _accountsService = AccountsService();
  final SalesService _salesService = SalesService();
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  String? _errorMessage;
  String _status = '';
  String _balanceFilter = '';
  List<_SalesLedgerRegisterRow> _rows = const <_SalesLedgerRegisterRow>[];

  List<_SalesLedgerRegisterRow> get _filteredRows {
    final query = _searchController.text.trim().toLowerCase();
    return _rows
        .where((row) {
          final statusOk =
              _status.isEmpty ||
              (_status == 'active' ? row.isActive : !row.isActive);
          final balanceOk =
              _balanceFilter.isEmpty ||
              (_balanceFilter == 'receivable' && row.receivableAmount > 0) ||
              (_balanceFilter == 'advance' && row.advanceAmount > 0) ||
              (_balanceFilter == 'settled' && row.outstanding == 0);
          final searchOk =
              query.isEmpty ||
              [
                row.customerCode,
                row.customerName,
                row.ledgerCode,
                row.ledgerName,
              ].join(' ').toLowerCase().contains(query);
          return statusOk && balanceOk && searchOk;
        })
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    unawaited(_loadRows());
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadRows() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final responses = await Future.wait<dynamic>([
        _accountsService.partyAccountsRegister(
          filters: const <String, dynamic>{
            'account_purpose': 'receivable',
            'per_page': 200,
            'sort_by': 'id',
            'sort_order': 'desc',
          },
        ),
        _salesService.invoices(
          filters: const <String, dynamic>{
            'per_page': 200,
            'sort_by': 'invoice_date',
            'sort_order': 'desc',
          },
        ),
        _salesService.receipts(
          filters: const <String, dynamic>{
            'per_page': 200,
            'sort_by': 'receipt_date',
            'sort_order': 'desc',
          },
        ),
      ]);

      final mappings =
          (responses[0] as PaginatedResponse<PartyAccountModel>).data ??
          const <PartyAccountModel>[];
      final invoices =
          (responses[1] as PaginatedResponse<SalesInvoiceModel>).data ??
          const <SalesInvoiceModel>[];
      final receipts =
          (responses[2] as PaginatedResponse<SalesReceiptModel>).data ??
          const <SalesReceiptModel>[];

      final invoiceTotals = <int, double>{};
      final receiptTotals = <int, double>{};
      final lastInvoiceDates = <int, String>{};
      final lastReceiptDates = <int, String>{};

      for (final invoice in invoices) {
        final customerId = invoice.customerPartyId;
        invoiceTotals[customerId] =
            (invoiceTotals[customerId] ?? 0) + (invoice.totalAmount ?? 0);
        final invoiceDate = invoice.invoiceDate;
        final currentLastDate = lastInvoiceDates[customerId] ?? '';
        if (invoiceDate.compareTo(currentLastDate) > 0) {
          lastInvoiceDates[customerId] = invoiceDate;
        }
      }

      for (final receipt in receipts) {
        final customerId = receipt.customerPartyId;
        if (customerId == null) {
          continue;
        }
        receiptTotals[customerId] =
            (receiptTotals[customerId] ?? 0) + (receipt.paidAmount ?? 0);
        final receiptDate = receipt.receiptDate ?? '';
        final currentLastDate = lastReceiptDates[customerId] ?? '';
        if (receiptDate.compareTo(currentLastDate) > 0) {
          lastReceiptDates[customerId] = receiptDate;
        }
      }

      final nextRows = mappings
          .where((item) => item.id != null)
          .map(
            (item) => _SalesLedgerRegisterRow(
              id: item.id!,
              customerCode: item.partyCode ?? '',
              customerName: item.partyName ?? '',
              ledgerCode: item.accountCode ?? '',
              ledgerName: item.accountName ?? '',
              isActive: item.isActive,
              invoiceTotal: invoiceTotals[item.partyId ?? -1] ?? 0,
              receiptTotal: receiptTotals[item.partyId ?? -1] ?? 0,
              lastInvoiceDate: lastInvoiceDates[item.partyId ?? -1] ?? '',
              lastReceiptDate: lastReceiptDates[item.partyId ?? -1] ?? '',
            ),
          )
          .toList(growable: false);

      if (!mounted) {
        return;
      }

      setState(() {
        _rows = nextRows;
        _loading = false;
      });
    } catch (errorValue) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorMessage = errorValue.toString();
      });
    }
  }

  void _setStatus(String? value) {
    setState(() {
      _status = value ?? '';
    });
  }

  void _setBalanceFilter(String? value) {
    setState(() {
      _balanceFilter = value ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<_SalesLedgerRegisterRow>(
      title: 'Sales Ledger',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _errorMessage,
      onRetry: _loadRows,
      emptyMessage: 'No sales ledgers found.',
      actions: [
        AdaptiveShellActionButton(
          onPressed: _loadRows,
          icon: Icons.refresh_outlined,
          label: 'Refresh',
          filled: false,
        ),
      ],
      filters: _SalesLedgerFilters(
        searchController: _searchController,
        status: _status,
        statusItems: _statusItems,
        onStatusChanged: _setStatus,
        balanceFilter: _balanceFilter,
        balanceItems: _balanceItems,
        onBalanceChanged: _setBalanceFilter,
      ),
      rows: _filteredRows,
      columns: [
        PurchaseRegisterColumn(
          label: 'Customer Code',
          valueBuilder: (row) => row.customerCode,
        ),
        PurchaseRegisterColumn(
          label: 'Customer Name',
          flex: 3,
          valueBuilder: (row) => row.customerName,
        ),
        PurchaseRegisterColumn(
          label: 'Ledger Code',
          valueBuilder: (row) => row.ledgerCode,
        ),
        PurchaseRegisterColumn(
          label: 'Ledger Name',
          flex: 3,
          valueBuilder: (row) => row.ledgerName,
        ),
        PurchaseRegisterColumn(
          label: 'Receivable',
          valueBuilder: (row) =>
              _formatSalesRegisterAmount(row.receivableAmount),
        ),
        PurchaseRegisterColumn(
          label: 'Advance',
          valueBuilder: (row) => _formatSalesRegisterAmount(row.advanceAmount),
        ),
        PurchaseRegisterColumn(
          label: 'Last Invoice',
          valueBuilder: (row) => displayDate(row.lastInvoiceDate),
        ),
        PurchaseRegisterColumn(
          label: 'Last Receipt',
          valueBuilder: (row) => displayDate(row.lastReceiptDate),
        ),
        PurchaseRegisterColumn(
          label: 'Status',
          valueBuilder: (row) => row.isActive ? 'Active' : 'Inactive',
        ),
      ],
      onRowTap: (row) =>
          _openSalesLedgerRoute(context, '/sales/ledgers/${row.id}'),
    );
  }
}

class SalesLedgerDetailPage extends StatefulWidget {
  const SalesLedgerDetailPage({
    super.key,
    required this.ledgerId,
    this.embedded = false,
  });

  final int ledgerId;
  final bool embedded;

  @override
  State<SalesLedgerDetailPage> createState() => _SalesLedgerDetailPageState();
}

class _SalesLedgerDetailPageState extends State<SalesLedgerDetailPage> {
  final AccountsService _accountsService = AccountsService();
  final ScrollController _scrollController = ScrollController();

  bool _loading = true;
  String? _errorMessage;
  PartyAccountModel? _mapping;
  List<LedgerStatementRowData> _statementRows =
      const <LedgerStatementRowData>[];
  double _openingBalance = 0;
  double _totalDebit = 0;
  double _totalCredit = 0;
  double _closingBalance = 0;
  String _lastVoucherDate = '';

  @override
  void initState() {
    super.initState();
    unawaited(_loadDetail());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final mappingResponse = await _accountsService.partyAccount(
        widget.ledgerId,
      );
      final mapping = mappingResponse.data;
      if (mapping == null) {
        throw Exception('Sales ledger mapping not found.');
      }
      if (mapping.accountId == null) {
        throw Exception('Sales ledger account is not configured.');
      }

      final accountResponse = await _accountsService.account(mapping.accountId!);
      final account = accountResponse.data;
      if (account?.id == null || account?.companyId == null) {
        throw Exception('Sales ledger account details are incomplete.');
      }

      final reportResponse = await _accountsService.reportGeneralLedger(
        filters: <String, dynamic>{
          'company_id': account!.companyId,
          'account_id': account.id,
          if (mapping.partyId != null) 'party_id': mapping.partyId,
          'date_from': _ledgerHistoryDateFrom,
          'date_to': _ledgerHistoryDateTo(),
        },
      );
      final reportData = reportResponse.data?.data ?? const <String, dynamic>{};
      final summary = _ledgerMap(reportData['summary']);
      final lines = _ledgerList(reportData['lines']);
      final statementRows = lines
          .map(
            (line) => _SalesStatementRowSortWrapper(
              sortDate: line['voucher_date']?.toString() ?? '',
              row: LedgerStatementRowData(
                date: displayDate(line['voucher_date']?.toString()),
                code: _ledgerCode(line),
                ledgerName: mapping.accountName ?? mapping.accountCode ?? '-',
                cashBankLedger: _ledgerDescriptor(line),
                credit: _ledgerAmountText(line['credit']),
                debit: _ledgerAmountText(line['debit']),
              ),
            ),
          )
          .toList(growable: false)
        ..sort((left, right) => right.sortDate.compareTo(left.sortDate));

      if (!mounted) {
        return;
      }

      setState(() {
        _mapping = mapping;
        _statementRows = statementRows
            .map((item) => item.row)
            .toList(growable: false);
        _openingBalance = _ledgerDouble(summary['opening_balance']);
        _totalDebit = _ledgerDouble(summary['total_debit']);
        _totalCredit = _ledgerDouble(summary['total_credit']);
        _closingBalance = _ledgerDouble(summary['closing_balance']);
        _lastVoucherDate = lines.isEmpty
            ? ''
            : lines.last['voucher_date']?.toString() ?? '';
        _loading = false;
      });
    } catch (errorValue) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorMessage = errorValue.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      AdaptiveShellActionButton(
        onPressed: _loadDetail,
        icon: Icons.refresh_outlined,
        label: 'Refresh',
        filled: false,
      ),
    ];

    final content = _buildContent(context);
    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }
    return AppStandaloneShell(
      title: 'Sales Ledger',
      scrollController: _scrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_loading) {
      return const AppLoadingView(message: 'Loading sales ledger...');
    }

    if (_errorMessage != null) {
      return AppErrorStateView(
        title: 'Unable to load sales ledger',
        message: _errorMessage!,
        onRetry: _loadDetail,
      );
    }

    final mapping = _mapping;
    if (mapping == null) {
      return AppErrorStateView(
        title: 'Sales ledger unavailable',
        message: 'No sales ledger mapping was found for this record.',
        onRetry: _loadDetail,
      );
    }

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppUiConstants.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionCard(
            child: Wrap(
              spacing: AppUiConstants.spacingLg,
              runSpacing: AppUiConstants.spacingMd,
              children: [
                _SalesSummaryTile(
                  label: 'Customer',
                  value: mapping.partyName ?? '-',
                  width: 280,
                ),
                _SalesSummaryTile(
                  label: 'Ledger Code',
                  value: mapping.accountCode ?? '-',
                ),
                _SalesSummaryTile(
                  label: 'Ledger Name',
                  value: mapping.accountName ?? '-',
                  width: 280,
                ),
                _SalesSummaryTile(
                  label: 'Opening Balance',
                  value: _formatSalesLedgerAmount(_openingBalance),
                ),
                _SalesSummaryTile(
                  label: 'Total Debit',
                  value: _formatSalesLedgerAmount(_totalDebit),
                ),
                _SalesSummaryTile(
                  label: 'Total Credit',
                  value: _formatSalesLedgerAmount(_totalCredit),
                ),
                _SalesSummaryTile(
                  label: 'Closing Balance',
                  value: _formatSalesLedgerAmount(_closingBalance),
                ),
                _SalesSummaryTile(
                  label: 'Last Voucher',
                  value: displayDate(_lastVoucherDate),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppUiConstants.spacingLg),
          LedgerStatementTable(
            title: 'Ledger Statement',
            rows: _statementRows,
            emptyMessage:
                'No posted accounting transactions were found for this sales ledger.',
          ),
        ],
      ),
    );
  }
}

class _SalesLedgerFilters extends StatelessWidget {
  const _SalesLedgerFilters({
    required this.searchController,
    required this.status,
    required this.statusItems,
    required this.onStatusChanged,
    required this.balanceFilter,
    required this.balanceItems,
    required this.onBalanceChanged,
  });

  final TextEditingController searchController;
  final String status;
  final List<AppDropdownItem<String>> statusItems;
  final ValueChanged<String?> onStatusChanged;
  final String balanceFilter;
  final List<AppDropdownItem<String>> balanceItems;
  final ValueChanged<String?> onBalanceChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppUiConstants.spacingMd,
      runSpacing: AppUiConstants.spacingMd,
      children: [
        SizedBox(
          width: 320,
          child: AppFormTextField(
            controller: searchController,
            labelText: 'Search',
            hintText: 'Customer, code, or ledger',
          ),
        ),
        SizedBox(
          width: 220,
          child: AppDropdownField<String>.fromMapped(
            labelText: 'Status',
            mappedItems: statusItems,
            initialValue: status,
            onChanged: onStatusChanged,
          ),
        ),
        SizedBox(
          width: 220,
          child: AppDropdownField<String>.fromMapped(
            labelText: 'Ledger Balance',
            mappedItems: balanceItems,
            initialValue: balanceFilter,
            onChanged: onBalanceChanged,
          ),
        ),
      ],
    );
  }
}

class _SalesSummaryTile extends StatelessWidget {
  const _SalesSummaryTile({
    required this.label,
    required this.value,
    this.width = 220,
  });

  final String label;
  final String value;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(
                context,
              ).extension<AppThemeExtension>()!.mutedText,
            ),
          ),
          const SizedBox(height: AppUiConstants.spacingXs),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _SalesLedgerRegisterRow {
  const _SalesLedgerRegisterRow({
    required this.id,
    required this.customerCode,
    required this.customerName,
    required this.ledgerCode,
    required this.ledgerName,
    required this.isActive,
    required this.invoiceTotal,
    required this.receiptTotal,
    required this.lastInvoiceDate,
    required this.lastReceiptDate,
  });

  final int id;
  final String customerCode;
  final String customerName;
  final String ledgerCode;
  final String ledgerName;
  final bool isActive;
  final double invoiceTotal;
  final double receiptTotal;
  final String lastInvoiceDate;
  final String lastReceiptDate;

  double get outstanding => invoiceTotal - receiptTotal;
  double get receivableAmount => outstanding > 0 ? outstanding : 0;
  double get advanceAmount => outstanding < 0 ? outstanding.abs() : 0;
}

class _SalesStatementRowSortWrapper {
  const _SalesStatementRowSortWrapper({
    required this.sortDate,
    required this.row,
  });

  final String sortDate;
  final LedgerStatementRowData row;
}

String _formatSalesLedgerAmount(double value) => value.toStringAsFixed(2);

const String _ledgerHistoryDateFrom = '2000-01-01';

String _formatSalesRegisterAmount(double value) {
  if (value == 0) {
    return '';
  }
  return value.toStringAsFixed(2);
}

String _ledgerHistoryDateTo() =>
    DateTime.now().toIso8601String().split('T').first;

Map<String, dynamic> _ledgerMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map(
      (key, entry) => MapEntry(key.toString(), entry),
    );
  }
  return const <String, dynamic>{};
}

List<Map<String, dynamic>> _ledgerList(dynamic value) {
  if (value is! List) {
    return const <Map<String, dynamic>>[];
  }
  return value.map(_ledgerMap).toList(growable: false);
}

double _ledgerDouble(dynamic value) =>
    double.tryParse(value?.toString() ?? '') ?? 0;

String _ledgerAmountText(dynamic value) {
  final amount = _ledgerDouble(value);
  if (amount == 0) {
    return '';
  }
  return amount.toStringAsFixed(2);
}

String _ledgerCode(Map<String, dynamic> line) {
  final voucherNo = line['voucher_no']?.toString().trim() ?? '';
  if (voucherNo.isNotEmpty) {
    return voucherNo;
  }
  final voucherId = line['voucher_id']?.toString().trim() ?? '';
  return voucherId.isEmpty ? '-' : 'V-$voucherId';
}

String _ledgerDescriptor(Map<String, dynamic> line) {
  final parts = <String>[
    line['voucher_type']?.toString().trim() ?? '',
    line['reference_no']?.toString().trim() ?? '',
    line['narration']?.toString().trim() ?? '',
  ].where((item) => item.isNotEmpty).toList(growable: false);
  return parts.isEmpty ? '-' : parts.join(' · ');
}
