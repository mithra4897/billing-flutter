import '../../screen.dart';

class PartyManagementController extends GetxController {
  PartyManagementController();

  int activeTabIndex = 0;
  int partyTypeFilterId = 0;
  String partySort = 'name_asc';
  String searchQuery = '';
  final Set<String> openDetailDrafts = <String>{};
  bool isCompany = false;
  String openingBalanceType = 'debit';
  bool partyActive = true;
  String addressType = 'billing';
  bool addressDefault = false;
  bool addressActive = true;
  bool contactPrimary = false;
  bool contactActive = true;
  String registrationType = 'regular';
  bool gstDefault = false;
  bool gstActive = true;
  bool bankDefault = false;
  bool bankActive = true;
  bool creditActive = true;
  String dueBasis = 'invoice_date';
  bool paymentDefault = false;
  bool paymentActive = true;
  bool canViewPartyAccounts = false;
  bool partyAccountsAccessResolved = false;
  bool initialLoading = true;
  bool partySaving = false;
  bool detailSaving = false;
  String? pageError;
  String? partyFormError;
  String? detailFormError;
  List<PartyTypeModel> partyTypes = const <PartyTypeModel>[];
  List<DocumentSeriesModel> documentSeries = const <DocumentSeriesModel>[];
  List<PartyModel> parties = const <PartyModel>[];
  PartyModel? selectedParty;
  int? partyTypeId;
  List<PartyAddressModel> addresses = const <PartyAddressModel>[];
  PartyAddressModel? selectedAddress;
  List<PartyContactModel> contacts = const <PartyContactModel>[];
  PartyContactModel? selectedContact;
  List<PartyGstDetailModel> gstDetails = const <PartyGstDetailModel>[];
  PartyGstDetailModel? selectedGstDetail;
  List<PartyBankAccountModel> bankAccounts = const <PartyBankAccountModel>[];
  PartyBankAccountModel? selectedBankAccount;
  List<PartyCreditLimitModel> creditLimits = const <PartyCreditLimitModel>[];
  PartyCreditLimitModel? selectedCreditLimit;
  List<PartyPaymentTermModel> paymentTerms = const <PartyPaymentTermModel>[];
  PartyPaymentTermModel? selectedPaymentTerm;

  void setActiveTabIndex(int index) {
    activeTabIndex = index;
    update();
  }

  void setPartyTypeFilterId(int value) {
    partyTypeFilterId = value;
    update();
  }

  void setPartySort(String value) {
    partySort = value;
    update();
  }

  void setSearchQuery(String value) {
    searchQuery = value;
    update();
  }

  bool isDetailDraftOpen(String sectionKey) {
    return openDetailDrafts.contains(sectionKey);
  }

  void openDetailDraft(String sectionKey) {
    openDetailDrafts
      ..remove(sectionKey)
      ..add(sectionKey);
    update();
  }

  void closeDetailDraft(String sectionKey) {
    openDetailDrafts.remove(sectionKey);
    update();
  }

  void clearAllDetailDrafts() {
    openDetailDrafts.clear();
    update();
  }

  void setIsCompany(bool value) {
    isCompany = value;
    update();
  }

  void setOpeningBalanceType(String value) {
    openingBalanceType = value;
    update();
  }

  void setPartyActive(bool value) {
    partyActive = value;
    update();
  }

  void setAddressType(String value) {
    addressType = value;
    update();
  }

  void setAddressDefault(bool value) {
    addressDefault = value;
    update();
  }

  void setAddressActive(bool value) {
    addressActive = value;
    update();
  }

  void setContactPrimary(bool value) {
    contactPrimary = value;
    update();
  }

  void setContactActive(bool value) {
    contactActive = value;
    update();
  }

  void setRegistrationType(String value) {
    registrationType = value;
    update();
  }

  void setGstDefault(bool value) {
    gstDefault = value;
    update();
  }

  void setGstActive(bool value) {
    gstActive = value;
    update();
  }

  void setBankDefault(bool value) {
    bankDefault = value;
    update();
  }

  void setBankActive(bool value) {
    bankActive = value;
    update();
  }

  void setCreditActive(bool value) {
    creditActive = value;
    update();
  }

  void setDueBasis(String value) {
    dueBasis = value;
    update();
  }

  void setPaymentDefault(bool value) {
    paymentDefault = value;
    update();
  }

  void setPaymentActive(bool value) {
    paymentActive = value;
    update();
  }

  void setPartyAccountsAccess(bool value) {
    canViewPartyAccounts = value;
    update();
  }

  void setPartyAccountsAccessResolved(bool value) {
    partyAccountsAccessResolved = value;
    update();
  }

  void beginPageLoad({required bool showFullLoading}) {
    initialLoading = showFullLoading;
    pageError = null;
    update();
  }

  void completePageLoad({
    required List<PartyTypeModel> partyTypes,
    required List<DocumentSeriesModel> documentSeries,
    required List<PartyModel> parties,
  }) {
    syncPageState(
      initialLoading: false,
      clearPageError: true,
      partyTypes: partyTypes,
      documentSeries: documentSeries,
      parties: parties,
    );
  }

  void failPageLoad(String message) {
    syncPageState(initialLoading: false, pageError: message);
  }

  void applyPartyTypeChange(
    int? value, {
    required bool supportsCompanyFlag,
    required bool supportsGst,
  }) {
    partyTypeId = value;
    if (!supportsCompanyFlag) {
      isCompany = false;
    }
    if (!supportsGst) {
      gstDetails = const <PartyGstDetailModel>[];
      selectedGstDetail = null;
      registrationType = 'regular';
      gstDefault = false;
      gstActive = true;
    }
    update();
  }

  void selectParty(PartyModel party) {
    syncPageState(
      selectedParty: party,
      partyTypeId: party.partyTypeId,
      clearPartyFormError: true,
    );
    isCompany = party.isCompany;
    openingBalanceType = party.openingBalanceType ?? 'debit';
    partyActive = party.isActive;
    update();
  }

  void resetPartyDraft() {
    syncPageState(
      clearSelectedParty: true,
      clearPartyTypeId: true,
      clearPartyFormError: true,
    );
    isCompany = false;
    openingBalanceType = 'debit';
    partyActive = true;
    update();
  }

  void beginPartySave() {
    syncPageState(partySaving: true, clearPartyFormError: true);
  }

  void failPartySave(String message) {
    syncPageState(partyFormError: message);
  }

  void finishPartySave() {
    syncPageState(partySaving: false);
  }

  void setPartyChildren({
    required List<PartyAddressModel> addresses,
    required List<PartyContactModel> contacts,
    required List<PartyGstDetailModel> gstDetails,
    required List<PartyBankAccountModel> bankAccounts,
    required List<PartyCreditLimitModel> creditLimits,
    required List<PartyPaymentTermModel> paymentTerms,
  }) {
    syncPageState(
      clearDetailFormError: true,
      addresses: addresses,
      contacts: contacts,
      gstDetails: gstDetails,
      bankAccounts: bankAccounts,
      creditLimits: creditLimits,
      paymentTerms: paymentTerms,
    );
  }

  void failDetailLoad(String message) {
    syncPageState(detailFormError: message);
  }

  void clearDetailTabsState() {
    syncPageState(
      addresses: const <PartyAddressModel>[],
      clearSelectedAddress: true,
      contacts: const <PartyContactModel>[],
      clearSelectedContact: true,
      gstDetails: const <PartyGstDetailModel>[],
      clearSelectedGstDetail: true,
      bankAccounts: const <PartyBankAccountModel>[],
      clearSelectedBankAccount: true,
      creditLimits: const <PartyCreditLimitModel>[],
      clearSelectedCreditLimit: true,
      paymentTerms: const <PartyPaymentTermModel>[],
      clearSelectedPaymentTerm: true,
      clearDetailFormError: true,
    );
    clearAllDetailDrafts();
  }

  void beginDetailSave() {
    syncPageState(detailSaving: true, clearDetailFormError: true);
  }

  void failDetailSave(String message) {
    syncPageState(detailFormError: message);
  }

  void finishDetailSave() {
    syncPageState(detailSaving: false);
  }

  void resetAddressDraft() {
    syncPageState(clearSelectedAddress: true);
    addressType = 'billing';
    addressDefault = false;
    addressActive = true;
    update();
  }

  void selectAddress(PartyAddressModel address) {
    syncPageState(selectedAddress: address);
    addressType = address.addressType ?? 'billing';
    addressDefault = address.isDefault;
    addressActive = address.isActive;
    update();
  }

  void resetContactDraft() {
    syncPageState(clearSelectedContact: true);
    contactPrimary = false;
    contactActive = true;
    update();
  }

  void selectContact(PartyContactModel contact) {
    syncPageState(selectedContact: contact);
    contactPrimary = contact.isPrimary;
    contactActive = contact.isActive;
    update();
  }

  void resetGstDraft() {
    syncPageState(clearSelectedGstDetail: true);
    registrationType = 'regular';
    gstDefault = false;
    gstActive = true;
    update();
  }

  void selectGstDetail(PartyGstDetailModel record, Map<String, dynamic> data) {
    syncPageState(selectedGstDetail: record);
    registrationType = stringValue(data, 'registration_type', 'regular');
    gstDefault = boolValue(data, 'is_default');
    gstActive = boolValue(data, 'is_active', fallback: true);
    update();
  }

  void resetBankDraft() {
    syncPageState(clearSelectedBankAccount: true);
    bankDefault = false;
    bankActive = true;
    update();
  }

  void selectBankAccount(
    PartyBankAccountModel record,
    Map<String, dynamic> data,
  ) {
    syncPageState(selectedBankAccount: record);
    bankDefault = boolValue(data, 'is_default');
    bankActive = boolValue(data, 'is_active', fallback: true);
    update();
  }

  void resetCreditDraft() {
    syncPageState(clearSelectedCreditLimit: true);
    creditActive = true;
    update();
  }

  void selectCreditLimit(
    PartyCreditLimitModel record,
    Map<String, dynamic> data,
  ) {
    syncPageState(selectedCreditLimit: record);
    creditActive = boolValue(data, 'is_active', fallback: true);
    update();
  }

  void resetPaymentTermDraft() {
    syncPageState(clearSelectedPaymentTerm: true);
    dueBasis = 'invoice_date';
    paymentDefault = false;
    paymentActive = true;
    update();
  }

  void selectPaymentTerm(
    PartyPaymentTermModel record,
    Map<String, dynamic> data,
  ) {
    syncPageState(selectedPaymentTerm: record);
    dueBasis = stringValue(data, 'due_basis', 'invoice_date');
    paymentDefault = boolValue(data, 'is_default');
    paymentActive = boolValue(data, 'is_active', fallback: true);
    update();
  }

  void syncPageState({
    bool? initialLoading,
    bool? partySaving,
    bool? detailSaving,
    String? pageError,
    bool clearPageError = false,
    String? partyFormError,
    bool clearPartyFormError = false,
    String? detailFormError,
    bool clearDetailFormError = false,
    List<PartyTypeModel>? partyTypes,
    List<DocumentSeriesModel>? documentSeries,
    List<PartyModel>? parties,
    PartyModel? selectedParty,
    bool clearSelectedParty = false,
    int? partyTypeId,
    bool clearPartyTypeId = false,
    List<PartyAddressModel>? addresses,
    PartyAddressModel? selectedAddress,
    bool clearSelectedAddress = false,
    List<PartyContactModel>? contacts,
    PartyContactModel? selectedContact,
    bool clearSelectedContact = false,
    List<PartyGstDetailModel>? gstDetails,
    PartyGstDetailModel? selectedGstDetail,
    bool clearSelectedGstDetail = false,
    List<PartyBankAccountModel>? bankAccounts,
    PartyBankAccountModel? selectedBankAccount,
    bool clearSelectedBankAccount = false,
    List<PartyCreditLimitModel>? creditLimits,
    PartyCreditLimitModel? selectedCreditLimit,
    bool clearSelectedCreditLimit = false,
    List<PartyPaymentTermModel>? paymentTerms,
    PartyPaymentTermModel? selectedPaymentTerm,
    bool clearSelectedPaymentTerm = false,
  }) {
    if (initialLoading != null) {
      this.initialLoading = initialLoading;
    }
    if (partySaving != null) {
      this.partySaving = partySaving;
    }
    if (detailSaving != null) {
      this.detailSaving = detailSaving;
    }
    if (clearPageError) {
      this.pageError = null;
    } else if (pageError != null) {
      this.pageError = pageError;
    }
    if (clearPartyFormError) {
      this.partyFormError = null;
    } else if (partyFormError != null) {
      this.partyFormError = partyFormError;
    }
    if (clearDetailFormError) {
      this.detailFormError = null;
    } else if (detailFormError != null) {
      this.detailFormError = detailFormError;
    }
    if (partyTypes != null) {
      this.partyTypes = partyTypes;
    }
    if (documentSeries != null) {
      this.documentSeries = documentSeries;
    }
    if (parties != null) {
      this.parties = parties;
    }
    if (clearSelectedParty) {
      this.selectedParty = null;
    } else if (selectedParty != null) {
      this.selectedParty = selectedParty;
    }
    if (clearPartyTypeId) {
      this.partyTypeId = null;
    } else if (partyTypeId != null) {
      this.partyTypeId = partyTypeId;
    }
    if (addresses != null) {
      this.addresses = addresses;
    }
    if (clearSelectedAddress) {
      this.selectedAddress = null;
    } else if (selectedAddress != null) {
      this.selectedAddress = selectedAddress;
    }
    if (contacts != null) {
      this.contacts = contacts;
    }
    if (clearSelectedContact) {
      this.selectedContact = null;
    } else if (selectedContact != null) {
      this.selectedContact = selectedContact;
    }
    if (gstDetails != null) {
      this.gstDetails = gstDetails;
    }
    if (clearSelectedGstDetail) {
      this.selectedGstDetail = null;
    } else if (selectedGstDetail != null) {
      this.selectedGstDetail = selectedGstDetail;
    }
    if (bankAccounts != null) {
      this.bankAccounts = bankAccounts;
    }
    if (clearSelectedBankAccount) {
      this.selectedBankAccount = null;
    } else if (selectedBankAccount != null) {
      this.selectedBankAccount = selectedBankAccount;
    }
    if (creditLimits != null) {
      this.creditLimits = creditLimits;
    }
    if (clearSelectedCreditLimit) {
      this.selectedCreditLimit = null;
    } else if (selectedCreditLimit != null) {
      this.selectedCreditLimit = selectedCreditLimit;
    }
    if (paymentTerms != null) {
      this.paymentTerms = paymentTerms;
    }
    if (clearSelectedPaymentTerm) {
      this.selectedPaymentTerm = null;
    } else if (selectedPaymentTerm != null) {
      this.selectedPaymentTerm = selectedPaymentTerm;
    }
    update();
  }
}
