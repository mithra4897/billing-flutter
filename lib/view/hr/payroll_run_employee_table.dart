import '../../screen.dart';

class PayrollRunEmployeeTable extends StatelessWidget {
  const PayrollRunEmployeeTable({
    super.key,
    required this.employees,
  });

  final List<PayrollEmployeePreviewModel> employees;

  Color _statusColor(BuildContext context, PayrollEmployeePreviewModel employee) {
    if (employee.eligible) {
      return Colors.green;
    }
    final reason = (employee.reason ?? '').toLowerCase();
    return reason.contains('salary component') ||
            reason.contains('gross salary') ||
            reason.contains('structure')
        ? Theme.of(context).colorScheme.error
        : Colors.orange.shade700;
  }

  String _statusLabel(PayrollEmployeePreviewModel employee) {
    if (employee.eligible) return 'Eligible';
    final reason = employee.reason?.trim();
    return reason == null || reason.isEmpty ? 'Attention' : 'Blocked';
  }

  @override
  Widget build(BuildContext context) {
    if (employees.isEmpty) {
      return const Text('No employees found for this company.');
    }

    return SizedBox(
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
          columnSpacing: 28,
          headingRowColor: WidgetStatePropertyAll(
            Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          columns: const [
            DataColumn(label: Text('Employee')),
            DataColumn(label: Text('Code')),
            DataColumn(label: Text('Eligibility')),
            DataColumn(label: Text('Gross')),
            DataColumn(label: Text('Paid days')),
            DataColumn(label: Text('LOP')),
            DataColumn(label: Text('Details')),
          ],
              rows: employees.map((employee) {
            final color = _statusColor(context, employee);
            return DataRow(
              color: WidgetStatePropertyAll(color.withValues(alpha: 0.08)),
              cells: [
                DataCell(Text(employee.employeeName ?? '—')),
                DataCell(Text(employee.employeeCode ?? '—')),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withValues(alpha: 0.45)),
                    ),
                    child: Text(
                      _statusLabel(employee),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                DataCell(Text(formatAmount(employee.grossSalary ?? 0))),
                DataCell(
                  Text(
                    '${formatAmount(employee.paidDays ?? 0)}/${employee.workingDays ?? 0}',
                  ),
                ),
                DataCell(Text(formatAmount(employee.lopDays ?? 0))),
                DataCell(
                  SizedBox(
                    width: 360,
                    child: Text(
                      employee.eligible
                          ? 'Ready for payroll processing'
                          : employee.reason ?? 'Payroll setup needs attention.',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            );
              }).toList(growable: false),
            ),
          ),
        ),
      ),
    );
  }
}
