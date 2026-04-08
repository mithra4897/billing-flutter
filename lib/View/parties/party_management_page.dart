import '../../screen.dart';

class PartyManagementPage extends StatefulWidget {
  const PartyManagementPage({
    super.key,
    this.embedded = false,
    this.initialTabIndex = 0,
  });

  final bool embedded;
  final int initialTabIndex;

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

  bool _initialLoading = true;
  bool _partySaving = false;
  bool _detailSaving = false;
  String? _pageError;
  String? _partyFormError;
  String? _detailFormError;

  List<PartyTypeModel> _partyTypes = const <PartyTypeModel>[];
  List<DocumentSeriesModel> _documentSeries = const <DocumentSeriesModel>[];
  List<PartyModel> _parties = const <PartyModel>[];
  List<PartyModel> _filteredParties = const <PartyModel>[];
  PartyModel? _selectedParty;
  int _partyTypeFilterId = 0;
  String _partySort = 'name_asc';

  int? _partyTypeId;
  bool _isCompany = false;
  String _openingBalanceType = 'debit';
  bool _partyActive = true;

  List<PartyAddressModel> _addresses = const <PartyAddressModel>[];
  PartyAddressModel? _selectedAddress;
  String _addressType = 'billing';
  bool _addressDefault = false;
  bool _addressActive = true;

  List<PartyContactModel> _contacts = const <PartyContactModel>[];
  PartyContactModel? _selectedContact;
  bool _contactPrimary = false;
  bool _contactActive = true;

  List<PartyGstDetailModel> _gstDetails = const <PartyGstDetailModel>[];
  PartyGstDetailModel? _selectedGstDetail;
  String _registrationType = 'regular';
  bool _gstDefault = false;
  bool _gstActive = true;

  List<PartyBankAccountModel> _bankAccounts = const <PartyBankAccountModel>[];
  PartyBankAccountModel? _selectedBankAccount;
  bool _bankDefault = false;
  bool _bankActive = true;

  List<PartyCreditLimitModel> _creditLimits = const <PartyCreditLimitModel>[];
  PartyCreditLimitModel? _selectedCreditLimit;
  bool _creditActive = true;

  List<PartyPaymentTermModel> _paymentTerms = const <PartyPaymentTermModel>[];
  PartyPaymentTermModel? _selectedPaymentTerm;
  String _dueBasis = 'invoice_date';
  bool _paymentDefault = false;
  bool _paymentActive = true;
  bool _partyCodeManuallyEdited = false;
  bool _suppressPartyCodeListener = false;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(
          length: 7,
          vsync: this,
          initialIndex: widget.initialTabIndex.clamp(0, 6),
        )..addListener(() {
          if (!_tabController.indexIsChanging) {
            setState(() {});
          }
        });
    _partyCodeController.addListener(_handlePartyCodeChanged);
    _searchController.addListener(_applySearch);
    _loadPage();
  }

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

  void _handlePartyCodeChanged() {
    if (_suppressPartyCodeListener) {
      return;
    }

    _partyCodeManuallyEdited = true;
  }

  Future<void> _loadPage({int? selectId}) async {
    setState(() {
      _initialLoading = _parties.isEmpty;
      _pageError = null;
    });

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

      setState(() {
        _partyTypes = partyTypes;
        _documentSeries = documentSeries;
        _parties = parties;
        _filteredParties = _computeFilteredParties(parties);
        _initialLoading = false;
      });

      final selected = selectId != null
          ? parties.cast<PartyModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (_selectedParty == null
                ? (parties.isNotEmpty ? parties.first : null)
                : parties.cast<PartyModel?>().firstWhere(
                    (item) => item?.id == _selectedParty?.id,
                    orElse: () => parties.isNotEmpty ? parties.first : null,
                  ));

      if (selected != null) {
        await _selectParty(selected);
      } else {
        _resetPartyForm();
        _clearDetailTabs();
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
      _filteredParties = _computeFilteredParties(_parties);
    });
  }

  List<PartyModel> _computeFilteredParties(List<PartyModel> source) {
    final filteredByType = _partyTypeFilterId == 0
        ? source
        : source
              .where((party) => party.partyTypeId == _partyTypeFilterId)
              .toList(growable: false);

    final searched = filterMasterList(filteredByType, _searchController.text, (
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

      switch (_partySort) {
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
          value: intValue(type.data, 'id') ?? 0,
          label: stringValue(type.data, 'name'),
        ),
      ),
    ];
  }

  PartyTypeModel? _partyTypeById(int? id) {
    if (id == null) {
      return null;
    }

    return _partyTypes.cast<PartyTypeModel?>().firstWhere(
      (item) => intValue(item?.data ?? const {}, 'id') == id,
      orElse: () => null,
    );
  }

  bool _isNonBusinessPartyType(int? id) {
    final type = _partyTypeById(id);
    final code = stringValue(type?.data ?? const {}, 'code').toUpperCase();

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
        stringValue(matched?.data ?? const {}, 'code').trim().isNotEmpty
        ? stringValue(matched?.data ?? const {}, 'code')
        : stringValue(matched?.data ?? const {}, 'name', 'PTY');
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
      final match = pattern.firstMatch((party.partyCode ?? '').trim().toUpperCase());
      if (match == null) {
        continue;
      }

      final value = int.tryParse(match.group(1) ?? '');
      if (value != null && value >= nextNumber) {
        nextNumber = value + 1;
      }
    }

    final number = nextNumber.toString().padLeft(series?.numberLength ?? 5, '0');
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
    setState(() {
      _partyTypeId = value;
      if (!_supportsCompanyFlag(value)) {
        _isCompany = false;
      }
      if (!_supportsGst(value)) {
        _gstDetails = const <PartyGstDetailModel>[];
        _selectedGstDetail = null;
        _resetGstForm();
      }
    });

    if (_selectedParty == null && !_partyCodeManuallyEdited) {
      _setPartyCode(_generatePartyCodeForType(value), autoGenerated: true);
      setState(() {});
    }
  }

  Future<void> _selectParty(PartyModel party) async {
    _selectedParty = party;
    _partyCodeController.text = party.partyCode ?? '';
    _partyCodeManuallyEdited = true;
    _partyNameController.text = party.partyName ?? '';
    _displayNameController.text = party.displayName ?? '';
    _partyTypeId = party.partyTypeId;
    _isCompany = party.isCompany;
    _websiteController.text = party.website ?? '';
    _panController.text = party.pan ?? '';
    _aadhaarController.text = party.aadhaar ?? '';
    _currencyController.text = party.defaultCurrency ?? 'INR';
    _openingBalanceController.text = party.openingBalance?.toString() ?? '';
    _openingBalanceType = party.openingBalanceType ?? 'debit';
    _remarksController.text = party.remarks ?? '';
    _partyActive = party.isActive;
    _partyFormError = null;

    _resetAddressForm();
    _resetContactForm();
    _resetGstForm();
    _resetBankForm();
    _resetCreditForm();
    _resetPaymentTermForm();

    setState(() {});

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

      setState(() {
        _addresses = addressesResponse.data ?? const <PartyAddressModel>[];
        _contacts = contactsResponse.data ?? const <PartyContactModel>[];
        _gstDetails = gstResponse.data ?? const <PartyGstDetailModel>[];
        _bankAccounts = bankResponse.data ?? const <PartyBankAccountModel>[];
        _creditLimits = creditResponse.data ?? const <PartyCreditLimitModel>[];
        _paymentTerms = paymentResponse.data ?? const <PartyPaymentTermModel>[];
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _detailFormError = error.toString();
      });
    }
  }

  void _resetPartyForm() {
    _selectedParty = null;
    _setPartyCode('', autoGenerated: true);
    _partyNameController.clear();
    _displayNameController.clear();
    _partyTypeId = null;
    _isCompany = false;
    _websiteController.clear();
    _panController.clear();
    _aadhaarController.clear();
    _currencyController.text = 'INR';
    _openingBalanceController.clear();
    _openingBalanceType = 'debit';
    _remarksController.clear();
    _partyActive = true;
    _partyFormError = null;
    setState(() {});
  }

  void _clearDetailTabs() {
    _addresses = const <PartyAddressModel>[];
    _selectedAddress = null;
    _contacts = const <PartyContactModel>[];
    _selectedContact = null;
    _gstDetails = const <PartyGstDetailModel>[];
    _selectedGstDetail = null;
    _bankAccounts = const <PartyBankAccountModel>[];
    _selectedBankAccount = null;
    _creditLimits = const <PartyCreditLimitModel>[];
    _selectedCreditLimit = null;
    _paymentTerms = const <PartyPaymentTermModel>[];
    _selectedPaymentTerm = null;
    _detailFormError = null;
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

    setState(() {
      _partySaving = true;
      _partyFormError = null;
    });

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
        setState(() {
          _partyFormError = response.message;
        });
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadPage(selectId: saved.id);
    } catch (error) {
      setState(() {
        _partyFormError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _partySaving = false;
        });
      }
    }
  }

  void _resetAddressForm() {
    _selectedAddress = null;
    _addressType = 'billing';
    _addressLine1Controller.clear();
    _addressLine2Controller.clear();
    _addressAreaController.clear();
    _addressCityController.clear();
    _addressDistrictController.clear();
    _addressStateCodeController.clear();
    _addressStateNameController.clear();
    _addressCountryCodeController.clear();
    _addressPostalCodeController.clear();
    _addressDefault = false;
    _addressActive = true;
  }

  void _selectAddress(PartyAddressModel address) {
    _selectedAddress = address;
    _addressType = address.addressType ?? 'billing';
    _addressLine1Controller.text = address.addressLine1 ?? '';
    _addressLine2Controller.text = address.addressLine2 ?? '';
    _addressAreaController.text = address.area ?? '';
    _addressCityController.text = address.city ?? '';
    _addressDistrictController.text = address.district ?? '';
    _addressStateCodeController.text = address.stateCode ?? '';
    _addressStateNameController.text = address.stateName ?? '';
    _addressCountryCodeController.text = address.countryCode ?? '';
    _addressPostalCodeController.text = address.postalCode ?? '';
    _addressDefault = address.isDefault;
    _addressActive = address.isActive;
    setState(() {});
  }

  Future<void> _saveAddress() async {
    final partyId = _selectedParty?.id;
    if (partyId == null || !_addressFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _detailSaving = true;
      _detailFormError = null;
    });

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
      _resetAddressForm();
      setState(() {});
    } catch (error) {
      setState(() {
        _detailFormError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _detailSaving = false;
        });
      }
    }
  }

  void _resetContactForm() {
    _selectedContact = null;
    _contactNameController.clear();
    _contactDesignationController.clear();
    _contactMobileController.clear();
    _contactPhoneController.clear();
    _contactEmailController.clear();
    _contactPrimary = false;
    _contactActive = true;
  }

  void _selectContact(PartyContactModel contact) {
    _selectedContact = contact;
    _contactNameController.text = contact.contactName ?? '';
    _contactDesignationController.text = contact.designation ?? '';
    _contactMobileController.text = contact.mobile ?? '';
    _contactPhoneController.text = contact.phone ?? '';
    _contactEmailController.text = contact.email ?? '';
    _contactPrimary = contact.isPrimary;
    _contactActive = contact.isActive;
    setState(() {});
  }

  Future<void> _saveContact() async {
    final partyId = _selectedParty?.id;
    if (partyId == null || !_contactFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _detailSaving = true;
      _detailFormError = null;
    });

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
      _resetContactForm();
      setState(() {});
    } catch (error) {
      setState(() {
        _detailFormError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _detailSaving = false;
        });
      }
    }
  }

  void _resetGstForm() {
    _selectedGstDetail = null;
    _gstinDetailController.clear();
    _registrationType = 'regular';
    _gstLegalNameController.clear();
    _gstTradeNameController.clear();
    _gstStateCodeController.clear();
    _gstStateNameController.clear();
    _gstAddress1Controller.clear();
    _gstAddress2Controller.clear();
    _gstCityController.clear();
    _gstDistrictController.clear();
    _gstPostalCodeController.clear();
    _gstDefault = false;
    _gstActive = true;
  }

  void _selectGstDetail(PartyGstDetailModel record) {
    final data = record.data;
    _selectedGstDetail = record;
    _gstinDetailController.text = stringValue(data, 'gstin');
    _registrationType = stringValue(data, 'registration_type', 'regular');
    _gstLegalNameController.text = stringValue(data, 'legal_name');
    _gstTradeNameController.text = stringValue(data, 'trade_name');
    _gstStateCodeController.text = stringValue(data, 'state_code');
    _gstStateNameController.text = stringValue(data, 'state_name');
    _gstAddress1Controller.text = stringValue(data, 'address_line1');
    _gstAddress2Controller.text = stringValue(data, 'address_line2');
    _gstCityController.text = stringValue(data, 'city');
    _gstDistrictController.text = stringValue(data, 'district');
    _gstPostalCodeController.text = stringValue(data, 'postal_code');
    _gstDefault = boolValue(data, 'is_default');
    _gstActive = boolValue(data, 'is_active', fallback: true);
    setState(() {});
  }

  Future<void> _saveGstDetail() async {
    final partyId = _selectedParty?.id;
    if (partyId == null || !_gstFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _detailSaving = true;
      _detailFormError = null;
    });

    try {
      final body = PartyGstDetailModel({
        if (intValue(_selectedGstDetail?.data ?? const {}, 'id') != null)
          'id': intValue(_selectedGstDetail!.data, 'id'),
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

      final id = intValue(_selectedGstDetail?.data ?? const {}, 'id');
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
      _resetGstForm();
      setState(() {});
    } catch (error) {
      setState(() {
        _detailFormError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _detailSaving = false;
        });
      }
    }
  }

  void _resetBankForm() {
    _selectedBankAccount = null;
    _bankAccountHolderController.clear();
    _bankNameController.clear();
    _bankBranchController.clear();
    _bankAccountNumberController.clear();
    _bankIfscController.clear();
    _bankSwiftController.clear();
    _bankIbanController.clear();
    _bankUpiController.clear();
    _bankDefault = false;
    _bankActive = true;
  }

  void _selectBankAccount(PartyBankAccountModel record) {
    final data = record.data;
    _selectedBankAccount = record;
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
    _bankDefault = boolValue(data, 'is_default');
    _bankActive = boolValue(data, 'is_active', fallback: true);
    setState(() {});
  }

  Future<void> _saveBankAccount() async {
    final partyId = _selectedParty?.id;
    if (partyId == null || !_bankFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _detailSaving = true;
      _detailFormError = null;
    });

    try {
      final body = PartyBankAccountModel({
        if (intValue(_selectedBankAccount?.data ?? const {}, 'id') != null)
          'id': intValue(_selectedBankAccount!.data, 'id'),
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

      final id = intValue(_selectedBankAccount?.data ?? const {}, 'id');
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
      _resetBankForm();
      setState(() {});
    } catch (error) {
      setState(() {
        _detailFormError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _detailSaving = false;
        });
      }
    }
  }

  void _resetCreditForm() {
    _selectedCreditLimit = null;
    _creditLimitController.clear();
    _creditDaysController.clear();
    _creditFromController.clear();
    _creditToController.clear();
    _creditActive = true;
  }

  void _selectCreditLimit(PartyCreditLimitModel record) {
    final data = record.data;
    _selectedCreditLimit = record;
    _creditLimitController.text = stringValue(data, 'credit_limit');
    _creditDaysController.text = stringValue(data, 'credit_days');
    _creditFromController.text = stringValue(data, 'effective_from');
    _creditToController.text = stringValue(data, 'effective_to');
    _creditActive = boolValue(data, 'is_active', fallback: true);
    setState(() {});
  }

  Future<void> _saveCreditLimit() async {
    final partyId = _selectedParty?.id;
    if (partyId == null || !_creditFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _detailSaving = true;
      _detailFormError = null;
    });

    try {
      final body = PartyCreditLimitModel({
        if (intValue(_selectedCreditLimit?.data ?? const {}, 'id') != null)
          'id': intValue(_selectedCreditLimit!.data, 'id'),
        'credit_limit': double.tryParse(_creditLimitController.text.trim()),
        'credit_days': int.tryParse(_creditDaysController.text.trim()),
        'effective_from': nullIfEmpty(_creditFromController.text),
        'effective_to': nullIfEmpty(_creditToController.text),
        'is_active': _creditActive,
      });

      final id = intValue(_selectedCreditLimit?.data ?? const {}, 'id');
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
      _resetCreditForm();
      setState(() {});
    } catch (error) {
      setState(() {
        _detailFormError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _detailSaving = false;
        });
      }
    }
  }

  void _resetPaymentTermForm() {
    _selectedPaymentTerm = null;
    _paymentTermNameController.clear();
    _paymentDaysController.clear();
    _paymentRemarksController.clear();
    _dueBasis = 'invoice_date';
    _paymentDefault = false;
    _paymentActive = true;
  }

  void _selectPaymentTerm(PartyPaymentTermModel record) {
    final data = record.data;
    _selectedPaymentTerm = record;
    _paymentTermNameController.text = stringValue(data, 'term_name');
    _paymentDaysController.text = stringValue(data, 'days');
    _paymentRemarksController.text = stringValue(data, 'remarks');
    _dueBasis = stringValue(data, 'due_basis', 'invoice_date');
    _paymentDefault = boolValue(data, 'is_default');
    _paymentActive = boolValue(data, 'is_active', fallback: true);
    setState(() {});
  }

  Future<void> _savePaymentTerm() async {
    final partyId = _selectedParty?.id;
    if (partyId == null || !_paymentTermFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _detailSaving = true;
      _detailFormError = null;
    });

    try {
      final body = PartyPaymentTermModel({
        if (intValue(_selectedPaymentTerm?.data ?? const {}, 'id') != null)
          'id': intValue(_selectedPaymentTerm!.data, 'id'),
        'term_name': _paymentTermNameController.text.trim(),
        'days': int.tryParse(_paymentDaysController.text.trim()),
        'due_basis': _dueBasis,
        'remarks': nullIfEmpty(_paymentRemarksController.text),
        'is_default': _paymentDefault,
        'is_active': _paymentActive,
      });

      final id = intValue(_selectedPaymentTerm?.data ?? const {}, 'id');
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
      _resetPaymentTermForm();
      setState(() {});
    } catch (error) {
      setState(() {
        _detailFormError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _detailSaving = false;
        });
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
              initialValue: _partyTypeFilterId,
              onChanged: (value) {
                setState(() {
                  _partyTypeFilterId = value ?? 0;
                  _filteredParties = _computeFilteredParties(_parties);
                });
              },
            ),
            const SizedBox(height: 12),
            AppDropdownField<String>.fromMapped(
              labelText: 'Sort',
              mappedItems: _sortItems,
              initialValue: _partySort,
              onChanged: (value) {
                setState(() {
                  _partySort = value ?? 'name_asc';
                  _filteredParties = _computeFilteredParties(_parties);
                });
              },
            ),
            const SizedBox(height: 16),
            if (_filteredParties.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('No parties found.'),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredParties.length,
                separatorBuilder: (_, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final party = _filteredParties[index];
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
      editor: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedBuilder(
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
                      Tab(text: 'Addresses'),
                      Tab(text: 'Contacts'),
                      Tab(text: 'GST Details'),
                      Tab(text: 'Bank Accounts'),
                      Tab(text: 'Credit Limits'),
                      Tab(text: 'Payment Terms'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  IndexedStack(
                    index: _tabController.index,
                    children: [
                      _buildPrimaryTab(context),
                      _buildAddressesTab(context),
                      _buildContactsTab(context),
                      _buildGstDetailsTab(context),
                      _buildBankAccountsTab(context),
                      _buildCreditLimitsTab(context),
                      _buildPaymentTermsTab(context),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryTab(BuildContext context) {
    final supportsCompanyFlag = _supportsCompanyFlag(_partyTypeId);
    final partyTypeItems = _partyTypes
        .map(
          (type) => AppDropdownItem<int>(
            value: intValue(type.data, 'id') ?? 0,
            label: stringValue(type.data, 'name'),
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
                    setState(() => _openingBalanceType = value ?? 'debit'),
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
                    onChanged: (value) => setState(() => _isCompany = value),
                  ),
                ),
              SizedBox(
                child: AppSwitchTile(
                  label: 'Active',
                  value: _partyActive,
                  onChanged: (value) => setState(() => _partyActive = value),
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
        item.data,
        'gstin',
        stringValue(item.data, 'registration_type', 'GST Detail'),
      ),
      itemSubtitle: (item) => [
        stringValue(item.data, 'registration_type'),
        stringValue(item.data, 'state_name'),
      ].where((value) => value.isNotEmpty).join(' • '),
      onSelect: (item) => _selectGstDetail(item),
      form: Form(key: _gstFormKey, child: _buildGstForm(context)),
    );
  }

  Widget _buildBankAccountsTab(BuildContext context) {
    return _buildDetailTab<PartyBankAccountModel>(
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
          stringValue(item.data, 'account_holder_name', 'Bank Account'),
      itemSubtitle: (item) => [
        stringValue(item.data, 'bank_name'),
        stringValue(item.data, 'account_number'),
      ].where((value) => value.isNotEmpty).join(' • '),
      onSelect: (item) => _selectBankAccount(item),
      form: Form(key: _bankFormKey, child: _buildBankForm(context)),
    );
  }

  Widget _buildCreditLimitsTab(BuildContext context) {
    return _buildDetailTab<PartyCreditLimitModel>(
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
          stringValue(item.data, 'credit_limit', 'Credit Limit'),
      itemSubtitle: (item) => [
        stringValue(item.data, 'credit_days'),
        stringValue(item.data, 'effective_from'),
        stringValue(item.data, 'effective_to'),
      ].where((value) => value.isNotEmpty).join(' • '),
      onSelect: (item) => _selectCreditLimit(item),
      form: Form(key: _creditFormKey, child: _buildCreditForm(context)),
    );
  }

  Widget _buildPaymentTermsTab(BuildContext context) {
    return _buildDetailTab<PartyPaymentTermModel>(
      title: 'Payment Terms',
      subtitle:
          'Maintain invoice due basis, days, and default payment term logic for the party.',
      emptyTitle: 'Select a party first',
      emptyMessage:
          'Choose a party from the left to manage payment terms for that party.',
      onNew: _resetPaymentTermForm,
      list: _paymentTerms,
      selected: _selectedPaymentTerm,
      itemTitle: (item) => stringValue(item.data, 'term_name', 'Payment Term'),
      itemSubtitle: (item) => [
        stringValue(item.data, 'due_basis'),
        stringValue(item.data, 'days'),
      ].where((value) => value.isNotEmpty).join(' • '),
      onSelect: (item) => _selectPaymentTerm(item),
      form: Form(
        key: _paymentTermFormKey,
        child: _buildPaymentTermForm(context),
      ),
    );
  }

  Widget _buildDetailTab<T>({
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
              onPressed: onNew,
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
        if (list.isEmpty)
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
              return SettingsListTile(
                title: itemTitle(item),
                subtitle: itemSubtitle(item),
                selected: identical(item, selected),
                onTap: () => onSelect(item),
              );
            },
          ),
        const SizedBox(height: 20),
        form,
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
                  setState(() => _addressType = value ?? 'billing'),
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
                onChanged: (value) => setState(() => _addressDefault = value),
              ),
            ),
            SizedBox(
              child: AppSwitchTile(
                label: 'Active',
                value: _addressActive,
                onChanged: (value) => setState(() => _addressActive = value),
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
                onChanged: (value) => setState(() => _contactPrimary = value),
              ),
            ),
            SizedBox(
              child: AppSwitchTile(
                label: 'Active',
                value: _contactActive,
                onChanged: (value) => setState(() => _contactActive = value),
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
                  setState(() => _registrationType = value ?? 'regular'),
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
                onChanged: (value) => setState(() => _gstDefault = value),
              ),
            ),
            SizedBox(
              child: AppSwitchTile(
                label: 'Active',
                value: _gstActive,
                onChanged: (value) => setState(() => _gstActive = value),
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
                onChanged: (value) => setState(() => _bankDefault = value),
              ),
            ),
            SizedBox(
              child: AppSwitchTile(
                label: 'Active',
                value: _bankActive,
                onChanged: (value) => setState(() => _bankActive = value),
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
            onChanged: (value) => setState(() => _creditActive = value),
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
                  setState(() => _dueBasis = value ?? 'invoice_date'),
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
                onChanged: (value) => setState(() => _paymentDefault = value),
              ),
            ),
            SizedBox(
              child: AppSwitchTile(
                label: 'Active',
                value: _paymentActive,
                onChanged: (value) => setState(() => _paymentActive = value),
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
