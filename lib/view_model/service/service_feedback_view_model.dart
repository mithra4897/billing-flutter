import 'package:billing/screen.dart';
import 'package:billing/view/hr/hr_workflow_dialogs.dart';
import 'package:billing/view/purchase/purchase_support.dart';

class ServiceFeedbackViewModel extends ChangeNotifier {
  ServiceFeedbackViewModel() {
    searchController.addListener(notifyListeners);
  }

  final ServiceModuleService _service = ServiceModuleService();

  final TextEditingController searchController = TextEditingController();
  final TextEditingController feedbackDateController = TextEditingController();
  final TextEditingController ratingOverallController = TextEditingController();
  final TextEditingController ratingTechnicianController =
      TextEditingController();
  final TextEditingController ratingResolutionController =
      TextEditingController();
  final TextEditingController ratingTimelinessController =
      TextEditingController();
  final TextEditingController customerFeedbackController =
      TextEditingController();

  bool loading = true;
  bool detailLoading = false;
  bool saving = false;
  String? pageError;
  String? formError;
  String? actionMessage;

  List<ServiceFeedbackModel> rows = const <ServiceFeedbackModel>[];
  List<ServiceTicketModel> ticketOptions = const <ServiceTicketModel>[];
  List<ServiceWorkOrderModel> workOrderOptions = const <ServiceWorkOrderModel>[];

  ServiceFeedbackModel? selected;

  int? serviceTicketId;
  int? serviceWorkOrderId;
  int resolutionConfirmed = 0;
  int revisitRequired = 0;

  int? get selectedId =>
      intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');

  List<ServiceFeedbackModel> get filteredRows {
    final q = searchController.text.trim().toLowerCase();
    return rows.where((row) {
      if (q.isEmpty) {
        return true;
      }
      final data = row.toJson();
      final tid = intValue(data, 'service_ticket_id');
      return [
        tid?.toString() ?? '',
        stringValue(data, 'customer_feedback'),
      ].join(' ').toLowerCase().contains(q);
    }).toList(growable: false);
  }

  List<ServiceWorkOrderModel> get workOrdersForTicket {
    final tid = serviceTicketId;
    if (tid == null) {
      return workOrderOptions;
    }
    return workOrderOptions.where((w) {
      return intValue(w.toJson(), 'service_ticket_id') == tid;
    }).toList(growable: false);
  }

  String ticketLabel(ServiceTicketModel t) {
    final d = t.toJson();
    final no = stringValue(d, 'ticket_no');
    final title = stringValue(d, 'issue_title');
    if (no.isNotEmpty && title.isNotEmpty) {
      return '$no · $title';
    }
    if (no.isNotEmpty) {
      return no;
    }
    final id = intValue(d, 'id');
    return id != null ? 'Ticket #$id' : 'Ticket';
  }

  String? consumeActionMessage() {
    final message = actionMessage;
    actionMessage = null;
    return message;
  }

  Future<void> load({int? selectId}) async {
    loading = true;
    pageError = null;
    notifyListeners();
    try {
      final info = await hrSessionCompanyInfo();

      final filters = <String, dynamic>{'per_page': 200};
      if (info.companyId != null) {
        filters['company_id'] = info.companyId;
      }

      final responses = await Future.wait<dynamic>([
        _service.feedbacks(filters: filters),
        _service.tickets(filters: filters),
        _service.workOrders(filters: filters),
      ]);

      rows =
          (responses[0] as PaginatedResponse<ServiceFeedbackModel>).data ??
              const <ServiceFeedbackModel>[];

      ticketOptions =
          (responses[1] as PaginatedResponse<ServiceTicketModel>).data ??
              const <ServiceTicketModel>[];

      workOrderOptions =
          (responses[2] as PaginatedResponse<ServiceWorkOrderModel>).data ??
              const <ServiceWorkOrderModel>[];

      loading = false;

      if (selectId != null) {
        ServiceFeedbackModel? match;
        for (final r in rows) {
          if (intValue(r.toJson(), 'id') == selectId) {
            match = r;
            break;
          }
        }
        if (match != null) {
          await select(match);
          return;
        }
        await select(ServiceFeedbackModel(<String, dynamic>{'id': selectId}));
        return;
      }
      resetDraft();
      notifyListeners();
    } catch (e) {
      pageError = e.toString();
      loading = false;
      notifyListeners();
    }
  }

  void resetDraft() {
    selected = null;
    formError = null;
    serviceTicketId =
        ticketOptions.isNotEmpty ? intValue(ticketOptions.first.toJson(), 'id') : null;
    serviceWorkOrderId = null;
    resolutionConfirmed = 0;
    revisitRequired = 0;
    feedbackDateController.text =
        DateTime.now().toIso8601String().split('T').first;
    ratingOverallController.clear();
    ratingTechnicianController.clear();
    ratingResolutionController.clear();
    ratingTimelinessController.clear();
    customerFeedbackController.clear();
    notifyListeners();
  }

  void setServiceTicketId(int? value) {
    serviceTicketId = value;
    serviceWorkOrderId = null;
    notifyListeners();
  }

  void setServiceWorkOrderId(int? value) {
    serviceWorkOrderId = value;
    notifyListeners();
  }

  void setResolutionConfirmed(int value) {
    resolutionConfirmed = value;
    notifyListeners();
  }

  void setRevisitRequired(int value) {
    revisitRequired = value;
    notifyListeners();
  }

  Future<void> select(ServiceFeedbackModel row) async {
    final id = intValue(row.toJson(), 'id');
    if (id == null) {
      return;
    }
    selected = row;
    detailLoading = true;
    formError = null;
    notifyListeners();
    try {
      final response = await _service.feedback(id);
      final doc = response.data ?? row;
      selected = doc;
      _applyDetail(doc.toJson());
    } catch (e) {
      formError = e.toString();
    } finally {
      detailLoading = false;
      notifyListeners();
    }
  }

  void _applyDetail(Map<String, dynamic> data) {
    serviceTicketId = intValue(data, 'service_ticket_id');
    serviceWorkOrderId = intValue(data, 'service_work_order_id');
    feedbackDateController.text =
        displayDate(nullableStringValue(data, 'feedback_date'));
    ratingOverallController.text =
        _numString(data, 'rating_overall');
    ratingTechnicianController.text =
        _numString(data, 'rating_technician');
    ratingResolutionController.text =
        _numString(data, 'rating_resolution');
    ratingTimelinessController.text =
        _numString(data, 'rating_timeliness');
    customerFeedbackController.text =
        stringValue(data, 'customer_feedback');
    resolutionConfirmed =
        int.tryParse(data['resolution_confirmed']?.toString() ?? '') ?? 0;
    resolutionConfirmed = resolutionConfirmed != 0 ? 1 : 0;
    revisitRequired =
        int.tryParse(data['revisit_required']?.toString() ?? '') ?? 0;
    revisitRequired = revisitRequired != 0 ? 1 : 0;
  }

  String _numString(Map<String, dynamic> data, String key) {
    final v = data[key];
    if (v == null) {
      return '';
    }
    return v.toString();
  }

  String? _validateSave() {
    if (serviceTicketId == null) {
      return 'Service ticket is required.';
    }
    if (feedbackDateController.text.trim().isEmpty) {
      return 'Feedback date is required.';
    }
    return null;
  }

  Map<String, dynamic> _buildPayload() {
    double? p(String s) => double.tryParse(s.trim());

    return <String, dynamic>{
      'service_ticket_id': serviceTicketId,
      if (serviceWorkOrderId != null)
        'service_work_order_id': serviceWorkOrderId,
      'feedback_date': feedbackDateController.text.trim(),
      'rating_overall': p(ratingOverallController.text),
      'rating_technician': p(ratingTechnicianController.text),
      'rating_resolution': p(ratingResolutionController.text),
      'rating_timeliness': p(ratingTimelinessController.text),
      'customer_feedback':
          nullIfEmpty(customerFeedbackController.text),
      'resolution_confirmed': resolutionConfirmed,
      'revisit_required': revisitRequired,
    };
  }

  Future<void> save() async {
    final err = _validateSave();
    if (err != null) {
      formError = err;
      notifyListeners();
      return;
    }
    saving = true;
    formError = null;
    actionMessage = null;
    notifyListeners();
    try {
      if (selected == null) {
        final response = await _service.createFeedback(
          ServiceFeedbackModel(_buildPayload()),
        );
        actionMessage = response.message;
        await load(selectId: intValue(response.data?.toJson() ?? {}, 'id'));
      } else {
        final id = selectedId;
        if (id == null) {
          formError = 'Missing feedback id.';
          notifyListeners();
          return;
        }
        final response = await _service.updateFeedback(
          id,
          ServiceFeedbackModel(_buildPayload()),
        );
        actionMessage = response.message;
        await load(selectId: id);
      }
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> deleteFeedback() async {
    final id = selectedId;
    if (id == null) {
      return;
    }
    try {
      await _service.deleteFeedback(id);
      actionMessage = 'Feedback deleted.';
      await load();
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    feedbackDateController.dispose();
    ratingOverallController.dispose();
    ratingTechnicianController.dispose();
    ratingResolutionController.dispose();
    ratingTimelinessController.dispose();
    customerFeedbackController.dispose();
    super.dispose();
  }
}
