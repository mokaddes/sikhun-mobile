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
      walletBalance: json['wallet_balance'] != null
          ? double.tryParse(json['wallet_balance'].toString()) ?? 0.0
          : 0.0,
      booksOwned: json['books_owned'] ?? 0,
      examsTaken: json['exams_taken'] ?? 0,
      coursesEnrolled: json['courses_enrolled'] ?? 0,
      unresolvedMistakes: json['unresolved_mistakes'] ?? 0,
    );
  }
}

class PendingOrderModel {
  final int id;
  final String orderNumber;
  final String orderableType;
  final double amount;
  final String paymentMethod;
  final String? gatewayTransactionId;

  PendingOrderModel({
    required this.id,
    required this.orderNumber,
    required this.orderableType,
    required this.amount,
    required this.paymentMethod,
    this.gatewayTransactionId,
  });

  factory PendingOrderModel.fromJson(Map<String, dynamic> json) {
    return PendingOrderModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      orderNumber: json['order_number']?.toString() ?? '',
      orderableType: json['orderable_type']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      paymentMethod: json['payment_method']?.toString() ?? '',
      gatewayTransactionId: json['gateway_transaction_id']?.toString(),
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
    String? rawCover = json['cover_image_url']?.toString() ?? json['cover_image']?.toString();
    if (rawCover != null && rawCover.isNotEmpty && !rawCover.startsWith('http')) {
      final clean = rawCover.startsWith('/') ? rawCover.substring(1) : rawCover;
      rawCover = 'https://sikhun.com/${clean.startsWith('storage/') ? clean : 'storage/$clean'}';
    }

    final int total = json['total_pages'] ?? 1;
    final int curr = json['current_page'] ?? json['last_page'] ?? 1;
    final int pct = json['progress'] != null
        ? (int.tryParse(json['progress'].toString()) ?? 0)
        : (total > 0 ? ((curr / total) * 100).round().clamp(0, 100).toInt() : 0);

    return ContinueReadingModel(
      bookId: json['book_id'] ?? json['id'] ?? 0,
      bookTitle: json['book_title'] ?? json['title'] ?? 'বই',
      bookSlug: json['book_slug']?.toString() ?? json['slug']?.toString(),
      coverImage: rawCover,
      currentPage: curr,
      totalPages: total,
      progress: pct,
    );
  }
}

class DashboardDataModel {
  final DashboardStatsModel stats;
  final PendingOrderModel? pendingOrder;
  final ContinueReadingModel? continueReading;
  final Map<String, dynamic>? continueCourse;
  final List<dynamic> recentExams;
  final List<dynamic> leaderboardTop;
  final dynamic myRank;
  final Map<String, dynamic>? activeSubscription;
  final Map<String, dynamic>? access;
  final bool canAccessQuestionBank;
  final bool onboardingCompleted;

  DashboardDataModel({
    required this.stats,
    this.pendingOrder,
    this.continueReading,
    this.continueCourse,
    this.recentExams = const [],
    this.leaderboardTop = const [],
    this.myRank,
    this.activeSubscription,
    this.access,
    this.canAccessQuestionBank = false,
    this.onboardingCompleted = true,
  });

  double get walletBalance => stats.walletBalance;
  int get booksOwned => stats.booksOwned;
  int get examsTaken => stats.examsTaken;
  int get coursesEnrolled => stats.coursesEnrolled;
  int get unresolvedMistakes => stats.unresolvedMistakes;

  String get activeSubscriptionPlan =>
      activeSubscription?['plan']?['name']?.toString() ??
      (access?['has_access'] == true ? 'ফ্রি অ্যাক্সেস পাস' : 'ফ্রি / ট্রায়াল');

  String? get activeSubscriptionExpiresAt {
    final raw = activeSubscription?['expires_at']?.toString() ?? access?['expires_at']?.toString();
    if (raw == null || raw.isEmpty) return null;
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  factory DashboardDataModel.fromJson(Map<String, dynamic> json) {
    return DashboardDataModel(
      stats: json['stats'] != null
          ? DashboardStatsModel.fromJson(json['stats'])
          : DashboardStatsModel(),
      pendingOrder: json['pending_order'] is Map<String, dynamic>
          ? PendingOrderModel.fromJson(json['pending_order'])
          : null,
      continueReading: json['continue_reading'] is Map<String, dynamic>
          ? ContinueReadingModel.fromJson(json['continue_reading'])
          : null,
      continueCourse: json['continue_course'] is Map<String, dynamic>
          ? json['continue_course'] as Map<String, dynamic>
          : null,
      recentExams: json['recent_exams'] ?? [],
      leaderboardTop: json['leaderboard_top'] ?? [],
      myRank: json['my_rank'],
      activeSubscription: json['active_subscription'] is Map<String, dynamic>
          ? json['active_subscription'] as Map<String, dynamic>
          : null,
      access: json['access'] is Map<String, dynamic>
          ? json['access'] as Map<String, dynamic>
          : null,
      canAccessQuestionBank: json['can_access_question_bank'] == true,
      onboardingCompleted: json['onboarding']?['completed'] != false,
    );
  }
}
