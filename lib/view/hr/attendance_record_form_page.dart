import '../../screen.dart';

class AttendanceRecordFormPage extends StatefulWidget {
  const AttendanceRecordFormPage({
    super.key,
    required this.companyId,
    this.recordId,
    this.embedded = false,
  });

  final int companyId;
  final int? recordId;
  final bool embedded;

  @override
  State<AttendanceRecordFormPage> createState() =>
      _AttendanceRecordFormPageState();
}

class _AttendanceRecordFormPageState extends State<AttendanceRecordFormPage> {
  static const List<AppDropdownItem<String>> _statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'present', label: 'Present'),
        AppDropdownItem(value: 'absent', label: 'Absent'),
        AppDropdownItem(value: 'half_day', label: 'Half day'),
        AppDropdownItem(value: 'leave', label: 'Paid leave'),
        AppDropdownItem(value: 'lop', label: 'Loss of pay'),
        AppDropdownItem(value: 'holiday', label: 'Holiday'),
      ];

  final HrService _hr = HrService();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _checkInController = TextEditingController();
  final TextEditingController _checkOutController = TextEditingController();

  List<EmployeeModel> _employees = const <EmployeeModel>[];
  int? _employeeId;
  String _status = 'present';
  String? _error;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _dateController.dispose();
    _checkInController.dispose();
    _checkOutController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final employeeResponse = await _hr.employees(
        filters: <String, dynamic>{
          'per_page': 500,
          'sort_by': 'employee_name',
          'company_id': widget.companyId,
        },
      );
      final employees = (employeeResponse.data ?? const <EmployeeModel>[])
          .where(
            (employee) =>
                employee.companyId == widget.companyId && employee.id != null,
          )
          .toList(growable: false);
      final recordId = widget.recordId;
      if (recordId == null) {
        if (!mounted) {
          return;
        }
        setState(() {
          _employees = employees;
          _dateController.text = displayDate(DateTime.now().toIso8601String());
          _loading = false;
        });
        return;
      }
      final response = await _hr.attendanceRecord(recordId);
      if (!mounted) {
        return;
      }
      if (response.success != true || response.data == null) {
        setState(() {
          _employees = employees;
          _error = response.message;
          _loading = false;
        });
        return;
      }
      final json = response.data!.toJson();
      setState(() {
        _employees = employees;
        _employeeId = intValue(json, 'employee_id');
        _status = stringValue(json, 'status', 'present');
        _dateController.text = displayDate(
          nullableStringValue(json, 'attendance_date'),
        );
        _checkInController.text = displayDateTime(
          nullableStringValue(json, 'check_in'),
        );
        _checkOutController.text = displayDateTime(
          nullableStringValue(json, 'check_out'),
        );
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (_saving || _formKey.currentState?.validate() != true) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final json = <String, dynamic>{
        'employee_id': _employeeId,
        'attendance_date': _dateController.text.trim(),
        'status': _status,
        if (_checkInController.text.trim().isNotEmpty)
          'check_in': normalizeOptionalCheckInOut(_checkInController.text),
        if (_checkOutController.text.trim().isNotEmpty)
          'check_out': normalizeOptionalCheckInOut(_checkOutController.text),
      };
      final model = AttendanceRecordModel.fromJson(json);
      final response = widget.recordId == null
          ? await _hr.createAttendance(model)
          : await _hr.updateAttendance(widget.recordId!, model);
      if (!mounted) {
        return;
      }
      if (response.success != true || response.data == null) {
        setState(() {
          _saving = false;
          _error = response.message;
        });
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      openFormScreenRoute(context, '/hr/attendance');
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _loading
        ? const AppLoadingView(message: 'Loading attendance...')
        : SingleChildScrollView(
            padding: const EdgeInsets.all(AppUiConstants.pagePadding),
            child: AppSectionCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      widget.recordId == null
                          ? 'New attendance'
                          : 'Edit attendance',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppUiConstants.spacingLg),
                    if (_error != null) ...<Widget>[
                      AppErrorStateView.inline(message: _error!),
                      const SizedBox(height: AppUiConstants.spacingMd),
                    ],
                    SettingsFormWrap(
                      children: <Widget>[
                        AppDropdownField<int>.fromMapped(
                          labelText: 'Employee',
                          mappedItems: _employees
                              .map(
                                (employee) => AppDropdownItem<int>(
                                  value: employee.id!,
                                  label: employee.toString(),
                                ),
                              )
                              .toList(growable: false),
                          initialValue: _employeeId,
                          onChanged: (value) =>
                              setState(() => _employeeId = value),
                          validator: Validators.requiredSelection('Employee'),
                        ),
                        AppFormTextField(
                          controller: _dateController,
                          labelText: 'Attendance date',
                          keyboardType: TextInputType.datetime,
                          inputFormatters: const <TextInputFormatter>[
                            DateInputFormatter(),
                          ],
                          validator:
                              Validators.compose(<String? Function(String?)>[
                                Validators.required('Attendance date'),
                                Validators.date('Attendance date'),
                              ]),
                        ),
                        AppDropdownField<String>.fromMapped(
                          labelText: 'Status',
                          mappedItems: _statusItems,
                          initialValue: _status,
                          onChanged: (value) =>
                              setState(() => _status = value ?? 'present'),
                        ),
                        AppFormTextField(
                          controller: _checkInController,
                          labelText: 'Check in (optional)',
                          keyboardType: TextInputType.datetime,
                          inputFormatters: const <TextInputFormatter>[
                            DateTimeInputFormatter(),
                          ],
                          validator: (value) =>
                              validateOptionalSqlDateTime(value, 'Check in'),
                        ),
                        AppFormTextField(
                          controller: _checkOutController,
                          labelText: 'Check out (optional)',
                          keyboardType: TextInputType.datetime,
                          inputFormatters: const <TextInputFormatter>[
                            DateTimeInputFormatter(),
                          ],
                          validator: (value) =>
                              validateOptionalSqlDateTime(value, 'Check out'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppUiConstants.spacingLg),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(_saving ? 'Saving...' : 'Save'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
    if (widget.embedded) {
      return content;
    }
    return AppStandaloneShell(
      title: widget.recordId == null ? 'New attendance' : 'Edit attendance',
      scrollController: _scrollController,
      actions: const <Widget>[],
      child: content,
    );
  }
}
