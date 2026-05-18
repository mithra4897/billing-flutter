class MediaFileModel {
  const MediaFileModel({
    required this.id,
    required this.originalName,
    required this.storedName,
    required this.filePath,
    this.module,
    this.documentType,
    this.documentId,
    this.purpose,
    this.mimeType,
    this.fileSize,
    this.downloadUrl,
    this.publicUrl,
    this.isPublic = false,
    Map<String, dynamic>? raw,
  }) : _raw = raw;

  final int id;
  final String originalName;
  final String storedName;
  final String filePath;
  final String? module;
  final String? documentType;
  final int? documentId;
  final String? purpose;
  final String? mimeType;
  final int? fileSize;
  final String? downloadUrl;
  final String? publicUrl;
  final bool isPublic;

  factory MediaFileModel.fromJson(Map<String, dynamic> json) {
    return MediaFileModel(
      id: _parseInt(json['id']),
      originalName: json['original_name']?.toString() ?? '',
      storedName: json['stored_name']?.toString() ?? '',
      filePath: json['file_path']?.toString() ?? '',
      module: json['module']?.toString(),
      documentType: json['document_type']?.toString(),
      documentId: _nullableInt(json['document_id']),
      purpose: json['purpose']?.toString(),
      mimeType: json['mime_type']?.toString(),
      fileSize: _nullableInt(json['file_size']),
      downloadUrl: json['download_url']?.toString(),
      publicUrl: json['public_url']?.toString(),
      isPublic: json['is_public'] == true || json['is_public'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'original_name': originalName,
    'stored_name': storedName,
    'file_path': filePath,
    if (module != null) 'module': module,
    if (documentType != null) 'document_type': documentType,
    if (documentId != null) 'document_id': documentId,
    if (purpose != null) 'purpose': purpose,
    if (mimeType != null) 'mime_type': mimeType,
    if (fileSize != null) 'file_size': fileSize,
    if (downloadUrl != null) 'download_url': downloadUrl,
    if (publicUrl != null) 'public_url': publicUrl,
    'is_public': isPublic,
  };

  static int _parseInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '') ?? 0;

  static int? _nullableInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '');
}
