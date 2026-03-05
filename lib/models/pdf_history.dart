class PdfHistory {
  final String id;
  final String title;
  final String path;
  final int sizeInBytes;
  final DateTime createdAt;

  PdfHistory({
    required this.id,
    required this.title,
    required this.path,
    required this.sizeInBytes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'path': path,
      'sizeInBytes': sizeInBytes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PdfHistory.fromJson(Map<String, dynamic> json) {
    return PdfHistory(
      id: json['id'],
      title: json['title'],
      path: json['path'],
      sizeInBytes: json['sizeInBytes'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
