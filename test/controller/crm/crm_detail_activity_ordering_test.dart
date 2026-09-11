import 'package:billing/controller/crm/crm_enquiries_controller.dart';
import 'package:billing/controller/crm/crm_leads_controller.dart';
import 'package:billing/controller/crm/crm_opportunities_controller.dart';
import 'package:billing/helper/string_extensions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'a new lead activity is inserted, expanded, and date-prefilled first',
    () {
      final controller = CrmLeadsController(
        startInNewMode: false,
        initialSelectId: null,
        initialLeadName: null,
        initialCompanyId: null,
      );
      final existing = LeadActivityDraft(notes: 'Older activity');
      controller.activities = <LeadActivityDraft>[existing];
      controller.currentDateTimeLocal = '2026-09-11 12:45:00';

      controller.addActivity();

      expect(controller.activities, hasLength(2));
      expect(controller.activities.first, isNot(same(existing)));
      expect(controller.activities[1], same(existing));
      expect(controller.expandedActivityIndex, 0);
      expect(
        controller.activities.first.activityDateTimeController.text,
        displayDateTime('2026-09-11 12:45:00'),
      );
      expect(controller.activities.first.status, 'pending');

      controller.disposeActivities(controller.activities);
    },
  );

  test(
    'a new enquiry follow-up is inserted and date/assignee-prefilled first',
    () {
      final controller = CrmEnquiriesController(
        instanceTag: 'detail-ordering-test',
        startInNewMode: false,
        initialSelectId: null,
      );
      final existing = FollowupDraft(notes: 'Older follow-up');
      controller.followups = <FollowupDraft>[existing];
      controller.currentDateTimeLocal = '2026-09-11 12:45:00';
      controller.assignedTo = 42;

      controller.addFollowup();

      expect(controller.followups, hasLength(2));
      expect(controller.followups.first, isNot(same(existing)));
      expect(controller.followups[1], same(existing));
      expect(controller.expandedFollowupIndex, 0);
      expect(
        controller.followups.first.followupDateController.text,
        displayDateTime('2026-09-11 12:45:00'),
      );
      expect(controller.followups.first.assignedTo, 42);

      controller.disposeFollowups(controller.followups);
    },
  );

  test(
    'a new opportunity follow-up is inserted and date/assignee-prefilled first',
    () {
      final controller = CrmOpportunitiesController(
        instanceTag: 'detail-ordering-test',
        startInNewMode: false,
        initialSelectId: null,
        initialLeadId: null,
        initialCompanyId: null,
        initialAssignedTo: null,
      );
      final existing = OpportunityFollowupDraft(notes: 'Older follow-up');
      controller.followups = <OpportunityFollowupDraft>[existing];
      controller.currentDateTimeLocal = '2026-09-11 12:45:00';
      controller.assignedTo = 42;

      controller.addFollowup();

      expect(controller.followups, hasLength(2));
      expect(controller.followups.first, isNot(same(existing)));
      expect(controller.followups[1], same(existing));
      expect(controller.expandedFollowupIndex, 0);
      expect(
        controller.followups.first.followupDateController.text,
        displayDateTime('2026-09-11 12:45:00'),
      );
      expect(controller.followups.first.assignedTo, 42);

      controller.disposeFollowups(controller.followups);
    },
  );
}
