import '../../../screen.dart';

class ProjectSubtabExpandableSection extends StatelessWidget {
  const ProjectSubtabExpandableSection({
    super.key,
    required this.title,
    required this.description,
    required this.addLabel,
    required this.addIcon,
    required this.onAdd,
    required this.emptyMessage,
    required this.showDraftTile,
    required this.draftTitle,
    required this.draftSubtitle,
    required this.onDraftToggle,
    required this.draftChild,
    required this.recordTiles,
    this.addEnabled = true,
  });

  final String title;
  final String description;
  final String addLabel;
  final IconData addIcon;
  final VoidCallback? onAdd;
  final String emptyMessage;
  final bool showDraftTile;
  final String draftTitle;
  final String draftSubtitle;
  final VoidCallback onDraftToggle;
  final Widget draftChild;
  final List<Widget> recordTiles;
  final bool addEnabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  AppActionButton(
                    onPressed: addEnabled ? onAdd : null,
                    icon: addIcon,
                    label: addLabel,
                  ),
                ],
              ),
              const SizedBox(height: AppUiConstants.spacingSm),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).extension<AppThemeExtension>()!.mutedText,
                ),
              ),
              const SizedBox(height: AppUiConstants.spacingMd),
              if (recordTiles.isEmpty && !showDraftTile)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(emptyMessage),
                ),
              if (showDraftTile) ...[
                SettingsExpandableTile(
                  expanded: true,
                  highlighted: true,
                  leadingIcon: Icons.add_outlined,
                  title: draftTitle,
                  subtitle: draftSubtitle,
                  onToggle: onDraftToggle,
                  child: draftChild,
                ),
                if (recordTiles.isNotEmpty)
                  const SizedBox(height: AppUiConstants.spacingSm),
              ],
              ...recordTiles,
            ],
          ),
        ),
      ],
    );
  }
}
