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

  final AccountsService _accountsService = AccountsService();
  final SalesService _salesService = SalesService();
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  String? _errorMessage;
  String _status = '';
  List<_SalesLedgerRegisterRow> _rows = const <_SalesLedgerRegisterRow>[];

  List<_SalesLedgerRegisterRow> get _filteredRows {
    final query = _searchController.text.trim().toLowerCase();
    return _rows
        .where((row) {
          final statusOk =
              _status.isEmpty ||
              (_status == 'active' ? row.isActive : !row.isActive);
          final searchOk =
              query.isEmpty ||
              [
                row.customerCode,
                row.customerName,
                row.ledgerCode,
                row.ledgerName,
              ].join(' ').toLowerCase().contains(query);
          return statusOk && searchOk;
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
  final SalesService _salesService = SalesService();
  final ScrollController _scrollController = ScrollController();

  bool _loading = true;
  String? _errorMessage;
  PartyAccountModel? _mapping;
  List<LedgerStatementRowData> _statementRows =
      const <LedgerStatementRowData>[];
  double _invoiceTotal = 0;
  double _receiptTotal = 0;
  String _lastReceiptDate = '';
  String _recentCashBankLedger = '-';

  double get _outstanding => _invoiceTotal - _receiptTotal;

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

      final responses = await Future.wait<dynamic>([
        _accountsService.accountsAll(
          filters: const <String, dynamic>{
            'is_active': 1,
            'sort_by': 'account_name',
          },
        ),
        _salesService.invoices(
          filters: <String, dynamic>{
            'customer_party_id': mapping.partyId,
            'per_page': 200,
            'sort_by': 'invoice_date',
            'sort_order': 'desc',
          },
        ),
        _salesService.receipts(
          filters: <String, dynamic>{
            'customer_party_id': mapping.partyId,
            'per_page': 200,
            'sort_by': 'receipt_date',
            'sort_order': 'desc',
          },
        ),
      ]);

      final accounts =
          (responses[0] as ApiResponse<List<AccountModel>>).data ??
          const <AccountModel>[];
      final invoices =
          (responses[1] as PaginatedResponse<SalesInvoiceModel>).data ??
          const <SalesInvoiceModel>[];
      final receipts =
          (responses[2] as PaginatedResponse<SalesReceiptModel>).data ??
          const <SalesReceiptModel>[];

      final accountNames = <int, String>{
        for (final account in accounts)
          if (account.id != null)
            account.id!: _salesAccountLabel(
              account.accountCode,
              account.accountName,
            ),
      };

      final statementRows = <_SalesStatementRowSortWrapper>[
        for (final invoice in invoices)
          _SalesStatementRowSortWrapper(
            sortDate: invoice.invoiceDate,
            row: LedgerStatementRowData(
              date: displayDate(invoice.invoiceDate),
              code: (invoice.invoiceNo?.trim().isNotEmpty ?? false)
                  ? invoice.invoiceNo!.trim()
                  : 'SI-${invoice.id}',
              ledgerName: mapping.accountName ?? mapping.accountCode ?? '-',
              cashBankLedger: 'Customer Receivable',
              credit: _formatSalesLedgerAmount(invoice.totalAmount ?? 0),
              debit: '',
            ),
          ),
        for (final receipt in receipts)
          _SalesStatementRowSortWrapper(
            sortDate: receipt.receiptDate ?? '',
            row: LedgerStatementRowData(
              date: displayDate(receipt.receiptDate),
              code: (receipt.receiptNo?.trim().isNotEmpty ?? false)
                  ? receipt.receiptNo!.trim()
                  : 'SR-${receipt.id ?? ''}',
              ledgerName: mapping.accountName ?? mapping.accountCode ?? '-',
              cashBankLedger:
                  accountNames[receipt.accountId] ??
                  (receipt.paymentMode?.titleCase ?? '-'),
              credit: '',
              debit: _formatSalesLedgerAmount(receipt.paidAmount ?? 0),
            ),
          ),
      ];

      statementRows.sort(
        (left, right) => right.sortDate.compareTo(left.sortDate),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _mapping = mapping;
        _statementRows = statementRows
            .map((item) => item.row)
            .toList(growable: false);
        _invoiceTotal = invoices.fold<double>(
          0,
          (sum, item) => sum + (item.totalAmount ?? 0),
        );
        _receiptTotal = receipts.fold<double>(
          0,
          (sum, item) => sum + (item.paidAmount ?? 0),
        );
        _lastReceiptDate = receipts.fold<String>('', (latest, item) {
          final value = item.receiptDate ?? '';
          return value.compareTo(latest) > 0 ? value : latest;
        });
        _recentCashBankLedger = receipts.isEmpty
            ? '-'
            : accountNames[receipts.first.accountId] ??
                  (receipts.first.paymentMode?.titleCase ?? '-');
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
                  label: 'Last Receipt Ledger',
                  value: _recentCashBankLedger,
                  width: 240,
                ),
                _SalesSummaryTile(
                  label: 'Invoice Total',
                  value: _formatSalesLedgerAmount(_invoiceTotal),
                ),
                _SalesSummaryTile(
                  label: 'Receipts',
                  value: _formatSalesLedgerAmount(_receiptTotal),
                ),
                _SalesSummaryTile(
                  label: _salesBalanceLabel(_outstanding),
                  value: _formatSalesLedgerAmount(_outstanding.abs()),
                ),
                _SalesSummaryTile(
                  label: 'Last Receipt',
                  value: displayDate(_lastReceiptDate),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppUiConstants.spacingLg),
          LedgerStatementTable(
            title: 'Ledger Statement',
            rows: _statementRows,
            emptyMessage:
                'No invoices or receipts were found for this sales ledger.',
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
  });

  final TextEditingController searchController;
  final String status;
  final List<AppDropdownItem<String>> statusItems;
  final ValueChanged<String?> onStatusChanged;

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

String _formatSalesRegisterAmount(double value) {
  if (value == 0) {
    return '';
  }
  return value.toStringAsFixed(2);
}

String _salesBalanceLabel(double value) {
  if (value > 0) {
    return 'Amount Receivable';
  }
  if (value < 0) {
    return 'Advance Received';
  }
  return 'Settled Balance';
}

String _salesAccountLabel(String? code, String? name) {
  final normalizedCode = (code ?? '').trim();
  final normalizedName = (name ?? '').trim();
  if (normalizedCode.isEmpty) {
    return normalizedName.isEmpty ? '-' : normalizedName;
  }
  if (normalizedName.isEmpty) {
    return normalizedCode;
  }
  return '$normalizedCode · $normalizedName';
}
