import 'package:flutter/material.dart';

import '../../../app/constants/app_ui_constants.dart';
import '../../../app/theme/app_theme_extension.dart';
import '../../../components/adaptive_shell.dart';
import '../../../components/app_loading_view.dart';
import '../../../core/storage/session_storage.dart';
import '../../../model/app/public_branding_model.dart';
import '../../../model/masters/branch_model.dart';
import '../../../model/masters/business_location_model.dart';
import '../../../model/masters/company_model.dart';
import '../../../model/masters/warehouse_model.dart';
import '../../../service/app/app_session_service.dart';
import '../../../service/master/master_service.dart';
import '../../core/page_shell_actions.dart';

class CompanyManagementPage extends StatefulWidget {
  const CompanyManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<CompanyManagementPage> createState() => _CompanyManagementPageState();
}

class _CompanyManagementPageState extends State<CompanyManagementPage> {
  final MasterService _masterService = MasterService();
  final ScrollController _pageScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _legalNameController = TextEditingController();
  final TextEditingController _tradeNameController = TextEditingController();
  final TextEditingController _gstinController = TextEditingController();
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _currencyController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  List<CompanyModel> _companies = const <CompanyModel>[];
  List<CompanyModel> _filteredCompanies = const <CompanyModel>[];
  CompanyModel? _selectedCompany;
  bool _isActive = true;
  String _companyType = 'private_limited';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applySearch);
    _loadCompanies();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _searchController.dispose();
    _codeController.dispose();
    _legalNameController.dispose();
    _tradeNameController.dispose();
    _gstinController.dispose();
    _panController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _currencyController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadCompanies({int? selectId}) async {
    setState(() {
      _initialLoading = _companies.isEmpty;
      _pageError = null;
    });

    try {
      final response = await _masterService.companies(
        filters: const {'per_page': 100, 'sort_by': 'legal_name'},
      );
      final items = response.data ?? const <CompanyModel>[];
      if (!mounted) {
        return;
      }

      setState(() {
        _companies = items;
        _filteredCompanies = _filterList(items, _searchController.text, (
          company,
        ) {
          return [
            company.code ?? '',
            company.legalName ?? '',
            company.tradeName ?? '',
            company.city ?? '',
          ];
        });
        _initialLoading = false;
      });

      final selected = selectId != null
          ? items.cast<CompanyModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (_selectedCompany == null
                ? (items.isNotEmpty ? items.first : null)
                : items.cast<CompanyModel?>().firstWhere(
                    (item) => item?.id == _selectedCompany?.id,
                    orElse: () => items.isNotEmpty ? items.first : null,
                  ));

      if (selected != null) {
        _selectCompany(selected);
      } else {
        _resetForm();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _initialLoading = false;
        _pageError = error.toString();
      });
    }
  }

  void _applySearch() {
    setState(() {
      _filteredCompanies = _filterList(_companies, _searchController.text, (
        company,
      ) {
        return [
          company.code ?? '',
          company.legalName ?? '',
          company.tradeName ?? '',
          company.city ?? '',
        ];
      });
    });
  }

  void _selectCompany(CompanyModel company) {
    _selectedCompany = company;
    _codeController.text = company.code ?? '';
    _legalNameController.text = company.legalName ?? '';
    _tradeNameController.text = company.tradeName ?? '';
    _gstinController.text = company.gstin ?? '';
    _panController.text = company.pan ?? '';
    _phoneController.text = company.phone ?? '';
    _emailController.text = company.email ?? '';
    _websiteController.text = company.website ?? '';
    _cityController.text = company.city ?? '';
    _stateController.text = company.stateName ?? company.stateCode ?? '';
    _currencyController.text = company.baseCurrency ?? 'INR';
    _remarksController.text = company.remarks ?? '';
    _companyType = company.companyType ?? 'private_limited';
    _isActive = company.isActive;
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedCompany = null;
    _codeController.clear();
    _legalNameController.clear();
    _tradeNameController.clear();
    _gstinController.clear();
    _panController.clear();
    _phoneController.clear();
    _emailController.clear();
    _websiteController.clear();
    _cityController.clear();
    _stateController.clear();
    _currencyController.text = 'INR';
    _remarksController.clear();
    _companyType = 'private_limited';
    _isActive = true;
    _formError = null;
    setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    final model = CompanyModel(
      id: _selectedCompany?.id,
      code: _codeController.text.trim(),
      legalName: _legalNameController.text.trim(),
      tradeName: _nullIfEmpty(_tradeNameController.text),
      companyType: _companyType,
      gstin: _nullIfEmpty(_gstinController.text),
      pan: _nullIfEmpty(_panController.text),
      phone: _nullIfEmpty(_phoneController.text),
      email: _nullIfEmpty(_emailController.text),
      website: _nullIfEmpty(_websiteController.text),
      city: _nullIfEmpty(_cityController.text),
      stateName: _nullIfEmpty(_stateController.text),
      baseCurrency: _nullIfEmpty(_currencyController.text) ?? 'INR',
      remarks: _nullIfEmpty(_remarksController.text),
      isActive: _isActive,
    );

    try {
      final response = _selectedCompany == null
          ? await _masterService.createCompany(model)
          : await _masterService.updateCompany(_selectedCompany!.id!, model);

      final saved = response.data;
      if (!mounted) {
        return;
      }
      if (saved == null) {
        setState(() {
          _formError = response.message;
        });
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadCompanies(selectId: saved.id);
    } catch (error) {
      setState(() {
        _formError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    final actions = [
      AdaptiveShellActionButton(
        onPressed: _resetForm,
        icon: Icons.add_business_outlined,
        label: 'New Company',
      ),
    ];

    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }

    return FutureBuilder<PublicBrandingModel?>(
      future: SessionStorage.getBranding(),
      builder: (context, snapshot) {
        final branding =
            snapshot.data ??
            const PublicBrandingModel(companyName: 'Billing ERP');

        return AdaptiveShell(
          title: 'Companies',
          branding: branding,
          scrollController: _pageScrollController,
          actions: actions,
          onLogout: () async {
            await AppSessionService.instance.clearSession();
            if (context.mounted) {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/login', (_) => false);
            }
          },
          child: content,
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading companies...');
    }
    if (_pageError != null) {
      return Center(child: Text(_pageError!));
    }

    return _MasterWorkspace(
      scrollController: _pageScrollController,
      list: _MasterListCard<CompanyModel>(
        title: 'Company Directory',
        subtitle: 'Legal entities and base configuration.',
        searchController: _searchController,
        searchHint: 'Search companies',
        items: _filteredCompanies,
        selectedItem: _selectedCompany,
        emptyMessage: 'No companies found.',
        itemBuilder: (company, selected) => _MasterListTile(
          title: company.legalName ?? '',
          subtitle: [
            company.code ?? '',
            company.city ?? '',
            company.stateName ?? '',
          ].where((item) => item.isNotEmpty).join(' • '),
          selected: selected,
          trailing: _StatusPill(
            label: company.isActive ? 'Active' : 'Inactive',
            active: company.isActive,
          ),
          onTap: () => _selectCompany(company),
        ),
      ),
      editor: _MasterEditorCard(
        title: _selectedCompany == null ? 'Create Company' : 'Edit Company',
        subtitle:
            'Keep company-level legal identity, tax identifiers, and base contact details here.',
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MasterFormWrap(
                children: [
                  _textField(
                    controller: _codeController,
                    label: 'Code',
                    required: true,
                  ),
                  _textField(
                    controller: _legalNameController,
                    label: 'Legal Name',
                    required: true,
                  ),
                  _textField(
                    controller: _tradeNameController,
                    label: 'Trade Name',
                  ),
                  _dropdownField<String>(
                    value: _companyType,
                    label: 'Company Type',
                    items: const [
                      DropdownMenuItem(
                        value: 'private_limited',
                        child: Text('Private Limited'),
                      ),
                      DropdownMenuItem(
                        value: 'proprietorship',
                        child: Text('Proprietorship'),
                      ),
                      DropdownMenuItem(
                        value: 'partnership',
                        child: Text('Partnership'),
                      ),
                      DropdownMenuItem(value: 'llp', child: Text('LLP')),
                      DropdownMenuItem(
                        value: 'public_limited',
                        child: Text('Public Limited'),
                      ),
                      DropdownMenuItem(value: 'trust', child: Text('Trust')),
                      DropdownMenuItem(
                        value: 'society',
                        child: Text('Society'),
                      ),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (value) =>
                        setState(() => _companyType = value ?? _companyType),
                  ),
                  _textField(controller: _gstinController, label: 'GSTIN'),
                  _textField(controller: _panController, label: 'PAN'),
                  _textField(controller: _phoneController, label: 'Phone'),
                  _textField(controller: _emailController, label: 'Email'),
                  _textField(controller: _websiteController, label: 'Website'),
                  _textField(controller: _cityController, label: 'City'),
                  _textField(controller: _stateController, label: 'State Name'),
                  _textField(
                    controller: _currencyController,
                    label: 'Base Currency',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                subtitle: const Text(
                  'Inactive companies stay visible but should not be used for new work.',
                ),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _remarksController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Remarks'),
              ),
              if ((_formError ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  _formError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: Icon(
                      _selectedCompany == null
                          ? Icons.add
                          : Icons.save_outlined,
                    ),
                    label: Text(_saving ? 'Saving...' : 'Save Company'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _resetForm,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BranchManagementPage extends StatefulWidget {
  const BranchManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<BranchManagementPage> createState() => _BranchManagementPageState();
}

class _BranchManagementPageState extends State<BranchManagementPage> {
  final MasterService _masterService = MasterService();
  final ScrollController _pageScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  List<BranchModel> _branches = const <BranchModel>[];
  List<BranchModel> _filteredBranches = const <BranchModel>[];
  List<CompanyModel> _companies = const <CompanyModel>[];
  BranchModel? _selectedBranch;
  int? _companyId;
  String _branchType = 'branch_office';
  bool _isHeadOffice = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applySearch);
    _loadData();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _searchController.dispose();
    _codeController.dispose();
    _nameController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadData({int? selectId}) async {
    setState(() {
      _initialLoading = _branches.isEmpty;
      _pageError = null;
    });

    try {
      final responses = await Future.wait([
        _masterService.branches(
          filters: const {'per_page': 100, 'sort_by': 'name'},
        ),
        _masterService.companies(
          filters: const {'per_page': 100, 'sort_by': 'legal_name'},
        ),
      ]);

      final branches =
          responses[0].data as List<BranchModel>? ?? const <BranchModel>[];
      final companies =
          responses[1].data as List<CompanyModel>? ?? const <CompanyModel>[];
      if (!mounted) {
        return;
      }

      setState(() {
        _branches = branches;
        _companies = companies;
        _filteredBranches = _filterList(branches, _searchController.text, (
          branch,
        ) {
          return [branch.code ?? '', branch.name ?? ''];
        });
        _initialLoading = false;
      });

      final selected = selectId != null
          ? branches.cast<BranchModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (_selectedBranch == null
                ? (branches.isNotEmpty ? branches.first : null)
                : branches.cast<BranchModel?>().firstWhere(
                    (item) => item?.id == _selectedBranch?.id,
                    orElse: () => branches.isNotEmpty ? branches.first : null,
                  ));

      if (selected != null) {
        _selectBranch(selected);
      } else {
        _resetForm();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _initialLoading = false;
        _pageError = error.toString();
      });
    }
  }

  void _applySearch() {
    setState(() {
      _filteredBranches = _filterList(_branches, _searchController.text, (
        branch,
      ) {
        return [branch.code ?? '', branch.name ?? ''];
      });
    });
  }

  void _selectBranch(BranchModel branch) {
    _selectedBranch = branch;
    _companyId = branch.companyId;
    _codeController.text = branch.code ?? '';
    _nameController.text = branch.name ?? '';
    _branchType = branch.branchType ?? 'branch_office';
    _isHeadOffice = branch.isHeadOffice;
    _isActive = branch.isActive;
    _remarksController.text = branch.remarks ?? '';
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedBranch = null;
    _companyId = _companies.isNotEmpty ? _companies.first.id : null;
    _codeController.clear();
    _nameController.clear();
    _branchType = 'branch_office';
    _isHeadOffice = false;
    _isActive = true;
    _remarksController.clear();
    _formError = null;
    setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    final model = BranchModel(
      id: _selectedBranch?.id,
      companyId: _companyId,
      code: _codeController.text.trim(),
      name: _nameController.text.trim(),
      branchType: _branchType,
      isHeadOffice: _isHeadOffice,
      isActive: _isActive,
      remarks: _nullIfEmpty(_remarksController.text),
    );

    try {
      final response = _selectedBranch == null
          ? await _masterService.createBranch(model)
          : await _masterService.updateBranch(_selectedBranch!.id!, model);
      final saved = response.data;
      if (!mounted) {
        return;
      }
      if (saved == null) {
        setState(() => _formError = response.message);
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadData(selectId: saved.id);
    } catch (error) {
      setState(() => _formError = error.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    final actions = [
      AdaptiveShellActionButton(
        onPressed: _resetForm,
        icon: Icons.add,
        label: 'New Branch',
      ),
    ];

    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }

    return _StandaloneMasterShell(
      title: 'Branches',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading branches...');
    }
    if (_pageError != null) {
      return Center(child: Text(_pageError!));
    }

    return _MasterWorkspace(
      scrollController: _pageScrollController,
      list: _MasterListCard<BranchModel>(
        title: 'Branch Structure',
        subtitle: 'Organizational and accounting units under each company.',
        searchController: _searchController,
        searchHint: 'Search branches',
        items: _filteredBranches,
        selectedItem: _selectedBranch,
        emptyMessage: 'No branches found.',
        itemBuilder: (branch, selected) => _MasterListTile(
          title: branch.name ?? '',
          subtitle: [
            branch.code ?? '',
            _companyName(_companies, branch.companyId),
            branch.branchType?.replaceAll('_', ' ') ?? '',
          ].where((item) => item.isNotEmpty).join(' • '),
          selected: selected,
          trailing: _StatusPill(
            label: branch.isActive ? 'Active' : 'Inactive',
            active: branch.isActive,
          ),
          onTap: () => _selectBranch(branch),
        ),
      ),
      editor: _MasterEditorCard(
        title: _selectedBranch == null ? 'Create Branch' : 'Edit Branch',
        subtitle:
            'Use branches for organizational ownership and reporting context.',
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MasterFormWrap(
                children: [
                  _dropdownField<int>(
                    value: _companyId,
                    label: 'Company',
                    items: _companies
                        .map(
                          (company) => DropdownMenuItem<int>(
                            value: company.id,
                            child: Text(company.legalName ?? ''),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) => setState(() => _companyId = value),
                    validator: (value) =>
                        value == null ? 'Company is required' : null,
                  ),
                  _textField(
                    controller: _codeController,
                    label: 'Code',
                    required: true,
                  ),
                  _textField(
                    controller: _nameController,
                    label: 'Name',
                    required: true,
                  ),
                  _dropdownField<String>(
                    value: _branchType,
                    label: 'Branch Type',
                    items: const [
                      DropdownMenuItem(
                        value: 'head_office',
                        child: Text('Head Office'),
                      ),
                      DropdownMenuItem(
                        value: 'branch_office',
                        child: Text('Branch Office'),
                      ),
                      DropdownMenuItem(
                        value: 'factory',
                        child: Text('Factory'),
                      ),
                      DropdownMenuItem(
                        value: 'warehouse_office',
                        child: Text('Warehouse Office'),
                      ),
                      DropdownMenuItem(
                        value: 'retail_outlet',
                        child: Text('Retail Outlet'),
                      ),
                      DropdownMenuItem(
                        value: 'service_center',
                        child: Text('Service Center'),
                      ),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (value) =>
                        setState(() => _branchType = value ?? _branchType),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Head Office'),
                subtitle: const Text(
                  'Mark only one branch per company as head office.',
                ),
                value: _isHeadOffice,
                onChanged: (value) => setState(() => _isHeadOffice = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _remarksController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Remarks'),
              ),
              if ((_formError ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  _formError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: Icon(
                      _selectedBranch == null ? Icons.add : Icons.save,
                    ),
                    label: Text(_saving ? 'Saving...' : 'Save Branch'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _resetForm,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BusinessLocationManagementPage extends StatefulWidget {
  const BusinessLocationManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<BusinessLocationManagementPage> createState() =>
      _BusinessLocationManagementPageState();
}

class _BusinessLocationManagementPageState
    extends State<BusinessLocationManagementPage> {
  final MasterService _masterService = MasterService();
  final ScrollController _pageScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  List<BusinessLocationModel> _locations = const <BusinessLocationModel>[];
  List<BusinessLocationModel> _filteredLocations =
      const <BusinessLocationModel>[];
  List<CompanyModel> _companies = const <CompanyModel>[];
  List<BranchModel> _branches = const <BranchModel>[];
  BusinessLocationModel? _selectedLocation;
  int? _companyId;
  int? _branchId;
  String _locationType = 'billing';
  bool _allowSales = true;
  bool _allowPurchase = true;
  bool _allowStock = true;
  bool _allowAccounts = true;
  bool _allowHr = true;
  bool _isDefault = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applySearch);
    _loadData();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _searchController.dispose();
    _codeController.dispose();
    _nameController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _addressController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadData({int? selectId}) async {
    setState(() {
      _initialLoading = _locations.isEmpty;
      _pageError = null;
    });

    try {
      final responses = await Future.wait([
        _masterService.businessLocations(
          filters: const {'per_page': 100, 'sort_by': 'name'},
        ),
        _masterService.companies(filters: const {'per_page': 100}),
        _masterService.branches(filters: const {'per_page': 100}),
      ]);

      final locations =
          responses[0].data as List<BusinessLocationModel>? ??
          const <BusinessLocationModel>[];
      final companies =
          responses[1].data as List<CompanyModel>? ?? const <CompanyModel>[];
      final branches =
          responses[2].data as List<BranchModel>? ?? const <BranchModel>[];
      if (!mounted) {
        return;
      }

      setState(() {
        _locations = locations;
        _companies = companies;
        _branches = branches;
        _filteredLocations = _filterList(locations, _searchController.text, (
          location,
        ) {
          return [
            location.code ?? '',
            location.name ?? '',
            location.city ?? '',
          ];
        });
        _initialLoading = false;
      });

      final selected = selectId != null
          ? locations.cast<BusinessLocationModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (_selectedLocation == null
                ? (locations.isNotEmpty ? locations.first : null)
                : locations.cast<BusinessLocationModel?>().firstWhere(
                    (item) => item?.id == _selectedLocation?.id,
                    orElse: () => locations.isNotEmpty ? locations.first : null,
                  ));

      if (selected != null) {
        _selectLocation(selected);
      } else {
        _resetForm();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _initialLoading = false;
        _pageError = error.toString();
      });
    }
  }

  void _applySearch() {
    setState(() {
      _filteredLocations = _filterList(_locations, _searchController.text, (
        location,
      ) {
        return [location.code ?? '', location.name ?? '', location.city ?? ''];
      });
    });
  }

  void _selectLocation(BusinessLocationModel location) {
    _selectedLocation = location;
    _companyId = location.companyId;
    _branchId = location.branchId;
    _codeController.text = location.code ?? '';
    _nameController.text = location.name ?? '';
    _contactController.text = location.contactPerson ?? '';
    _phoneController.text = location.phone ?? '';
    _emailController.text = location.email ?? '';
    _cityController.text = location.city ?? '';
    _stateController.text = location.stateName ?? location.stateCode ?? '';
    _addressController.text = location.addressLine1 ?? '';
    _locationType = location.locationType ?? 'billing';
    _allowSales = location.allowSales;
    _allowPurchase = location.allowPurchase;
    _allowStock = location.allowStock;
    _allowAccounts = location.allowAccounts;
    _allowHr = location.allowHr;
    _isDefault = location.isDefault;
    _isActive = location.isActive;
    _remarksController.text = location.remarks ?? '';
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedLocation = null;
    _companyId = _companies.isNotEmpty ? _companies.first.id : null;
    _branchId = _branchesForCompany(_companyId).isNotEmpty
        ? _branchesForCompany(_companyId).first.id
        : null;
    _codeController.clear();
    _nameController.clear();
    _contactController.clear();
    _phoneController.clear();
    _emailController.clear();
    _cityController.clear();
    _stateController.clear();
    _addressController.clear();
    _locationType = 'billing';
    _allowSales = true;
    _allowPurchase = true;
    _allowStock = true;
    _allowAccounts = true;
    _allowHr = true;
    _isDefault = false;
    _isActive = true;
    _remarksController.clear();
    _formError = null;
    setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    final model = BusinessLocationModel(
      id: _selectedLocation?.id,
      companyId: _companyId,
      branchId: _branchId,
      code: _codeController.text.trim(),
      name: _nameController.text.trim(),
      locationType: _locationType,
      contactPerson: _nullIfEmpty(_contactController.text),
      phone: _nullIfEmpty(_phoneController.text),
      email: _nullIfEmpty(_emailController.text),
      addressLine1: _nullIfEmpty(_addressController.text),
      city: _nullIfEmpty(_cityController.text),
      stateName: _nullIfEmpty(_stateController.text),
      allowSales: _allowSales,
      allowPurchase: _allowPurchase,
      allowStock: _allowStock,
      allowAccounts: _allowAccounts,
      allowHr: _allowHr,
      isDefault: _isDefault,
      isActive: _isActive,
      remarks: _nullIfEmpty(_remarksController.text),
    );

    try {
      final response = _selectedLocation == null
          ? await _masterService.createBusinessLocation(model)
          : await _masterService.updateBusinessLocation(
              _selectedLocation!.id!,
              model,
            );
      final saved = response.data;
      if (!mounted) {
        return;
      }
      if (saved == null) {
        setState(() => _formError = response.message);
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadData(selectId: saved.id);
    } catch (error) {
      setState(() => _formError = error.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    final actions = [
      AdaptiveShellActionButton(
        onPressed: _resetForm,
        icon: Icons.add_location_alt_outlined,
        label: 'New Location',
      ),
    ];

    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }

    return _StandaloneMasterShell(
      title: 'Business Locations',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading business locations...');
    }
    if (_pageError != null) {
      return Center(child: Text(_pageError!));
    }

    final filteredBranches = _branchesForCompany(_companyId);

    return _MasterWorkspace(
      scrollController: _pageScrollController,
      list: _MasterListCard<BusinessLocationModel>(
        title: 'Business Locations',
        subtitle:
            'Physical operating sites used by sales, purchase, stock, and accounts.',
        searchController: _searchController,
        searchHint: 'Search locations',
        items: _filteredLocations,
        selectedItem: _selectedLocation,
        emptyMessage: 'No business locations found.',
        itemBuilder: (location, selected) => _MasterListTile(
          title: location.name ?? '',
          subtitle: [
            location.code ?? '',
            _branchName(_branches, location.branchId),
            location.city ?? '',
          ].where((item) => item.isNotEmpty).join(' • '),
          selected: selected,
          trailing: _StatusPill(
            label: location.isActive ? 'Active' : 'Inactive',
            active: location.isActive,
          ),
          onTap: () => _selectLocation(location),
        ),
      ),
      editor: _MasterEditorCard(
        title: _selectedLocation == null
            ? 'Create Business Location'
            : 'Edit Business Location',
        subtitle:
            'Store physical site details and enable only the modules this location should operate.',
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MasterFormWrap(
                children: [
                  _dropdownField<int>(
                    value: _companyId,
                    label: 'Company',
                    items: _companies
                        .map(
                          (company) => DropdownMenuItem<int>(
                            value: company.id,
                            child: Text(company.legalName ?? ''),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      setState(() {
                        _companyId = value;
                        final branches = _branchesForCompany(value);
                        _branchId = branches.isNotEmpty
                            ? branches.first.id
                            : null;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Company is required' : null,
                  ),
                  _dropdownField<int>(
                    value: _branchId,
                    label: 'Branch',
                    items: filteredBranches
                        .map(
                          (branch) => DropdownMenuItem<int>(
                            value: branch.id,
                            child: Text(branch.name ?? ''),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) => setState(() => _branchId = value),
                    validator: (value) =>
                        value == null ? 'Branch is required' : null,
                  ),
                  _textField(
                    controller: _codeController,
                    label: 'Code',
                    required: true,
                  ),
                  _textField(
                    controller: _nameController,
                    label: 'Name',
                    required: true,
                  ),
                  _dropdownField<String>(
                    value: _locationType,
                    label: 'Location Type',
                    items: const [
                      DropdownMenuItem(
                        value: 'billing',
                        child: Text('Billing'),
                      ),
                      DropdownMenuItem(value: 'office', child: Text('Office')),
                      DropdownMenuItem(
                        value: 'factory',
                        child: Text('Factory'),
                      ),
                      DropdownMenuItem(value: 'retail', child: Text('Retail')),
                      DropdownMenuItem(
                        value: 'service',
                        child: Text('Service'),
                      ),
                      DropdownMenuItem(
                        value: 'jobwork',
                        child: Text('Jobwork'),
                      ),
                      DropdownMenuItem(
                        value: 'warehouse',
                        child: Text('Warehouse Site'),
                      ),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (value) =>
                        setState(() => _locationType = value ?? _locationType),
                  ),
                  _textField(
                    controller: _contactController,
                    label: 'Contact Person',
                  ),
                  _textField(controller: _phoneController, label: 'Phone'),
                  _textField(controller: _emailController, label: 'Email'),
                  _textField(controller: _cityController, label: 'City'),
                  _textField(controller: _stateController, label: 'State'),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Address Line 1'),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _switchChip(
                    label: 'Sales',
                    value: _allowSales,
                    onChanged: (value) => setState(() => _allowSales = value),
                  ),
                  _switchChip(
                    label: 'Purchase',
                    value: _allowPurchase,
                    onChanged: (value) =>
                        setState(() => _allowPurchase = value),
                  ),
                  _switchChip(
                    label: 'Stock',
                    value: _allowStock,
                    onChanged: (value) => setState(() => _allowStock = value),
                  ),
                  _switchChip(
                    label: 'Accounts',
                    value: _allowAccounts,
                    onChanged: (value) =>
                        setState(() => _allowAccounts = value),
                  ),
                  _switchChip(
                    label: 'HR',
                    value: _allowHr,
                    onChanged: (value) => setState(() => _allowHr = value),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Default Location'),
                value: _isDefault,
                onChanged: (value) => setState(() => _isDefault = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
              TextFormField(
                controller: _remarksController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Remarks'),
              ),
              if ((_formError ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  _formError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: Icon(
                      _selectedLocation == null ? Icons.add : Icons.save,
                    ),
                    label: Text(_saving ? 'Saving...' : 'Save Location'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _resetForm,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WarehouseManagementPage extends StatefulWidget {
  const WarehouseManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<WarehouseManagementPage> createState() =>
      _WarehouseManagementPageState();
}

class _WarehouseManagementPageState extends State<WarehouseManagementPage> {
  final MasterService _masterService = MasterService();
  final ScrollController _pageScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  List<WarehouseModel> _warehouses = const <WarehouseModel>[];
  List<WarehouseModel> _filteredWarehouses = const <WarehouseModel>[];
  List<CompanyModel> _companies = const <CompanyModel>[];
  List<BranchModel> _branches = const <BranchModel>[];
  List<BusinessLocationModel> _locations = const <BusinessLocationModel>[];
  WarehouseModel? _selectedWarehouse;
  int? _companyId;
  int? _branchId;
  int? _locationId;
  int? _parentWarehouseId;
  String _warehouseType = 'main';
  bool _allowNegativeStock = false;
  bool _isSellableStock = true;
  bool _isReservedOnly = false;
  bool _isDefault = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applySearch);
    _loadData();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _searchController.dispose();
    _codeController.dispose();
    _nameController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadData({int? selectId}) async {
    setState(() {
      _initialLoading = _warehouses.isEmpty;
      _pageError = null;
    });

    try {
      final responses = await Future.wait([
        _masterService.warehouses(
          filters: const {'per_page': 100, 'sort_by': 'name'},
        ),
        _masterService.companies(filters: const {'per_page': 100}),
        _masterService.branches(filters: const {'per_page': 100}),
        _masterService.businessLocations(filters: const {'per_page': 100}),
      ]);

      final warehouses =
          responses[0].data as List<WarehouseModel>? ??
          const <WarehouseModel>[];
      final companies =
          responses[1].data as List<CompanyModel>? ?? const <CompanyModel>[];
      final branches =
          responses[2].data as List<BranchModel>? ?? const <BranchModel>[];
      final locations =
          responses[3].data as List<BusinessLocationModel>? ??
          const <BusinessLocationModel>[];
      if (!mounted) {
        return;
      }

      setState(() {
        _warehouses = warehouses;
        _companies = companies;
        _branches = branches;
        _locations = locations;
        _filteredWarehouses = _filterList(warehouses, _searchController.text, (
          warehouse,
        ) {
          return [warehouse.code ?? '', warehouse.name ?? ''];
        });
        _initialLoading = false;
      });

      final selected = selectId != null
          ? warehouses.cast<WarehouseModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (_selectedWarehouse == null
                ? (warehouses.isNotEmpty ? warehouses.first : null)
                : warehouses.cast<WarehouseModel?>().firstWhere(
                    (item) => item?.id == _selectedWarehouse?.id,
                    orElse: () =>
                        warehouses.isNotEmpty ? warehouses.first : null,
                  ));

      if (selected != null) {
        _selectWarehouse(selected);
      } else {
        _resetForm();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _initialLoading = false;
        _pageError = error.toString();
      });
    }
  }

  void _applySearch() {
    setState(() {
      _filteredWarehouses = _filterList(_warehouses, _searchController.text, (
        warehouse,
      ) {
        return [warehouse.code ?? '', warehouse.name ?? ''];
      });
    });
  }

  void _selectWarehouse(WarehouseModel warehouse) {
    _selectedWarehouse = warehouse;
    _companyId = warehouse.companyId;
    _branchId = warehouse.branchId;
    _locationId = warehouse.locationId;
    _parentWarehouseId = warehouse.parentWarehouseId;
    _codeController.text = warehouse.code ?? '';
    _nameController.text = warehouse.name ?? '';
    _warehouseType = warehouse.warehouseType ?? 'main';
    _allowNegativeStock = warehouse.allowNegativeStock;
    _isSellableStock = warehouse.isSellableStock;
    _isReservedOnly = warehouse.isReservedOnly;
    _isDefault = warehouse.isDefault;
    _isActive = warehouse.isActive;
    _remarksController.text = warehouse.remarks ?? '';
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedWarehouse = null;
    _companyId = _companies.isNotEmpty ? _companies.first.id : null;
    final branches = _branchesForCompany(_companyId);
    _branchId = branches.isNotEmpty ? branches.first.id : null;
    final locations = _locationsForBranch(_branchId);
    _locationId = locations.isNotEmpty ? locations.first.id : null;
    _parentWarehouseId = null;
    _codeController.clear();
    _nameController.clear();
    _warehouseType = 'main';
    _allowNegativeStock = false;
    _isSellableStock = true;
    _isReservedOnly = false;
    _isDefault = false;
    _isActive = true;
    _remarksController.clear();
    _formError = null;
    setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    final model = WarehouseModel(
      id: _selectedWarehouse?.id,
      companyId: _companyId,
      branchId: _branchId,
      locationId: _locationId,
      code: _codeController.text.trim(),
      name: _nameController.text.trim(),
      warehouseType: _warehouseType,
      parentWarehouseId: _parentWarehouseId,
      allowNegativeStock: _allowNegativeStock,
      isSellableStock: _isSellableStock,
      isReservedOnly: _isReservedOnly,
      isDefault: _isDefault,
      isActive: _isActive,
      remarks: _nullIfEmpty(_remarksController.text),
    );

    try {
      final response = _selectedWarehouse == null
          ? await _masterService.createWarehouse(model)
          : await _masterService.updateWarehouse(
              _selectedWarehouse!.id!,
              model,
            );
      final saved = response.data;
      if (!mounted) {
        return;
      }
      if (saved == null) {
        setState(() => _formError = response.message);
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadData(selectId: saved.id);
    } catch (error) {
      setState(() => _formError = error.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    final actions = [
      AdaptiveShellActionButton(
        onPressed: _resetForm,
        icon: Icons.add_home_work_outlined,
        label: 'New Warehouse',
      ),
    ];

    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }

    return _StandaloneMasterShell(
      title: 'Warehouses',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading warehouses...');
    }
    if (_pageError != null) {
      return Center(child: Text(_pageError!));
    }

    final branches = _branchesForCompany(_companyId);
    final locations = _locationsForBranch(_branchId);
    final parentOptions = _warehouses
        .where(
          (item) =>
              item.locationId == _locationId &&
              item.id != _selectedWarehouse?.id,
        )
        .toList(growable: false);

    return _MasterWorkspace(
      scrollController: _pageScrollController,
      list: _MasterListCard<WarehouseModel>(
        title: 'Warehouse Directory',
        subtitle: 'Stock storage units under each business location.',
        searchController: _searchController,
        searchHint: 'Search warehouses',
        items: _filteredWarehouses,
        selectedItem: _selectedWarehouse,
        emptyMessage: 'No warehouses found.',
        itemBuilder: (warehouse, selected) => _MasterListTile(
          title: warehouse.name ?? '',
          subtitle: [
            warehouse.code ?? '',
            _locationName(_locations, warehouse.locationId),
            warehouse.warehouseType?.replaceAll('_', ' ') ?? '',
          ].where((item) => item.isNotEmpty).join(' • '),
          selected: selected,
          trailing: _StatusPill(
            label: warehouse.isActive ? 'Active' : 'Inactive',
            active: warehouse.isActive,
          ),
          onTap: () => _selectWarehouse(warehouse),
        ),
      ),
      editor: _MasterEditorCard(
        title: _selectedWarehouse == null
            ? 'Create Warehouse'
            : 'Edit Warehouse',
        subtitle:
            'Define stock buckets per location, including defaults and parent-child storage structure.',
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MasterFormWrap(
                children: [
                  _dropdownField<int>(
                    value: _companyId,
                    label: 'Company',
                    items: _companies
                        .map(
                          (company) => DropdownMenuItem<int>(
                            value: company.id,
                            child: Text(company.legalName ?? ''),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      setState(() {
                        _companyId = value;
                        final branches = _branchesForCompany(value);
                        _branchId = branches.isNotEmpty
                            ? branches.first.id
                            : null;
                        final locations = _locationsForBranch(_branchId);
                        _locationId = locations.isNotEmpty
                            ? locations.first.id
                            : null;
                        _parentWarehouseId = null;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Company is required' : null,
                  ),
                  _dropdownField<int>(
                    value: _branchId,
                    label: 'Branch',
                    items: branches
                        .map(
                          (branch) => DropdownMenuItem<int>(
                            value: branch.id,
                            child: Text(branch.name ?? ''),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      setState(() {
                        _branchId = value;
                        final locations = _locationsForBranch(value);
                        _locationId = locations.isNotEmpty
                            ? locations.first.id
                            : null;
                        _parentWarehouseId = null;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Branch is required' : null,
                  ),
                  _dropdownField<int>(
                    value: _locationId,
                    label: 'Business Location',
                    items: locations
                        .map(
                          (location) => DropdownMenuItem<int>(
                            value: location.id,
                            child: Text(location.name ?? ''),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      setState(() {
                        _locationId = value;
                        _parentWarehouseId = null;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Location is required' : null,
                  ),
                  _textField(
                    controller: _codeController,
                    label: 'Code',
                    required: true,
                  ),
                  _textField(
                    controller: _nameController,
                    label: 'Name',
                    required: true,
                  ),
                  _dropdownField<String>(
                    value: _warehouseType,
                    label: 'Warehouse Type',
                    items: const [
                      DropdownMenuItem(value: 'main', child: Text('Main')),
                      DropdownMenuItem(
                        value: 'raw_material',
                        child: Text('Raw Material'),
                      ),
                      DropdownMenuItem(
                        value: 'finished_goods',
                        child: Text('Finished Goods'),
                      ),
                      DropdownMenuItem(value: 'wip', child: Text('WIP')),
                      DropdownMenuItem(value: 'damage', child: Text('Damage')),
                      DropdownMenuItem(
                        value: 'returns',
                        child: Text('Returns'),
                      ),
                      DropdownMenuItem(
                        value: 'transit',
                        child: Text('Transit'),
                      ),
                      DropdownMenuItem(
                        value: 'jobwork',
                        child: Text('Jobwork'),
                      ),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (value) => setState(
                      () => _warehouseType = value ?? _warehouseType,
                    ),
                  ),
                  _dropdownField<int?>(
                    value: _parentWarehouseId,
                    label: 'Parent Warehouse',
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('None'),
                      ),
                      ...parentOptions.map(
                        (warehouse) => DropdownMenuItem<int?>(
                          value: warehouse.id,
                          child: Text(warehouse.name ?? ''),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _parentWarehouseId = value),
                  ),
                ],
              ),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _switchChip(
                    label: 'Allow Negative',
                    value: _allowNegativeStock,
                    onChanged: (value) =>
                        setState(() => _allowNegativeStock = value),
                  ),
                  _switchChip(
                    label: 'Sellable',
                    value: _isSellableStock,
                    onChanged: (value) =>
                        setState(() => _isSellableStock = value),
                  ),
                  _switchChip(
                    label: 'Reserved Only',
                    value: _isReservedOnly,
                    onChanged: (value) =>
                        setState(() => _isReservedOnly = value),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Default Warehouse'),
                value: _isDefault,
                onChanged: (value) => setState(() => _isDefault = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
              TextFormField(
                controller: _remarksController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Remarks'),
              ),
              if ((_formError ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  _formError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: Icon(
                      _selectedWarehouse == null ? Icons.add : Icons.save,
                    ),
                    label: Text(_saving ? 'Saving...' : 'Save Warehouse'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _resetForm,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StandaloneMasterShell extends StatelessWidget {
  const _StandaloneMasterShell({
    required this.title,
    required this.scrollController,
    required this.actions,
    required this.child,
  });

  final String title;
  final ScrollController scrollController;
  final List<Widget> actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PublicBrandingModel?>(
      future: SessionStorage.getBranding(),
      builder: (context, snapshot) {
        final branding =
            snapshot.data ??
            const PublicBrandingModel(companyName: 'Billing ERP');

        return AdaptiveShell(
          title: title,
          branding: branding,
          scrollController: scrollController,
          actions: actions,
          onLogout: () async {
            await AppSessionService.instance.clearSession();
            if (context.mounted) {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/login', (_) => false);
            }
          },
          child: child,
        );
      },
    );
  }
}

/*
Widget _wrapStandalone({
  required String title,
  required ScrollController scrollController,
  required List<Widget> actions,
  required Widget child,
}) {}
*/

class _MasterWorkspace extends StatelessWidget {
  const _MasterWorkspace({
    required this.scrollController,
    required this.list,
    required this.editor,
  });

  final ScrollController scrollController;
  final Widget list;
  final Widget editor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1120;

        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(AppUiConstants.pagePadding),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 360, child: list),
                    const SizedBox(width: 24),
                    Expanded(child: editor),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [list, const SizedBox(height: 20), editor],
                ),
        );
      },
    );
  }
}

class _MasterListCard<T> extends StatelessWidget {
  const _MasterListCard({
    required this.title,
    required this.subtitle,
    required this.searchController,
    required this.searchHint,
    required this.items,
    required this.selectedItem,
    required this.emptyMessage,
    required this.itemBuilder,
  });

  final String title;
  final String subtitle;
  final TextEditingController searchController;
  final String searchHint;
  final List<T> items;
  final T? selectedItem;
  final String emptyMessage;
  final Widget Function(T item, bool selected) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return _MasterCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).extension<AppThemeExtension>()!.mutedText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: searchHint,
              prefixIcon: const Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(emptyMessage),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) => itemBuilder(
                items[index],
                identical(items[index], selectedItem),
              ),
            ),
        ],
      ),
    );
  }
}

class _MasterEditorCard extends StatelessWidget {
  const _MasterEditorCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _MasterCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).extension<AppThemeExtension>()!.mutedText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _MasterCard extends StatelessWidget {
  const _MasterCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: appTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
        boxShadow: [
          BoxShadow(
            color: appTheme.cardShadow,
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppUiConstants.cardPadding),
        child: child,
      ),
    );
  }
}

class _MasterListTile extends StatelessWidget {
  const _MasterListTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(AppUiConstants.buttonRadius),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary.withValues(alpha: 0.08) : null,
          borderRadius: BorderRadius.circular(AppUiConstants.buttonRadius),
          border: Border.all(
            color: selected
                ? colorScheme.primary.withValues(alpha: 0.28)
                : theme.dividerColor.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.extension<AppThemeExtension>()!.mutedText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = active
        ? colorScheme.primary.withValues(alpha: 0.12)
        : colorScheme.error.withValues(alpha: 0.10);
    final foreground = active ? colorScheme.primary : colorScheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MasterFormWrap extends StatelessWidget {
  const _MasterFormWrap({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 16, runSpacing: 16, children: children);
  }
}

Widget _switchChip({
  required String label,
  required bool value,
  required ValueChanged<bool> onChanged,
}) {
  return FilterChip(selected: value, onSelected: onChanged, label: Text(label));
}

Widget _textField({
  required TextEditingController controller,
  required String label,
  bool required = false,
}) {
  return SizedBox(
    width: 260,
    child: TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      validator: required
          ? (value) => (value == null || value.trim().isEmpty)
                ? '$label is required'
                : null
          : null,
    ),
  );
}

Widget _dropdownField<T>({
  required T? value,
  required String label,
  required List<DropdownMenuItem<T>> items,
  required ValueChanged<T?> onChanged,
  FormFieldValidator<T>? validator,
}) {
  return SizedBox(
    width: 260,
    child: DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: items,
      onChanged: onChanged,
      validator: validator,
    ),
  );
}

List<T> _filterList<T>(
  List<T> items,
  String query,
  List<String> Function(T item) textBuilder,
) {
  final trimmed = query.trim().toLowerCase();
  if (trimmed.isEmpty) {
    return items;
  }

  return items
      .where((item) {
        final haystack = textBuilder(item).join(' ').toLowerCase();
        return haystack.contains(trimmed);
      })
      .toList(growable: false);
}

String? _nullIfEmpty(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String _companyName(List<CompanyModel> companies, int? id) {
  return companies
          .cast<CompanyModel?>()
          .firstWhere((item) => item?.id == id, orElse: () => null)
          ?.legalName ??
      '';
}

String _branchName(List<BranchModel> branches, int? id) {
  return branches
          .cast<BranchModel?>()
          .firstWhere((item) => item?.id == id, orElse: () => null)
          ?.name ??
      '';
}

String _locationName(List<BusinessLocationModel> locations, int? id) {
  return locations
          .cast<BusinessLocationModel?>()
          .firstWhere((item) => item?.id == id, orElse: () => null)
          ?.name ??
      '';
}

extension on _BusinessLocationManagementPageState {
  List<BranchModel> _branchesForCompany(int? companyId) {
    if (companyId == null) {
      return const <BranchModel>[];
    }

    return _branches
        .where((branch) => branch.companyId == companyId)
        .toList(growable: false);
  }
}

extension on _WarehouseManagementPageState {
  List<BranchModel> _branchesForCompany(int? companyId) {
    if (companyId == null) {
      return const <BranchModel>[];
    }

    return _branches
        .where((branch) => branch.companyId == companyId)
        .toList(growable: false);
  }

  List<BusinessLocationModel> _locationsForBranch(int? branchId) {
    if (branchId == null) {
      return const <BusinessLocationModel>[];
    }

    return _locations
        .where((location) => location.branchId == branchId)
        .toList(growable: false);
  }
}
