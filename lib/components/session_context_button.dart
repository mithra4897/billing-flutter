import '../screen.dart';

class SessionContextButton extends StatefulWidget {
  const SessionContextButton({super.key});

  @override
  State<SessionContextButton> createState() => _SessionContextButtonState();
}

class _SessionContextButtonState extends State<SessionContextButton> {
  bool _busy = false;
  String? _companyLabel;
  String? _branchLabel;
  String? _locationLabel;
  String? _financialYearLabel;

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

    final company = authContext?.companies.cast<CompanyModel?>().firstWhere(
      (item) => item?.id == companyId,
      orElse: () => null,
    );
    final branch = authContext?.branches.cast<BranchModel?>().firstWhere(
      (item) => item?.id == branchId,
      orElse: () => null,
    );
    final location = authContext?.locations
        .cast<BusinessLocationModel?>()
        .firstWhere((item) => item?.id == locationId, orElse: () => null);
    final financialYear = authContext?.financialYears
        .cast<FinancialYearModel?>()
        .firstWhere((item) => item?.id == financialYearId, orElse: () => null);

    setState(() {
      _companyLabel = company?.toString();
      _branchLabel = branch?.toString();
      _locationLabel = location?.toString();
      _financialYearLabel = financialYear?.toString();
    });
  }

  String get _summaryLabel {
    final primary = <String>[
      if ((_companyLabel ?? '').trim().isNotEmpty) _companyLabel!,
      if ((_branchLabel ?? '').trim().isNotEmpty) _branchLabel!,
      if ((_locationLabel ?? '').trim().isNotEmpty) _locationLabel!,
    ];
    if (primary.isEmpty) {
      return 'Context';
    }
    return primary.join(' / ');
  }

  String get _tooltipLabel {
    final values = <String>[
      if ((_companyLabel ?? '').trim().isNotEmpty) 'Company: $_companyLabel',
      if ((_branchLabel ?? '').trim().isNotEmpty) 'Branch: $_branchLabel',
      if ((_locationLabel ?? '').trim().isNotEmpty) 'Location: $_locationLabel',
      if ((_financialYearLabel ?? '').trim().isNotEmpty)
        'FY: $_financialYearLabel',
    ];
    if (values.isEmpty) {
      return 'Working Context';
    }
    return values.join('\n');
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
        );
        companyId.value = selection.companyId;
        branchId.value = selection.branchId;
        locationId.value = selection.locationId;
        financialYearId.value = selection.financialYearId;
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
                      .where(
                        (BusinessLocationModel item) {
                          final companyMatches =
                              companyId.value == null ||
                              item.companyId == companyId.value;
                          final branchMatches =
                              branchId.value == null ||
                              item.branchId == branchId.value;
                          return companyMatches && branchMatches;
                        },
                      )
                      .toList(growable: false);
                  final scopedFinancialYears = snapshot.financialYears
                      .where(
                        (FinancialYearModel item) =>
                            companyId.value == null ||
                            item.companyId == companyId.value,
                      )
                      .toList(growable: false);

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      if (snapshot.companies.length <= 1 &&
                          scopedBranches.length <= 1 &&
                          scopedLocations.isEmpty &&
                          scopedFinancialYears.length <= 1)
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
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Text(
                      _summaryLabel,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
