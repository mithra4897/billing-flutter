import '../../screen.dart';
import '../purchase/purchase_support.dart';
import 'crm_sales_pipeline_bar.dart';

void _openCrmShellRoute(BuildContext context, String route) {
  final navigate = ShellRouteScope.maybeOf(context);
  if (navigate != null) {
    navigate(route);
    return;
  }
  Navigator.of(context).pushNamed(route);
}

class CrmEnquiriesPage extends StatefulWidget {
  const CrmEnquiriesPage({
    super.key,
    this.embedded = false,
    this.initialSelectId,
  });

  final bool embedded;

  /// Deep link from lead conversion: `/crm/enquiries?select_id=…`
  final int? initialSelectId;

  @override
  State<CrmEnquiriesPage> createState() => _CrmEnquiriesPageState();
}

class _CrmEnquiriesPageState extends State<CrmEnquiriesPage>
    with SingleTickerProviderStateMixin {
  static const List<AppDropdownItem<String>> _statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'open', label: 'Open'),
        AppDropdownItem(value: 'in_progress', label: 'In Progress'),
        AppDropdownItem(value: 'converted', label: 'Converted'),
        AppDropdownItem(value: 'lost', label: 'Lost'),
      ];
  static const List<AppDropdownItem<String>> _followupStatuses =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'pending', label: 'Pending'),
        AppDropdownItem(value: 'done', label: 'Done'),
        AppDropdownItem(value: 'skipped', label: 'Skipped'),
      ];

  final CrmService _crmService = CrmService();
  final MasterService _masterService = MasterService();
  final AuthService _authService = AuthService();
  final PartiesService _partiesService = PartiesService();
  final InventoryService _inventoryService = InventoryService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _enquiryNoController = TextEditingController();
  final TextEditingController _enquiryDateController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  late final TabController _tabController;
  int _activeTabIndex = 0;
  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  List<CrmEnquiryModel> _items = const <CrmEnquiryModel>[];
  List<CrmEnquiryModel> _filteredItems = const <CrmEnquiryModel>[];
  List<CompanyModel> _companies = const <CompanyModel>[];
  List<CrmLeadModel> _leads = const <CrmLeadModel>[];
  List<PartyModel> _customers = const <PartyModel>[];
  List<CrmStageModel> _stages = const <CrmStageModel>[];
  List<UserModel> _users = const <UserModel>[];
  List<ItemModel> _itemsLookup = const <ItemModel>[];
  CrmEnquiryModel? _selectedItem;
  int? _contextCompanyId;
  int? _companyId;
  int? _leadId;
  int? _customerPartyId;
  int? _stageId;
  int? _assignedTo;
  String _enquiryStatus = 'open';
  List<_EnquiryLineDraft> _lines = <_EnquiryLineDraft>[];
  List<_FollowupDraft> _followups = <_FollowupDraft>[];
  int? _expandedLineIndex;
  int? _expandedFollowupIndex;
  Map<String, dynamic>? _salesChain;

  String _normalizedStageType(CrmStageModel stage) {
    return stringValue(stage.toJson(), 'stage_type').trim().toLowerCase();
  }

  bool _isAllowedEnquiryStage(CrmStageModel stage) {
    final type = _normalizedStageType(stage);
    return type == 'enquiry' ||
        type == 'opportunity' ||
        type == 'closed_won' ||
        type == 'closed_lost' ||
        type == 'closed won' ||
        type == 'closed lost';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!mounted || _tabController.indexIsChanging) {
        return;
      }
      _activeTabIndex = _tabController.index;
      setState(() {});
    });
    _searchController.addListener(_applySearch);
    _loadPage(selectId: widget.initialSelectId);
  }

  @override
  void didUpdateWidget(covariant CrmEnquiriesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSelectId != null &&
        widget.initialSelectId != oldWidget.initialSelectId) {
      _loadPage(selectId: widget.initialSelectId);
    }
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _workspaceController.dispose();
    _searchController.dispose();
    _tabController.dispose();
    _enquiryNoController.dispose();
    _enquiryDateController.dispose();
    _remarksController.dispose();
    _disposeLines(_lines);
    _disposeFollowups(_followups);
    super.dispose();
  }

  Future<void> _loadPage({int? selectId}) async {
    setState(() {
      _initialLoading = _items.isEmpty;
      _pageError = null;
    });

    try {
      final responses = await Future.wait<dynamic>([
        _crmService.enquiries(
          filters: const {'per_page': 200, 'sort_by': 'enquiry_date'},
        ),
        _masterService.companies(
          filters: const {'per_page': 100, 'sort_by': 'legal_name'},
        ),
        _crmService.leads(
          filters: const {'per_page': 300, 'sort_by': 'lead_name'},
        ),
        _partiesService.parties(
          filters: const {'per_page': 300, 'sort_by': 'party_name'},
        ),
        _crmService.stages(
          filters: const {'per_page': 200, 'sort_by': 'sequence_no'},
        ),
        _authService.users(
          filters: const {'per_page': 200, 'sort_by': 'username'},
        ),
        _inventoryService.items(
          filters: const {'per_page': 300, 'sort_by': 'item_name'},
        ),
      ]);

      final companies =
          (responses[1] as PaginatedResponse<CompanyModel>).data ??
          const <CompanyModel>[];
      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: companies
                .where((item) => item.isActive)
                .toList(growable: false),
            branches: const <BranchModel>[],
            locations: const <BusinessLocationModel>[],
            financialYears: const <FinancialYearModel>[],
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _items =
            (responses[0] as PaginatedResponse<CrmEnquiryModel>).data ??
            const <CrmEnquiryModel>[];
        _companies = companies.where((item) => item.isActive).toList();
        _leads =
            (responses[2] as PaginatedResponse<CrmLeadModel>).data ??
            const <CrmLeadModel>[];
        _customers =
            ((responses[3] as PaginatedResponse<PartyModel>).data ??
                    const <PartyModel>[])
                .where((item) => item.isActive)
                .toList();
        _stages = () {
          final allStages =
              ((responses[4] as PaginatedResponse<CrmStageModel>).data ??
                      const <CrmStageModel>[])
                  .where(
                    (item) =>
                        boolValue(item.toJson(), 'is_active', fallback: true),
                  )
                  .toList(growable: false);
          final filtered = allStages
              .where(_isAllowedEnquiryStage)
              .toList(growable: false);
          return filtered.isNotEmpty ? filtered : allStages;
        }();
        _users =
            ((responses[5] as PaginatedResponse<UserModel>).data ??
                    const <UserModel>[])
                .where((item) => (item.status ?? 'active') == 'active')
                .toList();
        _itemsLookup =
            ((responses[6] as PaginatedResponse<ItemModel>).data ??
                    const <ItemModel>[])
                .where((item) => item.isActive)
                .toList();
        _contextCompanyId = contextSelection.companyId;
        _initialLoading = false;
      });
      _applySearch();

      final selected = selectId != null
          ? _items.cast<CrmEnquiryModel?>().firstWhere(
              (item) => intValue(item?.toJson() ?? const {}, 'id') == selectId,
              orElse: () => null,
            )
          : (_selectedItem == null
                ? (_items.isNotEmpty ? _items.first : null)
                : _items.cast<CrmEnquiryModel?>().firstWhere(
                    (item) =>
                        intValue(item?.toJson() ?? const {}, 'id') ==
                        intValue(_selectedItem!.toJson(), 'id'),
                    orElse: () => _items.isNotEmpty ? _items.first : null,
                  ));

      if (selected != null) {
        await _selectItem(selected);
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
      _filteredItems = filterMasterList(_items, _searchController.text, (item) {
        final data = item.toJson();
        return [
          stringValue(data, 'enquiry_no'),
          stringValue(data, 'enquiry_status'),
          stringValue(data, 'remarks'),
        ];
      });
    });
  }

  ErpLinkFieldOption<int>? _selectedLeadOption() {
    final selectedId = _leadId;
    if (selectedId == null) {
      return null;
    }
    final lead = _leads.cast<CrmLeadModel?>().firstWhere(
      (item) => intValue(item?.toJson() ?? const {}, 'id') == selectedId,
      orElse: () => null,
    );
    return lead == null ? null : _leadOption(lead);
  }

  ErpLinkFieldOption<int> _leadOption(CrmLeadModel lead) {
    final data = lead.toJson();
    final label = lead.toString();
    final companyName = stringValue(data, 'company_name');
    final mobile = stringValue(data, 'mobile');
    final email = stringValue(data, 'email');
    final subtitle = [
      companyName,
      mobile,
      email,
    ].where((value) => value.trim().isNotEmpty).join(' • ');

    return ErpLinkFieldOption<int>(
      value: intValue(data, 'id')!,
      label: label,
      subtitle: subtitle.isEmpty ? null : subtitle,
      searchText: [label, companyName, mobile, email].join(' '),
    );
  }

  Future<List<ErpLinkFieldOption<int>>> _searchLeadOptions(String query) async {
    final normalized = query.trim().toLowerCase();
    return _leads
        .where((lead) => intValue(lead.toJson(), 'id') != null)
        .where((lead) {
          if (normalized.isEmpty) {
            return true;
          }
          final data = lead.toJson();
          final haystack = [
            lead.toString(),
            stringValue(data, 'company_name'),
            stringValue(data, 'mobile'),
            stringValue(data, 'email'),
            stringValue(data, 'lead_status'),
          ].join(' ').toLowerCase();
          return haystack.contains(normalized);
        })
        .map(_leadOption)
        .toList(growable: false);
  }

  void _openNewLeadForm(String query) {
    final leadName = query.trim();
    final route = Uri(
      path: '/crm/leads',
      queryParameters: <String, String>{
        'new': '1',
        if (leadName.isNotEmpty) 'lead_name': leadName,
        if (_companyId != null) 'company_id': _companyId.toString(),
      },
    ).toString();
    _openCrmShellRoute(context, route);
  }

  Future<void> _selectItem(CrmEnquiryModel item) async {
    final id = intValue(item.toJson(), 'id');
    if (id == null) {
      return;
    }
    final response = await _crmService.enquiry(id);
    final full = response.data ?? item;
    final data = full.toJson();
    final lines = (data['lines'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(_EnquiryLineDraft.fromJson)
        .toList(growable: true);
    final followups = (data['followups'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(_FollowupDraft.fromJson)
        .toList(growable: true);

    _disposeLines(_lines);
    _disposeFollowups(_followups);
    setState(() {
      _selectedItem = full;
      _companyId = intValue(data, 'company_id');
      _leadId = intValue(data, 'lead_id');
      _customerPartyId = intValue(data, 'customer_party_id');
      _stageId = intValue(data, 'stage_id');
      _assignedTo = intValue(data, 'assigned_to');
      _enquiryStatus = stringValue(data, 'enquiry_status', 'open');
      _enquiryNoController.text = stringValue(data, 'enquiry_no');
      _enquiryDateController.text = displayDate(
        nullableStringValue(data, 'enquiry_date'),
      );
      _remarksController.text = stringValue(data, 'remarks');
      _lines = lines;
      _followups = followups;
      _expandedLineIndex = null;
      _expandedFollowupIndex = null;
      _formError = null;
    });
    await _refreshSalesChainForEnquiry(id);
  }

  int? _pipelineOpportunityId() {
    final raw = _salesChain?['opportunity'];
    if (raw is Map) {
      return intValue(Map<String, dynamic>.from(raw), 'id');
    }
    return null;
  }

  Future<void> _refreshSalesChainForEnquiry(int enquiryId) async {
    try {
      final response = await _crmService.salesChain(enquiryId: enquiryId);
      if (!mounted) {
        return;
      }
      setState(() => _salesChain = response.data);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _salesChain = null);
    }
  }

  void _resetForm() {
    _disposeLines(_lines);
    _disposeFollowups(_followups);
    setState(() {
      _selectedItem = null;
      _companyId = _contextCompanyId;
      _leadId = null;
      _customerPartyId = null;
      _stageId = null;
      _assignedTo = null;
      _enquiryStatus = 'open';
      _enquiryNoController.clear();
      _enquiryDateController.text = DateTime.now()
          .toIso8601String()
          .split('T')
          .first;
      _remarksController.clear();
      _lines = <_EnquiryLineDraft>[];
      _followups = <_FollowupDraft>[];
      _expandedLineIndex = null;
      _expandedFollowupIndex = null;
      _formError = null;
      _tabController.index = 0;
      _activeTabIndex = 0;
      _salesChain = null;
    });
  }

  void _disposeLines(List<_EnquiryLineDraft> lines) {
    for (final line in lines) {
      line.dispose();
    }
  }

  void _disposeFollowups(List<_FollowupDraft> followups) {
    for (final followup in followups) {
      followup.dispose();
    }
  }

  void _addLine() {
    setState(() {
      _lines = List<_EnquiryLineDraft>.from(_lines)..add(_EnquiryLineDraft());
      _expandedLineIndex = _lines.length - 1;
    });
  }

  void _removeLine(int index) {
    setState(() {
      final lines = List<_EnquiryLineDraft>.from(_lines);
      lines.removeAt(index).dispose();
      _lines = lines;
      if (_expandedLineIndex == index) {
        _expandedLineIndex = null;
      } else if ((_expandedLineIndex ?? -1) > index) {
        _expandedLineIndex = _expandedLineIndex! - 1;
      }
    });
  }

  void _addFollowup() {
    setState(() {
      _followups = List<_FollowupDraft>.from(_followups)..add(_FollowupDraft());
      _expandedFollowupIndex = _followups.length - 1;
    });
  }

  void _removeFollowup(int index) {
    setState(() {
      final followups = List<_FollowupDraft>.from(_followups);
      followups.removeAt(index).dispose();
      _followups = followups;
      if (_expandedFollowupIndex == index) {
        _expandedFollowupIndex = null;
      } else if ((_expandedFollowupIndex ?? -1) > index) {
        _expandedFollowupIndex = _expandedFollowupIndex! - 1;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    final payload = CrmEnquiryModel({
      'company_id': _companyId,
      'enquiry_no': nullIfEmpty(_enquiryNoController.text),
      'enquiry_date': nullIfEmpty(_enquiryDateController.text),
      'lead_id': _leadId,
      'customer_party_id': _customerPartyId,
      'stage_id': _stageId,
      'assigned_to': _assignedTo,
      'enquiry_status': _enquiryStatus,
      'remarks': nullIfEmpty(_remarksController.text),
      'lines': _lines.map((item) => item.toJson()).toList(growable: false),
      'followups': _followups
          .map((item) => item.toJson())
          .toList(growable: false),
    });

    try {
      final response = _selectedItem == null
          ? await _crmService.createEnquiry(payload)
          : await _crmService.updateEnquiry(
              intValue(_selectedItem!.toJson(), 'id')!,
              payload,
            );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadPage(
        selectId: intValue(response.data?.toJson() ?? const {}, 'id'),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _formError = error.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _delete() async {
    final id = intValue(_selectedItem?.toJson() ?? const {}, 'id');
    if (id == null) {
      return;
    }
    try {
      final response = await _crmService.deleteEnquiry(id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadPage();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _formError = error.toString());
    }
  }

  Future<void> _convert() async {
    final id = intValue(_selectedItem?.toJson() ?? const {}, 'id');
    if (id == null) {
      return;
    }
    try {
      final response = await _crmService.convertEnquiry(id);
      if (!mounted) {
        return;
      }
      final payload = response.data ?? const <String, dynamic>{};
      final oppRaw = payload['opportunity'];
      Map<String, dynamic>? oppMap;
      if (oppRaw is Map) {
        oppMap = Map<String, dynamic>.from(oppRaw);
      }
      final opportunityId = oppMap != null ? intValue(oppMap, 'id') : null;

      await _loadPage(selectId: id);

      if (!mounted) {
        return;
      }

      if (opportunityId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            action: SnackBarAction(
              label: 'Open deal',
              onPressed: () => _openCrmShellRoute(
                context,
                '/crm/opportunities?select_id=$opportunityId',
              ),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _formError = error.toString());
    }
  }

  Future<void> _lose() async {
    final id = intValue(_selectedItem?.toJson() ?? const {}, 'id');
    if (id == null) {
      return;
    }
    try {
      final response = await _crmService.loseEnquiry(
        id,
        CrmEnquiryModel(const <String, dynamic>{}),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadPage(selectId: id);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _formError = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      AdaptiveShellActionButton(
        onPressed: () {
          _resetForm();
          if (!Responsive.isDesktop(context)) {
            _workspaceController.openEditor();
          }
        },
        icon: Icons.add_outlined,
        label: 'New Enquiry',
      ),
    ];

    final content = _buildContent();
    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }
    return AppStandaloneShell(
      title: 'CRM Enquiries',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading CRM enquiries...');
    }
    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load CRM enquiries',
        message: _pageError!,
        onRetry: _loadPage,
      );
    }

    return SettingsWorkspace(
      title: 'CRM Enquiries',
      scrollController: _pageScrollController,
      controller: _workspaceController,
      editorTitle: _selectedItem?.toString() ?? 'New Enquiry',
      list: SettingsListCard<CrmEnquiryModel>(
        searchController: _searchController,
        searchHint: 'Search enquiries',
        items: _filteredItems,
        selectedItem: _selectedItem,
        emptyMessage: 'No CRM enquiries found.',
        itemBuilder: (item, selected) {
          final data = item.toJson();
          return SettingsListTile(
            title: item.toString(),
            subtitle: [
              displayDate(nullableStringValue(data, 'enquiry_date')),
              stringValue(data, 'enquiry_status'),
            ].where((value) => value.isNotEmpty).join(' • '),
            selected: selected,
            onTap: () => _selectItem(item),
            detail: stringValue(data, 'remarks'),
            trailing: SettingsStatusPill(
              label: stringValue(data, 'enquiry_status', 'open'),
              active: stringValue(data, 'enquiry_status', 'open') != 'lost',
            ),
          );
        },
      ),
      editor: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Primary'),
                  Tab(text: 'Lines'),
                  Tab(text: 'Followups'),
                ],
              ),
              const SizedBox(height: AppUiConstants.spacingMd),
              IndexedStack(
                index: _activeTabIndex,
                children: [
                  _buildPrimaryTab(),
                  _selectedItem?.toJson()['id'] == null
                      ? _buildDependentTabPlaceholder(
                          title: 'Lines',
                          message:
                              'Save this enquiry first to manage requested items and descriptions.',
                        )
                      : _buildLinesTab(),
                  _selectedItem?.toJson()['id'] == null
                      ? _buildDependentTabPlaceholder(
                          title: 'Followups',
                          message:
                              'Save this enquiry first to manage follow-up dates, notes, and next actions.',
                        )
                      : _buildFollowupsTab(),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPrimaryTab() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_formError != null) ...[
            AppErrorStateView.inline(message: _formError!),
            const SizedBox(height: AppUiConstants.spacingSm),
          ],
          if (intValue(_selectedItem?.toJson() ?? const {}, 'id') != null) ...[
            CrmSalesPipelineBar(data: _salesChain),
            if (_pipelineOpportunityId() != null) ...[
              AppActionButton(
                icon: Icons.request_quote_outlined,
                label: 'New quotation (this deal)',
                filled: false,
                onPressed: () => openModuleShellRoute(
                  context,
                  '/sales/quotations/new?crm_opportunity_id=${_pipelineOpportunityId()}',
                ),
              ),
              const SizedBox(height: AppUiConstants.spacingSm),
            ],
          ],
          SettingsFormWrap(
            children: [
              AppDropdownField<int>.fromMapped(
                labelText: 'Company',
                mappedItems: _companies
                    .where((item) => item.id != null)
                    .map(
                      (item) => AppDropdownItem(
                        value: item.id!,
                        label: item.toString(),
                      ),
                    )
                    .toList(growable: false),
                initialValue: _companyId,
                onChanged: (value) => setState(() => _companyId = value),
                validator: Validators.requiredSelection('Company'),
              ),
              AppFormTextField(
                controller: _enquiryNoController,
                labelText: 'Enquiry No',
                hintText: 'Leave blank — we assign a number for you',
              ),
              AppFormTextField(
                controller: _enquiryDateController,
                labelText: 'Enquiry Date',
                keyboardType: TextInputType.datetime,
                inputFormatters: const [DateInputFormatter()],
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: ErpLinkField<int>(
                  labelText: 'Lead',
                  doctypeLabel: 'Lead',
                  allowCreate: true,
                  hintText: 'Search or create lead',
                  initialSelection: _selectedLeadOption(),
                  search: _searchLeadOptions,
                  onNavigateToCreateNew: _openNewLeadForm,
                  onChanged: (value) {
                    setState(() {
                      _leadId = value;
                      _formError = null;
                    });
                  },
                ),
              ),
              AppDropdownField<int>.fromMapped(
                labelText: 'Customer',
                doctypeLabel: 'Customer',
                allowCreate: true,
                onNavigateToCreateNew: (name) {
                    final uri = Uri(
                      path: '/parties',
                      queryParameters: {
                        'new': '1',
                        if (name.trim().isNotEmpty) 'party_name': name.trim(),
                      },
                    );
                    openModuleShellRoute(context, uri.toString());
                  },
                mappedItems: _customers
                    .where((item) => item.id != null)
                    .map(
                      (item) => AppDropdownItem(
                        value: item.id!,
                        label: item.toString(),
                      ),
                    )
                    .toList(growable: false),
                initialValue: _customerPartyId,
                onChanged: (value) => setState(() => _customerPartyId = value),
              ),
              AppDropdownField<int>.fromMapped(
                labelText: 'Stage',
                mappedItems: _stages
                    .where((item) => intValue(item.toJson(), 'id') != null)
                    .map(
                      (item) => AppDropdownItem(
                        value: intValue(item.toJson(), 'id')!,
                        label: item.toString(),
                      ),
                    )
                    .toList(growable: false),
                initialValue: _stageId,
                onChanged: (value) => setState(() => _stageId = value),
              ),
              AppDropdownField<int>.fromMapped(
                labelText: 'Assigned To',
                mappedItems: _users
                    .where((item) => item.id != null)
                    .map(
                      (item) => AppDropdownItem(
                        value: item.id!,
                        label: item.displayName ?? item.username ?? '',
                      ),
                    )
                    .toList(growable: false),
                initialValue: _assignedTo,
                onChanged: (value) => setState(() => _assignedTo = value),
              ),
              AppDropdownField<String>.fromMapped(
                labelText: 'Status',
                mappedItems: _statusItems,
                initialValue: _enquiryStatus,
                onChanged: (value) =>
                    setState(() => _enquiryStatus = value ?? _enquiryStatus),
              ),
              AppFormTextField(
                controller: _remarksController,
                labelText: 'Remarks',
                maxLines: 3,
              ),
            ],
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          Wrap(
            spacing: AppUiConstants.spacingSm,
            runSpacing: AppUiConstants.spacingSm,
            children: [
              AppActionButton(
                icon: Icons.save_outlined,
                label: _selectedItem == null
                    ? 'Save Enquiry'
                    : 'Update Enquiry',
                onPressed: _save,
                busy: _saving,
              ),
              if (_selectedItem != null) ...[
                AppActionButton(
                  icon: Icons.auto_graph_outlined,
                  label: 'Start deal',
                  filled: false,
                  onPressed:
                      (_pipelineOpportunityId() != null ||
                          _enquiryStatus == 'converted')
                      ? null
                      : _convert,
                ),
                AppActionButton(
                  icon: Icons.cancel_outlined,
                  label: 'Lose',
                  filled: false,
                  onPressed: _lose,
                ),
                AppActionButton(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  filled: false,
                  onPressed: _delete,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLinesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Requested Items',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            AppActionButton(
              icon: Icons.add_outlined,
              label: 'Add Line',
              filled: false,
              onPressed: _addLine,
            ),
          ],
        ),
        const SizedBox(height: AppUiConstants.spacingSm),
        if (_lines.isEmpty)
          const SettingsEmptyState(
            icon: Icons.playlist_add_check_outlined,
            title: 'No Lines',
            message: 'Add requested items, descriptions, and quantities.',
            minHeight: 180,
          )
        else
          ...List<Widget>.generate(_lines.length, (index) {
            final line = _lines[index];
            final expanded = _expandedLineIndex == index;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
              child: SettingsExpandableTile(
                title: line.itemLabel(_itemsLookup),
                subtitle: line.qtySummary,
                detail: line.descriptionController.text.trim(),
                expanded: expanded,
                highlighted: expanded,
                leadingIcon: Icons.inventory_2_outlined,
                trailing: IconButton(
                  onPressed: () => _removeLine(index),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline),
                ),
                onToggle: () {
                  setState(() {
                    _expandedLineIndex = expanded ? null : index;
                  });
                },
                child: PurchaseCompactFieldGrid(
                  children: [
                    AppSearchPickerField<int>(
                      labelText: 'Item',
                      selectedLabel: _itemsLookup
                          .cast<ItemModel?>()
                          .firstWhere(
                            (item) => item?.id == line.itemId,
                            orElse: () => null,
                          )
                          ?.toString(),
                      options: _itemsLookup
                          .where((item) => item.id != null)
                          .map(
                            (item) => AppSearchPickerOption<int>(
                              value: item.id!,
                              label: item.toString(),
                              subtitle: item.itemCode,
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) => setState(() => line.itemId = value),
                    ),
                    AppFormTextField(
                      controller: line.descriptionController,
                      labelText: 'Description',
                    ),
                    AppFormTextField(
                      controller: line.qtyController,
                      labelText: 'Quantity',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: AppUiConstants.spacingMd),
        Wrap(
          spacing: AppUiConstants.spacingSm,
          runSpacing: AppUiConstants.spacingSm,
          children: [
            AppActionButton(
              icon: Icons.save_outlined,
              label: _selectedItem == null ? 'Save Enquiry' : 'Update Enquiry',
              onPressed: _save,
              busy: _saving,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFollowupsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Followups',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            AppActionButton(
              icon: Icons.add_outlined,
              label: 'Add Followup',
              filled: false,
              onPressed: _addFollowup,
            ),
          ],
        ),
        const SizedBox(height: AppUiConstants.spacingSm),
        if (_followups.isEmpty)
          const SettingsEmptyState(
            icon: Icons.alarm_outlined,
            title: 'No Followups',
            message: 'Add next actions, notes, assignee, and status.',
            minHeight: 180,
          )
        else
          ...List<Widget>.generate(_followups.length, (index) {
            final followup = _followups[index];
            final expanded = _expandedFollowupIndex == index;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
              child: SettingsExpandableTile(
                title: followup.statusLabel,
                subtitle: [
                  followup.followupDateController.text.trim(),
                  followup.assigneeLabel(_users),
                ].where((value) => value.isNotEmpty).join(' • '),
                detail: followup.notesController.text.trim(),
                expanded: expanded,
                highlighted: expanded,
                leadingIcon: Icons.alarm_outlined,
                trailing: IconButton(
                  onPressed: () => _removeFollowup(index),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline),
                ),
                onToggle: () {
                  setState(() {
                    _expandedFollowupIndex = expanded ? null : index;
                  });
                },
                child: PurchaseCompactFieldGrid(
                  children: [
                    AppFormTextField(
                      controller: followup.followupDateController,
                      labelText: 'Followup Date',
                      hintText: 'YYYY-MM-DD HH:MM:SS',
                      keyboardType: TextInputType.datetime,
                      inputFormatters: const [DateTimeInputFormatter()],
                    ),
                    AppFormTextField(
                      controller: followup.nextFollowupController,
                      labelText: 'Next Followup',
                      hintText: 'YYYY-MM-DD HH:MM:SS',
                      keyboardType: TextInputType.datetime,
                      inputFormatters: const [DateTimeInputFormatter()],
                    ),
                    AppDropdownField<int>.fromMapped(
                      labelText: 'Assigned To',
                      mappedItems: _users
                          .where((item) => item.id != null)
                          .map(
                            (item) => AppDropdownItem(
                              value: item.id!,
                              label: item.displayName ?? item.username ?? '',
                            ),
                          )
                          .toList(growable: false),
                      initialValue: followup.assignedTo,
                      onChanged: (value) =>
                          setState(() => followup.assignedTo = value),
                    ),
                    AppDropdownField<String>.fromMapped(
                      labelText: 'Status',
                      mappedItems: _followupStatuses,
                      initialValue: followup.status,
                      onChanged: (value) =>
                          setState(() => followup.status = value ?? 'pending'),
                    ),
                    AppFormTextField(
                      controller: followup.notesController,
                      labelText: 'Notes',
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: AppUiConstants.spacingMd),
        Wrap(
          spacing: AppUiConstants.spacingSm,
          runSpacing: AppUiConstants.spacingSm,
          children: [
            AppActionButton(
              icon: Icons.save_outlined,
              label: _selectedItem == null ? 'Save Enquiry' : 'Update Enquiry',
              onPressed: _save,
              busy: _saving,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDependentTabPlaceholder({
    required String title,
    required String message,
  }) {
    return SettingsEmptyState(
      icon: Icons.link_outlined,
      title: title,
      message: message,
      minHeight: 240,
    );
  }
}

class _EnquiryLineDraft {
  _EnquiryLineDraft({this.itemId, String? description, String? qty})
    : descriptionController = TextEditingController(text: description ?? ''),
      qtyController = TextEditingController(text: qty ?? '');

  factory _EnquiryLineDraft.fromJson(Map<String, dynamic> json) {
    return _EnquiryLineDraft(
      itemId: intValue(json, 'item_id'),
      description: stringValue(json, 'description'),
      qty: stringValue(json, 'qty'),
    );
  }

  int? itemId;
  final TextEditingController descriptionController;
  final TextEditingController qtyController;

  String itemLabel(List<ItemModel> items) {
    final item = items.cast<ItemModel?>().firstWhere(
      (entry) => entry?.id == itemId,
      orElse: () => null,
    );
    final itemLabel = item?.toString();
    if ((itemLabel ?? '').trim().isNotEmpty) {
      return itemLabel!.trim();
    }
    final description = descriptionController.text.trim();
    return description.isNotEmpty ? description : 'Enquiry Line';
  }

  String get qtySummary {
    final qty = qtyController.text.trim();
    return qty.isNotEmpty ? 'Qty $qty' : '';
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'description': nullIfEmpty(descriptionController.text),
      'qty': double.tryParse(qtyController.text.trim()) ?? 0,
    };
  }

  void dispose() {
    descriptionController.dispose();
    qtyController.dispose();
  }
}

class _FollowupDraft {
  _FollowupDraft({
    this.assignedTo,
    this.status = 'pending',
    String? followupDate,
    String? notes,
    String? nextFollowup,
  }) : followupDateController = TextEditingController(
         text: displayDateTime(followupDate) == ''
             ? currentDateTimeInput()
             : displayDateTime(followupDate),
       ),
       notesController = TextEditingController(text: notes ?? ''),
       nextFollowupController = TextEditingController(
         text: displayDateTime(nextFollowup),
       );

  factory _FollowupDraft.fromJson(Map<String, dynamic> json) {
    return _FollowupDraft(
      assignedTo: intValue(json, 'assigned_to'),
      status: stringValue(json, 'status', 'pending'),
      followupDate: stringValue(json, 'followup_date'),
      notes: stringValue(json, 'notes'),
      nextFollowup: stringValue(json, 'next_followup'),
    );
  }

  int? assignedTo;
  String status;
  final TextEditingController followupDateController;
  final TextEditingController notesController;
  final TextEditingController nextFollowupController;

  String get statusLabel {
    switch (status) {
      case 'done':
        return 'Done';
      case 'skipped':
        return 'Skipped';
      default:
        return 'Pending';
    }
  }

  String assigneeLabel(List<UserModel> users) {
    final user = users.cast<UserModel?>().firstWhere(
      (entry) => entry?.id == assignedTo,
      orElse: () => null,
    );
    return user?.displayName ?? user?.username ?? '';
  }

  Map<String, dynamic> toJson() {
    return {
      'followup_date': nullIfEmpty(followupDateController.text),
      'notes': nullIfEmpty(notesController.text),
      'next_followup': nullIfEmpty(nextFollowupController.text),
      'assigned_to': assignedTo,
      'status': status,
    };
  }

  void dispose() {
    followupDateController.dispose();
    notesController.dispose();
    nextFollowupController.dispose();
  }
}
