import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ShellPageActionsController extends ValueNotifier<List<Widget>> {
  ShellPageActionsController() : super(const <Widget>[]);

  void setActions(List<Widget> actions) {
    if (listEquals(value, actions)) {
      return;
    }

    value = List<Widget>.unmodifiable(actions);
  }

  void clearActions() {
    if (value.isEmpty) {
      return;
    }

    value = const <Widget>[];
  }
}

class ShellPageActionsScope
    extends InheritedNotifier<ShellPageActionsController> {
  const ShellPageActionsScope({
    super.key,
    required ShellPageActionsController controller,
    required super.child,
  }) : super(notifier: controller);

  static ShellPageActionsController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ShellPageActionsScope>()
        ?.notifier;
  }
}

class ShellPageActions extends StatefulWidget {
  const ShellPageActions({
    super.key,
    required this.actions,
    required this.child,
  });

  final List<Widget> actions;
  final Widget child;

  @override
  State<ShellPageActions> createState() => _ShellPageActionsState();
}

class _ShellPageActionsState extends State<ShellPageActions> {
  ShellPageActionsController? _controller;
  List<Widget>? _pendingActions;
  bool _clearOnDispose = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = ShellPageActionsScope.maybeOf(context);
    _scheduleActionsSync(widget.actions);
  }

  @override
  void didUpdateWidget(covariant ShellPageActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.actions, widget.actions)) {
      _scheduleActionsSync(widget.actions);
    }
  }

  @override
  void dispose() {
    _clearOnDispose = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_clearOnDispose) {
        _controller?.clearActions();
      }
    });
    super.dispose();
  }

  void _scheduleActionsSync(List<Widget> actions) {
    _clearOnDispose = false;
    _pendingActions = actions;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final pendingActions = _pendingActions;
      if (pendingActions == null) {
        return;
      }

      _pendingActions = null;
      _controller?.setActions(pendingActions);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
