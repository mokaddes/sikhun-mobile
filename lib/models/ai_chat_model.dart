class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final int? bookId;
  final int? pageNumber;
  final String? bookTitle;
  final bool isError;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.bookId,
    this.pageNumber,
    this.bookTitle,
    this.isError = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      content: json['message'] ?? json['content'] ?? '',
      isUser: json['sender'] == 'user' || json['role'] == 'user' || json['is_user'] == true,
      timestamp: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      bookId: json['book_id'],
      pageNumber: json['page_number'],
      bookTitle: json['book_title'],
      isError: json['is_error'] == true,
    );
  }
}
