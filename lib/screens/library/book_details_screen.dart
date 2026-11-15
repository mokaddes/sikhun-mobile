import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../models/book_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/library_provider.dart';
import '../auth/login_screen.dart';

class BookDetailsScreen extends StatefulWidget {
  final int bookId;

  const BookDetailsScreen({super.key, required this.bookId});

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  final Set<int> _selectedChapterIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LibraryProvider>(context, listen: false).fetchBookDetails(widget.bookId);
    });
  }

  Future<void> _openReader({int? chapterId, int? page}) async {
    String url = 'https://sikhun.com/library/${widget.bookId}/read';
    if (page != null) {
      url += '?page=$page';
    } else if (chapterId != null) {
      url += '?chapter=$chapterId';
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('রিডার চালু করা যায়নি')),
        );
      }
    }
  }

  void _showBatchPurchaseSheet(BookModel book) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    final lockedChapters = book.chapters.where((c) => !c.canRead).toList();
    if (lockedChapters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('সকল অধ্যায় উন্মুক্ত রয়েছে!')),
      );
      return;
    }

    _selectedChapterIds.clear();
    for (var c in lockedChapters) {
      _selectedChapterIds.add(c.id);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            double totalCost = 0.0;
            for (var c in lockedChapters) {
              if (_selectedChapterIds.contains(c.id)) {
                totalCost += c.price;
              }
            }

            return Container(
              padding: const EdgeInsets.all(20),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'অধ্যায় নির্বাচন করে কিনুন',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'আপনার ওয়ালেট ব্যালেন্স: ৳${auth.user?.walletBalance.toStringAsFixed(2) ?? '0.00'}',
                    style: const TextStyle(color: SikhunTheme.primary, fontWeight: FontWeight.w600),
                  ),
                  const Divider(height: 24),
                  Expanded(
                    child: ListView.builder(
                      itemCount: lockedChapters.length,
                      itemBuilder: (context, idx) {
                        final ch = lockedChapters[idx];
                        final isChecked = _selectedChapterIds.contains(ch.id);
                        return CheckboxListTile(
                          value: isChecked,
                          title: Text(ch.title, style: const TextStyle(fontSize: 14)),
                          subtitle: Text('পৃষ্ঠা ${ch.pageStart}-${ch.pageEnd} • ৳${ch.price.toStringAsFixed(0)}'),
                          activeColor: SikhunTheme.primary,
                          onChanged: (val) {
                            setModalState(() {
                              if (val == true) {
                                _selectedChapterIds.add(ch.id);
                              } else {
                                _selectedChapterIds.remove(ch.id);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'মোট নির্বাচিত: ${_selectedChapterIds.length} টি',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'মোট: ৳${totalCost.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: SikhunTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Consumer<LibraryProvider>(
                    builder: (btnContext, libProv, _) {
                      return ElevatedButton(
                        onPressed: (_selectedChapterIds.isEmpty || libProv.isActionLoading)
                            ? null
                            : () async {
                                final res = await libProv.purchaseChapters(
                                  bookId: book.id,
                                  chapterIds: _selectedChapterIds.toList(),
                                );
                                if (ctx.mounted) {
                                  Navigator.of(ctx).pop();
                                }
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(res['message'])),
                                );
                              },
                        child: libProv.isActionLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('নিশ্চিত করুন ও কিনুন'),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lib = Provider.of<LibraryProvider>(context);
    final book = lib.selectedBook;

    if (lib.isLoading && book == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (book == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('বই লোড করা যায়নি'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => lib.fetchBookDetails(widget.bookId),
                child: const Text('আবার চেষ্টা করুন'),
              ),
            ],
          ),
        ),
      );
    }

    final hasLockedChapters = book.chapters.any((c) => !c.canRead);

    return Scaffold(
      appBar: AppBar(
        title: Text(book.title),
        actions: [
          IconButton(
            icon: Icon(
              book.inBookshelf ? Icons.bookmark : Icons.bookmark_border,
              color: book.inBookshelf ? SikhunTheme.primary : null,
            ),
            tooltip: book.inBookshelf ? 'তাক থেকে সরান' : 'তাকে যোগ করুন',
            onPressed: () => lib.toggleBookshelf(book),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.menu_book),
                label: const Text('পড়া শুরু করুন'),
                onPressed: () => _openReader(),
              ),
            ),
            if (hasLockedChapters) ...[
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  label: const Text('অধ্যায় কিনুন'),
                  onPressed: () => _showBatchPurchaseSheet(book),
                ),
              ),
            ],
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Cover + Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 120,
                    height: 170,
                    color: Colors.grey.shade200,
                    child: book.coverImage != null && book.coverImage!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: book.coverImage!,
                            fit: BoxFit.cover,
                            placeholder: (c, u) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (c, u, e) => const Icon(Icons.book, size: 48),
                          )
                        : const Icon(Icons.book, size: 48),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'লেখক: ${book.author ?? "শিখুন"}',
                        style: const TextStyle(color: SikhunTheme.mutedDark, fontSize: 13),
                      ),
                      Text(
                        'প্রকাশনী: ${book.publisher ?? "শিখুন প্রকাশনী"}',
                        style: const TextStyle(color: SikhunTheme.mutedDark, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: SikhunTheme.primary.withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              book.gradeLevel ?? 'সকল',
                              style: const TextStyle(
                                color: SikhunTheme.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (book.totalPages > 0)
                            Text(
                              '${book.totalPages} পৃষ্ঠা',
                              style: const TextStyle(fontSize: 12, color: SikhunTheme.mutedDark),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'মূল্য: ${book.effectivePriceDisplay}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: SikhunTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Description
            if (book.description != null && book.description!.isNotEmpty) ...[
              const Text(
                'বইটি সম্পর্কে',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                book.description!,
                style: const TextStyle(fontSize: 13, height: 1.5, color: SikhunTheme.textDark),
              ),
              const SizedBox(height: 20),
            ],

            // Chapters List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'অধ্যায়সমূহ (${book.chapters.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (hasLockedChapters)
                  TextButton.icon(
                    icon: const Icon(Icons.add_shopping_cart, size: 16),
                    label: const Text('একত্রে কিনুন', style: TextStyle(fontSize: 12)),
                    onPressed: () => _showBatchPurchaseSheet(book),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            if (book.chapters.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    'সম্পূর্ণ বইটি একসাথেই পড়া যাবে',
                    style: TextStyle(color: SikhunTheme.mutedDark, fontSize: 13),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: book.chapters.length,
                separatorBuilder: (c, i) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final chapter = book.chapters[index];
                  final canRead = chapter.canRead;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: canRead
                          ? SikhunTheme.accent.withAlpha(30)
                          : Colors.grey.shade200,
                      child: Icon(
                        canRead ? Icons.lock_open : Icons.lock,
                        size: 16,
                        color: canRead ? SikhunTheme.accent : Colors.grey,
                      ),
                    ),
                    title: Text(
                      chapter.title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'পৃষ্ঠা: ${chapter.pageStart} - ${chapter.pageEnd}',
                      style: const TextStyle(fontSize: 12, color: SikhunTheme.mutedDark),
                    ),
                    trailing: canRead
                        ? TextButton(
                            onPressed: () => _openReader(page: chapter.pageStart),
                            child: const Text('পড়ুন'),
                          )
                        : Text(
                            '৳${chapter.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: SikhunTheme.primary,
                            ),
                          ),
                  );
                },
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
