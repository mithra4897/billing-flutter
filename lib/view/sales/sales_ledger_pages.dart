import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

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
  static const List<AppDropdownItem<String>> _balanceItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'receivable', label: 'Receivable'),
        AppDropdownItem(value: 'advance', label: 'Advance'),
        AppDropdownItem(value: 'settled', label: 'Settled'),
      ];

  final AccountsService _accountsService = AccountsService();
  final SalesService _salesService = SalesService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _dateFromController = TextEditingController();
  final TextEditingController _dateToController = TextEditingController();

  bool _loading = true;
  String? _errorMessage;
  Set<String> _balanceFilters = <String>{'receivable'};
  Set<int> _customerIds = <int>{};
  List<_SalesLedgerRegisterRow> _rows = const <_SalesLedgerRegisterRow>[];
  bool _exporting = false;

  List<AppDropdownItem<int>> get _customerItems {
    final customers = _rows
        .where((row) => row.customerId != null && row.customerName.isNotEmpty)
        .map((row) => MapEntry<int, String>(row.customerId!, row.customerName))
        .toList(growable: false);
    final uniqueCustomers = <int, String>{
      for (final entry in customers) entry.key: entry.value,
    };
    return <AppDropdownItem<int>>[
      ...uniqueCustomers.entries.map(
        (entry) => AppDropdownItem<int>(value: entry.key, label: entry.value),
      ),
    ];
  }

  List<_SalesLedgerRegisterRow> get _filteredRows {
    final query = _searchController.text.trim().toLowerCase();
    final dateFrom = _normalizedFilterDate(_dateFromController.text);
    final dateTo = _normalizedFilterDate(_dateToController.text);
    return _rows
        .where((row) {
          final balanceOk =
              _balanceFilters.isEmpty ||
              (_balanceFilters.contains('receivable') &&
                  row.receivableAmount > 0) ||
              (_balanceFilters.contains('advance') && row.advanceAmount > 0) ||
              (_balanceFilters.contains('settled') && row.outstanding == 0);
          final customerOk =
              _customerIds.isEmpty ||
              (row.customerId != null && _customerIds.contains(row.customerId));
          final activityDate = row.lastActivityDate;
          final dateOk =
              (dateFrom == null ||
                  (activityDate.isNotEmpty &&
                      activityDate.compareTo(dateFrom) >= 0)) &&
              (dateTo == null ||
                  (activityDate.isNotEmpty &&
                      activityDate.compareTo(dateTo) <= 0));
          final searchOk =
              query.isEmpty ||
              [
                row.customerCode,
                row.customerName,
              ].join(' ').toLowerCase().contains(query);
          return balanceOk && customerOk && dateOk && searchOk;
        })
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    _dateFromController.addListener(_handleSearchChanged);
    _dateToController.addListener(_handleSearchChanged);
    unawaited(_loadRows());
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    _dateFromController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    _dateToController
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
              customerId: item.partyId,
              customerCode: item.partyCode ?? '',
              customerName: item.partyName ?? '',
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

  void _setBalanceFilters(Set<String> values) {
    setState(() {
      _balanceFilters = Set<String>.from(values);
    });
  }

  void _setCustomerIds(Set<int> values) {
    setState(() {
      _customerIds = Set<int>.from(values);
    });
  }

  Future<void> _exportRows() async {
    final rows = _filteredRows;
    if (rows.isEmpty) {
      _showMessage('No sales ledger rows to export.');
      return;
    }

    setState(() {
      _exporting = true;
    });

    try {
      final workbook = _buildSalesLedgerWorkbook(rows);
      final saved = await saveBytesFile(
        suggestedName: _suggestedFileName(),
        bytes: workbook,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      _showMessage(
        saved
            ? 'Sales ledger exported successfully.'
            : 'Sales ledger export cancelled.',
      );
    } catch (error) {
      _showMessage('Sales ledger export failed: $error');
    } finally {
      if (mounted) {
        setState(() {
          _exporting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    final messenger =
        ScaffoldMessenger.maybeOf(context) ??
        appScaffoldMessengerKey.currentState;
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  String _suggestedFileName() {
    final now = DateTime.now();
    final date =
        '${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final time =
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    return 'sales_ledger_${date}_$time.xlsx';
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
          onPressed: _exporting ? null : _exportRows,
          icon: Icons.file_download_outlined,
          label: 'Export',
          filled: false,
        ),
        AdaptiveShellActionButton(
          onPressed: _loadRows,
          icon: Icons.refresh_outlined,
          label: 'Refresh',
          filled: false,
        ),
      ],
      filters: _SalesLedgerFilters(
        searchController: _searchController,
        dateFromController: _dateFromController,
        dateToController: _dateToController,
        customerIds: _customerIds,
        customerItems: _customerItems,
        onCustomerChanged: _setCustomerIds,
        balanceFilters: _balanceFilters,
        balanceItems: _balanceItems,
        onBalanceChanged: _setBalanceFilters,
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
          label: 'Receivable',
          alignRight: true,
          showPlaceholderWhenEmpty: false,
          valueBuilder: (row) => formatAmount(row.receivableAmount),
        ),
        PurchaseRegisterColumn(
          label: 'Advance',
          alignRight: true,
          showPlaceholderWhenEmpty: false,
          padding: const EdgeInsets.only(right: AppUiConstants.spacingMd),
          valueBuilder: (row) => formatAmount(row.advanceAmount),
        ),
        PurchaseRegisterColumn(
          label: 'Last Invoice',
          padding: const EdgeInsets.only(left: AppUiConstants.spacingMd),
          valueBuilder: (row) => displayDate(row.lastInvoiceDate),
        ),
        PurchaseRegisterColumn(
          label: 'Last Receipt',
          valueBuilder: (row) => displayDate(row.lastReceiptDate),
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
  bool _exporting = false;
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

      final accountResponse = await _accountsService.account(
        mapping.accountId!,
      );
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
      final statementRows =
          lines
              .map(
                (line) => _SalesStatementRowSortWrapper(
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

  Future<void> _exportDetail() async {
    final mapping = _mapping;
    if (mapping == null) {
      _showMessage('Sales ledger is not ready to export.');
      return;
    }
    if (_statementRows.isEmpty) {
      _showMessage('No sales ledger entries to export.');
      return;
    }

    setState(() {
      _exporting = true;
    });

    try {
      final workbook = _buildSalesLedgerDetailWorkbook(
        mapping: mapping,
        rows: _statementRows,
        openingBalance: _openingBalance,
        totalDebit: _totalDebit,
        totalCredit: _totalCredit,
        closingBalance: _closingBalance,
        lastVoucherDate: _lastVoucherDate,
      );
      final saved = await saveBytesFile(
        suggestedName: _salesLedgerDetailFileName(mapping),
        bytes: workbook,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      _showMessage(
        saved
            ? 'Sales ledger statement exported successfully.'
            : 'Sales ledger export cancelled.',
      );
    } catch (error) {
      _showMessage('Sales ledger export failed: $error');
    } finally {
      if (mounted) {
        setState(() {
          _exporting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    final messenger =
        ScaffoldMessenger.maybeOf(context) ??
        appScaffoldMessengerKey.currentState;
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      AdaptiveShellActionButton(
        onPressed: _exporting ? null : _exportDetail,
        icon: Icons.file_download_outlined,
        label: 'Export',
        filled: false,
      ),
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
    required this.dateFromController,
    required this.dateToController,
    required this.customerIds,
    required this.customerItems,
    required this.onCustomerChanged,
    required this.balanceFilters,
    required this.balanceItems,
    required this.onBalanceChanged,
  });

  final TextEditingController searchController;
  final TextEditingController dateFromController;
  final TextEditingController dateToController;
  final Set<int> customerIds;
  final List<AppDropdownItem<int>> customerItems;
  final ValueChanged<Set<int>> onCustomerChanged;
  final Set<String> balanceFilters;
  final List<AppDropdownItem<String>> balanceItems;
  final ValueChanged<Set<String>> onBalanceChanged;

  @override
  Widget build(BuildContext context) {
    Widget searchField() {
      return AppFormTextField(
        controller: searchController,
        labelText: 'Search',
        hintText: 'Customer name or code',
      );
    }

    Widget customerField() {
      return AppDropdownField<int>.fromMapped(
        labelText: 'Customer',
        mappedItems: customerItems,
        multiInitialValues: customerIds,
        multiHintText: 'Select customers',
        onMultiChanged: onCustomerChanged,
      );
    }

    Widget balanceField() {
      return AppDropdownField<String>.fromMapped(
        labelText: 'Ledger Balance',
        mappedItems: balanceItems,
        multiInitialValues: balanceFilters,
        multiHintText: 'Select balances',
        onMultiChanged: onBalanceChanged,
      );
    }

    Widget dateField({
      required String label,
      required TextEditingController controller,
    }) {
      return AppFormTextField(
        labelText: label,
        controller: controller,
        hintText: 'YYYY-MM-DD',
        keyboardType: TextInputType.datetime,
        inputFormatters: const [DateInputFormatter()],
        validator: Validators.optionalDate(label),
      );
    }

    void clearFilters() {
      searchController.clear();
      dateFromController.clear();
      dateToController.clear();
      onCustomerChanged(<int>{});
      onBalanceChanged(<String>{});
    }

    Widget actionField() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppUiConstants.spacingXs),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: clearFilters,
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isWide = width >= 1480;
        final isMedium = width >= 920 && width < 1480;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: searchField()),
              const SizedBox(width: AppUiConstants.spacingMd),
              Expanded(child: customerField()),
              const SizedBox(width: AppUiConstants.spacingMd),
              Expanded(child: balanceField()),
              const SizedBox(width: AppUiConstants.spacingMd),
              Expanded(
                child: dateField(
                  label: 'Date From',
                  controller: dateFromController,
                ),
              ),
              const SizedBox(width: AppUiConstants.spacingMd),
              Expanded(
                child: dateField(
                  label: 'Date To',
                  controller: dateToController,
                ),
              ),
              const SizedBox(width: AppUiConstants.spacingMd),
              SizedBox(width: 160, child: actionField()),
            ],
          );
        }

        if (isMedium) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Find Sales Ledger',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppUiConstants.spacingMd),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: searchField()),
                  const SizedBox(width: AppUiConstants.spacingMd),
                  Expanded(child: customerField()),
                  const SizedBox(width: AppUiConstants.spacingMd),
                  Expanded(child: balanceField()),
                ],
              ),
              const SizedBox(height: AppUiConstants.spacingMd),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: dateField(
                      label: 'Date From',
                      controller: dateFromController,
                    ),
                  ),
                  const SizedBox(width: AppUiConstants.spacingMd),
                  Expanded(
                    child: dateField(
                      label: 'Date To',
                      controller: dateToController,
                    ),
                  ),
                  const SizedBox(width: AppUiConstants.spacingMd),
                  SizedBox(width: 160, child: actionField()),
                ],
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Find Sales Ledger',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            SettingsFormWrap(
              maxWidth: double.infinity,
              children: [
                searchField(),
                customerField(),
                balanceField(),
                dateField(label: 'Date From', controller: dateFromController),
                dateField(label: 'Date To', controller: dateToController),
                actionField(),
              ],
            ),
          ],
        );
      },
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
    required this.customerId,
    required this.customerCode,
    required this.customerName,
    required this.isActive,
    required this.invoiceTotal,
    required this.receiptTotal,
    required this.lastInvoiceDate,
    required this.lastReceiptDate,
  });

  final int id;
  final int? customerId;
  final String customerCode;
  final String customerName;
  final bool isActive;
  final double invoiceTotal;
  final double receiptTotal;
  final String lastInvoiceDate;
  final String lastReceiptDate;

  double get outstanding => invoiceTotal - receiptTotal;
  double get receivableAmount => outstanding > 0 ? outstanding : 0;
  double get advanceAmount => outstanding < 0 ? outstanding.abs() : 0;
  String get lastActivityDate {
    final invoiceDate = lastInvoiceDate.trim();
    final receiptDate = lastReceiptDate.trim();
    if (invoiceDate.isEmpty) {
      return receiptDate;
    }
    if (receiptDate.isEmpty) {
      return invoiceDate;
    }
    return invoiceDate.compareTo(receiptDate) >= 0 ? invoiceDate : receiptDate;
  }
}

class _SalesStatementRowSortWrapper {
  const _SalesStatementRowSortWrapper({
    required this.sortDate,
    required this.row,
  });

  final String sortDate;
  final LedgerStatementRowData row;
}

String _formatSalesLedgerAmount(double value) => formatAmount(value);

const String _ledgerHistoryDateFrom = '2000-01-01';

String _ledgerHistoryDateTo() =>
    DateTime.now().toIso8601String().split('T').first;

String? _normalizedFilterDate(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  final parsed = DateTime.tryParse(trimmed);
  if (parsed == null) {
    return null;
  }
  return parsed.toIso8601String().split('T').first;
}

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

String _salesLedgerDetailFileName(PartyAccountModel mapping) {
  final now = DateTime.now();
  final date =
      '${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  final time =
      '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
  final name = (mapping.partyName ?? mapping.accountName ?? 'sales_ledger')
      .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '')
      .toLowerCase();
  final prefix = name.isEmpty ? 'sales_ledger' : name;
  return '${prefix}_${date}_$time.xlsx';
}

Uint8List _buildSalesLedgerWorkbook(List<_SalesLedgerRegisterRow> rows) {
  const headers = <String>[
    'Customer Code',
    'Customer Name',
    'Receivable',
    'Advance',
    'Outstanding',
    'Last Invoice',
    'Last Receipt',
    'Last Activity',
    'Status',
  ];

  final sheetRows = <List<_SalesLedgerExcelCell>>[
    <_SalesLedgerExcelCell>[
      _SalesLedgerExcelCell.text('Sales Ledger'),
      _SalesLedgerExcelCell.text(''),
      _SalesLedgerExcelCell.text(''),
      _SalesLedgerExcelCell.text(''),
      _SalesLedgerExcelCell.text(''),
      _SalesLedgerExcelCell.text(''),
      _SalesLedgerExcelCell.text(''),
      _SalesLedgerExcelCell.text(''),
      _SalesLedgerExcelCell.text(''),
    ],
    headers.map(_SalesLedgerExcelCell.header).toList(growable: false),
    ...rows.map(
      (row) => <_SalesLedgerExcelCell>[
        _SalesLedgerExcelCell.text(row.customerCode),
        _SalesLedgerExcelCell.text(row.customerName),
        _SalesLedgerExcelCell.number(row.receivableAmount),
        _SalesLedgerExcelCell.number(row.advanceAmount),
        _SalesLedgerExcelCell.number(row.outstanding),
        _SalesLedgerExcelCell.text(displayDate(row.lastInvoiceDate)),
        _SalesLedgerExcelCell.text(displayDate(row.lastReceiptDate)),
        _SalesLedgerExcelCell.text(displayDate(row.lastActivityDate)),
        _SalesLedgerExcelCell.text(row.isActive ? 'Active' : 'Inactive'),
      ],
    ),
  ];

  final archive = Archive()
    ..addFile(
      ArchiveFile.string('[Content_Types].xml', _salesLedgerContentTypesXml()),
    )
    ..addFile(ArchiveFile.string('_rels/.rels', _salesLedgerRootRelsXml()))
    ..addFile(ArchiveFile.string('docProps/app.xml', _salesLedgerAppXml()))
    ..addFile(ArchiveFile.string('docProps/core.xml', _salesLedgerCoreXml()))
    ..addFile(ArchiveFile.string('xl/workbook.xml', _salesLedgerWorkbookXml()))
    ..addFile(
      ArchiveFile.string(
        'xl/_rels/workbook.xml.rels',
        _salesLedgerWorkbookRelsXml(),
      ),
    )
    ..addFile(ArchiveFile.string('xl/styles.xml', _salesLedgerStylesXml()))
    ..addFile(
      ArchiveFile.string(
        'xl/worksheets/sheet1.xml',
        _salesLedgerWorksheetXml(sheetRows),
      ),
    );

  final bytes = ZipEncoder().encode(archive);
  return Uint8List.fromList(bytes);
}

Uint8List _buildSalesLedgerDetailWorkbook({
  required PartyAccountModel mapping,
  required List<LedgerStatementRowData> rows,
  required double openingBalance,
  required double totalDebit,
  required double totalCredit,
  required double closingBalance,
  required String lastVoucherDate,
}) {
  const headers = <String>[
    'Date',
    'Voucher',
    'Ledger',
    'Narration',
    'Debit',
    'Credit',
  ];

  final sheetRows = <List<_SalesLedgerExcelCell>>[
    <_SalesLedgerExcelCell>[
      _SalesLedgerExcelCell.text('Sales Ledger Statement'),
      _SalesLedgerExcelCell.text(''),
      _SalesLedgerExcelCell.text(''),
      _SalesLedgerExcelCell.text(''),
      _SalesLedgerExcelCell.text(''),
      _SalesLedgerExcelCell.text(''),
    ],
    <_SalesLedgerExcelCell>[
      _SalesLedgerExcelCell.text('Customer'),
      _SalesLedgerExcelCell.text(mapping.partyName ?? '-'),
      _SalesLedgerExcelCell.text('Opening Balance'),
      _SalesLedgerExcelCell.number(openingBalance),
      _SalesLedgerExcelCell.text('Closing Balance'),
      _SalesLedgerExcelCell.number(closingBalance),
    ],
    <_SalesLedgerExcelCell>[
      _SalesLedgerExcelCell.text('Total Debit'),
      _SalesLedgerExcelCell.number(totalDebit),
      _SalesLedgerExcelCell.text('Total Credit'),
      _SalesLedgerExcelCell.number(totalCredit),
      _SalesLedgerExcelCell.text('Last Voucher'),
      _SalesLedgerExcelCell.text(displayDate(lastVoucherDate)),
    ],
    headers.map(_SalesLedgerExcelCell.header).toList(growable: false),
    ...rows.map(
      (row) => <_SalesLedgerExcelCell>[
        _SalesLedgerExcelCell.text(row.date),
        _SalesLedgerExcelCell.text(row.code),
        _SalesLedgerExcelCell.text(row.ledgerName),
        _SalesLedgerExcelCell.text(row.cashBankLedger),
        _SalesLedgerExcelCell.number(_salesLedgerAmountFromText(row.debit)),
        _SalesLedgerExcelCell.number(_salesLedgerAmountFromText(row.credit)),
      ],
    ),
  ];

  final archive = Archive()
    ..addFile(
      ArchiveFile.string('[Content_Types].xml', _salesLedgerContentTypesXml()),
    )
    ..addFile(ArchiveFile.string('_rels/.rels', _salesLedgerRootRelsXml()))
    ..addFile(ArchiveFile.string('docProps/app.xml', _salesLedgerAppXml()))
    ..addFile(ArchiveFile.string('docProps/core.xml', _salesLedgerCoreXml()))
    ..addFile(ArchiveFile.string('xl/workbook.xml', _salesLedgerWorkbookXml()))
    ..addFile(
      ArchiveFile.string(
        'xl/_rels/workbook.xml.rels',
        _salesLedgerWorkbookRelsXml(),
      ),
    )
    ..addFile(ArchiveFile.string('xl/styles.xml', _salesLedgerStylesXml()))
    ..addFile(
      ArchiveFile.string(
        'xl/worksheets/sheet1.xml',
        _salesLedgerDetailWorksheetXml(sheetRows),
      ),
    );

  final bytes = ZipEncoder().encode(archive);
  return Uint8List.fromList(bytes);
}

double _salesLedgerAmountFromText(String value) =>
    double.tryParse(value.trim()) ?? 0;

String _salesLedgerContentTypesXml() {
  return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
  <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
</Types>''';
}

String _salesLedgerRootRelsXml() {
  return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>''';
}

String _salesLedgerAppXml() {
  return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
  <Application>Billing ERP</Application>
</Properties>''';
}

String _salesLedgerCoreXml() {
  final created = DateTime.now().toUtc().toIso8601String();
  return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dc:creator>Billing ERP</dc:creator>
  <cp:lastModifiedBy>Billing ERP</cp:lastModifiedBy>
  <dcterms:created xsi:type="dcterms:W3CDTF">$created</dcterms:created>
  <dcterms:modified xsi:type="dcterms:W3CDTF">$created</dcterms:modified>
</cp:coreProperties>''';
}

String _salesLedgerWorkbookXml() {
  return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets>
    <sheet name="Sales Ledger" sheetId="1" r:id="rId1"/>
  </sheets>
</workbook>''';
}

String _salesLedgerWorkbookRelsXml() {
  return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>''';
}

String _salesLedgerStylesXml() {
  return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <fonts count="2">
    <font>
      <sz val="11"/>
      <name val="Calibri"/>
    </font>
    <font>
      <b/>
      <sz val="11"/>
      <name val="Calibri"/>
    </font>
  </fonts>
  <fills count="3">
    <fill><patternFill patternType="none"/></fill>
    <fill><patternFill patternType="gray125"/></fill>
    <fill><patternFill patternType="solid"><fgColor rgb="FFE9EEF7"/><bgColor indexed="64"/></patternFill></fill>
  </fills>
  <borders count="1">
    <border><left/><right/><top/><bottom/><diagonal/></border>
  </borders>
  <cellStyleXfs count="1">
    <xf numFmtId="0" fontId="0" fillId="0" borderId="0"/>
  </cellStyleXfs>
  <cellXfs count="3">
    <xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
    <xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1"/>
    <xf numFmtId="4" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>
  </cellXfs>
  <cellStyles count="1">
    <cellStyle name="Normal" xfId="0" builtinId="0"/>
  </cellStyles>
</styleSheet>''';
}

String _salesLedgerWorksheetXml(List<List<_SalesLedgerExcelCell>> rows) {
  final builder = XmlBuilder();
  builder.processing('xml', 'version="1.0" encoding="UTF-8" standalone="yes"');
  builder.element(
    'worksheet',
    namespaces: <String, String>{
      'http://schemas.openxmlformats.org/spreadsheetml/2006/main': '',
    },
    nest: () {
      builder.element(
        'sheetViews',
        nest: () {
          builder.element('sheetView', attributes: {'workbookViewId': '0'});
        },
      );
      builder.element('sheetFormatPr', attributes: {'defaultRowHeight': '15'});
      builder.element(
        'cols',
        nest: () {
          final widths = <double>[18, 30, 14, 14, 14, 16, 16, 16, 12];
          for (var i = 0; i < widths.length; i++) {
            builder.element(
              'col',
              attributes: {
                'min': '${i + 1}',
                'max': '${i + 1}',
                'width': widths[i].toStringAsFixed(2),
                'customWidth': '1',
              },
            );
          }
        },
      );
      builder.element(
        'sheetData',
        nest: () {
          for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
            final row = rows[rowIndex];
            builder.element(
              'row',
              attributes: {'r': '${rowIndex + 1}'},
              nest: () {
                for (
                  var columnIndex = 0;
                  columnIndex < row.length;
                  columnIndex++
                ) {
                  final cell = row[columnIndex];
                  final ref =
                      '${_salesLedgerColumnName(columnIndex + 1)}${rowIndex + 1}';
                  builder.element(
                    'c',
                    attributes: {
                      'r': ref,
                      's': cell.styleIndex.toString(),
                      if (cell.isNumber) 't': 'n' else 't': 'inlineStr',
                    },
                    nest: () {
                      if (cell.isNumber) {
                        builder.element('v', nest: cell.value);
                      } else {
                        builder.element(
                          'is',
                          nest: () {
                            builder.element('t', nest: cell.value);
                          },
                        );
                      }
                    },
                  );
                }
              },
            );
          }
        },
      );
    },
  );
  return builder.buildDocument().toXmlString(pretty: false);
}

String _salesLedgerDetailWorksheetXml(List<List<_SalesLedgerExcelCell>> rows) {
  final builder = XmlBuilder();
  builder.processing('xml', 'version="1.0" encoding="UTF-8" standalone="yes"');
  builder.element(
    'worksheet',
    namespaces: <String, String>{
      'http://schemas.openxmlformats.org/spreadsheetml/2006/main': '',
    },
    nest: () {
      builder.element(
        'sheetViews',
        nest: () {
          builder.element('sheetView', attributes: {'workbookViewId': '0'});
        },
      );
      builder.element('sheetFormatPr', attributes: {'defaultRowHeight': '15'});
      builder.element(
        'cols',
        nest: () {
          final widths = <double>[16, 18, 26, 36, 14, 14];
          for (var i = 0; i < widths.length; i++) {
            builder.element(
              'col',
              attributes: {
                'min': '${i + 1}',
                'max': '${i + 1}',
                'width': widths[i].toStringAsFixed(2),
                'customWidth': '1',
              },
            );
          }
        },
      );
      builder.element(
        'sheetData',
        nest: () {
          for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
            final row = rows[rowIndex];
            builder.element(
              'row',
              attributes: {'r': '${rowIndex + 1}'},
              nest: () {
                for (
                  var columnIndex = 0;
                  columnIndex < row.length;
                  columnIndex++
                ) {
                  final cell = row[columnIndex];
                  final ref =
                      '${_salesLedgerColumnName(columnIndex + 1)}${rowIndex + 1}';
                  builder.element(
                    'c',
                    attributes: {
                      'r': ref,
                      's': cell.styleIndex.toString(),
                      if (cell.isNumber) 't': 'n' else 't': 'inlineStr',
                    },
                    nest: () {
                      if (cell.isNumber) {
                        builder.element('v', nest: cell.value);
                      } else {
                        builder.element(
                          'is',
                          nest: () {
                            builder.element('t', nest: cell.value);
                          },
                        );
                      }
                    },
                  );
                }
              },
            );
          }
        },
      );
    },
  );
  return builder.buildDocument().toXmlString(pretty: false);
}

String _salesLedgerColumnName(int index) {
  var value = index;
  final buffer = StringBuffer();
  while (value > 0) {
    final remainder = (value - 1) % 26;
    buffer.writeCharCode(65 + remainder);
    value = (value - 1) ~/ 26;
  }
  return buffer.toString().split('').reversed.join();
}

class _SalesLedgerExcelCell {
  const _SalesLedgerExcelCell._({
    required this.value,
    required this.isNumber,
    required this.styleIndex,
  });

  factory _SalesLedgerExcelCell.text(String value) =>
      _SalesLedgerExcelCell._(value: value, isNumber: false, styleIndex: 0);

  factory _SalesLedgerExcelCell.header(String value) =>
      _SalesLedgerExcelCell._(value: value, isNumber: false, styleIndex: 1);

  factory _SalesLedgerExcelCell.number(num value) => _SalesLedgerExcelCell._(
    value: AppFormatSettings.fixedNumber(value.toDouble()),
    isNumber: true,
    styleIndex: 2,
  );

  final String value;
  final bool isNumber;
  final int styleIndex;
}
