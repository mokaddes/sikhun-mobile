class NotificationModel {
  final int id;
  final String title;
  final String body;
  final String? type;
  final Map<String, dynamic>? data;
  final DateTime? readAt;
  final DateTime? createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.type,
    this.data,
    this.readAt,
    this.createdAt,
  });

  bool get isRead => readAt != null;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? 'নোটিফিকেশন',
      body: json['body']?.toString() ?? '',
      type: json['type']?.toString(),
      data: json['data'] is Map<String, dynamic> ? json['data'] : null,
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at'].toString()) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }
}
