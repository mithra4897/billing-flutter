import '../../../screen.dart';

class EmailMessagesPage extends StatefulWidget {
  const EmailMessagesPage({super.key, this.embedded = false});

  final bool embedded;

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
  List<CompanyModel> _companies = const <CompanyModel>[];
  List<AppDropdownItem<String>> _documentTypeItems = const [
    AppDropdownItem(value: '', label: 'All'),
  ];
  List<EmailMessageModel> _messages = const <EmailMessageModel>[];
  List<EmailMessageModel> _filteredMessages = const <EmailMessageModel>[];
  EmailMessageModel? _selectedMessage;

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

      setState(() {
        _companies = companies;
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
        _pageError = error.toString();
      });
    }
  }

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
    final companyIdNotifier = ValueNotifier<int?>(null);
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

    final companyItems = <AppDropdownItem<int?>>[
      const AppDropdownItem<int?>(value: null, label: 'All'),
      ..._companies.map(
        (company) => AppDropdownItem<int?>(
          value: company.id,
          label: company.legalName ?? company.code ?? 'Company',
        ),
      ),
    ];

    final result = await showDialog<bool>(
      context: context,
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
                        ValueListenableBuilder<int?>(
                          valueListenable: companyIdNotifier,
                          builder: (context, companyId, _) {
                            return AppDropdownField<int?>.fromMapped(
                              labelText: 'Company',
                              mappedItems: companyItems,
                              initialValue: companyId,
                              onChanged: (value) =>
                                  companyIdNotifier.value = value,
                            );
                          },
                        ),
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
                      if (companyIdNotifier.value != null)
                        'company_id': companyIdNotifier.value,
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
                    SnackBar(content: Text(error.toString())),
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

    companyIdNotifier.dispose();
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
      title: 'Email Messages',
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

    final selectedData = _selectedMessage?.data ?? const <String, dynamic>{};

    return SettingsWorkspace(
      title: 'Message Detail',
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
