/// Entity representing an attachment or resource uploaded by the teacher.
class AssignmentAttachmentEntity {
  final String id;
  final String fileName;
  final String fileUrl;
  final int fileSize;
  final String fileType;

  const AssignmentAttachmentEntity({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    required this.fileSize,
    required this.fileType,
  });

  factory AssignmentAttachmentEntity.fromJson(Map<String, dynamic> json) {
    return AssignmentAttachmentEntity(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      fileName:
          json['fileName']?.toString() ??
          json['name']?.toString() ??
          json['title']?.toString() ??
          'Attachment',
      fileUrl: json['fileUrl']?.toString() ?? json['url']?.toString() ?? '',
      fileSize:
          (json['fileSize'] as num?)?.toInt() ??
          (json['size'] as num?)?.toInt() ??
          0,
      fileType:
          json['fileType']?.toString() ??
          json['type']?.toString() ??
          'application/pdf',
    );
  }

  /// Formatted file size string (e.g., "112.1 KB", "2.4 MB")
  String get displayFileSize {
    if (fileSize <= 0) return '';
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssignmentAttachmentEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          fileName == other.fileName &&
          fileUrl == other.fileUrl &&
          fileSize == other.fileSize &&
          fileType == other.fileType;

  @override
  int get hashCode =>
      id.hashCode ^
      fileName.hashCode ^
      fileUrl.hashCode ^
      fileSize.hashCode ^
      fileType.hashCode;
}
