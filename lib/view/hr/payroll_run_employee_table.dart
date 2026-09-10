import '../../screen.dart';

class PayrollRunEmployeeTable extends StatelessWidget {
  const PayrollRunEmployeeTable({
    super.key,
    this.employees = const [],
    this.lines = const [],
  });

  final List<PayrollEmployeePreviewModel> employees;
  final List<PayrollLineModel> lines;

  @override
  Widget build(BuildContext context) {
    final rows = lines.isNotEmpty
        ? lines
              .map(
                (line) => <String, dynamic>{
                  ...line.toJson(),
                  'gross_salary': line.monthlyGrossSalary,
                  'earned_gross': line.grossSalary,
                  'lop_amount': line.calculationDetails['notional_lop_amount'],
                },
              )
              .toList(growable: false)
        : employees
              .map((employee) => employee.toJson())
              .toList(growable: false);
    String number(Map<String, dynamic> row, String key) {
      final amount = JsonModel.nullableDouble(row[key]);
      return amount == null ? '—' : amount.toStringAsFixed(2);
    }

    return SizedBox(
      width: double.infinity,
      child: SharedRegisterList<Map<String, dynamic>>(
        title: 'Employee payroll',
        embedded: true,
        contentSized: true,
        loading: false,
        errorMessage: null,
        onRetry: () async {},
        actions: const [],
        rows: rows,
        emptyMessage: 'No employee payroll details available.',
        onRowTap: (_) {},
        columns: [
          PurchaseRegisterColumn<Map<String, dynamic>>(
            label: 'Employee',
            flex: 2,
            valueBuilder: (r) => r['employee_name']?.toString() ?? '—',
            detailBuilder: (r) => [
              r['employee_code']?.toString() ?? '—',
              if (r['reason'] != null) r['reason'].toString(),
            ].join(' · '),
          ),
          for (final entry in const {
            'gross_salary': 'Salary',
            'earned_gross': 'Earned gross',
            'lop_days': 'LOP days',
            'lop_amount': 'LOP amount',
            'total_deductions': 'Deductions',
            'net_salary': 'Net pay',
            'paid_days': 'Paid days',
            'working_days': 'Working days',
            'present_days': 'Present',
            'leave_days': 'Leave',
          }.entries)
            PurchaseRegisterColumn<Map<String, dynamic>>(
              label: entry.value,
              alignRight: true,
              valueBuilder: (r) => number(r, entry.key),
            ),
        ],
      ),
    );
  }
}
