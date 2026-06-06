import '../../screen.dart';

class MrpDetailFieldData {
  const MrpDetailFieldData({
    required this.labelText,
    required this.value,
    this.large = false,
  });

  final String labelText;
  final String value;
  final bool large;
}

class MrpDetailSection extends StatelessWidget {
  const MrpDetailSection({
    super.key,
    required this.title,
    required this.fields,
    this.hideEmptyFields = true,
  });

  final String title;
  final List<MrpDetailFieldData> fields;
  final bool hideEmptyFields;

  @override
  Widget build(BuildContext context) {
    final visibleFields = hideEmptyFields
        ? fields
              .where((field) => field.value.trim().isNotEmpty)
              .toList(growable: false)
        : fields;
    if (visibleFields.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppUiConstants.spacingSm),
        Wrap(
          spacing: AppUiConstants.spacingSm,
          runSpacing: AppUiConstants.spacingSm,
          children: visibleFields
              .map(
                (field) => MrpDetailField(
                  labelText: field.labelText,
                  value: field.value,
                  large: field.large,
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class MrpDetailField extends StatelessWidget {
  const MrpDetailField({
    super.key,
    required this.labelText,
    required this.value,
    this.large = false,
  });

  final String labelText;
  final String value;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: large ? 520 : 250,
      child: AppFieldBox(
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: labelText,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            isDense: true,
            contentPadding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
          ),
          child: Text(
            value.trim().isEmpty ? '-' : value,
            maxLines: large ? 3 : 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
