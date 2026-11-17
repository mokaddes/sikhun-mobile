import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/offline_service.dart';
import '../library/book_details_screen.dart';
import '../notifications/notification_screen.dart';

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
      Provider.of<DashboardProvider>(context, listen: false).fetchDashboard();
    });
  }

  Future<void> _openWeb(String path) async {
    final uri = Uri.parse('https://sikhun.com$path');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final dashProv = Provider.of<DashboardProvider>(context);
    final localeProv = Provider.of<LocaleProvider>(context);
    final themeProv = Provider.of<ThemeProvider>(context);
    final notifProv = Provider.of<NotificationProvider>(context);

    final user = auth.user;
    final data = dashProv.dashboardData;
    final isDark = themeProv.isDarkMode;

    // Current Date Formatter
    final now = DateTime.now();
    final List<String> weekdaysEn = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final List<String> weekdaysBn = ['সোমবার', 'মঙ্গলবার', 'বুধবার', 'বৃহস্পতিবার', 'শুক্রবার', 'শনিবার', 'রবিবার'];
    final List<String> monthsEn = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final List<String> monthsBn = ['জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন', 'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'];

    final weekday = localeProv.isBengali ? weekdaysBn[now.weekday - 1] : weekdaysEn[now.weekday - 1];
    final month = localeProv.isBengali ? monthsBn[now.month - 1] : monthsEn[now.month - 1];
    final dateString = '📅 $weekday ${now.day} $month';

    final studentName = user?.name.split(' ').first ?? (localeProv.isBengali ? 'শিক্ষার্থী' : 'Student');
    final walletBal = user?.walletBalance ?? data?.walletBalance ?? 0.0;
    final continueReading = data?.continueReading;

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildStudentDrawer(context, auth, localeProv, themeProv),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, size: 24),
          tooltip: 'Menu',
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        titleSpacing: 0,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isDark ? SikhunTheme.darkSurface2 : SikhunTheme.lightSurface2,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? SikhunTheme.darkBorder : SikhunTheme.lightBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                localeProv.isBengali ? 'ওয়ালেট: ' : 'Wallet Balance: ',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? SikhunTheme.darkTextMuted : SikhunTheme.mutedDark,
                ),
              ),
              Text(
                '৳${walletBal.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? SikhunTheme.darkPrimary : SikhunTheme.primary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          // 1. Language Toggle Button (বাং / EN)
          InkWell(
            onTap: () => localeProv.toggleLocale(),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: isDark ? SikhunTheme.darkSurface2 : SikhunTheme.lightSurface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? SikhunTheme.darkBorder : SikhunTheme.lightBorder,
                ),
              ),
              child: Text(
                localeProv.isBengali ? 'বাং' : 'EN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? SikhunTheme.darkPrimary : SikhunTheme.primary,
                ),
              ),
            ),
          ),

          // 2. Theme Toggle Button (☀️ / 🌙)
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 20,
            ),
            tooltip: isDark ? 'Light Mode' : 'Dark Mode',
            onPressed: () => themeProv.toggleTheme(),
          ),

          // 3. Notification Bell with Unread Badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 22),
                tooltip: 'Notifications',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotificationScreen()),
                  );
                },
              ),
              if (notifProv.unreadCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: const BoxDecoration(
                      color: Color(0xFF8A5A32),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${notifProv.unreadCount > 99 ? '99+' : notifProv.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),

          // 4. Student Avatar Circle with Initial
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 4),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF8A5A32),
              child: Text(
                user != null && user.name.isNotEmpty ? user.name[0].toUpperCase() : 'র',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (auth.isAuthenticated) await auth.fetchProfile();
          await dashProv.fetchDashboard();
          await notifProv.fetchNotifications(silent: true);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================================
              // STUDENT OVERVIEW CARD (MATCHING IMAGE 3)
              // ==========================================
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            SikhunTheme.darkSurface,
                            SikhunTheme.darkSurface2,
                          ]
                        : [
                            const Color(0xFFF9F6F0),
                            const Color(0xFFF2ECE1),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? SikhunTheme.darkBorder : const Color(0xFFE5DED2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 30 : 10),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Eyebrow
                    Text(
                      localeProv.t('dashboard.overview'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: isDark ? SikhunTheme.darkTextMuted : SikhunTheme.mutedDark,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Title
                    Text(
                      '${localeProv.t('dashboard.welcome')}, $studentName 👋',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Playfair Display',
                        color: isDark ? SikhunTheme.darkText : SikhunTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Subtitle
                    Text(
                      localeProv.t('dashboard.subtitle'),
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? SikhunTheme.darkTextMuted : SikhunTheme.mutedDark,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Date Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDark ? SikhunTheme.darkSurface2 : Colors.white.withAlpha(200),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? SikhunTheme.darkBorder : SikhunTheme.lightBorder,
                        ),
                      ),
                      child: Text(
                        dateString,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? SikhunTheme.darkTextMuted : SikhunTheme.mutedDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 4 Stat Cards in 2x2 Grid (IMAGE 3)
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.6,
                      children: [
                        _buildStatTile(
                          context,
                          label: localeProv.t('dashboard.wallet_balance'),
                          value: '৳${walletBal.toStringAsFixed(0)}',
                          icon: Icons.account_balance_wallet_outlined,
                          isDark: isDark,
                        ),
                        _buildStatTile(
                          context,
                          label: localeProv.t('dashboard.books_owned'),
                          value: '${data?.booksOwned ?? 0}',
                          icon: Icons.menu_book_outlined,
                          isDark: isDark,
                        ),
                        _buildStatTile(
                          context,
                          label: localeProv.t('dashboard.exams_taken'),
                          value: '${data?.examsTaken ?? 0}',
                          icon: Icons.fact_check_outlined,
                          isDark: isDark,
                        ),
                        _buildStatTile(
                          context,
                          label: localeProv.t('dashboard.courses_enrolled'),
                          value: '${data?.coursesEnrolled ?? 0}',
                          icon: Icons.school_outlined,
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // CURRENT PLAN SECTION (MATCHING IMAGE 3)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? SikhunTheme.darkSurface2 : Colors.white.withAlpha(220),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? SikhunTheme.darkBorder : SikhunTheme.lightBorder,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localeProv.t('dashboard.current_plan'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: isDark ? SikhunTheme.darkTextMuted : SikhunTheme.mutedDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF16A34A),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                data?.activeSubscriptionPlan ?? 'স্টার্টার লার্নার',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? SikhunTheme.darkText : SikhunTheme.textDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${localeProv.t('dashboard.active_until')} 11/30/2026',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? SikhunTheme.darkTextMuted : SikhunTheme.mutedDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _openWeb('/plans'),
                            child: Text(
                              localeProv.t('dashboard.manage_plan'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? SikhunTheme.darkPrimary : SikhunTheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ==========================================
              // PENDING ORDER BANNER (MATCHING IMAGE 3)
              // ==========================================
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF261E14) : const Color(0xFFFFF9ED),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFD97706).withAlpha(80),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD97706).withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('⏳', style: TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    localeProv.t('dashboard.payment_pending'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isDark ? SikhunTheme.darkText : SikhunTheme.textDark,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD97706).withAlpha(40),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      '#SKH-261114-KG7UHQ',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFB45309),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      localeProv.t('dashboard.payment_pending_desc'),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? SikhunTheme.darkTextMuted : SikhunTheme.mutedDark,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => _openWeb('/wallet'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8A5A32),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            minimumSize: const Size(0, 36),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: Text(
                            localeProv.t('dashboard.verify_trx'),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => _openWeb('/support/tickets'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? SikhunTheme.darkText : SikhunTheme.textDark,
                            side: BorderSide(color: isDark ? SikhunTheme.darkBorder : SikhunTheme.lightBorder),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: const Size(0, 36),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            localeProv.t('dashboard.contact_support'),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => _openWeb('/wallet'),
                          child: Text(
                            localeProv.t('dashboard.wallet_link'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? SikhunTheme.darkPrimary : SikhunTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ==========================================
              // CONTINUE READING SECTION
              // ==========================================
              if (continueReading != null) ...[
                Text(
                  localeProv.t('dashboard.continue_reading'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BookDetailsScreen(bookId: continueReading.bookId),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 60,
                              height: 80,
                              color: isDark ? SikhunTheme.darkSurface2 : SikhunTheme.lightSurface2,
                              child: continueReading.coverImage != null
                                  ? CachedNetworkImage(
                                      imageUrl: continueReading.coverImage!,
                                      fit: BoxFit.cover,
                                      errorWidget: (c, u, e) => const Icon(Icons.book),
                                    )
                                  : const Icon(Icons.book),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  continueReading.bookTitle,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  continueReading.chapterTitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? SikhunTheme.darkTextMuted : SikhunTheme.mutedDark,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: LinearProgressIndicator(
                                        value: (continueReading.progressPercent / 100.0).clamp(0.05, 1.0),
                                        backgroundColor: isDark ? SikhunTheme.darkBorder : SikhunTheme.lightBorder,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          isDark ? SikhunTheme.darkPrimary : SikhunTheme.primary,
                                        ),
                                        minHeight: 5,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${continueReading.progressPercent.toInt()}%',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: isDark ? SikhunTheme.darkTextMuted : SikhunTheme.mutedDark,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ==========================================
              // STUDY DESK TOOLS
              // ==========================================
              Text(
                localeProv.t('dashboard.smart_desk'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildDeskToolPill(
                    label: localeProv.t('nav.mistakes'),
                    icon: Icons.history_edu_outlined,
                    isDark: isDark,
                    onTap: () => _openWeb('/mistakes'),
                  ),
                  const SizedBox(width: 8),
                  _buildDeskToolPill(
                    label: localeProv.t('nav.flashcards'),
                    icon: Icons.style_outlined,
                    isDark: isDark,
                    onTap: () => _openWeb('/flashcards'),
                  ),
                  const SizedBox(width: 8),
                  _buildDeskToolPill(
                    label: localeProv.t('nav.schedules'),
                    icon: Icons.calendar_month_outlined,
                    isDark: isDark,
                    onTap: () => _openWeb('/schedules'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatTile(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? SikhunTheme.darkSurface2 : Colors.white.withAlpha(220),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? SikhunTheme.darkBorder : SikhunTheme.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? SikhunTheme.darkTextMuted : SikhunTheme.mutedDark,
                  ),
                ),
              ),
              Icon(icon, size: 16, color: const Color(0xFF8A5A32)),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? SikhunTheme.darkText : SikhunTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeskToolPill({
    required String label,
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isDark ? SikhunTheme.darkSurface : SikhunTheme.lightSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? SikhunTheme.darkBorder : SikhunTheme.lightBorder),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF8A5A32)),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentDrawer(
    BuildContext context,
    AuthProvider auth,
    LocaleProvider localeProv,
    ThemeProvider themeProv,
  ) {
    final user = auth.user;
    final isDark = themeProv.isDarkMode;

    return Drawer(
      backgroundColor: isDark ? SikhunTheme.darkSurface : SikhunTheme.lightBg,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF8A5A32),
                    child: Text(
                      user != null && user.name.isNotEmpty ? user.name[0].toUpperCase() : 'র',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Mokaddes Hosain',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user?.email ?? 'support@sikhun.com',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? SikhunTheme.darkTextMuted : SikhunTheme.mutedDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: Text(localeProv.t('nav.dashboard')),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: Text(localeProv.t('nav.library')),
              onTap: () {
                Navigator.of(context).pop();
                _openWeb('/library');
              },
            ),
            ListTile(
              leading: const Icon(Icons.quiz_outlined),
              title: Text(localeProv.t('nav.question_bank')),
              onTap: () {
                Navigator.of(context).pop();
                _openWeb('/question-bank');
              },
            ),
            ListTile(
              leading: const Icon(Icons.history_edu_outlined),
              title: Text(localeProv.t('nav.mistakes')),
              onTap: () {
                Navigator.of(context).pop();
                _openWeb('/mistakes');
              },
            ),
            ListTile(
              leading: const Icon(Icons.fact_check_outlined),
              title: Text(localeProv.t('nav.exams')),
              onTap: () {
                Navigator.of(context).pop();
                _openWeb('/exams');
              },
            ),
            ListTile(
              leading: const Icon(Icons.school_outlined),
              title: Text(localeProv.t('nav.courses')),
              onTap: () {
                Navigator.of(context).pop();
                _openWeb('/courses');
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: Text(localeProv.t('nav.wallet')),
              onTap: () {
                Navigator.of(context).pop();
                _openWeb('/wallet');
              },
            ),
            ListTile(
              leading: const Icon(Icons.card_membership_outlined),
              title: Text(localeProv.t('nav.plans')),
              onTap: () {
                Navigator.of(context).pop();
                _openWeb('/plans');
              },
            ),
            ListTile(
              leading: const Icon(Icons.leaderboard_outlined),
              title: Text(localeProv.t('nav.leaderboard')),
              onTap: () {
                Navigator.of(context).pop();
                _openWeb('/leaderboard');
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.cloud_off_outlined),
              title: Text(localeProv.t('offline.mode')),
              subtitle: Text(localeProv.t('offline.read_offline')),
              trailing: Switch(
                value: Provider.of<OfflineService>(context).isOfflineMode,
                onChanged: (val) {
                  Provider.of<OfflineService>(context, listen: false).setOfflineMode(val);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
