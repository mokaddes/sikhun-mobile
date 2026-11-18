import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/app_setting_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/blog_provider.dart';
import '../../providers/library_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/sikhun_brand_logo.dart';
import '../ai_chat/ai_chat_screen.dart';
import '../auth/login_screen.dart';
import '../blog/blog_details_screen.dart';
import '../blog/blog_list_screen.dart';
import '../bookshelf/bookshelf_screen.dart';
import '../courses/courses_screen.dart';
import '../dashboard/student_dashboard_screen.dart';
import '../exams/exams_screen.dart';
import '../library/book_details_screen.dart';
import '../library/library_screen.dart';
import '../notifications/notification_screen.dart';
import '../plans/plans_screen.dart';
import '../portals/portals_screen.dart';
import '../question_bank/question_bank_screen.dart';

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
      final auth = Provider.of<AuthProvider>(context, listen: false);
      Provider.of<AppSettingProvider>(context, listen: false).fetchSettings();
      Provider.of<LibraryProvider>(context, listen: false).fetchBooks();
      if (auth.isAuthenticated) {
        Provider.of<LibraryProvider>(context, listen: false).fetchBookshelf();
        Provider.of<NotificationProvider>(context, listen: false).fetchNotifications(silent: true);
      }
      Provider.of<BlogProvider>(context, listen: false).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final appSetting = Provider.of<AppSettingProvider>(context);
    final lib = Provider.of<LibraryProvider>(context);
    final blog = Provider.of<BlogProvider>(context);
    final notif = Provider.of<NotificationProvider>(context);
    final themeProv = Provider.of<ThemeProvider>(context);

    final setting = appSetting.setting;
    final canSeeQuestionBank = !auth.isAuthenticated || (auth.user?.canAccessQuestionBank ?? true);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: SikhunBrandLogo(
          compact: true,
          markSize: 32,
          customTitle: setting.title,
          customTagline: setting.subtitle,
        ),
        actions: [
          IconButton(
            icon: Icon(
              themeProv.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 20,
            ),
            onPressed: () => themeProv.toggleTheme(),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, size: 22),
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
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          if (auth.isAuthenticated)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const StudentDashboardScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: SikhunTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: const Size(0, 34),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.dashboard_outlined, size: 16),
                label: const Text('ড্যাশবোর্ড', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            )
          else
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
              // Hero Banner
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
                                      ? 'ক্যাটাগরি: ${auth.user!.typeLabelBn} • আপনার পড়াশোনা এগিয়ে নিন'
                                      : 'বইয়ের পাতায় এআই টিউটর, অধ্যায়ভিত্তিক স্টাডি ও স্মার্ট প্রশ্নব্যাংক',
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const SikhunMark(size: 46),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const CoursesScreen()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: SikhunTheme.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: const Size(0, 32),
                              ),
                              icon: const Icon(Icons.play_circle_outline, size: 15),
                              label: const Text('কোর্সসমূহ', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const PlansScreen()),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white54),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: const Size(0, 32),
                              ),
                              icon: const Icon(Icons.workspace_premium_outlined, size: 15),
                              label: const Text('সাবস্ক্রিপশন প্ল্যান', style: TextStyle(fontSize: 11.5)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Official Portals Strip (Admission 2026 Live + Job News)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PortalsScreen(initialTab: 0)),
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: SikhunTheme.primary.withAlpha(18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: SikhunTheme.primary.withAlpha(50)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.school, color: SikhunTheme.primary, size: 22),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('ভর্তি বিজ্ঞপ্তি',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    Text('Admission Live',
                                        style: TextStyle(fontSize: 10.5, color: SikhunTheme.mutedDark)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PortalsScreen(initialTab: 1)),
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: SikhunTheme.success.withAlpha(18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: SikhunTheme.success.withAlpha(50)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.work, color: SikhunTheme.success, size: 22),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('চাকরি নিউজ',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    Text('BCS & Govt Circulars',
                                        style: TextStyle(fontSize: 10.5, color: SikhunTheme.mutedDark)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3 Study Paths
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('পড়াশোনার সহজ ছন্দ',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('যেখান থেকে শুরু করতে চান',
                        style: TextStyle(fontSize: 13, color: SikhunTheme.mutedDark)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildStudyPathCard(
                          number: '০১',
                          title: 'বুঝে পড়ুন',
                          desc: 'বই ও অধ্যায় ধরে এআই সাথে স্টাডি',
                          icon: Icons.menu_book,
                          color: const Color(0xFF2563EB),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const LibraryScreen()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStudyPathCard(
                          number: '০২',
                          title: canSeeQuestionBank ? 'প্রশ্নব্যাংক' : 'মডেল টেস্ট',
                          desc: canSeeQuestionBank ? 'প্রশ্নব্যাংক ও মডেল টেস্ট' : 'এআই অনুশীলন ও পরীক্ষা',
                          icon: Icons.quiz,
                          color: const Color(0xFF059669),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => canSeeQuestionBank
                                  ? const QuestionBankScreen()
                                  : const ExamsScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStudyPathCard(
                          number: '০৩',
                          title: 'টিউটর',
                          desc: 'তাৎক্ষণিক এআই ব্যাখ্যা',
                          icon: Icons.smart_toy,
                          color: const Color(0xFFD97706),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AiChatScreen()),
                          ),
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
                      const Text('আমার বুকশেলফ',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const BookshelfScreen()),
                        ),
                        child: Text('সব দেখুন (${lib.bookshelf.length})'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 205,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: lib.bookshelf.length,
                    itemBuilder: (context, index) {
                      final book = lib.bookshelf[index];
                      return Container(
                        width: 136,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BookDetailsScreen(bookId: book.id, bookSlug: book.slug),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  height: 136,
                                  color: Colors.grey.shade200,
                                  child: book.coverImage != null && book.coverImage!.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: book.coverImage!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          errorWidget: (c, u, e) => const Icon(Icons.book, size: 40),
                                        )
                                      : const Center(child: Icon(Icons.book, size: 40)),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(book.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(book.author ?? 'শিখুন',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: SikhunTheme.mutedDark, fontSize: 11)),
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
                    const Text('লাইব্রেরির জনপ্রিয় বই',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                const Center(
                  child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()),
                )
              else
                SizedBox(
                  height: 225,
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
                                builder: (_) => BookDetailsScreen(bookId: book.id, bookSlug: book.slug),
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
                                              errorWidget: (c, u, e) => const Icon(Icons.book, size: 40),
                                            )
                                          : const Center(child: Icon(Icons.book, size: 40)),
                                      Positioned(
                                        top: 6,
                                        right: 6,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: book.isFree ? SikhunTheme.success : SikhunTheme.primary,
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
                              Text(book.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(book.author ?? 'শিখুন',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: SikhunTheme.mutedDark, fontSize: 11)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 20),

              // Latest Blog Articles
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('সাম্প্রতিক ব্লগ ও আর্টিক্যাল',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                                  Text(item.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                                          child: Text(item.category!,
                                              style: const TextStyle(fontSize: 10, color: SikhunTheme.primary)),
                                        ),
                                      const Spacer(),
                                      Text('${item.readingTime} মিনিট পড়া',
                                          style: const TextStyle(fontSize: 11, color: SikhunTheme.mutedDark)),
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
                  Text(number,
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
                  Icon(icon, size: 18, color: color),
                ],
              ),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Text(desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: SikhunTheme.mutedDark)),
            ],
          ),
        ),
      ),
    );
  }
}
