import '../../../controller/settings/user/login_history_management_controller.dart';
import '../../../screen.dart';

class LoginHistoryPage extends StatefulWidget {
  const LoginHistoryPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<LoginHistoryPage> createState() => _LoginHistoryPageState();
}

class _LoginHistoryPageState extends State<LoginHistoryPage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'LoginHistoryManagementController',
    );
    Get.put(LoginHistoryManagementController(), tag: _controllerTag);
  }

  Future<void> _openFilterPanel(
    BuildContext context,
    LoginHistoryManagementController controller,
  ) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 600 ? 12.0 : 24.0;
    final dialogPadding = screenWidth < 600 ? 16.0 : AppUiConstants.cardPadding;

    final searchText = controller.searchController.text;
    final usernameText = controller.usernameController.text;
    final dateFromText = controller.dateFromController.text;
    final dateToText = controller.dateToController.text;

    String? tempDeviceType = controller.deviceType;
    String? tempOs = controller.os;
    String? tempStatus = controller.status;

    final applied = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final appTheme = Theme.of(
          dialogContext,
        ).extension<AppThemeExtension>()!;

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
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
                    MediaQuery.of(dialogContext).viewInsets.bottom +
                        dialogPadding,
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
                              style: Theme.of(dialogContext)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            tooltip: 'Close',
                            icon: const Icon(Icons.close),
                            color: appTheme.mutedText,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildFilterFields(
                        dialogContext,
                        controller,
                        tempDeviceType: tempDeviceType,
                        tempOs: tempOs,
                        tempStatus: tempStatus,
                        onDeviceTypeChanged: (value) {
                          setDialogState(() => tempDeviceType = value);
                        },
                        onOsChanged: (value) {
                          setDialogState(() => tempOs = value);
                        },
                        onStatusChanged: (value) {
                          setDialogState(() => tempStatus = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            onPressed: () {
                              controller.updateDeviceType(tempDeviceType);
                              controller.updateOs(tempOs);
                              controller.updateStatus(tempStatus);
                              Navigator.of(dialogContext).pop(true);
                            },
                            icon: const Icon(Icons.search),
                            label: const Text('Apply Filters'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              controller.clearFilters();
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
      },
    );

    if (applied == true) {
      await controller.loadHistory(page: 1);
    } else {
      controller.searchController.text = searchText;
      controller.usernameController.text = usernameText;
      controller.dateFromController.text = dateFromText;
      controller.dateToController.text = dateToText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LoginHistoryManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = _buildShellContent(context, controller);
        if (widget.embedded) {
          return ShellPageActions(
            actions: _buildShellActions(context, controller),
            child: content,
          );
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
              scrollController: controller.pageScrollController,
              actions: _buildShellActions(context, controller),
              child: content,
            );
          },
        );
      },
    );
  }

  List<Widget> _buildShellActions(
    BuildContext context,
    LoginHistoryManagementController controller,
  ) {
    return [
      AdaptiveShellMenuAction<String>(
        icon: Icons.sort_outlined,
        label: 'Sort',
        onSelected: (value) {
          controller.updateSort(value);
          controller.loadHistory(page: 1);
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
        onPressed: () => _openFilterPanel(context, controller),
      ),
      AdaptiveShellActionButton(
        icon: Icons.refresh,
        label: 'Refresh',
        onPressed: controller.loadHistory,
      ),
    ];
  }

  Widget _buildShellContent(
    BuildContext context,
    LoginHistoryManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading login history...');
    }

    if (controller.error != null) {
      return AppErrorStateView(
        title: 'Unable to load login history',
        message: controller.error!,
        onRetry: controller.loadHistory,
      );
    }

    return SingleChildScrollView(
      controller: controller.pageScrollController,
      padding: const EdgeInsets.all(AppUiConstants.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAppliedFilters(context, controller),
          const SizedBox(height: 20),
          if (controller.dataLoading)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(
                minHeight: 3,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          IgnorePointer(
            ignoring: controller.dataLoading,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: controller.dataLoading ? 0.72 : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildResults(context, controller),
                  if (controller.meta != null) ...[
                    const SizedBox(height: 20),
                    ReportPaginationBar(
                      meta: controller.meta!,
                      onPerPageChanged: (value) {
                        controller.loadHistory(page: 1, perPage: value);
                      },
                      onPageChanged: (value) {
                        controller.loadHistory(page: value);
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

  Widget _buildAppliedFilters(
    BuildContext context,
    LoginHistoryManagementController controller,
  ) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;
    final chips = controller.appliedFilterChips();

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

  Widget _buildFilterFields(
    BuildContext context,
    LoginHistoryManagementController controller, {
    required String? tempDeviceType,
    required String? tempOs,
    required String? tempStatus,
    required ValueChanged<String?> onDeviceTypeChanged,
    required ValueChanged<String?> onOsChanged,
    required ValueChanged<String?> onStatusChanged,
  }) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _filterBox(
          child: TextField(
            controller: controller.searchController,
            decoration: const InputDecoration(labelText: 'Search'),
          ),
        ),
        _filterBox(
          child: TextField(
            controller: controller.usernameController,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
        ),
        _filterBox(
          child: AppDropdownField<String>.fromMapped(
            initialValue: tempDeviceType,
            labelText: 'Device',
            mappedItems: const [
              AppDropdownItem(value: 'desktop', label: 'Desktop'),
              AppDropdownItem(value: 'mobile', label: 'Mobile'),
              AppDropdownItem(value: 'tablet', label: 'Tablet'),
            ],
            onChanged: onDeviceTypeChanged,
          ),
        ),
        _filterBox(
          child: AppDropdownField<String>.fromMapped(
            initialValue: tempOs,
            labelText: 'OS',
            mappedItems: const [
              AppDropdownItem(value: 'Windows', label: 'Windows'),
              AppDropdownItem(value: 'macOS', label: 'macOS'),
              AppDropdownItem(value: 'Linux', label: 'Linux'),
              AppDropdownItem(value: 'Android', label: 'Android'),
              AppDropdownItem(value: 'iOS', label: 'iOS'),
            ],
            onChanged: onOsChanged,
          ),
        ),
        _filterBox(
          child: AppDropdownField<String>.fromMapped(
            initialValue: tempStatus,
            labelText: 'Status',
            mappedItems: const [
              AppDropdownItem(value: 'success', label: 'Success'),
              AppDropdownItem(value: 'failed', label: 'Failed'),
              AppDropdownItem(value: 'blocked', label: 'Blocked'),
            ],
            onChanged: onStatusChanged,
          ),
        ),
        _filterBox(
          child: AppFormTextField(
            controller: controller.dateFromController,
            labelText: 'Date From',
            hintText: 'YYYY-MM-DD',
            keyboardType: TextInputType.datetime,
            inputFormatters: const [DateInputFormatter()],
          ),
        ),
        _filterBox(
          child: AppFormTextField(
            controller: controller.dateToController,
            labelText: 'Date To',
            hintText: 'YYYY-MM-DD',
            keyboardType: TextInputType.datetime,
            inputFormatters: const [DateInputFormatter()],
          ),
        ),
      ],
    );
  }

  Widget _buildResults(
    BuildContext context,
    LoginHistoryManagementController controller,
  ) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;
    final useTable = MediaQuery.of(context).size.width >= 900;

    if (controller.entries.isEmpty) {
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
            ? _buildDesktopTable(controller)
            : _buildMobileCards(context, controller),
      ),
    );
  }

  Widget _buildDesktopTable(LoginHistoryManagementController controller) {
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
        rows: controller.entries
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

  Widget _buildMobileCards(
    BuildContext context,
    LoginHistoryManagementController controller,
  ) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;

    return Column(
      children: controller.entries
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
}
