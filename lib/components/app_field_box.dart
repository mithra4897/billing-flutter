import 'package:flutter/material.dart';

class AppFieldBox extends StatelessWidget {
  const AppFieldBox({
    super.key,
    required this.child,
    this.width,
    this.padding = const EdgeInsets.symmetric(vertical: 8),
  });

  final Widget child;
  final double? width;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final content = width == null
        ? child
        : SizedBox(width: width, child: child);
    return Padding(padding: padding, child: content);
  }
}
