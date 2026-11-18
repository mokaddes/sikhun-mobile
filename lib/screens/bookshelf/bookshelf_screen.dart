import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../providers/library_provider.dart';
import '../../providers/locale_provider.dart';
import '../library/book_details_screen.dart';
import '../reader/book_reader_screen.dart';

class BookshelfScreen extends StatefulWidget {
  const BookshelfScreen({super.key});

  @override
  State<BookshelfScreen> createState() => _BookshelfScreenState();
}

class _BookshelfScreenState extends State<BookshelfScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LibraryProvider>(context, listen: false).fetchBookshelf();
    });
  }

  Future<void> _openWebUpload() async {
    final uri = Uri.parse('https://sikhun.com/bookshelf');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lib = Provider.of<LibraryProvider>(context);
    final localeProv = Provider.of<LocaleProvider>(context);
    final en = !localeProv.isBengali;
    final quota = lib.uploadQuota;

    return Scaffold(
      appBar: AppBar(
        title: Text(en ? 'Bookshelf & My Books' : 'আমার বুকশেল্ফ ও নিজস্ব বই'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_outlined),
            tooltip: en ? 'Upload PDF on Web' : 'নিজের PDF আপলোড করুন',
            onPressed: _openWebUpload,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => lib.fetchBookshelf(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Quota Card
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: SikhunTheme.primary.withAlpha(18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: SikhunTheme.primary.withAlpha(50)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_upload_outlined, color: SikhunTheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      en
                          ? 'My Books Slots: ${quota['current_count'] ?? 0}/${quota['max_slots'] ?? 1} • Monthly Re-uploads: ${quota['reuploads_remaining'] ?? 0}'
                          : 'নিজস্ব বই স্লট: ${quota['current_count'] ?? 0}/${quota['max_slots'] ?? 1} • মাসিক আপলোড বাকি: ${quota['reuploads_remaining'] ?? 0}',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            Text(
              en ? 'My Added Books (${lib.myBooks.length})' : 'আমার আপলোড করা বই (${lib.myBooks.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (lib.myBooks.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text('আপনার নিজের আপলোড করা কোনো PDF বই নেই।'),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.upload_file),
                        label: const Text('ওয়েব থেকে PDF আপলোড করুন'),
                        onPressed: _openWebUpload,
                      ),
                    ],
                  ),
                ),
              )
            else
              ...lib.myBooks.map((mb) {
                final id = mb['id'] is int ? mb['id'] : int.tryParse(mb['id'].toString()) ?? 0;
                final title = (mb['title'] ?? 'My Book').toString();
                final status = (mb['processing_status'] ?? 'pending').toString();
                final pages = mb['total_pages'] ?? 0;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0x208A5A32),
                      child: Icon(Icons.picture_as_pdf, color: SikhunTheme.primary),
                    ),
                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('$pages পৃষ্ঠা • স্ট্যাটাস: $status', style: const TextStyle(fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu_book, color: SikhunTheme.primary),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BookReaderScreen(
                                  bookId: id,
                                  title: title,
                                  isMyBook: true,
                                  initialPage: int.tryParse((mb['last_page'] ?? 1).toString()) ?? 1,
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: SikhunTheme.danger),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('বই মুছে ফেলুন'),
                                content: Text('আপনি কি "$title" বুকশেল্ফ থেকে মুছে ফেলতে চান?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('না')),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: SikhunTheme.danger),
                                    onPressed: () => Navigator.of(ctx).pop(true),
                                    child: const Text('মুছে ফেলুন'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await lib.deleteMyBook(id);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 18),
            Text(
              en ? 'Library Bookshelf (${lib.bookshelf.length})' : 'লাইব্রেরি বুকশেল্ফ (${lib.bookshelf.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (lib.bookshelf.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('আপনার লাইব্রেরি বুকশেল্ফে এখনো কোনো বই নেই।'),
                ),
              )
            else
              ...lib.bookshelf.map((book) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 44,
                          height: 58,
                          child: book.coverImage != null
                              ? CachedNetworkImage(imageUrl: book.coverImage!, fit: BoxFit.cover)
                              : Container(color: Colors.grey.shade200, child: const Icon(Icons.book)),
                        ),
                      ),
                      title: Text(book.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(
                        '${book.totalPages} পৃষ্ঠা${book.lastReadPage != null ? ' • সর্বশেষ: পৃষ্ঠা ${book.lastReadPage}' : ''}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BookReaderScreen(
                                bookId: book.id,
                                title: book.title,
                                initialPage: book.lastReadPage ?? 1,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SikhunTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Text('পড়ুন', style: TextStyle(fontSize: 12)),
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => BookDetailsScreen(bookId: book.id)),
                        );
                      },
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
