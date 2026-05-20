import '../../../screen.dart';

class EmailMessagesManagementController extends GetxController {
  EmailMessagesManagementController();

  final CommunicationService _communicationService = CommunicationService();
  final MasterService _masterService = MasterService();
  final ScrollController pageScrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();

  bool initialLoading = true;
  bool sending = false;
  String? pageError;
  int? contextCompanyId;
  List<AppDropdownItem<String>> documentTypeItems = const [
    AppDropdownItem(value: '', label: 'All'),
  ];
  List<EmailMessageModel> messages = const <EmailMessageModel>[];
  List<EmailMessageModel> filteredMessages = const <EmailMessageModel>[];
  EmailMessageModel? selectedMessage;
  bool composerLaunched = false;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_applySearch);
    loadPage();
  }

  @override
  void onClose() {
    pageScrollController.dispose();
    searchController
      ..removeListener(_applySearch)
      ..dispose();
    super.onClose();
  }

  String errorMessage(Object error) {
    if (error is ApiException) {
      return error.displayMessage;
    }
    if (error is ApiResponse) {
      return error.message;
    }
    return error.toString();
  }

  Future<void> loadPage({int? selectId}) async {
    initialLoading = messages.isEmpty;
    pageError = null;
    update();

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

      final companies = companiesResponse.data ?? const <CompanyModel>[];
      final documentTypes =
          (documentSeriesResponse.data ?? const <DocumentSeriesModel>[])
              .map((item) => (item.documentType ?? '').trim())
              .where((item) => item.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
      final nextMessages = messagesResponse.data ?? const <EmailMessageModel>[];
      final activeCompanies = companies
          .where((item) => item.isActive)
          .toList(growable: false);
      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: activeCompanies,
            branches: const <BranchModel>[],
            locations: const <BusinessLocationModel>[],
            financialYears: const <FinancialYearModel>[],
          );

      contextCompanyId = contextSelection.companyId;
      documentTypeItems = [
        const AppDropdownItem(value: '', label: 'All'),
        ...documentTypes.map(
          (item) => AppDropdownItem(value: item, label: item),
        ),
      ];
      messages = nextMessages;
      filteredMessages = filterMessages(nextMessages, searchController.text);
      initialLoading = false;

      final selected = selectId != null
          ? nextMessages.cast<EmailMessageModel?>().firstWhere(
              (item) => intValue(item?.toJson() ?? const {}, 'id') == selectId,
              orElse: () => null,
            )
          : (selectedMessage == null
                ? (nextMessages.isNotEmpty ? nextMessages.first : null)
                : nextMessages.cast<EmailMessageModel?>().firstWhere(
                    (item) =>
                        intValue(item?.toJson() ?? const {}, 'id') ==
                        intValue(selectedMessage?.toJson() ?? const {}, 'id'),
                    orElse: () =>
                        nextMessages.isNotEmpty ? nextMessages.first : null,
                  ));

      selectedMessage = selected;
    } catch (errorValue) {
      initialLoading = false;
      pageError = errorMessage(errorValue);
    }

    update();
  }

  List<EmailMessageModel> filterMessages(
    List<EmailMessageModel> items,
    String query,
  ) {
    return filterMasterList(items, query, (message) {
      final data = message.toJson();
      return [
        stringValue(data, 'subject'),
        stringValue(data, 'status'),
        stringValue(data, 'module'),
        stringValue(data, 'to_emails'),
      ];
    });
  }

  void _applySearch() {
    filteredMessages = filterMessages(messages, searchController.text);
    update();
  }

  void selectMessage(EmailMessageModel? value) {
    selectedMessage = value;
    update();
  }

  void markComposerLaunched() {
    composerLaunched = true;
  }

  Future<void> sendEmail({
    required BuildContext context,
    required String module,
    required String documentType,
    required String documentId,
    required String eventCode,
    required String to,
    required String cc,
    required String bcc,
    required String subject,
    required String body,
    required bool isHtml,
  }) async {
    sending = true;
    update();

    try {
      final response = await _communicationService.sendEmail(
        EmailMessageModel.fromJson({
          if (contextCompanyId != null) 'company_id': contextCompanyId,
          'module': module.trim(),
          'document_type': nullIfEmpty(documentType),
          'document_id': int.tryParse(documentId.trim()),
          'event_code': nullIfEmpty(eventCode),
          'to': to.trim(),
          'cc': nullIfEmpty(cc),
          'bcc': nullIfEmpty(bcc),
          'subject': subject.trim(),
          'body': body.trim(),
          'is_html': isHtml,
        }),
      );
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadPage(
        selectId: intValue(response.data?.toJson() ?? const {}, 'id'),
      );
    } catch (errorValue) {
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(errorMessage(errorValue))),
      );
    } finally {
      sending = false;
      update();
    }
  }
}
