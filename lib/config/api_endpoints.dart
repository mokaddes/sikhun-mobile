class ApiEndpoints {
  static const String baseUrl = 'https://sikhun.com/api';
  static const String siteUrl = 'https://sikhun.com';

  // Auth & Email Verification & Password Reset
  static const String register = '$baseUrl/auth/register';
  static const String login = '$baseUrl/auth/login';
  static const String logout = '$baseUrl/auth/logout';
  static const String me = '$baseUrl/auth/me';
  static const String forgotPassword = '$baseUrl/auth/forgot-password';
  static const String resetPassword = '$baseUrl/auth/reset-password';
  static const String sendVerification = '$baseUrl/auth/email/verification-notification';

  // Public Content & Portals
  static const String home = '$baseUrl/home';
  static const String contact = '$baseUrl/contact';
  static const String publicPlans = '$baseUrl/plans';
  static String customPage(String slug) => '$baseUrl/pages/$slug';

  // Blogs
  static const String blogs = '$baseUrl/blog';
  static String blogCategory(String slug) => '$baseUrl/blog/category/$slug';
  static String blogDetails(String slug) => '$baseUrl/blog/$slug';

  // Portals (Job News & Admission Notices)
  static const String jobNews = '$baseUrl/job-news';
  static String jobDetails(String slug) => '$baseUrl/job-news/$slug';
  static const String admissionNotices = '$baseUrl/admission-notice';
  static String admissionDetails(String slug) => '$baseUrl/admission-notice/$slug';

  // Dashboard & Onboarding
  static const String dashboard = '$baseUrl/dashboard';
  static const String onboarding = '$baseUrl/onboarding';
  static const String onboardingStep = '$baseUrl/onboarding/step';
  static const String onboardingSkip = '$baseUrl/onboarding/skip';

  // Library, Purchases & Bookshelf
  static const String library = '$baseUrl/library';
  static String bookDetails(String slug) => '$baseUrl/library/$slug';
  static String bookChapters(int bookId) => '$baseUrl/library/$bookId/chapters';
  static String bookAccess(int bookId) => '$baseUrl/library/$bookId/access';
  static String purchaseBook(int bookId) => '$baseUrl/library/$bookId/purchase';
  static String addToShelf(int bookId) => '$baseUrl/library/$bookId/shelf';
  static String purchaseChapter(int bookId, int chapterId) =>
      '$baseUrl/library/$bookId/chapters/$chapterId/purchase';
  static String purchaseChapters(int bookId) =>
      '$baseUrl/library/$bookId/chapters/purchase';

  static const String bookshelf = '$baseUrl/bookshelf';

  // Catalog Reader
  static String readerShow(int bookId) => '$baseUrl/reader/$bookId';
  static String readerPageUrl(int bookId, int page) =>
      '$baseUrl/reader/$bookId/page/$page/url';
  static String readerProgress(int bookId) => '$baseUrl/reader/$bookId/progress';
  static String readerChat(int bookId) => '$baseUrl/reader/$bookId/chat';

  // My Books (Student Uploaded PDFs & Reader)
  static const String myBooks = '$baseUrl/my-books';
  static String deleteMyBook(int id) => '$baseUrl/my-books/$id';
  static String myBookRead(int id) => '$baseUrl/my-books/$id/read';
  static String myBookPageUrl(int id, int page) =>
      '$baseUrl/my-books/$id/read/page/$page/url';
  static String myBookProgress(int id) => '$baseUrl/my-books/$id/read/progress';
  static String myBookChat(int id) => '$baseUrl/my-books/$id/read/chat';

  // Courses
  static const String courses = '$baseUrl/courses';
  static String courseDetails(String slug) => '$baseUrl/courses/$slug';
  static String enrollCourse(int courseId) => '$baseUrl/courses/$courseId/enroll';
  static String courseLesson(int courseId, int sectionId, int lessonId) =>
      '$baseUrl/courses/$courseId/sections/$sectionId/lessons/$lessonId';
  static String completeLesson(int courseId, int sectionId, int lessonId) =>
      '$baseUrl/courses/$courseId/sections/$sectionId/lessons/$lessonId/complete';
  static String courseLessonVideo(String slug, int sectionId, int lessonId) =>
      '$baseUrl/courses/$slug/sections/$sectionId/lessons/$lessonId/video';
  static String courseLessonDownload(String slug, int sectionId, int lessonId) =>
      '$baseUrl/courses/$slug/sections/$sectionId/lessons/$lessonId/download';

  // Wallet, Orders & Invoices
  static const String wallet = '$baseUrl/wallet';
  static const String walletTransactions = '$baseUrl/wallet/transactions';
  static const String walletRecharge = '$baseUrl/wallet/recharge';
  static String verifyOrder(int orderId) => '$baseUrl/wallet/orders/$orderId/verify';

  static const String invoices = '$baseUrl/invoices';
  static String invoiceDetails(int id) => '$baseUrl/invoices/$id';
  static String payInvoice(int id) => '$baseUrl/invoices/$id/pay';

  // Subscriptions & Custom Plan Builder
  static const String subscriptionsPlans = '$baseUrl/subscriptions/plans';
  static const String subscriptionsActive = '$baseUrl/subscriptions/active';
  static const String subscriptionsPurchase = '$baseUrl/subscriptions/purchase';
  static const String subscriptionsCustomPurchase = '$baseUrl/subscriptions/custom/purchase';

  // Question Bank & Mistake Review
  static const String questionBank = '$baseUrl/question-bank';
  static String questionBankAiExplain(int id) => '$baseUrl/question-bank/$id/ai-explain';
  static const String questionBankGenerateTest = '$baseUrl/question-bank/generate-test';

  static const String mistakes = '$baseUrl/mistakes';
  static const String mistakesPractice = '$baseUrl/mistakes/practice';
  static const String mistakesReset = '$baseUrl/mistakes/reset';

  // AI Chat
  static const String aiSessions = '$baseUrl/ai/chat/sessions';
  static String aiSession(int sessionId) => '$baseUrl/ai/chat/sessions/$sessionId';
  static String aiSessionBook(int sessionId) => '$baseUrl/ai/chat/sessions/$sessionId/book';
  static String aiSessionMessages(int sessionId) => '$baseUrl/ai/chat/sessions/$sessionId/message';

  // AI Exams
  static const String exams = '$baseUrl/exams';
  static const String examsCreateData = '$baseUrl/exams/create-data';
  static String examDetails(int examId) => '$baseUrl/exams/$examId';
  static String examStatus(int examId) => '$baseUrl/exams/$examId/status';
  static String examRetry(int examId) => '$baseUrl/exams/$examId/retry';
  static String examComplete(int examId) => '$baseUrl/exams/$examId/complete';
  static String examResult(int examId) => '$baseUrl/exams/$examId/result';
  static String examQuestionExplanation(int examId, int questionId) =>
      '$baseUrl/exams/$examId/questions/$questionId/explanation';
  static String examPdf(int examId) => '$baseUrl/exams/$examId/pdf';

  // AI Flashcards
  static const String flashcards = '$baseUrl/flashcards';
  static const String flashcardsCreateData = '$baseUrl/flashcards/create-data';
  static String flashcardDetails(int setId) => '$baseUrl/flashcards/$setId';
  static String flashcardRetry(int setId) => '$baseUrl/flashcards/$setId/retry';
  static String flashcardReview(int setId, int cardId) =>
      '$baseUrl/flashcards/$setId/review/$cardId';
  static String flashcardPdf(int setId) => '$baseUrl/flashcards/$setId/pdf';

  // AI Essay Grader
  static const String essays = '$baseUrl/essays';
  static String essayDetails(int essayId) => '$baseUrl/essays/$essayId';
  static String essayStatus(int essayId) => '$baseUrl/essays/$essayId/status';
  static String essayRetry(int essayId) => '$baseUrl/essays/$essayId/retry';

  // Study Schedule Maker
  static const String schedules = '$baseUrl/schedules';
  static String scheduleDetails(int scheduleId) => '$baseUrl/schedules/$scheduleId';
  static String scheduleStatus(int scheduleId) => '$baseUrl/schedules/$scheduleId/status';
  static String scheduleRetry(int scheduleId) => '$baseUrl/schedules/$scheduleId/retry';
  static String scheduleProgress(int scheduleId) => '$baseUrl/schedules/$scheduleId/progress';
  static String schedulePdf(int scheduleId) => '$baseUrl/schedules/$scheduleId/pdf';

  // Leaderboard, Referrals & Free Access Coupons
  static const String leaderboard = '$baseUrl/leaderboard';
  static const String leaderboardMyRank = '$baseUrl/leaderboard/my-rank';
  static const String referrals = '$baseUrl/referrals';
  static const String referralsStats = '$baseUrl/referrals/stats';
  static const String accessStatus = '$baseUrl/access/status';
  static const String accessRedeem = '$baseUrl/access/redeem';

  // Profile & Settings
  static const String profile = '$baseUrl/profile';
  static const String settings = '$baseUrl/home'; // home returns active site info & plans
  static const String updatePassword = '$baseUrl/profile/password';
  static const String updateTheme = '$baseUrl/profile/theme';
  static const String updateLeaderboardOptOut = '$baseUrl/profile/leaderboard-opt-out';
  static const String updateNotifications = '$baseUrl/profile/notifications';
  static const String registerFcmToken = '$baseUrl/profile/fcm-token';

  // Notifications
  static const String notifications = '$baseUrl/notifications';
  static String notificationMarkRead(int id) => '$baseUrl/notifications/$id/read';
  static const String notificationsMarkAllRead = '$baseUrl/notifications/read-all';
  static String notificationDelete(int id) => '$baseUrl/notifications/$id';

  // Support Bot, Tickets & Feedback
  static const String supportConversation = '$baseUrl/support/conversation';
  static const String supportMessage = '$baseUrl/support/message';
  static const String supportHandoff = '$baseUrl/support/conversation/ticket';
  static const String supportTickets = '$baseUrl/support/tickets';
  static String supportTicketDetails(int id) => '$baseUrl/support/tickets/$id';
  static String supportTicketReply(int id) => '$baseUrl/support/tickets/$id/messages';
  static const String feedback = '$baseUrl/feedback';
}
