import '../screen.dart';

const Color appStatusColorNeutral = Color(0xFF7A869A);
const Color appStatusColorInfo = Color(0xFF2F6FED);
const Color appStatusColorSuccess = Color(0xFF1FA971);
const Color appStatusColorWarning = Color(0xFFE67E22);
const Color appStatusColorDanger = Color(0xFFDA4D78);
const Color appStatusColorAccent = Color(0xFF19A7B8);

Color appStatusColor(String? rawStatus) {
  final status = (rawStatus ?? '').trim().toLowerCase();
  if (status.isEmpty) {
    return appStatusColorNeutral;
  }

  if (status.contains('cancelled') ||
      status.contains('canceled') ||
      status.contains('rejected') ||
      status.contains('void') ||
      status.contains('lost') ||
      status.contains('overdue') ||
      status.contains('failed') ||
      status.contains('delay') ||
      status.contains('delayed')) {
    return appStatusColorDanger;
  }

  if (status.contains('completed') ||
      status.contains('closed') ||
      status.contains('won') ||
      status.contains('approved') ||
      status.contains('paid') ||
      status.contains('posted') ||
      status.contains('delivered') ||
      status.contains('received') ||
      status.contains('active') ||
      status.contains('success')) {
    return appStatusColorSuccess;
  }

  if (status.contains('working') ||
      status.contains('in_progress') ||
      status.contains('in progress') ||
      status.contains('pending') ||
      status.contains('on_hold') ||
      status.contains('on hold') ||
      status.contains('draft') ||
      status.contains('inactive') ||
      status.contains('hold')) {
    return appStatusColorWarning;
  }

  if (status.contains('open')) {
    return appStatusColorInfo;
  }

  return appStatusColorNeutral;
}
