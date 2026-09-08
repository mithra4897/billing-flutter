import 'package:flutter/material.dart';

import '../view/core/page_shell_actions.dart';

void openFormScreenRoute(BuildContext context, String route) {
  final navigate = ShellRouteScope.maybeOf(context);
  if (navigate != null) {
    navigate(route);
    return;
  }
  Navigator.of(context).pushNamed(route);
}
