import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../models/book_model.dart';
import '../../providers/library_provider.dart';
import 'book_details_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _categories = [
    {'label': 'সকল বই', 'value': 'all'},
    {'label': 'HSC', 'value': 'HSC'},
    {'label': 'SSC', 'value': 'SSC'},
    {'label': 'ভর্তি পরীক্ষা', 'value': 'ADMISSION'},
    {'label': 'চাকরি প্রস্তুতি', 'value': 'JOB'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lib = Provider.of<LibraryProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('শিখুন লাইব্রেরি'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: SikhunTheme.primary,
          unselectedLabelColor: SikhunTheme.mutedDark,
          indicatorColor: SikhunTheme.primary,
          tabs: const [
            Tab(icon: Icon(Icons.collections_bookmark_outlined), text: 'সব বই'),
            Tab(icon: Icon(Icons.bookmark_outline), text: 'আমার তাক'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: All Books
          Column(
            children: [
              // Search input
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'বইয়ের নাম বা লেখক খুঁজুন...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              lib.fetchBooks(search: '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                  onSubmitted: (val) {
                    lib.fetchBooks(search: val.trim());
                  },
                ),
              ),

              // Category chips
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = lib.selectedCategory == cat['value'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat['label']!),
                        selected: isSelected,
                        onSelected: (_) {
                          lib.setCategory(cat['value']!);
                        },
                        selectedColor: SikhunTheme.primary.withAlpha(40),
                        checkmarkColor: SikhunTheme.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? SikhunTheme.primary : SikhunTheme.textDark,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),

              // Books Grid
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => lib.fetchBooks(),
                  child: lib.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : lib.books.isEmpty
                          ? const Center(
                              child: Text(
                                'কোনো বই পাওয়া যায়নি',
                                style: TextStyle(color: SikhunTheme.mutedDark),
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(12),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.62,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: lib.books.length,
                              itemBuilder: (context, index) {
                                final book = lib.books[index];
                                return _buildBookGridCard(book);
                              },
                            ),
                ),
              ),
            ],
          ),

          // Tab 2: My Shelf
          RefreshIndicator(
            onRefresh: () => lib.fetchBookshelf(),
            child: lib.bookshelf.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.menu_book, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'আপনার তাকে এখনো কোনো বই নেই',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'লাইব্রেরি থেকে বই নির্বাচন করে আপনার তাকে যোগ করুন',
                          style: TextStyle(color: SikhunTheme.mutedDark, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            _tabController.animateTo(0);
                          },
                          child: const Text('বই ব্রাউজ করুন'),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.62,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: lib.bookshelf.length,
                    itemBuilder: (context, index) {
                      final book = lib.bookshelf[index];
                      return _buildBookGridCard(book);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookGridCard(BookModel book) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  book.coverImage != null && book.coverImage!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: book.coverImage!,
                          fit: BoxFit.cover,
                          placeholder: (c, u) => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          errorWidget: (c, u, e) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.book, size: 48, color: Colors.grey),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.book, size: 48, color: Colors.grey),
                        ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: book.isFree ? SikhunTheme.accent : SikhunTheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        book.effectivePriceDisplay,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    book.author ?? 'শিখুন',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: SikhunTheme.mutedDark, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        book.gradeLevel ?? 'সকল',
                        style: const TextStyle(
                          color: SikhunTheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (book.totalPages > 0)
                        Text(
                          '${book.totalPages} পৃঃ',
                          style: const TextStyle(color: SikhunTheme.mutedDark, fontSize: 11),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
