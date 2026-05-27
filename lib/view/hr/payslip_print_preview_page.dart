import '../../screen.dart';

Future<void> openPayslipPrintPreview(
  BuildContext context, {
  required HrService hr,
  required int payslipId,
}) async {
  try {
    final response = await hr.payslip(payslipId);
    if (!context.mounted) {
      return;
    }
    if (response.success != true || response.data == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      return;
    }
    await openDocumentPrintDesigner(
      context,
      documentType: 'hr_payslip',
      title: 'Payslip',
      documentData: _payslipPrintData(response.data!),
    );
  } catch (e) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(e.toString())));
  }
}

DocumentPrintDataModel _payslipPrintData(PayslipModel payslip) {
  final company = payslip.company;
  final employee = payslip.employeeProfile;
  final gross = payslip.grossSalary ?? 0;
  final deductions = payslip.totalDeductions ?? 0;
  final net = payslip.netSalary ?? 0;

  return DocumentPrintDataModel(
    companyName: company?.name ?? company?.legalName ?? '',
    companyLogoUrl: AppConfig.resolvePublicFileUrl(company?.logoPath) ?? '',
    companyGstin: company?.gstin ?? '',
    documentNumber: payslip.payslipNo ?? 'PAYSLIP-${payslip.id ?? ''}',
    documentDate: payslip.payslipDate ?? '',
    referenceNumber: payslip.payrollPeriodLabel,
    partyName: employee?.employeeName ?? payslip.employeeName ?? '',
    partyAddress: company?.address ?? '',
    partyContact: company?.phone ?? '',
    partyGstin: employee?.employeeCode ?? payslip.employeeCode ?? '',
    notes: payslip.remarks ?? '',
    termsConditions: 'System generated payslip.',
    subtotal: gross,
    taxAmount: 0,
    totalAmount: net,
    amountInWords: printTemplateAmountInWords(net, 'INR'),
    extraData: <String, dynamic>{
      'employee_profile': employee?.toJson() ?? <String, dynamic>{},
      'attendance': <String, dynamic>{
        'working_days': payslip.workingDays ?? 0,
        'present_days': payslip.presentDays ?? 0,
        'leave_days': payslip.leaveDays ?? 0,
        'paid_days': payslip.paidDays ?? 0,
        'lop_days': payslip.lopDays ?? 0,
      },
      'salary_summary': <String, dynamic>{
        'basic_salary': payslip.basicSalary ?? 0,
        'gross_salary': gross,
        'total_deductions': deductions,
        'ctc_monthly': payslip.ctcMonthly ?? 0,
        'net_salary': net,
      },
      'earnings': payslip.earnings
          .map(
            (item) => <String, dynamic>{
              'label': item.label ?? '',
              'amount': item.amount ?? 0,
            },
          )
          .toList(growable: false),
      'deductions': payslip.deductions
          .map(
            (item) => <String, dynamic>{
              'label': item.label ?? '',
              'amount': item.amount ?? 0,
            },
          )
          .toList(growable: false),
    },
  );
}
