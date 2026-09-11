/// Holds the latest Company-local calendar date returned by a paginated API
/// response for the current working context. It is a display/comparison value,
/// never a source for persisted timestamps.
class CompanyLocalDateSource {
  CompanyLocalDateSource._();

  static String? _todayLocal;
  static int? _companyId;

  static String? get todayLocal => _todayLocal;
  static int? get companyId => _companyId;

  static void update(String? value, {required int companyId}) {
    final normalized = (value ?? '').trim();
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(normalized) ||
        DateTime.tryParse(normalized) == null) {
      return;
    }

    _todayLocal = normalized;
    _companyId = companyId;
  }

  static void clear() {
    _todayLocal = null;
    _companyId = null;
  }
}
