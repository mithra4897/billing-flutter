import '../../controller/parties/party_management_controller.dart';
import '../../screen.dart';

class PartyManagementPage extends StatefulWidget {
  const PartyManagementPage({
    super.key,
    this.embedded = false,
    this.initialTabIndex = 0,
    this.startInNewMode = false,
    this.initialPartyId,
    this.initialPartyName,
  });

  final bool embedded;
  final int initialTabIndex;
  final bool startInNewMode;
  final int? initialPartyId;
  final String? initialPartyName;

  @override
  State<PartyManagementPage> createState() => _PartyManagementPageState();
}

class _PartyManagementPageState extends State<PartyManagementPage>
    with SingleTickerProviderStateMixin {
  static const List<AppDropdownItem<int>> _partyTypeFilterItemsBase =
      <AppDropdownItem<int>>[AppDropdownItem(value: 0, label: 'All')];
  static const List<AppDropdownItem<String>> _sortItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'name_asc', label: 'Name A-Z'),
        AppDropdownItem(value: 'name_desc', label: 'Name Z-A'),
        AppDropdownItem(value: 'code_asc', label: 'Code A-Z'),
        AppDropdownItem(value: 'code_desc', label: 'Code Z-A'),
      ];
  static const List<AppDropdownItem<String>> _openingBalanceTypeItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'debit', label: 'Debit'),
        AppDropdownItem(value: 'credit', label: 'Credit'),
      ];

  static const List<AppDropdownItem<String>> _addressTypeItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'billing', label: 'Billing'),
        AppDropdownItem(value: 'shipping', label: 'Shipping'),
        AppDropdownItem(value: 'office', label: 'Office'),
        AppDropdownItem(value: 'factory', label: 'Factory'),
        AppDropdownItem(value: 'other', label: 'Other'),
      ];

  static const List<AppDropdownItem<String>> _registrationTypeItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'regular', label: 'Regular'),
        AppDropdownItem(value: 'composition', label: 'Composition'),
        AppDropdownItem(value: 'unregistered', label: 'Unregistered'),
        AppDropdownItem(value: 'consumer', label: 'Consumer'),
        AppDropdownItem(value: 'overseas', label: 'Overseas'),
        AppDropdownItem(value: 'sez', label: 'SEZ'),
        AppDropdownItem(value: 'deemed_export', label: 'Deemed Export'),
      ];

  static const List<AppDropdownItem<String>> _dueBasisItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'invoice_date', label: 'Invoice Date'),
        AppDropdownItem(value: 'bill_date', label: 'Bill Date'),
        AppDropdownItem(value: 'dispatch_date', label: 'Dispatch Date'),
        AppDropdownItem(value: 'end_of_month', label: 'End Of Month'),
        AppDropdownItem(value: 'fixed_days', label: 'Fixed Days'),
      ];
  final PartiesService _partiesService = PartiesService();
  final MasterService _masterService = MasterService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  late final TabController _tabController;
  late final String _controllerTag;

  final GlobalKey<FormState> _partyFormKey = GlobalKey<FormState>();
  final TextEditingController _partyCodeController = TextEditingController();
  final TextEditingController _partyNameController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _aadhaarController = TextEditingController();
  final TextEditingController _currencyController = TextEditingController();
  final TextEditingController _openingBalanceController =
      TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  final GlobalKey<FormState> _addressFormKey = GlobalKey<FormState>();
  final TextEditingController _addressLine1Controller = TextEditingController();
  final TextEditingController _addressLine2Controller = TextEditingController();
  final TextEditingController _addressAreaController = TextEditingController();
  final TextEditingController _addressCityController = TextEditingController();
  final TextEditingController _addressDistrictController =
      TextEditingController();
  final TextEditingController _addressStateCodeController =
      TextEditingController();
  final TextEditingController _addressStateNameController =
      TextEditingController();
  final TextEditingController _addressCountryCodeController =
      TextEditingController();
  final TextEditingController _addressPostalCodeController =
      TextEditingController();

  final GlobalKey<FormState> _contactFormKey = GlobalKey<FormState>();
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _contactDesignationController =
      TextEditingController();
  final TextEditingController _contactMobileController =
      TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();

  final GlobalKey<FormState> _gstFormKey = GlobalKey<FormState>();
  final TextEditingController _gstinDetailController = TextEditingController();
  final TextEditingController _gstLegalNameController = TextEditingController();
  final TextEditingController _gstTradeNameController = TextEditingController();
  final TextEditingController _gstStateCodeController = TextEditingController();
  final TextEditingController _gstStateNameController = TextEditingController();
  final TextEditingController _gstAddress1Controller = TextEditingController();
  final TextEditingController _gstAddress2Controller = TextEditingController();
  final TextEditingController _gstCityController = TextEditingController();
  final TextEditingController _gstDistrictController = TextEditingController();
  final TextEditingController _gstPostalCodeController =
      TextEditingController();

  final GlobalKey<FormState> _bankFormKey = GlobalKey<FormState>();
  final TextEditingController _bankAccountHolderController =
      TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _bankBranchController = TextEditingController();
  final TextEditingController _bankAccountNumberController =
      TextEditingController();
  final TextEditingController _bankIfscController = TextEditingController();
  final TextEditingController _bankSwiftController = TextEditingController();
  final TextEditingController _bankIbanController = TextEditingController();
  final TextEditingController _bankUpiController = TextEditingController();

  final GlobalKey<FormState> _creditFormKey = GlobalKey<FormState>();
  final TextEditingController _creditLimitController = TextEditingController();
  final TextEditingController _creditDaysController = TextEditingController();
  final TextEditingController _creditFromController = TextEditingController();
  final TextEditingController _creditToController = TextEditingController();

  final GlobalKey<FormState> _paymentTermFormKey = GlobalKey<FormState>();
  final TextEditingController _paymentTermNameController =
      TextEditingController();
  final TextEditingController _paymentDaysController = TextEditingController();
  final TextEditingController _paymentRemarksController =
      TextEditingController();

  bool _partyCodeManuallyEdited = false;
  bool _suppressPartyCodeListener = false;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag('PartyManagementController');
    Get.put(PartyManagementController(), tag: _controllerTag);
    _tabController =
        TabController(
          length: 8,
          vsync: this,
          initialIndex: widget.initialTabIndex.clamp(0, 7),
        )..addListener(() {
          if (!_tabController.indexIsChanging) {
            _controller.setActiveTabIndex(_tabController.index);
          }
        });
    _controller.setActiveTabIndex(_tabController.index);
    _partyCodeController.addListener(_handlePartyCodeChanged);
    _searchController.addListener(() {
      _controller.setSearchQuery(_searchController.text);
    });
    _loadPartyAccountsAccess();
    _loadPage(selectId: widget.initialPartyId);
  }

  PartyManagementController get _controller =>
      Get.find<PartyManagementController>(tag: _controllerTag);

  bool get _isCompany => _controller.isCompany;
  String get _openingBalanceType => _controller.openingBalanceType;
  bool get _partyActive => _controller.partyActive;
  String get _addressType => _controller.addressType;
  bool get _addressDefault => _controller.addressDefault;
  bool get _addressActive => _controller.addressActive;
  bool get _contactPrimary => _controller.contactPrimary;
  bool get _contactActive => _controller.contactActive;
  String get _registrationType => _controller.registrationType;
  bool get _gstDefault => _controller.gstDefault;
  bool get _gstActive => _controller.gstActive;
  bool get _bankDefault => _controller.bankDefault;
  bool get _bankActive => _controller.bankActive;
  bool get _creditActive => _controller.creditActive;
  String get _dueBasis => _controller.dueBasis;
  bool get _paymentDefault => _controller.paymentDefault;
  bool get _paymentActive => _controller.paymentActive;
  bool get _initialLoading => _controller.initialLoading;
  bool get _partySaving => _controller.partySaving;
  bool get _detailSaving => _controller.detailSaving;
  String? get _pageError => _controller.pageError;
  String? get _partyFormError => _controller.partyFormError;
  String? get _detailFormError => _controller.detailFormError;
  List<PartyTypeModel> get _partyTypes => _controller.partyTypes;
  List<DocumentSeriesModel> get _documentSeries => _controller.documentSeries;
  List<PartyModel> get _parties => _controller.parties;
  PartyModel? get _selectedParty => _controller.selectedParty;
  int? get _partyTypeId => _controller.partyTypeId;
  List<PartyAddressModel> get _addresses => _controller.addresses;
  PartyAddressModel? get _selectedAddress => _controller.selectedAddress;
  List<PartyContactModel> get _contacts => _controller.contacts;
  PartyContactModel? get _selectedContact => _controller.selectedContact;
  List<PartyGstDetailModel> get _gstDetails => _controller.gstDetails;
  PartyGstDetailModel? get _selectedGstDetail => _controller.selectedGstDetail;
  List<PartyBankAccountModel> get _bankAccounts => _controller.bankAccounts;
  PartyBankAccountModel? get _selectedBankAccount =>
      _controller.selectedBankAccount;
  List<PartyCreditLimitModel> get _creditLimits => _controller.creditLimits;
  PartyCreditLimitModel? get _selectedCreditLimit =>
      _controller.selectedCreditLimit;
  List<PartyPaymentTermModel> get _paymentTerms => _controller.paymentTerms;
  PartyPaymentTermModel? get _selectedPaymentTerm =>
      _controller.selectedPaymentTerm;

  @override
  void dispose() {
    _pageScrollController.dispose();
    _workspaceController.dispose();
    _searchController.dispose();
    _tabController.dispose();
    _partyCodeController.dispose();
    _partyNameController.dispose();
    _displayNameController.dispose();
    _websiteController.dispose();
    _panController.dispose();
    _aadhaarController.dispose();
    _currencyController.dispose();
    _openingBalanceController.dispose();
    _remarksController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _addressAreaController.dispose();
    _addressCityController.dispose();
    _addressDistrictController.dispose();
    _addressStateCodeController.dispose();
    _addressStateNameController.dispose();
    _addressCountryCodeController.dispose();
    _addressPostalCodeController.dispose();
    _contactNameController.dispose();
    _contactDesignationController.dispose();
    _contactMobileController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    _gstinDetailController.dispose();
    _gstLegalNameController.dispose();
    _gstTradeNameController.dispose();
    _gstStateCodeController.dispose();
    _gstStateNameController.dispose();
    _gstAddress1Controller.dispose();
    _gstAddress2Controller.dispose();
    _gstCityController.dispose();
    _gstDistrictController.dispose();
    _gstPostalCodeController.dispose();
    _bankAccountHolderController.dispose();
    _bankNameController.dispose();
    _bankBranchController.dispose();
    _bankAccountNumberController.dispose();
    _bankIfscController.dispose();
    _bankSwiftController.dispose();
    _bankIbanController.dispose();
    _bankUpiController.dispose();
    _creditLimitController.dispose();
    _creditDaysController.dispose();
    _creditFromController.dispose();
    _creditToController.dispose();
    _paymentTermNameController.dispose();
    _paymentDaysController.dispose();
    _paymentRemarksController.dispose();
    super.dispose();
  }

  Future<void> _loadPartyAccountsAccess() async {
    final permissionCodes = await SessionStorage.getPermissionCodes();
    final canViewPartyAccounts = permissionCodes.contains('accounts.view');

    if (!mounted) {
      return;
    }

    _controller.setPartyAccountsAccess(canViewPartyAccounts);
    _controller.setPartyAccountsAccessResolved(true);
  }

  void _handlePartyCodeChanged() {
    if (_suppressPartyCodeListener) {
      return;
    }

    _partyCodeManuallyEdited = true;
  }

  Future<void> _loadPage({int? selectId}) async {
    _controller.beginPageLoad(showFullLoading: _parties.isEmpty);

    try {
      final partyTypesResponse = await _partiesService.partyTypes(
        filters: const {'per_page': 100, 'sort_by': 'name'},
      );
      final documentSeriesResponse = await _masterService.documentSeries(
        filters: const {
          'per_page': 100,
          'document_type': 'PARTY',
          'is_active': 1,
        },
      );
      final partiesResponse = await _partiesService.parties(
        filters: const {'per_page': 100, 'sort_by': 'party_name'},
      );

      if (!mounted) {
        return;
      }

      final partyTypes = partyTypesResponse.data ?? const <PartyTypeModel>[];
      final documentSeries =
          documentSeriesResponse.data ?? const <DocumentSeriesModel>[];
      final parties = partiesResponse.data ?? const <PartyModel>[];

      _controller.completePageLoad(
        partyTypes: partyTypes,
        documentSeries: documentSeries,
        parties: parties,
      );

      final selected = selectId != null
          ? parties.cast<PartyModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (widget.startInNewMode && _selectedParty == null
                ? null
                : (_selectedParty == null
                      ? (parties.isNotEmpty ? parties.first : null)
                      : parties.cast<PartyModel?>().firstWhere(
                          (item) => item?.id == _selectedParty?.id,
                          orElse: () =>
                              parties.isNotEmpty ? parties.first : null,
                        )));

      if (selected != null) {
        await _selectParty(selected);
      } else {
        _resetPartyForm();
        _clearDetailTabs();
        // Pre-fill party name if navigated from a "create new" dropdown action
        if (widget.initialPartyName != null &&
            _partyNameController.text.isEmpty) {
          _partyNameController.text = widget.initialPartyName!;
          _displayNameController.text = widget.initialPartyName!;
        }
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      _controller.failPageLoad(error.toString());
    }
  }

  List<PartyModel> _computeFilteredParties(List<PartyModel> source) {
    final filteredByType = _controller.partyTypeFilterId == 0
        ? source
        : source
              .where(
                (party) => party.partyTypeId == _controller.partyTypeFilterId,
              )
              .toList(growable: false);

    final searched = filterMasterList(filteredByType, _controller.searchQuery, (
      party,
    ) {
      return [
        party.partyCode ?? '',
        party.partyName ?? '',
        party.displayName ?? '',
        party.partyType ?? '',
        party.website ?? '',
      ];
    });

    final sorted = searched.toList(growable: false);
    sorted.sort((left, right) {
      final leftName = (left.partyName ?? '').toLowerCase();
      final rightName = (right.partyName ?? '').toLowerCase();
      final leftCode = (left.partyCode ?? '').toLowerCase();
      final rightCode = (right.partyCode ?? '').toLowerCase();

      switch (_controller.partySort) {
        case 'name_desc':
          return rightName.compareTo(leftName);
        case 'code_asc':
          return leftCode.compareTo(rightCode);
        case 'code_desc':
          return rightCode.compareTo(leftCode);
        case 'name_asc':
        default:
          return leftName.compareTo(rightName);
      }
    });

    return sorted;
  }

  List<AppDropdownItem<int>> _partyTypeFilterItems() {
    return [
      ..._partyTypeFilterItemsBase,
      ..._partyTypes.map(
        (type) => AppDropdownItem<int>(
          value: intValue(type.toJson(), 'id') ?? 0,
          label: stringValue(type.toJson(), 'name'),
        ),
      ),
    ];
  }

  PartyTypeModel? _partyTypeById(int? id) {
    if (id == null) {
      return null;
    }

    return _partyTypes.cast<PartyTypeModel?>().firstWhere(
      (item) => intValue(item?.toJson() ?? const {}, 'id') == id,
      orElse: () => null,
    );
  }

  bool _isNonBusinessPartyType(int? id) {
    final type = _partyTypeById(id);
    final code = stringValue(type?.toJson() ?? const {}, 'code').toUpperCase();

    return const {'BANK', 'CASH', 'EMPLOYEE', 'GENERAL'}.contains(code);
  }

  bool _supportsGst(int? id) => !_isNonBusinessPartyType(id);

  bool _supportsCompanyFlag(int? id) => !_isNonBusinessPartyType(id);

  String _partyTypeCode(int? id) {
    if (id == null) {
      return 'PTY';
    }

    final matched = _partyTypeById(id);

    final source =
        stringValue(matched?.toJson() ?? const {}, 'code').trim().isNotEmpty
        ? stringValue(matched?.toJson() ?? const {}, 'code')
        : stringValue(matched?.toJson() ?? const {}, 'name', 'PTY');
    final normalized = source.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    final prefix = normalized.isEmpty ? 'PTY' : normalized.toUpperCase();

    return prefix.length <= 3 ? prefix : prefix.substring(0, 3);
  }

  DocumentSeriesModel? _defaultPartySeries() {
    final partySeries = _documentSeries
        .where((item) => (item.documentType ?? '').toUpperCase() == 'PARTY')
        .toList(growable: false);
    final series = partySeries.cast<DocumentSeriesModel?>().firstWhere(
      (item) => item?.isDefault == true,
      orElse: () => null,
    );

    return series ?? (partySeries.isNotEmpty ? partySeries.first : null);
  }

  String _generatePartyCodeForType(int? partyTypeId) {
    final typeCode = _partyTypeCode(partyTypeId);
    final series = _defaultPartySeries();
    final pattern = RegExp('^${RegExp.escape(typeCode)}/(\\d+)');
    var nextNumber = series?.nextNumber ?? 1;

    for (final party in _parties) {
      final match = pattern.firstMatch(
        (party.partyCode ?? '').trim().toUpperCase(),
      );
      if (match == null) {
        continue;
      }

      final value = int.tryParse(match.group(1) ?? '');
      if (value != null && value >= nextNumber) {
        nextNumber = value + 1;
      }
    }

    final number = nextNumber.toString().padLeft(
      series?.numberLength ?? 5,
      '0',
    );
    final suffix = (series?.suffix ?? '').trim();

    return '$typeCode/$number$suffix';
  }

  void _setPartyCode(String value, {bool autoGenerated = false}) {
    _suppressPartyCodeListener = true;
    _partyCodeController.text = value;
    _suppressPartyCodeListener = false;
    _partyCodeManuallyEdited = !autoGenerated;
  }

  void _onPartyTypeChanged(int? value) {
    _controller.applyPartyTypeChange(
      value,
      supportsCompanyFlag: _supportsCompanyFlag(value),
      supportsGst: _supportsGst(value),
    );
    if (!_supportsGst(value)) {
      _resetGstForm();
    }

    if (_selectedParty == null && !_partyCodeManuallyEdited) {
      _setPartyCode(_generatePartyCodeForType(value), autoGenerated: true);
      _controller.update();
    }
  }

  Future<void> _selectParty(PartyModel party) async {
    _controller.selectParty(party);
    _partyCodeController.text = party.partyCode ?? '';
    _partyCodeManuallyEdited = true;
    _partyNameController.text = party.partyName ?? '';
    _displayNameController.text = party.displayName ?? '';
    _websiteController.text = party.website ?? '';
    _panController.text = party.pan ?? '';
    _aadhaarController.text = party.aadhaar ?? '';
    _currencyController.text = party.defaultCurrency ?? 'INR';
    _openingBalanceController.text = party.openingBalance?.toString() ?? '';
    _remarksController.text = party.remarks ?? '';

    _resetAddressForm();
    _resetContactForm();
    _resetGstForm();
    _resetBankForm();
    _resetCreditForm();
    _resetPaymentTermForm();

    await _loadPartyChildren(party.id!);
  }

  Future<void> _loadPartyChildren(int partyId) async {
    try {
      final addressesResponse = await _partiesService.partyAddresses(partyId);
      final contactsResponse = await _partiesService.partyContacts(partyId);
      final gstResponse = await _partiesService.partyGstDetails(partyId);
      final bankResponse = await _partiesService.partyBankAccounts(partyId);
      final creditResponse = await _partiesService.partyCreditLimits(partyId);
      final paymentResponse = await _partiesService.partyPaymentTerms(partyId);

      if (!mounted) {
        return;
      }

      _controller.setPartyChildren(
        addresses: addressesResponse.data ?? const <PartyAddressModel>[],
        contacts: contactsResponse.data ?? const <PartyContactModel>[],
        gstDetails: gstResponse.data ?? const <PartyGstDetailModel>[],
        bankAccounts: bankResponse.data ?? const <PartyBankAccountModel>[],
        creditLimits: creditResponse.data ?? const <PartyCreditLimitModel>[],
        paymentTerms: paymentResponse.data ?? const <PartyPaymentTermModel>[],
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _controller.failDetailLoad(error.toString());
    }
  }

  void _resetPartyForm() {
    _controller.resetPartyDraft();
    _setPartyCode('', autoGenerated: true);
    _partyNameController.clear();
    _displayNameController.clear();
    _websiteController.clear();
    _panController.clear();
    _aadhaarController.clear();
    _currencyController.text = 'INR';
    _openingBalanceController.clear();
    _remarksController.clear();
  }

  void _clearDetailTabs() {
    _controller.clearDetailTabsState();
    _resetAddressForm();
    _resetContactForm();
    _resetGstForm();
    _resetBankForm();
    _resetCreditForm();
    _resetPaymentTermForm();
  }

  Future<void> _saveParty() async {
    if (!_partyFormKey.currentState!.validate()) {
      return;
    }

    _controller.beginPartySave();

    final model = PartyModel(
      id: _selectedParty?.id,
      partyCode: _partyCodeController.text.trim(),
      partyName: _partyNameController.text.trim(),
      displayName: nullIfEmpty(_displayNameController.text),
      partyTypeId: _partyTypeId,
      isCompany: _supportsCompanyFlag(_partyTypeId) ? _isCompany : false,
      website: nullIfEmpty(_websiteController.text),
      pan: nullIfEmpty(_panController.text),
      aadhaar: nullIfEmpty(_aadhaarController.text),
      defaultCurrency: nullIfEmpty(_currencyController.text) ?? 'INR',
      openingBalance: double.tryParse(_openingBalanceController.text.trim()),
      openingBalanceType: _openingBalanceType,
      remarks: nullIfEmpty(_remarksController.text),
      isActive: _partyActive,
    );

    try {
      final response = _selectedParty == null
          ? await _partiesService.createParty(model)
          : await _partiesService.updateParty(_selectedParty!.id!, model);

      final saved = response.data;
      if (!mounted) {
        return;
      }
      if (saved == null) {
        _controller.failPartySave(response.message);
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadPage(selectId: saved.id);
    } catch (error) {
      _controller.failPartySave(error.toString());
    } finally {
      if (mounted) {
        _controller.finishPartySave();
      }
    }
  }

  void _resetAddressForm() {
    _controller.resetAddressDraft();
    _addressLine1Controller.clear();
    _addressLine2Controller.clear();
    _addressAreaController.clear();
    _addressCityController.clear();
    _addressDistrictController.clear();
    _addressStateCodeController.clear();
    _addressStateNameController.clear();
    _addressCountryCodeController.clear();
    _addressPostalCodeController.clear();
  }

  void _selectAddress(PartyAddressModel address) {
    _controller.selectAddress(address);
    _addressLine1Controller.text = address.addressLine1 ?? '';
    _addressLine2Controller.text = address.addressLine2 ?? '';
    _addressAreaController.text = address.area ?? '';
    _addressCityController.text = address.city ?? '';
    _addressDistrictController.text = address.district ?? '';
    _addressStateCodeController.text = address.stateCode ?? '';
    _addressStateNameController.text = address.stateName ?? '';
    _addressCountryCodeController.text = address.countryCode ?? '';
    _addressPostalCodeController.text = address.postalCode ?? '';
  }

  Future<void> _saveAddress() async {
    final partyId = _selectedParty?.id;
    if (partyId == null || !_addressFormKey.currentState!.validate()) {
      return;
    }

    _controller.beginDetailSave();

    try {
      final model = PartyAddressModel(
        id: _selectedAddress?.id,
        partyId: partyId,
        addressType: _addressType,
        addressLine1: nullIfEmpty(_addressLine1Controller.text),
        addressLine2: nullIfEmpty(_addressLine2Controller.text),
        area: nullIfEmpty(_addressAreaController.text),
        city: nullIfEmpty(_addressCityController.text),
        district: nullIfEmpty(_addressDistrictController.text),
        stateCode: nullIfEmpty(_addressStateCodeController.text),
        stateName: nullIfEmpty(_addressStateNameController.text),
        countryCode: nullIfEmpty(_addressCountryCodeController.text),
        postalCode: nullIfEmpty(_addressPostalCodeController.text),
        isDefault: _addressDefault,
        isActive: _addressActive,
      );

      final response = _selectedAddress == null
          ? await _partiesService.createPartyAddress(partyId, model)
          : await _partiesService.updatePartyAddress(
              partyId,
              _selectedAddress!.id!,
              model,
            );

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadPartyChildren(partyId);
      _controller.closeDetailDraft('addresses');
      _resetAddressForm();
    } catch (error) {
      _controller.failDetailSave(error.toString());
    } finally {
      if (mounted) {
        _controller.finishDetailSave();
      }
    }
  }

  void _resetContactForm() {
    _controller.resetContactDraft();
    _contactNameController.clear();
    _contactDesignationController.clear();
    _contactMobileController.clear();
    _contactPhoneController.clear();
    _contactEmailController.clear();
  }

  void _selectContact(PartyContactModel contact) {
    _controller.selectContact(contact);
    _contactNameController.text = contact.contactName ?? '';
    _contactDesignationController.text = contact.designation ?? '';
    _contactMobileController.text = contact.mobile ?? '';
    _contactPhoneController.text = contact.phone ?? '';
    _contactEmailController.text = contact.email ?? '';
  }

  Future<void> _saveContact() async {
    final partyId = _selectedParty?.id;
    if (partyId == null || !_contactFormKey.currentState!.validate()) {
      return;
    }

    _controller.beginDetailSave();

    try {
      final model = PartyContactModel(
        id: _selectedContact?.id,
        partyId: partyId,
        contactName: _contactNameController.text.trim(),
        designation: nullIfEmpty(_contactDesignationController.text),
        mobile: nullIfEmpty(_contactMobileController.text),
        phone: nullIfEmpty(_contactPhoneController.text),
        email: nullIfEmpty(_contactEmailController.text),
        isPrimary: _contactPrimary,
        isActive: _contactActive,
      );

      final response = _selectedContact == null
          ? await _partiesService.createPartyContact(partyId, model)
          : await _partiesService.updatePartyContact(
              partyId,
              _selectedContact!.id!,
              model,
            );

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadPartyChildren(partyId);
      _controller.closeDetailDraft('contacts');
      _resetContactForm();
    } catch (error) {
      _controller.failDetailSave(error.toString());
    } finally {
      if (mounted) {
        _controller.finishDetailSave();
      }
    }
  }

  void _resetGstForm() {
    _controller.resetGstDraft();
    _gstinDetailController.clear();
    _gstLegalNameController.clear();
    _gstTradeNameController.clear();
    _gstStateCodeController.clear();
    _gstStateNameController.clear();
    _gstAddress1Controller.clear();
    _gstAddress2Controller.clear();
    _gstCityController.clear();
    _gstDistrictController.clear();
    _gstPostalCodeController.clear();
  }

  void _selectGstDetail(PartyGstDetailModel record) {
    final data = record.toJson();
    _controller.selectGstDetail(record, data);
    _gstinDetailController.text = stringValue(data, 'gstin');
    _gstLegalNameController.text = stringValue(data, 'legal_name');
    _gstTradeNameController.text = stringValue(data, 'trade_name');
    _gstStateCodeController.text = stringValue(data, 'state_code');
    _gstStateNameController.text = stringValue(data, 'state_name');
    _gstAddress1Controller.text = stringValue(data, 'address_line1');
    _gstAddress2Controller.text = stringValue(data, 'address_line2');
    _gstCityController.text = stringValue(data, 'city');
    _gstDistrictController.text = stringValue(data, 'district');
    _gstPostalCodeController.text = stringValue(data, 'postal_code');
  }

  Future<void> _saveGstDetail() async {
    final partyId = _selectedParty?.id;
    if (partyId == null || !_gstFormKey.currentState!.validate()) {
      return;
    }

    _controller.beginDetailSave();

    try {
      final body = PartyGstDetailModel.fromJson({
        if (intValue(_selectedGstDetail?.toJson() ?? const {}, 'id') != null)
          'id': intValue(_selectedGstDetail!.toJson(), 'id'),
        'gstin': nullIfEmpty(_gstinDetailController.text),
        'registration_type': _registrationType,
        'legal_name': nullIfEmpty(_gstLegalNameController.text),
        'trade_name': nullIfEmpty(_gstTradeNameController.text),
        'state_code': nullIfEmpty(_gstStateCodeController.text),
        'state_name': nullIfEmpty(_gstStateNameController.text),
        'address_line1': nullIfEmpty(_gstAddress1Controller.text),
        'address_line2': nullIfEmpty(_gstAddress2Controller.text),
        'city': nullIfEmpty(_gstCityController.text),
        'district': nullIfEmpty(_gstDistrictController.text),
        'postal_code': nullIfEmpty(_gstPostalCodeController.text),
        'is_default': _gstDefault,
        'is_active': _gstActive,
      });

      final id = intValue(_selectedGstDetail?.toJson() ?? const {}, 'id');
      final response = id == null
          ? await _partiesService.createPartyGstDetail(partyId, body)
          : await _partiesService.updatePartyGstDetail(partyId, id, body);

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadPartyChildren(partyId);
      _controller.closeDetailDraft('gst');
      _resetGstForm();
    } catch (error) {
      _controller.failDetailSave(error.toString());
    } finally {
      if (mounted) {
        _controller.finishDetailSave();
      }
    }
  }

  void _resetBankForm() {
    _controller.resetBankDraft();
    _bankAccountHolderController.clear();
    _bankNameController.clear();
    _bankBranchController.clear();
    _bankAccountNumberController.clear();
    _bankIfscController.clear();
    _bankSwiftController.clear();
    _bankIbanController.clear();
    _bankUpiController.clear();
  }

  void _selectBankAccount(PartyBankAccountModel record) {
    final data = record.toJson();
    _controller.selectBankAccount(record, data);
    _bankAccountHolderController.text = stringValue(
      data,
      'account_holder_name',
    );
    _bankNameController.text = stringValue(data, 'bank_name');
    _bankBranchController.text = stringValue(data, 'branch_name');
    _bankAccountNumberController.text = stringValue(data, 'account_number');
    _bankIfscController.text = stringValue(data, 'ifsc_code');
    _bankSwiftController.text = stringValue(data, 'swift_code');
    _bankIbanController.text = stringValue(data, 'iban');
    _bankUpiController.text = stringValue(data, 'upi_id');
  }

  Future<void> _saveBankAccount() async {
    final partyId = _selectedParty?.id;
    if (partyId == null || !_bankFormKey.currentState!.validate()) {
      return;
    }

    _controller.beginDetailSave();

    try {
      final body = PartyBankAccountModel.fromJson({
        if (intValue(_selectedBankAccount?.toJson() ?? const {}, 'id') != null)
          'id': intValue(_selectedBankAccount!.toJson(), 'id'),
        'account_holder_name': _bankAccountHolderController.text.trim(),
        'bank_name': _bankNameController.text.trim(),
        'branch_name': nullIfEmpty(_bankBranchController.text),
        'account_number': _bankAccountNumberController.text.trim(),
        'ifsc_code': nullIfEmpty(_bankIfscController.text),
        'swift_code': nullIfEmpty(_bankSwiftController.text),
        'iban': nullIfEmpty(_bankIbanController.text),
        'upi_id': nullIfEmpty(_bankUpiController.text),
        'is_default': _bankDefault,
        'is_active': _bankActive,
      });

      final id = intValue(_selectedBankAccount?.toJson() ?? const {}, 'id');
      final response = id == null
          ? await _partiesService.createPartyBankAccount(partyId, body)
          : await _partiesService.updatePartyBankAccount(partyId, id, body);

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadPartyChildren(partyId);
      _controller.closeDetailDraft('bank');
      _resetBankForm();
    } catch (error) {
      _controller.failDetailSave(error.toString());
    } finally {
      if (mounted) {
        _controller.finishDetailSave();
      }
    }
  }

  void _resetCreditForm() {
    _controller.resetCreditDraft();
    _creditLimitController.clear();
    _creditDaysController.clear();
    _creditFromController.clear();
    _creditToController.clear();
  }

  void _selectCreditLimit(PartyCreditLimitModel record) {
    final data = record.toJson();
    _controller.selectCreditLimit(record, data);
    _creditLimitController.text = stringValue(data, 'credit_limit');
    _creditDaysController.text = stringValue(data, 'credit_days');
    _creditFromController.text = stringValue(data, 'effective_from');
    _creditToController.text = stringValue(data, 'effective_to');
  }

  Future<void> _saveCreditLimit() async {
    final partyId = _selectedParty?.id;
    if (partyId == null || !_creditFormKey.currentState!.validate()) {
      return;
    }

    _controller.beginDetailSave();

    try {
      final body = PartyCreditLimitModel.fromJson({
        if (intValue(_selectedCreditLimit?.toJson() ?? const {}, 'id') != null)
          'id': intValue(_selectedCreditLimit!.toJson(), 'id'),
        'credit_limit': double.tryParse(_creditLimitController.text.trim()),
        'credit_days': int.tryParse(_creditDaysController.text.trim()),
        'effective_from': nullIfEmpty(_creditFromController.text),
        'effective_to': nullIfEmpty(_creditToController.text),
        'is_active': _creditActive,
      });

      final id = intValue(_selectedCreditLimit?.toJson() ?? const {}, 'id');
      final response = id == null
          ? await _partiesService.createPartyCreditLimit(partyId, body)
          : await _partiesService.updatePartyCreditLimit(partyId, id, body);

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadPartyChildren(partyId);
      _controller.closeDetailDraft('credit');
      _resetCreditForm();
    } catch (error) {
      _controller.failDetailSave(error.toString());
    } finally {
      if (mounted) {
        _controller.finishDetailSave();
      }
    }
  }

  void _resetPaymentTermForm() {
    _controller.resetPaymentTermDraft();
    _paymentTermNameController.clear();
    _paymentDaysController.clear();
    _paymentRemarksController.clear();
  }

  void _selectPaymentTerm(PartyPaymentTermModel record) {
    final data = record.toJson();
    _controller.selectPaymentTerm(record, data);
    _paymentTermNameController.text = stringValue(data, 'term_name');
    _paymentDaysController.text = stringValue(data, 'days');
    _paymentRemarksController.text = stringValue(data, 'remarks');
  }

  Future<void> _savePaymentTerm() async {
    final partyId = _selectedParty?.id;
    if (partyId == null || !_paymentTermFormKey.currentState!.validate()) {
      return;
    }

    _controller.beginDetailSave();

    try {
      final body = PartyPaymentTermModel.fromJson({
        if (intValue(_selectedPaymentTerm?.toJson() ?? const {}, 'id') != null)
          'id': intValue(_selectedPaymentTerm!.toJson(), 'id'),
        'term_name': _paymentTermNameController.text.trim(),
        'days': int.tryParse(_paymentDaysController.text.trim()),
        'due_basis': _dueBasis,
        'remarks': nullIfEmpty(_paymentRemarksController.text),
        'is_default': _paymentDefault,
        'is_active': _paymentActive,
      });

      final id = intValue(_selectedPaymentTerm?.toJson() ?? const {}, 'id');
      final response = id == null
          ? await _partiesService.createPartyPaymentTerm(partyId, body)
          : await _partiesService.updatePartyPaymentTerm(partyId, id, body);

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadPartyChildren(partyId);
      _controller.closeDetailDraft('payment_terms');
      _resetPaymentTermForm();
    } catch (error) {
      _controller.failDetailSave(error.toString());
    } finally {
      if (mounted) {
        _controller.finishDetailSave();
      }
    }
  }

  void _startNewParty() {
    _resetPartyForm();
    _clearDetailTabs();
    _tabController.animateTo(0);

    if (!Responsive.isDesktop(context)) {
      _workspaceController.openEditor();
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    final actions = <Widget>[
      AdaptiveShellActionButton(
        onPressed: _startNewParty,
        icon: Icons.person_add_alt_outlined,
        label: 'New Party',
      ),
    ];

    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }

    return AppStandaloneShell(
      title: 'Parties',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading parties...');
    }

    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load parties',
        message: _pageError!,
        onRetry: _loadPage,
      );
    }

    final partyTypeFilterItems = _partyTypeFilterItems();
    final filteredParties = _computeFilteredParties(_parties);

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Parties',
      editorTitle: _selectedParty?.toString(),
      scrollController: _pageScrollController,
      list: AppSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppFormTextField(
              labelText: 'Search parties',
              controller: _searchController,
              prefixIcon: const Icon(Icons.search),
            ),
            const SizedBox(height: 12),
            AppDropdownField<int>.fromMapped(
              labelText: 'Party Type',
              mappedItems: partyTypeFilterItems,
              initialValue: _controller.partyTypeFilterId,
              onChanged: (value) =>
                  _controller.setPartyTypeFilterId(value ?? 0),
            ),
            const SizedBox(height: 12),
            AppDropdownField<String>.fromMapped(
              labelText: 'Sort',
              mappedItems: _sortItems,
              initialValue: _controller.partySort,
              onChanged: (value) =>
                  _controller.setPartySort(value ?? 'name_asc'),
            ),
            const SizedBox(height: 16),
            if (filteredParties.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('No parties found.'),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredParties.length,
                separatorBuilder: (_, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final party = filteredParties[index];
                  final selected = identical(party, _selectedParty);
                  return SettingsListTile(
                    title: party.partyName ?? '-',
                    subtitle: [
                      party.partyType ?? '',
                      party.partyCode ?? '',
                      party.displayName ?? '',
                    ].where((value) => value.isNotEmpty).join(' • '),
                    selected: selected,
                    onTap: () => _selectParty(party),
                    trailing: SettingsStatusPill(
                      label: party.isActive ? 'Active' : 'Inactive',
                      active: party.isActive,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
      editor: GetBuilder<PartyManagementController>(
        tag: _controllerTag,
        builder: (controller) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Primary'),
                  Tab(text: 'Addresses'),
                  Tab(text: 'Contacts'),
                  Tab(text: 'GST Details'),
                  Tab(text: 'Bank Accounts'),
                  Tab(text: 'Credit Limits'),
                  Tab(text: 'Payment Terms'),
                  Tab(text: 'Party Accounts'),
                ],
              ),
              const SizedBox(height: 20),
              IndexedStack(
                index: controller.activeTabIndex,
                children: [
                  _buildPrimaryTab(context),
                  _buildAddressesTab(context),
                  _buildContactsTab(context),
                  _buildGstDetailsTab(context),
                  _buildBankAccountsTab(context),
                  _buildCreditLimitsTab(context),
                  _buildPaymentTermsTab(context),
                  _buildPartyAccountsTab(context),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPrimaryTab(BuildContext context) {
    final supportsCompanyFlag = _supportsCompanyFlag(_partyTypeId);
    final partyTypeItems = _partyTypes
        .map(
          (type) => AppDropdownItem<int>(
            value: intValue(type.toJson(), 'id') ?? 0,
            label: stringValue(type.toJson(), 'name'),
          ),
        )
        .toList(growable: false);

    return Form(
      key: _partyFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_partyFormError != null) ...[
            AppErrorStateView.inline(message: _partyFormError!),
            const SizedBox(height: 16),
          ],
          SettingsFormWrap(
            children: [
              AppDropdownField<int>.fromMapped(
                labelText: 'Party Type',
                mappedItems: partyTypeItems,
                initialValue: _partyTypeId,
                onChanged: _onPartyTypeChanged,
                validator: Validators.requiredSelection('Party type'),
              ),
              AppFormTextField(
                labelText: 'Party Code',
                controller: _partyCodeController,
                readOnly: true,
                validator: Validators.compose([
                  Validators.required('Party code'),
                  Validators.optionalMaxLength(50, 'Party code'),
                ]),
              ),
              AppFormTextField(
                labelText: 'Party Name',
                controller: _partyNameController,
                validator: Validators.compose([
                  Validators.required('Party name'),
                  Validators.optionalMaxLength(255, 'Party name'),
                ]),
              ),
              AppFormTextField(
                labelText: 'Display Name',
                controller: _displayNameController,
                validator: Validators.optionalMaxLength(255, 'Display name'),
              ),
              AppFormTextField(
                labelText: 'Website',
                controller: _websiteController,
                validator: Validators.optionalMaxLength(255, 'Website'),
              ),
              AppFormTextField(
                labelText: 'PAN',
                controller: _panController,
                validator: Validators.compose([
                  Validators.optionalMaxLength(10, 'PAN'),
                  Validators.optionalExactLength(10, 'PAN'),
                ]),
              ),
              AppFormTextField(
                labelText: 'Aadhaar',
                controller: _aadhaarController,
                validator: Validators.optionalDigitsExactLength(12, 'Aadhaar'),
              ),
              AppFormTextField(
                labelText: 'Default Currency',
                controller: _currencyController,
                validator: Validators.optionalMaxLength(10, 'Default currency'),
              ),
              AppFormTextField(
                labelText: 'Opening Balance',
                controller: _openingBalanceController,
                keyboardType: TextInputType.number,
                validator: Validators.optionalNonNegativeNumber(
                  'Opening balance',
                ),
              ),
              AppDropdownField<String>.fromMapped(
                labelText: 'Opening Balance Type',
                mappedItems: _openingBalanceTypeItems,
                initialValue: _openingBalanceType,
                onChanged: (value) =>
                    _controller.setOpeningBalanceType(value ?? 'debit'),
              ),
              AppFormTextField(
                labelText: 'Remarks',
                controller: _remarksController,
                maxLines: 3,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              if (supportsCompanyFlag)
                SizedBox(
                  child: AppSwitchTile(
                    label: 'Is Company',
                    value: _isCompany,
                    onChanged: (value) => _controller.setIsCompany(value),
                  ),
                ),
              SizedBox(
                child: AppSwitchTile(
                  label: 'Active',
                  value: _partyActive,
                  onChanged: (value) => _controller.setPartyActive(value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AppActionButton(
            icon: Icons.save_outlined,
            label: _selectedParty == null ? 'Save Party' : 'Update Party',
            onPressed: _saveParty,
            busy: _partySaving,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressesTab(BuildContext context) {
    return _buildDetailTab(
      sectionKey: 'addresses',
      title: 'Addresses',
      subtitle:
          'Maintain billing, shipping, office, or factory addresses for the selected party.',
      emptyTitle: 'Select a party first',
      emptyMessage:
          'Choose a party from the left to manage addresses for that party.',
      onNew: _resetAddressForm,
      list: _addresses,
      selected: _selectedAddress,
      itemTitle: (item) => item.addressType?.toUpperCase() ?? 'ADDRESS',
      itemSubtitle: (item) => [
        item.city ?? '',
        item.stateName ?? item.stateCode ?? '',
        item.postalCode ?? '',
      ].where((value) => value.isNotEmpty).join(' • '),
      onSelect: (item) => _selectAddress(item),
      form: Form(key: _addressFormKey, child: _buildAddressForm(context)),
    );
  }

  Widget _buildContactsTab(BuildContext context) {
    return _buildDetailTab(
      sectionKey: 'contacts',
      title: 'Contacts',
      subtitle:
          'Track contact persons, designations, and primary communication points.',
      emptyTitle: 'Select a party first',
      emptyMessage:
          'Choose a party from the left to manage contact persons for that party.',
      onNew: _resetContactForm,
      list: _contacts,
      selected: _selectedContact,
      itemTitle: (item) => item.contactName ?? 'Contact',
      itemSubtitle: (item) => [
        item.designation ?? '',
        item.mobile ?? '',
        item.email ?? '',
      ].where((value) => value.isNotEmpty).join(' • '),
      onSelect: (item) => _selectContact(item),
      form: Form(key: _contactFormKey, child: _buildContactForm(context)),
    );
  }

  Widget _buildGstDetailsTab(BuildContext context) {
    if (!_supportsGst(_selectedParty?.partyTypeId ?? _partyTypeId)) {
      return SettingsEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'GST not applicable',
        message:
            'GST details are not required for bank, cash, employee, or general parties.',
        minHeight: 200,
      );
    }

    return _buildDetailTab<PartyGstDetailModel>(
      sectionKey: 'gst',
      title: 'GST Details',
      subtitle:
          'Keep one or more GST registrations, legal names, and addresses linked to the party.',
      emptyTitle: 'Select a party first',
      emptyMessage:
          'Choose a party from the left to manage GST registrations for that party.',
      onNew: _resetGstForm,
      list: _gstDetails,
      selected: _selectedGstDetail,
      itemTitle: (item) => stringValue(
        item.toJson(),
        'gstin',
        stringValue(item.toJson(), 'registration_type', 'GST Detail'),
      ),
      itemSubtitle: (item) => [
        stringValue(item.toJson(), 'registration_type'),
        stringValue(item.toJson(), 'state_name'),
      ].where((value) => value.isNotEmpty).join(' • '),
      onSelect: (item) => _selectGstDetail(item),
      form: Form(key: _gstFormKey, child: _buildGstForm(context)),
    );
  }

  Widget _buildBankAccountsTab(BuildContext context) {
    return _buildDetailTab<PartyBankAccountModel>(
      sectionKey: 'bank',
      title: 'Bank Accounts',
      subtitle:
          'Store bank, branch, account, and UPI details for settlements and reimbursements.',
      emptyTitle: 'Select a party first',
      emptyMessage:
          'Choose a party from the left to manage bank accounts for that party.',
      onNew: _resetBankForm,
      list: _bankAccounts,
      selected: _selectedBankAccount,
      itemTitle: (item) =>
          stringValue(item.toJson(), 'account_holder_name', 'Bank Account'),
      itemSubtitle: (item) => [
        stringValue(item.toJson(), 'bank_name'),
        stringValue(item.toJson(), 'account_number'),
      ].where((value) => value.isNotEmpty).join(' • '),
      onSelect: (item) => _selectBankAccount(item),
      form: Form(key: _bankFormKey, child: _buildBankForm(context)),
    );
  }

  Widget _buildCreditLimitsTab(BuildContext context) {
    return _buildDetailTab<PartyCreditLimitModel>(
      sectionKey: 'credit',
      title: 'Credit Limits',
      subtitle:
          'Define the credit cap, days, and effective period for this party.',
      emptyTitle: 'Select a party first',
      emptyMessage:
          'Choose a party from the left to manage credit limits for that party.',
      onNew: _resetCreditForm,
      list: _creditLimits,
      selected: _selectedCreditLimit,
      itemTitle: (item) =>
          stringValue(item.toJson(), 'credit_limit', 'Credit Limit'),
      itemSubtitle: (item) => [
        stringValue(item.toJson(), 'credit_days'),
        stringValue(item.toJson(), 'effective_from'),
        stringValue(item.toJson(), 'effective_to'),
      ].where((value) => value.isNotEmpty).join(' • '),
      onSelect: (item) => _selectCreditLimit(item),
      form: Form(key: _creditFormKey, child: _buildCreditForm(context)),
    );
  }

  Widget _buildPaymentTermsTab(BuildContext context) {
    return _buildDetailTab<PartyPaymentTermModel>(
      sectionKey: 'payment_terms',
      title: 'Payment Terms',
      subtitle:
          'Maintain invoice due basis, days, and default payment term logic for the party.',
      emptyTitle: 'Select a party first',
      emptyMessage:
          'Choose a party from the left to manage payment terms for that party.',
      onNew: _resetPaymentTermForm,
      list: _paymentTerms,
      selected: _selectedPaymentTerm,
      itemTitle: (item) =>
          stringValue(item.toJson(), 'term_name', 'Payment Term'),
      itemSubtitle: (item) => [
        stringValue(item.toJson(), 'due_basis'),
        stringValue(item.toJson(), 'days'),
      ].where((value) => value.isNotEmpty).join(' • '),
      onSelect: (item) => _selectPaymentTerm(item),
      form: Form(
        key: _paymentTermFormKey,
        child: _buildPaymentTermForm(context),
      ),
    );
  }

  Widget _buildPartyAccountsTab(BuildContext context) {
    if (!_controller.partyAccountsAccessResolved) {
      return const AppLoadingView(message: 'Checking account access...');
    }

    if (!_controller.canViewPartyAccounts) {
      return const SettingsEmptyState(
        icon: Icons.lock_outline,
        title: 'Accounting access required',
        message:
            'Party–ledger mapping requires accounting permission. Ask an administrator for accounts access.',
        minHeight: 200,
      );
    }

    if (_selectedParty?.id == null) {
      return const SettingsEmptyState(
        icon: Icons.handshake_outlined,
        title: 'Select a party first',
        message:
            'Choose a party from the list, then open the Party Accounts register to create or edit ledger links.',
      );
    }

    final partyId = _selectedParty!.id!;
    final route =
        '/accounting/party-accounts?party_id=${Uri.encodeComponent('$partyId')}';

    return Padding(
      padding: const EdgeInsets.all(AppUiConstants.pagePadding),
      child: AppSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Party accounts',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
            Text(
              'Ledger mappings for ${_selectedParty!.displayName ?? _selectedParty!.partyName ?? 'this party'} are maintained on the Party account register so you have one place to add, edit, or remove links.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppUiConstants.spacingLg),
            FilledButton.icon(
              onPressed: () {
                final navigate = ShellRouteScope.maybeOf(context);
                if (navigate != null) {
                  navigate(route);
                } else {
                  Navigator.of(context).pushNamed(route);
                }
              },
              icon: const Icon(Icons.open_in_new_outlined),
              label: const Text('Open party account register'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTab<T>({
    required String sectionKey,
    required String title,
    required String subtitle,
    required String emptyTitle,
    required String emptyMessage,
    required VoidCallback onNew,
    required List<T> list,
    required T? selected,
    required String Function(T item) itemTitle,
    required String Function(T item) itemSubtitle,
    required ValueChanged<T> onSelect,
    required Widget form,
  }) {
    if (_selectedParty?.id == null) {
      return SettingsEmptyState(
        icon: Icons.handshake_outlined,
        title: emptyTitle,
        message: emptyMessage,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            AppActionButton(
              icon: Icons.add_outlined,
              label: 'New',
              onPressed: () {
                onNew();
                _controller.openDetailDraft(sectionKey);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).extension<AppThemeExtension>()!.mutedText,
          ),
        ),
        if (_detailFormError != null) ...[
          const SizedBox(height: 16),
          AppErrorStateView.inline(message: _detailFormError!),
        ],
        const SizedBox(height: 16),
        if (_controller.isDetailDraftOpen(sectionKey)) ...[
          SettingsExpandableTile(
            key: ValueKey('$sectionKey-draft'),
            title: 'New $title',
            subtitle: subtitle,
            expanded: true,
            highlighted: true,
            leadingIcon: Icons.add_outlined,
            onToggle: () {
              onNew();
              _controller.closeDetailDraft(sectionKey);
            },
            child: form,
          ),
          if (list.isNotEmpty) const SizedBox(height: 8),
        ],
        if (list.isEmpty && !_controller.isDetailDraftOpen(sectionKey))
          SettingsEmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'No records yet',
            message: 'Create the first record for this section.',
            minHeight: 200,
          )
        else
          ListView.separated(
            shrinkWrap: true,
            primary: false,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (_, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = list[index];
              final expanded = identical(item, selected);
              return SettingsExpandableTile(
                key: ValueKey('$sectionKey-$index-$expanded'),
                title: itemTitle(item),
                subtitle: itemSubtitle(item),
                expanded: expanded,
                highlighted: expanded,
                onToggle: () {
                  if (expanded) {
                    onNew();
                  } else {
                    onSelect(item);
                  }
                  _controller.closeDetailDraft(sectionKey);
                },
                child: form,
              );
            },
          ),
      ],
    );
  }

  Widget _buildAddressForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsFormWrap(
          children: [
            AppDropdownField<String>.fromMapped(
              labelText: 'Address Type',
              mappedItems: _addressTypeItems,
              initialValue: _addressType,
              onChanged: (value) =>
                  _controller.setAddressType(value ?? 'billing'),
            ),
            AppFormTextField(
              labelText: 'Address Line 1',
              controller: _addressLine1Controller,
              validator: Validators.compose([
                Validators.required('Address line 1'),
                Validators.optionalMaxLength(255, 'Address line 1'),
              ]),
            ),
            AppFormTextField(
              labelText: 'Address Line 2',
              controller: _addressLine2Controller,
              validator: Validators.optionalMaxLength(255, 'Address line 2'),
            ),
            AppFormTextField(
              labelText: 'Area',
              controller: _addressAreaController,
              validator: Validators.optionalMaxLength(150, 'Area'),
            ),
            AppFormTextField(
              labelText: 'City',
              controller: _addressCityController,
              validator: Validators.optionalMaxLength(100, 'City'),
            ),
            AppFormTextField(
              labelText: 'District',
              controller: _addressDistrictController,
              validator: Validators.optionalMaxLength(100, 'District'),
            ),
            AppFormTextField(
              labelText: 'State Code',
              controller: _addressStateCodeController,
              validator: Validators.optionalMaxLength(5, 'State code'),
            ),
            AppFormTextField(
              labelText: 'State Name',
              controller: _addressStateNameController,
              validator: Validators.optionalMaxLength(100, 'State name'),
            ),
            AppFormTextField(
              labelText: 'Country Code',
              controller: _addressCountryCodeController,
              validator: Validators.optionalMaxLength(5, 'Country code'),
            ),
            AppFormTextField(
              labelText: 'Postal Code',
              controller: _addressPostalCodeController,
              validator: Validators.optionalMaxLength(20, 'Postal code'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            SizedBox(
              child: AppSwitchTile(
                label: 'Default',
                value: _addressDefault,
                onChanged: (value) => _controller.setAddressDefault(value),
              ),
            ),
            SizedBox(
              child: AppSwitchTile(
                label: 'Active',
                value: _addressActive,
                onChanged: (value) => _controller.setAddressActive(value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppActionButton(
          icon: Icons.save_outlined,
          label: _selectedAddress == null ? 'Save Address' : 'Update Address',
          onPressed: _saveAddress,
          busy: _detailSaving,
        ),
      ],
    );
  }

  Widget _buildContactForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsFormWrap(
          children: [
            AppFormTextField(
              labelText: 'Contact Name',
              controller: _contactNameController,
              validator: Validators.compose([
                Validators.required('Contact name'),
                Validators.optionalMaxLength(150, 'Contact name'),
              ]),
            ),
            AppFormTextField(
              labelText: 'Designation',
              controller: _contactDesignationController,
              validator: Validators.optionalMaxLength(100, 'Designation'),
            ),
            AppFormTextField(
              labelText: 'Mobile',
              controller: _contactMobileController,
              validator: Validators.optionalMaxLength(20, 'Mobile'),
            ),
            AppFormTextField(
              labelText: 'Phone',
              controller: _contactPhoneController,
              validator: Validators.optionalMaxLength(20, 'Phone'),
            ),
            AppFormTextField(
              labelText: 'Email',
              controller: _contactEmailController,
              validator: Validators.compose([
                Validators.optionalEmail(),
                Validators.optionalMaxLength(150, 'Email'),
              ]),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            SizedBox(
              child: AppSwitchTile(
                label: 'Primary Contact',
                value: _contactPrimary,
                onChanged: (value) => _controller.setContactPrimary(value),
              ),
            ),
            SizedBox(
              child: AppSwitchTile(
                label: 'Active',
                value: _contactActive,
                onChanged: (value) => _controller.setContactActive(value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppActionButton(
          icon: Icons.save_outlined,
          label: _selectedContact == null ? 'Save Contact' : 'Update Contact',
          onPressed: _saveContact,
          busy: _detailSaving,
        ),
      ],
    );
  }

  Widget _buildGstForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsFormWrap(
          children: [
            AppFormTextField(
              labelText: 'GSTIN',
              controller: _gstinDetailController,
              validator: Validators.compose([
                Validators.optionalMaxLength(15, 'GSTIN'),
                Validators.optionalExactLength(15, 'GSTIN'),
              ]),
            ),
            AppDropdownField<String>.fromMapped(
              labelText: 'Registration Type',
              mappedItems: _registrationTypeItems,
              initialValue: _registrationType,
              onChanged: (value) =>
                  _controller.setRegistrationType(value ?? 'regular'),
              validator: Validators.requiredSelection('Registration type'),
            ),
            AppFormTextField(
              labelText: 'Legal Name',
              controller: _gstLegalNameController,
              validator: Validators.optionalMaxLength(255, 'Legal name'),
            ),
            AppFormTextField(
              labelText: 'Trade Name',
              controller: _gstTradeNameController,
              validator: Validators.optionalMaxLength(255, 'Trade name'),
            ),
            AppFormTextField(
              labelText: 'State Code',
              controller: _gstStateCodeController,
              validator: Validators.optionalMaxLength(5, 'State code'),
            ),
            AppFormTextField(
              labelText: 'State Name',
              controller: _gstStateNameController,
              validator: Validators.optionalMaxLength(100, 'State name'),
            ),
            AppFormTextField(
              labelText: 'Address Line 1',
              controller: _gstAddress1Controller,
              validator: Validators.optionalMaxLength(255, 'Address line 1'),
            ),
            AppFormTextField(
              labelText: 'Address Line 2',
              controller: _gstAddress2Controller,
              validator: Validators.optionalMaxLength(255, 'Address line 2'),
            ),
            AppFormTextField(
              labelText: 'City',
              controller: _gstCityController,
              validator: Validators.optionalMaxLength(100, 'City'),
            ),
            AppFormTextField(
              labelText: 'District',
              controller: _gstDistrictController,
              validator: Validators.optionalMaxLength(100, 'District'),
            ),
            AppFormTextField(
              labelText: 'Postal Code',
              controller: _gstPostalCodeController,
              validator: Validators.optionalMaxLength(20, 'Postal code'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            SizedBox(
              child: AppSwitchTile(
                label: 'Default GST Detail',
                value: _gstDefault,
                onChanged: (value) => _controller.setGstDefault(value),
              ),
            ),
            SizedBox(
              child: AppSwitchTile(
                label: 'Active',
                value: _gstActive,
                onChanged: (value) => _controller.setGstActive(value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppActionButton(
          icon: Icons.save_outlined,
          label: _selectedGstDetail == null
              ? 'Save GST Detail'
              : 'Update GST Detail',
          onPressed: _saveGstDetail,
          busy: _detailSaving,
        ),
      ],
    );
  }

  Widget _buildBankForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsFormWrap(
          children: [
            AppFormTextField(
              labelText: 'Account Holder Name',
              controller: _bankAccountHolderController,
              validator: Validators.compose([
                Validators.required('Account holder name'),
                Validators.optionalMaxLength(255, 'Account holder name'),
              ]),
            ),
            AppFormTextField(
              labelText: 'Bank Name',
              controller: _bankNameController,
              validator: Validators.compose([
                Validators.required('Bank name'),
                Validators.optionalMaxLength(255, 'Bank name'),
              ]),
            ),
            AppFormTextField(
              labelText: 'Branch Name',
              controller: _bankBranchController,
              validator: Validators.optionalMaxLength(255, 'Branch name'),
            ),
            AppFormTextField(
              labelText: 'Account Number',
              controller: _bankAccountNumberController,
              validator: Validators.compose([
                Validators.required('Account number'),
                Validators.optionalMaxLength(50, 'Account number'),
              ]),
            ),
            AppFormTextField(
              labelText: 'IFSC Code',
              controller: _bankIfscController,
              validator: Validators.compose([
                Validators.optionalMaxLength(20, 'IFSC code'),
                Validators.optionalExactLength(11, 'IFSC code'),
              ]),
            ),
            AppFormTextField(
              labelText: 'SWIFT Code',
              controller: _bankSwiftController,
              validator: Validators.optionalMaxLength(20, 'SWIFT code'),
            ),
            AppFormTextField(
              labelText: 'IBAN',
              controller: _bankIbanController,
              validator: Validators.optionalMaxLength(50, 'IBAN'),
            ),
            AppFormTextField(
              labelText: 'UPI ID',
              controller: _bankUpiController,
              validator: Validators.optionalMaxLength(100, 'UPI ID'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            SizedBox(
              child: AppSwitchTile(
                label: 'Default Bank Account',
                value: _bankDefault,
                onChanged: (value) => _controller.setBankDefault(value),
              ),
            ),
            SizedBox(
              child: AppSwitchTile(
                label: 'Active',
                value: _bankActive,
                onChanged: (value) => _controller.setBankActive(value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppActionButton(
          icon: Icons.save_outlined,
          label: _selectedBankAccount == null
              ? 'Save Bank Account'
              : 'Update Bank Account',
          onPressed: _saveBankAccount,
          busy: _detailSaving,
        ),
      ],
    );
  }

  Widget _buildCreditForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsFormWrap(
          children: [
            AppFormTextField(
              labelText: 'Credit Limit',
              controller: _creditLimitController,
              keyboardType: TextInputType.number,
              validator: Validators.optionalNonNegativeNumber('Credit limit'),
            ),
            AppFormTextField(
              labelText: 'Credit Days',
              controller: _creditDaysController,
              keyboardType: TextInputType.number,
              validator: Validators.optionalNonNegativeInteger('Credit days'),
            ),
            AppFormTextField(
              labelText: 'Effective From',
              controller: _creditFromController,
              inputFormatters: [DateInputFormatter()],
              hintText: 'YYYY-MM-DD',
              validator: Validators.optionalDate('Effective from'),
            ),
            AppFormTextField(
              labelText: 'Effective To',
              controller: _creditToController,
              inputFormatters: [DateInputFormatter()],
              hintText: 'YYYY-MM-DD',
              validator: Validators.optionalDateOnOrAfter(
                'Effective to',
                () => _creditFromController.text,
                startFieldName: 'Effective from',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          child: AppSwitchTile(
            label: 'Active',
            value: _creditActive,
            onChanged: (value) => _controller.setCreditActive(value),
          ),
        ),
        const SizedBox(height: 16),
        AppActionButton(
          icon: Icons.save_outlined,
          label: _selectedCreditLimit == null
              ? 'Save Credit Limit'
              : 'Update Credit Limit',
          onPressed: _saveCreditLimit,
          busy: _detailSaving,
        ),
      ],
    );
  }

  Widget _buildPaymentTermForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsFormWrap(
          children: [
            AppFormTextField(
              labelText: 'Term Name',
              controller: _paymentTermNameController,
              validator: Validators.compose([
                Validators.required('Term name'),
                Validators.optionalMaxLength(150, 'Term name'),
              ]),
            ),
            AppFormTextField(
              labelText: 'Days',
              controller: _paymentDaysController,
              keyboardType: TextInputType.number,
              validator: Validators.optionalNonNegativeInteger('Days'),
            ),
            AppDropdownField<String>.fromMapped(
              labelText: 'Due Basis',
              mappedItems: _dueBasisItems,
              initialValue: _dueBasis,
              onChanged: (value) =>
                  _controller.setDueBasis(value ?? 'invoice_date'),
              validator: Validators.requiredSelection('Due basis'),
            ),
            AppFormTextField(
              labelText: 'Remarks',
              controller: _paymentRemarksController,
              maxLines: 3,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            SizedBox(
              child: AppSwitchTile(
                label: 'Default Payment Term',
                value: _paymentDefault,
                onChanged: (value) => _controller.setPaymentDefault(value),
              ),
            ),
            SizedBox(
              child: AppSwitchTile(
                label: 'Active',
                value: _paymentActive,
                onChanged: (value) => _controller.setPaymentActive(value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppActionButton(
          icon: Icons.save_outlined,
          label: _selectedPaymentTerm == null
              ? 'Save Payment Term'
              : 'Update Payment Term',
          onPressed: _savePaymentTerm,
          busy: _detailSaving,
        ),
      ],
    );
  }
}
