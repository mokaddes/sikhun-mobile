import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../models/book_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/library_provider.dart';
import '../auth/login_screen.dart';
import '../reader/book_reader_screen.dart';

class BookDetailsScreen extends StatefulWidget {
  final int bookId;
  final String? bookSlug;

  const BookDetailsScreen({super.key, required this.bookId, this.bookSlug});

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  final Set<int> _selectedChapterIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lib = context.read<LibraryProvider>();
      String? slug = widget.bookSlug;
      if (slug == null) {
        final match = [...lib.books, ...lib.bookshelf]
            .where((b) => b.id == widget.bookId && b.slug != null && b.slug!.isNotEmpty)
            .toList();
        if (match.isNotEmpty) slug = match.first.slug;
      }
      lib.fetchBookDetails(slug ?? widget.bookId);
    });
  }

  void _openReader(BookModel book, {int? page}) {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookReaderScreen(
          bookId: book.id,
          title: book.title,
          isMyBook: false,
          initialPage: page ?? book.lastReadPage ?? 1,
        ),
      ),
    );
  }

  Future<String?> _pickPaymentMethod(String label) async {
    final auth = context.read<AuthProvider>();
    return showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet, color: SikhunTheme.primary),
                title: Text('শিখুন ওয়ালেট (ব্যালেন্স: ৳${auth.user?.walletBalance.toStringAsFixed(0) ?? 0})'),
                onTap: () => Navigator.pop(ctx, 'wallet'),
              ),
              ListTile(
                leading: const Icon(Icons.payment, color: SikhunTheme.accent),
                title: const Text('অনলাইন পেমেন্ট (bKash / Nagad / MHPay)'),
                onTap: () => Navigator.pop(ctx, 'mhpay'),
              ),
              ListTile(
                leading: const Icon(Icons.credit_card, color: Colors.blue),
                title: const Text('ZiniPay গেটওয়ে'),
                onTap: () => Navigator.pop(ctx, 'zinipay'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _buyFullBook(BookModel book) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    final method = await _pickPaymentMethod('${book.title} (${book.effectivePriceDisplay})');
    if (method == null || !mounted) return;

    final lib = context.read<LibraryProvider>();
    final res = await lib.purchaseBook(bookId: book.id, paymentMethod: method);
    if (!mounted) return;

    if (res['success'] == true) {
      if (res['redirect_url'] != null) {
        final uri = Uri.tryParse(res['redirect_url'].toString());
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
        }
      } else {
        await auth.fetchProfile();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'].toString()), backgroundColor: SikhunTheme.success),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'].toString()), backgroundColor: SikhunTheme.danger),
      );
    }
  }

  void _showBatchPurchaseSheet(BookModel book) {
    final lockedChapters = book.chapters.where((c) => !c.canRead).toList();
    if (lockedChapters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('এই বইয়ের সকল অধ্যায় আপনার জন্য উন্মুক্ত!')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            double totalCost = 0;
            for (final c in lockedChapters) {
              if (_selectedChapterIds.contains(c.id)) {
                totalCost += c.price;
              }
            }

            return Container(
              padding: const EdgeInsets.all(20),
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.78),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('অধ্যায় সিলেক্ট করে একত্রে কিনুন',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            if (_selectedChapterIds.length == lockedChapters.length) {
                              _selectedChapterIds.clear();
                            } else {
                              _selectedChapterIds.addAll(lockedChapters.map((e) => e.id));
                            }
                          });
                        },
                        child: Text(
                          _selectedChapterIds.length == lockedChapters.length
                              ? 'সব বাদ দিন'
                              : 'সব সিলেক্ট করুন',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: lockedChapters.length,
                      itemBuilder: (ctx, i) {
                        final c = lockedChapters[i];
                        final isSel = _selectedChapterIds.contains(c.id);
                        return CheckboxListTile(
                          value: isSel,
                          activeColor: SikhunTheme.primary,
                          title: Text(c.title, style: const TextStyle(fontSize: 14)),
                          subtitle: Text('পৃষ্ঠা: ${c.pageStart} - ${c.pageEnd}',
                              style: const TextStyle(fontSize: 12)),
                          secondary: Text('৳${c.price.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: SikhunTheme.primary)),
                          onChanged: (val) {
                            setModalState(() {
                              if (val == true) {
                                _selectedChapterIds.add(c.id);
                              } else {
                                _selectedChapterIds.remove(c.id);
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('নির্বাচিত অধ্যায়: ${_selectedChapterIds.length} টি',
                              style: const TextStyle(fontSize: 12)),
                          Text('মোট: ৳${totalCost.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.bold, color: SikhunTheme.primary)),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _selectedChapterIds.isEmpty
                            ? null
                            : () async {
                                Navigator.pop(context);
                                final method = await _pickPaymentMethod(
                                    'অধ্যায়সমূহ (৳${totalCost.toStringAsFixed(0)})');
                                if (method == null || !mounted) return;
                                final libProv = context.read<LibraryProvider>();
                                final auth = context.read<AuthProvider>();
                                final res = await libProv.purchaseChapters(
                                  bookId: book.id,
                                  chapterIds: _selectedChapterIds.toList(),
                                  paymentMethod: method,
                                );
                                if (!mounted) return;
                                if (res['success'] == true) {
                                  if (res['redirect_url'] != null) {
                                    final uri = Uri.tryParse(res['redirect_url'].toString());
                                    if (uri != null) {
                                      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
                                    }
                                  } else {
                                    await auth.fetchProfile();
                                  }
                                  _selectedChapterIds.clear();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(res['message'].toString()),
                                        backgroundColor: SikhunTheme.success),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(res['message'].toString()),
                                        backgroundColor: SikhunTheme.danger),
                                  );
                                }
                              },
                        icon: const Icon(Icons.shopping_cart_checkout, size: 18),
                        label: const Text('কনফার্ম করুন'),
                      ),
                    ],
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
    final lib = context.watch<LibraryProvider>();
    final book = lib.selectedBook;

    if (lib.isLoading && book == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('বইয়ের বিবরণ')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (book == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('বইয়ের বিবরণ')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(lib.errorMessage ?? 'বইটি পাওয়া যায়নি'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => lib.fetchBookDetails(widget.bookSlug ?? widget.bookId),
                child: const Text('আবার চেষ্টা করুন'),
              ),
            ],
          ),
        ),
      );
    }

    final hasLockedChapters = book.chapters.any((c) => !c.canRead);
    final hasAnyReadAccess = book.hasAccess || book.isFree || book.isPurchased || book.chapters.any((c) => c.canRead);

    return Scaffold(
      appBar: AppBar(
        title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: Icon(
              book.inBookshelf ? Icons.bookmark : Icons.bookmark_border,
              color: book.inBookshelf ? SikhunTheme.primary : null,
            ),
            tooltip: 'বুকশেলফে রাখুন',
            onPressed: () async {
              final res = await lib.addToBookshelf(book);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res.message ?? (res.success ? 'বুকশেলফে সংযুক্ত হয়েছে' : 'ব্যর্থ হয়েছে')),
                    backgroundColor: res.success ? SikhunTheme.success : SikhunTheme.danger,
                  ),
                );
              }
            },
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 8, offset: const Offset(0, -2)),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              if (hasAnyReadAccess)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openReader(book),
                    icon: const Icon(Icons.menu_book, size: 18),
                    label: Text(
                      book.lastReadPage != null && book.lastReadPage! > 1
                          ? 'পড়া চালিয়ে যান (${book.lastReadPage})'
                          : 'বইটি পড়ুন',
                    ),
                  ),
                )
              else
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: lib.isActionLoading ? null : () => _buyFullBook(book),
                    icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                    label: Text('সম্পূর্ণ বই কিনুন (${book.effectivePriceDisplay})'),
                  ),
                ),
              if (hasLockedChapters && book.chapterPurchaseEnabled) ...[
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: SikhunTheme.accent),
                  onPressed: () => _showBatchPurchaseSheet(book),
                  icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                  label: const Text('অধ্যায় কিনুন'),
                ),
              ],
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                      Text(book.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      if (book.author != null)
                        Text('লেখক: ${book.author}',
                            style: const TextStyle(color: SikhunTheme.mutedDark, fontSize: 13)),
                      const SizedBox(height: 6),
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
                            Text('${book.totalPages} পৃষ্ঠা',
                                style: const TextStyle(fontSize: 12, color: SikhunTheme.mutedDark)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'মূল্য: ${book.effectivePriceDisplay}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold, color: SikhunTheme.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (book.description != null && book.description!.isNotEmpty) ...[
              const Text('বইটি সম্পর্কে', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(book.description!, style: const TextStyle(fontSize: 13, height: 1.5)),
              const SizedBox(height: 20),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('অধ্যায়সমূহ (${book.chapters.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                if (hasLockedChapters && book.chapterPurchaseEnabled)
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
                  color: SikhunTheme.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text('সম্পূর্ণ বইটি একসাথেই পড়া যাবে', style: TextStyle(fontSize: 13)),
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
                  final canRead = chapter.canRead || book.hasAccess;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          canRead ? SikhunTheme.success.withAlpha(30) : Colors.grey.shade200,
                      child: Icon(
                        canRead ? Icons.lock_open : Icons.lock,
                        size: 16,
                        color: canRead ? SikhunTheme.success : Colors.grey,
                      ),
                    ),
                    title: Text(chapter.title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text('পৃষ্ঠা: ${chapter.pageStart} - ${chapter.pageEnd}',
                        style: const TextStyle(fontSize: 12, color: SikhunTheme.mutedDark)),
                    trailing: canRead
                        ? TextButton(
                            onPressed: () => _openReader(book, page: chapter.pageStart),
                            child: const Text('পড়ুন'),
                          )
                        : Text(
                            '৳${chapter.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, color: SikhunTheme.primary),
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
