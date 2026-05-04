import '../../screen.dart';
import '../../view_model/service/warranty_claim_view_model.dart';
import '../purchase/purchase_support.dart';
import 'service_assign_prompt.dart';

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
  late final WarrantyClaimViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = WarrantyClaimViewModel()..load(selectId: widget.initialId);
  }

  @override
  void dispose() {
    _viewModel.dispose();
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
    final result = await promptServiceAssigneeUserId(context);
    if (!mounted || !result.submitted) {
      return;
    }
    await _viewModel.assignClaim(assignedToUserId: result.assignedToUserId);
    _snack();
  }

  Future<void> _createWo() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create work order'),
        content: const Text(
          'Create a service work order from this claim using server defaults?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }
    await _viewModel.createWorkOrderFromClaim();
    _snack();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: _viewModel.loading
                ? null
                : () {
                    _viewModel.resetDraft();
                    _openRoute('/service/warranty-claims/new');
                    if (!Responsive.isDesktop(context)) {
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
          await _viewModel.deleteClaim();
          _snack();
          _openRoute('/service/warranty-claims');
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
                    labelText: 'Company',
                    mappedItems: vm.companies
                        .where((c) => c.id != null)
                        .map(
                          (c) => AppDropdownItem<int>(
                            value: c.id!,
                            label: c.toString(),
                          ),
                        )
                        .toList(growable: false),
                    initialValue: vm.companyId,
                    onChanged: (int? v) {
                      if (edit) {
                        vm.setCompanyId(v);
                      }
                    },
                    validator: Validators.requiredSelection('Company'),
                  ),
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Customer',
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
                  AppDropdownField<int?>.fromMapped(
                    labelText: 'Document series',
                    mappedItems: [
                      const AppDropdownItem<int?>(
                        value: null,
                        label: '—',
                      ),
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
                  AppFormTextField(
                    labelText: 'Ticket date',
                    controller: vm.ticketDateController,
                    enabled: edit,
                    validator: Validators.required('Ticket date'),
                  ),
                  AppFormTextField(
                    labelText: 'Item id',
                    controller: vm.itemIdController,
                    enabled: edit,
                    keyboardType: TextInputType.number,
                    validator: Validators.compose([
                      Validators.required('Item id'),
                      (v) {
                        if (int.tryParse((v ?? '').trim()) == null) {
                          return 'Enter a valid item id';
                        }
                        return null;
                      },
                    ]),
                  ),
                  AppFormTextField(
                    labelText: 'Serial id (optional)',
                    controller: vm.serialIdController,
                    enabled: edit,
                    keyboardType: TextInputType.number,
                  ),
                  AppFormTextField(
                    labelText: 'Service contract asset id (optional)',
                    controller: vm.contractAssetIdController,
                    enabled: edit,
                    keyboardType: TextInputType.number,
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
                  AppFormTextField(
                    labelText: 'Priority',
                    controller: vm.priorityController,
                    enabled: edit,
                  ),
                  AppDropdownField<int?>.fromMapped(
                    labelText: 'Branch (optional)',
                    mappedItems: [
                      const AppDropdownItem<int?>(
                        value: null,
                        label: '—',
                      ),
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
                      const AppDropdownItem<int?>(
                        value: null,
                        label: '—',
                      ),
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
                  AppDropdownField<int?>.fromMapped(
                    labelText: 'Financial year (optional)',
                    mappedItems: [
                      const AppDropdownItem<int?>(
                        value: null,
                        label: '—',
                      ),
                      ...vm.financialYearOptions
                          .where((f) => f.id != null)
                          .map(
                            (f) => AppDropdownItem<int?>(
                              value: f.id!,
                              label: f.toString(),
                            ),
                          ),
                    ],
                    initialValue: vm.financialYearId,
                    onChanged: (int? v) {
                      if (edit) {
                        vm.setFinancialYearId(v);
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
                    icon: Icons.build_circle_outlined,
                    label: 'Create work order',
                    filled: false,
                    busy: vm.actionBusy,
                    onPressed: vm.selected == null || vm.saving || vm.actionBusy
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
