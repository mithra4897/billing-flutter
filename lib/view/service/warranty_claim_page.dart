import '../../screen.dart';

String _claimListTitle(ServiceTicketModel row) {
  final data = row.toJson();
  final no = stringValue(data, 'ticket_no');
  if (no.isNotEmpty) {
    return no;
  }
  final id = intValue(data, 'id');
  return id != null ? 'Claim #$id' : 'Claim';
}

class WarrantyClaimPage extends StatefulWidget {
  const WarrantyClaimPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<WarrantyClaimPage> createState() => _WarrantyClaimPageState();
}

class _WarrantyClaimPageState extends State<WarrantyClaimPage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  late final String _controllerTag;
  late final WarrantyClaimViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag('WarrantyClaimViewModel');
    _viewModel = Get.put(
      WarrantyClaimViewModel()..load(selectId: widget.initialId),
      tag: _controllerTag,
      permanent: true,
    );
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _workspaceController.dispose();
    super.dispose();
  }

  void _openRoute(String route) {
    final navigate = ShellRouteScope.maybeOf(context);
    if (navigate != null) {
      navigate(route);
      return;
    }
    Navigator.of(context).pushNamed(route);
  }

  void _snack() {
    final msg = _viewModel.consumeActionMessage();
    if (!mounted || msg == null || msg.trim().isEmpty) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _assign() async {
    final result = await promptServiceAssigneeUserId(
      context,
      _viewModel.users,
      initialUserId: intValue(
        _viewModel.selected?.toJson() ?? const <String, dynamic>{},
        'assigned_to_user_id',
      ),
    );
    if (!mounted || !result.submitted) {
      return;
    }
    await _viewModel.assignClaim(assignedToUserId: result.assignedToUserId);
    _snack();
  }

  Future<void> _createWo() async {
    int? seriesId = _viewModel.woSeriesOptions.isNotEmpty
        ? _viewModel.woSeriesOptions.first.id
        : null;
    int? technicianUserId = intValue(
      _viewModel.selected?.toJson() ?? const <String, dynamic>{},
      'assigned_to_user_id',
    );
    String executionMode = stringValue(
      _viewModel.selected?.toJson() ?? const <String, dynamic>{},
      'service_mode',
    );
    if (executionMode.trim().isEmpty) {
      executionMode = 'onsite';
    }
    final dateCtrl = TextEditingController(
      text: DateTime.now().toIso8601String().split('T').first,
    );
    final diagnosisCtrl = TextEditingController(
      text: stringValue(
        _viewModel.selected?.toJson() ?? const <String, dynamic>{},
        'issue_description',
      ),
    );
    final actionCtrl = TextEditingController();
    final resolutionCtrl = TextEditingController();
    final remarksCtrl = TextEditingController(
      text: stringValue(
        _viewModel.selected?.toJson() ?? const <String, dynamic>{},
        'notes',
      ),
    );

    final body = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Create work order'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DocumentSeriesSelector<int?>(
                    labelText: 'Work order series',
                    mappedItems: [
                      const AppDropdownItem<int?>(value: null, label: '-'),
                      ..._viewModel.woSeriesOptions
                          .where((s) => s.id != null)
                          .map(
                            (s) => AppDropdownItem<int?>(
                              value: s.id!,
                              label: s.toString(),
                            ),
                          ),
                    ],
                    initialValue: seriesId,
                    onChanged: (value) => setState(() => seriesId = value),
                  ),
                  AppDateField(
                    labelText: 'Work order date',
                    controller: dateCtrl,
                    validator: Validators.required('Work order date'),
                  ),
                  AppDropdownField<String>.fromMapped(
                    labelText: 'Execution mode',
                    mappedItems: const [
                      AppDropdownItem<String>(value: 'onsite', label: 'Onsite'),
                      AppDropdownItem<String>(value: 'remote', label: 'Remote'),
                      AppDropdownItem<String>(
                        value: 'workshop',
                        label: 'Workshop',
                      ),
                    ],
                    initialValue: executionMode,
                    onChanged: (value) =>
                        setState(() => executionMode = value ?? 'onsite'),
                  ),
                  AppDropdownField<int?>.fromMapped(
                    labelText: 'Technician',
                    mappedItems: [
                      const AppDropdownItem<int?>(value: null, label: '-'),
                      ..._viewModel.users
                          .where((u) => u.id != null)
                          .map(
                            (u) => AppDropdownItem<int?>(
                              value: u.id!,
                              label: u.toString(),
                            ),
                          ),
                    ],
                    initialValue: technicianUserId,
                    onChanged: (value) =>
                        setState(() => technicianUserId = value),
                  ),
                  AppFormTextField(
                    labelText: 'Diagnosis notes',
                    controller: diagnosisCtrl,
                    maxLines: 3,
                  ),
                  AppFormTextField(
                    labelText: 'Action taken',
                    controller: actionCtrl,
                    maxLines: 2,
                  ),
                  AppFormTextField(
                    labelText: 'Resolution summary',
                    controller: resolutionCtrl,
                    maxLines: 2,
                  ),
                  AppFormTextField(
                    labelText: 'Remarks',
                    controller: remarksCtrl,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, <String, dynamic>{
                  'document_series_id': ?seriesId,
                  'work_order_date': dateCtrl.text.trim(),
                  'execution_mode': executionMode,
                  'technician_user_id': ?technicianUserId,
                  'diagnosis_notes': nullIfEmpty(diagnosisCtrl.text),
                  'action_taken': nullIfEmpty(actionCtrl.text),
                  'resolution_summary': nullIfEmpty(resolutionCtrl.text),
                  'remarks': nullIfEmpty(remarksCtrl.text),
                }),
                child: const Text('Create'),
              ),
            ],
          ),
        );
      },
    );
    dateCtrl.dispose();
    diagnosisCtrl.dispose();
    actionCtrl.dispose();
    resolutionCtrl.dispose();
    remarksCtrl.dispose();
    if (body == null || !mounted) {
      return;
    }
    await _viewModel.createWorkOrderFromClaim(body: body);
    _snack();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WarrantyClaimViewModel>(
      tag: _controllerTag,
      builder: (_) {
        final isDesktop = Responsive.isDesktop(context);
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: _viewModel.loading
                ? null
                : () {
                    _viewModel.resetDraft();
                    if (widget.editorOnly || !isDesktop) {
                      _openRoute('/service/warranty-claims/new');
                    }
                    if (!isDesktop) {
                      _workspaceController.openEditor();
                    }
                  },
            icon: Icons.add_outlined,
            label: 'New warranty claim',
          ),
        ];
        final content = _buildContent(context);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Warranty claims',
          scrollController: _pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_viewModel.loading) {
      return const AppLoadingView(message: 'Loading warranty claims...');
    }
    if (_viewModel.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load warranty claims',
        message: _viewModel.pageError!,
        onRetry: () => _viewModel.load(selectId: widget.initialId),
      );
    }
    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Warranty claims',
      editorTitle: _viewModel.selected == null
          ? 'New warranty claim'
          : _claimListTitle(_viewModel.selected!),
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: SettingsListCard<ServiceTicketModel>(
        searchController: _viewModel.searchController,
        searchHint: 'Search ticket no., title, customer, status',
        items: _viewModel.filteredRows,
        selectedItem: _viewModel.selected,
        emptyMessage: 'No warranty claims found.',
        itemBuilder: (row, selected) {
          final data = row.toJson();
          return SettingsListTile(
            title: _claimListTitle(row),
            subtitle: [
              displayDate(nullableStringValue(data, 'ticket_date')),
              _viewModel.customerLabelFor(data),
              stringValue(data, 'ticket_status'),
            ].where((v) => v.trim().isNotEmpty).join(' · '),
            selected: selected,
            onTap: () async {
              await _viewModel.select(row);
              if (!context.mounted) {
                return;
              }
              if (!Responsive.isDesktop(context)) {
                _workspaceController.openEditor();
              }
            },
          );
        },
      ),
      editor: _WarrantyClaimEditor(
        vm: _viewModel,
        onSave: (formContext) async {
          if (!Form.of(formContext).validate()) {
            return;
          }
          await _viewModel.save();
          _snack();
        },
        onAssign: _assign,
        onResolve: () async {
          await _viewModel.resolveClaim();
          _snack();
        },
        onClose: () async {
          await _viewModel.closeClaim();
          _snack();
        },
        onCancelClaim: () async {
          await _viewModel.cancelClaim();
          _snack();
        },
        onDelete: () async {
          final shouldNavigateBack =
              widget.editorOnly || !Responsive.isDesktop(context);
          await _viewModel.deleteClaim();
          _snack();
          if (shouldNavigateBack) {
            _openRoute('/service/warranty-claims');
          }
        },
        onCreateWorkOrder: _createWo,
      ),
    );
  }
}

class _WarrantyClaimEditor extends StatelessWidget {
  const _WarrantyClaimEditor({
    required this.vm,
    required this.onSave,
    required this.onAssign,
    required this.onResolve,
    required this.onClose,
    required this.onCancelClaim,
    required this.onDelete,
    required this.onCreateWorkOrder,
  });

  final WarrantyClaimViewModel vm;
  final Future<void> Function(BuildContext formContext) onSave;
  final Future<void> Function() onAssign;
  final Future<void> Function() onResolve;
  final Future<void> Function() onClose;
  final Future<void> Function() onCancelClaim;
  final Future<void> Function() onDelete;
  final Future<void> Function() onCreateWorkOrder;

  @override
  Widget build(BuildContext context) {
    if (vm.detailLoading) {
      return const AppLoadingView(message: 'Loading document...');
    }

    final edit = vm.canEdit;

    return Form(
      child: Builder(
        builder: (formContext) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (vm.formError != null) ...[
                AppErrorStateView.inline(message: vm.formError!),
                const SizedBox(height: AppUiConstants.spacingSm),
              ],
              SettingsFormWrap(
                children: [
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Customer',
                    doctypeLabel: 'Customer',
                    allowCreate: true,
                    onNavigateToCreateNew: (name) {
                      final uri = Uri(
                        path: '/parties',
                        queryParameters: {
                          'new': '1',
                          if (name.trim().isNotEmpty) 'party_name': name.trim(),
                        },
                      );
                      final navigate = ShellRouteScope.maybeOf(context);
                      if (navigate != null) {
                        navigate(uri.toString());
                      } else {
                        Navigator.of(context).pushNamed(uri.toString());
                      }
                    },
                    mappedItems: vm.parties
                        .where((p) => p.id != null)
                        .map(
                          (p) => AppDropdownItem<int>(
                            value: p.id!,
                            label: p.toString(),
                          ),
                        )
                        .toList(growable: false),
                    initialValue: vm.customerPartyId,
                    onChanged: (int? v) {
                      if (edit) {
                        vm.setCustomerPartyId(v);
                      }
                    },
                    validator: Validators.requiredSelection('Customer'),
                  ),
                  AppFormTextField(
                    labelText: 'Ticket no. (optional if series set)',
                    controller: vm.ticketNoController,
                    enabled: edit,
                  ),
                  DocumentSeriesSelector<int?>(
                    labelText: 'Document series',
                    mappedItems: [
                      const AppDropdownItem<int?>(value: null, label: '-'),
                      ...vm.ticketSeriesOptions
                          .where((s) => s.id != null)
                          .map(
                            (s) => AppDropdownItem<int?>(
                              value: s.id!,
                              label: s.toString(),
                            ),
                          ),
                    ],
                    initialValue: vm.documentSeriesId,
                    onChanged: (int? v) {
                      if (edit) {
                        vm.setDocumentSeriesId(v);
                      }
                    },
                  ),
                  AppDateField(
                    labelText: 'Ticket date',
                    controller: vm.ticketDateController,
                    enabled: edit,
                    validator: Validators.required('Ticket date'),
                  ),
                  AppSearchPickerField<int>(
                    labelText: 'Item',
                    selectedLabel: vm.selectedItem?.toString(),
                    options: vm.itemOptions
                        .where((item) => item.id != null)
                        .map(
                          (item) => AppSearchPickerOption<int>(
                            value: item.id!,
                            label: item.toString(),
                            subtitle: item.itemCode,
                          ),
                        )
                        .toList(growable: false),
                    validator: (_) =>
                        vm.itemId == null ? 'Item is required' : null,
                    onChanged: edit ? vm.setItemId : (_) {},
                  ),
                  AppSearchPickerField<int>(
                    labelText: 'Serial (optional)',
                    selectedLabel: vm.selectedSerial?.toString(),
                    options: vm.serialOptions
                        .where((serial) => serial.id != null)
                        .map(
                          (serial) => AppSearchPickerOption<int>(
                            value: serial.id!,
                            label: serial.toString(),
                            subtitle: serial.status,
                          ),
                        )
                        .toList(growable: false),
                    onChanged: edit ? vm.setSerialId : (_) {},
                  ),
                  AppDropdownField<int?>.fromMapped(
                    labelText: 'Warranty contract (optional)',
                    mappedItems: [
                      const AppDropdownItem<int?>(value: null, label: '-'),
                      ...vm.contractOptions.map(
                        (contract) => AppDropdownItem<int?>(
                          value: contract.id!,
                          label: contract.toString(),
                        ),
                      ),
                    ],
                    initialValue: vm.serviceContractId,
                    onChanged: (value) {
                      if (edit) {
                        unawaited(vm.setServiceContractId(value));
                      }
                    },
                  ),
                  AppDropdownField<int?>.fromMapped(
                    labelText: 'Warranty asset (optional)',
                    mappedItems: [
                      const AppDropdownItem<int?>(value: null, label: '-'),
                      ...vm.contractAssetOptions.map(
                        (asset) => AppDropdownItem<int?>(
                          value: asset.id!,
                          label: asset.toString(),
                        ),
                      ),
                    ],
                    initialValue: vm.serviceContractAssetId,
                    onChanged: (value) {
                      if (edit) {
                        vm.setServiceContractAssetId(value);
                      }
                    },
                  ),
                  AppFormTextField(
                    labelText: 'Issue title (optional)',
                    controller: vm.issueTitleController,
                    enabled: edit,
                  ),
                  AppFormTextField(
                    labelText: 'Issue description',
                    controller: vm.issueDescriptionController,
                    enabled: edit,
                    maxLines: 3,
                  ),
                  AppDropdownField<String>.fromMapped(
                    labelText: 'Priority',
                    mappedItems: const [
                      AppDropdownItem<String>(value: 'low', label: 'Low'),
                      AppDropdownItem<String>(value: 'normal', label: 'Normal'),
                      AppDropdownItem<String>(value: 'high', label: 'High'),
                      AppDropdownItem<String>(
                        value: 'critical',
                        label: 'Critical',
                      ),
                    ],
                    initialValue: vm.priorityController.text.trim().isEmpty
                        ? 'normal'
                        : vm.priorityController.text.trim(),
                    onChanged: (value) {
                      if (edit) {
                        vm.priorityController.text = value ?? 'normal';
                      }
                    },
                  ),
                  AppDropdownField<int?>.fromMapped(
                    labelText: 'Branch (optional)',
                    mappedItems: [
                      const AppDropdownItem<int?>(value: null, label: '-'),
                      ...vm.branchOptions
                          .where((b) => b.id != null)
                          .map(
                            (b) => AppDropdownItem<int?>(
                              value: b.id!,
                              label: b.toString(),
                            ),
                          ),
                    ],
                    initialValue: vm.branchId,
                    onChanged: (int? v) {
                      if (edit) {
                        vm.setBranchId(v);
                      }
                    },
                  ),
                  AppDropdownField<int?>.fromMapped(
                    labelText: 'Location (optional)',
                    mappedItems: [
                      const AppDropdownItem<int?>(value: null, label: '-'),
                      ...vm.locationOptions
                          .where((l) => l.id != null)
                          .map(
                            (l) => AppDropdownItem<int?>(
                              value: l.id!,
                              label: l.toString(),
                            ),
                          ),
                    ],
                    initialValue: vm.locationId,
                    onChanged: (int? v) {
                      if (edit) {
                        vm.setLocationId(v);
                      }
                    },
                  ),
                  AppFormTextField(
                    labelText: 'Contact person',
                    controller: vm.contactPersonController,
                    enabled: edit,
                  ),
                  AppFormTextField(
                    labelText: 'Contact mobile',
                    controller: vm.contactMobileController,
                    enabled: edit,
                  ),
                  AppFormTextField(
                    labelText: 'Contact email',
                    controller: vm.contactEmailController,
                    enabled: edit,
                  ),
                  AppFormTextField(
                    labelText: 'Notes',
                    controller: vm.notesController,
                    enabled: edit,
                    maxLines: 2,
                  ),
                  if (vm.selected != null)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppUiConstants.spacingSm,
                        bottom: AppUiConstants.spacingSm,
                      ),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(vm.ticketStatus),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppUiConstants.spacingMd),
              Wrap(
                spacing: AppUiConstants.spacingSm,
                runSpacing: AppUiConstants.spacingSm,
                children: [
                  AppActionButton(
                    icon: Icons.save_outlined,
                    label: vm.selected == null ? 'Save' : 'Update',
                    busy: vm.saving,
                    onPressed: edit ? () => onSave(formContext) : null,
                  ),
                  if (vm.canAssign)
                    AppActionButton(
                      icon: Icons.person_add_alt_outlined,
                      label: 'Assign',
                      filled: false,
                      onPressed: vm.saving ? null : () => onAssign(),
                    ),
                  if (vm.canResolve)
                    AppActionButton(
                      icon: Icons.check_circle_outline,
                      label: 'Resolve',
                      filled: false,
                      onPressed: vm.saving ? null : () => onResolve(),
                    ),
                  if (vm.canClose)
                    AppActionButton(
                      icon: Icons.door_front_door_outlined,
                      label: 'Close',
                      filled: false,
                      onPressed: vm.saving ? null : () => onClose(),
                    ),
                  if (vm.canCancel)
                    AppActionButton(
                      icon: Icons.cancel_outlined,
                      label: 'Cancel claim',
                      filled: false,
                      onPressed: vm.saving ? null : () => onCancelClaim(),
                    ),
                  AppActionButton(
                    icon: vm.hasWorkOrder
                        ? Icons.check_circle_outline
                        : Icons.build_circle_outlined,
                    label: vm.workOrderButtonLabel,
                    filled: false,
                    busy: vm.actionBusy,
                    onPressed:
                        vm.selected == null ||
                            vm.saving ||
                            vm.actionBusy ||
                            vm.hasWorkOrder
                        ? null
                        : () => onCreateWorkOrder(),
                  ),
                  if (vm.canDelete)
                    AppActionButton(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      filled: false,
                      onPressed: vm.saving ? null : () => onDelete(),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
