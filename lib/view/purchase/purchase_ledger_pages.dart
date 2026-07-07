import '../../screen.dart';

void _openPurchaseLedgerRoute(BuildContext context, String route) {
  final navigate = ShellRouteScope.maybeOf(context);
  if (navigate != null) {
    navigate(route);
    return;
  }
  Navigator.of(context).pushNamed(route);
}

class PurchaseLedgerRegisterPage extends StatefulWidget {
  const PurchaseLedgerRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<PurchaseLedgerRegisterPage> createState() =>
      _PurchaseLedgerRegisterPageState();
}

class _PurchaseLedgerRegisterPageState
    extends State<PurchaseLedgerRegisterPage> {
  static const List<AppDropdownItem<String>> _statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: '', label: 'All status'),
        AppDropdownItem(value: 'active', label: 'Active'),
        AppDropdownItem(value: 'inactive', label: 'Inactive'),
      ];
  static const List<AppDropdownItem<String>> _balanceItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: '', label: 'All balances'),
        AppDropdownItem(value: 'payable', label: 'Payable'),
        AppDropdownItem(value: 'advance', label: 'Advance'),
        AppDropdownItem(value: 'settled', label: 'Settled'),
      ];

  final AccountsService _accountsService = AccountsService();
  final PurchaseService _purchaseService = PurchaseService();
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  String? _errorMessage;
  String _status = '';
  String _balanceFilter = '';
  List<_PurchaseLedgerRegisterRow> _rows = const <_PurchaseLedgerRegisterRow>[];

  List<_PurchaseLedgerRegisterRow> get _filteredRows {
    final query = _searchController.text.trim().toLowerCase();
    return _rows
        .where((row) {
          final statusOk =
              _status.isEmpty ||
              (_status == 'active' ? row.isActive : !row.isActive);
          final balanceOk =
              _balanceFilter.isEmpty ||
              (_balanceFilter == 'payable' && row.payableAmount > 0) ||
              (_balanceFilter == 'advance' && row.advanceAmount > 0) ||
              (_balanceFilter == 'settled' && row.balance == 0);
          final searchOk =
              query.isEmpty ||
              [
                row.supplierCode,
                row.ledgerCode,
                row.ledgerName,
                row.partyName,
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
            'account_purpose': 'payable',
            'per_page': 200,
            'sort_by': 'id',
            'sort_order': 'desc',
          },
        ),
        _purchaseService.invoicesAll(
          filters: const <String, dynamic>{
            'per_page': 200,
            'sort_by': 'invoice_date',
            'sort_order': 'desc',
          },
        ),
        _purchaseService.paymentsAll(
          filters: const <String, dynamic>{
            'per_page': 200,
            'sort_by': 'payment_date',
            'sort_order': 'desc',
          },
        ),
      ]);

      final mappings =
          (responses[0] as PaginatedResponse<PartyAccountModel>).data ??
          const <PartyAccountModel>[];
      final invoices =
          (responses[1] as ApiResponse<List<PurchaseInvoiceModel>>).data ??
          const <PurchaseInvoiceModel>[];
      final payments =
          (responses[2] as ApiResponse<List<PurchasePaymentModel>>).data ??
          const <PurchasePaymentModel>[];

      final invoiceTotals = <int, double>{};
      final paymentTotals = <int, double>{};
      final transactionCounts = <int, int>{};
      final lastInvoiceDates = <int, String>{};
      final lastPaymentDates = <int, String>{};

      for (final invoice in invoices) {
        final partyId = invoice.supplierPartyId;
        invoiceTotals[partyId] =
            (invoiceTotals[partyId] ?? 0) + (invoice.totalAmount ?? 0);
        transactionCounts[partyId] = (transactionCounts[partyId] ?? 0) + 1;
        final invoiceDate = invoice.invoiceDate;
        final currentLastDate = lastInvoiceDates[partyId] ?? '';
        if (invoiceDate.compareTo(currentLastDate) > 0) {
          lastInvoiceDates[partyId] = invoiceDate;
        }
      }

      for (final payment in payments) {
        final partyId = payment.supplierPartyId;
        if (partyId == null) {
          continue;
        }
        paymentTotals[partyId] =
            (paymentTotals[partyId] ?? 0) + (payment.paidAmount ?? 0);
        transactionCounts[partyId] = (transactionCounts[partyId] ?? 0) + 1;
        final paymentDate = payment.paymentDate ?? '';
        final currentLastDate = lastPaymentDates[partyId] ?? '';
        if (paymentDate.compareTo(currentLastDate) > 0) {
          lastPaymentDates[partyId] = paymentDate;
        }
      }

      final nextRows = mappings
          .where((item) => item.id != null)
          .map(
            (item) => _PurchaseLedgerRegisterRow(
              id: item.id!,
              partyId: item.partyId,
              supplierCode: item.partyCode ?? '',
              ledgerCode: item.accountCode ?? '',
              ledgerName: item.accountName ?? '',
              partyName: item.partyName ?? '',
              isActive: item.isActive,
              invoiceTotal: invoiceTotals[item.partyId ?? -1] ?? 0,
              paymentTotal: paymentTotals[item.partyId ?? -1] ?? 0,
              transactionCount: transactionCounts[item.partyId ?? -1] ?? 0,
              lastInvoiceDate: lastInvoiceDates[item.partyId ?? -1] ?? '',
              lastPaymentDate: lastPaymentDates[item.partyId ?? -1] ?? '',
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
    return PurchaseRegisterPage<_PurchaseLedgerRegisterRow>(
      title: 'Purchase Ledger',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _errorMessage,
      onRetry: _loadRows,
      emptyMessage: 'No payable ledgers found for purchase.',
      actions: [
        AdaptiveShellActionButton(
          onPressed: _loadRows,
          icon: Icons.refresh_outlined,
          label: 'Refresh',
          filled: false,
        ),
      ],
      filters: _PurchaseLedgerFilters(
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
          label: 'Supplier Code',
          valueBuilder: (row) => row.supplierCode,
        ),
        PurchaseRegisterColumn(
          label: 'Supplier Name',
          flex: 3,
          valueBuilder: (row) => row.partyName,
        ),
        PurchaseRegisterColumn(
          label: 'Payable',
          alignRight: true,
          showPlaceholderWhenEmpty: false,
          valueBuilder: (row) =>
              _formatPurchaseRegisterAmount(row.payableAmount),
        ),
        PurchaseRegisterColumn(
          label: 'Advance',
          alignRight: true,
          showPlaceholderWhenEmpty: false,
          padding: const EdgeInsets.only(right: AppUiConstants.spacingMd),
          valueBuilder: (row) =>
              _formatPurchaseRegisterAmount(row.advanceAmount),
        ),
        PurchaseRegisterColumn(
          label: 'Last Bill',
          padding: const EdgeInsets.only(left: AppUiConstants.spacingMd),
          valueBuilder: (row) => displayDate(row.lastInvoiceDate),
        ),
        PurchaseRegisterColumn(
          label: 'Last Payment',
          valueBuilder: (row) => displayDate(row.lastPaymentDate),
        ),
      ],
      onRowTap: (row) =>
          _openPurchaseLedgerRoute(context, '/purchase/ledgers/${row.id}'),
    );
  }
}

class PurchaseLedgerDetailPage extends StatefulWidget {
  const PurchaseLedgerDetailPage({
    super.key,
    required this.ledgerId,
    this.embedded = false,
  });

  final int ledgerId;
  final bool embedded;

  @override
  State<PurchaseLedgerDetailPage> createState() =>
      _PurchaseLedgerDetailPageState();
}

class _PurchaseLedgerDetailPageState extends State<PurchaseLedgerDetailPage> {
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
        throw Exception('Purchase ledger mapping not found.');
      }
      if (mapping.accountId == null) {
        throw Exception('Purchase ledger account is not configured.');
      }

      final accountResponse = await _accountsService.account(
        mapping.accountId!,
      );
      final account = accountResponse.data;
      if (account?.id == null || account?.companyId == null) {
        throw Exception('Purchase ledger account details are incomplete.');
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
      final statementRows =
          lines
              .map(
                (line) => _StatementRowSortWrapper(
                  sortDate: line['voucher_date']?.toString() ?? '',
                  row: LedgerStatementRowData(
                    date: displayDate(line['voucher_date']?.toString()),
                    code: _ledgerCode(line),
                    ledgerName:
                        mapping.accountName ?? mapping.accountCode ?? '-',
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
      title: 'Purchase Ledger',
      scrollController: _scrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_loading) {
      return const AppLoadingView(message: 'Loading purchase ledger...');
    }

    if (_errorMessage != null) {
      return AppErrorStateView(
        title: 'Unable to load purchase ledger',
        message: _errorMessage!,
        onRetry: _loadDetail,
      );
    }

    final mapping = _mapping;
    if (mapping == null) {
      return AppErrorStateView(
        title: 'Purchase ledger unavailable',
        message: 'No purchase ledger mapping was found for this record.',
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
                _SummaryTile(
                  label: 'Supplier',
                  value: mapping.partyName ?? '-',
                  width: 280,
                ),
                _SummaryTile(
                  label: 'Ledger Code',
                  value: mapping.accountCode ?? '-',
                ),
                _SummaryTile(
                  label: 'Ledger Name',
                  value: mapping.accountName ?? '-',
                  width: 280,
                ),
                _SummaryTile(
                  label: 'Opening Balance',
                  value: _formatAmount(_openingBalance),
                ),
                _SummaryTile(
                  label: 'Total Debit',
                  value: _formatAmount(_totalDebit),
                ),
                _SummaryTile(
                  label: 'Total Credit',
                  value: _formatAmount(_totalCredit),
                ),
                _SummaryTile(
                  label: 'Closing Balance',
                  value: _formatAmount(_closingBalance),
                ),
                _SummaryTile(
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
                'No posted accounting transactions were found for this purchase ledger.',
          ),
        ],
      ),
    );
  }
}

class _PurchaseLedgerFilters extends StatelessWidget {
  const _PurchaseLedgerFilters({
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
            hintText: 'Supplier, code, or ledger',
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

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
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

class _PurchaseLedgerRegisterRow {
  const _PurchaseLedgerRegisterRow({
    required this.id,
    required this.partyId,
    required this.supplierCode,
    required this.ledgerCode,
    required this.ledgerName,
    required this.partyName,
    required this.isActive,
    required this.invoiceTotal,
    required this.paymentTotal,
    required this.transactionCount,
    required this.lastInvoiceDate,
    required this.lastPaymentDate,
  });

  final int id;
  final int? partyId;
  final String supplierCode;
  final String ledgerCode;
  final String ledgerName;
  final String partyName;
  final bool isActive;
  final double invoiceTotal;
  final double paymentTotal;
  final int transactionCount;
  final String lastInvoiceDate;
  final String lastPaymentDate;

  double get balance => invoiceTotal - paymentTotal;
  double get payableAmount => balance > 0 ? balance : 0;
  double get advanceAmount => balance < 0 ? balance.abs() : 0;
}

class _StatementRowSortWrapper {
  const _StatementRowSortWrapper({required this.sortDate, required this.row});

  final String sortDate;
  final LedgerStatementRowData row;
}

String _formatAmount(double value) => formatAmount(value);

const String _ledgerHistoryDateFrom = '2000-01-01';

String _formatPurchaseRegisterAmount(double value) {
  if (value == 0) {
    return '';
  }
  return formatAmount(value);
}

String _ledgerHistoryDateTo() =>
    DateTime.now().toIso8601String().split('T').first;

Map<String, dynamic> _ledgerMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, entry) => MapEntry(key.toString(), entry));
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
  return formatAmount(amount);
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
