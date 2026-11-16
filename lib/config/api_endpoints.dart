class ApiEndpoints {
  static const String baseUrl = 'https://sikhun.com/api';
  static const String siteUrl = 'https://sikhun.com';

  // Auth
  static const String register = '$baseUrl/auth/register';
  static const String login = '$baseUrl/auth/login';
  static const String logout = '$baseUrl/auth/logout';
  static const String me = '$baseUrl/auth/me';

  // Library & Books
  static const String library = '$baseUrl/library';
  static String bookDetails(String slug) => '$baseUrl/library/$slug';
  static String bookChapters(int bookId) => '$baseUrl/library/$bookId/chapters';
  static String bookAccess(int bookId) => '$baseUrl/library/$bookId/access';
  static String purchaseBook(int bookId) => '$baseUrl/library/$bookId/purchase';
  static String purchaseChapter(int bookId, int chapterId) =>
      '$baseUrl/library/$bookId/chapters/$chapterId/purchase';
  static String purchaseChapters(int bookId) =>
      '$baseUrl/library/$bookId/chapters/purchase';
  static String readerPageUrl(int bookId, int page) =>
      '$baseUrl/reader/$bookId/page/$page/url';

  // Bookshelf
  static const String bookshelf = '$baseUrl/bookshelf';
  static String addToShelf(int bookId) => '$baseUrl/bookshelf/$bookId';
  static String removeFromShelf(int bookId) => '$baseUrl/bookshelf/$bookId';

  // Question Bank
  static const String questionBank = '$baseUrl/question-bank';
  static const String questionBankFilters = '$baseUrl/question-bank/filters';
  static String questionDetails(int id) => '$baseUrl/question-bank/$id';

  // Courses
  static const String courses = '$baseUrl/courses';
  static String courseDetails(String slug) => '$baseUrl/courses/$slug';

  // AI Chat
  static const String aiSessions = '$baseUrl/ai/chat/sessions';
  static String aiSessionMessages(int sessionId) =>
      '$baseUrl/ai/chat/sessions/$sessionId/message';

  // Blogs
  static const String blogs = '$baseUrl/blogs';
  static const String blogCategories = '$baseUrl/blogs/categories';
  static String blogDetails(String slug) => '$baseUrl/blogs/$slug';

  // Wallet
  static const String wallet = '$baseUrl/wallet';
  static const String walletTransactions = '$baseUrl/wallet/transactions';
  static const String walletRecharge = '$baseUrl/wallet/recharge';

  // Profile & Settings
  static const String profile = '$baseUrl/profile';
  static const String settings = '$baseUrl/settings';
  static const String dashboard = '$baseUrl/dashboard';
  static const String updatePassword = '$baseUrl/profile/password';
  static const String updateTheme = '$baseUrl/profile/theme';

  // Notifications & Push
  static const String notifications = '$baseUrl/notifications';
  static String notificationMarkRead(int id) => '$baseUrl/notifications/$id/read';
  static const String notificationsMarkAllRead = '$baseUrl/notifications/read-all';
  static const String registerFcmToken = '$baseUrl/profile/fcm-token';
}
