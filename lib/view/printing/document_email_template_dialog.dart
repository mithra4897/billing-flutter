import '../../screen.dart';

class PrintableDocumentEmailTarget {
  const PrintableDocumentEmailTarget({
    required this.module,
    required this.documentType,
  });

  final String module;
  final String documentType;
}

class PrintableDocumentEmailPayload {
  const PrintableDocumentEmailPayload({
    required this.target,
    required this.title,
    required this.documentId,
    required this.documentData,
    this.companyId,
    this.fileName,
  });

  final PrintableDocumentEmailTarget target;
  final String title;
  final int documentId;
  final DocumentPrintDataModel documentData;
  final int? companyId;
  final String? fileName;
}

const printableDocumentEmailTemplateTypeItems = <AppDropdownItem<String>>[
  AppDropdownItem(value: 'sales_quotation', label: 'Sales Quotation'),
  AppDropdownItem(
    value: 'sales_proforma_invoice',
    label: 'Sales Proforma Invoice',
  ),
  AppDropdownItem(value: 'sales_order', label: 'Sales Order'),
  AppDropdownItem(value: 'sales_delivery', label: 'Sales Delivery'),
  AppDropdownItem(value: 'sales_invoice', label: 'Sales Invoice'),
  AppDropdownItem(value: 'sales_receipt', label: 'Sales Receipt'),
  AppDropdownItem(value: 'purchase_order', label: 'Purchase Order'),
  AppDropdownItem(value: 'purchase_receipt', label: 'Purchase Receipt'),
  AppDropdownItem(value: 'purchase_invoice', label: 'Purchase Invoice'),
  AppDropdownItem(value: 'purchase_payment', label: 'Purchase Payment'),
];

String printableDocumentEmailMissingTemplateMessage(
  PrintableDocumentEmailTarget target,
) {
  final label = printableDocumentEmailTemplateTypeItems
      .where((item) => item.value == target.documentType)
      .map((item) => item.label)
      .firstOrNull;
  return 'No active email template is configured for '
      '${label ?? target.documentType.replaceAll('_', ' ')}.';
}

String printableDocumentEmailFailureMessage(Object error) {
  if (error is ApiException) {
    return error.displayMessage;
  }
  if (error is ApiResponse) {
    return error.message;
  }
  final message = error.toString().trim();
  return message.startsWith('Exception: ')
      ? message.substring('Exception: '.length)
      : message;
}

bool printableDocumentEmailIsMissingTemplateError(Object error) =>
    printableDocumentEmailFailureMessage(
      error,
    ).toLowerCase().contains('no active email template is configured');

Map<String, dynamic> printableDocumentEmailPreviewData(
  DocumentPrintDataModel documentData, {
  int? documentId,
}) {
  final data = documentData.toJson();
  final documentNumber = documentData.documentNumber;
  final totalAmount = documentData.totalAmount;
  return <String, dynamic>{
    ...data,
    'document_id': documentId ?? '',
    'document_no': documentNumber,
    'customer_name': documentData.partyName,
    'supplier_name': documentData.partyName,
    'invoice_number': documentNumber,
    'receipt_number': documentNumber,
    'payment_number': documentNumber,
    'purchase_order_number': documentNumber,
    'grand_total': totalAmount,
    'amount': totalAmount,
  };
}

String printableDocumentEmailPreviewValue(
  String? template,
  DocumentPrintDataModel documentData, {
  int? documentId,
}) => resolvePrintTemplateText(
  template ?? '',
  printableDocumentEmailPreviewData(documentData, documentId: documentId),
);

String _emailTemplatePreviewText(String value) => value
    .replaceAll(RegExp(r'<[^>]+>'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

PrintableDocumentEmailTarget? printableDocumentEmailTarget(
  String printDocumentType,
) {
  const salesTypes = <String>{
    'sales_quotation',
    'sales_proforma_invoice',
    'sales_order',
    'sales_delivery',
    'sales_invoice',
    'sales_receipt',
    'sales_return',
  };
  const purchaseTypes = <String>{
    'purchase_order',
    'purchase_receipt',
    'purchase_invoice',
    'purchase_payment',
    'purchase_return',
  };
  if (salesTypes.contains(printDocumentType)) {
    return PrintableDocumentEmailTarget(
      module: 'sales',
      documentType: printDocumentType,
    );
  }
  if (purchaseTypes.contains(printDocumentType)) {
    return PrintableDocumentEmailTarget(
      module: 'purchase',
      documentType: printDocumentType,
    );
  }
  if (printDocumentType == 'hr_payslip') {
    return const PrintableDocumentEmailTarget(
      module: 'hr',
      documentType: 'payslip',
    );
  }
  return null;
}

Future<EmailTemplateModel?> selectPrintableDocumentEmailTemplate(
  BuildContext context, {
  required PrintableDocumentEmailTarget target,
  int? companyId,
  DocumentPrintDataModel? previewDocumentData,
  int? previewDocumentId,
}) async {
  final response = await CommunicationService().emailTemplates(
    filters: <String, dynamic>{
      'company_id': ?companyId,
      'module': target.module,
      'document_type': target.documentType,
      'is_active': 1,
      'per_page': 100,
    },
  );
  if (!context.mounted) {
    return null;
  }
  if (response.success != true) {
    throw Exception(response.message);
  }

  final templates = (response.data ?? const <EmailTemplateModel>[])
      .where(
        (template) =>
            template.id != null &&
            template.isActive == true &&
            template.module == target.module &&
            template.documentType == target.documentType,
      )
      .toList(growable: false);
  if (templates.isEmpty) {
    throw Exception(printableDocumentEmailMissingTemplateMessage(target));
  }

  EmailTemplateModel? selected = templates.length == 1 ? templates.first : null;
  return showDialog<EmailTemplateModel>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Select email template'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Choose the template to use before sending the PDF.',
                ),
                const SizedBox(height: 12),
                ...templates.map((template) {
                  final isSelected = selected?.id == template.id;
                  return ListTile(
                    selected: isSelected,
                    leading: Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                    ),
                    title: Text(template.templateName ?? template.toString()),
                    subtitle: Text(template.subjectTemplate ?? 'No subject'),
                    onTap: () => setDialogState(() => selected = template),
                  );
                }),
                if (selected != null) ...<Widget>[
                  const Divider(height: 24),
                  Text(
                    'Preview',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  if (previewDocumentData == null)
                    const Text(
                      'The message will be resolved for each selected document.',
                    )
                  else ...<Widget>[
                    Text(
                      printableDocumentEmailPreviewValue(
                        selected!.subjectTemplate,
                        previewDocumentData,
                        documentId: previewDocumentId,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _emailTemplatePreviewText(
                        printableDocumentEmailPreviewValue(
                          selected!.bodyTemplate,
                          previewDocumentData,
                          documentId: previewDocumentId,
                        ),
                      ),
                      maxLines: 8,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: selected == null
                ? null
                : () => Navigator.of(dialogContext).pop(selected),
            icon: const Icon(Icons.attach_email_outlined),
            label: const Text('Continue'),
          ),
        ],
      ),
    ),
  );
}

Future<bool> sendPrintableDocumentEmailDirectly(
  BuildContext context, {
  required PrintableDocumentEmailPayload payload,
  bool rethrowOnError = false,
}) async {
  try {
    final template = await selectPrintableDocumentEmailTemplate(
      context,
      target: payload.target,
      companyId: payload.companyId,
      previewDocumentData: payload.documentData,
      previewDocumentId: payload.documentId,
    );
    if (template?.id == null || !context.mounted) {
      return false;
    }
    final pdfBytes = await generateDocumentPrintPdf(
      context,
      documentType: payload.target.documentType,
      title: payload.title,
      documentData: payload.documentData,
    );
    if (pdfBytes == null || pdfBytes.isEmpty) {
      throw Exception('Unable to generate ${payload.title} PDF.');
    }
    final response = await CommunicationService().sendPrintableDocumentEmail(
      module: payload.target.module,
      documentType: payload.target.documentType,
      documentId: payload.documentId,
      templateId: template!.id!,
      pdfBytes: pdfBytes,
      fileName: payload.fileName ?? '${payload.title}.pdf',
    );
    if (response.success != true ||
        response.data?.status?.toLowerCase() != 'sent') {
      throw Exception(response.data?.errorMessage ?? response.message);
    }
    if (context.mounted) {
      AppToast.show(
        response.message.isEmpty
            ? 'PDF emailed successfully.'
            : response.message,
        context: context,
        type: AppToastType.success,
      );
    }
    return true;
  } catch (error) {
    if (rethrowOnError) {
      rethrow;
    }
    if (context.mounted) {
      final missingTemplate = printableDocumentEmailIsMissingTemplateError(
        error,
      );
      AppToast.show(
        'PDF email failed: $error',
        context: context,
        type: missingTemplate ? AppToastType.warning : AppToastType.error,
      );
    }
    return false;
  }
}
