import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/api_endpoints.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  bool _isLoading = true;
  String? _error;
  String _selectedLevel = 'all';
  String _search = '';
  List<Map<String, dynamic>> _courses = [];

  final List<Map<String, String>> _levels = const [
    {'id': 'all', 'label': 'সকল কোর্স'},
    {'id': 'admission', 'label': 'ভর্তি পরীক্ষা'},
    {'id': 'job', 'label': 'চাকরি ও বিসিএস'},
    {'id': 'hsc', 'label': 'HSC'},
    {'id': 'ssc', 'label': 'SSC'},
    {'id': 'university', 'label': 'বিশ্ববিদ্যালয়'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final params = <String, dynamic>{};
    if (_selectedLevel != 'all') {
      params['level'] = _selectedLevel;
    }

    final res = await ApiService.get(ApiEndpoints.courses, queryParams: params);
    if (!mounted) return;

    if (res.success && res.data != null) {
      final raw = res.data is List
          ? res.data as List
          : (res.data is Map && res.data['data'] is List ? res.data['data'] as List : []);
      setState(() {
        _courses = raw.whereType<Map<String, dynamic>>().toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = res.message ?? 'কোর্স তালিকা লোড করা যায়নি';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _search.trim().isEmpty
        ? _courses
        : _courses.where((c) {
            final t = (c['title'] ?? '').toString().toLowerCase();
            final d = (c['description'] ?? '').toString().toLowerCase();
            final q = _search.trim().toLowerCase();
            return t.contains(q) || d.contains(q);
          }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('কোর্সসমূহ (Courses)')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'কোর্স খুঁজুন...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _levels.length,
              itemBuilder: (ctx, i) {
                final lv = _levels[i];
                final selected = _selectedLevel == lv['id'];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(lv['label']!),
                    selected: selected,
                    selectedColor: SikhunTheme.primary,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : null,
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) {
                      setState(() => _selectedLevel = lv['id']!);
                      _loadCourses();
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_error!),
                            const SizedBox(height: 8),
                            ElevatedButton(onPressed: _loadCourses, child: const Text('আবার চেষ্টা করুন')),
                          ],
                        ),
                      )
                    : filtered.isEmpty
                        ? const Center(child: Text('এই ক্যাটাগরিতে কোনো কোর্স নেই'))
                        : RefreshIndicator(
                            onRefresh: _loadCourses,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filtered.length,
                              itemBuilder: (ctx, i) {
                                final c = filtered[i];
                                final slug = c['slug']?.toString() ?? '';
                                final title = c['title']?.toString() ?? 'কোর্স';
                                final cover = c['cover_image_url']?.toString();
                                final price = double.tryParse(c['price']?.toString() ?? '0') ?? 0;
                                final mentor = (c['mentor'] is Map) ? c['mentor']['name']?.toString() : null;
                                final category = (c['category'] is Map) ? c['category']['name']?.toString() : null;
                                final delivery = c['delivery_type']?.toString() ?? 'video';

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  clipBehavior: Clip.antiAlias,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  child: InkWell(
                                    onTap: () {
                                      if (slug.isEmpty) return;
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => CourseDetailsScreen(slug: slug, title: title),
                                        ),
                                      );
                                    },
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (cover != null && cover.isNotEmpty)
                                          SizedBox(
                                            height: 165,
                                            width: double.infinity,
                                            child: CachedNetworkImage(
                                              imageUrl: cover,
                                              fit: BoxFit.cover,
                                              errorWidget: (_, __, ___) => _placeholderBanner(),
                                            ),
                                          )
                                        else
                                          _placeholderBanner(),
                                        Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  if (category != null)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: SikhunTheme.primary.withAlpha(20),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        category,
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.bold,
                                                          color: SikhunTheme.primary,
                                                        ),
                                                      ),
                                                    ),
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: SikhunTheme.accent.withAlpha(20),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      delivery == 'video' ? 'রেকর্ডেড লেসন' : 'লাইভ / রিসোর্স',
                                                      style: const TextStyle(fontSize: 10, color: SikhunTheme.accent),
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Text(
                                                    price <= 0 ? 'ফ্রি' : '৳${price.toStringAsFixed(0)}',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 15,
                                                      color: price <= 0 ? SikhunTheme.success : SikhunTheme.primary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                title,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                              ),
                                              if (mentor != null) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  'মেন্টর: $mentor',
                                                  style: const TextStyle(fontSize: 12, color: SikhunTheme.mutedDark),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderBanner() {
    return Container(
      height: 120,
      width: double.infinity,
      color: SikhunTheme.primary.withAlpha(20),
      child: const Icon(Icons.play_circle_outline, size: 48, color: SikhunTheme.primary),
    );
  }
}

class CourseDetailsScreen extends StatefulWidget {
  final String slug;
  final String title;

  const CourseDetailsScreen({super.key, required this.slug, required this.title});

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  bool _isLoading = true;
  bool _isEnrolling = false;
  String? _error;

  Map<String, dynamic>? _course;
  Map<String, dynamic>? _enrollment;
  bool _isEnrolled = false;
  bool _hasAccess = false;

  @override
  void initState() {
    super.initState();
    _loadCourse();
  }

  Future<void> _loadCourse() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final res = await ApiService.get(ApiEndpoints.courseDetails(widget.slug));
    if (!mounted) return;

    if (res.success && res.data is Map<String, dynamic>) {
      final data = res.data as Map<String, dynamic>;
      setState(() {
        _course = data['course'] as Map<String, dynamic>?;
        _enrollment = data['enrollment'] as Map<String, dynamic>?;
        _isEnrolled = data['is_enrolled'] == true;
        _hasAccess = data['has_access'] == true;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = res.message ?? 'কোর্স বিবরণ লোড করা যায়নি';
        _isLoading = false;
      });
    }
  }

  Future<void> _enroll() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    final courseId = int.tryParse(_course?['id']?.toString() ?? '0') ?? 0;
    final price = double.tryParse(_course?['price']?.toString() ?? '0') ?? 0;

    String paymentMethod = 'wallet';
    if (price > 0 && !_hasAccess) {
      final picked = await showModalBottomSheet<String>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('পেমেন্ট মাধ্যম নির্বাচন করুন (৳${price.toStringAsFixed(0)})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
      if (picked == null) return;
      paymentMethod = picked;
    }

    setState(() => _isEnrolling = true);
    final res = await ApiService.post(
      ApiEndpoints.enrollCourse(courseId),
      body: {'payment_method': paymentMethod},
    );
    if (!mounted) return;
    setState(() => _isEnrolling = false);

    if (res.success) {
      if (res.data is Map && res.data['redirect_url'] != null) {
        final uri = Uri.tryParse(res.data['redirect_url'].toString());
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
        }
      } else {
        await auth.fetchProfile();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('কোর্সে এনরোল সফল হয়েছে!'), backgroundColor: SikhunTheme.success),
        );
      }
      _loadCourse();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? 'এনরোল করা যায়নি'), backgroundColor: SikhunTheme.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _course;
    final price = double.tryParse(c?['price']?.toString() ?? '0') ?? 0;
    final sections = (c?['sections'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
    final progress = double.tryParse(_enrollment?['progress_percentage']?.toString() ?? '0') ?? 0;
    final externalLink = c?['external_link']?.toString();
    final linkNote = c?['link_note']?.toString();

    return Scaffold(
      appBar: AppBar(title: Text(c?['title']?.toString() ?? widget.title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null || c == null
              ? Center(child: Text(_error ?? 'তথ্য পাওয়া যায়নি'))
              : RefreshIndicator(
                  onRefresh: _loadCourse,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (c['cover_image_url'] != null && c['cover_image_url'].toString().isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: CachedNetworkImage(
                            imageUrl: c['cover_image_url'].toString(),
                            height: 190,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(height: 14),
                      Text(
                        c['title']?.toString() ?? '',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      if (c['mentor'] is Map)
                        Text(
                          'মেন্টর: ${c['mentor']['name'] ?? ''}',
                          style: const TextStyle(fontSize: 13, color: SikhunTheme.mutedDark),
                        ),
                      const SizedBox(height: 12),

                      if (_isEnrolled) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: SikhunTheme.success.withAlpha(18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: SikhunTheme.success.withAlpha(60)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('আপনার অগ্রগতি', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text('${progress.toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold, color: SikhunTheme.success)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                value: (progress / 100).clamp(0.0, 1.0),
                                color: SikhunTheme.success,
                                minHeight: 7,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ] else
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isEnrolling ? null : _enroll,
                            icon: _isEnrolling
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.school_outlined),
                            label: Text(
                              _hasAccess || price <= 0
                                  ? 'ফ্রি / সাবস্ক্রিপশনে এনরোল করুন'
                                  : 'এনরোল করুন (৳${price.toStringAsFixed(0)})',
                            ),
                          ),
                        ),

                      if (externalLink != null && externalLink.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Card(
                          color: SikhunTheme.primary.withAlpha(15),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('কোর্স রিসোর্স / ক্লাস লিংক',
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                                if (linkNote != null && linkNote.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(linkNote, style: const TextStyle(fontSize: 12)),
                                ],
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    final uri = Uri.tryParse(externalLink);
                                    if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
                                  },
                                  icon: const Icon(Icons.open_in_new, size: 18),
                                  label: const Text('ক্লাস / রিসোর্স লিংক খুলুন'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      if (c['description'] != null && c['description'].toString().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text('কোর্স পরিচিতি', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(c['description'].toString(), style: const TextStyle(fontSize: 13, height: 1.5)),
                      ],

                      const SizedBox(height: 20),
                      Text('পাঠ্যক্রম (${sections.length} টি সেকশন)',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),

                      ...sections.map((sec) {
                        final lessons = (sec['lessons'] as List? ?? [])
                            .whereType<Map<String, dynamic>>()
                            .toList();
                        final sectionId = int.tryParse(sec['id']?.toString() ?? '0') ?? 0;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ExpansionTile(
                            title: Text(sec['title']?.toString() ?? 'সেকশন',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text('${lessons.length} টি লেসন', style: const TextStyle(fontSize: 12)),
                            children: lessons.map((l) {
                              final lessonId = int.tryParse(l['id']?.toString() ?? '0') ?? 0;
                              final isFreePreview = l['is_free_preview'] == true;
                              final canOpen = _isEnrolled || _hasAccess || isFreePreview;

                              return ListTile(
                                leading: Icon(
                                  canOpen ? Icons.play_circle_fill : Icons.lock_outline,
                                  color: canOpen ? SikhunTheme.primary : Colors.grey,
                                ),
                                title: Text(l['title']?.toString() ?? 'লেসন',
                                    style: const TextStyle(fontSize: 13)),
                                subtitle: Text(
                                  isFreePreview ? 'ফ্রি প্রিভিউ' : (l['type']?.toString() ?? 'লেসন'),
                                  style: const TextStyle(fontSize: 11),
                                ),
                                onTap: canOpen
                                    ? () async {
                                        await Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => LessonViewerScreen(
                                              courseId: int.tryParse(c['id']?.toString() ?? '0') ?? 0,
                                              courseSlug: widget.slug,
                                              sectionId: sectionId,
                                              lessonId: lessonId,
                                              title: l['title']?.toString() ?? 'লেসন',
                                            ),
                                          ),
                                        );
                                        _loadCourse();
                                      }
                                    : () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('এই লেসনটি দেখতে কোর্সে এনরোল করুন।')),
                                        );
                                      },
                              );
                            }).toList(),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
    );
  }
}

class LessonViewerScreen extends StatefulWidget {
  final int courseId;
  final String courseSlug;
  final int sectionId;
  final int lessonId;
  final String title;

  const LessonViewerScreen({
    super.key,
    required this.courseId,
    required this.courseSlug,
    required this.sectionId,
    required this.lessonId,
    required this.title,
  });

  @override
  State<LessonViewerScreen> createState() => _LessonViewerScreenState();
}

class _LessonViewerScreenState extends State<LessonViewerScreen> {
  bool _isLoading = true;
  bool _isCompleting = false;
  bool _isCompleted = false;
  Map<String, dynamic>? _lesson;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLesson();
  }

  Future<void> _loadLesson() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final res = await ApiService.get(
      ApiEndpoints.courseLesson(widget.courseId, widget.sectionId, widget.lessonId),
    );
    if (!mounted) return;
    if (res.success && res.data is Map<String, dynamic>) {
      setState(() {
        _lesson = res.data['lesson'] as Map<String, dynamic>?;
        _isCompleted = res.data['is_completed'] == true;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = res.message ?? 'লেসন লোড করা যায়নি';
        _isLoading = false;
      });
    }
  }

  Future<void> _markCompleted() async {
    setState(() => _isCompleting = true);
    final res = await ApiService.post(
      ApiEndpoints.completeLesson(widget.courseId, widget.sectionId, widget.lessonId),
    );
    if (!mounted) return;
    setState(() => _isCompleting = false);
    if (res.success) {
      setState(() => _isCompleted = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('লেসন সম্পন্ন হয়েছে!'), backgroundColor: SikhunTheme.success),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? 'আপডেট ব্যর্থ হয়েছে'), backgroundColor: SikhunTheme.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = _lesson;
    final videoUrl = l?['stream_url']?.toString() ??
        l?['video_url']?.toString() ??
        ApiEndpoints.courseLessonVideo(widget.courseSlug, widget.sectionId, widget.lessonId);
    final downloadUrl = l?['download_url']?.toString() ??
        (l?['has_attachment'] == true
            ? ApiEndpoints.courseLessonDownload(widget.courseSlug, widget.sectionId, widget.lessonId)
            : null);

    return Scaffold(
      appBar: AppBar(title: Text(l?['title']?.toString() ?? widget.title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null || l == null
              ? Center(child: Text(_error ?? 'লেসন পাওয়া যায়নি'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      l['title']?.toString() ?? widget.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),
                    if ((l['video_url'] != null && l['video_url'].toString().isNotEmpty) ||
                        l['stream_url'] != null)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.play_circle_filled, size: 54, color: Colors.white),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: () {
                                final uri = Uri.tryParse(videoUrl);
                                if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
                              },
                              icon: const Icon(Icons.ondemand_video),
                              label: const Text('ভিডিও প্লেয়ারে দেখুন'),
                            ),
                          ],
                        ),
                      ),
                    if (downloadUrl != null && downloadUrl.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          final uri = Uri.tryParse(downloadUrl);
                          if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('লেসন PDF / হ্যান্ডনোট ডাউনলোড'),
                      ),
                    ],
                    if (l['content'] != null && l['content'].toString().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withAlpha(40)),
                        ),
                        child: SelectableText(
                          l['content'].toString(),
                          style: const TextStyle(fontSize: 14, height: 1.6),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (_isCompleted || _isCompleting) ? null : _markCompleted,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isCompleted ? SikhunTheme.success : SikhunTheme.primary,
                        ),
                        icon: Icon(_isCompleted ? Icons.check_circle : Icons.check),
                        label: Text(_isCompleted ? 'লেসনটি সম্পন্ন হয়েছে' : 'সম্পন্ন হিসেবে চিহ্নিত করুন'),
                      ),
                    ),
                  ],
                ),
    );
  }
}
