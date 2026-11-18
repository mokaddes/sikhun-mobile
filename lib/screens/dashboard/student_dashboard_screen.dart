import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/dashboard_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/sikhun_brand_logo.dart';
import '../ai_chat/ai_chat_screen.dart';
import '../blog/blog_list_screen.dart';
import '../bookshelf/bookshelf_screen.dart';
import '../community/community_screen.dart';
import '../courses/courses_screen.dart';
import '../exams/exams_screen.dart';
import '../flashcards/flashcards_screen.dart';
import '../library/library_screen.dart';
import '../mistakes/mistake_review_screen.dart';
import '../notifications/notification_screen.dart';
import '../plans/plans_screen.dart';
import '../portals/portals_screen.dart';
import '../profile/profile_screen.dart';
import '../question_bank/question_bank_screen.dart';
import '../reader/book_reader_screen.dart';
import '../tools/ai_tools_screen.dart';
import '../wallet/wallet_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAll();
    });
  }

  Future<void> _refreshAll() async {
    await context.read<AuthProvider>().fetchProfile();
    if (!mounted) return;
    await context.read<DashboardProvider>().fetchDashboard();
    if (!mounted) return;
    await context.read<NotificationProvider>().fetchNotifications(silent: true);
  }

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final dash = context.watch<DashboardProvider>();
    final notif = context.watch<NotificationProvider>();
    final locale = context.watch<LocaleProvider>();
    final themeProv = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = auth.user;
    final data = dash.dashboardData;
    final isEn = !locale.isBengali;

    final primary = isDark ? SikhunTheme.darkPrimary : SikhunTheme.primary;
    final bgColor = isDark ? SikhunTheme.darkBg : SikhunTheme.lightBg;
    final surface = isDark ? SikhunTheme.darkSurface : SikhunTheme.lightSurface;
    final surface2 = isDark ? SikhunTheme.darkSurface2 : SikhunTheme.lightSurface2;
    final textColor = isDark ? SikhunTheme.darkText : SikhunTheme.textDark;
    final muted = isDark ? SikhunTheme.darkTextMuted : SikhunTheme.mutedDark;
    final border = isDark ? SikhunTheme.darkBorder : SikhunTheme.lightBorder;

    final firstName = (user?.name ?? 'Student').trim().split(' ').first;
    final avatarChar = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'S';

    // Web condition: SSC / HSC / University students cannot see Question Bank
    final canSeeQuestionBank = data?.canAccessQuestionBank ?? (user?.canAccessQuestionBank ?? false);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bgColor,
      drawer: _buildNavigationDrawer(
        isDark: isDark,
        surface: surface,
        primary: primary,
        textColor: textColor,
        muted: muted,
        border: border,
        locale: locale,
        auth: auth,
        canSeeQuestionBank: canSeeQuestionBank,
      ),
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: textColor),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        titleSpacing: 0,
        title: SikhunBrandLogo(
          compact: true,
          markSize: 30,
          showTagline: false,
          isBangla: !isEn,
        ),
        actions: [
          // Wallet Balance Pill
          InkWell(
            onTap: () => _push(const WalletScreen()),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: surface2,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: border),
              ),
              child: Center(
                child: Text(
                  '৳${(data?.walletBalance ?? user?.walletBalance ?? 0).toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primary),
                ),
              ),
            ),
          ),

          // Language Toggle Pill (BN/EN)
          InkWell(
            onTap: () => locale.toggleLocale(),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  isEn ? 'বাং' : 'EN',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                ),
              ),
            ),
          ),

          // Theme Toggle Icon
          IconButton(
            icon: Icon(
              themeProv.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 20,
              color: textColor,
            ),
            onPressed: () => themeProv.toggleTheme(),
          ),

          // Notifications Bell
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.notifications_none, size: 22, color: textColor),
                onPressed: () => _push(const NotificationScreen()),
              ),
              if (notif.unreadCount > 0)
                Positioned(
                  top: 10,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: SikhunTheme.danger,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${notif.unreadCount > 99 ? '99+' : notif.unreadCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),

          // User Avatar Badge
          Padding(
            padding: const EdgeInsets.only(right: 10, left: 2),
            child: InkWell(
              onTap: () => _push(const ProfileScreen()),
              child: CircleAvatar(
                radius: 15,
                backgroundColor: primary,
                child: Text(
                  avatarChar,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF111827) : Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. STUDENT OVERVIEW Header + Quick Plan Pill
              Text(
                locale.t('dashboard.overview'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: primary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEn
                              ? '${locale.t('dashboard.welcome')}, $firstName'
                              : '${locale.t('dashboard.welcome')}, ${user?.name ?? 'শিক্ষার্থী'}',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textColor),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: primary.withAlpha(24),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isEn ? (user?.typeLabelEn ?? 'Student') : (user?.typeLabelBn ?? 'শিক্ষার্থী'),
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primary),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                locale.t('dashboard.subtitle'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12.5, color: muted),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Real Pending Order Payment Alert Banner (No Hardcoded Order IDs!)
              if (data != null && data.pendingOrder != null) ...[
                _buildPendingPaymentAlert(data.pendingOrder!, primary, surface, textColor, muted, locale),
                const SizedBox(height: 16),
              ],

              // 3. Stats 2x2 Grid
              Row(
                children: [
                  _buildStatCard(
                    title: locale.t('dashboard.wallet_balance'),
                    value: '৳${(data?.walletBalance ?? user?.walletBalance ?? 0).toStringAsFixed(0)}',
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: primary,
                    surface: surface,
                    border: border,
                    textColor: textColor,
                    muted: muted,
                    onTap: () => _push(const WalletScreen()),
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    title: locale.t('dashboard.books_owned'),
                    value: '${data?.booksOwned ?? 0}',
                    icon: Icons.menu_book_outlined,
                    iconColor: Colors.blueAccent,
                    surface: surface,
                    border: border,
                    textColor: textColor,
                    muted: muted,
                    onTap: () => _push(const BookshelfScreen()),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatCard(
                    title: locale.t('dashboard.exams_taken'),
                    value: '${data?.examsTaken ?? 0}',
                    icon: Icons.assignment_turned_in_outlined,
                    iconColor: SikhunTheme.success,
                    surface: surface,
                    border: border,
                    textColor: textColor,
                    muted: muted,
                    onTap: () => _push(const ExamsScreen()),
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    title: locale.t('dashboard.courses_enrolled'),
                    value: '${data?.coursesEnrolled ?? 0}',
                    icon: Icons.play_circle_outline,
                    iconColor: Colors.purpleAccent,
                    surface: surface,
                    border: border,
                    textColor: textColor,
                    muted: muted,
                    onTap: () => _push(const CoursesScreen()),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4. Current Subscription Plan Card (Real Plan & Expiry)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            locale.t('dashboard.current_plan'),
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: muted),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data?.activeSubscriptionPlan ?? (isEn ? 'Free Trial' : 'ফ্রি ট্রায়াল'),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor),
                          ),
                          if (data != null && data.activeSubscriptionExpiresAt != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              '${locale.t('dashboard.active_until')} ${data.activeSubscriptionExpiresAt}',
                              style: TextStyle(fontSize: 12, color: muted),
                            ),
                          ],
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _push(const PlansScreen()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: surface2,
                        foregroundColor: primary,
                        elevation: 0,
                        side: BorderSide(color: border),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      child: Text(
                        locale.t('dashboard.manage_plan'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 5. Continue Reading Card
              if (data != null && data.continueReading != null) ...[
                Text(
                  locale.t('dashboard.continue_reading'),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () {
                    final cr = data.continueReading!;
                    _push(BookReaderScreen(
                      bookId: cr.bookId,
                      title: cr.bookTitle,
                      initialPage: cr.currentPage,
                    ));
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                data.continueReading!.bookTitle,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor),
                              ),
                            ),
                            Text(
                              '${data.continueReading!.progress}%',
                              style: TextStyle(fontWeight: FontWeight.bold, color: primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data.continueReading!.chapterTitle,
                          style: TextStyle(fontSize: 12, color: muted),
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: (data.continueReading!.progressPercent / 100).clamp(0.0, 1.0).toDouble(),
                          backgroundColor: surface2,
                          valueColor: AlwaysStoppedAnimation<Color>(primary),
                          minHeight: 7,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 6. Smart Study Desk Grid (100% Native Screens, Goal-aware)
              Text(
                locale.t('dashboard.smart_desk'),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 10),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.96,
                children: [
                  _buildDeskAction(
                    icon: Icons.smart_toy_outlined,
                    label: locale.t('nav.ai_chat'),
                    color: Colors.amber.shade700,
                    surface: surface,
                    border: border,
                    textColor: textColor,
                    onTap: () => _push(const AiChatScreen()),
                  ),
                  _buildDeskAction(
                    icon: Icons.quiz_outlined,
                    label: locale.t('nav.exams'),
                    color: Colors.deepOrange,
                    surface: surface,
                    border: border,
                    textColor: textColor,
                    onTap: () => _push(const ExamsScreen()),
                  ),
                  if (canSeeQuestionBank)
                    _buildDeskAction(
                      icon: Icons.assignment_turned_in_outlined,
                      label: locale.t('nav.question_bank'),
                      color: SikhunTheme.success,
                      surface: surface,
                      border: border,
                      textColor: textColor,
                      onTap: () => _push(const QuestionBankScreen()),
                    ),
                  _buildDeskAction(
                    icon: Icons.bookmark_remove_outlined,
                    label: locale.t('nav.mistakes'),
                    color: SikhunTheme.danger,
                    surface: surface,
                    border: border,
                    textColor: textColor,
                    onTap: () => _push(const MistakeReviewScreen()),
                  ),
                  _buildDeskAction(
                    icon: Icons.style_outlined,
                    label: locale.t('nav.flashcards'),
                    color: Colors.teal,
                    surface: surface,
                    border: border,
                    textColor: textColor,
                    onTap: () => _push(const FlashcardsScreen()),
                  ),
                  _buildDeskAction(
                    icon: Icons.menu_book_outlined,
                    label: locale.t('nav.bookshelf'),
                    color: Colors.blueAccent,
                    surface: surface,
                    border: border,
                    textColor: textColor,
                    onTap: () => _push(const BookshelfScreen()),
                  ),
                  _buildDeskAction(
                    icon: Icons.play_circle_outline,
                    label: locale.t('nav.courses'),
                    color: Colors.indigo,
                    surface: surface,
                    border: border,
                    textColor: textColor,
                    onTap: () => _push(const CoursesScreen()),
                  ),
                  _buildDeskAction(
                    icon: Icons.rate_review_outlined,
                    label: locale.t('nav.essays'),
                    color: Colors.purple,
                    surface: surface,
                    border: border,
                    textColor: textColor,
                    onTap: () => _push(const AiToolsScreen(initialTab: 0)),
                  ),
                  _buildDeskAction(
                    icon: Icons.calendar_month_outlined,
                    label: locale.t('nav.schedules'),
                    color: Colors.cyan.shade700,
                    surface: surface,
                    border: border,
                    textColor: textColor,
                    onTap: () => _push(const AiToolsScreen(initialTab: 1)),
                  ),
                  _buildDeskAction(
                    icon: Icons.work_outline,
                    label: locale.t('nav.notices'),
                    color: Colors.brown,
                    surface: surface,
                    border: border,
                    textColor: textColor,
                    onTap: () => _push(const PortalsScreen()),
                  ),
                  _buildDeskAction(
                    icon: Icons.leaderboard_outlined,
                    label: locale.t('nav.leaderboard'),
                    color: Colors.orange.shade700,
                    surface: surface,
                    border: border,
                    textColor: textColor,
                    onTap: () => _push(const CommunityScreen(initialTab: 0)),
                  ),
                  _buildDeskAction(
                    icon: Icons.workspace_premium_outlined,
                    label: locale.t('nav.plans'),
                    color: primary,
                    surface: surface,
                    border: border,
                    textColor: textColor,
                    onTap: () => _push(const PlansScreen()),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 7. Recent Exam Results & Leaderboard Preview
              if (data != null && data.recentExams.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      locale.t('dashboard.recent_exams'),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    TextButton(
                      onPressed: () => _push(const ExamsScreen()),
                      child: Text(locale.t('common.view_all'), style: TextStyle(color: primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...data.recentExams.take(3).map((ex) {
                  final map = ex is Map<String, dynamic> ? ex : <String, dynamic>{};
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(Icons.assignment_turned_in, color: primary),
                      title: Text(map['title']?.toString() ?? 'মডেল টেস্ট',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                      subtitle: Text('স্কোর: ${map['score'] ?? 0} / ${map['total_marks'] ?? 0}'),
                      onTap: () => _push(const ExamsScreen()),
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingPaymentAlert(
    PendingOrderModel order,
    Color primary,
    Color surface,
    Color textColor,
    Color muted,
    LocaleProvider locale,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SikhunTheme.warning.withAlpha(24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SikhunTheme.warning.withAlpha(110)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.hourglass_top_rounded, color: SikhunTheme.warning, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${locale.t('dashboard.payment_pending')} (${order.orderNumber} • ৳${order.amount.toStringAsFixed(0)})',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: textColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(locale.t('dashboard.payment_pending_desc'),
              style: TextStyle(fontSize: 12, color: muted)),
          const SizedBox(height: 10),
          Row(
            children: [
              ElevatedButton(
                onPressed: () => _push(WalletScreen(verifyOrderId: order.id)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SikhunTheme.warning,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: Text(locale.t('dashboard.verify_trx'), style: const TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => _push(const CommunityScreen(initialTab: 2)),
                child: Text(locale.t('dashboard.contact_support'), style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color surface,
    required Color border,
    required Color textColor,
    required Color muted,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(24),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      title,
                      style: TextStyle(fontSize: 11, color: muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeskAction({
    required IconData icon,
    required String label,
    required Color color,
    required Color surface,
    required Color border,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(22),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: textColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationDrawer({
    required bool isDark,
    required Color surface,
    required Color primary,
    required Color textColor,
    required Color muted,
    required Color border,
    required LocaleProvider locale,
    required AuthProvider auth,
    required bool canSeeQuestionBank,
  }) {
    return Drawer(
      backgroundColor: surface,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  SikhunBrandLogo(
                    compact: true,
                    markSize: 34,
                    showTagline: true,
                    isBangla: locale.isBengali,
                  ),
                ],
              ),
            ),
            Divider(color: border),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  _drawerItem(Icons.menu_book_outlined, locale.t('nav.library'),
                      () => _push(const LibraryScreen())),
                  _drawerItem(Icons.bookmarks_outlined, locale.t('nav.bookshelf'),
                      () => _push(const BookshelfScreen())),
                  _drawerItem(Icons.play_circle_outline, locale.t('nav.courses'),
                      () => _push(const CoursesScreen())),
                  const Divider(),
                  if (canSeeQuestionBank)
                    _drawerItem(Icons.assignment_turned_in_outlined, locale.t('nav.question_bank'),
                        () => _push(const QuestionBankScreen())),
                  _drawerItem(Icons.bookmark_remove_outlined, locale.t('nav.mistakes'),
                      () => _push(const MistakeReviewScreen())),
                  _drawerItem(Icons.quiz_outlined, locale.t('nav.exams'),
                      () => _push(const ExamsScreen())),
                  _drawerItem(Icons.style_outlined, locale.t('nav.flashcards'),
                      () => _push(const FlashcardsScreen())),
                  _drawerItem(Icons.rate_review_outlined, locale.t('nav.essays'),
                      () => _push(const AiToolsScreen(initialTab: 0))),
                  _drawerItem(Icons.calendar_month_outlined, locale.t('nav.schedules'),
                      () => _push(const AiToolsScreen(initialTab: 1))),
                  const Divider(),
                  _drawerItem(Icons.smart_toy_outlined, locale.t('nav.ai_chat'),
                      () => _push(const AiChatScreen())),
                  _drawerItem(Icons.school_outlined, locale.t('nav.admissions'),
                      () => _push(const PortalsScreen(initialTab: 0))),
                  _drawerItem(Icons.work_outline, locale.t('nav.jobs'),
                      () => _push(const PortalsScreen(initialTab: 1))),
                  _drawerItem(Icons.article_outlined, locale.t('nav.blog'),
                      () => _push(const BlogListScreen())),
                  const Divider(),
                  _drawerItem(Icons.workspace_premium_outlined, locale.t('nav.plans'),
                      () => _push(const PlansScreen())),
                  _drawerItem(Icons.account_balance_wallet_outlined, locale.t('nav.wallet'),
                      () => _push(const WalletScreen())),
                  _drawerItem(Icons.leaderboard_outlined, locale.t('nav.leaderboard'),
                      () => _push(const CommunityScreen(initialTab: 0))),
                  _drawerItem(Icons.card_giftcard_outlined, locale.t('nav.referrals'),
                      () => _push(const CommunityScreen(initialTab: 1))),
                  _drawerItem(Icons.support_agent_outlined, locale.t('nav.support'),
                      () => _push(const CommunityScreen(initialTab: 2))),
                  _drawerItem(Icons.settings_outlined, locale.t('nav.profile_settings'),
                      () => _push(const ProfileScreen())),
                ],
              ),
            ),
            Divider(color: border),
            ListTile(
              leading: const Icon(Icons.logout, color: SikhunTheme.danger),
              title: Text(locale.t('common.logout'),
                  style: const TextStyle(color: SikhunTheme.danger, fontWeight: FontWeight.bold)),
              onTap: () async {
                Navigator.pop(context);
                await auth.logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20, color: SikhunTheme.primary),
      title: Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}
