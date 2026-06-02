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
  late final TextEditingController _moduleController;
  late final TextEditingController _documentTypeController;
  late final TextEditingController _documentIdController;
  late final TextEditingController _eventCodeController;
  late final TextEditingController _toController;
  late final TextEditingController _ccController;
  late final TextEditingController _bccController;
  late final TextEditingController _subjectController;
  late final TextEditingController _bodyController;
  late final ValueNotifier<bool> _isHtmlNotifier;
  final GlobalKey<FormState> _composerFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'EmailMessagesManagementController',
    );
    _moduleController = TextEditingController();
    _documentTypeController = TextEditingController();
    _documentIdController = TextEditingController();
    _eventCodeController = TextEditingController();
    _toController = TextEditingController();
    _ccController = TextEditingController();
    _bccController = TextEditingController();
    _subjectController = TextEditingController();
    _bodyController = TextEditingController();
    _isHtmlNotifier = ValueNotifier<bool>(true);
    Get.put(EmailMessagesManagementController(), tag: _controllerTag);
  }

  @override
  void dispose() {
    _moduleController.dispose();
    _documentTypeController.dispose();
    _documentIdController.dispose();
    _eventCodeController.dispose();
    _toController.dispose();
    _ccController.dispose();
    _bccController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    _isHtmlNotifier.dispose();
    super.dispose();
  }

  String get _pageTitle =>
      widget.openSendComposerOnInit ? 'Send Email' : 'Email Messages';

  Future<void> _openSendDialog(
    BuildContext pageContext,
    EmailMessagesManagementController controller,
  ) async {
    final formKey = GlobalKey<FormState>();
    final moduleController = TextEditingController(
      text: _moduleController.text,
    );
    final documentTypeController = TextEditingController(
      text: _documentTypeController.text,
    );
    final documentIdController = TextEditingController(
      text: _documentIdController.text,
    );
    final eventCodeController = TextEditingController(
      text: _eventCodeController.text,
    );
    final toController = TextEditingController(text: _toController.text);
    final ccController = TextEditingController(text: _ccController.text);
    final bccController = TextEditingController(text: _bccController.text);
    final subjectController = TextEditingController(
      text: _subjectController.text,
    );
    final bodyController = TextEditingController(text: _bodyController.text);
    final isHtmlNotifier = ValueNotifier<bool>(_isHtmlNotifier.value);

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
                _copyComposerValues(
                  moduleController: moduleController,
                  documentTypeController: documentTypeController,
                  documentIdController: documentIdController,
                  eventCodeController: eventCodeController,
                  toController: toController,
                  ccController: ccController,
                  bccController: bccController,
                  subjectController: subjectController,
                  bodyController: bodyController,
                  isHtml: isHtmlNotifier.value,
                );
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

  void _copyComposerValues({
    required TextEditingController moduleController,
    required TextEditingController documentTypeController,
    required TextEditingController documentIdController,
    required TextEditingController eventCodeController,
    required TextEditingController toController,
    required TextEditingController ccController,
    required TextEditingController bccController,
    required TextEditingController subjectController,
    required TextEditingController bodyController,
    required bool isHtml,
  }) {
    _moduleController.text = moduleController.text;
    _documentTypeController.text = documentTypeController.text;
    _documentIdController.text = documentIdController.text;
    _eventCodeController.text = eventCodeController.text;
    _toController.text = toController.text;
    _ccController.text = ccController.text;
    _bccController.text = bccController.text;
    _subjectController.text = subjectController.text;
    _bodyController.text = bodyController.text;
    _isHtmlNotifier.value = isHtml;
  }

  Future<void> _sendInlineEmail(
    BuildContext context,
    EmailMessagesManagementController controller,
  ) async {
    if (!_composerFormKey.currentState!.validate()) {
      return;
    }

    await controller.sendEmail(
      context: context,
      module: _moduleController.text,
      documentType: _documentTypeController.text,
      documentId: _documentIdController.text,
      eventCode: _eventCodeController.text,
      to: _toController.text,
      cc: _ccController.text,
      bcc: _bccController.text,
      subject: _subjectController.text,
      body: _bodyController.text,
      isHtml: _isHtmlNotifier.value,
    );
  }

  Widget _buildComposerFields(EmailMessagesManagementController controller) {
    return SettingsFormWrap(
      children: [
        AppFormTextField(
          labelText: 'Module',
          controller: _moduleController,
          validator: Validators.required('Module'),
        ),
        AppDropdownField<String>.fromMapped(
          labelText: 'Document Type',
          mappedItems: controller.documentTypeItems,
          initialValue: _documentTypeController.text,
          onChanged: (value) => _documentTypeController.text = value ?? '',
        ),
        AppFormTextField(
          labelText: 'Document Id',
          controller: _documentIdController,
          keyboardType: TextInputType.number,
        ),
        AppFormTextField(
          labelText: 'Event Code',
          controller: _eventCodeController,
        ),
        AppFormTextField(
          labelText: 'To',
          controller: _toController,
          validator: Validators.required('To'),
        ),
        AppFormTextField(labelText: 'CC', controller: _ccController),
        AppFormTextField(labelText: 'BCC', controller: _bccController),
        AppFormTextField(
          labelText: 'Subject',
          controller: _subjectController,
          validator: Validators.required('Subject'),
        ),
        AppFormTextField(
          labelText: 'Body',
          controller: _bodyController,
          maxLines: 10,
          validator: Validators.required('Body'),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _isHtmlNotifier,
          builder: (context, isHtml, _) {
            return AppSwitchTile(
              label: 'HTML Email',
              value: isHtml,
              onChanged: (value) => _isHtmlNotifier.value = value,
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<EmailMessagesManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = _buildContent(context, controller);
        final actions = <Widget>[
          if (!widget.openSendComposerOnInit)
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
      return SingleChildScrollView(
        controller: controller.pageScrollController,
        child: AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Send Email', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppUiConstants.spacingSm),
              Text(
                'Compose and send an email from this dedicated page.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppUiConstants.spacingLg),
              Form(
                key: _composerFormKey,
                child: _buildComposerFields(controller),
              ),
              const SizedBox(height: AppUiConstants.spacingLg),
              Align(
                alignment: Alignment.centerLeft,
                child: AppActionButton(
                  onPressed: controller.sending
                      ? null
                      : () => _sendInlineEmail(context, controller),
                  icon: Icons.send_outlined,
                  label: 'Send Email',
                  busy: controller.sending,
                ),
              ),
            ],
          ),
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
      editorBuilder: (_) => controller.selectedMessage == null
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
