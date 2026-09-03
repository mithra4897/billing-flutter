import 'dart:ui' show PointerDeviceKind;

import 'package:billing/app/theme/app_theme.dart';
import 'package:billing/widgets/erp_line_item_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('line-item row hover is safe during mouse tracking', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: ErpLineItemTable(
            lines: const <ErpLineItemTableRow>[
              ErpLineItemTableRow(rowKey: 'row-1', amount: 100),
            ],
            visibleColumns: const <ErpLineItemTableColumn>{
              ErpLineItemTableColumn.no,
              ErpLineItemTableColumn.amount,
            },
          ),
        ),
      ),
    );

    final rowRegion = find.byWidgetPredicate(
      (widget) =>
          widget is MouseRegion &&
          widget.onEnter != null &&
          widget.onExit != null,
    );
    expect(rowRegion, findsOneWidget);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(790, 590));
    await mouse.moveTo(tester.getCenter(rowRegion));
    await tester.pump();
    await mouse.moveTo(const Offset(790, 590));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
