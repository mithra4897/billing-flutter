import 'package:flutter/widgets.dart';

class Responsive {
  const Responsive._();

  static const double mobileBreakpoint = 600;
  static const double desktopBreakpoint = 1120;

  static bool isMobile(BuildContext context) {
    return MediaQuery.sizeOf(context).width < mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= desktopBreakpoint;
  }

  static bool isNotMobile(BuildContext context) {
    return !isMobile(context);
  }
}
