import '../../../screen.dart';

class EmailMessagesPage extends StatefulWidget {
  const EmailMessagesPage({
    super.key,
    this.embedded = false,
    this.openSendComposerOnInit = false,
  });

  final bool embedded;

  /// When true (e.g. `/communication/send-email`), opens the send dialog once after the first successful load.
  final bool openSendComposerOnInit;

  @override
  State<EmailMessagesPage> createState() => _EmailMessagesPageState();
}

class _EmailMessagesPageState extends State<EmailMessagesPage> {
  final CommunicationService _communicationService = CommunicationService();
  final MasterService _masterService = MasterService();
  final ScrollController _pageScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  bool _initialLoading = true;
  bool _sending = false;
  String? _pageError;
  int? _contextCompanyId;
  List<AppDropdownItem<String>> _documentTypeItems = const [
    AppDropdownItem(value: '', label: 'All'),
  ];
  List<EmailMessageModel> _messages = const <EmailMessageModel>[];
  List<EmailMessageModel> _filteredMessages = const <EmailMessageModel>[];
  EmailMessageModel? _selectedMessage;

  String _errorMessage(Object error) {
    if (error is ApiException) {
      return error.displayMessage;
    }
    if (error is ApiResponse) {
      return error.message;
    }
    return error.toString();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applySearch);
    _loadPage();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPage({int? selectId}) async {
    setState(() {
      _initialLoading = _messages.isEmpty;
      _pageError = null;
    });

    try {
      final companiesResponse = await _masterService.companies(
        filters: const {'per_page': 100, 'sort_by': 'legal_name'},
      );
      final documentSeriesResponse = await _masterService.documentSeries(
        filters: const {'per_page': 500},
      );
      final messagesResponse = await _communicationService.emailMessages(
        filters: const {'per_page': 100},
      );

      if (!mounted) {
        return;
      }

      final companies = companiesResponse.data ?? const <CompanyModel>[];
      final documentTypes =
          (documentSeriesResponse.data ?? const <DocumentSeriesModel>[])
              .map((item) => (item.documentType ?? '').trim())
              .where((item) => item.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
      final messages = messagesResponse.data ?? const <EmailMessageModel>[];
      final activeCompanies =
          companies.where((item) => item.isActive).toList(growable: false);
      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: activeCompanies,
            branches: const <BranchModel>[],
            locations: const <BusinessLocationModel>[],
            financialYears: const <FinancialYearModel>[],
          );

      setState(() {
        _contextCompanyId = contextSelection.companyId;
        _documentTypeItems = [
          const AppDropdownItem(value: '', label: 'All'),
          ...documentTypes.map(
            (item) => AppDropdownItem(value: item, label: item),
          ),
        ];
        _messages = messages;
        _filteredMessages = _filterMessages(messages, _searchController.text);
        _initialLoading = false;
      });

      final selected = selectId != null
          ? messages.cast<EmailMessageModel?>().firstWhere(
              (item) => intValue(item?.data ?? const {}, 'id') == selectId,
              orElse: () => null,
            )
          : (_selectedMessage == null
                ? (messages.isNotEmpty ? messages.first : null)
                : messages.cast<EmailMessageModel?>().firstWhere(
                    (item) =>
                        intValue(item?.data ?? const {}, 'id') ==
                        intValue(_selectedMessage?.data ?? const {}, 'id'),
                    orElse: () => messages.isNotEmpty ? messages.first : null,
                  ));

      setState(() {
        _selectedMessage = selected;
      });

    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _initialLoading = false;
        _pageError = _errorMessage(error);
      });
    }
  }

  String get _pageTitle =>
      widget.openSendComposerOnInit ? 'Send Email' : 'Email Messages';

  void _applySearch() {
    setState(() {
      _filteredMessages = _filterMessages(_messages, _searchController.text);
    });
  }

  List<EmailMessageModel> _filterMessages(
    List<EmailMessageModel> items,
    String query,
  ) {
    return filterMasterList(items, query, (message) {
      final data = message.data;
      return [
        stringValue(data, 'subject'),
        stringValue(data, 'status'),
        stringValue(data, 'module'),
        stringValue(data, 'to_emails'),
      ];
    });
  }

  Future<void> _openSendDialog() async {
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

    final dialogContext = appNavigatorKey.currentContext ?? context;

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
                          mappedItems: _documentTypeItems,
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

                final scaffoldMessenger = ScaffoldMessenger.of(this.context);
                Navigator.of(context).pop(true);
                setState(() {
                  _sending = true;
                });

                try {
                  final response = await _communicationService.sendEmail(
                    EmailMessageModel({
                      if (_contextCompanyId != null)
                        'company_id': _contextCompanyId,
                      'module': moduleController.text.trim(),
                      'document_type': nullIfEmpty(documentTypeController.text),
                      'document_id': int.tryParse(
                        documentIdController.text.trim(),
                      ),
                      'event_code': nullIfEmpty(eventCodeController.text),
                      'to': toController.text.trim(),
                      'cc': nullIfEmpty(ccController.text),
                      'bcc': nullIfEmpty(bccController.text),
                      'subject': subjectController.text.trim(),
                      'body': bodyController.text.trim(),
                      'is_html': isHtmlNotifier.value,
                    }),
                  );
                  if (!mounted) {
                    return;
                  }
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text(response.message)),
                  );
                  await _loadPage(
                    selectId: intValue(response.data?.data ?? const {}, 'id'),
                  );
                } catch (error) {
                  if (!mounted) {
                    return;
                  }
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text(_errorMessage(error))),
                  );
                } finally {
                  if (mounted) {
                    setState(() {
                      _sending = false;
                    });
                  }
                }
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
    final content = _buildContent(context);
    final actions = <Widget>[
      AdaptiveShellActionButton(
        onPressed: _sending ? null : _openSendDialog,
        icon: Icons.send_outlined,
        label: 'Send Email',
      ),
    ];

    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }

    return AppStandaloneShell(
      title: _pageTitle,
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading email messages...');
    }

    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load email messages',
        message: _pageError!,
        onRetry: _loadPage,
      );
    }

    if (widget.openSendComposerOnInit) {
      return AppSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send Email',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
            Text(
              'Compose and send an email from this route-first page.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppUiConstants.spacingLg),
            AppActionButton(
              onPressed: _sending ? null : _openSendDialog,
              icon: Icons.send_outlined,
              label: 'Open Composer',
              busy: _sending,
            ),
          ],
        ),
      );
    }

    final selectedData = _selectedMessage?.data ?? const <String, dynamic>{};

    return SettingsWorkspace(
      title: _pageTitle,
      editorTitle: _selectedMessage?.toString(),
      scrollController: _pageScrollController,
      list: SettingsListCard<EmailMessageModel>(
        searchController: _searchController,
        searchHint: 'Search email messages',
        items: _filteredMessages,
        selectedItem: _selectedMessage,
        emptyMessage: 'No email messages found.',
        itemBuilder: (message, selected) {
          final data = message.data;
          return SettingsListTile(
            title: stringValue(data, 'subject', 'Message'),
            subtitle: [
              stringValue(data, 'module'),
              stringValue(data, 'status'),
              stringValue(data, 'created_at'),
            ].where((value) => value.isNotEmpty).join(' • '),
            selected: selected,
            onTap: () => setState(() => _selectedMessage = message),
          );
        },
      ),
      editor: _selectedMessage == null
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
