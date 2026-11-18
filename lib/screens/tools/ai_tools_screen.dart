import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/api_endpoints.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class AiToolsScreen extends StatefulWidget {
  final int initialTab;

  const AiToolsScreen({super.key, this.initialTab = 0});

  @override
  State<AiToolsScreen> createState() => _AiToolsScreenState();
}

class _AiToolsScreenState extends State<AiToolsScreen> with SingleTickerProviderStateMixin {
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
        title: const Text('এআই স্টাডি স্টুডিও'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(icon: Icon(Icons.rate_review_outlined), text: 'রচনা মূল্যায়ন'),
            Tab(icon: Icon(Icons.calendar_month_outlined), text: 'স্টাডি রুটিন'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          _EssayGraderTab(),
          _StudyScheduleTab(),
        ],
      ),
    );
  }
}

// ======================= TAB 1: ESSAY GRADER =======================
class _EssayGraderTab extends StatefulWidget {
  const _EssayGraderTab();

  @override
  State<_EssayGraderTab> createState() => _EssayGraderTabState();
}

class _EssayGraderTabState extends State<_EssayGraderTab> {
  final _essayCtrl = TextEditingController();
  String _gradingType = 'hsc_bangla';
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _submissions = [];
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadEssays();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _essayCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEssays() async {
    setState(() => _isLoading = true);
    final res = await ApiService.get(ApiEndpoints.essays);
    if (!mounted) return;

    if (res.success && res.data != null) {
      final raw = res.data is List
          ? res.data as List
          : (res.data is Map && res.data['data'] is List ? res.data['data'] as List : []);
      setState(() {
        _submissions = raw.whereType<Map<String, dynamic>>().toList();
        _isLoading = false;
      });
      _checkAndPoll();
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _checkAndPoll() {
    _pollTimer?.cancel();
    final hasPending = _submissions.any((s) => s['status'] == 'grading' || s['status'] == 'pending');
    if (hasPending) {
      _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
        final res = await ApiService.get(ApiEndpoints.essays);
        if (!mounted) return;
        if (res.success && res.data != null) {
          final raw = res.data is List
              ? res.data as List
              : (res.data is Map && res.data['data'] is List ? res.data['data'] as List : []);
          final list = raw.whereType<Map<String, dynamic>>().toList();
          setState(() => _submissions = list);
          if (!list.any((s) => s['status'] == 'grading' || s['status'] == 'pending')) {
            _pollTimer?.cancel();
          }
        }
      });
    }
  }

  Future<void> _submitEssay() async {
    final text = _essayCtrl.text.trim();
    if (text.length < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('অন্তত ১০০ অক্ষরের রচনা/অনুচ্ছেদ লিখুন।')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final res = await ApiService.post(
      ApiEndpoints.essays,
      body: {'grading_type': _gradingType, 'essay_text': text},
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (res.success) {
      _essayCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('এআই মূল্যায়ন শুরু হয়েছে! কয়েক সেকেন্ডের মধ্যে ফলাফল দেখা যাবে।'),
          backgroundColor: SikhunTheme.success,
        ),
      );
      _loadEssays();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? 'জমা দেওয়া যায়নি'), backgroundColor: SikhunTheme.danger),
      );
    }
  }

  Future<void> _retryEssay(int id) async {
    final res = await ApiService.post(ApiEndpoints.essayRetry(id));
    if (!mounted) return;
    if (res.success) {
      _loadEssays();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? 'আবার চেষ্টা করা যায়নি')),
      );
    }
  }

  void _showResult(Map<String, dynamic> sub) {
    final result = sub['result'] is Map ? sub['result'] as Map : null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        builder: (_, sc) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: sc,
            children: [
              const Text('এআই রচনা মূল্যায়ন রিপোর্ট',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(height: 24),
              if (result == null)
                Text('স্ট্যাটাস: ${sub['status'] ?? 'pending'}')
              else
                ...result.entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.key.toString().toUpperCase().replaceAll('_', ' '),
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold, color: SikhunTheme.primary),
                        ),
                        const SizedBox(height: 4),
                        Text(e.value.toString(), style: const TextStyle(fontSize: 13, height: 1.5)),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadEssays,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('নতুন রচনা / প্যারাগ্রাফ জমা দিন',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _gradingType,
                    decoration: const InputDecoration(labelText: 'মূল্যায়ন মানদণ্ড'),
                    items: const [
                      DropdownMenuItem(value: 'hsc_bangla', child: Text('HSC বাংলা রচনা / প্রবন্ধ')),
                      DropdownMenuItem(value: 'hsc_english', child: Text('HSC English Essay / Paragraph')),
                      DropdownMenuItem(value: 'general', child: Text('সাধারণ / বিসিএস লিখিত')),
                      DropdownMenuItem(value: 'custom_rubric', child: Text('বিস্তারিত এআই রুব্রিক')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _gradingType = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _essayCtrl,
                    maxLines: 6,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'আপনার রচনা লিখুন (সর্বনিম্ন ১০০ অক্ষর)',
                      alignLabelWithHint: true,
                      helperText: 'অক্ষর সংখ্যা: ${_essayCtrl.text.trim().length}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submitEssay,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(_isSubmitting ? 'জমা হচ্ছে...' : 'এআই দ্বারা মূল্যায়ন করুন'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('পূর্বের মূল্যায়নসমূহ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (_submissions.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('এখনো কোনো রচনা জমা দেওয়া হয়নি।', textAlign: TextAlign.center),
              ),
            )
          else
            ..._submissions.map((s) {
              final status = s['status']?.toString() ?? 'pending';
              final preview = s['essay_text']?.toString() ?? '';
              final result = s['result'] is Map ? s['result'] as Map : null;
              final score = result?['score'] ?? result?['marks'] ?? result?['grade'];

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(
                    preview.length > 65 ? '${preview.substring(0, 65)}...' : preview,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  subtitle: Text('${s['grading_type']} • $status${score != null ? ' • স্কোর: $score' : ''}'),
                  trailing: status == 'failed'
                      ? TextButton(
                          onPressed: () => _retryEssay(int.parse(s['id'].toString())),
                          child: const Text('রিসেট'),
                        )
                      : status == 'grading'
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.chevron_right),
                  onTap: () => _showResult(s),
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ======================= TAB 2: STUDY SCHEDULE =======================
class _StudyScheduleTab extends StatefulWidget {
  const _StudyScheduleTab();

  @override
  State<_StudyScheduleTab> createState() => _StudyScheduleTabState();
}

class _StudyScheduleTabState extends State<_StudyScheduleTab> {
  final _subjectsCtrl = TextEditingController(text: 'পদার্থবিজ্ঞান, রসায়ন, গণিত, ইংরেজি');
  final _weakCtrl = TextEditingController(text: 'উচ্চতর গণিত');
  DateTime _examDate = DateTime.now().add(const Duration(days: 30));
  int _hoursPerDay = 6;
  String _style = 'balanced';
  bool _includeWeekends = true;

  bool _isLoading = true;
  bool _isGenerating = false;
  List<Map<String, dynamic>> _schedules = [];
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _subjectsCtrl.dispose();
    _weakCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSchedules() async {
    setState(() => _isLoading = true);
    final res = await ApiService.get(ApiEndpoints.schedules);
    if (!mounted) return;
    if (res.success && res.data != null) {
      final raw = res.data is List
          ? res.data as List
          : (res.data is Map && res.data['data'] is List ? res.data['data'] as List : []);
      setState(() {
        _schedules = raw.whereType<Map<String, dynamic>>().toList();
        _isLoading = false;
      });
      _checkPoll();
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _checkPoll() {
    _pollTimer?.cancel();
    if (_schedules.any((s) => s['status'] == 'generating')) {
      _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
        final res = await ApiService.get(ApiEndpoints.schedules);
        if (!mounted) return;
        if (res.success && res.data is List) {
          final list = (res.data as List).whereType<Map<String, dynamic>>().toList();
          setState(() => _schedules = list);
          if (!list.any((s) => s['status'] == 'generating')) {
            _pollTimer?.cancel();
          }
        }
      });
    }
  }

  Future<void> _generate() async {
    final subjects = _subjectsCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('অন্তত একটি বিষয়ের নাম লিখুন।')),
      );
      return;
    }

    final weak = _weakCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final dateStr =
        '${_examDate.year}-${_examDate.month.toString().padLeft(2, '0')}-${_examDate.day.toString().padLeft(2, '0')}';

    setState(() => _isGenerating = true);
    final res = await ApiService.post(
      ApiEndpoints.schedules,
      body: {
        'exam_date': dateStr,
        'subjects': subjects,
        'weak_subjects': weak,
        'hours_per_day': _hoursPerDay,
        'style': _style,
        'include_weekends': _includeWeekends,
      },
    );
    if (!mounted) return;
    setState(() => _isGenerating = false);

    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('এআই রুটিন তৈরি শুরু হয়েছে!'), backgroundColor: SikhunTheme.success),
      );
      _loadSchedules();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? 'রুটিন তৈরি ব্যর্থ হয়েছে'), backgroundColor: SikhunTheme.danger),
      );
    }
  }

  void _showScheduleDetail(Map<String, dynamic> sch) {
    final data = sch['schedule_data'];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        builder: (_, sc) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: sc,
            children: [
              Text('স্টাডি রুটিন (${sch['exam_date']?.toString().split('T').first ?? ''})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(height: 20),
              if (data is Map)
                ...data.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.key.toString(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, color: SikhunTheme.primary)),
                          const SizedBox(height: 4),
                          Text(e.value.toString(), style: const TextStyle(fontSize: 12, height: 1.5)),
                        ],
                      ),
                    ))
              else if (data is List)
                ...data.map((d) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(d.toString(), style: const TextStyle(fontSize: 13)),
                      ),
                    ))
              else
                Text('স্ট্যাটাস: ${sch['status']}'),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadSchedules,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('স্মার্ট এআই রুটিন তৈরি করুন',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event),
                    title: const Text('সম্ভাব্য পরীক্ষার তারিখ'),
                    subtitle: Text(
                      '${_examDate.day}/${_examDate.month}/${_examDate.year}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: const Text('পরিবর্তন'),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _examDate,
                        firstDate: DateTime.now().add(const Duration(days: 1)),
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                      );
                      if (d != null) setState(() => _examDate = d);
                    },
                  ),
                  TextField(
                    controller: _subjectsCtrl,
                    decoration: const InputDecoration(
                      labelText: 'বিষয়সমূহ (কমা দিয়ে লিখুন)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _weakCtrl,
                    decoration: const InputDecoration(
                      labelText: 'দুর্বল বিষয় (যদি থাকে, কমা দিয়ে)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('প্রতিদিন পড়াশোনা:'),
                      Text('$_hoursPerDay ঘন্টা',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: SikhunTheme.primary)),
                    ],
                  ),
                  Slider(
                    value: _hoursPerDay.toDouble(),
                    min: 1,
                    max: 16,
                    divisions: 15,
                    activeColor: SikhunTheme.primary,
                    onChanged: (v) => setState(() => _hoursPerDay = v.round()),
                  ),
                  DropdownButtonFormField<String>(
                    value: _style,
                    decoration: const InputDecoration(labelText: 'রুটিনের ধরন'),
                    items: const [
                      DropdownMenuItem(value: 'balanced', child: Text('ভারসাম্যপূর্ণ (Balanced)')),
                      DropdownMenuItem(value: 'intensive', child: Text('নিবিড় / ক্র্যাশ (Intensive)')),
                      DropdownMenuItem(value: 'relaxed', child: Text('সহজ গতি (Relaxed)')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _style = v);
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('সাপ্তাহিক ছুটির দিন অন্তর্ভুক্ত করুন'),
                    value: _includeWeekends,
                    onChanged: (v) => setState(() => _includeWeekends = v),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _generate,
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.schedule),
                      label: Text(_isGenerating ? 'তৈরি হচ্ছে...' : 'রুটিন তৈরি করুন'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('আপনার তৈরি রুটিনসমূহ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (_schedules.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('এখনো কোনো রুটিন তৈরি করা হয়নি।', textAlign: TextAlign.center),
              ),
            )
          else
            ..._schedules.map((sch) {
              final status = sch['status']?.toString() ?? 'generating';
              final date = sch['exam_date']?.toString().split('T').first ?? '';
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(Icons.calendar_today, color: SikhunTheme.primary),
                  title: Text('পরীক্ষার তারিখ: $date'),
                  subtitle: Text('স্ট্যাটাস: $status'),
                  trailing: status == 'generating'
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.chevron_right),
                  onTap: () => _showScheduleDetail(sch),
                ),
              );
            }),
        ],
      ),
    );
  }
}
