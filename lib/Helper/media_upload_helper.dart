import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../service/media/media_service.dart';

class MediaUploadHelper {
  static Future<void> uploadImage({
    required BuildContext context,
    required MediaService mediaService,
    required Function(bool) onLoading,
    required Function(String) onSuccess,
    required Function(String) onError,
    String? module,
    String? documentType,
    int? documentId,
    String? purpose,
    String? folder,
    bool isPublic = true,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.first;
      final fileBytes = file.bytes;
      if (fileBytes == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to read file bytes.')),
          );
        }
        return;
      }

      onLoading(true);

      final response = await mediaService.uploadFileBytes(
        fileBytes: fileBytes,
        fileName: file.name,
        module: module,
        documentType: documentType,
        documentId: documentId,
        purpose: purpose,
        folder: folder,
        isPublic: isPublic,
      );

      final uploaded = response.data;
      if (uploaded == null) {
        onError(response.message);
        return;
      }

      onSuccess(uploaded.publicUrl ?? uploaded.filePath);
    } catch (error) {
      onError(error.toString());
    } finally {
      onLoading(false);
    }
  }
}
