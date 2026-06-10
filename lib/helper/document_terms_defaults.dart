String documentTermsDefault(String documentType) {
  switch (documentType) {
    case 'sales_quotation':
    case 'sales_order':
      return '''
1. Prototypes works doesn't cover any warranty
2. Products damaged will not be covered under the warranty, its carries warranty if specified in description
3. Subject to Vellore Jurisdiction.
''';
    case 'sales_invoice':
      return '''
1. Goods once sold will not be taken back or exchanged unless agreed in writing.
2. The buyer must check goods at the time of delivery. No claims for damage or shortage will be accepted later.
3. Ownership of goods remains with the seller until full payment is received.
4. All disputes are subject to Vellore jurisdiction.
''';
    case 'sales_delivery':
      return '';
    case 'purchase_order':
      return '''
Payment Terms :
1. Payment will be made 45 days after the successful delivery of the magnetic relay.
2. Any invoice discrepancies should be resolved before payment processing.
3. Payment will be made via NEFT as per standard company policy

Delivery Terms :
1. Delivery must be made inside our office premises at as in shipping location.
2. The supplier must ensure safe and damage-free delivery.
3. The delivery timeline should be 5 days from the date of order confirmation.
4. Any delays beyond the agreed delivery date must be communicated in advance.
5. Partial deliveries will not be accepted unless pre-approved.
6. The supplier is responsible for any transportation and handling costs.
''';
    default:
      return '';
  }
}

String documentTermsOrDefault(String? terms, String documentType) {
  final normalized = terms?.trim() ?? '';
  if (normalized.isNotEmpty) {
    return terms!;
  }
  return documentTermsDefault(documentType);
}
