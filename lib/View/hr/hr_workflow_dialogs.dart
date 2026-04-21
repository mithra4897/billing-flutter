import 'dart:convert';

import '../../screen.dart';
import '../purchase/purchase_support.dart';

/// Resolves the company saved in session (header). Returns null if none saved.
Future<({int? companyId, String? banner})> hrSessionCompanyInfo() async {
  final storedId = await SessionStorage.getCurrentCompanyId();
  if (storedId == null) {
    return (companyId: null, banner: null);
  }
  final master = MasterService();
  try {
    final companiesResp = await master.companies(
      filters: const {'per_page': 200, 'sort_by': 'legal_name'},
    );
    final companies = companiesResp.data ?? const <CompanyModel>[];
    for (final c in companies) {
      if (c.id == storedId) {
        return (companyId: storedId, banner: c.toString());
      }
    }
    return (companyId: storedId, banner: 'Company #$storedId');
  } catch (_) {
    return (companyId: storedId, banner: 'Company #$storedId');
  }
}

DateTime? tryParseFlexibleDateTime(String raw) {
  final t = raw.trim();
  if (t.isEmpty) {
    return null;
  }
  final isoTry = DateTime.tryParse(t);
  if (isoTry != null) {
    return isoTry;
  }
  final withT = DateTime.tryParse(t.replaceFirst(' ', 'T'));
  if (withT != null) {
    return withT;
  }
  final m = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2}):(\d{2})$',
  ).firstMatch(t);
  if (m != null) {
    return DateTime(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
      int.parse(m.group(4)!),
      int.parse(m.group(5)!),
      int.parse(m.group(6)!),
    );
  }
  return null;
}

String formatSqlLocalDateTime(DateTime dt) {
  final local = dt.isUtc ? dt.toLocal() : dt;
  String p2(int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${p2(local.month)}-${p2(local.day)} '
      '${p2(local.hour)}:${p2(local.minute)}:${p2(local.second)}';
}

/// Normalizes API datetime strings for the [DateTimeInputFormatter] field.
String _sqlDateTimeForInput(String? value) {
  if (value == null || value.trim().isEmpty) {
    return '';
  }
  var s = value.trim();
  if (s.contains('.')) {
    s = s.split('.').first;
  }
  s = s.replaceFirst('T', ' ');
  final parsed = tryParseFlexibleDateTime(s);
  if (parsed != null) {
    return formatSqlLocalDateTime(parsed);
  }
  return displayDateTime(value);
}

String? normalizeOptionalCheckInOut(String raw) {
  final t = raw.trim();
  if (t.isEmpty) {
    return null;
  }
  final parsed = tryParseFlexibleDateTime(t);
  if (parsed == null) {
    throw const FormatException('Invalid date/time');
  }
  return formatSqlLocalDateTime(parsed);
}

String? validateOptionalSqlDateTime(String? value, String fieldName) {
  final t = value?.trim() ?? '';
  if (t.isEmpty) {
    return null;
  }
  if (tryParseFlexibleDateTime(t) == null) {
    return '$fieldName: use YYYY-MM-DD HH:MM:SS (14 digits: date then time)';
  }
  return null;
}

List<AccountModel> filterCashBankPaymentAccounts(List<AccountModel> source) {
  return source
      .where(
        (a) =>
            a.id != null &&
            a.isActive &&
            (a.accountType == 'cash' || a.accountType == 'bank'),
      )
      .toList(growable: false);
}

const List<AppDropdownItem<String>> _attendanceStatusItems =
    <AppDropdownItem<String>>[
      AppDropdownItem(value: 'present', label: 'Present'),
      AppDropdownItem(value: 'absent', label: 'Absent'),
      AppDropdownItem(value: 'leave', label: 'Leave'),
      AppDropdownItem(value: 'half_day', label: 'Half day'),
      AppDropdownItem(value: 'holiday', label: 'Holiday'),
    ];

/// Requires a company already saved from the header session control.
Future<int?> hrResolveCompanyId(BuildContext context) async {
  final storedId = await SessionStorage.getCurrentCompanyId();
  if (storedId == null) {
    return null;
  }
  final master = MasterService();
  try {
    final companiesResp = await master.companies(
      filters: const {'per_page': 200, 'sort_by': 'legal_name'},
    );
    final active = (companiesResp.data ?? const <CompanyModel>[])
        .where((c) => c.isActive)
        .toList();
    if (active.isEmpty) {
      return null;
    }
    final ctx = await WorkingContextService.instance.resolveSelection(
      companies: active,
      branches: const <BranchModel>[],
      locations: const <BusinessLocationModel>[],
      financialYears: const <FinancialYearModel>[],
      companyId: storedId,
    );
    return ctx.companyId;
  } catch (_) {
    return null;
  }
}

Future<bool> _confirm(
  BuildContext context,
  String title,
  String message,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Continue'),
        ),
      ],
    ),
  );
  return ok == true;
}

Map<String, dynamic>? _map(dynamic v) {
  if (v is Map<String, dynamic>) {
    return v;
  }
  if (v is Map) {
    return Map<String, dynamic>.from(v);
  }
  return null;
}

Future<void> showPayslipDetailDialog(
  BuildContext context, {
  required HrService hr,
  required int id,
}) async {
  try {
    final response = await hr.payslip(id);
    if (!context.mounted) {
      return;
    }
    if (response.success != true || response.data == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      return;
    }
    final text = const JsonEncoder.withIndent(
      '  ',
    ).convert(response.data!.toJson());
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Payslip #$id'),
        content: SizedBox(
          width: 560,
          height: 420,
          child: SingleChildScrollView(child: SelectableText(text)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

Future<void> openAttendanceRecordEditor(
  BuildContext context, {
  required HrService hr,
  required int companyId,
  int? recordId,
  required VoidCallback onSaved,
}) async {
  final formKey = GlobalKey<FormState>();
  int? employeeId;
  String status = 'present';
  final dateCtrl = TextEditingController();
  final checkInCtrl = TextEditingController();
  final checkOutCtrl = TextEditingController();
  List<EmployeeModel> employees = const <EmployeeModel>[];
  String? loadError;
  String? formError;

  try {
    final empResp = await hr.employees(
      filters: <String, dynamic>{
        'per_page': 500,
        'sort_by': 'employee_name',
        'company_id': companyId,
      },
    );
    employees =
        (empResp.data ?? const <EmployeeModel>[]).where((e) {
          return e.companyId == companyId && e.id != null;
        }).toList();
    if (recordId != null) {
      final detail = await hr.attendanceRecord(recordId);
      if (detail.success == true && detail.data != null) {
        final d = detail.data!.toJson();
        employeeId = intValue(d, 'employee_id');
        status = stringValue(d, 'status');
        if (status.isEmpty) {
          status = 'present';
        }
        dateCtrl.text = displayDate(nullableStringValue(d, 'attendance_date'));
        checkInCtrl.text = _sqlDateTimeForInput(
          nullableStringValue(d, 'check_in'),
        );
        checkOutCtrl.text = _sqlDateTimeForInput(
          nullableStringValue(d, 'check_out'),
        );
      } else {
        loadError = detail.message;
      }
    } else {
      dateCtrl.text = displayDate(DateTime.now().toIso8601String());
    }
  } catch (e) {
    loadError = e.toString();
  }

  if (!context.mounted) {
    dateCtrl.dispose();
    checkInCtrl.dispose();
    checkOutCtrl.dispose();
    return;
  }

  if (loadError != null) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(loadError)));
    dateCtrl.dispose();
    checkInCtrl.dispose();
    checkOutCtrl.dispose();
    return;
  }

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(recordId == null ? 'New attendance' : 'Edit attendance'),
            content: SizedBox(
              width: 420,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (formError != null) ...[
                        Text(
                          formError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: AppUiConstants.spacingSm),
                      ],
                      AppDropdownField<int>.fromMapped(
                        labelText: 'Employee',
                        mappedItems: employees
                            .map(
                              (e) => AppDropdownItem<int>(
                                value: e.id!,
                                label: e.toString(),
                              ),
                            )
                            .toList(),
                        initialValue: employeeId,
                        onChanged: (v) => setDialogState(() => employeeId = v),
                        validator: Validators.requiredSelection('Employee'),
                      ),
                      AppFormTextField(
                        controller: dateCtrl,
                        labelText: 'Attendance date',
                        keyboardType: TextInputType.datetime,
                        inputFormatters: const [DateInputFormatter()],
                        validator: Validators.compose([
                          Validators.required('Attendance date'),
                          Validators.date('Attendance date'),
                        ]),
                      ),
                      AppDropdownField<String>.fromMapped(
                        labelText: 'Status',
                        mappedItems: _attendanceStatusItems,
                        initialValue: status,
                        onChanged: (v) =>
                            setDialogState(() => status = v ?? 'present'),
                      ),
                      AppFormTextField(
                        controller: checkInCtrl,
                        labelText: 'Check in (optional)',
                        hintText: 'YYYY-MM-DD HH:MM:SS (numeric keypad)',
                        keyboardType: TextInputType.datetime,
                        inputFormatters: const [DateTimeInputFormatter()],
                        validator: (v) =>
                            validateOptionalSqlDateTime(v, 'Check in'),
                      ),
                      AppFormTextField(
                        controller: checkOutCtrl,
                        labelText: 'Check out (optional)',
                        hintText: 'YYYY-MM-DD HH:MM:SS (numeric keypad)',
                        keyboardType: TextInputType.datetime,
                        inputFormatters: const [DateTimeInputFormatter()],
                        validator: (v) =>
                            validateOptionalSqlDateTime(v, 'Check out'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  if (formKey.currentState?.validate() != true) {
                    return;
                  }
                  final body = <String, dynamic>{
                    'employee_id': employeeId,
                    'attendance_date': dateCtrl.text.trim(),
                    'status': status,
                  };
                  try {
                    final ci = normalizeOptionalCheckInOut(checkInCtrl.text);
                    final co = normalizeOptionalCheckInOut(checkOutCtrl.text);
                    if (ci != null) {
                      body['check_in'] = ci;
                    }
                    if (co != null) {
                      body['check_out'] = co;
                    }
                  } on FormatException {
                    setDialogState(
                      () => formError =
                          'Check in/out must be valid YYYY-MM-DD HH:MM:SS.',
                    );
                    return;
                  }
                  setDialogState(() => formError = null);
                  try {
                    final model = AttendanceRecordModel(body);
                    final response = recordId == null
                        ? await hr.createAttendance(model)
                        : await hr.updateAttendance(recordId, model);
                    if (!dialogContext.mounted) {
                      return;
                    }
                    if (response.success != true || response.data == null) {
                      setDialogState(() => formError = response.message);
                      return;
                    }
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text(response.message)),
                    );
                    Navigator.pop(dialogContext);
                    onSaved();
                  } catch (e) {
                    setDialogState(() => formError = e.toString());
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );

  dateCtrl.dispose();
  checkInCtrl.dispose();
  checkOutCtrl.dispose();
}

Future<void> showAttendanceRecordDetailDialog(
  BuildContext context, {
  required HrService hr,
  required int id,
  required int companyId,
  required VoidCallback onChanged,
}) async {
  try {
    final response = await hr.attendanceRecord(id);
    if (!context.mounted) {
      return;
    }
    if (response.success != true || response.data == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      return;
    }
    final text = const JsonEncoder.withIndent(
      '  ',
    ).convert(response.data!.toJson());

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Attendance #$id'),
        content: SizedBox(
          width: 560,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(child: SelectableText(text)),
              ),
              const Divider(),
              Wrap(
                spacing: AppUiConstants.spacingSm,
                runSpacing: AppUiConstants.spacingSm,
                children: [
                  FilledButton.tonal(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await openAttendanceRecordEditor(
                        context,
                        hr: hr,
                        companyId: companyId,
                        recordId: id,
                        onSaved: onChanged,
                      );
                    },
                    child: const Text('Edit'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(ctx).colorScheme.error,
                      foregroundColor: Theme.of(ctx).colorScheme.onError,
                    ),
                    onPressed: () async {
                      if (!await _confirm(
                        ctx,
                        'Delete attendance',
                        'Delete this attendance record?',
                      )) {
                        return;
                      }
                      final del = await hr.deleteAttendance(id);
                      if (!ctx.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text(del.message)),
                      );
                      if (del.success == true) {
                        Navigator.pop(ctx);
                        onChanged();
                      }
                    },
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

class _ExpenseLineEditors {
  _ExpenseLineEditors({
    required this.expenseDate,
    required this.category,
    required this.description,
    required this.amount,
    required this.remarks,
  });

  final TextEditingController expenseDate;
  final TextEditingController category;
  final TextEditingController description;
  final TextEditingController amount;
  final TextEditingController remarks;

  void dispose() {
    expenseDate.dispose();
    category.dispose();
    description.dispose();
    amount.dispose();
    remarks.dispose();
  }
}

List<_ExpenseLineEditors> _editorsFromClaimJson(Map<String, dynamic> data) {
  final linesRaw = data['lines'];
  final editors = <_ExpenseLineEditors>[];
  if (linesRaw is List) {
    for (final item in linesRaw) {
      final m = _map(item);
      if (m == null) {
        continue;
      }
      editors.add(
        _ExpenseLineEditors(
          expenseDate: TextEditingController(
            text: displayDate(nullableStringValue(m, 'expense_date')),
          ),
          category: TextEditingController(
            text: stringValue(m, 'expense_category'),
          ),
          description: TextEditingController(
            text: stringValue(m, 'description'),
          ),
          amount: TextEditingController(
            text: stringValue(m, 'amount'),
          ),
          remarks: TextEditingController(
            text: stringValue(m, 'remarks'),
          ),
        ),
      );
    }
  }
  if (editors.isEmpty) {
    editors.add(
      _ExpenseLineEditors(
        expenseDate: TextEditingController(
          text: displayDate(DateTime.now().toIso8601String()),
        ),
        category: TextEditingController(),
        description: TextEditingController(),
        amount: TextEditingController(),
        remarks: TextEditingController(),
      ),
    );
  }
  return editors;
}

Future<void> openExpenseClaimEditor(
  BuildContext context, {
  required HrService hr,
  required int companyId,
  int? claimId,
  required VoidCallback onSaved,
}) async {
  final formKey = GlobalKey<FormState>();
  int? employeeId;
  final claimNoCtrl = TextEditingController();
  final claimDateCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  List<_ExpenseLineEditors> lineEditors = <_ExpenseLineEditors>[];
  List<EmployeeModel> employees = const <EmployeeModel>[];
  String? loadError;
  String? formError;

  try {
    final empResp = await hr.employees(
      filters: <String, dynamic>{
        'per_page': 500,
        'sort_by': 'employee_name',
        'company_id': companyId,
      },
    );
    employees =
        (empResp.data ?? const <EmployeeModel>[]).where((e) {
          return e.companyId == companyId && e.id != null;
        }).toList();

    if (claimId != null) {
      final detail = await hr.expenseClaim(claimId);
      if (detail.success == true && detail.data != null) {
        final d = detail.data!.toJson();
        employeeId = intValue(d, 'employee_id');
        claimNoCtrl.text = stringValue(d, 'claim_no');
        claimDateCtrl.text = displayDate(nullableStringValue(d, 'claim_date'));
        notesCtrl.text = stringValue(d, 'notes');
        lineEditors = _editorsFromClaimJson(d);
      } else {
        loadError = detail.message;
      }
    } else {
      claimDateCtrl.text = displayDate(DateTime.now().toIso8601String());
      lineEditors = _editorsFromClaimJson(<String, dynamic>{});
    }
  } catch (e) {
    loadError = e.toString();
  }

  if (!context.mounted) {
    claimNoCtrl.dispose();
    claimDateCtrl.dispose();
    notesCtrl.dispose();
    for (final e in lineEditors) {
      e.dispose();
    }
    return;
  }

  if (loadError != null) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(loadError)));
    claimNoCtrl.dispose();
    claimDateCtrl.dispose();
    notesCtrl.dispose();
    for (final e in lineEditors) {
      e.dispose();
    }
    return;
  }

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          Widget lineForm(int index, _ExpenseLineEditors line) {
            return AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Line ${index + 1}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const Spacer(),
                      if (lineEditors.length > 1)
                        IconButton(
                          tooltip: 'Remove line',
                          onPressed: () {
                            setDialogState(() {
                              lineEditors[index].dispose();
                              lineEditors.removeAt(index);
                            });
                          },
                          icon: const Icon(Icons.delete_outline),
                        ),
                    ],
                  ),
                  AppFormTextField(
                    controller: line.expenseDate,
                    labelText: 'Expense date',
                    keyboardType: TextInputType.datetime,
                    inputFormatters: const [DateInputFormatter()],
                    validator: Validators.compose([
                      Validators.required('Expense date'),
                      Validators.date('Expense date'),
                    ]),
                  ),
                  AppFormTextField(
                    controller: line.category,
                    labelText: 'Category',
                    validator: Validators.required('Category'),
                  ),
                  AppFormTextField(
                    controller: line.description,
                    labelText: 'Description',
                    validator: Validators.required('Description'),
                  ),
                  AppFormTextField(
                    controller: line.amount,
                    labelText: 'Amount',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: Validators.compose([
                      Validators.required('Amount'),
                      (String? v) {
                        final t = v?.trim() ?? '';
                        final d = double.tryParse(t);
                        if (d == null) {
                          return 'Amount must be a valid number';
                        }
                        if (d <= 0) {
                          return 'Amount must be greater than zero';
                        }
                        return null;
                      },
                    ]),
                  ),
                  AppFormTextField(
                    controller: line.remarks,
                    labelText: 'Remarks (optional)',
                  ),
                ],
              ),
            );
          }

          return AlertDialog(
            title: Text(claimId == null ? 'New expense claim' : 'Edit claim'),
            content: SizedBox(
              width: 480,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (formError != null) ...[
                        Text(
                          formError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: AppUiConstants.spacingSm),
                      ],
                      AppDropdownField<int>.fromMapped(
                        labelText: 'Employee',
                        mappedItems: employees
                            .map(
                              (e) => AppDropdownItem<int>(
                                value: e.id!,
                                label: e.toString(),
                              ),
                            )
                            .toList(),
                        initialValue: employeeId,
                        onChanged: (v) => setDialogState(() => employeeId = v),
                        validator: Validators.requiredSelection('Employee'),
                      ),
                      AppFormTextField(
                        controller: claimNoCtrl,
                        labelText: 'Claim no. (optional)',
                      ),
                      AppFormTextField(
                        controller: claimDateCtrl,
                        labelText: 'Claim date',
                        keyboardType: TextInputType.datetime,
                        inputFormatters: const [DateInputFormatter()],
                        validator: Validators.compose([
                          Validators.required('Claim date'),
                          Validators.date('Claim date'),
                        ]),
                      ),
                      AppFormTextField(
                        controller: notesCtrl,
                        labelText: 'Notes (optional)',
                        maxLines: 2,
                      ),
                      const SizedBox(height: AppUiConstants.spacingSm),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () {
                            setDialogState(() {
                              lineEditors.add(
                                _ExpenseLineEditors(
                                  expenseDate: TextEditingController(
                                    text: displayDate(
                                      DateTime.now().toIso8601String(),
                                    ),
                                  ),
                                  category: TextEditingController(),
                                  description: TextEditingController(),
                                  amount: TextEditingController(),
                                  remarks: TextEditingController(),
                                ),
                              );
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add line'),
                        ),
                      ),
                      ...List<Widget>.generate(lineEditors.length, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppUiConstants.spacingSm,
                          ),
                          child: lineForm(i, lineEditors[i]),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  if (formKey.currentState?.validate() != true) {
                    return;
                  }
                  final lines = <Map<String, dynamic>>[];
                  for (final line in lineEditors) {
                    lines.add(<String, dynamic>{
                      'expense_date': line.expenseDate.text.trim(),
                      'expense_category': line.category.text.trim(),
                      'description': line.description.text.trim(),
                      'amount': double.parse(line.amount.text.trim()),
                      if (line.remarks.text.trim().isNotEmpty)
                        'remarks': line.remarks.text.trim(),
                    });
                  }
                  final body = <String, dynamic>{
                    'company_id': companyId,
                    'employee_id': employeeId,
                    'claim_date': claimDateCtrl.text.trim(),
                    'lines': lines,
                  };
                  final cn = claimNoCtrl.text.trim();
                  if (cn.isNotEmpty) {
                    body['claim_no'] = cn;
                  }
                  final nt = notesCtrl.text.trim();
                  if (nt.isNotEmpty) {
                    body['notes'] = nt;
                  }
                  setDialogState(() => formError = null);
                  try {
                    final model = ExpenseClaimModel(body);
                    final response = claimId == null
                        ? await hr.createExpenseClaim(model)
                        : await hr.updateExpenseClaim(claimId, model);
                    if (!dialogContext.mounted) {
                      return;
                    }
                    if (response.success != true || response.data == null) {
                      setDialogState(() => formError = response.message);
                      return;
                    }
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text(response.message)),
                    );
                    Navigator.pop(dialogContext);
                    onSaved();
                  } catch (e) {
                    setDialogState(() => formError = e.toString());
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );

  claimNoCtrl.dispose();
  claimDateCtrl.dispose();
  notesCtrl.dispose();
  for (final e in lineEditors) {
    e.dispose();
  }
}

Future<void> _openReimburseDialog(
  BuildContext context, {
  required HrService hr,
  required AccountsService accountsService,
  required int companyId,
  required int claimId,
  required VoidCallback onChanged,
}) async {
  int? accountId;
  final formKey = GlobalKey<FormState>();
  final paymentDateCtrl = TextEditingController(
    text: displayDate(DateTime.now().toIso8601String()),
  );
  List<AccountModel> accounts = const <AccountModel>[];
  String? errorText;

  try {
    final acc = await accountsService.accounts(
      filters: <String, dynamic>{
        'per_page': 500,
        'company_id': companyId,
        'is_active': 1,
        'sort_by': 'account_name',
      },
    );
    final rawAccounts = acc.data ?? const <AccountModel>[];
    accounts = filterCashBankPaymentAccounts(rawAccounts);
    if (accounts.isEmpty) {
      if (rawAccounts.isNotEmpty) {
        errorText =
            'No bank or cash ledgers found for this company. Add an account '
            'with type Bank or Cash under Accounting → Accounts.';
      } else {
        errorText =
            'No active accounts loaded for this company. Check Accounting → Accounts.';
      }
    }
  } catch (e) {
    errorText = e.toString();
  }

  if (!context.mounted) {
    return;
  }

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setSt) {
          return AlertDialog(
            title: const Text('Reimburse claim'),
            content: SizedBox(
              width: 440,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Uses a Payment voucher. Pick the bank or cash ledger the '
                      'money is paid from. The employee must already have an '
                      'active reimbursement mapping on HR → Employees → Accounts.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppUiConstants.spacingSm),
                    if (errorText != null)
                      Text(
                        errorText!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    AppDropdownField<int>.fromMapped(
                      labelText: 'Payment account (bank or cash)',
                      mappedItems: accounts
                          .map(
                            (a) => AppDropdownItem<int>(
                              value: a.id!,
                              label:
                                  '${a.accountName ?? a.accountCode ?? '#${a.id}'} '
                                  '(${a.accountType ?? '—'})',
                            ),
                          )
                          .toList(),
                      initialValue: accountId,
                      onChanged: (v) => setSt(() => accountId = v),
                      validator: Validators.requiredSelection('Payment account'),
                    ),
                    AppFormTextField(
                      controller: paymentDateCtrl,
                      labelText: 'Payment date',
                      keyboardType: TextInputType.datetime,
                      inputFormatters: const [DateInputFormatter()],
                      validator: Validators.compose([
                        Validators.required('Payment date'),
                        Validators.date('Payment date'),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  if (formKey.currentState?.validate() != true) {
                    return;
                  }
                  try {
                    final body = ExpenseClaimModel(<String, dynamic>{
                      'account_id': accountId,
                      'payment_date': paymentDateCtrl.text.trim(),
                    });
                    final res = await hr.reimburseExpenseClaim(
                      claimId,
                      body,
                    );
                    if (!dialogContext.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text(res.message)),
                    );
                    if (res.success == true) {
                      Navigator.pop(dialogContext);
                      onChanged();
                    }
                  } catch (e) {
                    setSt(() => errorText = e.toString());
                  }
                },
                child: const Text('Reimburse'),
              ),
            ],
          );
        },
      );
    },
  );

  paymentDateCtrl.dispose();
}

Future<void> showExpenseClaimDetailDialog(
  BuildContext context, {
  required HrService hr,
  required int id,
  required int companyId,
  required VoidCallback onChanged,
}) async {
  final accountsService = AccountsService();
  try {
    final response = await hr.expenseClaim(id);
    if (!context.mounted) {
      return;
    }
    if (response.success != true || response.data == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      return;
    }
    final snapshot = response.data!;
    final text = const JsonEncoder.withIndent(
      '  ',
    ).convert(snapshot.toJson());
    final st = stringValue(snapshot.toJson(), 'claim_status');

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Expense claim #$id'),
        content: SizedBox(
          width: 600,
          height: 480,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(child: SelectableText(text)),
              ),
              const Divider(),
              if (st == 'draft')
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppUiConstants.spacingSm,
                  ),
                  child: Text(
                    'Approve creates a posted Journal (needs OTHEXP001 expense '
                    'ledger, Journal voucher type, and the employee’s active '
                    'reimbursement account on HR → Employees → Accounts). '
                    'Reimburse then pays from a bank/cash ledger via a Payment voucher.',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                ),
              if (st == 'approved' &&
                  intValue(snapshot.toJson(), 'reimbursement_voucher_id') ==
                      null)
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppUiConstants.spacingSm,
                  ),
                  child: Text(
                    'Next: Reimburse records payment from a Bank or Cash ledger '
                    '(Payment voucher type must exist). Employee reimbursement '
                    'payable was set at approve time.',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                ),
              Wrap(
                spacing: AppUiConstants.spacingSm,
                runSpacing: AppUiConstants.spacingSm,
                children: [
                  if (st == 'draft') ...[
                    FilledButton.tonal(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await openExpenseClaimEditor(
                          context,
                          hr: hr,
                          companyId: companyId,
                          claimId: id,
                          onSaved: onChanged,
                        );
                      },
                      child: const Text('Edit'),
                    ),
                    FilledButton.tonal(
                      onPressed: () async {
                        final res = await hr.approveExpenseClaim(
                          id,
                          ExpenseClaimModel(<String, dynamic>{}),
                        );
                        if (!ctx.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(res.message)),
                        );
                        if (res.success == true) {
                          Navigator.pop(ctx);
                          onChanged();
                        }
                      },
                      child: const Text('Approve'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(ctx).colorScheme.error,
                        foregroundColor: Theme.of(ctx).colorScheme.onError,
                      ),
                      onPressed: () async {
                        if (!await _confirm(
                          ctx,
                          'Delete claim',
                          'Delete this draft expense claim?',
                        )) {
                          return;
                        }
                        final del = await hr.deleteExpenseClaim(id);
                        if (!ctx.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(del.message)),
                        );
                        if (del.success == true) {
                          Navigator.pop(ctx);
                          onChanged();
                        }
                      },
                      child: const Text('Delete'),
                    ),
                  ],
                  if (st == 'approved' &&
                      intValue(snapshot.toJson(), 'reimbursement_voucher_id') ==
                          null)
                    FilledButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _openReimburseDialog(
                          context,
                          hr: hr,
                          accountsService: accountsService,
                          companyId: companyId,
                          claimId: id,
                          onChanged: onChanged,
                        );
                      },
                      child: const Text('Reimburse'),
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

Future<void> openPayrollRunEditor(
  BuildContext context, {
  required HrService hr,
  required int companyId,
  int? runId,
  required VoidCallback onSaved,
}) async {
  final formKey = GlobalKey<FormState>();
  final monthCtrl = TextEditingController();
  final yearCtrl = TextEditingController();
  final runDateCtrl = TextEditingController();
  String? loadError;
  String? formError;

  try {
    if (runId != null) {
      final detail = await hr.payrollRun(runId);
      if (detail.success == true && detail.data != null) {
        final d = detail.data!.toJson();
        monthCtrl.text = stringValue(d, 'payroll_month');
        yearCtrl.text = stringValue(d, 'payroll_year');
        runDateCtrl.text = displayDate(nullableStringValue(d, 'run_date'));
      } else {
        loadError = detail.message;
      }
    } else {
      final now = DateTime.now();
      monthCtrl.text = now.month.toString();
      yearCtrl.text = now.year.toString();
      runDateCtrl.text = displayDate(now.toIso8601String());
    }
  } catch (e) {
    loadError = e.toString();
  }

  if (!context.mounted) {
    monthCtrl.dispose();
    yearCtrl.dispose();
    runDateCtrl.dispose();
    return;
  }

  if (loadError != null) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(loadError)));
    monthCtrl.dispose();
    yearCtrl.dispose();
    runDateCtrl.dispose();
    return;
  }

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(runId == null ? 'New payroll run' : 'Edit payroll run'),
            content: SizedBox(
              width: 360,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (formError != null) ...[
                      Text(
                        formError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: AppUiConstants.spacingSm),
                    ],
                    AppFormTextField(
                      controller: monthCtrl,
                      labelText: 'Payroll month (1–12)',
                      keyboardType: TextInputType.number,
                      validator: Validators.compose([
                        Validators.required('Month'),
                        (v) {
                          final n = int.tryParse(v?.trim() ?? '');
                          if (n == null || n < 1 || n > 12) {
                            return 'Enter a month from 1 to 12';
                          }
                          return null;
                        },
                      ]),
                    ),
                    AppFormTextField(
                      controller: yearCtrl,
                      labelText: 'Payroll year',
                      keyboardType: TextInputType.number,
                      validator: Validators.compose([
                        Validators.required('Year'),
                        (v) {
                          final n = int.tryParse(v?.trim() ?? '');
                          if (n == null || n < 2000 || n > 2100) {
                            return 'Enter a valid year';
                          }
                          return null;
                        },
                      ]),
                    ),
                    AppFormTextField(
                      controller: runDateCtrl,
                      labelText: 'Run date',
                      keyboardType: TextInputType.datetime,
                      inputFormatters: const [DateInputFormatter()],
                      validator: Validators.compose([
                        Validators.required('Run date'),
                        Validators.date('Run date'),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  if (formKey.currentState?.validate() != true) {
                    return;
                  }
                  final body = PayrollRunModel(<String, dynamic>{
                    'company_id': companyId,
                    'payroll_month': int.parse(monthCtrl.text.trim()),
                    'payroll_year': int.parse(yearCtrl.text.trim()),
                    'run_date': runDateCtrl.text.trim(),
                    'status': 'draft',
                  });
                  setDialogState(() => formError = null);
                  try {
                    final response = runId == null
                        ? await hr.createPayrollRun(body)
                        : await hr.updatePayrollRun(runId, body);
                    if (!dialogContext.mounted) {
                      return;
                    }
                    if (response.success != true || response.data == null) {
                      setDialogState(() => formError = response.message);
                      return;
                    }
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text(response.message)),
                    );
                    Navigator.pop(dialogContext);
                    onSaved();
                  } catch (e) {
                    setDialogState(() => formError = e.toString());
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );

  monthCtrl.dispose();
  yearCtrl.dispose();
  runDateCtrl.dispose();
}

Future<void> showPayrollRunDetailDialog(
  BuildContext context, {
  required HrService hr,
  required int id,
  required int companyId,
  required VoidCallback onChanged,
}) async {
  try {
    final response = await hr.payrollRun(id);
    if (!context.mounted) {
      return;
    }
    if (response.success != true || response.data == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      return;
    }
    final snap = response.data!;
    final data = snap.toJson();
    final text = const JsonEncoder.withIndent('  ').convert(data);
    final st = stringValue(data, 'status');

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Payroll run #$id'),
        content: SizedBox(
          width: 600,
          height: 440,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(child: SelectableText(text)),
              ),
              const Divider(),
              Wrap(
                spacing: AppUiConstants.spacingSm,
                runSpacing: AppUiConstants.spacingSm,
                children: [
                  if (st == 'draft') ...[
                    FilledButton.tonal(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await openPayrollRunEditor(
                          context,
                          hr: hr,
                          companyId: companyId,
                          runId: id,
                          onSaved: onChanged,
                        );
                      },
                      child: const Text('Edit'),
                    ),
                    FilledButton.tonal(
                      onPressed: () async {
                        if (!await _confirm(
                          ctx,
                          'Process payroll',
                          'Generate payroll lines and payslips for all active '
                          'employees? This cannot be undone.',
                        )) {
                          return;
                        }
                        final res = await hr.processPayrollRun(
                          id,
                          PayrollRunModel(<String, dynamic>{}),
                        );
                        if (!ctx.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(res.message)),
                        );
                        if (res.success == true) {
                          Navigator.pop(ctx);
                          onChanged();
                        }
                      },
                      child: const Text('Process'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(ctx).colorScheme.error,
                        foregroundColor: Theme.of(ctx).colorScheme.onError,
                      ),
                      onPressed: () async {
                        if (!await _confirm(
                          ctx,
                          'Delete payroll run',
                          'Delete this draft payroll run?',
                        )) {
                          return;
                        }
                        final del = await hr.deletePayrollRun(id);
                        if (!ctx.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(del.message)),
                        );
                        if (del.success == true) {
                          Navigator.pop(ctx);
                          onChanged();
                        }
                      },
                      child: const Text('Delete'),
                    ),
                  ],
                  if (st == 'processed')
                    FilledButton(
                      onPressed: () async {
                        if (!await _confirm(
                          ctx,
                          'Post payroll',
                          'Post this payroll run to accounting?',
                        )) {
                          return;
                        }
                        final res = await hr.postPayrollRun(
                          id,
                          PayrollRunModel(<String, dynamic>{}),
                        );
                        if (!ctx.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(res.message)),
                        );
                        if (res.success == true) {
                          Navigator.pop(ctx);
                          onChanged();
                        }
                      },
                      child: const Text('Post'),
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}
