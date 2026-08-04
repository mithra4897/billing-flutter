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
      documentData: buildPayslipPrintData(response.data!),
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

Future<void> openPayslipTemplateDesigner(BuildContext context) {
  return openDocumentPrintDesigner(
    context,
    documentType: 'hr_payslip',
    title: 'Payslip',
    documentData: _payslipTemplateSampleData(),
  );
}

DocumentPrintDataModel _payslipTemplateSampleData() {
  const grossSalary = 30000.0;
  const totalDeductions = 1800.0;
  const netSalary = grossSalary - totalDeductions;

  return DocumentPrintDataModel(
    companyName: 'Your Company Name',
    companyGstin: 'GSTIN / Registration No.',
    documentNumber: 'PAYSLIP-SAMPLE',
    documentDate: '2026-08-31',
    referenceNumber: 'August 2026',
    partyName: 'Sample Employee',
    partyAddress: 'Company address',
    partyContact: 'Company contact number',
    partyGstin: 'EMP-001',
    termsConditions: 'This is a system generated payslip.',
    subtotal: grossSalary,
    totalAmount: netSalary,
    amountInWords: printTemplateAmountInWords(netSalary, 'INR'),
    extraData: const <String, dynamic>{
      'employee_profile': <String, dynamic>{
        'employee_name': 'Sample Employee',
        'employee_code': 'EMP-001',
        'department_name': 'Operations',
        'designation_name': 'Executive',
        'salary_mode': 'Monthly',
        'bank_account_no': 'XXXX1234',
        'ifsc_code': 'BANK0000123',
        'pf_uan_no': '100000000001',
        'esi_no': '1000000001',
        'mobile': '9000000000',
        'email': 'employee@example.com',
      },
      'attendance': <String, dynamic>{
        'working_days': 31,
        'present_days': 30,
        'leave_days': 1,
        'paid_days': 30,
        'lop_days': 0,
      },
      'salary_summary': <String, dynamic>{
        'basic_salary': 15000,
        'gross_salary': 30000,
        'total_deductions': 1800,
        'ctc_monthly': 36000,
        'net_salary': 28200,
      },
      'earnings': <Map<String, dynamic>>[
        <String, dynamic>{'label': 'Basic Salary', 'amount': 15000},
        <String, dynamic>{'label': 'House Rent Allowance', 'amount': 7500},
        <String, dynamic>{'label': 'Special Allowance', 'amount': 7500},
      ],
      'deductions': <Map<String, dynamic>>[
        <String, dynamic>{'label': 'Provident Fund', 'amount': 1800},
      ],
    },
  );
}

class DesignedPayslipEmailResult {
  const DesignedPayslipEmailResult({
    required this.sent,
    required this.failed,
    required this.skipped,
    required this.errors,
  });

  final int sent;
  final int failed;
  final int skipped;
  final List<String> errors;

  String get message {
    final summary =
        'Designed payslip emails: $sent sent, $failed failed, '
        '$skipped skipped.';
    return errors.isEmpty ? summary : '$summary ${errors.join(' ')}';
  }
}

Future<DesignedPayslipEmailResult> emailDesignedPayslipsForRun(
  BuildContext context, {
  required HrService hr,
  required int payrollRunId,
  required int companyId,
}) async {
  final listResponse = await hr.payslips(
    filters: <String, dynamic>{
      'payroll_run_id': payrollRunId,
      'company_id': companyId,
      'per_page': 500,
    },
  );
  if (listResponse.success != true) {
    throw Exception(listResponse.message);
  }

  var sent = 0;
  var failed = 0;
  var skipped = 0;
  final errors = <String>[];
  for (final summary in listResponse.data ?? const <PayslipModel>[]) {
    final payslipId = summary.id;
    if (payslipId == null) {
      skipped++;
      continue;
    }

    try {
      final detailResponse = await hr.payslip(payslipId);
      final payslip = detailResponse.data;
      if (detailResponse.success != true || payslip == null) {
        failed++;
        errors.add(
          '${summary.employeeName ?? 'Payslip $payslipId'}: '
          '${detailResponse.message}',
        );
        continue;
      }
      if (!context.mounted) {
        throw Exception('Payslip email operation was cancelled.');
      }

      final pdfBytes = await generateDocumentPrintPdf(
        context,
        documentType: 'hr_payslip',
        title: 'Payslip',
        documentData: buildPayslipPrintData(payslip),
      );
      if (pdfBytes == null || pdfBytes.isEmpty) {
        failed++;
        errors.add(
          '${payslip.employeeName ?? 'Payslip $payslipId'}: '
          'PDF generation failed.',
        );
        continue;
      }

      final fileName = '${payslip.payslipNo ?? 'payslip_$payslipId'}.pdf';
      final emailResponse = await hr.sendPayslipEmailPdf(
        payslipId,
        pdfBytes: pdfBytes,
        fileName: fileName,
      );
      if (emailResponse.success == true &&
          emailResponse.data?.status?.toLowerCase() == 'sent') {
        sent++;
      } else {
        failed++;
        errors.add(
          '${payslip.employeeName ?? fileName}: '
          '${emailResponse.data?.errorMessage ?? emailResponse.message}',
        );
      }
    } catch (error) {
      failed++;
      errors.add('${summary.employeeName ?? 'Payslip $payslipId'}: $error');
    }
  }

  return DesignedPayslipEmailResult(
    sent: sent,
    failed: failed,
    skipped: skipped,
    errors: errors,
  );
}

DocumentPrintDataModel buildPayslipPrintData(PayslipModel payslip) {
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
