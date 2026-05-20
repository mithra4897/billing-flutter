import '../../../controller/settings/communication/email_messages_management_controller.dart';
import '../../../screen.dart';

class EmailMessagesPage extends StatefulWidget {
  const EmailMessagesPage({
    super.key,
    this.embedded = false,
    this.openSendComposerOnInit = false,
  });

  final bool embedded;
  final bool openSendComposerOnInit;

  @override
  State<EmailMessagesPage> createState() => _EmailMessagesPageState();
}

class _EmailMessagesPageState extends State<EmailMessagesPage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'EmailMessagesManagementController',
    );
    Get.put(EmailMessagesManagementController(), tag: _controllerTag);
  }

  String get _pageTitle =>
      widget.openSendComposerOnInit ? 'Send Email' : 'Email Messages';

  Future<void> _openSendDialog(
    BuildContext pageContext,
    EmailMessagesManagementController controller,
  ) async {
    final moduleController = TextEditingController();
    final documentTypeController = TextEditingController();
    final documentIdController = TextEditingController();
    final eventCodeController = TextEditingController();
    final toController = TextEditingController();
    final ccController = TextEditingController();
    final bccController = TextEditingController();
    final subjectController = TextEditingController();
    final bodyController = TextEditingController();
    final isHtmlNotifier = ValueNotifier<bool>(true);
    final formKey = GlobalKey<FormState>();

    final dialogContext = appNavigatorKey.currentContext ?? pageContext;

    final result = await showDialog<bool>(
      context: dialogContext,
      builder: (context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.all(24),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Form(
              key: formKey,
              child: StatefulBuilder(
                builder: (context, setLocalState) {
                  return SingleChildScrollView(
                    child: SettingsFormWrap(
                      children: [
                        AppFormTextField(
                          labelText: 'Module',
                          controller: moduleController,
                          validator: Validators.required('Module'),
                        ),
                        AppDropdownField<String>.fromMapped(
                          labelText: 'Document Type',
                          mappedItems: controller.documentTypeItems,
                          initialValue: '',
                          onChanged: (value) =>
                              documentTypeController.text = value ?? '',
                        ),
                        AppFormTextField(
                          labelText: 'Document Id',
                          controller: documentIdController,
                          keyboardType: TextInputType.number,
                        ),
                        AppFormTextField(
                          labelText: 'Event Code',
                          controller: eventCodeController,
                        ),
                        AppFormTextField(
                          labelText: 'To',
                          controller: toController,
                          validator: Validators.required('To'),
                        ),
                        AppFormTextField(
                          labelText: 'CC',
                          controller: ccController,
                        ),
                        AppFormTextField(
                          labelText: 'BCC',
                          controller: bccController,
                        ),
                        AppFormTextField(
                          labelText: 'Subject',
                          controller: subjectController,
                          validator: Validators.required('Subject'),
                        ),
                        AppFormTextField(
                          labelText: 'Body',
                          controller: bodyController,
                          maxLines: 10,
                          validator: Validators.required('Body'),
                        ),
                        ValueListenableBuilder<bool>(
                          valueListenable: isHtmlNotifier,
                          builder: (context, isHtml, _) {
                            return AppSwitchTile(
                              label: 'HTML Email',
                              value: isHtml,
                              onChanged: (value) =>
                                  isHtmlNotifier.value = value,
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () async {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                Navigator.of(context).pop(true);
                await controller.sendEmail(
                  context: pageContext,
                  module: moduleController.text,
                  documentType: documentTypeController.text,
                  documentId: documentIdController.text,
                  eventCode: eventCodeController.text,
                  to: toController.text,
                  cc: ccController.text,
                  bcc: bccController.text,
                  subject: subjectController.text,
                  body: bodyController.text,
                  isHtml: isHtmlNotifier.value,
                );
              },
              icon: const Icon(Icons.send_outlined),
              label: const Text('Send Email'),
            ),
          ],
        );
      },
    );

    moduleController.dispose();
    documentTypeController.dispose();
    documentIdController.dispose();
    eventCodeController.dispose();
    toController.dispose();
    ccController.dispose();
    bccController.dispose();
    subjectController.dispose();
    bodyController.dispose();
    isHtmlNotifier.dispose();

    if (result == null) {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<EmailMessagesManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        if (widget.openSendComposerOnInit &&
            !controller.initialLoading &&
            !controller.composerLaunched) {
          controller.markComposerLaunched();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _openSendDialog(context, controller);
            }
          });
        }

        final content = _buildContent(context, controller);
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: controller.sending
                ? null
                : () => _openSendDialog(context, controller),
            icon: Icons.send_outlined,
            label: 'Send Email',
          ),
        ];

        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }

        return AppStandaloneShell(
          title: _pageTitle,
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    EmailMessagesManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading email messages...');
    }

    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load email messages',
        message: controller.pageError!,
        onRetry: controller.loadPage,
      );
    }

    if (widget.openSendComposerOnInit) {
      return AppSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Send Email', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppUiConstants.spacingSm),
            Text(
              'Compose and send an email from this route-first page.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppUiConstants.spacingLg),
            AppActionButton(
              onPressed: controller.sending
                  ? null
                  : () => _openSendDialog(context, controller),
              icon: Icons.send_outlined,
              label: 'Open Composer',
              busy: controller.sending,
            ),
          ],
        ),
      );
    }

    final selectedData =
        controller.selectedMessage?.toJson() ?? const <String, dynamic>{};

    return SettingsWorkspace(
      title: _pageTitle,
      editorTitle: controller.selectedMessage?.toString(),
      scrollController: controller.pageScrollController,
      list: SettingsListCard<EmailMessageModel>(
        searchController: controller.searchController,
        searchHint: 'Search email messages',
        items: controller.filteredMessages,
        selectedItem: controller.selectedMessage,
        emptyMessage: 'No email messages found.',
        itemBuilder: (message, selected) {
          final data = message.toJson();
          return SettingsListTile(
            title: stringValue(data, 'subject', 'Message'),
            subtitle: [
              stringValue(data, 'module'),
              stringValue(data, 'status'),
              stringValue(data, 'created_at'),
            ].where((value) => value.isNotEmpty).join(' • '),
            selected: selected,
            onTap: () => controller.selectMessage(message),
          );
        },
      ),
      editor: controller.selectedMessage == null
          ? const SettingsEmptyState(
              icon: Icons.mark_email_read_outlined,
              title: 'No email selected',
              message:
                  'Choose an email message from the left to review its recipients, content, and status.',
              minHeight: 280,
            )
          : SettingsFormWrap(
              children: [
                AppFormTextField(
                  width: 320,
                  labelText: 'Subject',
                  initialValue: stringValue(selectedData, 'subject'),
                  readOnly: true,
                ),
                AppFormTextField(
                  width: 320,
                  labelText: 'Status',
                  initialValue: stringValue(selectedData, 'status'),
                  readOnly: true,
                ),
                AppFormTextField(
                  width: 320,
                  labelText: 'Module',
                  initialValue: stringValue(selectedData, 'module'),
                  readOnly: true,
                ),
                AppFormTextField(
                  width: 320,
                  labelText: 'Document Type',
                  initialValue: stringValue(selectedData, 'document_type'),
                  readOnly: true,
                ),
                AppFormTextField(
                  width: 320,
                  labelText: 'To',
                  initialValue: stringValue(selectedData, 'to_emails'),
                  readOnly: true,
                ),
                AppFormTextField(
                  width: 320,
                  labelText: 'CC',
                  initialValue: stringValue(selectedData, 'cc_emails'),
                  readOnly: true,
                ),
                AppFormTextField(
                  width: 320,
                  labelText: 'BCC',
                  initialValue: stringValue(selectedData, 'bcc_emails'),
                  readOnly: true,
                ),
                AppFormTextField(
                  width: 320,
                  labelText: 'Error Message',
                  initialValue: stringValue(selectedData, 'error_message'),
                  readOnly: true,
                ),
                AppFormTextField(
                  width: 660,
                  labelText: 'Body',
                  initialValue: stringValue(selectedData, 'body'),
                  readOnly: true,
                  maxLines: 12,
                ),
              ],
            ),
    );
  }
}
