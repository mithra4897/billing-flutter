import '../screen.dart';

final _optionalLabelPattern = RegExp(
  r'\s*\(optional.*?\)',
  caseSensitive: false,
);

Widget? buildFormLabel(
  String? labelText, {
  bool isRequired = false,
  TextStyle? style,
}) {
  final cleanedLabel = labelText?.replaceAll(_optionalLabelPattern, '').trim();
  if (cleanedLabel == null || cleanedLabel.isEmpty) {
    return null;
  }

  return RichText(
    text: TextSpan(
      style: style,
      children: <InlineSpan>[
        TextSpan(text: cleanedLabel),
        if (isRequired)
          TextSpan(
            text: ' *',
            style:
                style?.copyWith(color: Colors.red) ??
                const TextStyle(color: Colors.red),
          ),
      ],
    ),
  );
}
