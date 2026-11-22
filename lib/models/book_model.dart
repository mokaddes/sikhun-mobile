class ChapterModel {
  final int id;
  final int bookId;
  final int? parentId;
  final int level;
  final String title;
  final int chapterNumber;
  final int pageStart;
  final int pageEnd;
  final double price;
  final bool isFree;
  final bool isPurchased;
  final bool purchasable;
  final String? readerUrl;

  ChapterModel({
    required this.id,
    required this.bookId,
    this.parentId,
    this.level = 1,
    required this.title,
    this.chapterNumber = 1,
    this.pageStart = 1,
    this.pageEnd = 1,
    this.price = 0.0,
    this.isFree = false,
    this.isPurchased = false,
    this.purchasable = false,
    this.readerUrl,
  });

  factory ChapterModel.fromJson(Map<String, dynamic> json) {
    final parsedPrice = json['price'] != null
        ? double.tryParse(json['price'].toString()) ?? 0.0
        : 0.0;
    final owned = json['owned'] == true ||
        json['is_purchased'] == true ||
        json['purchased'] == true;
    final free = json['is_free'] == true ||
        json['is_free'] == 1 ||
        (json['purchasable'] == false && owned);

    return ChapterModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      bookId: json['book_id'] is int ? json['book_id'] : int.tryParse(json['book_id']?.toString() ?? '0') ?? 0,
      parentId: json['parent_id'] is int ? json['parent_id'] : int.tryParse(json['parent_id']?.toString() ?? ''),
      level: json['level'] is int ? json['level'] : int.tryParse(json['level']?.toString() ?? '1') ?? 1,
      title: json['title']?.toString() ?? json['name']?.toString() ?? 'অধ্যায়',
      chapterNumber: int.tryParse((json['chapter_number'] ?? json['order'] ?? 1).toString()) ?? 1,
      pageStart: int.tryParse((json['page_start'] ?? json['start_page'] ?? 1).toString()) ?? 1,
      pageEnd: int.tryParse((json['page_end'] ?? json['end_page'] ?? 1).toString()) ?? 1,
      price: parsedPrice,
      isFree: free,
      isPurchased: owned,
      purchasable: json['purchasable'] == true,
      readerUrl: json['reader_url']?.toString(),
    );
  }

  bool get canRead => isFree || isPurchased;
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
  final bool hasAccess;
  final String? accessType;
  final bool chapterPurchaseEnabled;
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
    this.hasAccess = false,
    this.accessType,
    this.chapterPurchaseEnabled = false,
    this.inBookshelf = false,
    this.progress = 0.0,
    this.lastReadPage,
    this.chapters = const [],
  });

  BookModel copyWith({
    List<ChapterModel>? chapters,
    bool? hasAccess,
    String? accessType,
    bool? chapterPurchaseEnabled,
    bool? inBookshelf,
  }) {
    return BookModel(
      id: id,
      title: title,
      slug: slug,
      description: description,
      author: author,
      publisher: publisher,
      subject: subject,
      gradeLevel: gradeLevel,
      price: price,
      discountPrice: discountPrice,
      coverImage: coverImage,
      totalPages: totalPages,
      isFree: isFree,
      isPurchased: isPurchased,
      hasAccess: hasAccess ?? this.hasAccess,
      accessType: accessType ?? this.accessType,
      chapterPurchaseEnabled: chapterPurchaseEnabled ?? this.chapterPurchaseEnabled,
      inBookshelf: inBookshelf ?? this.inBookshelf,
      progress: progress,
      lastReadPage: lastReadPage,
      chapters: chapters ?? this.chapters,
    );
  }

  factory BookModel.fromJson(Map<String, dynamic> json) {
    String parsedAuthor = 'শিখুন';
    if (json['author'] is Map) {
      parsedAuthor = json['author']['name']?.toString() ?? 'শিখুন';
    } else if (json['author'] is String && json['author'].toString().isNotEmpty) {
      parsedAuthor = json['author'].toString();
    }

    String parsedPublisher = 'শিখুন প্রকাশনী';
    if (json['publication'] is Map) {
      parsedPublisher = json['publication']['name']?.toString() ?? 'শিখুন প্রকাশনী';
    } else if (json['publisher'] is Map) {
      parsedPublisher = json['publisher']['name']?.toString() ?? 'শিখুন প্রকাশনী';
    } else if (json['publisher'] is String && json['publisher'].toString().isNotEmpty) {
      parsedPublisher = json['publisher'].toString();
    }

    String? rawCover = json['cover_image_url']?.toString() ??
        json['cover_url']?.toString() ??
        json['cover_image']?.toString();
    String? resolvedCover;
    if (rawCover != null && rawCover.isNotEmpty) {
      if (rawCover.startsWith('http')) {
        resolvedCover = rawCover;
      } else {
        final cleanPath = rawCover.startsWith('/') ? rawCover.substring(1) : rawCover;
        resolvedCover = cleanPath.startsWith('storage/')
            ? 'https://sikhun.com/$cleanPath'
            : 'https://sikhun.com/storage/$cleanPath';
      }
    }

    final rawChapters = json['chapters'] as List?;
    final chapterList = rawChapters != null
        ? rawChapters.map((c) => ChapterModel.fromJson(c as Map<String, dynamic>)).toList()
        : <ChapterModel>[];

    final parsedPrice = json['price'] != null
        ? double.tryParse(json['price'].toString()) ?? 0.0
        : 0.0;
    final free = json['is_free'] == true || json['is_free'] == 1 || parsedPrice == 0.0;
    final hasAcc = json['has_access'] == true ||
        json['is_purchased'] == true ||
        json['purchased'] == true ||
        free;

    return BookModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString(),
      description: json['description']?.toString(),
      author: parsedAuthor,
      publisher: parsedPublisher,
      subject: json['subject']?.toString(),
      gradeLevel: json['grade_level']?.toString() ?? json['class']?.toString() ?? json['level']?.toString(),
      price: parsedPrice,
      discountPrice: json['discount_price'] != null
          ? double.tryParse(json['discount_price'].toString())
          : null,
      coverImage: resolvedCover,
      totalPages: json['total_pages'] ?? json['pages_count'] ?? 0,
      isFree: free,
      isPurchased: json['is_purchased'] == true || json['purchased'] == true || json['access_type'] == 'purchased',
      hasAccess: hasAcc,
      accessType: json['access_type']?.toString(),
      chapterPurchaseEnabled: json['chapter_purchase_enabled'] == true || json['chapter_purchase_enabled'] == 1,
      inBookshelf: json['in_bookshelf'] == true || json['in_shelf'] == true,
      progress: json['progress'] != null ? double.tryParse(json['progress'].toString()) ?? 0.0 : 0.0,
      lastReadPage: json['last_read_page'],
      chapters: chapterList,
    );
  }

  bool get isPaidBook => !isFree && price > 0;

  String get effectivePriceDisplay {
    if (price <= 0 || isFree) {
      return 'বিনামূল্যে';
    }
    final effective = discountPrice ?? price;
    return '৳${effective.toStringAsFixed(effective.truncateToDouble() == effective ? 0 : 2)}';
  }

  String get readerUrl => 'https://sikhun.com/library/$id/read';
}
