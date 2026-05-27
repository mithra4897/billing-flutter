export 'item_planning_policy_page.dart';
export 'mrp_readonly_page.dart';
export 'mrp_recommendation_page.dart';
export 'mrp_run_page.dart';
export 'planning_calendar_page.dart';
export 'stock_reservation_page.dart';

import '../../screen.dart';

class MrpDemandPage extends StatelessWidget {
  const MrpDemandPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  Widget build(BuildContext context) {
    return MrpReadonlyPage(
      module: MrpReadonlyModule.demand,
      title: 'MRP Demands',
      embedded: embedded,
      editorOnly: editorOnly,
      initialId: initialId,
    );
  }
}

class MrpSupplyPage extends StatelessWidget {
  const MrpSupplyPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  Widget build(BuildContext context) {
    return MrpReadonlyPage(
      module: MrpReadonlyModule.supply,
      title: 'MRP Supplies',
      embedded: embedded,
      editorOnly: editorOnly,
      initialId: initialId,
    );
  }
}

class MrpNetRequirementPage extends StatelessWidget {
  const MrpNetRequirementPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  Widget build(BuildContext context) {
    return MrpReadonlyPage(
      module: MrpReadonlyModule.netRequirement,
      title: 'MRP Net Requirements',
      embedded: embedded,
      editorOnly: editorOnly,
      initialId: initialId,
    );
  }
}
