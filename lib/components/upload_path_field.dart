import '../screen.dart';
import '../core/files/pdf_web_actions.dart';

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
    final resolvedPreviewUrl = (previewUrl ?? '').trim();
    final hasPreview = resolvedPreviewUrl.isNotEmpty;
    final isImagePreview = _isImageUrl(resolvedPreviewUrl);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasPreview)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isImagePreview)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      AppUiConstants.fieldRadius,
                    ),
                    child: Image.network(
                      resolvedPreviewUrl,
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _fallbackPreviewCard(appTheme);
                      },
                    ),
                  )
                else
                  _fallbackPreviewCard(appTheme),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _openPreview(context, resolvedPreviewUrl),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('View'),
                ),
              ],
            ),
          ),
        SizedBox(
          height: 36,
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: isUploading
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        tooltip: 'Upload file',
                        onPressed: onUpload,
                        icon: const Icon(Icons.upload_outlined, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _fallbackPreviewCard(AppThemeExtension appTheme) {
    return Container(
      width: 96,
      height: 96,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: appTheme.subtleFill,
        borderRadius: BorderRadius.circular(AppUiConstants.fieldRadius),
      ),
      child: Icon(previewIcon),
    );
  }

  bool _isImageUrl(String value) {
    final normalized = value.toLowerCase();
    return normalized.contains('.png') ||
        normalized.contains('.jpg') ||
        normalized.contains('.jpeg') ||
        normalized.contains('.gif') ||
        normalized.contains('.webp') ||
        normalized.contains('.bmp') ||
        normalized.contains('.svg');
  }

  Future<void> _openPreview(BuildContext context, String url) async {
    final opened = await openWebUrl(url);
    if (opened || !context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File preview is supported in the web app browser.'),
      ),
    );
  }
}
