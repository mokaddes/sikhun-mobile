class BlogModel {
  final int id;
  final String title;
  final String slug;
  final String? excerpt;
  final String? content;
  final String? coverImage;
  final String? category;
  final List<String> tags;
  final String? authorName;
  final int viewsCount;
  final int readingTime;
  final String? publishedAt;

  BlogModel({
    required this.id,
    required this.title,
    required this.slug,
    this.excerpt,
    this.content,
    this.coverImage,
    this.category,
    this.tags = const [],
    this.authorName,
    this.viewsCount = 0,
    this.readingTime = 5,
    this.publishedAt,
  });

  factory BlogModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedTags = [];
    if (json['tags'] is List) {
      parsedTags = (json['tags'] as List).map((t) {
        if (t is Map) return t['name']?.toString() ?? '';
        return t.toString();
      }).where((t) => t.isNotEmpty).toList();
    } else if (json['tags'] is String && (json['tags'] as String).isNotEmpty) {
      parsedTags = (json['tags'] as String).split(',').map((t) => t.trim()).toList();
    }

    return BlogModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      excerpt: json['excerpt']?.toString() ?? json['summary']?.toString(),
      content: json['content']?.toString() ?? json['body']?.toString(),
      coverImage: json['cover_image']?.toString() ?? json['featured_image']?.toString(),
      category: json['category'] is Map ? json['category']['name']?.toString() : json['category']?.toString(),
      tags: parsedTags,
      authorName: json['author'] is Map ? json['author']['name']?.toString() : json['author']?.toString() ?? 'শিখুন সম্পাদকীয়',
      viewsCount: json['views_count'] ?? json['views'] ?? 0,
      readingTime: json['reading_time'] ?? 5,
      publishedAt: json['published_at']?.toString() ?? json['created_at']?.toString(),
    );
  }
}
