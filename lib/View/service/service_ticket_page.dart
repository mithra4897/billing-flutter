import '../../screen.dart';
import '../../view_model/service/service_ticket_view_model.dart';
import '../purchase/purchase_support.dart';
import 'service_assign_prompt.dart';

String _ticketListTitle(ServiceTicketModel row) {
  final data = row.toJson();
  final no = stringValue(data, 'ticket_no');
  if (no.isNotEmpty) {
    return no;
  }
  final id = intValue(data, 'id');
  return id != null ? 'Ticket #$id' : 'Ticket';
}

class ServiceTicketPage extends StatefulWidget {
  const ServiceTicketPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<ServiceTicketPage> createState() => _ServiceTicketPageState();
}

class _ServiceTicketPageState extends State<ServiceTicketPage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  late final ServiceTicketViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ServiceTicketViewModel()..load(selectId: widget.initialId);
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
    await _viewModel.assignTicket(assignedToUserId: result.assignedToUserId);
    _snack();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final isDesktop = Responsive.isDesktop(context);
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: _viewModel.loading
                ? null
                : () {
                    _viewModel.resetDraft();
                    if (widget.editorOnly || !isDesktop) {
                      _openRoute('/service/tickets/new');
                    }
                    if (!isDesktop) {
                      _workspaceController.openEditor();
                    }
                  },
            icon: Icons.add_outlined,
            label: 'New ticket',
          ),
        ];
        final content = _buildContent(context);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Service tickets',
          scrollController: _pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_viewModel.loading) {
      return const AppLoadingView(message: 'Loading tickets...');
    }
    if (_viewModel.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load tickets',
        message: _viewModel.pageError!,
        onRetry: () => _viewModel.load(selectId: widget.initialId),
      );
    }
    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Service tickets',
      editorTitle: _viewModel.selected == null
          ? 'New ticket'
          : _ticketListTitle(_viewModel.selected!),
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: SettingsListCard<ServiceTicketModel>(
        searchController: _viewModel.searchController,
        searchHint: 'Search ticket no., title, customer, status',
        items: _viewModel.filteredRows,
        selectedItem: _viewModel.selected,
        emptyMessage: 'No service tickets found.',
        itemBuilder: (row, selected) {
          final data = row.toJson();
          return SettingsListTile(
            title: _ticketListTitle(row),
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
      editor: _ServiceTicketEditor(
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
          await _viewModel.resolveTicket();
          _snack();
        },
        onClose: () async {
          await _viewModel.closeTicket();
          _snack();
        },
        onCancelTicket: () async {
          await _viewModel.cancelTicket();
          _snack();
        },
        onDelete: () async {
          final shouldNavigateBack =
              widget.editorOnly || !Responsive.isDesktop(context);
          await _viewModel.deleteTicket();
          _snack();
          if (shouldNavigateBack) {
            _openRoute('/service/tickets');
          }
        },
      ),
    );
  }
}

class _ServiceTicketEditor extends StatelessWidget {
  const _ServiceTicketEditor({
    required this.vm,
    required this.onSave,
    required this.onAssign,
    required this.onResolve,
    required this.onClose,
    required this.onCancelTicket,
    required this.onDelete,
  });

  final ServiceTicketViewModel vm;
  final Future<void> Function(BuildContext formContext) onSave;
  final Future<void> Function() onAssign;
  final Future<void> Function() onResolve;
  final Future<void> Function() onClose;
  final Future<void> Function() onCancelTicket;
  final Future<void> Function() onDelete;

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
                    labelText: 'Issue title',
                    controller: vm.issueTitleController,
                    enabled: edit,
                    validator: Validators.required('Issue title'),
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
                    labelText: 'Item id (optional)',
                    controller: vm.itemIdController,
                    enabled: edit,
                    keyboardType: TextInputType.number,
                  ),
                  AppFormTextField(
                    labelText: 'Serial id (optional)',
                    controller: vm.serialIdController,
                    enabled: edit,
                    keyboardType: TextInputType.number,
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
                      label: 'Cancel ticket',
                      filled: false,
                      onPressed: vm.saving ? null : () => onCancelTicket(),
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
