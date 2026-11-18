import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../models/blog_model.dart';
import '../../providers/blog_provider.dart';
import 'blog_details_screen.dart';

class BlogListScreen extends StatefulWidget {
  const BlogListScreen({super.key});

  @override
  State<BlogListScreen> createState() => _BlogListScreenState();
}

class _BlogListScreenState extends State<BlogListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BlogProvider>(context, listen: false).init();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blog = Provider.of<BlogProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ব্লগ ও নির্দেশিকা'),
      ),
      body: Column(
        children: [
          // Search input
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ব্লগ খুঁজুন...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          blog.fetchBlogs(search: '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onSubmitted: (val) {
                blog.fetchBlogs(search: val.trim());
              },
            ),
          ),

          // Categories horizontal list
          if (blog.categories.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('সকল ক্যাটাগরি'),
                      selected: blog.selectedCategory == null,
                      onSelected: (_) => blog.setCategory(null),
                    ),
                  ),
                  ...blog.categories.map((cat) {
                    final isSel = blog.selectedCategory == cat.slug;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat.name),
                        selected: isSel,
                        onSelected: (_) => blog.setCategory(cat.slug),
                      ),
                    );
                  }),
                ],
              ),
            ),
          const SizedBox(height: 8),

          // Blogs list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => blog.fetchBlogs(),
              child: blog.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : blog.blogs.isEmpty
                      ? const Center(
                          child: Text(
                            'কোনো ব্লগ পাওয়া যায়নি',
                            style: TextStyle(color: SikhunTheme.mutedDark),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: blog.blogs.length,
                          itemBuilder: (context, index) {
                            final item = blog.blogs[index];
                            return _buildBlogCard(context, item);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlogCard(BuildContext context, BlogModel item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BlogDetailsScreen(slug: item.slug),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.coverImage != null && item.coverImage!.isNotEmpty)
              SizedBox(
                height: 180,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: item.coverImage!,
                  fit: BoxFit.cover,
                  placeholder: (c, u) => Container(
                    color: Colors.grey.shade200,
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (c, u, e) => Container(
                    color: SikhunTheme.primary.withAlpha(20),
                    child: const Icon(Icons.article, size: 48, color: SikhunTheme.primary),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (item.category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: SikhunTheme.primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.category!,
                            style: const TextStyle(
                              color: SikhunTheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const Spacer(),
                      const Icon(Icons.schedule, size: 14, color: SikhunTheme.mutedDark),
                      const SizedBox(width: 4),
                      Text(
                        '${item.readingTime} মিনিট পড়া',
                        style: const TextStyle(fontSize: 11, color: SikhunTheme.mutedDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (item.excerpt != null && item.excerpt!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.excerpt!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: SikhunTheme.mutedDark, height: 1.4),
                    ),
                  ],
                  if (item.tags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: item.tags.take(4).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '#$tag',
                            style: const TextStyle(fontSize: 10, color: SikhunTheme.mutedDark),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
