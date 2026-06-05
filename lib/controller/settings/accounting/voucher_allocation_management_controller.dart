import '../../../screen.dart';
import 'settings_accounting_module_refresh_controller.dart';

class VoucherAllocationManagementController extends GetxController {
  VoucherAllocationManagementController();

  static const String _refreshSource = 'VoucherAllocationManagementController';

  static const List<AppDropdownItem<String>> allocationTypeItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'adjustment', label: 'Adjustment'),
        AppDropdownItem(value: 'receipt', label: 'Receipt'),
        AppDropdownItem(value: 'payment', label: 'Payment'),
        AppDropdownItem(value: 'advance_setoff', label: 'Advance Setoff'),
      ];

  final AccountsService _accountsService = AccountsService();
  final ScrollController pageScrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController referenceNoController = TextEditingController();
  final TextEditingController referenceDateController = TextEditingController();
  final TextEditingController allocationAmountController =
      TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late final SettingsAccountingModuleRefreshController _moduleRefresh;
  Worker? _refreshWorker;

  bool initialLoading = true;
  bool loading = false;
  bool saving = false;
  String? pageError;
  String? formError;

  List<VoucherModel> vouchers = const <VoucherModel>[];
  VoucherModel? sourceVoucherDetail;
  VoucherModel? againstVoucherDetail;
  int? sourceVoucherId;
  int? sourceLineId;
  int? againstVoucherId;
  int? againstVoucherLineId;
  String allocationType = 'adjustment';

  List<VoucherAllocationModel> rows = const <VoucherAllocationModel>[];
  List<VoucherAllocationModel> filteredRows = const <VoucherAllocationModel>[];
  VoucherAllocationModel? editing;

  bool canCreate = false;
  bool canUpdate = false;
  bool canDelete = false;

  @override
  void onInit() {
    super.onInit();
    _moduleRefresh =
        SettingsAccountingModuleRefreshController.ensureRegistered();
    _refreshWorker = ever<SettingsAccountingModuleRefreshEvent?>(
      _moduleRefresh.lastEvent,
      (event) {
        if (event == null || event.source == _refreshSource) {
          return;
        }
        unawaited(loadPage());
      },
    );
    searchController.addListener(_applySearch);
    loadPage();
  }

  @override
  void onClose() {
    _refreshWorker?.dispose();
    pageScrollController.dispose();
    searchController
      ..removeListener(_applySearch)
      ..dispose();
    referenceNoController.dispose();
    referenceDateController.dispose();
    allocationAmountController.dispose();
    remarksController.dispose();
    super.onClose();
  }

  Future<void> loadPermissions() async {
    final codes = await SessionStorage.getPermissionCodes();
    canCreate = codes.contains('accounts.create');
    canUpdate = codes.contains('accounts.update');
    canDelete = codes.contains('accounts.delete');
  }

  Future<void> loadPage() async {
    initialLoading = vouchers.isEmpty;
    pageError = null;
    update();

    try {
      await loadPermissions();
      final response = await _accountsService.vouchersAll(
        filters: const <String, dynamic>{
          'sort_by': 'voucher_date',
          'sort_order': 'desc',
        },
      );

      vouchers = (response.data ?? const <VoucherModel>[])
          .where((item) => item.id != null)
          .toList(growable: false);

      if (sourceVoucherId != null) {
        await _loadSourceVoucherDetail(
          voucherId: sourceVoucherId,
          preferredLineId: sourceLineId,
        );
      }
      if (againstVoucherId != null) {
        await _loadAgainstVoucherDetail(
          voucherId: againstVoucherId,
          preferredLineId: againstVoucherLineId,
        );
      }

      initialLoading = false;
      _applySearch();
    } catch (errorValue) {
      initialLoading = false;
      pageError = errorValue.toString();
    }

    update();
  }

  Future<void> setSourceVoucherId(int? value) async {
    sourceVoucherId = value;
    sourceLineId = null;
    sourceVoucherDetail = null;
    rows = const <VoucherAllocationModel>[];
    filteredRows = const <VoucherAllocationModel>[];
    startNewAllocation(notify: false);
    update();

    if (value == null) {
      return;
    }

    await _loadSourceVoucherDetail(voucherId: value);
    await fetch();
  }

  Future<void> setSourceLineId(int? value) async {
    sourceLineId = value;
    startNewAllocation(notify: false);
    update();
    await fetch();
  }

  Future<void> setAgainstVoucherId(int? value) async {
    againstVoucherId = value;
    againstVoucherLineId = null;
    againstVoucherDetail = null;
    update();

    if (value == null) {
      return;
    }

    await _loadAgainstVoucherDetail(voucherId: value);
    update();
  }

  void setAgainstVoucherLineId(int? value) {
    againstVoucherLineId = value;
    update();
  }

  void setAllocationType(String? value) {
    allocationType = value ?? 'adjustment';
    update();
  }

  Future<void> fetch() async {
    final voucherLineId = sourceLineId;
    if (voucherLineId == null) {
      rows = const <VoucherAllocationModel>[];
      filteredRows = const <VoucherAllocationModel>[];
      pageError = null;
      update();
      return;
    }

    loading = true;
    pageError = null;
    update();

    try {
      final response = await _accountsService.voucherAllocations(
        filters: <String, dynamic>{'voucher_line_id': voucherLineId},
      );
      rows = response.data ?? const <VoucherAllocationModel>[];
      loading = false;
      _applySearch();
    } catch (errorValue) {
      rows = const <VoucherAllocationModel>[];
      filteredRows = const <VoucherAllocationModel>[];
      loading = false;
      pageError = errorValue.toString();
      update();
    }
  }

  void startNewAllocation({bool notify = true}) {
    editing = null;
    formError = null;
    againstVoucherId = null;
    againstVoucherLineId = null;
    againstVoucherDetail = null;
    allocationType = 'adjustment';
    referenceNoController.clear();
    referenceDateController.clear();
    allocationAmountController.clear();
    remarksController.clear();
    if (notify) {
      update();
    }
  }

  Future<void> editRow(VoucherAllocationModel row) async {
    editing = row;
    formError = null;
    againstVoucherId = row.againstVoucherId;
    againstVoucherLineId = row.againstVoucherLineId;
    allocationType = row.allocationType ?? 'adjustment';
    referenceNoController.text = row.referenceNo ?? '';
    referenceDateController.text = row.referenceDate ?? '';
    allocationAmountController.text = row.allocationAmount?.toString() ?? '';
    remarksController.text = row.remarks ?? '';
    update();

    if (againstVoucherId != null) {
      await _loadAgainstVoucherDetail(
        voucherId: againstVoucherId,
        preferredLineId: againstVoucherLineId,
      );
    }

    update();
  }

  Future<void> saveAllocation() async {
    if (!canCreate && editing == null) {
      return;
    }
    if (!canUpdate && editing != null) {
      return;
    }
    if (sourceLineId == null) {
      formError = 'Select a source voucher line first.';
      update();
      return;
    }
    if (formKey.currentState?.validate() != true) {
      return;
    }

    saving = true;
    formError = null;
    update();

    try {
      final model = VoucherAllocationModel(
        id: editing?.id,
        voucherLineId: sourceLineId,
        againstVoucherId: againstVoucherId,
        againstVoucherLineId: againstVoucherLineId,
        referenceNo: referenceNoController.text.trim(),
        referenceDate: nullIfEmpty(referenceDateController.text),
        allocationAmount: double.tryParse(
          allocationAmountController.text.trim(),
        ),
        allocationType: allocationType,
        remarks: nullIfEmpty(remarksController.text),
      );

      final ApiResponse<VoucherAllocationModel> response = editing == null
          ? await _accountsService.createVoucherAllocation(model)
          : await _accountsService.updateVoucherAllocation(editing!.id!, model);

      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      _moduleRefresh.notifyChanged(source: _refreshSource);
      await fetch();
      startNewAllocation();
    } catch (errorValue) {
      formError = errorValue.toString();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> deleteAllocation() async {
    final id = editing?.id;
    if (id == null || !canDelete) {
      return;
    }

    saving = true;
    formError = null;
    update();

    try {
      final response = await _accountsService.deleteVoucherAllocation(id);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      _moduleRefresh.notifyChanged(source: _refreshSource);
      await fetch();
      startNewAllocation();
    } catch (errorValue) {
      formError = errorValue.toString();
    } finally {
      saving = false;
      update();
    }
  }

  List<AppDropdownItem<int>> get sourceVoucherItems => vouchers
      .map(
        (item) =>
            AppDropdownItem<int>(value: item.id!, label: _voucherLabel(item)),
      )
      .toList(growable: false);

  List<AppDropdownItem<int>> get againstVoucherItems => vouchers
      .where((item) => item.id != sourceVoucherId)
      .map(
        (item) =>
            AppDropdownItem<int>(value: item.id!, label: _voucherLabel(item)),
      )
      .toList(growable: false);

  List<AppDropdownItem<int>> get sourceLineItems =>
      _lineItemsForVoucher(sourceVoucherDetail);

  List<AppDropdownItem<int>> get againstLineItems =>
      _lineItemsForVoucher(againstVoucherDetail);

  bool get canEdit =>
      (editing == null && canCreate) || (editing != null && canUpdate);

  String sourceLineSummary() {
    final line = selectedSourceLine;
    if (line == null) {
      return '';
    }
    return [
      line.accountName ?? line.accountCode ?? '',
      line.entryType ?? '',
      if (line.amount != null) line.amount!.toStringAsFixed(2),
      if ((line.partyName ?? '').isNotEmpty) line.partyName!,
    ].where((value) => value.isNotEmpty).join(' · ');
  }

  VoucherLineModel? get selectedSourceLine => sourceVoucherDetail?.lines
      .cast<VoucherLineModel?>()
      .firstWhere((item) => item?.id == sourceLineId, orElse: () => null);

  Future<void> _loadSourceVoucherDetail({
    required int? voucherId,
    int? preferredLineId,
  }) async {
    if (voucherId == null) {
      sourceVoucherDetail = null;
      sourceLineId = null;
      return;
    }
    final response = await _accountsService.voucher(voucherId);
    final detail = response.data;
    sourceVoucherDetail = detail;
    final lines = detail?.lines ?? const <VoucherLineModel>[];
    if (lines.isEmpty) {
      sourceLineId = null;
      return;
    }

    final nextLine = lines.cast<VoucherLineModel?>().firstWhere(
      (item) => item?.id == preferredLineId,
      orElse: () => null,
    );
    sourceLineId = nextLine?.id ?? lines.first.id;
  }

  Future<void> _loadAgainstVoucherDetail({
    required int? voucherId,
    int? preferredLineId,
  }) async {
    if (voucherId == null) {
      againstVoucherDetail = null;
      againstVoucherLineId = null;
      return;
    }
    final response = await _accountsService.voucher(voucherId);
    final detail = response.data;
    againstVoucherDetail = detail;
    final lines = detail?.lines ?? const <VoucherLineModel>[];
    if (lines.isEmpty) {
      againstVoucherLineId = null;
      return;
    }

    final nextLine = lines.cast<VoucherLineModel?>().firstWhere(
      (item) => item?.id == preferredLineId,
      orElse: () => null,
    );
    againstVoucherLineId = nextLine?.id;
  }

  void _applySearch() {
    final query = searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      filteredRows = rows;
      update();
      return;
    }
    filteredRows = rows
        .where((item) {
          return [
            item.referenceNo ?? '',
            item.referenceDate ?? '',
            item.allocationType ?? '',
            item.remarks ?? '',
            item.allocationAmount?.toString() ?? '',
          ].any((value) => value.toLowerCase().contains(query));
        })
        .toList(growable: false);
    update();
  }

  List<AppDropdownItem<int>> _lineItemsForVoucher(VoucherModel? voucher) {
    final lines = voucher?.lines ?? const <VoucherLineModel>[];
    return lines
        .where((item) => item.id != null)
        .map(
          (item) =>
              AppDropdownItem<int>(value: item.id!, label: _lineLabel(item)),
        )
        .toList(growable: false);
  }

  String _voucherLabel(VoucherModel item) {
    return [
      item.voucherNo ?? '',
      item.voucherDate ?? '',
      item.voucherTypeName ?? '',
    ].where((value) => value.isNotEmpty).join(' · ');
  }

  String _lineLabel(VoucherLineModel item) {
    final amount = item.amount != null ? item.amount!.toStringAsFixed(2) : '';
    return [
      if (item.lineNo != null) 'Line ${item.lineNo}',
      item.accountName ?? item.accountCode ?? '',
      item.entryType ?? '',
      amount,
      if ((item.partyName ?? '').isNotEmpty) item.partyName!,
    ].where((value) => value.isNotEmpty).join(' · ');
  }
}
