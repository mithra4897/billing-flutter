import '../../screen.dart';
import 'hr_workflow_dialogs.dart';

class PayrollRunDetailPage extends StatefulWidget {
  const PayrollRunDetailPage({
    super.key,
    required this.runId,
    required this.companyId,
    this.embedded = true,
  });

  final int runId;
  final int companyId;
  final bool embedded;

  @override
  State<PayrollRunDetailPage> createState() => _PayrollRunDetailPageState();
}

class _PayrollRunDetailPageState extends State<PayrollRunDetailPage> {
  final HrService _hr = HrService();
  PayrollRunModel? _run;
  String? _error;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final response = await _hr.payrollRun(widget.runId);
      if (!mounted) return;
      setState(() {
        _run = response.success == true ? response.data : null;
        _error = response.success == true ? null : response.message;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  void _backToRegister() {
    final navigate = ShellRouteScope.maybeOf(context);
    if (navigate != null) {
      navigate('/hr/payroll-runs');
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<bool> _confirmAction(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Continue'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _process() async {
    if (_run == null ||
        !await _confirmAction(
          'Process payroll',
          'Generate payroll lines and payslips for eligible employees?',
        )) {
      return;
    }
    await _runAction(() => _hr.processPayrollRun(
          widget.runId,
          PayrollRunModel.fromJson(const <String, dynamic>{}),
        ));
  }

  Future<void> _delete() async {
    if (_run == null ||
        !await _confirmAction(
          'Delete payroll run',
          'Delete this payroll run and its generated records?',
        )) {
      return;
    }
    await _runAction(() => _hr.deletePayrollRun(widget.runId));
  }

  Future<void> _runAction(Future<ApiResponse<dynamic>> Function() action) async {
    setState(() => _busy = true);
    try {
      final response = await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      if (response.success == true) {
        if (_run?.status == 'draft' || response.data == null) {
          _backToRegister();
        } else {
          await _load();
        }
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.displayMessage)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppLoadingView(message: 'Loading payroll run...');
    }
    if (_error != null || _run == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Unable to load payroll run',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
            Text(_error ?? 'Payroll run not found.'),
            const SizedBox(height: AppUiConstants.spacingMd),
            FilledButton(
              onPressed: _backToRegister,
              child: const Text('Back to payroll runs'),
            ),
          ],
        ),
      );
    }

    final run = _run!;
    final lines = run.lines;
    final preview = run.payrollPreview;
    final totalGross = lines.fold<double>(0, (sum, line) => sum + (line.grossSalary ?? 0));
    final totalDeductions = lines.fold<double>(0, (sum, line) => sum + (line.totalDeductions ?? 0));
    final totalNet = lines.fold<double>(0, (sum, line) => sum + (line.netSalary ?? 0));
    final status = run.status ?? '';

    return SizedBox(
      width: double.infinity,
      child: AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Payroll run #${widget.runId}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          Wrap(
            spacing: AppUiConstants.spacingSm,
            runSpacing: AppUiConstants.spacingSm,
            children: [
              _PayrollInfoChip(label: 'Period', value: run.periodLabel),
              _PayrollInfoChip(label: 'Run date', value: displayDate(run.runDate)),
              _PayrollInfoChip(label: 'Status', value: status.toUpperCase()),
              _PayrollInfoChip(label: 'Lines', value: '${run.linesCount ?? lines.length}'),
              _PayrollInfoChip(label: 'Gross', value: formatAmount(totalGross)),
              _PayrollInfoChip(label: 'Deductions', value: formatAmount(totalDeductions)),
              _PayrollInfoChip(label: 'Net', value: formatAmount(totalNet)),
            ],
          ),
          const SizedBox(height: AppUiConstants.spacingLg),
          Text(
            status == 'draft' ? 'Employees for this run' : 'Employee lines',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppUiConstants.spacingSm),
          Expanded(
            child: SingleChildScrollView(
              child: status == 'draft' && preview != null
                  ? PayrollRunEmployeeTable(employees: preview.employees)
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _processedTable(lines),
                    ),
            ),
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: AppUiConstants.spacingSm,
              children: [
              if (lines.isNotEmpty)
                FilledButton.tonal(
                  onPressed: () => ShellRouteScope.maybeOf(context)?.call(
                    '/hr/payslips?payroll_run_id=${widget.runId}',
                  ),
                  child: const Text('View payslips'),
                ),
              if (status == 'draft') ...[
                FilledButton.tonal(
                  onPressed: _busy
                      ? null
                      : () => openPayrollRunEditor(
                          context,
                          hr: _hr,
                          companyId: widget.companyId,
                          runId: widget.runId,
                          onSaved: () => _load(),
                        ),
                  child: const Text('Edit'),
                ),
                FilledButton(
                  onPressed: _busy ? null : _process,
                  child: const Text('Process'),
                ),
              ],
              if (status == 'draft' || status == 'processed')
                FilledButton(
                  onPressed: _busy ? null : _delete,
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _processedTable(List<PayrollLineModel> lines) {
    if (lines.isEmpty) return const Text('No payroll lines were generated.');
    return DataTable(
      columns: const [
        DataColumn(label: Text('Employee')),
        DataColumn(label: Text('Code')),
        DataColumn(label: Text('Gross')),
        DataColumn(label: Text('Deductions')),
        DataColumn(label: Text('Net')),
        DataColumn(label: Text('Paid days')),
        DataColumn(label: Text('LOP')),
      ],
      rows: lines.map((line) {
        return DataRow(cells: [
          DataCell(Text(line.employeeName ?? '—')),
          DataCell(Text(line.employeeCode ?? '—')),
          DataCell(Text(formatAmount(line.grossSalary ?? 0))),
          DataCell(Text(formatAmount(line.totalDeductions ?? 0))),
          DataCell(Text(formatAmount(line.netSalary ?? 0))),
          DataCell(Text('${formatAmount(line.paidDays ?? 0)}/${line.workingDays ?? 0}')),
          DataCell(Text(formatAmount(line.lopDays ?? 0))),
        ]);
      }).toList(growable: false),
    );
  }
}

class _PayrollInfoChip extends StatelessWidget {
  const _PayrollInfoChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label: $value'));
  }
}
