import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/api_endpoints.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class PortalsScreen extends StatefulWidget {
  final int initialTab;

  const PortalsScreen({super.key, this.initialTab = 0});

  @override
  State<PortalsScreen> createState() => _PortalsScreenState();
}

class _PortalsScreenState extends State<PortalsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ভর্তি ও চাকরি নিউজ পোর্টাল'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(icon: Icon(Icons.school_outlined), text: 'বিশ্ববিদ্যালয় ভর্তি'),
            Tab(icon: Icon(Icons.work_outline), text: 'চাকরি ও বিসিএস'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          _AdmissionsTab(),
          _JobsTab(),
        ],
      ),
    );
  }
}

// ======================= TAB 1: ADMISSIONS =======================
class _AdmissionsTab extends StatefulWidget {
  const _AdmissionsTab();

  @override
  State<_AdmissionsTab> createState() => _AdmissionsTabState();
}

class _AdmissionsTabState extends State<_AdmissionsTab> {
  final _searchCtrl = TextEditingController();
  String _type = 'all';
  bool _isLoading = true;
  List<Map<String, dynamic>> _notices = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final params = <String, dynamic>{};
    if (_type != 'all') params['type'] = _type;
    if (_searchCtrl.text.trim().isNotEmpty) params['search'] = _searchCtrl.text.trim();

    final res = await ApiService.get(ApiEndpoints.admissionNotices, queryParams: params);
    if (!mounted) return;

    if (res.success && res.data != null) {
      final raw = res.data is List
          ? res.data as List
          : (res.data is Map && res.data['data'] is List ? res.data['data'] as List : []);
      setState(() {
        _notices = raw.whereType<Map<String, dynamic>>().toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              hintText: 'বিশ্ববিদ্যালয় বা ভর্তি বিজ্ঞপ্তি খুঁজুন...',
              prefixIcon: Icon(Icons.search),
            ),
            onSubmitted: (_) => _load(),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              _chip('all', 'সকল'),
              const SizedBox(width: 6),
              _chip('public', 'পাবলিক'),
              const SizedBox(width: 6),
              _chip('guccho', 'গুচ্ছ (GST)'),
              const SizedBox(width: 6),
              _chip('private', 'প্রাইভেট'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _notices.isEmpty
                  ? const Center(child: Text('কোনো ভর্তি বিজ্ঞপ্তি পাওয়া যায়নি'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notices.length,
                        itemBuilder: (ctx, i) {
                          final n = _notices[i];
                          final slug = n['slug']?.toString() ?? '';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(14),
                              title: Text(
                                n['title']?.toString() ?? 'ভর্তি বিজ্ঞপ্তি',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (n['institution_name'] != null)
                                      Text('প্রতিষ্ঠান: ${n['institution_name']}'),
                                    if (n['application_deadline'] != null)
                                      Text(
                                        'আবেদনের শেষ তারিখ: ${n['application_deadline'].toString().split('T').first}',
                                        style: const TextStyle(
                                            color: SikhunTheme.danger, fontWeight: FontWeight.w600),
                                      ),
                                    if (n['application_fee'] != null)
                                      Text('আবেদন ফি: ${n['application_fee']}'),
                                  ],
                                ),
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                if (slug.isEmpty) return;
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PortalDetailScreen(slug: slug, isAdmission: true),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _chip(String val, String label) {
    final selected = _type == val;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: SikhunTheme.primary,
      labelStyle: TextStyle(color: selected ? Colors.white : null, fontSize: 12),
      onSelected: (_) {
        setState(() => _type = val);
        _load();
      },
    );
  }
}

// ======================= TAB 2: JOB NEWS =======================
class _JobsTab extends StatefulWidget {
  const _JobsTab();

  @override
  State<_JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends State<_JobsTab> {
  final _searchCtrl = TextEditingController();
  String _category = 'all';
  bool _isLoading = true;
  List<Map<String, dynamic>> _jobs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final params = <String, dynamic>{};
    if (_category != 'all') params['category'] = _category;
    if (_searchCtrl.text.trim().isNotEmpty) params['search'] = _searchCtrl.text.trim();

    final res = await ApiService.get(ApiEndpoints.jobNews, queryParams: params);
    if (!mounted) return;

    if (res.success && res.data != null) {
      final raw = res.data is List
          ? res.data as List
          : (res.data is Map && res.data['data'] is List ? res.data['data'] as List : []);
      setState(() {
        _jobs = raw.whereType<Map<String, dynamic>>().toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              hintText: 'চাকরি বা প্রতিষ্ঠান খুঁজুন...',
              prefixIcon: Icon(Icons.search),
            ),
            onSubmitted: (_) => _load(),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              _chip('all', 'সকল'),
              const SizedBox(width: 6),
              _chip('government', 'সরকারি ও বিসিএস'),
              const SizedBox(width: 6),
              _chip('bank', 'ব্যাংক'),
              const SizedBox(width: 6),
              _chip('ngo', 'এনজিও'),
              const SizedBox(width: 6),
              _chip('private', 'বেসরকারি'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _jobs.isEmpty
                  ? const Center(child: Text('কোনো চাকরির বিজ্ঞপ্তি পাওয়া যায়নি'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _jobs.length,
                        itemBuilder: (ctx, i) {
                          final j = _jobs[i];
                          final slug = j['slug']?.toString() ?? '';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(14),
                              title: Text(
                                j['title']?.toString() ?? 'চাকরির বিজ্ঞপ্তি',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (j['organization'] != null)
                                      Text('প্রতিষ্ঠান: ${j['organization']}'),
                                    if (j['deadline'] != null)
                                      Text(
                                        'শেষ তারিখ: ${j['deadline'].toString().split('T').first}',
                                        style: const TextStyle(
                                            color: SikhunTheme.danger, fontWeight: FontWeight.w600),
                                      ),
                                    if (j['vacancy_count'] != null)
                                      Text('শূন্যপদ: ${j['vacancy_count']}'),
                                  ],
                                ),
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                if (slug.isEmpty) return;
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PortalDetailScreen(slug: slug, isAdmission: false),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _chip(String val, String label) {
    final selected = _category == val;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: SikhunTheme.primary,
      labelStyle: TextStyle(color: selected ? Colors.white : null, fontSize: 12),
      onSelected: (_) {
        setState(() => _category = val);
        _load();
      },
    );
  }
}

class PortalDetailScreen extends StatefulWidget {
  final String slug;
  final bool isAdmission;

  const PortalDetailScreen({super.key, required this.slug, required this.isAdmission});

  @override
  State<PortalDetailScreen> createState() => _PortalDetailScreenState();
}

class _PortalDetailScreenState extends State<PortalDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _item;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final url = widget.isAdmission
        ? ApiEndpoints.admissionDetails(widget.slug)
        : ApiEndpoints.jobDetails(widget.slug);
    final res = await ApiService.get(url);
    if (!mounted) return;
    if (res.success && res.data is Map<String, dynamic>) {
      setState(() {
        _item = (widget.isAdmission ? res.data['notice'] : res.data['job']) as Map<String, dynamic>?;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    final applyUrl = widget.isAdmission
        ? (item?['apply_url']?.toString() ?? item?['official_website']?.toString())
        : item?['apply_link']?.toString();

    return Scaffold(
      appBar: AppBar(title: Text(widget.isAdmission ? 'ভর্তি বিজ্ঞপ্তি' : 'চাকরির বিজ্ঞপ্তি')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : item == null
              ? const Center(child: Text('তথ্য পাওয়া যায়নি'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(item['title']?.toString() ?? '',
                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    if (item['institution_name'] != null || item['organization'] != null)
                      Text(
                        '${widget.isAdmission ? 'প্রতিষ্ঠান' : 'নিয়োগদাতা'}: ${item['institution_name'] ?? item['organization']}',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: SikhunTheme.primary),
                      ),
                    const SizedBox(height: 12),
                    if (item['description'] != null)
                      Text(
                        item['description'].toString().replaceAll(RegExp(r'<[^>]*>'), ''),
                        style: const TextStyle(fontSize: 14, height: 1.6),
                      ),
                    if (applyUrl != null && applyUrl.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final uri = Uri.tryParse(applyUrl);
                            if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
                          },
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('অনলাইন আবেদন / অফিসিয়াল লিংক'),
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }
}
