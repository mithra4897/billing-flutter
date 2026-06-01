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
        AppDropdownItem(value: 'payable', label: 'Payable'),
        AppDropdownItem(value: 'excess_paid', label: 'Excess Paid'),
        AppDropdownItem(value: 'settled', label: 'Settled'),
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
              (_balanceFilter == 'payable' && row.payableAmount > 0) ||
              (_balanceFilter == 'excess_paid' && row.excessPaidAmount > 0) ||
              (_balanceFilter == 'settled' && row.outstanding == 0);
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
            final account = _preferredEmployeeAccount(
              employeeAccounts[item.id!] ?? const <EmployeeAccountModel>[],
            );
            return _EmployeeLedgerRegisterRow(
              employeeId: item.id!,
              employeeCode: item.employeeCode ?? '',
              employeeName: item.employeeName ?? '',
              departmentName: item.departmentName ?? '',
              ledgerCode: account?.accountCode ?? '',
              ledgerName: account?.accountName ?? '',
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
          label: 'Ledger Code',
          valueBuilder: (row) => row.ledgerCode,
        ),
        PurchaseRegisterColumn(
          label: 'Ledger Name',
          flex: 3,
          valueBuilder: (row) => row.ledgerName,
        ),
        PurchaseRegisterColumn(
          label: 'Department',
          valueBuilder: (row) => row.departmentName,
        ),
        PurchaseRegisterColumn(
          label: 'Payable',
          valueBuilder: (row) =>
              _formatEmployeeRegisterAmount(row.payableAmount),
        ),
        PurchaseRegisterColumn(
          label: 'Excess Paid',
          valueBuilder: (row) =>
              _formatEmployeeRegisterAmount(row.excessPaidAmount),
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
  final HrService _hrService = HrService();
  final ScrollController _scrollController = ScrollController();

  bool _loading = true;
  String? _errorMessage;
  EmployeeModel? _employee;
  EmployeeAccountModel? _account;
  List<LedgerStatementRowData> _statementRows =
      const <LedgerStatementRowData>[];
  double _salaryTotal = 0;
  double _reimbursementTotal = 0;
  String _lastSalaryPostingDate = '';
  String _lastReimbursementDate = '';

  double get _outstanding => _salaryTotal - _reimbursementTotal;

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
        _hrService.payslips(
          filters: <String, dynamic>{
            'employee_id': widget.employeeId,
            'per_page': 200,
            'sort_by': 'payslip_date',
            'sort_order': 'desc',
          },
        ),
        _hrService.expenseClaims(
          filters: <String, dynamic>{
            'employee_id': widget.employeeId,
            'per_page': 200,
            'sort_by': 'claim_date',
            'sort_order': 'desc',
          },
        ),
      ]);

      final employee = (responses[0] as ApiResponse<EmployeeModel>).data;
      final accounts =
          (responses[1] as ApiResponse<List<EmployeeAccountModel>>).data ??
          const <EmployeeAccountModel>[];
      final payslips =
          (responses[2] as PaginatedResponse<PayslipModel>).data ??
          const <PayslipModel>[];
      final claims =
          (responses[3] as PaginatedResponse<ExpenseClaimModel>).data ??
          const <ExpenseClaimModel>[];

      if (employee == null) {
        throw Exception('Employee ledger record not found.');
      }

      final preferredAccount = _preferredEmployeeAccount(accounts);
      final reimbursedClaims = claims
          .where((claim) {
            return claim.reimbursementVoucherId != null ||
                (claim.reimbursedAt?.trim().isNotEmpty ?? false);
          })
          .toList(growable: false);

      final statementRows = <_StatementRowSortWrapper>[
        for (final payslip in payslips)
          _StatementRowSortWrapper(
            sortDate: payslip.payslipDate ?? payslip.runDate ?? '',
            row: LedgerStatementRowData(
              date: displayDate(payslip.payslipDate ?? payslip.runDate),
              code: (payslip.payslipNo?.trim().isNotEmpty ?? false)
                  ? payslip.payslipNo!.trim()
                  : 'PS-${payslip.id ?? ''}',
              ledgerName:
                  preferredAccount?.accountName ??
                  preferredAccount?.accountCode ??
                  'Employee Payable',
              cashBankLedger: 'Salary Payable',
              credit: _formatLedgerAmount(payslip.netSalary ?? 0),
              debit: '',
            ),
          ),
        for (final claim in reimbursedClaims)
          _StatementRowSortWrapper(
            sortDate: claim.reimbursedAt ?? claim.claimDate ?? '',
            row: LedgerStatementRowData(
              date: displayDate(claim.reimbursedAt ?? claim.claimDate),
              code: (claim.claimNo?.trim().isNotEmpty ?? false)
                  ? claim.claimNo!.trim()
                  : 'EC-${claim.id ?? ''}',
              ledgerName:
                  preferredAccount?.accountName ??
                  preferredAccount?.accountCode ??
                  'Employee Payable',
              cashBankLedger: 'Reimbursement Payment',
              credit: '',
              debit: _formatLedgerAmount(claim.totalAmount ?? 0),
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
        _employee = employee;
        _account = preferredAccount;
        _statementRows = statementRows
            .map((item) => item.row)
            .toList(growable: false);
        _salaryTotal = payslips.fold<double>(
          0,
          (sum, item) => sum + (item.netSalary ?? 0),
        );
        _lastSalaryPostingDate = payslips.fold<String>('', (latest, item) {
          final value = item.payslipDate ?? item.runDate ?? '';
          return value.compareTo(latest) > 0 ? value : latest;
        });
        _reimbursementTotal = reimbursedClaims.fold<double>(
          0,
          (sum, item) => sum + (item.totalAmount ?? 0),
        );
        _lastReimbursementDate = reimbursedClaims.fold<String>('', (
          latest,
          item,
        ) {
          final value = item.reimbursedAt ?? item.claimDate ?? '';
          return value.compareTo(latest) > 0 ? value : latest;
        });
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
                  label: 'Ledger Code',
                  value: _account?.accountCode ?? '-',
                ),
                _EmployeeSummaryTile(
                  label: 'Ledger Name',
                  value: _account?.accountName ?? '-',
                  width: 260,
                ),
                _EmployeeSummaryTile(
                  label: 'Net Salary Total',
                  value: _formatLedgerAmount(_salaryTotal),
                ),
                _EmployeeSummaryTile(
                  label: 'Reimbursements',
                  value: _formatLedgerAmount(_reimbursementTotal),
                ),
                _EmployeeSummaryTile(
                  label: _employeeBalanceLabel(_outstanding),
                  value: _formatLedgerAmount(_outstanding.abs()),
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
                'No payslips or reimbursed claims were found for this employee ledger.',
          ),
        ],
      ),
    );
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

  double get outstanding => salaryTotal - reimbursementTotal;
  double get payableAmount => outstanding > 0 ? outstanding : 0;
  double get excessPaidAmount => outstanding < 0 ? outstanding.abs() : 0;
}

class _StatementRowSortWrapper {
  const _StatementRowSortWrapper({required this.sortDate, required this.row});

  final String sortDate;
  final LedgerStatementRowData row;
}

EmployeeAccountModel? _preferredEmployeeAccount(
  List<EmployeeAccountModel> accounts,
) {
  if (accounts.isEmpty) {
    return null;
  }

  EmployeeAccountModel? firstActive;
  EmployeeAccountModel? salaryPurpose;
  EmployeeAccountModel? defaultAccount;

  for (final account in accounts) {
    if (!account.isActive) {
      continue;
    }
    firstActive ??= account;
    if (account.isDefault) {
      defaultAccount ??= account;
    }
    if ((account.accountPurpose ?? '').toLowerCase() == 'salary') {
      salaryPurpose ??= account;
    }
  }

  return salaryPurpose ?? defaultAccount ?? firstActive ?? accounts.first;
}

String _formatLedgerAmount(double value) => value.toStringAsFixed(2);

String _formatEmployeeRegisterAmount(double value) {
  if (value == 0) {
    return '';
  }
  return value.toStringAsFixed(2);
}

String _employeeBalanceLabel(double value) {
  if (value > 0) {
    return 'Amount Payable';
  }
  if (value < 0) {
    return 'Excess Paid';
  }
  return 'Settled Balance';
}
