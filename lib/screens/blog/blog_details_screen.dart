import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../providers/blog_provider.dart';

class BlogDetailsScreen extends StatefulWidget {
  final String slug;

  const BlogDetailsScreen({super.key, required this.slug});

  @override
  State<BlogDetailsScreen> createState() => _BlogDetailsScreenState();
}

class _BlogDetailsScreenState extends State<BlogDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BlogProvider>(context, listen: false).fetchBlogDetails(widget.slug);
    });
  }

  @override
  Widget build(BuildContext context) {
    final blogProv = Provider.of<BlogProvider>(context);
    final item = blogProv.selectedBlog;

    if (blogProv.isLoading && item == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (item == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('ব্লগ লোড করা যায়নি'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => blogProv.fetchBlogDetails(widget.slug),
                child: const Text('আবার চেষ্টা করুন'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ব্লগ বিস্তারিত'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.coverImage != null && item.coverImage!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: item.coverImage!,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorWidget: (c, u, e) => const SizedBox.shrink(),
              ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: SikhunTheme.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.category!,
                        style: const TextStyle(
                          color: SikhunTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    item.title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.3),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 14,
                        backgroundColor: SikhunTheme.primary,
                        child: Icon(Icons.person, size: 16, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.authorName ?? 'শিখুন',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const Spacer(),
                      const Icon(Icons.schedule, size: 14, color: SikhunTheme.mutedDark),
                      const SizedBox(width: 4),
                      Text(
                        '${item.readingTime} মিনিট পড়া',
                        style: const TextStyle(fontSize: 12, color: SikhunTheme.mutedDark),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  // Blog content (stripping HTML tags if present)
                  Text(
                    _cleanHtml(item.content ?? item.excerpt ?? ''),
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.7,
                      color: SikhunTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (item.tags.isNotEmpty) ...[
                    const Text(
                      'ট্যাগসমূহ:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: item.tags.map((tag) {
                        return Chip(
                          label: Text('#$tag', style: const TextStyle(fontSize: 11)),
                          backgroundColor: Colors.grey.shade100,
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _cleanHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
