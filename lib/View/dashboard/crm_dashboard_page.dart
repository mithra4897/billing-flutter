import '../../screen.dart';
import 'crm_dashboard_support.dart';

class CrmDashboardPage extends StatelessWidget {
  const CrmDashboardPage({
    super.key,
    this.embedded = false,
    this.crmService,
    this.now,
  });

  final bool embedded;
  final CrmService? crmService;
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context) {
    final content = _CrmDashboardContent(
      crmService: crmService ?? CrmService(),
      now: now ?? DateTime.now,
    );
    if (embedded) {
      return content;
    }

    return FutureBuilder<PublicBrandingModel?>(
      future: SessionStorage.getBranding(),
      builder: (context, snapshot) {
        final branding =
            snapshot.data ??
            const PublicBrandingModel(companyName: 'Billing ERP');

        return AdaptiveShell(
          title: 'CRM Dashboard',
          branding: branding,
          child: content,
        );
      },
    );
  }
}

class _CrmDashboardContent extends StatefulWidget {
  const _CrmDashboardContent({required this.crmService, required this.now});

  final CrmService crmService;
  final DateTime Function() now;

  @override
  State<_CrmDashboardContent> createState() => _CrmDashboardContentState();
}

class _CrmDashboardContentState extends State<_CrmDashboardContent> {
  late Future<_CrmDashboardSnapshot> _snapshotFuture;

  @override
  void initState() {
    super.initState();
    _snapshotFuture = _loadSnapshot();
  }

  Future<_CrmDashboardSnapshot> _loadSnapshot() async {
    final leadResponse = await widget.crmService.leads(
      filters: const <String, dynamic>{'per_page': 1},
    );
    final enquiryResponse = await widget.crmService.enquiries(
      filters: const <String, dynamic>{'per_page': 1},
    );
    final pendingFollowupResponse = await widget.crmService.pendingFollowups();

    final pendingItems = sortCrmPendingFollowups(
      (pendingFollowupResponse.data ?? const <CrmFollowupModel>[]).map(
        (item) => CrmPendingFollowupItem.fromJson(item.toJson()),
      ),
      today: widget.now(),
    );

    return _CrmDashboardSnapshot(
      leadCount: leadResponse.meta?.total ?? leadResponse.data?.length ?? 0,
      customerOrEnquiryCount:
          enquiryResponse.meta?.total ?? enquiryResponse.data?.length ?? 0,
      pendingFollowups: pendingItems,
    );
  }

  void _reload() {
    setState(() {
      _snapshotFuture = _loadSnapshot();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;

    return FutureBuilder<_CrmDashboardSnapshot>(
      future: _snapshotFuture,
      builder: (context, snapshot) {
        final body = switch (snapshot.connectionState) {
          ConnectionState.waiting || ConnectionState.active =>
            const AppLoadingView(message: 'Loading CRM dashboard...'),
          _ when snapshot.hasError => AppErrorStateView(
            title: 'Unable to load CRM dashboard',
            message: snapshot.error.toString(),
            onRetry: _reload,
          ),
          _ => _buildDashboard(context, appTheme, snapshot.data),
        };

        return Padding(
          padding: const EdgeInsets.all(AppUiConstants.pagePadding),
          child: body,
        );
      },
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    AppThemeExtension appTheme,
    _CrmDashboardSnapshot? snapshot,
  ) {
    final data = snapshot ?? const _CrmDashboardSnapshot.empty();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CRM Dashboard',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppUiConstants.spacingSm),
                Text(
                  'Track lead volume, customer-facing enquiries, and every pending follow-up in one place.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: appTheme.mutedText),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          Wrap(
            spacing: AppUiConstants.spacingMd,
            runSpacing: AppUiConstants.spacingMd,
            children: [
              _CrmMetricCard(
                title: 'Leads',
                value: data.leadCount.toString(),
                subtitle: 'Total CRM leads',
                accentColor: Colors.blue,
              ),
              _CrmMetricCard(
                title: 'Customers / Enquiries',
                value: data.customerOrEnquiryCount.toString(),
                subtitle: 'Tracked customer-facing enquiries',
                accentColor: Colors.deepPurple,
              ),
              _CrmMetricCard(
                title: 'Pending Follow-ups',
                value: data.pendingFollowups.length.toString(),
                subtitle: 'Open follow-up actions',
                accentColor: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          AppSectionCard(
            child: _CrmPendingFollowupsSection(
              items: data.pendingFollowups,
              now: widget.now,
            ),
          ),
        ],
      ),
    );
  }
}

class _CrmDashboardSnapshot {
  const _CrmDashboardSnapshot({
    required this.leadCount,
    required this.customerOrEnquiryCount,
    required this.pendingFollowups,
  });

  const _CrmDashboardSnapshot.empty()
    : leadCount = 0,
      customerOrEnquiryCount = 0,
      pendingFollowups = const <CrmPendingFollowupItem>[];

  final int leadCount;
  final int customerOrEnquiryCount;
  final List<CrmPendingFollowupItem> pendingFollowups;
}

class _CrmMetricCard extends StatelessWidget {
  const _CrmMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accentColor,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 320),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: appTheme.cardBackground,
          borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
          boxShadow: [
            BoxShadow(
              color: appTheme.cardShadow,
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: accentColor.withValues(alpha: 0.18)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppUiConstants.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 6,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: AppUiConstants.spacingMd),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppUiConstants.spacingXs),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppUiConstants.spacingXs),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: appTheme.mutedText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CrmPendingFollowupsSection extends StatelessWidget {
  const _CrmPendingFollowupsSection({required this.items, required this.now});

  final List<CrmPendingFollowupItem> items;
  final DateTime Function() now;

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Pending Follow-ups',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppUiConstants.spacingSm,
                vertical: AppUiConstants.spacingXxs,
              ),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${items.length} open',
                style: textTheme.labelLarge?.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppUiConstants.spacingSm),
        Text(
          'Today first, then overdue, then upcoming. Priority stays High to Low inside each group.',
          style: textTheme.bodyMedium?.copyWith(color: appTheme.mutedText),
        ),
        const SizedBox(height: AppUiConstants.spacingMd),
        if (items.isEmpty)
          Container(
            key: const ValueKey<String>('crm-pending-followups-empty'),
            width: double.infinity,
            padding: const EdgeInsets.all(AppUiConstants.cardPadding),
            decoration: BoxDecoration(
              color: Colors.blueGrey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
              border: Border.all(
                color: Colors.blueGrey.withValues(alpha: 0.12),
              ),
            ),
            child: Text(
              'No pending follow-ups.',
              style: textTheme.bodyLarge?.copyWith(color: appTheme.mutedText),
            ),
          )
        else
          Column(
            children: items
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppUiConstants.spacingSm,
                    ),
                    child: _CrmPendingFollowupTile(item: item, now: now),
                  ),
                )
                .toList(growable: false),
          ),
      ],
    );
  }
}

class _CrmPendingFollowupTile extends StatelessWidget {
  const _CrmPendingFollowupTile({required this.item, required this.now});

  final CrmPendingFollowupItem item;
  final DateTime Function() now;

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;
    final textTheme = Theme.of(context).textTheme;
    final dateColor = crmFollowupDateColor(item, today: now());
    final priorityColor = crmPriorityColor(item.priority);

    return Container(
      key: ValueKey<String>(
        'crm-pending-followup-${item.id ?? item.subjectName}',
      ),
      width: double.infinity,
      padding: const EdgeInsets.all(AppUiConstants.cardPadding),
      decoration: BoxDecoration(
        color: appTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.subjectName,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppUiConstants.spacingXxs),
                    Text(
                      item.summary?.trim().isNotEmpty == true
                          ? item.summary!.trim()
                          : 'No notes available.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: appTheme.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppUiConstants.spacingSm),
          Wrap(
            spacing: AppUiConstants.spacingSm,
            runSpacing: AppUiConstants.spacingSm,
            children: [
              _CrmInfoChip(
                key: ValueKey<String>(
                  'crm-followup-date-${item.id ?? item.subjectName}',
                ),
                label: item.followupDateLabel.isEmpty
                    ? 'No follow-up date'
                    : item.followupDateLabel,
                color: dateColor,
              ),
              _CrmInfoChip(
                key: ValueKey<String>(
                  'crm-followup-priority-${item.id ?? item.subjectName}',
                ),
                label: crmPriorityLabel(item.priority),
                color: priorityColor,
              ),
              _CrmInfoChip(
                label: item.status.isEmpty ? 'Pending' : item.status,
                color: Colors.blueGrey,
              ),
              if ((item.assignedUserName ?? '').trim().isNotEmpty)
                _CrmInfoChip(
                  label: item.assignedUserName!.trim(),
                  color: Colors.indigo,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CrmInfoChip extends StatelessWidget {
  const _CrmInfoChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppUiConstants.spacingSm,
        vertical: AppUiConstants.spacingXxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
