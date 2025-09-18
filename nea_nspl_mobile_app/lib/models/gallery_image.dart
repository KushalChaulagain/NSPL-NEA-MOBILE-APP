class GalleryImage {
  final String id;
  final String taskId;
  final String taskTitle;
  final String meterNumber;
  final String fieldAgentName;
  final String fieldAgentId;
  final DateTime uploadedAt;
  final String fileName;
  final String fileSize;
  final String mimeType;
  final String? signedUrl;
  final DateTime? urlExpiresAt;

  GalleryImage({
    required this.id,
    required this.taskId,
    required this.taskTitle,
    required this.meterNumber,
    required this.fieldAgentName,
    required this.fieldAgentId,
    required this.uploadedAt,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    this.signedUrl,
    this.urlExpiresAt,
  });

  factory GalleryImage.fromJson(Map<String, dynamic> json) {
    return GalleryImage(
      id: json['id'] ?? '',
      taskId: json['taskId'] ?? '',
      taskTitle: json['taskTitle'] ?? '',
      meterNumber: json['meterNumber'] ?? '',
      fieldAgentName: json['fieldAgentName'] ?? '',
      fieldAgentId: json['fieldAgentId'] ?? '',
      uploadedAt: DateTime.parse(json['uploadedAt']),
      fileName: json['fileName'] ?? '',
      fileSize: json['fileSize'] ?? '',
      mimeType: json['mimeType'] ?? 'image/jpeg',
      signedUrl: json['signedUrl'],
      urlExpiresAt: json['urlExpiresAt'] != null
          ? DateTime.parse(json['urlExpiresAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'taskTitle': taskTitle,
      'meterNumber': meterNumber,
      'fieldAgentName': fieldAgentName,
      'fieldAgentId': fieldAgentId,
      'uploadedAt': uploadedAt.toIso8601String(),
      'fileName': fileName,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'signedUrl': signedUrl,
      'urlExpiresAt': urlExpiresAt?.toIso8601String(),
    };
  }

  // Helper method to check if URL is expired
  bool get isUrlExpired {
    if (urlExpiresAt == null) return false;
    return DateTime.now().isAfter(urlExpiresAt!);
  }

  // Helper method to format file size
  String get formattedFileSize {
    try {
      final size = int.parse(fileSize);
      if (size < 1024) return '${size}B';
      if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
      return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    } catch (e) {
      return fileSize;
    }
  }
}
