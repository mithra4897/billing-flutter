import '../../screen.dart';

void _openEmployeeLedgerRoute(BuildContext context, String route) {
  final navigate = ShellRouteScope.maybeOf(context);
  if (navigate != null) {
    navigate(route);
    return;
  }
  Navigator.of(context).pushNamed(route);
}

class EmployeeLedgerRegisterPage extends StatefulWidget {
  const EmployeeLedgerRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<EmployeeLedgerRegisterPage> createState() =>
      _EmployeeLedgerRegisterPageState();
}

class _EmployeeLedgerRegisterPageState
    extends State<EmployeeLedgerRegisterPage> {
  static const List<AppDropdownItem<String>> _statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: '', label: 'All status'),
        AppDropdownItem(value: 'active', label: 'Active'),
        AppDropdownItem(value: 'inactive', label: 'Inactive'),
      ];
  static const List<AppDropdownItem<String>> _balanceItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: '', label: 'All balances'),
        AppDropdownItem(value: 'salary_posted', label: 'Salary Posted'),
        AppDropdownItem(value: 'reimbursed', label: 'Reimbursed'),
        AppDropdownItem(value: 'no_activity', label: 'No Activity'),
      ];

  final HrService _hrService = HrService();
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  String? _errorMessage;
  String _status = '';
  String _balanceFilter = '';
  List<_EmployeeLedgerRegisterRow> _rows = const <_EmployeeLedgerRegisterRow>[];

  List<_EmployeeLedgerRegisterRow> get _filteredRows {
    final query = _searchController.text.trim().toLowerCase();
    return _rows
        .where((row) {
          final statusOk =
              _status.isEmpty ||
              (_status == 'active'
                  ? row.status.toLowerCase() == 'active'
                  : row.status.toLowerCase() != 'active');
          final balanceOk =
              _balanceFilter.isEmpty ||
              (_balanceFilter == 'salary_posted' && row.hasSalaryActivity) ||
              (_balanceFilter == 'reimbursed' &&
                  row.hasReimbursementActivity) ||
              (_balanceFilter == 'no_activity' && !row.hasAnyActivity);
          final searchOk =
              query.isEmpty ||
              [
                row.employeeCode,
                row.employeeName,
                row.ledgerCode,
                row.ledgerName,
                row.departmentName,
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
        _hrService.employees(
          filters: const <String, dynamic>{
            'per_page': 100,
            'sort_by': 'employee_name',
          },
        ),
        _hrService.payslips(
          filters: const <String, dynamic>{
            'per_page': 200,
            'sort_by': 'payslip_date',
            'sort_order': 'desc',
          },
        ),
        _hrService.expenseClaims(
          filters: const <String, dynamic>{
            'per_page': 200,
            'sort_by': 'claim_date',
            'sort_order': 'desc',
          },
        ),
      ]);

      final employees =
          (responses[0] as PaginatedResponse<EmployeeModel>).data ??
          const <EmployeeModel>[];
      final payslips =
          (responses[1] as PaginatedResponse<PayslipModel>).data ??
          const <PayslipModel>[];
      final expenseClaims =
          (responses[2] as PaginatedResponse<ExpenseClaimModel>).data ??
          const <ExpenseClaimModel>[];

      final employeeIds = employees
          .where((item) => item.id != null)
          .map((item) => item.id!)
          .toList(growable: false);

      final accountResponses =
          await Future.wait<ApiResponse<List<EmployeeAccountModel>>>(
            employeeIds.map(_hrService.employeeAccounts),
          );

      final employeeAccounts = <int, List<EmployeeAccountModel>>{};
      for (var i = 0; i < employeeIds.length; i++) {
        employeeAccounts[employeeIds[i]] =
            accountResponses[i].data ?? const <EmployeeAccountModel>[];
      }

      final salaryTotals = <int, double>{};
      final reimbursementTotals = <int, double>{};
      final lastPayslipDates = <int, String>{};
      final lastReimbursementDates = <int, String>{};

      for (final payslip in payslips) {
        final employeeId = payslip.employeeId;
        if (employeeId == null) {
          continue;
        }
        salaryTotals[employeeId] =
            (salaryTotals[employeeId] ?? 0) + (payslip.netSalary ?? 0);
        final payslipDate = payslip.payslipDate?.trim().isNotEmpty == true
            ? payslip.payslipDate!
            : (payslip.runDate ?? '');
        final currentLastDate = lastPayslipDates[employeeId] ?? '';
        if (payslipDate.compareTo(currentLastDate) > 0) {
          lastPayslipDates[employeeId] = payslipDate;
        }
      }

      for (final claim in expenseClaims) {
        final employeeId = claim.employeeId;
        if (employeeId == null) {
          continue;
        }
        final reimbursed =
            claim.reimbursementVoucherId != null ||
            (claim.reimbursedAt?.trim().isNotEmpty ?? false);
        if (!reimbursed) {
          continue;
        }
        reimbursementTotals[employeeId] =
            (reimbursementTotals[employeeId] ?? 0) + (claim.totalAmount ?? 0);
        final reimbursementDate = claim.reimbursedAt?.trim().isNotEmpty == true
            ? claim.reimbursedAt!
            : (claim.claimDate ?? '');
        final currentLastDate = lastReimbursementDates[employeeId] ?? '';
        if (reimbursementDate.compareTo(currentLastDate) > 0) {
          lastReimbursementDates[employeeId] = reimbursementDate;
        }
      }

      final nextRows = employees
          .where((item) => item.id != null)
          .map((item) {
            final accounts =
                employeeAccounts[item.id!] ?? const <EmployeeAccountModel>[];
            final salaryAccount = _preferredEmployeeAccount(
              accounts,
              preferredPurposes: const <String>['payable'],
            );
            return _EmployeeLedgerRegisterRow(
              employeeId: item.id!,
              employeeCode: item.employeeCode ?? '',
              employeeName: item.employeeName ?? '',
              departmentName: item.departmentName ?? '',
              ledgerCode: salaryAccount?.accountCode ?? '',
              ledgerName: salaryAccount?.accountName ?? '',
              status: (item.status ?? 'active').titleCase,
              salaryTotal: salaryTotals[item.id!] ?? 0,
              reimbursementTotal: reimbursementTotals[item.id!] ?? 0,
              lastPayslipDate: lastPayslipDates[item.id!] ?? '',
              lastReimbursementDate: lastReimbursementDates[item.id!] ?? '',
            );
          })
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
    return PurchaseRegisterPage<_EmployeeLedgerRegisterRow>(
      title: 'Employee Ledger',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _errorMessage,
      onRetry: _loadRows,
      emptyMessage: 'No employee ledgers found.',
      actions: [
        AdaptiveShellActionButton(
          onPressed: _loadRows,
          icon: Icons.refresh_outlined,
          label: 'Refresh',
          filled: false,
        ),
      ],
      filters: _EmployeeLedgerFilters(
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
          label: 'Employee Code',
          valueBuilder: (row) => row.employeeCode,
        ),
        PurchaseRegisterColumn(
          label: 'Employee Name',
          flex: 3,
          valueBuilder: (row) => row.employeeName,
        ),
        PurchaseRegisterColumn(
          label: 'Salary Ledger Code',
          valueBuilder: (row) => row.ledgerCode,
        ),
        PurchaseRegisterColumn(
          label: 'Salary Ledger Name',
          flex: 3,
          valueBuilder: (row) => row.ledgerName,
        ),
        PurchaseRegisterColumn(
          label: 'Department',
          valueBuilder: (row) => row.departmentName,
        ),
        PurchaseRegisterColumn(
          label: 'Salary Posted',
          valueBuilder: (row) => _formatEmployeeRegisterAmount(row.salaryTotal),
        ),
        PurchaseRegisterColumn(
          label: 'Reimbursed',
          valueBuilder: (row) =>
              _formatEmployeeRegisterAmount(row.reimbursementTotal),
        ),
        PurchaseRegisterColumn(
          label: 'Last Salary Posting',
          valueBuilder: (row) => displayDate(row.lastPayslipDate),
        ),
        PurchaseRegisterColumn(
          label: 'Last Reimbursement',
          valueBuilder: (row) => displayDate(row.lastReimbursementDate),
        ),
        PurchaseRegisterColumn(
          label: 'Status',
          valueBuilder: (row) => row.status,
        ),
      ],
      onRowTap: (row) => _openEmployeeLedgerRoute(
        context,
        '/hr/employee-ledgers/${row.employeeId}',
      ),
    );
  }
}

class EmployeeLedgerDetailPage extends StatefulWidget {
  const EmployeeLedgerDetailPage({
    super.key,
    required this.employeeId,
    this.embedded = false,
  });

  final int employeeId;
  final bool embedded;

  @override
  State<EmployeeLedgerDetailPage> createState() =>
      _EmployeeLedgerDetailPageState();
}

class _EmployeeLedgerDetailPageState extends State<EmployeeLedgerDetailPage> {
  final AccountsService _accountsService = AccountsService();
  final HrService _hrService = HrService();
  final ScrollController _scrollController = ScrollController();

  bool _loading = true;
  String? _errorMessage;
  EmployeeModel? _employee;
  EmployeeAccountModel? _payableAccount;
  EmployeeAccountModel? _reimbursementAccount;
  List<LedgerStatementRowData> _statementRows =
      const <LedgerStatementRowData>[];
  double _openingBalance = 0;
  double _totalDebit = 0;
  double _totalCredit = 0;
  double _closingBalance = 0;
  String _lastSalaryPostingDate = '';
  String _lastReimbursementDate = '';

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
      final responses = await Future.wait<dynamic>([
        _hrService.employee(widget.employeeId),
        _hrService.employeeAccounts(widget.employeeId),
      ]);

      final employee = (responses[0] as ApiResponse<EmployeeModel>).data;
      final accounts =
          (responses[1] as ApiResponse<List<EmployeeAccountModel>>).data ??
          const <EmployeeAccountModel>[];

      if (employee == null) {
        throw Exception('Employee ledger record not found.');
      }
      if (employee.companyId == null) {
        throw Exception('Employee company is not configured.');
      }

      final payableAccount = _preferredEmployeeAccount(
        accounts,
        preferredPurposes: const <String>['payable'],
      );
      final reimbursementAccount = _preferredEmployeeAccount(
        accounts,
        preferredPurposes: const <String>['reimbursement'],
      );
      final salaryReport = payableAccount?.accountId == null
          ? const <String, dynamic>{}
          : await _loadGeneralLedgerReport(
              companyId: employee.companyId!,
              accountId: payableAccount!.accountId!,
            );
      final reimbursementReport = reimbursementAccount?.accountId == null
          ? const <String, dynamic>{}
          : await _loadGeneralLedgerReport(
              companyId: employee.companyId!,
              accountId: reimbursementAccount!.accountId!,
            );

      final salarySummary = _employeeLedgerMap(salaryReport['summary']);
      final reimbursementSummary = _employeeLedgerMap(
        reimbursementReport['summary'],
      );
      final salaryLines = _employeeLedgerList(salaryReport['lines']);
      final reimbursementLines = _employeeLedgerList(
        reimbursementReport['lines'],
      );
      final statementRows = <_StatementRowSortWrapper>[
        ..._employeeStatementRows(
          salaryLines,
          ledgerName:
              payableAccount?.accountName ??
              payableAccount?.accountCode ??
              'Employee Payable',
        ),
        ..._employeeStatementRows(
          reimbursementLines,
          ledgerName:
              reimbursementAccount?.accountName ??
              reimbursementAccount?.accountCode ??
              'Employee Reimbursement Payable',
        ),
      ]..sort((left, right) => right.sortDate.compareTo(left.sortDate));

      if (!mounted) {
        return;
      }

      setState(() {
        _employee = employee;
        _payableAccount = payableAccount;
        _reimbursementAccount = reimbursementAccount;
        _statementRows = statementRows
            .map((item) => item.row)
            .toList(growable: false);
        _openingBalance =
            _employeeLedgerDouble(salarySummary['opening_balance']) +
            _employeeLedgerDouble(reimbursementSummary['opening_balance']);
        _totalDebit =
            _employeeLedgerDouble(salarySummary['total_debit']) +
            _employeeLedgerDouble(reimbursementSummary['total_debit']);
        _totalCredit =
            _employeeLedgerDouble(salarySummary['total_credit']) +
            _employeeLedgerDouble(reimbursementSummary['total_credit']);
        _closingBalance =
            _employeeLedgerDouble(salarySummary['closing_balance']) +
            _employeeLedgerDouble(reimbursementSummary['closing_balance']);
        _lastSalaryPostingDate = salaryLines.isEmpty
            ? ''
            : salaryLines.last['voucher_date']?.toString() ?? '';
        _lastReimbursementDate = reimbursementLines.isEmpty
            ? ''
            : reimbursementLines.last['voucher_date']?.toString() ?? '';
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
      title: 'Employee Ledger',
      scrollController: _scrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_loading) {
      return const AppLoadingView(message: 'Loading employee ledger...');
    }

    if (_errorMessage != null) {
      return AppErrorStateView(
        title: 'Unable to load employee ledger',
        message: _errorMessage!,
        onRetry: _loadDetail,
      );
    }

    final employee = _employee;
    if (employee == null) {
      return AppErrorStateView(
        title: 'Employee ledger unavailable',
        message: 'No employee ledger record was found for this entry.',
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
                _EmployeeSummaryTile(
                  label: 'Employee',
                  value: employee.employeeName ?? '-',
                  width: 280,
                ),
                _EmployeeSummaryTile(
                  label: 'Employee Code',
                  value: employee.employeeCode ?? '-',
                ),
                _EmployeeSummaryTile(
                  label: 'Department',
                  value: employee.departmentName ?? '-',
                ),
                _EmployeeSummaryTile(
                  label: 'Salary Ledger Code',
                  value: _payableAccount?.accountCode ?? '-',
                ),
                _EmployeeSummaryTile(
                  label: 'Salary Ledger Name',
                  value: _payableAccount?.accountName ?? '-',
                  width: 260,
                ),
                _EmployeeSummaryTile(
                  label: 'Reimbursement Ledger Code',
                  value: _reimbursementAccount?.accountCode ?? '-',
                ),
                _EmployeeSummaryTile(
                  label: 'Reimbursement Ledger Name',
                  value: _reimbursementAccount?.accountName ?? '-',
                  width: 260,
                ),
                _EmployeeSummaryTile(
                  label: 'Opening Balance',
                  value: _formatLedgerAmount(_openingBalance),
                ),
                _EmployeeSummaryTile(
                  label: 'Total Debit',
                  value: _formatLedgerAmount(_totalDebit),
                ),
                _EmployeeSummaryTile(
                  label: 'Total Credit',
                  value: _formatLedgerAmount(_totalCredit),
                ),
                _EmployeeSummaryTile(
                  label: 'Closing Balance',
                  value: _formatLedgerAmount(_closingBalance),
                ),
                _EmployeeSummaryTile(
                  label: 'Ledger Coverage',
                  value: _employeeLedgerCoverageLabel(
                    _payableAccount,
                    _reimbursementAccount,
                  ),
                ),
                _EmployeeSummaryTile(
                  label: 'Last Salary Posting',
                  value: displayDate(_lastSalaryPostingDate),
                ),
                _EmployeeSummaryTile(
                  label: 'Last Reimbursement',
                  value: displayDate(_lastReimbursementDate),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppUiConstants.spacingLg),
          LedgerStatementTable(
            title: 'Ledger Statement',
            rows: _statementRows,
            emptyMessage:
                'No posted accounting transactions were found for this employee ledger.',
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _loadGeneralLedgerReport({
    required int companyId,
    required int accountId,
  }) async {
    final response = await _accountsService.reportGeneralLedger(
      filters: <String, dynamic>{
        'company_id': companyId,
        'account_id': accountId,
        'date_from': _employeeLedgerHistoryDateFrom,
        'date_to': _employeeLedgerHistoryDateTo(),
      },
    );
    return response.data?.data ?? const <String, dynamic>{};
  }
}

class _EmployeeLedgerFilters extends StatelessWidget {
  const _EmployeeLedgerFilters({
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
            hintText: 'Employee, code, or ledger',
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

class _EmployeeSummaryTile extends StatelessWidget {
  const _EmployeeSummaryTile({
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

class _EmployeeLedgerRegisterRow {
  const _EmployeeLedgerRegisterRow({
    required this.employeeId,
    required this.employeeCode,
    required this.employeeName,
    required this.departmentName,
    required this.ledgerCode,
    required this.ledgerName,
    required this.status,
    required this.salaryTotal,
    required this.reimbursementTotal,
    required this.lastPayslipDate,
    required this.lastReimbursementDate,
  });

  final int employeeId;
  final String employeeCode;
  final String employeeName;
  final String departmentName;
  final String ledgerCode;
  final String ledgerName;
  final String status;
  final double salaryTotal;
  final double reimbursementTotal;
  final String lastPayslipDate;
  final String lastReimbursementDate;

  bool get hasSalaryActivity => salaryTotal > 0;
  bool get hasReimbursementActivity => reimbursementTotal > 0;
  bool get hasAnyActivity => hasSalaryActivity || hasReimbursementActivity;
}

class _StatementRowSortWrapper {
  const _StatementRowSortWrapper({required this.sortDate, required this.row});

  final String sortDate;
  final LedgerStatementRowData row;
}

const String _employeeLedgerHistoryDateFrom = '2000-01-01';

EmployeeAccountModel? _preferredEmployeeAccount(
  List<EmployeeAccountModel> accounts, {
  List<String> preferredPurposes = const <String>[],
}) {
  if (accounts.isEmpty) {
    return null;
  }

  EmployeeAccountModel? firstActive;
  EmployeeAccountModel? defaultAccount;
  final normalizedPreferredPurposes = preferredPurposes
      .map((item) => item.trim().toLowerCase())
      .where((item) => item.isNotEmpty)
      .toSet();
  final preferredMatches = <EmployeeAccountModel>[];

  for (final account in accounts) {
    if (!account.isActive) {
      continue;
    }
    firstActive ??= account;
    if (account.isDefault) {
      defaultAccount ??= account;
    }
    final purpose = (account.accountPurpose ?? '').trim().toLowerCase();
    if (normalizedPreferredPurposes.contains(purpose)) {
      preferredMatches.add(account);
    }
  }

  if (preferredMatches.isNotEmpty) {
    return preferredMatches.firstWhere(
      (account) => account.isDefault,
      orElse: () => preferredMatches.first,
    );
  }

  return defaultAccount ?? firstActive ?? accounts.first;
}

String _employeeLedgerHistoryDateTo() =>
    DateTime.now().toIso8601String().split('T').first;

Map<String, dynamic> _employeeLedgerMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, entry) => MapEntry(key.toString(), entry));
  }
  return const <String, dynamic>{};
}

List<Map<String, dynamic>> _employeeLedgerList(dynamic value) {
  if (value is! List) {
    return const <Map<String, dynamic>>[];
  }
  return value.map(_employeeLedgerMap).toList(growable: false);
}

double _employeeLedgerDouble(dynamic value) =>
    double.tryParse(value?.toString() ?? '') ?? 0;

List<_StatementRowSortWrapper> _employeeStatementRows(
  List<Map<String, dynamic>> lines, {
  required String ledgerName,
}) {
  return lines
      .map(
        (line) => _StatementRowSortWrapper(
          sortDate: line['voucher_date']?.toString() ?? '',
          row: LedgerStatementRowData(
            date: displayDate(line['voucher_date']?.toString()),
            code: _employeeLedgerCode(line),
            ledgerName: ledgerName,
            cashBankLedger: _employeeLedgerDescriptor(line),
            credit: _employeeLedgerAmountText(line['credit']),
            debit: _employeeLedgerAmountText(line['debit']),
          ),
        ),
      )
      .toList(growable: false);
}

String _employeeLedgerCode(Map<String, dynamic> line) {
  final voucherNo = line['voucher_no']?.toString().trim() ?? '';
  if (voucherNo.isNotEmpty) {
    return voucherNo;
  }
  final voucherId = line['voucher_id']?.toString().trim() ?? '';
  return voucherId.isEmpty ? '-' : 'V-$voucherId';
}

String _employeeLedgerDescriptor(Map<String, dynamic> line) {
  final parts = <String>[
    line['voucher_type']?.toString().trim() ?? '',
    line['reference_no']?.toString().trim() ?? '',
    line['narration']?.toString().trim() ?? '',
  ].where((item) => item.isNotEmpty).toList(growable: false);
  return parts.isEmpty ? '-' : parts.join(' · ');
}

String _employeeLedgerAmountText(dynamic value) {
  final amount = _employeeLedgerDouble(value);
  if (amount == 0) {
    return '';
  }
  return formatAmount(amount);
}

String _formatLedgerAmount(double value) => formatAmount(value);

String _formatEmployeeRegisterAmount(double value) {
  if (value == 0) {
    return '';
  }
  return formatAmount(value);
}

String _employeeLedgerCoverageLabel(
  EmployeeAccountModel? payableAccount,
  EmployeeAccountModel? reimbursementAccount,
) {
  final hasPayable = payableAccount != null;
  final hasReimbursement = reimbursementAccount != null;
  if (hasPayable && hasReimbursement) {
    return 'Salary + Reimbursement';
  }
  if (hasPayable) {
    return 'Salary only';
  }
  if (hasReimbursement) {
    return 'Reimbursement only';
  }
  return 'No active mapping';
}
