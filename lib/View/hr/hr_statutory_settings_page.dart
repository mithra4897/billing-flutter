import '../../screen.dart';
import 'hr_workflow_dialogs.dart';

/// State/UT names for PT — slabs should match that jurisdiction's official schedule.
const List<AppDropdownItem<String>> _kProfessionalTaxStateItems =
    <AppDropdownItem<String>>[
  AppDropdownItem(value: '', label: '— Select state / UT —'),
  AppDropdownItem(value: 'Andhra Pradesh', label: 'Andhra Pradesh'),
  AppDropdownItem(value: 'Arunachal Pradesh', label: 'Arunachal Pradesh'),
  AppDropdownItem(value: 'Assam', label: 'Assam'),
  AppDropdownItem(value: 'Bihar', label: 'Bihar'),
  AppDropdownItem(value: 'Chhattisgarh', label: 'Chhattisgarh'),
  AppDropdownItem(value: 'Goa', label: 'Goa'),
  AppDropdownItem(value: 'Gujarat', label: 'Gujarat'),
  AppDropdownItem(value: 'Haryana', label: 'Haryana'),
  AppDropdownItem(value: 'Himachal Pradesh', label: 'Himachal Pradesh'),
  AppDropdownItem(value: 'Jharkhand', label: 'Jharkhand'),
  AppDropdownItem(value: 'Karnataka', label: 'Karnataka'),
  AppDropdownItem(value: 'Kerala', label: 'Kerala'),
  AppDropdownItem(value: 'Madhya Pradesh', label: 'Madhya Pradesh'),
  AppDropdownItem(value: 'Maharashtra', label: 'Maharashtra'),
  AppDropdownItem(value: 'Manipur', label: 'Manipur'),
  AppDropdownItem(value: 'Meghalaya', label: 'Meghalaya'),
  AppDropdownItem(value: 'Mizoram', label: 'Mizoram'),
  AppDropdownItem(value: 'Nagaland', label: 'Nagaland'),
  AppDropdownItem(value: 'Odisha', label: 'Odisha'),
  AppDropdownItem(value: 'Punjab', label: 'Punjab'),
  AppDropdownItem(value: 'Rajasthan', label: 'Rajasthan'),
  AppDropdownItem(value: 'Sikkim', label: 'Sikkim'),
  AppDropdownItem(value: 'Tamil Nadu', label: 'Tamil Nadu'),
  AppDropdownItem(value: 'Telangana', label: 'Telangana'),
  AppDropdownItem(value: 'Tripura', label: 'Tripura'),
  AppDropdownItem(value: 'Uttar Pradesh', label: 'Uttar Pradesh'),
  AppDropdownItem(value: 'Uttarakhand', label: 'Uttarakhand'),
  AppDropdownItem(value: 'West Bengal', label: 'West Bengal'),
  AppDropdownItem(
    value: 'Andaman and Nicobar Islands',
    label: 'Andaman and Nicobar Islands',
  ),
  AppDropdownItem(value: 'Chandigarh', label: 'Chandigarh'),
  AppDropdownItem(
    value: 'Dadra and Nagar Haveli and Daman and Diu',
    label: 'Dadra and Nagar Haveli and Daman and Diu',
  ),
  AppDropdownItem(value: 'Delhi', label: 'Delhi'),
  AppDropdownItem(value: 'Jammu and Kashmir', label: 'Jammu and Kashmir'),
  AppDropdownItem(value: 'Ladakh', label: 'Ladakh'),
  AppDropdownItem(value: 'Lakshadweep', label: 'Lakshadweep'),
  AppDropdownItem(value: 'Puducherry', label: 'Puducherry'),
];

class _PtSlabControllers {
  _PtSlabControllers({
    String grossFrom = '0',
    String grossTo = '',
    String empTax = '0',
    String erTax = '0',
  }) : grossFrom = TextEditingController(text: grossFrom),
       grossTo = TextEditingController(text: grossTo),
       empTax = TextEditingController(text: empTax),
       erTax = TextEditingController(text: erTax);

  final TextEditingController grossFrom;
  final TextEditingController grossTo;
  final TextEditingController empTax;
  final TextEditingController erTax;

  void dispose() {
    grossFrom.dispose();
    grossTo.dispose();
    empTax.dispose();
    erTax.dispose();
  }
}

/// Company-level PF / ESI / professional tax configuration (India-oriented).
/// Payroll reads the active profile for the run month; salary components can use
/// % of basic / gross / CTC with employee vs employer role.
///
/// Professional tax slabs must follow the **fixed monthly rupee amounts** in the
/// notified schedule for the selected state/UT (not percentages).
class HrStatutorySettingsPage extends StatefulWidget {
  const HrStatutorySettingsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<HrStatutorySettingsPage> createState() =>
      _HrStatutorySettingsPageState();
}

class _HrStatutorySettingsPageState extends State<HrStatutorySettingsPage> {
  final GlobalKey<FormState> _profileFormKey = GlobalKey<FormState>();
  final HrService _hr = HrService();
  final MasterService _master = MasterService();
  final ScrollController _scroll = ScrollController();

  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<CompanyModel> _companies = const <CompanyModel>[];
  int? _companyId;
  List<ErpRecordModel> _profiles = const <ErpRecordModel>[];
  int? _selectedProfileId;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _effFromCtrl = TextEditingController();
  final TextEditingController _effToCtrl = TextEditingController();
  final TextEditingController _remarksCtrl = TextEditingController();
  bool _isActive = true;

  final TextEditingController _pfEmpCtrl = TextEditingController(text: '12');
  final TextEditingController _pfErCtrl = TextEditingController(text: '12');
  final TextEditingController _pfCeilCtrl = TextEditingController(
    text: '15000',
  );
  String _pfOn = 'basic';
  String _professionalTaxStateCode = '';

  final TextEditingController _esiEmpCtrl = TextEditingController(text: '0.75');
  final TextEditingController _esiErCtrl = TextEditingController(text: '3.25');
  final TextEditingController _esiCeilCtrl = TextEditingController(
    text: '21000',
  );
  String _esiOn = 'gross';

  final List<_PtSlabControllers> _ptSlabs = <_PtSlabControllers>[];

  static const List<AppDropdownItem<String>> _basisItems =
      <AppDropdownItem<String>>[
    AppDropdownItem(value: 'basic', label: 'Basic'),
    AppDropdownItem(value: 'gross', label: 'Gross'),
    AppDropdownItem(value: 'ctc', label: 'CTC'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _nameCtrl.dispose();
    _effFromCtrl.dispose();
    _effToCtrl.dispose();
    _remarksCtrl.dispose();
    _pfEmpCtrl.dispose();
    _pfErCtrl.dispose();
    _pfCeilCtrl.dispose();
    _esiEmpCtrl.dispose();
    _esiErCtrl.dispose();
    _esiCeilCtrl.dispose();
    for (final s in _ptSlabs) {
      s.dispose();
    }
    super.dispose();
  }

  void _clearPtSlabs() {
    for (final s in _ptSlabs) {
      s.dispose();
    }
    _ptSlabs.clear();
  }

  List<AppDropdownItem<String>> _ptStateItemsForDropdown() {
    const List<AppDropdownItem<String>> items = _kProfessionalTaxStateItems;
    final String st = _professionalTaxStateCode;
    if (st.isEmpty ||
        items.any((AppDropdownItem<String> e) => e.value == st)) {
      return items;
    }
    return <AppDropdownItem<String>>[
      items.first,
      AppDropdownItem<String>(value: st, label: '$st (saved)'),
      ...items.skip(1),
    ];
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final info = await hrSessionCompanyInfo();
      final companiesResp = await _master.companies(
        filters: const {'per_page': 200, 'sort_by': 'legal_name'},
      );
      final companies = (companiesResp.data ?? const <CompanyModel>[])
          .where((CompanyModel c) => c.isActive)
          .toList(growable: false);
      final cid =
          info.companyId ?? (companies.isEmpty ? null : companies.first.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _companies = companies;
        _companyId = cid;
      });
      if (cid != null) {
        await _reloadProfiles(selectId: _selectedProfileId);
      } else {
        setState(() {
          _profiles = const <ErpRecordModel>[];
          _loading = false;
          _error =
              'Select a company in the session header to edit statutory settings.';
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _reloadProfiles({int? selectId}) async {
    final cid = _companyId;
    if (cid == null) {
      return;
    }
    final res = await _hr.statutoryProfiles(
      filters: <String, dynamic>{'company_id': cid, 'per_page': 100},
    );
    if (!mounted) {
      return;
    }
    final rows = res.data ?? const <ErpRecordModel>[];
    setState(() {
      _profiles = rows;
      _loading = false;
    });
    final pick = selectId ?? (rows.isNotEmpty ? rows.first.id : null);
    if (pick != null && pick > 0) {
      await _hydrateProfile(pick);
    } else {
      _startNewForm();
    }
  }

  Map<String, dynamic>? _nested(dynamic v) {
    if (v is Map<String, dynamic>) {
      return v;
    }
    if (v is Map) {
      return Map<String, dynamic>.from(v);
    }
    return null;
  }

  Future<void> _hydrateProfile(int id) async {
    final res = await _hr.statutoryProfile(id);
    final row = res.data;
    if (!mounted || row == null) {
      return;
    }
    final d = row.data;
    _clearPtSlabs();
    _nameCtrl.text = d['profile_name']?.toString() ?? 'Default';
    _effFromCtrl.text = (d['effective_from']?.toString() ?? '')
        .split('T')
        .first
        .split(' ')
        .first;
    final et = d['effective_to']?.toString();
    _effToCtrl.text = et != null && et.isNotEmpty
        ? et.split('T').first.split(' ').first
        : '';
    _remarksCtrl.text = d['remarks']?.toString() ?? '';
    _professionalTaxStateCode =
        d['professional_tax_state_code']?.toString() ?? '';

    final pf = _nested(d['pf']);
    if (pf != null) {
      _pfEmpCtrl.text = pf['employee_percent']?.toString() ?? '12';
      _pfErCtrl.text = pf['employer_percent']?.toString() ?? '12';
      _pfCeilCtrl.text = pf['wage_ceiling']?.toString() ?? '';
    }
    final esi = _nested(d['esi']);
    if (esi != null) {
      _esiEmpCtrl.text = esi['employee_percent']?.toString() ?? '0.75';
      _esiErCtrl.text = esi['employer_percent']?.toString() ?? '3.25';
      _esiCeilCtrl.text = esi['gross_ceiling']?.toString() ?? '';
    }

    final slabs = d['pt_slabs'];
    if (slabs is List) {
      for (final item in slabs) {
        final m = _nested(item);
        if (m == null) {
          continue;
        }
        _ptSlabs.add(
          _PtSlabControllers(
            grossFrom: m['gross_from']?.toString() ?? '0',
            grossTo: m['gross_to']?.toString() ?? '',
            empTax: m['employee_tax_monthly']?.toString() ?? '0',
            erTax: m['employer_tax_monthly']?.toString() ?? '0',
          ),
        );
      }
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _selectedProfileId = id;
      _isActive = d['is_active'] == true || d['is_active'] == 1;
      _pfOn = pf?['calculate_on']?.toString() ?? 'basic';
      _esiOn = esi?['calculate_on']?.toString() ?? 'gross';
    });
  }

  void _startNewForm() {
    _selectedProfileId = null;
    _clearPtSlabs();
    _nameCtrl.text = 'Default';
    _effFromCtrl.clear();
    _effToCtrl.clear();
    _remarksCtrl.clear();
    _professionalTaxStateCode = '';
    _isActive = true;
    _pfEmpCtrl.text = '12';
    _pfErCtrl.text = '12';
    _pfCeilCtrl.text = '15000';
    _pfOn = 'basic';
    _esiEmpCtrl.text = '0.75';
    _esiErCtrl.text = '3.25';
    _esiCeilCtrl.text = '21000';
    _esiOn = 'gross';
    setState(() {});
  }

  Map<String, dynamic> _buildPayload() {
    final pt = <Map<String, dynamic>>[];
    for (var i = 0; i < _ptSlabs.length; i++) {
      final s = _ptSlabs[i];
      final to = s.grossTo.text.trim();
      pt.add(<String, dynamic>{
        'gross_from': double.tryParse(s.grossFrom.text.trim()) ?? 0,
        'gross_to': to.isEmpty ? null : double.tryParse(to),
        'employee_tax_monthly': double.tryParse(s.empTax.text.trim()) ?? 0,
        'employer_tax_monthly': double.tryParse(s.erTax.text.trim()) ?? 0,
        'sort_order': i,
      });
    }
    return <String, dynamic>{
      'company_id': _companyId,
      'profile_name': _nameCtrl.text.trim().isEmpty
          ? 'Default'
          : _nameCtrl.text.trim(),
      'effective_from': _effFromCtrl.text.trim(),
      'effective_to': _effToCtrl.text.trim().isEmpty
          ? null
          : _effToCtrl.text.trim(),
      'is_active': _isActive,
      'remarks': _remarksCtrl.text.trim().isEmpty
          ? null
          : _remarksCtrl.text.trim(),
      'professional_tax_state_code': _professionalTaxStateCode.isEmpty
          ? null
          : _professionalTaxStateCode,
      'pf': <String, dynamic>{
        'employee_percent': double.tryParse(_pfEmpCtrl.text.trim()) ?? 0,
        'employer_percent': double.tryParse(_pfErCtrl.text.trim()) ?? 0,
        'wage_ceiling': _pfCeilCtrl.text.trim().isEmpty
            ? null
            : double.tryParse(_pfCeilCtrl.text.trim()),
        'calculate_on': _pfOn,
      },
      'esi': <String, dynamic>{
        'employee_percent': double.tryParse(_esiEmpCtrl.text.trim()) ?? 0,
        'employer_percent': double.tryParse(_esiErCtrl.text.trim()) ?? 0,
        'gross_ceiling': _esiCeilCtrl.text.trim().isEmpty
            ? null
            : double.tryParse(_esiCeilCtrl.text.trim()),
        'calculate_on': _esiOn,
      },
      'pt_slabs': pt,
    };
  }

  Future<void> _save() async {
    if (_companyId == null) {
      return;
    }
    if (_profileFormKey.currentState?.validate() != true) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final body = _buildPayload();
      final ApiResponse<ErpRecordModel> res = _selectedProfileId == null
          ? await _hr.createStatutoryProfile(body)
          : await _hr.updateStatutoryProfile(_selectedProfileId!, body);
      if (!mounted) {
        return;
      }
      if (res.success != true || res.data == null) {
        setState(() {
          _saving = false;
          _error = res.message;
        });
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(res.message)));
      await _reloadProfiles(selectId: res.data!.id);
      setState(() => _saving = false);
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _delete() async {
    final id = _selectedProfileId;
    if (id == null) {
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete statutory profile'),
        content: const Text('Remove this PF/ESI/PT configuration?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }
    setState(() => _saving = true);
    try {
      final res = await _hr.deleteStatutoryProfile(id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(res.message)));
      _selectedProfileId = null;
      await _reloadProfiles();
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _loading
        ? const AppLoadingView(message: 'Loading statutory settings…')
        : _error != null && _profiles.isEmpty && _companyId == null
        ? AppErrorStateView(
            title: 'Statutory settings',
            message: _error!,
            onRetry: _load,
          )
        : SingleChildScrollView(
            controller: _scroll,
            padding: const EdgeInsets.all(AppUiConstants.pagePadding),
            child: Form(
              key: _profileFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppUiConstants.spacingMd,
                    ),
                    child: AppErrorStateView.inline(message: _error!),
                  ),
                Text(
                  'Configure PF, ESI, and professional tax per company. '
                  'Payroll uses the active profile for the salary month. '
                  'PT slabs must use fixed monthly amounts from the selected state/UT schedule (not %). '
                  'Gross for PT is the employee monthly gross on the active salary structure—confirm with '
                  'your consultant that this matches how that state defines taxable salary. '
                  'Use Employees → salary structures for CTC and %-based components.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppUiConstants.spacingMd),
                if (_companies.length > 1)
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Company',
                    mappedItems: _companies
                        .where((CompanyModel c) => c.id != null)
                        .map(
                          (CompanyModel c) => AppDropdownItem<int>(
                            value: c.id!,
                            label: c.toString(),
                          ),
                        )
                        .toList(growable: false),
                    initialValue: _companyId,
                    onChanged: (int? v) async {
                      if (v == null) {
                        return;
                      }
                      setState(() {
                        _companyId = v;
                        _selectedProfileId = null;
                      });
                      await _reloadProfiles();
                    },
                  ),
                const SizedBox(height: AppUiConstants.spacingMd),
                if (_profiles.isNotEmpty)
                  AppDropdownField<int?>.fromMapped(
                    labelText: 'Saved profile',
                    mappedItems: <AppDropdownItem<int?>>[
                      const AppDropdownItem<int?>(
                        value: null,
                        label: '— New profile —',
                      ),
                      ..._profiles.map(
                        (ErpRecordModel p) => AppDropdownItem<int?>(
                          value: p.id,
                          label:
                              '${p.data['profile_name'] ?? 'Profile'} · ${p.data['effective_from'] ?? ''}',
                        ),
                      ),
                    ],
                    initialValue: _selectedProfileId,
                    onChanged: (int? v) async {
                      if (v == null) {
                        _startNewForm();
                        return;
                      }
                      await _hydrateProfile(v);
                    },
                  ),
                const SizedBox(height: AppUiConstants.spacingLg),
                AppSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profile',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppUiConstants.spacingMd),
                      AppFormTextField(
                        controller: _nameCtrl,
                        labelText: 'Profile name',
                        validator: Validators.optionalMaxLength(
                          100,
                          'Profile name',
                        ),
                      ),
                      AppFormTextField(
                        controller: _effFromCtrl,
                        labelText: 'Effective from',
                        keyboardType: TextInputType.datetime,
                        inputFormatters: const [DateInputFormatter()],
                        validator: Validators.compose([
                          Validators.required('Effective from'),
                          Validators.date('Effective from'),
                        ]),
                      ),
                      AppFormTextField(
                        controller: _effToCtrl,
                        labelText: 'Effective to (optional)',
                        keyboardType: TextInputType.datetime,
                        inputFormatters: const [DateInputFormatter()],
                        validator: Validators.compose([
                          Validators.optionalDate('Effective to'),
                          Validators.optionalDateOnOrAfter(
                            'Effective to',
                            () => _effFromCtrl.text.trim(),
                            startFieldName: 'Effective from',
                          ),
                        ]),
                      ),
                      AppFormTextField(
                        controller: _remarksCtrl,
                        labelText: 'Remarks (optional)',
                        validator: Validators.optionalMaxLength(500, 'Remarks'),
                      ),
                      AppDropdownField<String>.fromMapped(
                        labelText: 'Professional tax — state / UT',
                        mappedItems: _ptStateItemsForDropdown(),
                        initialValue: _professionalTaxStateCode.isEmpty
                            ? ''
                            : _professionalTaxStateCode,
                        onChanged: (String? v) => setState(
                          () => _professionalTaxStateCode = v ?? '',
                        ),
                        validator: Validators.optionalMaxLength(
                          64,
                          'Professional tax state',
                        ),
                      ),
                      AppSwitchTile(
                        label: 'Active',
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppUiConstants.spacingMd),
                AppSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Provident fund (PF)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppUiConstants.spacingMd),
                      AppDropdownField<String>.fromMapped(
                        labelText: 'Calculate employee share on',
                        mappedItems: _basisItems,
                        initialValue: _pfOn,
                        onChanged: (String? v) =>
                            setState(() => _pfOn = v ?? 'basic'),
                      ),
                      AppFormTextField(
                        controller: _pfEmpCtrl,
                        labelText: 'Employee %',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: percentField0To100Optional('Employee %'),
                      ),
                      AppFormTextField(
                        controller: _pfErCtrl,
                        labelText: 'Employer %',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: percentField0To100Optional('Employer %'),
                      ),
                      AppFormTextField(
                        controller: _pfCeilCtrl,
                        labelText: 'Wage ceiling (optional, e.g. 15000)',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: Validators.optionalNonNegativeNumber(
                          'Wage ceiling',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppUiConstants.spacingMd),
                AppSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ESI',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppUiConstants.spacingMd),
                      AppDropdownField<String>.fromMapped(
                        labelText: 'Calculate on',
                        mappedItems: _basisItems,
                        initialValue: _esiOn,
                        onChanged: (String? v) =>
                            setState(() => _esiOn = v ?? 'gross'),
                      ),
                      AppFormTextField(
                        controller: _esiEmpCtrl,
                        labelText: 'Employee %',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: percentField0To100Optional('Employee %'),
                      ),
                      AppFormTextField(
                        controller: _esiErCtrl,
                        labelText: 'Employer %',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: percentField0To100Optional('Employer %'),
                      ),
                      AppFormTextField(
                        controller: _esiCeilCtrl,
                        labelText: 'Gross ceiling (optional, e.g. 21000)',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: Validators.optionalNonNegativeNumber(
                          'Gross ceiling',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppUiConstants.spacingMd),
                AppSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Professional tax — gross slabs (state schedule)',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _ptSlabs.add(_PtSlabControllers());
                              });
                            },
                            icon: const Icon(Icons.add, size: 20),
                            label: const Text('Add slab'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppUiConstants.spacingSm),
                      Text(
                        'Enter each slab as in the notified rules: monthly gross from/to (₹) and '
                        'fixed tax per month (₹). Employer column is usually zero; use only if your schedule includes it.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppUiConstants.spacingSm),
                      ...List<Widget>.generate(_ptSlabs.length, (int i) {
                        final s = _ptSlabs[i];
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppUiConstants.spacingSm,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: AppFormTextField(
                                  controller: s.grossFrom,
                                  labelText: 'Monthly gross from (₹)',
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  validator: Validators.optionalNonNegativeNumber(
                                    'Gross from',
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppUiConstants.spacingSm),
                              Expanded(
                                child: AppFormTextField(
                                  controller: s.grossTo,
                                  labelText: 'Monthly gross to (₹, empty = no upper)',
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  validator: Validators.optionalNonNegativeNumber(
                                    'Gross to',
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppUiConstants.spacingSm),
                              Expanded(
                                child: AppFormTextField(
                                  controller: s.empTax,
                                  labelText: 'Employee PT / month (₹)',
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  validator: Validators.optionalNonNegativeNumber(
                                    'Employee PT',
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppUiConstants.spacingSm),
                              Expanded(
                                child: AppFormTextField(
                                  controller: s.erTax,
                                  labelText: 'Employer PT / month (₹)',
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  validator: Validators.optionalNonNegativeNumber(
                                    'Employer PT',
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Remove',
                                onPressed: () {
                                  setState(() {
                                    _ptSlabs[i].dispose();
                                    _ptSlabs.removeAt(i);
                                  });
                                },
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: AppUiConstants.spacingLg),
                Wrap(
                  spacing: AppUiConstants.spacingSm,
                  runSpacing: AppUiConstants.spacingSm,
                  children: [
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _selectedProfileId == null
                                  ? 'Create profile'
                                  : 'Update profile',
                            ),
                    ),
                    if (_selectedProfileId != null)
                      FilledButton.tonal(
                        onPressed: _saving ? null : _delete,
                        child: const Text('Delete'),
                      ),
                  ],
                ),
              ],
            ),
            ),
          );

    if (widget.embedded) {
      return body;
    }
    return AppStandaloneShell(
      title: 'HR · PF, ESI & PT',
      scrollController: _scroll,
      actions: [],
      child: body,
    );
  }
}
