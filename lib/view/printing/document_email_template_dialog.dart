import '../../screen.dart';

class PrintableDocumentEmailTarget {
  const PrintableDocumentEmailTarget({
    required this.module,
    required this.documentType,
  });

  final String module;
  final String documentType;
}

String _emailTemplatePreviewText(String? value) => (value ?? '')
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
    throw Exception(
      'No active email template is configured for this document type.',
    );
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
                  Text(selected!.subjectTemplate ?? ''),
                  const SizedBox(height: 8),
                  Text(
                    _emailTemplatePreviewText(selected!.bodyTemplate),
                    maxLines: 8,
                    overflow: TextOverflow.ellipsis,
                  ),
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
