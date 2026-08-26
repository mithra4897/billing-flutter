import '../../screen.dart';
import '../../controller/hr/hr_module_refresh_controller.dart';

/// When no company is stored but the user has exactly one active company, persist it
/// so HR screens behave like the rest of the app without an extra header step.
Future<int?> _ensureStoredCompanyWhenSingleTenant(
  List<CompanyModel> activeCompanies,
) async {
  if (activeCompanies.length != 1) {
    return null;
  }
  final onlyId = activeCompanies.first.id;
  if (onlyId == null) {
    return null;
  }
  await SessionStorage.saveSelectedContext(companyId: onlyId);
  WorkingContextService.version.value++;
  return onlyId;
}

/// Resolves the company saved in session (header). If nothing is stored but there
/// is only one active company, selects it automatically.
Future<({int? companyId, String? banner})> hrSessionCompanyInfo() async {
  final master = MasterService();
  try {
    final companiesResp = await master.companies(
      filters: const {'per_page': 200, 'sort_by': 'legal_name'},
    );
    final companies = companiesResp.data ?? const <CompanyModel>[];
    final active = companies
        .where((CompanyModel c) => c.isActive)
        .toList(growable: false);

    var storedId = await SessionStorage.getCurrentCompanyId();
    storedId ??= await _ensureStoredCompanyWhenSingleTenant(active);
    if (storedId == null) {
      return (companyId: null, banner: null);
    }

    CompanyModel? match;
    for (final c in active) {
      if (c.id == storedId) {
        match = c;
        break;
      }
    }
    if (match == null) {
      return (companyId: null, banner: null);
    }
    return (companyId: storedId, banner: match.toString());
  } catch (_) {
    return (companyId: null, banner: null);
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
      AppDropdownItem(value: 'lop', label: 'LOP'),
    ];

/// Resolves working-context company. Uses session storage, or auto-selects when
/// there is exactly one active company.
Future<int?> hrResolveCompanyId(BuildContext context) async {
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
    var storedId = await SessionStorage.getCurrentCompanyId();
    storedId ??= await _ensureStoredCompanyWhenSingleTenant(active);
    if (storedId == null) {
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
  await openPayslipPrintPreview(context, hr: hr, payslipId: id);
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

  void disposeControllers() {
    dateCtrl.dispose();
    checkInCtrl.dispose();
    checkOutCtrl.dispose();
  }

  try {
    final empResp = await hr.employees(
      filters: <String, dynamic>{
        'per_page': 500,
        'sort_by': 'employee_name',
        'company_id': companyId,
      },
    );
    employees = (empResp.data ?? const <EmployeeModel>[]).where((e) {
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
    disposeControllers();
    return;
  }

  if (loadError != null) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(loadError)));
    disposeControllers();
    return;
  }

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              recordId == null ? 'New attendance' : 'Edit attendance',
            ),
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
                        validator: Validators.required('Status'),
                      ),
                      AppFormTextField(
                        controller: checkInCtrl,
                        labelText: 'Check in (optional)',
                        hintText: '${dateTimeFormatHint()} (numeric keypad)',
                        keyboardType: TextInputType.datetime,
                        inputFormatters: const [DateTimeInputFormatter()],
                        validator: (v) =>
                            validateOptionalSqlDateTime(v, 'Check in'),
                      ),
                      AppFormTextField(
                        controller: checkOutCtrl,
                        labelText: 'Check out (optional)',
                        hintText: '${dateTimeFormatHint()} (numeric keypad)',
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
                    final model = AttendanceRecordModel.fromJson(body);
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
                    ScaffoldMessenger.of(
                      dialogContext,
                    ).showSnackBar(SnackBar(content: Text(response.message)));
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

  WidgetsBinding.instance.addPostFrameCallback((_) {
    disposeControllers();
  });
}

Future<void> openBulkAttendanceEditor(
  BuildContext context, {
  required HrService hr,
  required int companyId,
  required List<EmployeeModel> employees,
  required VoidCallback onSaved,
}) async {
  final activeEmployees = employees
      .where(
        (employee) =>
            employee.id != null &&
            (employee.status ?? '').trim().toLowerCase() == 'active',
      )
      .toList(growable: false);
  if (activeEmployees.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No active employees are available.')),
    );
    return;
  }

  final formKey = GlobalKey<FormState>();
  final dateController = TextEditingController(text: displayTodayDate());
  final selectedIds = activeEmployees.map((employee) => employee.id!).toSet();
  final statuses = <int, String>{
    for (final employee in activeEmployees) employee.id!: 'present',
  };
  var commonStatus = 'present';
  var saving = false;
  String? formError;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        final allSelected = selectedIds.length == activeEmployees.length;
        return AlertDialog(
          title: const Text('Bulk manual attendance'),
          content: SizedBox(
            width: 760,
            height: 580,
            child: Form(
              key: formKey,
              child: Column(
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
                  Wrap(
                    spacing: AppUiConstants.spacingMd,
                    runSpacing: AppUiConstants.spacingSm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 220,
                        child: AppFormTextField(
                          controller: dateController,
                          labelText: 'Attendance date',
                          keyboardType: TextInputType.datetime,
                          inputFormatters: const [DateInputFormatter()],
                          validator: Validators.compose([
                            Validators.required('Attendance date'),
                            Validators.date('Attendance date'),
                          ]),
                        ),
                      ),
                      SizedBox(
                        width: 220,
                        child: AppDropdownField<String>.fromMapped(
                          labelText: 'Apply status to selected',
                          mappedItems: _attendanceStatusItems,
                          initialValue: commonStatus,
                          onChanged: saving
                              ? null
                              : (value) {
                                  final next = value ?? 'present';
                                  setDialogState(() {
                                    commonStatus = next;
                                    for (final id in selectedIds) {
                                      statuses[id] = next;
                                    }
                                  });
                                },
                        ),
                      ),
                      Text('${selectedIds.length} selected'),
                    ],
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    tristate: true,
                    value: allSelected
                        ? true
                        : selectedIds.isEmpty
                        ? false
                        : null,
                    onChanged: saving
                        ? null
                        : (value) => setDialogState(() {
                            selectedIds.clear();
                            if (value == true) {
                              selectedIds.addAll(
                                activeEmployees.map((employee) => employee.id!),
                              );
                            }
                          }),
                    title: const Text('Select all active employees'),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      itemCount: activeEmployees.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final employee = activeEmployees[index];
                        final employeeId = employee.id!;
                        final selected = selectedIds.contains(employeeId);
                        return Row(
                          children: [
                            Checkbox(
                              value: selected,
                              onChanged: saving
                                  ? null
                                  : (value) => setDialogState(() {
                                      if (value == true) {
                                        selectedIds.add(employeeId);
                                      } else {
                                        selectedIds.remove(employeeId);
                                      }
                                    }),
                            ),
                            Expanded(
                              child: Text(
                                [employee.employeeName, employee.employeeCode]
                                    .whereType<String>()
                                    .where((v) => v.isNotEmpty)
                                    .join(' · '),
                              ),
                            ),
                            SizedBox(
                              width: 170,
                              child: DropdownButton<String>(
                                value: statuses[employeeId] ?? 'present',
                                isExpanded: true,
                                onChanged: saving || !selected
                                    ? null
                                    : (value) => setDialogState(
                                        () => statuses[employeeId] =
                                            value ?? 'present',
                                      ),
                                items: _attendanceStatusItems
                                    .map(
                                      (item) => DropdownMenuItem<String>(
                                        value: item.value,
                                        child: Text(item.label),
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              icon: saving
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.playlist_add_check_outlined),
              label: Text(saving ? 'Saving…' : 'Create attendance'),
              onPressed: saving
                  ? null
                  : () async {
                      if (formKey.currentState?.validate() != true) return;
                      if (selectedIds.isEmpty) {
                        setDialogState(
                          () => formError = 'Select at least one employee.',
                        );
                        return;
                      }
                      setDialogState(() {
                        saving = true;
                        formError = null;
                      });
                      try {
                        final response = await hr.createBulkAttendance(
                          companyId: companyId,
                          attendanceDate: dateController.text.trim(),
                          records: activeEmployees
                              .where(
                                (employee) => selectedIds.contains(employee.id),
                              )
                              .map(
                                (employee) => <String, dynamic>{
                                  'employee_id': employee.id,
                                  'status': statuses[employee.id] ?? 'present',
                                },
                              )
                              .toList(growable: false),
                        );
                        if (!dialogContext.mounted) return;
                        if (response.success != true) {
                          setDialogState(() {
                            saving = false;
                            formError = response.message;
                          });
                          return;
                        }
                        final result = response.data is Map
                            ? Map<String, dynamic>.from(response.data as Map)
                            : const <String, dynamic>{};
                        final created = intValue(result, 'created_count') ?? 0;
                        final skipped = intValue(result, 'skipped_count') ?? 0;
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Created $created attendance record(s); '
                              'skipped $skipped existing record(s).',
                            ),
                          ),
                        );
                        if (created > 0) onSaved();
                      } catch (error) {
                        if (!dialogContext.mounted) return;
                        setDialogState(() {
                          saving = false;
                          formError = error.toString();
                        });
                      }
                    },
            ),
          ],
        );
      },
    ),
  );
  dateController.dispose();
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
                      ScaffoldMessenger.of(
                        ctx,
                      ).showSnackBar(SnackBar(content: Text(del.message)));
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
          amount: TextEditingController(text: stringValue(m, 'amount')),
          remarks: TextEditingController(text: stringValue(m, 'remarks')),
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
    employees = (empResp.data ?? const <EmployeeModel>[]).where((e) {
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
                    final model = ExpenseClaimModel.fromJson(body);
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
                    ScaffoldMessenger.of(
                      dialogContext,
                    ).showSnackBar(SnackBar(content: Text(response.message)));
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

Future<void> openExpenseClaimRejectDialog(
  BuildContext context, {
  required HrService hr,
  required int claimId,
  required VoidCallback onChanged,
}) async {
  final notes = TextEditingController();
  try {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reject claim'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Declines this draft. No vouchers are posted (requires hr.approve).',
                  style: Theme.of(dialogContext).textTheme.bodySmall,
                ),
                const SizedBox(height: AppUiConstants.spacingSm),
                TextField(
                  controller: notes,
                  decoration: const InputDecoration(
                    labelText: 'Reason (optional)',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Back'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
                foregroundColor: Theme.of(dialogContext).colorScheme.onError,
              ),
              onPressed: () async {
                final t = notes.text.trim();
                final res = await hr.rejectExpenseClaim(
                  claimId,
                  ExpenseClaimModel.fromJson(<String, dynamic>{
                    if (t.isNotEmpty) 'notes': t,
                  }),
                );
                if (!dialogContext.mounted) {
                  return;
                }
                ScaffoldMessenger.of(
                  dialogContext,
                ).showSnackBar(SnackBar(content: Text(res.message)));
                if (res.success == true) {
                  Navigator.pop(dialogContext);
                  onChanged();
                }
              },
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
  } finally {
    notes.dispose();
  }
}

Future<void> openExpenseClaimCancelDialog(
  BuildContext context, {
  required HrService hr,
  required int claimId,
  required VoidCallback onChanged,
}) async {
  final notes = TextEditingController();
  try {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancel claim'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Withdraws this draft without deleting the record (requires hr.update). '
                  'No vouchers are posted.',
                  style: Theme.of(dialogContext).textTheme.bodySmall,
                ),
                const SizedBox(height: AppUiConstants.spacingSm),
                TextField(
                  controller: notes,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Back'),
            ),
            FilledButton(
              onPressed: () async {
                final t = notes.text.trim();
                final res = await hr.cancelExpenseClaim(
                  claimId,
                  ExpenseClaimModel.fromJson(<String, dynamic>{
                    if (t.isNotEmpty) 'notes': t,
                  }),
                );
                if (!dialogContext.mounted) {
                  return;
                }
                ScaffoldMessenger.of(
                  dialogContext,
                ).showSnackBar(SnackBar(content: Text(res.message)));
                if (res.success == true) {
                  Navigator.pop(dialogContext);
                  onChanged();
                }
              },
              child: const Text('Cancel claim'),
            ),
          ],
        );
      },
    );
  } finally {
    notes.dispose();
  }
}

Future<void> openExpenseClaimReimburseDialog(
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
                                  '(${a.accountType ?? '-'})',
                            ),
                          )
                          .toList(),
                      initialValue: accountId,
                      onChanged: (v) => setSt(() => accountId = v),
                      validator: Validators.requiredSelection(
                        'Payment account',
                      ),
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
                    final body = ExpenseClaimModel.fromJson(<String, dynamic>{
                      'account_id': accountId,
                      'payment_date': paymentDateCtrl.text.trim(),
                    });
                    final res = await hr.reimburseExpenseClaim(claimId, body);
                    if (!dialogContext.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(
                      dialogContext,
                    ).showSnackBar(SnackBar(content: Text(res.message)));
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
    final text = const JsonEncoder.withIndent('  ').convert(snapshot.toJson());
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
                    'Approve (hr.approve) posts a Journal: expense OTHEXP001 vs '
                    'employee reimbursement payable. Reject (hr.approve) or '
                    'Cancel draft (hr.update) - no GL. After approval, Reimburse '
                    '(hr.update) pays bank/cash via a Payment voucher.',
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
                    'Reimburse (hr.update): payment from Bank or Cash; Payment '
                    'voucher type required. Payable was booked at approve time.',
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
                        try {
                          final res = await hr.approveExpenseClaim(
                            id,
                            ExpenseClaimModel.fromJson(<String, dynamic>{}),
                          );
                          if (!ctx.mounted) {
                            return;
                          }
                          ScaffoldMessenger.maybeOf(
                            ctx,
                          )?.showSnackBar(SnackBar(content: Text(res.message)));
                          if (res.success == true) {
                            Navigator.pop(ctx);
                            onChanged();
                          }
                        } on ApiException catch (e) {
                          if (!ctx.mounted) {
                            return;
                          }
                          ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(
                            SnackBar(content: Text(e.displayMessage)),
                          );
                        }
                      },
                      child: const Text('Approve'),
                    ),
                    FilledButton.tonal(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await openExpenseClaimRejectDialog(
                          context,
                          hr: hr,
                          claimId: id,
                          onChanged: onChanged,
                        );
                      },
                      child: const Text('Reject'),
                    ),
                    FilledButton.tonal(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await openExpenseClaimCancelDialog(
                          context,
                          hr: hr,
                          claimId: id,
                          onChanged: onChanged,
                        );
                      },
                      child: const Text('Cancel draft'),
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
                        ScaffoldMessenger.of(
                          ctx,
                        ).showSnackBar(SnackBar(content: Text(del.message)));
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
                        await openExpenseClaimReimburseDialog(
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
  var useAttendance = true;
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
        useAttendance = JsonModel.boolOf(d['use_attendance'] ?? true);
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
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                    const SizedBox(height: AppUiConstants.spacingSm),
                    AppSwitchTile(
                      label: 'Calculate using attendance',
                      value: useAttendance,
                      onChanged: (value) =>
                          setDialogState(() => useAttendance = value),
                    ),
                    Text(
                      useAttendance
                          ? 'Attendance and approved loss-of-pay leave are included.'
                          : 'Full salary is calculated without attendance or loss-of-pay deductions.',
                      style: Theme.of(context).textTheme.bodySmall,
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
                  final body = PayrollRunModel.fromJson(<String, dynamic>{
                    'company_id': companyId,
                    'payroll_month': int.parse(monthCtrl.text.trim()),
                    'payroll_year': int.parse(yearCtrl.text.trim()),
                    'run_date': runDateCtrl.text.trim(),
                    'use_attendance': useAttendance,
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
                    ScaffoldMessenger.of(
                      dialogContext,
                    ).showSnackBar(SnackBar(content: Text(response.message)));
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
    final run = response.data!;
    final st = run.status ?? '';
    final lineRows = run.lines;
    final payrollPreview = run.payrollPreview;
    final totalGross = lineRows.fold<double>(
      0,
      (sum, item) => sum + (item.grossSalary ?? 0),
    );
    final totalDeductions = lineRows.fold<double>(
      0,
      (sum, item) => sum + (item.totalDeductions ?? 0),
    );
    final totalNet = lineRows.fold<double>(
      0,
      (sum, item) => sum + (item.netSalary ?? 0),
    );

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => Scaffold(
          appBar: AppBar(title: Text('Payroll run #$id')),
          body: SafeArea(
            child: Center(
              child: AlertDialog(
                title: Text('Payroll run #$id'),
                content: SizedBox(
                  width: MediaQuery.sizeOf(ctx).width - 48,
                  height: MediaQuery.sizeOf(ctx).height - 140,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: AppUiConstants.spacingSm,
                                runSpacing: AppUiConstants.spacingSm,
                                children: [
                                  _HrInfoChip(
                                    label: 'Period',
                                    value: run.periodLabel,
                                  ),
                                  _HrInfoChip(
                                    label: 'Run date',
                                    value: displayDate(run.runDate),
                                  ),
                                  _HrInfoChip(
                                    label: 'Status',
                                    value: st.toUpperCase(),
                                  ),
                                  _HrInfoChip(
                                    label: 'Lines',
                                    value: (run.linesCount ?? lineRows.length)
                                        .toString(),
                                  ),
                                  _HrInfoChip(
                                    label: 'Attendance',
                                    value: run.useAttendance == false
                                        ? 'No'
                                        : 'Yes',
                                  ),
                                  if (run.voucherId != null)
                                    _HrInfoChip(
                                      label: 'Voucher',
                                      value:
                                          (run.voucherNo?.trim().isNotEmpty ??
                                              false)
                                          ? run.voucherNo!.trim()
                                          : 'ID ${run.voucherId}',
                                    ),
                                ],
                              ),
                              const SizedBox(height: AppUiConstants.spacingMd),
                              Text(
                                'Payroll Totals',
                                style: Theme.of(ctx).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: AppUiConstants.spacingSm),
                              Wrap(
                                spacing: AppUiConstants.spacingSm,
                                runSpacing: AppUiConstants.spacingSm,
                                children: [
                                  _HrInfoChip(
                                    label: 'Gross',
                                    value: formatAmount(totalGross),
                                  ),
                                  _HrInfoChip(
                                    label: 'Deductions',
                                    value: formatAmount(totalDeductions),
                                  ),
                                  _HrInfoChip(
                                    label: 'Net',
                                    value: formatAmount(totalNet),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppUiConstants.spacingMd),
                              Text(
                                st == 'draft'
                                    ? 'Employees for this run'
                                    : 'Employee Lines',
                                style: Theme.of(ctx).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: AppUiConstants.spacingSm),
                              if (st == 'draft' && payrollPreview != null) ...[
                                Text(
                                  '${payrollPreview.eligibleCount} ready • '
                                  '${payrollPreview.excludedCount} need attention',
                                  style: Theme.of(ctx).textTheme.bodyMedium,
                                ),
                                const SizedBox(
                                  height: AppUiConstants.spacingSm,
                                ),
                                if (payrollPreview.employees.isEmpty)
                                  const Text(
                                    'No employees found for this company.',
                                  )
                                else
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      columns: const [
                                        DataColumn(label: Text('Employee')),
                                        DataColumn(label: Text('Code')),
                                        DataColumn(label: Text('Status')),
                                        DataColumn(label: Text('Gross')),
                                        DataColumn(label: Text('Paid days')),
                                        DataColumn(label: Text('LOP')),
                                        DataColumn(label: Text('Details')),
                                      ],
                                      rows: payrollPreview.employees
                                          .map((employee) {
                                            return DataRow(
                                              cells: [
                                                DataCell(
                                                  Text(
                                                    employee.employeeName ??
                                                        '—',
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    employee.employeeCode ??
                                                        '—',
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    employee.eligible
                                                        ? 'Ready'
                                                        : 'Attention',
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    formatAmount(
                                                      employee.grossSalary ?? 0,
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    '${formatAmount(employee.paidDays ?? 0)}/${employee.workingDays ?? 0}',
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    formatAmount(
                                                      employee.lopDays ?? 0,
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    employee.eligible
                                                        ? 'Eligible for processing'
                                                        : employee.reason ??
                                                              'Payroll setup is incomplete.',
                                                  ),
                                                ),
                                              ],
                                            );
                                          })
                                          .toList(growable: false),
                                    ),
                                  ),
                              ] else if (lineRows.isEmpty)
                                const Text('No payroll lines were generated.')
                              else
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columns: const [
                                      DataColumn(label: Text('Employee')),
                                      DataColumn(label: Text('Code')),
                                      DataColumn(label: Text('Gross')),
                                      DataColumn(label: Text('Deductions')),
                                      DataColumn(label: Text('Net')),
                                      DataColumn(label: Text('Paid days')),
                                      DataColumn(label: Text('LOP')),
                                    ],
                                    rows: lineRows
                                        .map((line) {
                                          return DataRow(
                                            cells: [
                                              DataCell(
                                                Text(line.employeeName ?? '—'),
                                              ),
                                              DataCell(
                                                Text(line.employeeCode ?? '—'),
                                              ),
                                              DataCell(
                                                Text(
                                                  formatAmount(
                                                    line.grossSalary ?? 0,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  formatAmount(
                                                    line.totalDeductions ?? 0,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  formatAmount(
                                                    line.netSalary ?? 0,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  '${formatAmount(line.paidDays ?? 0)}/${line.workingDays ?? 0}',
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  formatAmount(
                                                    line.lopDays ?? 0,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        })
                                        .toList(growable: false),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(),
                      Wrap(
                        spacing: AppUiConstants.spacingSm,
                        runSpacing: AppUiConstants.spacingSm,
                        children: [
                          if (lineRows.isNotEmpty)
                            FilledButton.tonal(
                              onPressed: () {
                                Navigator.pop(ctx);
                                final route = '/hr/payslips?payroll_run_id=$id';
                                final navigate = ShellRouteScope.maybeOf(
                                  context,
                                );
                                if (navigate != null) {
                                  navigate(route);
                                  return;
                                }
                                Navigator.of(context).pushNamed(route);
                              },
                              child: const Text('View payslips'),
                            ),
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
                                  'Generate payroll lines and payslips for '
                                      '${payrollPreview?.eligibleCount ?? 0} eligible '
                                      'employees? Review any excluded employees first.',
                                )) {
                                  return;
                                }
                                try {
                                  final res = await hr.processPayrollRun(
                                    id,
                                    PayrollRunModel.fromJson(
                                      <String, dynamic>{},
                                    ),
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
                                } on ApiException catch (error) {
                                  if (!ctx.mounted) {
                                    return;
                                  }
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text(error.displayMessage),
                                    ),
                                  );
                                } catch (_) {
                                  if (!ctx.mounted) {
                                    return;
                                  }
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Unable to process payroll. Please try again.',
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: const Text('Process'),
                            ),
                          ],
                          if (st == 'draft' || st == 'processed')
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Theme.of(
                                  ctx,
                                ).colorScheme.error,
                                foregroundColor: Theme.of(
                                  ctx,
                                ).colorScheme.onError,
                              ),
                              onPressed: () async {
                                final isProcessed = st == 'processed';
                                if (!await _confirm(
                                  ctx,
                                  'Delete payroll run',
                                  isProcessed
                                      ? 'Delete this processed payroll run? Its payroll '
                                            'lines and payslips will be permanently removed.'
                                      : 'Delete this draft payroll run?',
                                )) {
                                  return;
                                }
                                try {
                                  final del = await hr.deletePayrollRun(id);
                                  if (!ctx.mounted) {
                                    return;
                                  }
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text(del.message)),
                                  );
                                  if (del.success == true) {
                                    HrModuleRefreshController.ensureRegistered()
                                        .notifyChanged(
                                          source: 'payroll_run_delete',
                                        );
                                    Navigator.pop(ctx);
                                    onChanged();
                                  }
                                } on ApiException catch (error) {
                                  if (!ctx.mounted) {
                                    return;
                                  }
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text(error.displayMessage),
                                    ),
                                  );
                                } catch (_) {
                                  if (!ctx.mounted) {
                                    return;
                                  }
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Unable to delete payroll run. Please try again.',
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: const Text('Delete'),
                            ),
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
                                  PayrollRunModel.fromJson(<String, dynamic>{}),
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
                                  try {
                                    final delivery =
                                        await emailDesignedPayslipsForRun(
                                          context,
                                          hr: hr,
                                          payrollRunId: id,
                                          companyId: companyId,
                                        );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(delivery.message),
                                        ),
                                      );
                                    }
                                  } catch (error) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Payroll was posted, but designed payslip '
                                            'emailing failed: $error',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                              child: const Text('Post'),
                            ),
                          if (st == 'posted')
                            FilledButton.tonalIcon(
                              onPressed: () async {
                                if (!await _confirm(
                                  ctx,
                                  'Email payslips',
                                  'Send every employee in this posted payroll run '
                                      'their PDF payslip now?',
                                )) {
                                  return;
                                }
                                if (!context.mounted) {
                                  return;
                                }
                                try {
                                  final delivery =
                                      await emailDesignedPayslipsForRun(
                                        context,
                                        hr: hr,
                                        payrollRunId: id,
                                        companyId: companyId,
                                      );
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(content: Text(delivery.message)),
                                    );
                                  }
                                } catch (error) {
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Designed payslip emailing failed: $error',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.email_outlined),
                              label: const Text('Email payslips'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
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

class _HrInfoChip extends StatelessWidget {
  const _HrInfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppUiConstants.buttonRadius),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
