import '../screen.dart';

class SessionContextButton extends StatefulWidget {
  const SessionContextButton({super.key});

  @override
  State<SessionContextButton> createState() => _SessionContextButtonState();
}

class _SessionContextButtonState extends State<SessionContextButton> {
  bool _busy = false;
  WorkingContextDisplay? _display;

  @override
  void initState() {
    super.initState();
    WorkingContextService.version.addListener(_handleVersionChanged);
    _reloadSummary();
  }

  @override
  void dispose() {
    WorkingContextService.version.removeListener(_handleVersionChanged);
    super.dispose();
  }

  void _handleVersionChanged() {
    if (mounted) {
      setState(() {});
      _reloadSummary();
    }
  }

  Future<void> _reloadSummary() async {
    final authContext = await SessionStorage.getAuthContext();
    final companyId = await SessionStorage.getCurrentCompanyId();
    final branchId = await SessionStorage.getCurrentBranchId();
    final locationId = await SessionStorage.getCurrentLocationId();
    final financialYearId = await SessionStorage.getCurrentFinancialYearId();
    if (!mounted) {
      return;
    }

    setState(() {
      _display = buildWorkingContextDisplay(
        companies: authContext?.companies ?? const <CompanyModel>[],
        branches: authContext?.branches ?? const <BranchModel>[],
        locations: authContext?.locations ?? const <BusinessLocationModel>[],
        financialYears:
            authContext?.financialYears ?? const <FinancialYearModel>[],
        companyId: companyId,
        branchId: branchId,
        locationId: locationId,
        financialYearId: financialYearId,
      );
    });
  }

  String get _primarySummaryLabel {
    return 'Context';
  }

  String? get _financialYearSummaryLabel {
    return _display?.financialYearSummary;
  }

  String get _tooltipLabel {
    final value = _display?.tooltipSummary ?? '';
    if (value.trim().isEmpty) {
      return 'Working Context';
    }
    return value;
  }

  Future<void> _openContextDialog() async {
    setState(() => _busy = true);
    try {
      final snapshot = await WorkingContextService.instance.loadSnapshot();
      if (!mounted) {
        return;
      }

      final companyId = ValueNotifier<int?>(snapshot.selection.companyId);
      final branchId = ValueNotifier<int?>(snapshot.selection.branchId);
      final locationId = ValueNotifier<int?>(snapshot.selection.locationId);
      final financialYearId = ValueNotifier<int?>(
        snapshot.selection.financialYearId,
      );

      Future<void> syncChildren() async {
        final selection = await WorkingContextService.instance.resolveSelection(
          companies: snapshot.companies,
          branches: snapshot.branches,
          locations: snapshot.locations,
          financialYears: snapshot.financialYears,
          companyId: companyId.value,
          branchId: branchId.value,
          locationId: locationId.value,
          financialYearId: financialYearId.value,
          persist: false,
        );
        companyId.value = selection.companyId;
        branchId.value = selection.branchId;
        locationId.value = selection.locationId;
        financialYearId.value = selection.financialYearId;
      }

      await syncChildren();
      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Working Context'),
            content: SizedBox(
              width: 420,
              child: StatefulBuilder(
                builder: (context, setLocalState) {
                  final scopedBranches = snapshot.branches
                      .where(
                        (BranchModel item) =>
                            companyId.value == null ||
                            item.companyId == companyId.value,
                      )
                      .toList(growable: false);
                  final scopedLocations = snapshot.locations
                      .where((BusinessLocationModel item) {
                        if (branchId.value != null) {
                          return item.branchId == branchId.value;
                        }
                        if (companyId.value != null) {
                          return item.companyId == companyId.value;
                        }
                        return true;
                      })
                      .toList(growable: false);
                  final scopedFinancialYears = snapshot.financialYears
                      .where(
                        (FinancialYearModel item) =>
                            companyId.value == null ||
                            item.companyId == companyId.value,
                      )
                      .toList(growable: false);
                  final hasMissingOptions =
                      snapshot.companies.isEmpty ||
                      scopedBranches.isEmpty ||
                      scopedLocations.isEmpty ||
                      scopedFinancialYears.isEmpty;
                  final hasOnlyResolvedOptions =
                      snapshot.companies.length <= 1 &&
                      scopedBranches.length <= 1 &&
                      scopedLocations.length <= 1 &&
                      scopedFinancialYears.length <= 1;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (snapshot.companies.length == 1)
                        InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Company',
                          ),
                          child: Text(
                            snapshot.companies.first.legalName ??
                                snapshot.companies.first.toString(),
                          ),
                        ),
                      if (snapshot.companies.length > 1)
                        AppDropdownField<int>.fromMapped(
                          labelText: 'Company',
                          initialValue: companyId.value,
                          mappedItems: snapshot.companies
                              .where((CompanyModel item) => item.id != null)
                              .map(
                                (CompanyModel item) => AppDropdownItem<int>(
                                  value: item.id!,
                                  label: item.legalName ?? item.toString(),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) async {
                            companyId.value = value;
                            await syncChildren();
                            setLocalState(() {});
                          },
                        ),
                      if (scopedBranches.isEmpty) ...[
                        const SizedBox(height: AppUiConstants.spacingMd),
                        const InputDecorator(
                          decoration: InputDecoration(labelText: 'Branch'),
                          child: Text('No branch available'),
                        ),
                      ],
                      if (scopedBranches.length > 1) ...[
                        const SizedBox(height: AppUiConstants.spacingMd),
                        AppDropdownField<int>.fromMapped(
                          labelText: 'Branch',
                          initialValue: branchId.value,
                          mappedItems: scopedBranches
                              .where((BranchModel item) => item.id != null)
                              .map(
                                (BranchModel item) => AppDropdownItem<int>(
                                  value: item.id!,
                                  label: item.name ?? item.toString(),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) async {
                            branchId.value = value;
                            await syncChildren();
                            setLocalState(() {});
                          },
                        ),
                      ],
                      if (scopedBranches.length == 1) ...[
                        const SizedBox(height: AppUiConstants.spacingMd),
                        InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Branch',
                          ),
                          child: Text(
                            scopedBranches.first.name ??
                                scopedBranches.first.toString(),
                          ),
                        ),
                      ],
                      if (scopedLocations.isEmpty) ...[
                        const SizedBox(height: AppUiConstants.spacingMd),
                        const InputDecorator(
                          decoration: InputDecoration(labelText: 'Location'),
                          child: Text('No location available'),
                        ),
                      ],
                      if (scopedLocations.length > 1) ...[
                        const SizedBox(height: AppUiConstants.spacingMd),
                        AppDropdownField<int>.fromMapped(
                          labelText: 'Location',
                          initialValue: locationId.value,
                          mappedItems: scopedLocations
                              .where(
                                (BusinessLocationModel item) => item.id != null,
                              )
                              .map(
                                (BusinessLocationModel item) =>
                                    AppDropdownItem<int>(
                                      value: item.id!,
                                      label: item.name ?? item.toString(),
                                    ),
                              )
                              .toList(growable: false),
                          onChanged: (value) async {
                            locationId.value = value;
                            await syncChildren();
                            setLocalState(() {});
                          },
                        ),
                      ],
                      if (scopedLocations.length == 1) ...[
                        const SizedBox(height: AppUiConstants.spacingMd),
                        InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Location',
                          ),
                          child: Text(
                            scopedLocations.first.name ??
                                scopedLocations.first.toString(),
                          ),
                        ),
                      ],
                      if (scopedFinancialYears.isEmpty) ...[
                        const SizedBox(height: AppUiConstants.spacingMd),
                        const InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Financial Year',
                          ),
                          child: Text('No financial year available'),
                        ),
                      ],
                      if (scopedFinancialYears.length > 1) ...[
                        const SizedBox(height: AppUiConstants.spacingMd),
                        AppDropdownField<int>.fromMapped(
                          labelText: 'Financial Year',
                          initialValue: financialYearId.value,
                          mappedItems: scopedFinancialYears
                              .where(
                                (FinancialYearModel item) => item.id != null,
                              )
                              .map(
                                (FinancialYearModel item) =>
                                    AppDropdownItem<int>(
                                      value: item.id!,
                                      label: item.fyName ?? item.toString(),
                                    ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            financialYearId.value = value;
                            setLocalState(() {});
                          },
                        ),
                      ],
                      if (scopedFinancialYears.length == 1) ...[
                        const SizedBox(height: AppUiConstants.spacingMd),
                        InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Financial Year',
                          ),
                          child: Text(
                            scopedFinancialYears.first.fyName ??
                                scopedFinancialYears.first.toString(),
                          ),
                        ),
                      ],
                      if (hasOnlyResolvedOptions && !hasMissingOptions)
                        const Text(
                          'Only one active option is available for each context, so defaults are already applied.',
                        ),
                    ],
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              FilledButton(
                onPressed: () async {
                  await WorkingContextService.instance.saveSelection(
                    WorkingContextSelection(
                      companyId: companyId.value,
                      branchId: branchId.value,
                      locationId: locationId.value,
                      financialYearId: financialYearId.value,
                    ),
                  );
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      );

      companyId.dispose();
      branchId.dispose();
      locationId.dispose();
      financialYearId.dispose();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 600;
    return Tooltip(
      message: _tooltipLabel,
      child: OutlinedButton(
        onPressed: _busy ? null : _openContextDialog,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 44),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 0 : 14,
            vertical: 10,
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppUiConstants.buttonRadius),
          ),
        ),
        child: compact
            ? const Icon(Icons.tune_outlined, size: 20)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.tune_outlined, size: 20),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _primarySummaryLabel,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        if (_financialYearSummaryLabel != null)
                          Text(
                            _financialYearSummaryLabel!,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
