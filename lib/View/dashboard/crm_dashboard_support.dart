import 'package:flutter/material.dart';

import '../purchase/purchase_support.dart';
import '../settings/master/master_setup_helpers.dart';

enum CrmFollowupTimingBucket { today, overdue, upcoming }

class CrmPendingFollowupItem {
  const CrmPendingFollowupItem({
    required this.id,
    required this.enquiryId,
    required this.subjectName,
    required this.followupDateRaw,
    required this.priority,
    required this.status,
    required this.assignedUserName,
    required this.summary,
  });

  final int? id;
  final int? enquiryId;
  final String subjectName;
  final String? followupDateRaw;
  final String priority;
  final String status;
  final String? assignedUserName;
  final String? summary;

  factory CrmPendingFollowupItem.fromJson(Map<String, dynamic> json) {
    final assignedUser = json['assigned_user'] is Map<String, dynamic>
        ? json['assigned_user'] as Map<String, dynamic>
        : null;
    final subjectName = stringValue(json, 'subject_name').trim().isNotEmpty
        ? stringValue(json, 'subject_name').trim()
        : (stringValue(json, 'customer_name').trim().isNotEmpty
              ? stringValue(json, 'customer_name').trim()
              : (stringValue(json, 'lead_name').trim().isNotEmpty
                    ? stringValue(json, 'lead_name').trim()
                    : 'Unknown lead/customer'));
    final assignedDisplayName = assignedUser == null
        ? null
        : (stringValue(assignedUser, 'display_name').trim().isNotEmpty
              ? stringValue(assignedUser, 'display_name').trim()
              : nullIfEmpty(stringValue(assignedUser, 'username')));

    return CrmPendingFollowupItem(
      id: intValue(json, 'id'),
      enquiryId: intValue(json, 'enquiry_id'),
      subjectName: subjectName,
      followupDateRaw: nullableStringValue(json, 'followup_date'),
      priority: crmNormalizePriority(
        nullableStringValue(json, 'priority') ??
            nullableStringValue(json, 'priority_level') ??
            nullableStringValue(json, 'priority_label'),
      ),
      status: stringValue(json, 'status', 'pending'),
      assignedUserName: assignedDisplayName,
      summary:
          nullIfEmpty(stringValue(json, 'summary')) ??
          nullIfEmpty(stringValue(json, 'notes')),
    );
  }

  DateTime? get followupDate {
    final raw = followupDateRaw?.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  String get followupDateLabel => displayDate(followupDateRaw);
}

String crmNormalizePriority(String? rawPriority) {
  final normalized = rawPriority?.trim().toLowerCase() ?? '';
  switch (normalized) {
    case 'high':
      return 'high';
    case 'low':
      return 'low';
    case 'medium':
    default:
      return 'medium';
  }
}

String crmPriorityLabel(String priority) {
  switch (crmNormalizePriority(priority)) {
    case 'high':
      return 'High';
    case 'low':
      return 'Low';
    case 'medium':
    default:
      return 'Medium';
  }
}

Color crmPriorityColor(String priority) {
  switch (crmNormalizePriority(priority)) {
    case 'high':
      return Colors.red;
    case 'low':
      return Colors.green;
    case 'medium':
    default:
      return Colors.orange;
  }
}

CrmFollowupTimingBucket crmFollowupBucket(
  CrmPendingFollowupItem item, {
  DateTime? today,
}) {
  final followupDate = item.followupDate;
  if (followupDate == null) {
    return CrmFollowupTimingBucket.upcoming;
  }

  final now = today ?? DateTime.now();
  final todayDate = DateTime(now.year, now.month, now.day);
  final dueDate = DateTime(
    followupDate.year,
    followupDate.month,
    followupDate.day,
  );

  if (dueDate == todayDate) {
    return CrmFollowupTimingBucket.today;
  }
  if (dueDate.isBefore(todayDate)) {
    return CrmFollowupTimingBucket.overdue;
  }
  return CrmFollowupTimingBucket.upcoming;
}

bool crmIsTodayFollowup(CrmPendingFollowupItem item, {DateTime? today}) {
  return crmFollowupBucket(item, today: today) == CrmFollowupTimingBucket.today;
}

Color crmFollowupDateColor(CrmPendingFollowupItem item, {DateTime? today}) {
  return crmIsTodayFollowup(item, today: today) ? Colors.red : Colors.blueGrey;
}

int crmPriorityRank(String priority) {
  switch (crmNormalizePriority(priority)) {
    case 'high':
      return 0;
    case 'medium':
      return 1;
    case 'low':
      return 2;
    default:
      return 1;
  }
}

List<CrmPendingFollowupItem> sortCrmPendingFollowups(
  Iterable<CrmPendingFollowupItem> items, {
  DateTime? today,
}) {
  final sorted = items.toList(growable: false);
  final now = today ?? DateTime.now();

  int bucketRank(CrmFollowupTimingBucket bucket) {
    switch (bucket) {
      case CrmFollowupTimingBucket.today:
        return 0;
      case CrmFollowupTimingBucket.overdue:
        return 1;
      case CrmFollowupTimingBucket.upcoming:
        return 2;
    }
  }

  int compareDateWithinBucket(
    CrmPendingFollowupItem left,
    CrmPendingFollowupItem right,
  ) {
    final leftDate = left.followupDate;
    final rightDate = right.followupDate;
    if (leftDate == null && rightDate == null) {
      return 0;
    }
    if (leftDate == null) {
      return 1;
    }
    if (rightDate == null) {
      return -1;
    }

    final leftBucket = crmFollowupBucket(left, today: now);
    if (leftBucket == CrmFollowupTimingBucket.overdue) {
      return rightDate.compareTo(leftDate);
    }

    return leftDate.compareTo(rightDate);
  }

  sorted.sort((left, right) {
    final bucketCompare = bucketRank(
      crmFollowupBucket(left, today: now),
    ).compareTo(bucketRank(crmFollowupBucket(right, today: now)));
    if (bucketCompare != 0) {
      return bucketCompare;
    }

    final priorityCompare = crmPriorityRank(
      left.priority,
    ).compareTo(crmPriorityRank(right.priority));
    if (priorityCompare != 0) {
      return priorityCompare;
    }

    final dateCompare = compareDateWithinBucket(left, right);
    if (dateCompare != 0) {
      return dateCompare;
    }

    return left.subjectName.toLowerCase().compareTo(
      right.subjectName.toLowerCase(),
    );
  });

  return sorted;
}
