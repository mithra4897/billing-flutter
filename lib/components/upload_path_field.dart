import 'package:flutter/material.dart';

import '../app/constants/app_ui_constants.dart';
import '../app/theme/app_theme_extension.dart';
import 'app_form_text_field.dart';

class UploadPathField extends StatelessWidget {
  const UploadPathField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.onUpload,
    this.isUploading = false,
    this.previewUrl,
    this.previewIcon = Icons.upload_file_outlined,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String labelText;
  final Future<void> Function() onUpload;
  final bool isUploading;
  final String? previewUrl;
  final IconData previewIcon;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((previewUrl ?? '').trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppUiConstants.fieldRadius),
              child: Image.network(
                previewUrl!,
                width: 96,
                height: 96,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 96,
                    height: 96,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: appTheme.subtleFill,
                      borderRadius: BorderRadius.circular(
                        AppUiConstants.fieldRadius,
                      ),
                    ),
                    child: Icon(previewIcon),
                  );
                },
              ),
            ),
          ),
        AppFormTextField(
          controller: controller,
          maxLines: maxLines,
          labelText: labelText,
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: isUploading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    tooltip: 'Upload file',
                    onPressed: onUpload,
                    icon: const Icon(Icons.upload_outlined),
                  ),
          ),
        ),
      ],
    );
  }
}
