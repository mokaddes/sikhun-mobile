class BlogModel {
  final int id;
  final String title;
  final String slug;
  final String? excerpt;
  final String? content;
  final String? coverImage;
  final String? category;
  final String? categorySlug;
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
    this.categorySlug,
    this.tags = const [],
    this.authorName,
    this.viewsCount = 0,
    this.readingTime = 5,
    this.publishedAt,
  });

  factory BlogModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedTags = [];
    if (json['tags'] is List) {
      parsedTags = (json['tags'] as List)
          .map((t) {
            if (t is Map) {
              return (t['name_bn'] ?? t['name_en'] ?? t['name'])?.toString() ?? '';
            }
            return t.toString();
          })
          .where((t) => t.isNotEmpty)
          .toList();
    } else if (json['tags'] is String && (json['tags'] as String).isNotEmpty) {
      parsedTags = (json['tags'] as String).split(',').map((t) => t.trim()).toList();
    }

    String? rawCover = (json['featured_image'] ?? json['cover_image'])?.toString();
    if (rawCover != null && rawCover.isNotEmpty && !rawCover.startsWith('http')) {
      final clean = rawCover.startsWith('/') ? rawCover.substring(1) : rawCover;
      rawCover = clean.startsWith('storage/') || clean.startsWith('images/')
          ? 'https://sikhun.com/$clean'
          : 'https://sikhun.com/storage/$clean';
    }

    String? catName;
    String? catSlug;
    if (json['category'] is Map) {
      catName = (json['category']['name_bn'] ?? json['category']['name_en'] ?? json['category']['name'])?.toString();
      catSlug = json['category']['slug']?.toString();
    } else if (json['category'] != null) {
      catName = json['category'].toString();
    }

    return BlogModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      excerpt: json['excerpt']?.toString() ?? json['summary']?.toString(),
      content: json['content']?.toString() ?? json['body']?.toString(),
      coverImage: rawCover,
      category: catName,
      categorySlug: catSlug,
      tags: parsedTags,
      authorName: json['author'] is Map
          ? json['author']['name']?.toString()
          : json['author']?.toString() ?? 'শিখুন সম্পাদকীয়',
      viewsCount: json['view_count'] ?? json['views_count'] ?? json['views'] ?? 0,
      readingTime: json['reading_time_minutes'] ?? json['reading_time'] ?? 5,
      publishedAt: json['published_at']?.toString() ?? json['created_at']?.toString(),
    );
  }
}
