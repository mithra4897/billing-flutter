import '../../../screen.dart';

class LoginHistoryManagementController extends GetxController {
  LoginHistoryManagementController();

  final AuthService _authService = AuthService();
  final ScrollController pageScrollController = ScrollController();

  final TextEditingController searchController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController dateFromController = TextEditingController();
  final TextEditingController dateToController = TextEditingController();

  bool initialLoading = true;
  bool dataLoading = false;
  String? error;
  List<LoginHistoryModel> entries = const <LoginHistoryModel>[];
  PaginationMeta? meta;
  String? deviceType;
  String? os;
  String? status;
  int perPage = 20;
  int currentPage = 1;
  String sortBy = 'login_at';
  String sortDirection = 'desc';

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  @override
  void onClose() {
    pageScrollController.dispose();
    searchController.dispose();
    usernameController.dispose();
    dateFromController.dispose();
    dateToController.dispose();
    super.onClose();
  }

  Future<void> loadHistory({int? page, int? perPage}) async {
    final showInitialLoader = meta == null && entries.isEmpty;

    initialLoading = showInitialLoader;
    dataLoading = !showInitialLoader;
    error = null;
    update();

    try {
      final response = await _authService.loginHistory(
        filters: {
          'per_page': perPage ?? this.perPage,
          'page': page ?? currentPage,
          'sort_by': sortBy,
          'sort_direction': sortDirection,
          if (searchController.text.trim().isNotEmpty)
            'search': searchController.text.trim(),
          if (usernameController.text.trim().isNotEmpty)
            'username': usernameController.text.trim(),
          if ((deviceType ?? '').isNotEmpty) 'device_type': deviceType,
          if ((os ?? '').isNotEmpty) 'os': os,
          if ((status ?? '').isNotEmpty) 'login_status': status,
          if (dateFromController.text.trim().isNotEmpty)
            'date_from': dateFromController.text.trim(),
          if (dateToController.text.trim().isNotEmpty)
            'date_to': dateToController.text.trim(),
        },
      );

      entries = response.data ?? const <LoginHistoryModel>[];
      meta = response.meta;
      this.perPage = response.meta?.perPage ?? (perPage ?? this.perPage);
      currentPage = response.meta?.currentPage ?? (page ?? currentPage);
      initialLoading = false;
      dataLoading = false;
    } catch (errorValue) {
      error = errorValue.toString();
      initialLoading = false;
      dataLoading = false;
    }

    update();
  }

  void updateDeviceType(String? value) {
    deviceType = value;
    update();
  }

  void updateOs(String? value) {
    os = value;
    update();
  }

  void updateStatus(String? value) {
    status = value;
    update();
  }

  void updateSort(String sortValue) {
    final parts = sortValue.split(':');
    sortBy = parts.first;
    sortDirection = parts.last;
    update();
  }

  void clearFilters() {
    searchController.clear();
    usernameController.clear();
    dateFromController.clear();
    dateToController.clear();
    deviceType = null;
    os = null;
    status = null;
    update();
  }

  List<String> appliedFilterChips() {
    return <String>[
      if (searchController.text.trim().isNotEmpty)
        'Search: ${searchController.text.trim()}',
      if (usernameController.text.trim().isNotEmpty)
        'Username: ${usernameController.text.trim()}',
      if ((deviceType ?? '').isNotEmpty) 'Device: $deviceType',
      if ((os ?? '').isNotEmpty) 'OS: $os',
      if ((status ?? '').isNotEmpty) 'Status: $status',
      if (dateFromController.text.trim().isNotEmpty)
        'From: ${dateFromController.text.trim()}',
      if (dateToController.text.trim().isNotEmpty)
        'To: ${dateToController.text.trim()}',
      'Sort: ${sortLabel()}',
    ];
  }

  String sortLabel() {
    return switch ('$sortBy:$sortDirection') {
      'login_at:desc' => 'Latest Login',
      'login_at:asc' => 'Oldest Login',
      'username:asc' => 'Username A-Z',
      'login_status:asc' => 'Status',
      'device_type:asc' => 'Device',
      _ => 'Custom',
    };
  }
}
