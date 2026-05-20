import '../../screen.dart';

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
    return StockReservationPage(
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
    return ItemPlanningPolicyPage(
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
    return PlanningCalendarPage(
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
    return MrpRunPage(
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
    return MrpRecommendationPage(
      embedded: embedded,
      editorOnly: editorOnly,
      initialId: initialId,
    );
  }
}
