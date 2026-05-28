import '../../screen.dart';

class HrPtSlabControllers {
  HrPtSlabControllers({
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

class HrStatutorySettingsController extends GetxController {
  HrStatutorySettingsController();

  static const List<AppDropdownItem<String>> basisItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'basic', label: 'Basic'),
        AppDropdownItem(value: 'gross', label: 'Gross'),
        AppDropdownItem(value: 'ctc', label: 'CTC'),
      ];

  final HrService hr = HrService();
  final MasterService master = MasterService();
  final ScrollController scroll = ScrollController();

  bool loading = true;
  bool saving = false;
  String? error;
  List<CompanyModel> companies = const <CompanyModel>[];
  int? companyId;
  List<ErpRecordModel> profiles = const <ErpRecordModel>[];
  int? selectedProfileId;

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController effFromCtrl = TextEditingController();
  final TextEditingController effToCtrl = TextEditingController();
  final TextEditingController remarksCtrl = TextEditingController();
  bool isActive = true;

  final TextEditingController pfEmpCtrl = TextEditingController(text: '12');
  final TextEditingController pfErCtrl = TextEditingController(text: '12');
  final TextEditingController pfCeilCtrl = TextEditingController(text: '15000');
  String pfOn = 'basic';
  String professionalTaxStateCode = '';

  final TextEditingController esiEmpCtrl = TextEditingController(text: '0.75');
  final TextEditingController esiErCtrl = TextEditingController(text: '3.25');
  final TextEditingController esiCeilCtrl = TextEditingController(
    text: '21000',
  );
  String esiOn = 'gross';

  final List<HrPtSlabControllers> ptSlabs = <HrPtSlabControllers>[];

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    scroll.dispose();
    nameCtrl.dispose();
    effFromCtrl.dispose();
    effToCtrl.dispose();
    remarksCtrl.dispose();
    pfEmpCtrl.dispose();
    pfErCtrl.dispose();
    pfCeilCtrl.dispose();
    esiEmpCtrl.dispose();
    esiErCtrl.dispose();
    esiCeilCtrl.dispose();
    clearPtSlabs();
    super.onClose();
  }

  void clearPtSlabs() {
    for (final s in ptSlabs) {
      s.dispose();
    }
    ptSlabs.clear();
  }

  Future<void> load() async {
    loading = true;
    error = null;
    update();
    try {
      final info = await hrSessionCompanyInfo();
      final companiesResp = await master.companies(
        filters: const {'per_page': 200, 'sort_by': 'legal_name'},
      );
      final nextCompanies = (companiesResp.data ?? const <CompanyModel>[])
          .where((CompanyModel c) => c.isActive)
          .toList(growable: false);
      final cid =
          info.companyId ??
          (nextCompanies.isEmpty ? null : nextCompanies.first.id);
      companies = nextCompanies;
      companyId = cid;
      if (cid != null) {
        await reloadProfiles(selectId: selectedProfileId);
      } else {
        profiles = const <ErpRecordModel>[];
        loading = false;
        error =
            'Select a company in the session header to edit statutory settings.';
        update();
      }
    } catch (errorValue) {
      error = errorValue.toString();
      loading = false;
      update();
    }
  }

  Future<void> reloadProfiles({int? selectId}) async {
    final cid = companyId;
    if (cid == null) {
      return;
    }
    final res = await hr.statutoryProfiles(
      filters: <String, dynamic>{'company_id': cid, 'per_page': 100},
    );
    profiles = res.data ?? const <ErpRecordModel>[];
    loading = false;
    update();
    final pick = selectId ?? (profiles.isNotEmpty ? profiles.first.id : null);
    if (pick != null && pick > 0) {
      await hydrateProfile(pick);
    } else {
      startNewForm();
    }
  }

  Map<String, dynamic>? nested(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  Future<void> hydrateProfile(int id) async {
    final res = await hr.statutoryProfile(id);
    final row = res.data;
    if (row == null) {
      return;
    }
    final data = row.toJson();
    clearPtSlabs();
    nameCtrl.text = data['profile_name']?.toString() ?? 'Default';
    effFromCtrl.text = (data['effective_from']?.toString() ?? '')
        .split('T')
        .first
        .split(' ')
        .first;
    final effectiveTo = data['effective_to']?.toString();
    effToCtrl.text = effectiveTo != null && effectiveTo.isNotEmpty
        ? effectiveTo.split('T').first.split(' ').first
        : '';
    remarksCtrl.text = data['remarks']?.toString() ?? '';
    professionalTaxStateCode =
        data['professional_tax_state_code']?.toString() ?? '';

    final pf = nested(data['pf']);
    if (pf != null) {
      pfEmpCtrl.text = pf['employee_percent']?.toString() ?? '12';
      pfErCtrl.text = pf['employer_percent']?.toString() ?? '12';
      pfCeilCtrl.text = pf['wage_ceiling']?.toString() ?? '';
    }
    final esi = nested(data['esi']);
    if (esi != null) {
      esiEmpCtrl.text = esi['employee_percent']?.toString() ?? '0.75';
      esiErCtrl.text = esi['employer_percent']?.toString() ?? '3.25';
      esiCeilCtrl.text = esi['gross_ceiling']?.toString() ?? '';
    }
    final slabs = data['pt_slabs'];
    if (slabs is List) {
      for (final item in slabs) {
        final mapped = nested(item);
        if (mapped == null) {
          continue;
        }
        ptSlabs.add(
          HrPtSlabControllers(
            grossFrom: mapped['gross_from']?.toString() ?? '0',
            grossTo: mapped['gross_to']?.toString() ?? '',
            empTax: mapped['employee_tax_monthly']?.toString() ?? '0',
            erTax: mapped['employer_tax_monthly']?.toString() ?? '0',
          ),
        );
      }
    }
    selectedProfileId = id;
    isActive = data['is_active'] == true || data['is_active'] == 1;
    pfOn = pf?['calculate_on']?.toString() ?? 'basic';
    esiOn = esi?['calculate_on']?.toString() ?? 'gross';
    update();
  }

  void startNewForm() {
    selectedProfileId = null;
    clearPtSlabs();
    nameCtrl.text = 'Default';
    effFromCtrl.clear();
    effToCtrl.clear();
    remarksCtrl.clear();
    professionalTaxStateCode = '';
    isActive = true;
    pfEmpCtrl.text = '12';
    pfErCtrl.text = '12';
    pfCeilCtrl.text = '15000';
    pfOn = 'basic';
    esiEmpCtrl.text = '0.75';
    esiErCtrl.text = '3.25';
    esiCeilCtrl.text = '21000';
    esiOn = 'gross';
    update();
  }

  Map<String, dynamic> buildPayload() {
    final pt = <Map<String, dynamic>>[];
    for (var i = 0; i < ptSlabs.length; i++) {
      final slab = ptSlabs[i];
      final upper = slab.grossTo.text.trim();
      pt.add(<String, dynamic>{
        'gross_from': double.tryParse(slab.grossFrom.text.trim()) ?? 0,
        'gross_to': upper.isEmpty ? null : double.tryParse(upper),
        'employee_tax_monthly': double.tryParse(slab.empTax.text.trim()) ?? 0,
        'employer_tax_monthly': double.tryParse(slab.erTax.text.trim()) ?? 0,
        'sort_order': i,
      });
    }
    return <String, dynamic>{
      'company_id': companyId,
      'profile_name': nameCtrl.text.trim().isEmpty
          ? 'Default'
          : nameCtrl.text.trim(),
      'effective_from': effFromCtrl.text.trim(),
      'effective_to': effToCtrl.text.trim().isEmpty
          ? null
          : effToCtrl.text.trim(),
      'is_active': isActive,
      'remarks': remarksCtrl.text.trim().isEmpty
          ? null
          : remarksCtrl.text.trim(),
      'professional_tax_state_code': professionalTaxStateCode.isEmpty
          ? null
          : professionalTaxStateCode,
      'pf': <String, dynamic>{
        'employee_percent': double.tryParse(pfEmpCtrl.text.trim()) ?? 0,
        'employer_percent': double.tryParse(pfErCtrl.text.trim()) ?? 0,
        'wage_ceiling': pfCeilCtrl.text.trim().isEmpty
            ? null
            : double.tryParse(pfCeilCtrl.text.trim()),
        'calculate_on': pfOn,
      },
      'esi': <String, dynamic>{
        'employee_percent': double.tryParse(esiEmpCtrl.text.trim()) ?? 0,
        'employer_percent': double.tryParse(esiErCtrl.text.trim()) ?? 0,
        'gross_ceiling': esiCeilCtrl.text.trim().isEmpty
            ? null
            : double.tryParse(esiCeilCtrl.text.trim()),
        'calculate_on': esiOn,
      },
      'pt_slabs': pt,
    };
  }

  Future<void> save({FormState? formState}) async {
    if (companyId == null) {
      return;
    }
    if (formState?.validate() != true) {
      return;
    }
    saving = true;
    error = null;
    update();
    try {
      final body = buildPayload();
      final ApiResponse<ErpRecordModel> res = selectedProfileId == null
          ? await hr.createStatutoryProfile(body)
          : await hr.updateStatutoryProfile(selectedProfileId!, body);
      if (res.success != true || res.data == null) {
        saving = false;
        error = res.message;
        update();
        return;
      }
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(res.message)),
      );
      await reloadProfiles(selectId: res.data!.id);
    } catch (errorValue) {
      error = errorValue.toString();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> deleteProfile() async {
    final id = selectedProfileId;
    if (id == null) {
      return;
    }
    saving = true;
    update();
    try {
      final res = await hr.deleteStatutoryProfile(id);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(res.message)),
      );
      selectedProfileId = null;
      await reloadProfiles();
    } catch (errorValue) {
      error = errorValue.toString();
    } finally {
      saving = false;
      update();
    }
  }

  void setProfessionalTaxStateCode(String? value) {
    professionalTaxStateCode = value ?? '';
    update();
  }

  void setIsActive(bool value) {
    isActive = value;
    update();
  }

  void setPfOn(String? value) {
    pfOn = value ?? 'basic';
    update();
  }

  void setEsiOn(String? value) {
    esiOn = value ?? 'gross';
    update();
  }

  void addPtSlab() {
    ptSlabs.add(HrPtSlabControllers());
    update();
  }

  void removePtSlabAt(int index) {
    final removed = ptSlabs.removeAt(index);
    update();
    disposeDraftEntriesNextFrame<HrPtSlabControllers>([
      removed,
    ], (entry) => entry.dispose());
  }
}
