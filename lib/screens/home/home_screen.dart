import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/library_provider.dart';
import '../../providers/blog_provider.dart';
import '../library/book_details_screen.dart';
import '../blog/blog_list_screen.dart';
import '../blog/blog_details_screen.dart';
import '../auth/login_screen.dart';

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
      lib.fetchBooks();
      lib.fetchBookshelf();
      blog.fetchBlogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final lib = Provider.of<LibraryProvider>(context);
    final blog = Provider.of<BlogProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: SikhunTheme.primary.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_stories, color: SikhunTheme.primary, size: 22),
            ),
            const SizedBox(width: 8),
            const Text(
              'শিখুন',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        actions: [
          if (auth.isAuthenticated)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: SikhunTheme.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SikhunTheme.primary.withAlpha(60)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined,
                      size: 16, color: SikhunTheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    '৳${auth.user!.walletBalance.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: SikhunTheme.primary,
                    ),
                  ),
                ],
              ),
            )
          else
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text('লগইন', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (auth.isAuthenticated) await auth.fetchProfile();
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
              // User Greeting Banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        SikhunTheme.primary,
                        SikhunTheme.primary.withAlpha(200),
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
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auth.isAuthenticated
                                  ? 'স্বাগতম, ${auth.user!.name}!'
                                  : 'মনোযোগ দিয়ে শেখার সহজ ঠিকানা',
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
                ),
              ),
              const SizedBox(height: 24),

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
                        // Library tab is handled in main navigation
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

              const SizedBox(height: 20),

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
}
