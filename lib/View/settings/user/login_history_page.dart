import '../../../screen.dart';

class LoginHistoryPage extends StatefulWidget {
  const LoginHistoryPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<LoginHistoryPage> createState() => _LoginHistoryPageState();
}

class _LoginHistoryPageState extends State<LoginHistoryPage> {
  final AuthService _authService = AuthService();
  final ScrollController _pageScrollController = ScrollController();

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _dateFromController = TextEditingController();
  final TextEditingController _dateToController = TextEditingController();

  bool _initialLoading = true;
  bool _dataLoading = false;
  String? _error;
  List<LoginHistoryModel> _entries = const <LoginHistoryModel>[];
  PaginationMeta? _meta;
  String? _deviceType;
  String? _os;
  String? _status;
  int _perPage = 20;
  int _currentPage = 1;
  String _sortBy = 'login_at';
  String _sortDirection = 'desc';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _searchController.dispose();
    _usernameController.dispose();
    _dateFromController.dispose();
    _dateToController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory({int? page, int? perPage}) async {
    final showInitialLoader = _meta == null && _entries.isEmpty;

    setState(() {
      _initialLoading = showInitialLoader;
      _dataLoading = !showInitialLoader;
      _error = null;
    });

    try {
      final response = await _authService.loginHistory(
        filters: {
          'per_page': perPage ?? _perPage,
          'page': page ?? _currentPage,
          'sort_by': _sortBy,
          'sort_direction': _sortDirection,
          if (_searchController.text.trim().isNotEmpty)
            'search': _searchController.text.trim(),
          if (_usernameController.text.trim().isNotEmpty)
            'username': _usernameController.text.trim(),
          if ((_deviceType ?? '').isNotEmpty) 'device_type': _deviceType,
          if ((_os ?? '').isNotEmpty) 'os': _os,
          if ((_status ?? '').isNotEmpty) 'login_status': _status,
          if (_dateFromController.text.trim().isNotEmpty)
            'date_from': _dateFromController.text.trim(),
          if (_dateToController.text.trim().isNotEmpty)
            'date_to': _dateToController.text.trim(),
        },
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _entries = response.data ?? const <LoginHistoryModel>[];
        _meta = response.meta;
        _perPage = response.meta?.perPage ?? (perPage ?? _perPage);
        _currentPage = response.meta?.currentPage ?? (page ?? _currentPage);
        _initialLoading = false;
        _dataLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _initialLoading = false;
        _dataLoading = false;
      });
    }
  }

  Future<void> _openFilterPanel() async {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 600 ? 12.0 : 24.0;
    final dialogPadding = screenWidth < 600 ? 16.0 : AppUiConstants.cardPadding;

    final applied = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final appTheme = Theme.of(
          dialogContext,
        ).extension<AppThemeExtension>()!;

        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 20,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                dialogPadding,
                dialogPadding,
                dialogPadding,
                MediaQuery.of(dialogContext).viewInsets.bottom + dialogPadding,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Filter Login History',
                          style: Theme.of(dialogContext).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        tooltip: 'Close',
                        icon: const Icon(Icons.close),
                        color: appTheme.mutedText,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFilterFields(dialogContext),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        icon: const Icon(Icons.search),
                        label: const Text('Apply Filters'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _usernameController.clear();
                            _dateFromController.clear();
                            _dateToController.clear();
                            _deviceType = null;
                            _os = null;
                            _status = null;
                          });
                          Navigator.of(dialogContext).pop(true);
                        },
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (applied == true) {
      _loadHistory(page: 1);
    }
  }

  Future<void> _logout(BuildContext context) async {
    await AppSessionService.instance.clearSession();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildShellContent(context);
    if (widget.embedded) {
      return ShellPageActions(actions: _buildShellActions(), child: content);
    }

    return FutureBuilder<PublicBrandingModel?>(
      future: SessionStorage.getBranding(),
      builder: (context, snapshot) {
        final branding =
            snapshot.data ??
            const PublicBrandingModel(companyName: 'Billing ERP');

        return AdaptiveShell(
          title: 'Login History',
          branding: branding,
          scrollController: _pageScrollController,
          actions: _buildShellActions(),
          onLogout: () => _logout(context),
          child: content,
        );
      },
    );
  }

  List<Widget> _buildShellActions() {
    return [
      AdaptiveShellMenuAction<String>(
        icon: Icons.sort_outlined,
        label: 'Sort',
        onSelected: (value) {
          final parts = value.split(':');
          setState(() {
            _sortBy = parts.first;
            _sortDirection = parts.last;
          });
          _loadHistory(page: 1);
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'login_at:desc', child: Text('Latest Login')),
          PopupMenuItem(value: 'login_at:asc', child: Text('Oldest Login')),
          PopupMenuItem(value: 'username:asc', child: Text('Username A-Z')),
          PopupMenuItem(value: 'login_status:asc', child: Text('Status')),
          PopupMenuItem(value: 'device_type:asc', child: Text('Device')),
        ],
      ),
      AdaptiveShellActionButton(
        icon: Icons.filter_alt_outlined,
        label: 'Filter',
        filled: false,
        onPressed: _openFilterPanel,
      ),
      AdaptiveShellActionButton(
        icon: Icons.refresh,
        label: 'Refresh',
        onPressed: _loadHistory,
      ),
    ];
  }

  Widget _buildShellContent(BuildContext context) {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading login history...');
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    return SingleChildScrollView(
      controller: _pageScrollController,
      padding: const EdgeInsets.all(AppUiConstants.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAppliedFilters(context),
          const SizedBox(height: 20),
          if (_dataLoading)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(
                minHeight: 3,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          IgnorePointer(
            ignoring: _dataLoading,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: _dataLoading ? 0.72 : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildResults(context),
                  if (_meta != null) ...[
                    const SizedBox(height: 20),
                    ReportPaginationBar(
                      meta: _meta!,
                      onPerPageChanged: (value) {
                        _loadHistory(page: 1, perPage: value);
                      },
                      onPageChanged: (value) {
                        _loadHistory(page: value);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppliedFilters(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;
    final chips = <String>[
      if (_searchController.text.trim().isNotEmpty)
        'Search: ${_searchController.text.trim()}',
      if (_usernameController.text.trim().isNotEmpty)
        'Username: ${_usernameController.text.trim()}',
      if ((_deviceType ?? '').isNotEmpty) 'Device: $_deviceType',
      if ((_os ?? '').isNotEmpty) 'OS: $_os',
      if ((_status ?? '').isNotEmpty) 'Status: $_status',
      if (_dateFromController.text.trim().isNotEmpty)
        'From: ${_dateFromController.text.trim()}',
      if (_dateToController.text.trim().isNotEmpty)
        'To: ${_dateToController.text.trim()}',
      'Sort: ${_sortLabel()}',
    ];

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
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: chips
              .map((chip) => Chip(label: Text(chip)))
              .toList(growable: false),
        ),
      ),
    );
  }

  Widget _buildFilterFields(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _filterBox(
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(labelText: 'Search'),
          ),
        ),
        _filterBox(
          child: TextField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
        ),
        _filterBox(
          child: AppDropdownField<String>.fromMapped(
            initialValue: _deviceType,
            labelText: 'Device',
            mappedItems: const [
              AppDropdownItem(value: 'desktop', label: 'Desktop'),
              AppDropdownItem(value: 'mobile', label: 'Mobile'),
              AppDropdownItem(value: 'tablet', label: 'Tablet'),
            ],
            onChanged: (value) => setState(() => _deviceType = value),
          ),
        ),
        _filterBox(
          child: AppDropdownField<String>.fromMapped(
            initialValue: _os,
            labelText: 'OS',
            mappedItems: const [
              AppDropdownItem(value: 'Windows', label: 'Windows'),
              AppDropdownItem(value: 'macOS', label: 'macOS'),
              AppDropdownItem(value: 'Linux', label: 'Linux'),
              AppDropdownItem(value: 'Android', label: 'Android'),
              AppDropdownItem(value: 'iOS', label: 'iOS'),
            ],
            onChanged: (value) => setState(() => _os = value),
          ),
        ),
        _filterBox(
          child: AppDropdownField<String>.fromMapped(
            initialValue: _status,
            labelText: 'Status',
            mappedItems: const [
              AppDropdownItem(value: 'success', label: 'Success'),
              AppDropdownItem(value: 'failed', label: 'Failed'),
              AppDropdownItem(value: 'blocked', label: 'Blocked'),
            ],
            onChanged: (value) => setState(() => _status = value),
          ),
        ),
        _filterBox(
          child: TextField(
            controller: _dateFromController,
            decoration: const InputDecoration(
              labelText: 'Date From',
              hintText: 'YYYY-MM-DD',
            ),
          ),
        ),
        _filterBox(
          child: TextField(
            controller: _dateToController,
            decoration: const InputDecoration(
              labelText: 'Date To',
              hintText: 'YYYY-MM-DD',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResults(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;
    final useTable = MediaQuery.of(context).size.width >= 900;

    if (_entries.isEmpty) {
      return Container(
        constraints: const BoxConstraints(minHeight: 280),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: appTheme.cardBackground,
          borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
        ),
        child: Text(
          'No login history found for the selected filters.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: appTheme.mutedText),
        ),
      );
    }

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
        child: useTable
            ? _buildDesktopTable(context)
            : _buildMobileCards(context),
      ),
    );
  }

  Widget _buildDesktopTable(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('User')),
          DataColumn(label: Text('Username')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Login At')),
          DataColumn(label: Text('Logout At')),
          DataColumn(label: Text('Device')),
          DataColumn(label: Text('IP')),
          DataColumn(label: Text('Remarks')),
        ],
        rows: _entries
            .map((entry) {
              final displayName =
                  entry.displayName ??
                  '${entry.firstName ?? ''} ${entry.lastName ?? ''}'.trim();
              return DataRow(
                cells: [
                  DataCell(Text(displayName.isEmpty ? '-' : displayName)),
                  DataCell(Text(entry.username ?? '-')),
                  DataCell(Text(entry.status ?? '-')),
                  DataCell(Text(entry.loginAt ?? '-')),
                  DataCell(Text(entry.logoutAt ?? '-')),
                  DataCell(
                    Text(
                      '${entry.deviceType ?? '-'} / ${entry.browser ?? '-'} / ${entry.os ?? '-'}',
                    ),
                  ),
                  DataCell(Text(entry.ipAddress ?? '-')),
                  DataCell(Text(entry.remarks ?? '-')),
                ],
              );
            })
            .toList(growable: false),
      ),
    );
  }

  Widget _buildMobileCards(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;

    return Column(
      children: _entries
          .map((entry) {
            final displayName =
                entry.displayName ??
                '${entry.firstName ?? ''} ${entry.lastName ?? ''}'.trim();
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: appTheme.subtleFill,
                borderRadius: BorderRadius.circular(
                  AppUiConstants.buttonRadius,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName.isEmpty
                              ? (entry.username ?? 'Unknown User')
                              : '$displayName (${entry.username ?? '-'})',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        entry.status ?? '-',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Login: ${entry.loginAt ?? '-'}'),
                  Text('Logout: ${entry.logoutAt ?? '-'}'),
                  Text('IP: ${entry.ipAddress ?? '-'}'),
                  Text('Host: ${entry.hostName ?? '-'}'),
                  Text(
                    'Device: ${entry.deviceType ?? '-'} | ${entry.browser ?? '-'} | ${entry.os ?? '-'}',
                  ),
                  if ((entry.remarks ?? '').isNotEmpty)
                    Text('Remarks: ${entry.remarks}'),
                ],
              ),
            );
          })
          .toList(growable: false),
    );
  }

  Widget _filterBox({required Widget child}) {
    return SizedBox(width: 240, child: child);
  }

  String _sortLabel() {
    return switch ('$_sortBy:$_sortDirection') {
      'login_at:desc' => 'Latest Login',
      'login_at:asc' => 'Oldest Login',
      'username:asc' => 'Username A-Z',
      'login_status:asc' => 'Status',
      'device_type:asc' => 'Device',
      _ => 'Custom',
    };
  }
}
