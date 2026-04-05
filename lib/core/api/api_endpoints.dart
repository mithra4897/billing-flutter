class ApiEndpoints {
  const ApiEndpoints._();

  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String authContext = '/auth/context';

  static const String companies = '/masters/companies';
  static const String branches = '/masters/branches';
  static const String businessLocations = '/masters/business-locations';
  static const String warehouses = '/masters/warehouses';
  static const String financialYears = '/masters/financial-years';
  static const String documentSeries = '/masters/document-series';

  static const String parties = '/parties';
  static const String partyAddresses = '/parties/addresses';
  static const String partyContacts = '/parties/contacts';

  static const String itemCategories = '/inventory/item-categories';
  static const String items = '/inventory/items';
  static const String taxCodes = '/inventory/tax-codes';
  static const String uoms = '/inventory/uoms';
  static const String brands = '/inventory/brands';

  static const String accounts = '/accounts/accounts';
  static const String vouchers = '/accounts/vouchers';

  static const String salesInvoices = '/sales/invoices';
  static const String salesOrders = '/sales/orders';
  static const String salesQuotations = '/sales/quotations';

  static const String purchaseInvoices = '/purchase/invoices';
  static const String purchaseOrders = '/purchase/orders';

  static const String mediaFiles = '/media/files';
  static const String emailTemplates = '/communication/email-templates';
  static const String emailRules = '/communication/email-rules';
  static const String emailMessages = '/communication/email-messages';
}
