import '../screen.dart';

/// Sort value used across all modules for "Pending (Red first)" ordering.
const String kPendingRedFirstSort = 'pending_red_first';

/// Sort item that can be appended to any module's sort dropdown.
const AppDropdownItem<String> kPendingRedFirstSortItem =
    AppDropdownItem<String>(value: kPendingRedFirstSort, label: 'Pending');

/// Returns an age-based background color for a document row in a register.
///
/// Color zones:
///   ≤ 7 days  → Green  (fresh / on track)
///   ≤ 15 days → Blue   (attention needed)
///   ≤ 30 days → Amber  (overdue warning)
///   > 30 days → Red    (critical / very old)
///
/// Returns `null` (no color) when:
///   - [isPending] is `false` – the document has been converted / closed.
///   - [createdAt] cannot be parsed.
///
/// [createdAt] should be an ISO-8601 datetime string. [referenceDate], when
/// supplied, must be a server-calculated Company-local calendar date. Callers
/// without a row-specific date use [CompanyLocalDateSource].
/// [isPending] should return `true` only for documents still "open" and not
/// yet progressed to a next-stage document.
Color? documentAgeZoneColor(
  String? createdAt, {
  required bool isPending,
  String? referenceDate,
}) {
  if (!isPending) return null;

  final parsed = DateTime.tryParse((createdAt ?? '').trim());
  if (parsed == null) return null;

  final normalizedReferenceDate =
      (referenceDate ?? CompanyLocalDateSource.todayLocal ?? '').trim();
  final today = DateTime.tryParse(normalizedReferenceDate);
  if (today == null) return null;
  final createdDate = DateTime(parsed.year, parsed.month, parsed.day);
  final todayDate = DateTime(today.year, today.month, today.day);
  final ageInDays = todayDate.difference(createdDate).inDays;

  final color = ageInDays <= 7
      ? appStatusColorSuccess
      : ageInDays <= 15
      ? appStatusColorInfo
      : ageInDays <= 30
      ? appStatusColorWarning
      : appStatusColorDanger;

  return color.withValues(alpha: 0.22);
}
