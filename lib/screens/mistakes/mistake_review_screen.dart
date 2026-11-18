import 'package:flutter/material.dart';
import '../../config/api_endpoints.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../exams/exams_screen.dart';

class MistakeReviewScreen extends StatefulWidget {
  const MistakeReviewScreen({super.key});

  @override
  State<MistakeReviewScreen> createState() => _MistakeReviewScreenState();
}

class _MistakeReviewScreenState extends State<MistakeReviewScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  bool _isLoading = true;
  bool _isActionLoading = false;
  String? _error;

  String _status = 'unresolved'; // unresolved | mastered | all
  int? _selectedSubjectId;
  String? _selectedInstitution;

  List<Map<String, dynamic>> _mistakes = [];
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _institutions = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadMistakes();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMistakes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final params = <String, dynamic>{'status': _status};
    if (_selectedSubjectId != null) {
      params['subject_id'] = _selectedSubjectId.toString();
    }
    if (_selectedInstitution != null && _selectedInstitution!.isNotEmpty) {
      params['institution'] = _selectedInstitution!;
    }
    if (_searchCtrl.text.trim().isNotEmpty) {
      params['search'] = _searchCtrl.text.trim();
    }

    final res = await ApiService.get(ApiEndpoints.mistakes, queryParams: params);
    if (!mounted) return;

    if (res.success && res.data is Map<String, dynamic>) {
      final data = res.data as Map<String, dynamic>;
      final rawMistakes = data['mistakes'];
      List<dynamic> items = [];
      if (rawMistakes is Map<String, dynamic> && rawMistakes['data'] is List) {
        items = rawMistakes['data'] as List;
      } else if (rawMistakes is List) {
        items = rawMistakes;
      }

      setState(() {
        _mistakes = items.whereType<Map<String, dynamic>>().toList();
        _subjects = (data['subjects'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
        _institutions = (data['institutions'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
        _stats = (data['stats'] is Map<String, dynamic>)
            ? data['stats'] as Map<String, dynamic>
            : {};
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = res.message ?? 'ভুল প্রশ্নের তথ্য লোড করা যায়নি';
        _isLoading = false;
      });
    }
  }

  Future<void> _startPracticeExam() async {
    setState(() => _isActionLoading = true);
    final body = <String, dynamic>{'limit': 20};
    if (_selectedSubjectId != null) {
      body['subject_id'] = _selectedSubjectId;
    }
    if (_selectedInstitution != null && _selectedInstitution!.isNotEmpty) {
      body['institution'] = _selectedInstitution;
    }

    final res = await ApiService.post(ApiEndpoints.mistakesPractice, body: body);
    if (!mounted) return;
    setState(() => _isActionLoading = false);

    if (res.success && res.data is Map<String, dynamic>) {
      final examId = res.data['id'];
      if (examId != null) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TakeExamScreen(examId: int.parse(examId.toString())),
          ),
        );
        _loadMistakes();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message ?? 'ভুল প্রশ্ন দিয়ে পরীক্ষা তৈরি করা যায়নি'),
          backgroundColor: SikhunTheme.danger,
        ),
      );
    }
  }

  Future<void> _resetMistakes() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ভুল প্রশ্নের তালিকা রিসেট'),
        content: Text(
          _selectedSubjectId != null || _selectedInstitution != null
              ? 'নির্বাচিত ফিল্টার অনুযায়ী ভুল প্রশ্নগুলো তালিকা থেকে মুছে ফেলা হবে। নিশ্চিত?'
              : 'আপনার সকল ভুল প্রশ্ন তালিকা থেকে মুছে ফেলা হবে। এটি আর ফিরিয়ে আনা যাবে না!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: SikhunTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('রিসেট করুন'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _isActionLoading = true);
    final body = <String, dynamic>{};
    if (_selectedSubjectId != null) {
      body['subject_id'] = _selectedSubjectId;
    }
    if (_selectedInstitution != null && _selectedInstitution!.isNotEmpty) {
      body['institution'] = _selectedInstitution;
    }

    final res = await ApiService.post(ApiEndpoints.mistakesReset, body: body);
    if (!mounted) return;
    setState(() => _isActionLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res.message ?? (res.success ? 'ভুল প্রশ্নের তালিকা রিসেট সম্পন্ন' : 'রিসেট ব্যর্থ হয়েছে'),
        ),
        backgroundColor: res.success ? SikhunTheme.success : SikhunTheme.danger,
      ),
    );
    if (res.success) {
      _loadMistakes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalMistakes = _stats['total_mistakes'] ?? 0;
    final masteredCount = _stats['mastered_count'] ?? 0;
    final accuracy = _stats['accuracy'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ভুল প্রশ্নের খাতা (Mistake Review)'),
        actions: [
          if (_mistakes.isNotEmpty || _stats['total_mistakes'] != 0)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'তালিকা রিসেট',
              onPressed: _isActionLoading ? null : _resetMistakes,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMistakes,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Stats Row
            Row(
              children: [
                _statCard('মোট ভুল', '$totalMistakes', Colors.redAccent),
                const SizedBox(width: 8),
                _statCard('সমাধান হয়েছে', '$masteredCount', SikhunTheme.success),
                const SizedBox(width: 8),
                _statCard('সঠিকতার হার', '$accuracy%', SikhunTheme.primary),
              ],
            ),
            const SizedBox(height: 14),

            // Practice CTA Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [SikhunTheme.primary, SikhunTheme.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_fix_high, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ভুলগুলো ঝালিয়ে নিন',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'আপনার ভুল করা প্রশ্নগুলো দিয়ে তাৎক্ষণিক রিভিশন পরীক্ষা দিন',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isActionLoading ? null : _startPracticeExam,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: SikhunTheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    child: _isActionLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('অনুশীলন', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Search bar
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'ভুল প্রশ্ন বা পরীক্ষার নাম খুঁজুন...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _loadMistakes();
                        },
                      )
                    : null,
              ),
              onSubmitted: (_) => _loadMistakes(),
            ),
            const SizedBox(height: 12),

            // Status filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _statusChip('unresolved', 'ভুল থাকা প্রশ্ন'),
                  const SizedBox(width: 8),
                  _statusChip('mastered', 'আয়ত্ত করা প্রশ্ন'),
                  const SizedBox(width: 8),
                  _statusChip('all', 'সকল'),
                ],
              ),
            ),

            if (_subjects.isNotEmpty) ...[
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('সকল বিষয়'),
                      selected: _selectedSubjectId == null,
                      onSelected: (_) {
                        setState(() => _selectedSubjectId = null);
                        _loadMistakes();
                      },
                    ),
                    ..._subjects.map((s) {
                      final sid = int.tryParse(s['subject_id']?.toString() ?? '');
                      final label = '${s['subject_name']} (${s['mistakes_count'] ?? 0})';
                      return Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: FilterChip(
                          label: Text(label, style: const TextStyle(fontSize: 12)),
                          selected: sid != null && _selectedSubjectId == sid,
                          onSelected: (_) {
                            setState(() => _selectedSubjectId = sid);
                            _loadMistakes();
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],

            if (_institutions.isNotEmpty) ...[
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('সকল প্রতিষ্ঠান'),
                      selected: _selectedInstitution == null,
                      onSelected: (_) {
                        setState(() => _selectedInstitution = null);
                        _loadMistakes();
                      },
                    ),
                    ..._institutions.map((inst) {
                      final name = inst['institution']?.toString() ?? '';
                      if (name.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: FilterChip(
                          label: Text('$name (${inst['mistakes_count'] ?? 0})',
                              style: const TextStyle(fontSize: 12)),
                          selected: _selectedInstitution == name,
                          onSelected: (_) {
                            setState(() => _selectedInstitution = name);
                            _loadMistakes();
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, size: 42, color: Colors.red),
                    const SizedBox(height: 8),
                    Text(_error!),
                    const SizedBox(height: 8),
                    ElevatedButton(onPressed: _loadMistakes, child: const Text('আবার চেষ্টা করুন')),
                  ],
                ),
              )
            else if (_mistakes.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.withAlpha(40)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 54, color: SikhunTheme.success),
                    const SizedBox(height: 12),
                    const Text(
                      'দারুণ! কোনো ভুল প্রশ্ন পাওয়া যায়নি।',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'মডেল টেস্ট দিলে আপনার ভুল প্রশ্নগুলো এখানে সংরক্ষিত থাকবে যেন সহজেই অনুশীলন করতে পারেন।',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ..._mistakes.map((m) => _buildMistakeCard(m)),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          children: [
            Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String value, String label) {
    final selected = _status == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: SikhunTheme.primary,
      labelStyle: TextStyle(
        color: selected ? Colors.white : null,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (_) {
        setState(() => _status = value);
        _loadMistakes();
      },
    );
  }

  Widget _buildMistakeCard(Map<String, dynamic> m) {
    final question = m['question_text']?.toString() ?? 'প্রশ্ন';
    final given = m['given_answer']?.toString() ?? '';
    final correct = m['correct_answer']?.toString() ?? '';
    final subject = m['subject_name']?.toString();
    final inst = m['institution']?.toString() ?? m['origin_tag']?.toString();
    final explanation = m['explanation']?.toString();
    final isCorrect = m['is_correct'] == true || m['is_correct'] == 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (subject != null && subject.isNotEmpty)
                  _badge(subject, SikhunTheme.primary),
                if (inst != null && inst.isNotEmpty)
                  _badge(inst, SikhunTheme.accent),
                _badge(
                  isCorrect ? 'সমাধান হয়েছে' : 'ভুল উত্তর',
                  isCorrect ? SikhunTheme.success : SikhunTheme.danger,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              question,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, height: 1.45),
            ),
            const SizedBox(height: 10),
            if (given.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: SikhunTheme.danger.withAlpha(18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: SikhunTheme.danger.withAlpha(60)),
                ),
                child: Text(
                  'আপনার উত্তর: $given',
                  style: const TextStyle(fontSize: 12, color: SikhunTheme.danger, fontWeight: FontWeight.w500),
                ),
              ),
            if (correct.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: SikhunTheme.success.withAlpha(18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: SikhunTheme.success.withAlpha(60)),
                ),
                child: Text(
                  'সঠিক উত্তর: $correct',
                  style: const TextStyle(fontSize: 12, color: SikhunTheme.success, fontWeight: FontWeight.bold),
                ),
              ),
            if (explanation != null && explanation.isNotEmpty) ...[
              const SizedBox(height: 8),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('ব্যাখ্যা দেখুন', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(explanation, style: const TextStyle(fontSize: 12, height: 1.5)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
