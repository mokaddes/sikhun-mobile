class ChapterModel {
  final int id;
  final int bookId;
  final String title;
  final int chapterNumber;
  final int pageStart;
  final int pageEnd;
  final double price;
  final bool isFree;
  final bool isPurchased;
  final String? readerUrl;

  ChapterModel({
    required this.id,
    required this.bookId,
    required this.title,
    this.chapterNumber = 1,
    this.pageStart = 1,
    this.pageEnd = 1,
    this.price = 0.0,
    this.isFree = false,
    this.isPurchased = false,
    this.readerUrl,
  });

  factory ChapterModel.fromJson(Map<String, dynamic> json) {
    return ChapterModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      bookId: json['book_id'] is int ? json['book_id'] : int.tryParse(json['book_id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? json['name']?.toString() ?? 'অধ্যায়',
      chapterNumber: json['chapter_number'] ?? json['order'] ?? 1,
      pageStart: json['page_start'] ?? json['start_page'] ?? 1,
      pageEnd: json['page_end'] ?? json['end_page'] ?? 1,
      price: (json['price'] != null)
          ? double.tryParse(json['price'].toString()) ?? 0.0
          : 0.0,
      isFree: json['is_free'] == true || json['is_free'] == 1,
      isPurchased: json['is_purchased'] == true || json['purchased'] == true,
      readerUrl: json['reader_url']?.toString(),
    );
  }

  bool get canRead => isFree || isPurchased || price <= 0;
}

class BookModel {
  final int id;
  final String title;
  final String? slug;
  final String? description;
  final String? author;
  final String? publisher;
  final String? subject;
  final String? gradeLevel;
  final double price;
  final double? discountPrice;
  final String? coverImage;
  final int totalPages;
  final bool isFree;
  final bool isPurchased;
  final bool inBookshelf;
  final double progress;
  final int? lastReadPage;
  final List<ChapterModel> chapters;

  BookModel({
    required this.id,
    required this.title,
    this.slug,
    this.description,
    this.author,
    this.publisher,
    this.subject,
    this.gradeLevel,
    this.price = 0.0,
    this.discountPrice,
    this.coverImage,
    this.totalPages = 0,
    this.isFree = false,
    this.isPurchased = false,
    this.inBookshelf = false,
    this.progress = 0.0,
    this.lastReadPage,
    this.chapters = const [],
  });

  factory BookModel.fromJson(Map<String, dynamic> json) {
    // 1. Author Resolution (handle String, Map {id, name}, or null)
    String parsedAuthor = 'শিখুন';
    if (json['author'] is Map) {
      parsedAuthor = json['author']['name']?.toString() ?? 'শিখুন';
    } else if (json['author'] is String && json['author'].toString().isNotEmpty) {
      parsedAuthor = json['author'].toString();
    }

    // 2. Publisher Resolution
    String parsedPublisher = 'শিখুন প্রকাশনী';
    if (json['publication'] is Map) {
      parsedPublisher = json['publication']['name']?.toString() ?? 'শিখুন প্রকাশনী';
    } else if (json['publisher'] is Map) {
      parsedPublisher = json['publisher']['name']?.toString() ?? 'শিখুন প্রকাশনী';
    } else if (json['publisher'] is String && json['publisher'].toString().isNotEmpty) {
      parsedPublisher = json['publisher'].toString();
    }

    // 3. Cover Image Resolution (ensure full URL with https://sikhun.com/storage/)
    String? rawCover = json['cover_image_url']?.toString() ??
        json['cover_url']?.toString() ??
        json['cover_image']?.toString();
    String? resolvedCover;
    if (rawCover != null && rawCover.isNotEmpty) {
      if (rawCover.startsWith('http')) {
        resolvedCover = rawCover;
      } else {
        final cleanPath = rawCover.startsWith('/') ? rawCover.substring(1) : rawCover;
        if (cleanPath.startsWith('storage/')) {
          resolvedCover = 'https://sikhun.com/$cleanPath';
        } else {
          resolvedCover = 'https://sikhun.com/storage/$cleanPath';
        }
      }
    }

    var rawChapters = json['chapters'] as List?;
    List<ChapterModel> chapterList = rawChapters != null
        ? rawChapters.map((c) => ChapterModel.fromJson(c as Map<String, dynamic>)).toList()
        : [];

    return BookModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString(),
      description: json['description']?.toString(),
      author: parsedAuthor,
      publisher: parsedPublisher,
      subject: json['subject']?.toString(),
      gradeLevel: json['grade_level']?.toString() ?? json['class']?.toString() ?? json['level']?.toString(),
      price: (json['price'] != null)
          ? double.tryParse(json['price'].toString()) ?? 0.0
          : 0.0,
      discountPrice: (json['discount_price'] != null)
          ? double.tryParse(json['discount_price'].toString())
          : null,
      coverImage: resolvedCover,
      totalPages: json['total_pages'] ?? json['pages_count'] ?? 0,
      isFree: json['is_free'] == true || json['is_free'] == 1 || (json['price'] != null && (double.tryParse(json['price'].toString()) ?? 0.0) == 0.0),
      isPurchased: json['is_purchased'] == true || json['purchased'] == true,
      inBookshelf: json['in_bookshelf'] == true || json['in_shelf'] == true,
      progress: (json['progress'] != null)
          ? double.tryParse(json['progress'].toString()) ?? 0.0
          : 0.0,
      lastReadPage: json['last_read_page'],
      chapters: chapterList,
    );
  }

  String get effectivePriceDisplay {
    if (price <= 0 || isFree) {
      return 'ফ্রি';
    }
    final effective = discountPrice ?? price;
    return '৳${effective.toStringAsFixed(effective.truncateToDouble() == effective ? 0 : 2)}';
  }

  String get readerUrl => 'https://sikhun.com/library/$id/read';
}
