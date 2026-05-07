import '../../screen.dart';
import '../../view_model/service/service_feedback_view_model.dart';
import '../purchase/purchase_support.dart';

String _feedbackListTitle(ServiceFeedbackModel row) {
  final data = row.toJson();
  final id = intValue(data, 'id');
  return id != null ? 'Feedback #$id' : 'Feedback';
}

class ServiceFeedbackPage extends StatefulWidget {
  const ServiceFeedbackPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<ServiceFeedbackPage> createState() => _ServiceFeedbackPageState();
}

class _ServiceFeedbackPageState extends State<ServiceFeedbackPage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  late final ServiceFeedbackViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ServiceFeedbackViewModel()..load(selectId: widget.initialId);
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
                      _openRoute('/service/feedbacks/new');
                    }
                    if (!isDesktop) {
                      _workspaceController.openEditor();
                    }
                  },
            icon: Icons.add_outlined,
            label: 'New feedback',
          ),
        ];
        final content = _buildContent(context);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Service feedbacks',
          scrollController: _pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_viewModel.loading) {
      return const AppLoadingView(message: 'Loading feedbacks...');
    }
    if (_viewModel.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load feedbacks',
        message: _viewModel.pageError!,
        onRetry: () => _viewModel.load(selectId: widget.initialId),
      );
    }
    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Service feedbacks',
      editorTitle: _viewModel.selected == null
          ? 'New feedback'
          : _feedbackListTitle(_viewModel.selected!),
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: SettingsListCard<ServiceFeedbackModel>(
        searchController: _viewModel.searchController,
        searchHint: 'Search ticket id, comments',
        items: _viewModel.filteredRows,
        selectedItem: _viewModel.selected,
        emptyMessage: 'No feedback records found.',
        itemBuilder: (row, selected) {
          final data = row.toJson();
          final ticketId = intValue(data, 'service_ticket_id');
          return SettingsListTile(
            title: _feedbackListTitle(row),
            subtitle: [
              displayDate(nullableStringValue(data, 'feedback_date')),
              if (ticketId != null) 'Ticket #$ticketId',
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
      editor: _ServiceFeedbackEditor(
        vm: _viewModel,
        onSave: (formContext) async {
          if (!Form.of(formContext).validate()) {
            return;
          }
          await _viewModel.save();
          _snack();
        },
        onDelete: () async {
          final shouldNavigateBack =
              widget.editorOnly || !Responsive.isDesktop(context);
          await _viewModel.deleteFeedback();
          _snack();
          if (shouldNavigateBack) {
            _openRoute('/service/feedbacks');
          }
        },
      ),
    );
  }
}

class _ServiceFeedbackEditor extends StatelessWidget {
  const _ServiceFeedbackEditor({
    required this.vm,
    required this.onSave,
    required this.onDelete,
  });

  final ServiceFeedbackViewModel vm;
  final Future<void> Function(BuildContext formContext) onSave;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    if (vm.detailLoading) {
      return const AppLoadingView(message: 'Loading document...');
    }

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
                    labelText: 'Service ticket',
                    mappedItems: vm.ticketOptions
                        .map((t) {
                          final id = intValue(t.toJson(), 'id');
                          if (id == null) {
                            return null;
                          }
                          return AppDropdownItem<int>(
                            value: id,
                            label: vm.ticketLabel(t),
                          );
                        })
                        .whereType<AppDropdownItem<int>>()
                        .toList(growable: false),
                    initialValue: vm.serviceTicketId,
                    onChanged: (int? v) {
                      vm.setServiceTicketId(v);
                    },
                    validator: Validators.requiredSelection('Service ticket'),
                  ),
                  AppDropdownField<int?>.fromMapped(
                    labelText: 'Work order (optional)',
                    mappedItems: [
                      const AppDropdownItem<int?>(
                        value: null,
                        label: '—',
                      ),
                      ...vm.workOrdersForTicket
                          .where((w) => intValue(w.toJson(), 'id') != null)
                          .map(
                            (w) => AppDropdownItem<int?>(
                              value: intValue(w.toJson(), 'id'),
                              label: stringValue(w.toJson(), 'work_order_no')
                                      .isNotEmpty
                                  ? stringValue(w.toJson(), 'work_order_no')
                                  : 'WO #${intValue(w.toJson(), 'id')}',
                            ),
                          ),
                    ],
                    initialValue: vm.serviceWorkOrderId,
                    onChanged: (int? v) {
                      vm.setServiceWorkOrderId(v);
                    },
                  ),
                  AppFormTextField(
                    labelText: 'Feedback date',
                    controller: vm.feedbackDateController,
                    validator: Validators.required('Feedback date'),
                  ),
                  AppFormTextField(
                    labelText: 'Rating overall',
                    controller: vm.ratingOverallController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  AppFormTextField(
                    labelText: 'Rating technician',
                    controller: vm.ratingTechnicianController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  AppFormTextField(
                    labelText: 'Rating resolution',
                    controller: vm.ratingResolutionController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  AppFormTextField(
                    labelText: 'Rating timeliness',
                    controller: vm.ratingTimelinessController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  AppFormTextField(
                    labelText: 'Customer feedback',
                    controller: vm.customerFeedbackController,
                    maxLines: 4,
                  ),
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Resolution confirmed',
                    mappedItems: const [
                      AppDropdownItem<int>(value: 0, label: 'No'),
                      AppDropdownItem<int>(value: 1, label: 'Yes'),
                    ],
                    initialValue: vm.resolutionConfirmed,
                    onChanged: (int? v) {
                      if (v != null) {
                        vm.setResolutionConfirmed(v);
                      }
                    },
                  ),
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Revisit required',
                    mappedItems: const [
                      AppDropdownItem<int>(value: 0, label: 'No'),
                      AppDropdownItem<int>(value: 1, label: 'Yes'),
                    ],
                    initialValue: vm.revisitRequired,
                    onChanged: (int? v) {
                      if (v != null) {
                        vm.setRevisitRequired(v);
                      }
                    },
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
                    onPressed: () => onSave(formContext),
                  ),
                  if (vm.selected != null)
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
