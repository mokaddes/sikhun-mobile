import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/library_provider.dart';
import '../../providers/blog_provider.dart';
import '../../providers/app_setting_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/locale_provider.dart';
import '../library/book_details_screen.dart';
import '../library/library_screen.dart';
import '../blog/blog_list_screen.dart';
import '../blog/blog_details_screen.dart';
import '../auth/login_screen.dart';
import '../dashboard/student_dashboard_screen.dart';
import '../notifications/notification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lib = Provider.of<LibraryProvider>(context, listen: false);
      final blog = Provider.of<BlogProvider>(context, listen: false);
      final appSetting = Provider.of<AppSettingProvider>(context, listen: false);
      final notif = Provider.of<NotificationProvider>(context, listen: false);
      lib.fetchBooks();
      lib.fetchBookshelf();
      blog.fetchBlogs();
      appSetting.fetchSettings();
      notif.fetchNotifications(silent: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final lib = Provider.of<LibraryProvider>(context);
    final blog = Provider.of<BlogProvider>(context);
    final appSetting = Provider.of<AppSettingProvider>(context);
    final notif = Provider.of<NotificationProvider>(context);
    final themeProv = Provider.of<ThemeProvider>(context);
    final localeProv = Provider.of<LocaleProvider>(context);
    final isDark = themeProv.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: [
            if (appSetting.logoUrl != null && appSetting.logoUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: appSetting.logoUrl!,
                height: 32,
                fit: BoxFit.contain,
                placeholder: (c, u) => Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: SikhunTheme.primary.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_stories, color: SikhunTheme.primary, size: 18),
                ),
                errorWidget: (c, u, e) => Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: SikhunTheme.primary.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_stories, color: SikhunTheme.primary, size: 20),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: SikhunTheme.primary.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_stories, color: SikhunTheme.primary, size: 20),
              ),
            const SizedBox(width: 8),
            Text(
              appSetting.siteName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
            ),
          ],
        ),
        actions: [
          // Language Toggle
          InkWell(
            onTap: () => localeProv.toggleLocale(),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.symmetric(vertical: 12),
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
          // Theme Toggle
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 20,
            ),
            tooltip: isDark ? 'Light Mode' : 'Dark Mode',
            onPressed: () => themeProv.toggleTheme(),
          ),
          // Notification Bell with Unread Badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'নোটিফিকেশন',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotificationScreen()),
                  );
                },
              ),
              if (notif.unreadCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${notif.unreadCount > 99 ? '99+' : notif.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),

          if (auth.isAuthenticated) ...[
            // Web-style brown Dashboard Button
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const StudentDashboardScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF78350F), // warm brown from web
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: const Size(0, 34),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.dashboard_outlined, size: 16),
                label: const Text('ড্যাশবোর্ড', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text('লগইন', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (auth.isAuthenticated) await auth.fetchProfile();
          await appSetting.fetchSettings();
          await notif.fetchNotifications(silent: true);
          await lib.fetchBooks();
          await lib.fetchBookshelf();
          await blog.fetchBlogs();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Greeting Banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        SikhunTheme.primary,
                        SikhunTheme.primary.withAlpha(210),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: SikhunTheme.primary.withAlpha(60),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  auth.isAuthenticated
                                      ? 'স্বাগতম, ${auth.user!.name}!'
                                      : 'শেখার জন্য একটু মনোযোগী পরিসর',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  auth.isAuthenticated
                                      ? 'ক্যাটাগরি: ${auth.user!.studentType ?? "সাধারণ"} • আপনার পড়াশোনা এগিয়ে নিন'
                                      : 'বইয়ের পাতায় এআই টিউটর, অধ্যায়ভিত্তিক স্টাডি এবং স্মার্ট প্রশ্নব্যাংক',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(40),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.school,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                      if (auth.isAuthenticated) ...[
                        const SizedBox(height: 14),
                        const Divider(color: Colors.white24, height: 1),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.account_balance_wallet_outlined, size: 16, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  'ওয়ালেট ব্যালেন্স: ৳${auth.user!.walletBalance.toStringAsFixed(0)}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const StudentDashboardScreen()),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(50),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  children: [
                                    Text('ড্যাশবোর্ড প্রবেশ', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                    SizedBox(width: 4),
                                    Icon(Icons.arrow_forward, size: 14, color: Colors.white),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 3 Study Paths (From Web Front Page)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'পড়াশোনার সহজ ছন্দ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'যেখান থেকে শুরু করতে চান',
                      style: TextStyle(fontSize: 13, color: SikhunTheme.mutedDark),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildStudyPathCard(
                          number: '০১',
                          title: 'বুঝে পড়ুন',
                          desc: 'বই ও অধ্যায় ধরে এআই সাথে স্টাডি',
                          icon: Icons.menu_book,
                          color: const Color(0xFF2563EB),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const LibraryScreen()),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildStudyPathCard(
                          number: '০২',
                          title: 'অনুশীলন',
                          desc: 'প্রশ্নব্যাংক ও মডেল টেস্ট',
                          icon: Icons.quiz,
                          color: const Color(0xFF059669),
                          onTap: () {
                            // Handled by tab navigation
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildStudyPathCard(
                          number: '০৩',
                          title: 'টিউটর',
                          desc: 'তাৎক্ষণিক এআই ব্যাখ্যা',
                          icon: Icons.smart_toy,
                          color: const Color(0xFFD97706),
                          onTap: () {
                            // Handled by tab navigation
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Continue Reading / Bookshelf Section
              if (lib.bookshelf.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'আমার বুকশেলফ (পড়া চালিয়ে যান)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${lib.bookshelf.length} টি বই',
                        style: const TextStyle(color: SikhunTheme.mutedDark, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 210,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: lib.bookshelf.length,
                    itemBuilder: (context, index) {
                      final book = lib.bookshelf[index];
                      return Container(
                        width: 140,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BookDetailsScreen(bookId: book.id),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  height: 140,
                                  color: Colors.grey.shade200,
                                  child: book.coverImage != null && book.coverImage!.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: book.coverImage!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          placeholder: (c, u) => const Center(
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                          errorWidget: (c, u, e) => const Icon(Icons.book, size: 40),
                                        )
                                      : const Center(child: Icon(Icons.book, size: 40)),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                book.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                book.author ?? 'শিখুন',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: SikhunTheme.mutedDark, fontSize: 11),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: LinearProgressIndicator(
                                      value: (book.progress > 0) ? (book.progress / 100.0) : 0.05,
                                      backgroundColor: Colors.grey.shade300,
                                      valueColor: const AlwaysStoppedAnimation<Color>(SikhunTheme.primary),
                                      minHeight: 4,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${book.progress.toInt()}%',
                                    style: const TextStyle(fontSize: 10, color: SikhunTheme.mutedDark),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Featured Books
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'লাইব্রেরির জনপ্রিয় বই',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LibraryScreen()),
                        );
                      },
                      child: const Text('সব দেখুন'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              if (lib.isLoading && lib.books.isEmpty)
                const Center(child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ))
              else
                SizedBox(
                  height: 230,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: lib.books.take(6).length,
                    itemBuilder: (context, index) {
                      final book = lib.books[index];
                      return Container(
                        width: 140,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BookDetailsScreen(bookId: book.id),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  height: 140,
                                  color: Colors.grey.shade200,
                                  child: Stack(
                                    children: [
                                      book.coverImage != null && book.coverImage!.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: book.coverImage!,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              placeholder: (c, u) => const Center(
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              ),
                                              errorWidget: (c, u, e) => const Icon(Icons.book, size: 40),
                                            )
                                          : const Center(child: Icon(Icons.book, size: 40)),
                                      Positioned(
                                        top: 6,
                                        right: 6,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: book.isFree ? SikhunTheme.accent : SikhunTheme.primary,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            book.effectivePriceDisplay,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                book.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                book.author ?? 'শিখুন',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: SikhunTheme.mutedDark, fontSize: 11),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                book.gradeLevel != null ? 'লেভেল: ${book.gradeLevel}' : 'পূর্ণাঙ্গ বই',
                                style: const TextStyle(color: SikhunTheme.primary, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 24),

              // 3-Step Rhythm (From Web Front Page)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withAlpha(40)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'কীভাবে শিখুন আপনাকে এগিয়ে রাখে',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 14),
                      _buildRhythmStep(
                        step: '১',
                        title: 'বিষয়টি বুঝে নিন',
                        desc: 'বইয়ের যেকোনো প্যারাগ্রাফে ট্যাপ করে তাৎক্ষণিক বাংলা ব্যাখ্যা ও সামারি জানুন।',
                        icon: Icons.lightbulb_outline,
                      ),
                      const SizedBox(height: 12),
                      _buildRhythmStep(
                        step: '২',
                        title: 'নিজে অনুশীলন করুন',
                        desc: 'অধ্যায়ভিত্তিক প্রশ্নব্যাংক ও নির্ভুল ব্যাখ্যাসহ সেলফ-টেস্ট দিয়ে প্রস্তুতি যাচাই করুন।',
                        icon: Icons.edit_note,
                      ),
                      const SizedBox(height: 12),
                      _buildRhythmStep(
                        step: '৩',
                        title: 'উন্নতি দেখে এগোন',
                        desc: 'ভুল খাতা ও লিডারবোর্ডের মাধ্যমে নিজের দুর্বল অংশ চিহ্নিত করে এগিয়ে যান।',
                        icon: Icons.trending_up,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Platform Stats Row (From Web Front Page)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildStatPill('১৫,০০০+', 'শিক্ষার্থী', Icons.people_outline),
                    const SizedBox(width: 8),
                    _buildStatPill('৫০,০০০+', 'প্রশ্নব্যাংক', Icons.fact_check_outlined),
                    const SizedBox(width: 8),
                    _buildStatPill('৫০০+', 'অধ্যায় ও বই', Icons.menu_book_outlined),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Latest Blog Articles
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'সাম্প্রতিক ব্লগ ও আর্টিক্যাল',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const BlogListScreen()),
                        );
                      },
                      child: const Text('সব দেখুন'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: blog.blogs.take(3).length,
                itemBuilder: (context, index) {
                  final item = blog.blogs[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    clipBehavior: Clip.antiAlias,
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BlogDetailsScreen(slug: item.slug),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          if (item.coverImage != null && item.coverImage!.isNotEmpty)
                            SizedBox(
                              width: 100,
                              height: 90,
                              child: CachedNetworkImage(
                                imageUrl: item.coverImage!,
                                fit: BoxFit.cover,
                                errorWidget: (c, u, e) => const Icon(Icons.article),
                              ),
                            )
                          else
                            Container(
                              width: 100,
                              height: 90,
                              color: SikhunTheme.primary.withAlpha(20),
                              child: const Icon(Icons.article, color: SikhunTheme.primary),
                            ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      if (item.category != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: SikhunTheme.primary.withAlpha(20),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            item.category!,
                                            style: const TextStyle(fontSize: 10, color: SikhunTheme.primary),
                                          ),
                                        ),
                                      const Spacer(),
                                      Text(
                                        '${item.readingTime} মিনিট পড়া',
                                        style: const TextStyle(fontSize: 11, color: SikhunTheme.mutedDark),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudyPathCard({
    required String number,
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha(15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withAlpha(40)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    number,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Icon(icon, size: 18, color: color),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: SikhunTheme.mutedDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRhythmStep({
    required String step,
    required String title,
    required String desc,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: SikhunTheme.primary.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(color: SikhunTheme.primary, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 3),
              Text(
                desc,
                style: const TextStyle(color: SikhunTheme.mutedDark, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatPill(String count, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: SikhunTheme.primary.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: SikhunTheme.primary),
            const SizedBox(height: 4),
            Text(
              count,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: SikhunTheme.primary),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: SikhunTheme.mutedDark),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
