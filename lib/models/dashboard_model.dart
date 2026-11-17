class DashboardStatsModel {
  final double walletBalance;
  final int booksOwned;
  final int examsTaken;
  final int coursesEnrolled;
  final int unresolvedMistakes;

  DashboardStatsModel({
    this.walletBalance = 0.0,
    this.booksOwned = 0,
    this.examsTaken = 0,
    this.coursesEnrolled = 0,
    this.unresolvedMistakes = 0,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      walletBalance: (json['wallet_balance'] != null)
          ? double.tryParse(json['wallet_balance'].toString()) ?? 0.0
          : 0.0,
      booksOwned: json['books_owned'] ?? 0,
      examsTaken: json['exams_taken'] ?? 0,
      coursesEnrolled: json['courses_enrolled'] ?? 0,
      unresolvedMistakes: json['unresolved_mistakes'] ?? 0,
    );
  }
}

class ContinueReadingModel {
  final int bookId;
  final String bookTitle;
  final String? bookSlug;
  final String? coverImage;
  final int currentPage;
  final int totalPages;
  final int progress;

  ContinueReadingModel({
    required this.bookId,
    required this.bookTitle,
    this.bookSlug,
    this.coverImage,
    this.currentPage = 1,
    this.totalPages = 1,
    this.progress = 0,
  });

  String get chapterTitle => 'পৃষ্ঠা: $currentPage / $totalPages';
  double get progressPercent => progress.toDouble();

  factory ContinueReadingModel.fromJson(Map<String, dynamic> json) {
    String? rawCover = json['cover_image']?.toString();
    if (rawCover != null && !rawCover.startsWith('http')) {
      final clean = rawCover.startsWith('/') ? rawCover.substring(1) : rawCover;
      rawCover = 'https://sikhun.com/${clean.startsWith('storage/') ? clean : 'storage/$clean'}';
    }

    return ContinueReadingModel(
      bookId: json['book_id'] ?? 0,
      bookTitle: json['book_title'] ?? 'বই',
      bookSlug: json['book_slug']?.toString(),
      coverImage: rawCover,
      currentPage: json['current_page'] ?? 1,
      totalPages: json['total_pages'] ?? 1,
      progress: (json['progress'] != null)
          ? int.tryParse(json['progress'].toString()) ?? 0
          : 0,
    );
  }
}

class DashboardDataModel {
  final DashboardStatsModel stats;
  final ContinueReadingModel? continueReading;
  final Map<String, dynamic>? continueCourse;
  final List<dynamic> recentExams;
  final List<dynamic> leaderboardTop;
  final dynamic myRank;
  final Map<String, dynamic>? activeSubscription;

  DashboardDataModel({
    required this.stats,
    this.continueReading,
    this.continueCourse,
    this.recentExams = const [],
    this.leaderboardTop = const [],
    this.myRank,
    this.activeSubscription,
  });

  double get walletBalance => stats.walletBalance;
  int get booksOwned => stats.booksOwned;
  int get examsTaken => stats.examsTaken;
  int get coursesEnrolled => stats.coursesEnrolled;
  int get unresolvedMistakes => stats.unresolvedMistakes;
  String get activeSubscriptionPlan => activeSubscription?['plan']?['name']?.toString() ?? 'স্টার্টার লার্নার';

  factory DashboardDataModel.fromJson(Map<String, dynamic> json) {
    return DashboardDataModel(
      stats: json['stats'] != null
          ? DashboardStatsModel.fromJson(json['stats'])
          : DashboardStatsModel(),
      continueReading: json['continue_reading'] != null
          ? ContinueReadingModel.fromJson(json['continue_reading'])
          : null,
      continueCourse: json['continue_course'],
      recentExams: json['recent_exams'] ?? [],
      leaderboardTop: json['leaderboard_top'] ?? [],
      myRank: json['my_rank'],
      activeSubscription: json['active_subscription'],
    );
  }
}
