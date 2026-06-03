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
      pdfActionLabel: 'Email PDF',
      onPdfReady: (pdfBytes) async {
        final fileName =
            '${response.data!.payslipNo ?? 'payslip_${response.data!.id ?? payslipId}'}.pdf';
        final emailResponse = await hr.sendPayslipEmailPdf(
          payslipId,
          pdfBytes: pdfBytes,
          fileName: fileName,
        );
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(emailResponse.message)));
      },
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
  final earningsRows = payslip.earnings
      .map(
        (item) => <String, dynamic>{
          'label': item.label ?? '',
          'amount': item.amount ?? 0,
        },
      )
      .where((row) => (row['label']?.toString().trim().isNotEmpty ?? false))
      .toList(growable: false);
  final deductionRows = payslip.deductions
      .map(
        (item) => <String, dynamic>{
          'label': item.label ?? '',
          'amount': item.amount ?? 0,
        },
      )
      .where((row) => (row['label']?.toString().trim().isNotEmpty ?? false))
      .toList(growable: false);
  final printableEarnings = earningsRows.isNotEmpty
      ? earningsRows
      : <Map<String, dynamic>>[
          if ((payslip.basicSalary ?? 0) > 0)
            <String, dynamic>{
              'label': 'Basic Salary',
              'amount': payslip.basicSalary ?? 0,
            }
          else if (gross > 0)
            <String, dynamic>{'label': 'Gross Salary', 'amount': gross},
        ];
  final printableDeductions = deductionRows.isNotEmpty
      ? deductionRows
      : <Map<String, dynamic>>[
          if (deductions > 0)
            <String, dynamic>{
              'label': 'Total Deductions',
              'amount': deductions,
            },
        ];
  final employeeProfileData = <String, dynamic>{
    'employee_name': employee?.employeeName ?? payslip.employeeName ?? '',
    'employee_code': employee?.employeeCode ?? payslip.employeeCode ?? '',
    'department_name': employee?.departmentName ?? '',
    'designation_name': employee?.designationName ?? '',
    'joining_date': employee?.joiningDate ?? '',
    'salary_mode': employee?.salaryMode ?? '',
    'bank_account_no': employee?.bankAccountNo ?? '',
    'ifsc_code': employee?.ifscCode ?? '',
    'pf_uan_no': employee?.pfUanNo ?? '',
    'esi_no': employee?.esiNo ?? '',
    'mobile': employee?.mobile ?? '',
    'email': employee?.email ?? '',
  };

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
      'employee_profile': employeeProfileData,
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
      'earnings': printableEarnings,
      'deductions': printableDeductions,
    },
  );
}
