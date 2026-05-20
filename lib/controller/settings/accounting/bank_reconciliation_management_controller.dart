import '../../../screen.dart';

class BankReconciliationManagementController extends GetxController {
  static const List<AppDropdownItem<String>> statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'pending', label: 'Pending'),
        AppDropdownItem(value: 'cleared', label: 'Cleared'),
        AppDropdownItem(value: 'bounced', label: 'Bounced'),
        AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
      ];

  BankReconciliationManagementController();

  final AccountsService _accountsService = AccountsService();

  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController bankDateController = TextEditingController();
  final TextEditingController clearedDateController = TextEditingController();
  final TextEditingController bankReferenceController =
      TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  List<BankReconciliationModel> records = const <BankReconciliationModel>[];
  List<BankReconciliationModel> filteredRecords =
      const <BankReconciliationModel>[];
  List<AccountModel> bankAccounts = const <AccountModel>[];
  List<VoucherModel> vouchers = const <VoucherModel>[];
  List<VoucherLineModel> voucherLineOptions = const <VoucherLineModel>[];
  BankReconciliationModel? selectedRecord;
  int? accountId;
  int? voucherId;
  int? voucherLineId;
  String status = 'pending';

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_applySearch);
    loadPage();
  }

  @override
  void onClose() {
    pageScrollController.dispose();
    workspaceController.dispose();
    searchController
      ..removeListener(_applySearch)
      ..dispose();
    bankDateController.dispose();
    clearedDateController.dispose();
    bankReferenceController.dispose();
    remarksController.dispose();
    super.onClose();
  }

  Future<void> loadPage({int? selectId}) async {
    initialLoading = records.isEmpty;
    pageError = null;
    update();

    try {
      final responses = await Future.wait<dynamic>([
        _accountsService.bankReconciliation(),
        _accountsService.accountsAll(
          filters: const {
            'account_type': 'bank',
            'allow_reconciliation': 1,
            'is_active': 1,
            'sort_by': 'account_name',
          },
        ),
        _accountsService.vouchersAll(
          filters: const {
            'posting_status': 'posted',
            'sort_by': 'voucher_date',
          },
        ),
      ]);

      final nextRecords =
          (responses[0] as ApiResponse<List<BankReconciliationModel>>).data ??
          const <BankReconciliationModel>[];
      final nextBankAccounts =
          (responses[1] as ApiResponse<List<AccountModel>>).data ??
          const <AccountModel>[];
      final nextVouchers =
          (responses[2] as ApiResponse<List<VoucherModel>>).data ??
          const <VoucherModel>[];

      records = nextRecords;
      filteredRecords = _filterRecords(nextRecords, searchController.text);
      bankAccounts = nextBankAccounts.where((item) => item.isActive).toList();
      vouchers = nextVouchers;
      initialLoading = false;

      final selected = selectId != null
          ? nextRecords.cast<BankReconciliationModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (selectedRecord == null
                ? (nextRecords.isNotEmpty ? nextRecords.first : null)
                : nextRecords.cast<BankReconciliationModel?>().firstWhere(
                    (item) => item?.id == selectedRecord?.id,
                    orElse: () =>
                        nextRecords.isNotEmpty ? nextRecords.first : null,
                  ));

      if (selected != null) {
        await selectRecord(selected, notify: false);
      } else {
        resetForm(notify: false);
      }
    } catch (error) {
      initialLoading = false;
      pageError = error.toString();
    }

    update();
  }

  List<BankReconciliationModel> _filterRecords(
    List<BankReconciliationModel> items,
    String query,
  ) {
    return filterMasterList(items, query, (item) {
      return [
        item.accountName ?? '',
        item.bankReferenceNo ?? '',
        item.voucherNo ?? '',
        item.reconciliationStatus ?? '',
      ];
    });
  }

  void _applySearch() {
    filteredRecords = _filterRecords(records, searchController.text);
    update();
  }

  Future<void> loadVoucherLinesForSelection({bool notify = true}) async {
    if (voucherId == null || accountId == null) {
      voucherLineOptions = const <VoucherLineModel>[];
      if (notify) {
        update();
      }
      return;
    }

    final response = await _accountsService.voucher(voucherId!);
    final voucher = response.data;
    final usedLineIds = records
        .where((item) => item.id != selectedRecord?.id)
        .map((item) => item.voucherLineId)
        .whereType<int>()
        .toSet();

    voucherLineOptions = (voucher?.lines ?? const <VoucherLineModel>[])
        .where(
          (item) => item.accountId == accountId && !usedLineIds.contains(item.id),
        )
        .toList(growable: false);

    if (!voucherLineOptions.any((item) => item.id == voucherLineId)) {
      voucherLineId = null;
    }

    if (notify) {
      update();
    }
  }

  Future<void> selectRecord(
    BankReconciliationModel item, {
    bool notify = true,
  }) async {
    selectedRecord = item;
    accountId = item.accountId;
    voucherId = item.voucherId;
    voucherLineId = item.voucherLineId;
    status = item.reconciliationStatus ?? 'pending';
    bankDateController.text =
        item.bankDate?.split('T').first.split(' ').first ?? '';
    clearedDateController.text =
        item.clearedDate?.split('T').first.split(' ').first ?? '';
    bankReferenceController.text = item.bankReferenceNo ?? '';
    remarksController.text = item.remarks ?? '';
    formError = null;
    voucherLineOptions = const <VoucherLineModel>[];

    await loadVoucherLinesForSelection(notify: false);

    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selectedRecord = null;
    accountId = bankAccounts.isNotEmpty ? bankAccounts.first.id : null;
    voucherId = null;
    voucherLineId = null;
    status = 'pending';
    bankDateController.clear();
    clearedDateController.clear();
    bankReferenceController.clear();
    remarksController.clear();
    voucherLineOptions = const <VoucherLineModel>[];
    formError = null;
    if (notify) {
      update();
    }
  }

  Future<void> startNew({required bool isDesktop}) async {
    resetForm();
    if (!isDesktop) {
      workspaceController.openEditor();
    }
  }

  Future<void> setAccountId(int? value) async {
    accountId = value;
    voucherLineId = null;
    await loadVoucherLinesForSelection();
  }

  Future<void> setVoucherId(int? value) async {
    voucherId = value;
    voucherLineId = null;
    await loadVoucherLinesForSelection();
  }

  void setVoucherLineId(int? value) {
    voucherLineId = value;
    update();
  }

  void setStatus(String? value) {
    status = value ?? 'pending';
    update();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    saving = true;
    formError = null;
    update();

    try {
      final model = BankReconciliationModel(
        id: selectedRecord?.id,
        accountId: accountId,
        voucherLineId: voucherLineId,
        bankDate: nullIfEmpty(bankDateController.text),
        clearedDate: nullIfEmpty(clearedDateController.text),
        reconciliationStatus: status,
        bankReferenceNo: nullIfEmpty(bankReferenceController.text),
        remarks: nullIfEmpty(remarksController.text),
      );

      final response = selectedRecord == null
          ? await _accountsService.createBankReconciliation(model)
          : await _accountsService.updateBankReconciliation(
              selectedRecord!.id!,
              model,
            );

      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadPage(selectId: response.data?.id);
    } catch (error) {
      formError = error.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }
}
