import '../../screen.dart';
import '../../controller/hr/hr_module_refresh_controller.dart';

class PayrollRunFormPage extends StatefulWidget {
  const PayrollRunFormPage({
    super.key,
    required this.companyId,
    this.runId,
    this.embedded = false,
  });

  final int companyId;
  final int? runId;
  final bool embedded;

  @override
  State<PayrollRunFormPage> createState() => _PayrollRunFormPageState();
}

class _PayrollRunFormPageState extends State<PayrollRunFormPage> {
  final HrService _hr = HrService();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _monthController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _runDateController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _useAttendance = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    _runDateController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final runId = widget.runId;
    if (runId == null) {
      final now = DateTime.now();
      _monthController.text = now.month.toString();
      _yearController.text = now.year.toString();
      _runDateController.text = displayDate(now.toIso8601String());
      setState(() => _loading = false);
      return;
    }

    try {
      final response = await _hr.payrollRun(runId);
      if (!mounted) {
        return;
      }
      if (response.success != true || response.data == null) {
        setState(() {
          _error = response.message;
          _loading = false;
        });
        return;
      }
      final json = response.data!.toJson();
      _monthController.text = stringValue(json, 'payroll_month');
      _yearController.text = stringValue(json, 'payroll_year');
      _runDateController.text = displayDate(
        nullableStringValue(json, 'run_date'),
      );
      setState(() {
        _useAttendance = JsonModel.boolOf(json['use_attendance'] ?? true);
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
      final model = PayrollRunModel.fromJson(<String, dynamic>{
        'company_id': widget.companyId,
        'payroll_month': int.parse(_monthController.text.trim()),
        'payroll_year': int.parse(_yearController.text.trim()),
        'run_date': _runDateController.text.trim(),
        'use_attendance': _useAttendance,
        'status': 'draft',
      });
      final response = widget.runId == null
          ? await _hr.createPayrollRun(model)
          : await _hr.updatePayrollRun(widget.runId!, model);
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
      HrModuleRefreshController.ensureRegistered().notifyChanged(
        source: 'payroll_run_form',
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      final savedId = intValue(response.data!.toJson(), 'id');
      openFormScreenRoute(
        context,
        savedId == null
            ? '/hr/payroll-runs'
            : '/hr/payroll-runs/detail?run_id=$savedId&company_id=${widget.companyId}',
      );
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
    final content = _buildContent();
    if (widget.embedded) {
      return content;
    }
    return AppStandaloneShell(
      title: widget.runId == null ? 'New payroll run' : 'Edit payroll run',
      scrollController: _scrollController,
      actions: const <Widget>[],
      child: content,
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const AppLoadingView(message: 'Loading payroll run...');
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppUiConstants.pagePadding),
      child: AppSectionCard(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                widget.runId == null ? 'New payroll run' : 'Edit payroll run',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppUiConstants.spacingLg),
              if (_error != null) ...<Widget>[
                AppErrorStateView.inline(message: _error!),
                const SizedBox(height: AppUiConstants.spacingMd),
              ],
              SettingsFormWrap(
                children: <Widget>[
                  AppFormTextField(
                    controller: _monthController,
                    labelText: 'Payroll month (1–12)',
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      final month = int.tryParse(value?.trim() ?? '');
                      return month == null || month < 1 || month > 12
                          ? 'Enter a month from 1 to 12'
                          : null;
                    },
                  ),
                  AppFormTextField(
                    controller: _yearController,
                    labelText: 'Payroll year',
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      final year = int.tryParse(value?.trim() ?? '');
                      return year == null || year < 2000 || year > 2100
                          ? 'Enter a valid year'
                          : null;
                    },
                  ),
                  AppFormTextField(
                    controller: _runDateController,
                    labelText: 'Run date',
                    keyboardType: TextInputType.datetime,
                    inputFormatters: const <TextInputFormatter>[
                      DateInputFormatter(),
                    ],
                    validator: Validators.compose(<String? Function(String?)>[
                      Validators.required('Run date'),
                      Validators.date('Run date'),
                    ]),
                  ),
                ],
              ),
              const SizedBox(height: AppUiConstants.spacingMd),
              AppSwitchTile(
                label: 'Calculate using attendance',
                value: _useAttendance,
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _useAttendance = value),
              ),
              Text(
                _useAttendance
                    ? 'Attendance and approved loss-of-pay leave are included.'
                    : 'Full salary is calculated without attendance or loss-of-pay deductions.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppUiConstants.spacingLg),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Saving...' : 'Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
