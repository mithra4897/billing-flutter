import '../../screen.dart';
import 'item_planning_policy_page.dart' as item_policy_page;
import 'mrp_readonly_page.dart' as mrp_readonly_page;
import 'mrp_recommendation_page.dart' as mrp_recommendation_page;
import 'mrp_run_page.dart' as mrp_run_page;
import 'planning_calendar_page.dart' as planning_calendar_page;
import 'stock_reservation_page.dart' as stock_reservation_page;
import '../../view_model/planning/mrp_readonly_view_model.dart' as mrp_readonly_vm;

class StockReservationPage extends StatelessWidget {
  const StockReservationPage({
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
    return stock_reservation_page.StockReservationPage(
      embedded: embedded,
      editorOnly: editorOnly,
      initialId: initialId,
    );
  }
}

class ItemPlanningPolicyPage extends StatelessWidget {
  const ItemPlanningPolicyPage({
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
    return item_policy_page.ItemPlanningPolicyPage(
      embedded: embedded,
      editorOnly: editorOnly,
      initialId: initialId,
    );
  }
}

class PlanningCalendarPage extends StatelessWidget {
  const PlanningCalendarPage({
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
    return planning_calendar_page.PlanningCalendarPage(
      embedded: embedded,
      editorOnly: editorOnly,
      initialId: initialId,
    );
  }
}

class MrpRunPage extends StatelessWidget {
  const MrpRunPage({
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
    return mrp_run_page.MrpRunPage(
      embedded: embedded,
      editorOnly: editorOnly,
      initialId: initialId,
    );
  }
}

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
    return mrp_readonly_page.MrpReadonlyPage(
      module: mrp_readonly_vm.MrpReadonlyModule.demand,
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
    return mrp_readonly_page.MrpReadonlyPage(
      module: mrp_readonly_vm.MrpReadonlyModule.supply,
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
    return mrp_readonly_page.MrpReadonlyPage(
      module: mrp_readonly_vm.MrpReadonlyModule.netRequirement,
      title: 'MRP Net Requirements',
      embedded: embedded,
      editorOnly: editorOnly,
      initialId: initialId,
    );
  }
}

class MrpRecommendationPage extends StatelessWidget {
  const MrpRecommendationPage({
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
    return mrp_recommendation_page.MrpRecommendationPage(
      embedded: embedded,
      editorOnly: editorOnly,
      initialId: initialId,
    );
  }
}
