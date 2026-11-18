import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/api_endpoints.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';

class ExamsScreen extends StatefulWidget {
  const ExamsScreen({super.key});

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _exams = [];

  @override
  void initState() {
    super.initState();
    _fetchExams();
  }

  Future<void> _fetchExams() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    final res = await ApiService.get(ApiEndpoints.exams);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (res.success && res.data is List) {
        _exams = (res.data as List).whereType<Map<String, dynamic>>().toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('এআই পরীক্ষা ও মডেল টেস্ট')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.assignment_outlined, size: 64, color: SikhunTheme.primary),
                const SizedBox(height: 12),
                const Text('পরীক্ষা দিতে ও ফলাফল সংরক্ষণ করতে লগইন করুন।', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen())).then((_) => _fetchExams()),
                  style: ElevatedButton.styleFrom(backgroundColor: SikhunTheme.primary, foregroundColor: Colors.white),
                  child: const Text('লগইন করুন'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('এআই পরীক্ষা ও মডেল টেস্ট'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchExams),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<Map<String, dynamic>>(
            MaterialPageRoute(builder: (_) => const CreateExamScreen()),
          );
          if (created != null && mounted) {
            final id = created['id'] is int ? created['id'] : int.tryParse(created['id'].toString()) ?? 0;
            if (id > 0) {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => TakeExamScreen(examId: id)),
              );
              _fetchExams();
            }
          }
        },
        backgroundColor: SikhunTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('নতুন পরীক্ষা'),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchExams,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _exams.isEmpty
                ? const Center(child: Text('এখনো কোনো পরীক্ষা নেই। নিচের বাটনে ক্লিক করে পরীক্ষা তৈরি করুন।'))
                : ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: _exams.length,
                    itemBuilder: (ctx, i) {
                      final ex = _exams[i];
                      final id = ex['id'] is int ? ex['id'] : int.tryParse(ex['id'].toString()) ?? 0;
                      final title = (ex['title'] ?? ex['config']?['title'] ?? 'এআই পরীক্ষা #$id').toString();
                      final status = (ex['status'] ?? 'pending').toString();
                      final score = ex['score'] ?? 0;
                      final total = ex['total'] ?? 0;
                      final mode = (ex['mode'] ?? 'practice').toString();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: status == 'completed'
                                ? SikhunTheme.success.withAlpha(25)
                                : SikhunTheme.primary.withAlpha(25),
                            child: Icon(
                              status == 'completed' ? Icons.check_circle : Icons.assignment,
                              color: status == 'completed' ? SikhunTheme.success : SikhunTheme.primary,
                            ),
                          ),
                          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(
                            status == 'completed'
                                ? 'ফলাফল: $score / $total (${ex['percentage'] ?? 0}%) • $mode'
                                : 'মোট প্রশ্ন: $total • স্ট্যাটাস: $status',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: status == 'failed'
                              ? TextButton(
                                  onPressed: () async {
                                    await ApiService.post(ApiEndpoints.examRetry(id));
                                    _fetchExams();
                                  },
                                  child: const Text('রিট্রাই'),
                                )
                              : const Icon(Icons.arrow_forward_ios, size: 14),
                          onTap: () {
                            Navigator.of(context)
                                .push(MaterialPageRoute(builder: (_) => TakeExamScreen(examId: id)))
                                .then((_) => _fetchExams());
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

class CreateExamScreen extends StatefulWidget {
  const CreateExamScreen({super.key});

  @override
  State<CreateExamScreen> createState() => _CreateExamScreenState();
}

class _CreateExamScreenState extends State<CreateExamScreen> {
  final _titleCtrl = TextEditingController();
  final _sourceTextCtrl = TextEditingController();
  String _sourceType = 'topic';
  String _selectedBookKey = '';
  int? _sourceBookId;
  int? _sourceMyBookId;
  final Set<int> _selectedChapterIds = {};
  String _questionType = 'mcq';
  int _count = 10;
  int _duration = 20;
  String _mode = 'practice';
  bool _loadingCreateData = true;
  bool _submitting = false;

  List<Map<String, dynamic>> _books = [];
  List<Map<String, dynamic>> _myBooks = [];

  @override
  void initState() {
    super.initState();
    _loadCreateData();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _sourceTextCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCreateData() async {
    final res = await ApiService.get(ApiEndpoints.examsCreateData);
    if (!mounted) return;
    setState(() {
      _loadingCreateData = false;
      if (res.success && res.data is Map) {
        _books = (res.data['books'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
        _myBooks = (res.data['my_books'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
      }
    });
  }

  List<Map<String, dynamic>> get _selectedChapters {
    if (_sourceBookId == null) return [];
    final book = _books.firstWhere((b) => b['id'] == _sourceBookId, orElse: () => {});
    return (book['chapters'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
  }

  Future<void> _submit() async {
    if (_sourceType != 'book' && _sourceTextCtrl.text.trim().length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('অনুগ্রহ করে টপিক বা অনুচ্ছেদ লিখুন।')),
      );
      return;
    }
    if (_sourceType == 'book' && _sourceBookId == null && _sourceMyBookId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('বুকশেল্ফ বা নিজের আপলোড করা বই নির্বাচন করুন।')),
      );
      return;
    }

    setState(() => _submitting = true);
    final res = await ApiService.post(
      ApiEndpoints.exams,
      body: {
        if (_titleCtrl.text.trim().isNotEmpty) 'title': _titleCtrl.text.trim(),
        'source_type': _sourceType,
        if (_sourceBookId != null) 'source_book_id': _sourceBookId,
        if (_sourceMyBookId != null) 'source_my_book_id': _sourceMyBookId,
        if (_selectedChapterIds.isNotEmpty) 'chapter_ids': _selectedChapterIds.toList(),
        if (_sourceType != 'book') 'source_text': _sourceTextCtrl.text.trim(),
        'type': _questionType,
        'count': _count,
        'duration': _duration,
        'mode': _mode,
      },
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (res.success && res.data is Map<String, dynamic>) {
      Navigator.of(context).pop(res.data as Map<String, dynamic>);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? 'পরীক্ষা তৈরি করা যায়নি।')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAnyBook = _books.isNotEmpty || _myBooks.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('নতুন এআই পরীক্ষা তৈরি করুন')),
      body: _loadingCreateData
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'পরীক্ষার নাম (ঐচ্ছিক)'),
                ),
                const SizedBox(height: 16),
                const Text('উৎস নির্বাচন করুন', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('টপিক'),
                      selected: _sourceType == 'topic',
                      onSelected: (_) => setState(() => _sourceType = 'topic'),
                    ),
                    ChoiceChip(
                      label: const Text('অনুচ্ছেদ'),
                      selected: _sourceType == 'paragraph',
                      onSelected: (_) => setState(() => _sourceType = 'paragraph'),
                    ),
                    ChoiceChip(
                      label: const Text('বই ও অধ্যায়'),
                      selected: _sourceType == 'book',
                      onSelected: hasAnyBook ? (_) => setState(() => _sourceType = 'book') : null,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_sourceType == 'book') ...[
                  DropdownButtonFormField<String>(
                    initialValue: _selectedBookKey.isEmpty ? null : _selectedBookKey,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'বুকশেল্ফ বা নিজস্ব বই নির্বাচন করুন'),
                    items: [
                      ..._books.map((b) => DropdownMenuItem(
                            value: 'book:${b['id']}',
                            child: Text('বুকশেল্ফ: ${b['title']}', overflow: TextOverflow.ellipsis),
                          )),
                      ..._myBooks.map((mb) => DropdownMenuItem(
                            value: 'my:${mb['id']}',
                            child: Text('আমার বই: ${mb['title']}', overflow: TextOverflow.ellipsis),
                          )),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedBookKey = val ?? '';
                        _selectedChapterIds.clear();
                        if (val != null && val.startsWith('my:')) {
                          _sourceMyBookId = int.tryParse(val.substring(3));
                          _sourceBookId = null;
                        } else if (val != null && val.startsWith('book:')) {
                          _sourceBookId = int.tryParse(val.substring(5));
                          _sourceMyBookId = null;
                        }
                      });
                    },
                  ),
                  if (_selectedChapters.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('অধ্যায় (ঐচ্ছিক)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: _selectedChapters.map((ch) {
                        final cid = ch['id'] is int ? ch['id'] : int.tryParse(ch['id'].toString()) ?? 0;
                        final sel = _selectedChapterIds.contains(cid);
                        return FilterChip(
                          label: Text((ch['title'] ?? '').toString(), style: const TextStyle(fontSize: 11.5)),
                          selected: sel,
                          onSelected: (v) {
                            setState(() {
                              if (v) {
                                _selectedChapterIds.add(cid);
                              } else {
                                _selectedChapterIds.remove(cid);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ] else
                  TextField(
                    controller: _sourceTextCtrl,
                    maxLines: _sourceType == 'paragraph' ? 5 : 2,
                    decoration: InputDecoration(
                      labelText: _sourceType == 'topic' ? 'টপিকের নাম লিখুন' : 'অনুচ্ছেদ বা নোট পেস্ট করুন',
                    ),
                  ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _questionType,
                  decoration: const InputDecoration(labelText: 'প্রশ্নের ধরন'),
                  items: const [
                    DropdownMenuItem(value: 'mcq', child: Text('বহুনির্বাচনী (MCQ)')),
                    DropdownMenuItem(value: 'true_false', child: Text('সত্য / মিথ্যা')),
                    DropdownMenuItem(value: 'short', child: Text('সংক্ষিপ্ত উত্তর')),
                    DropdownMenuItem(value: 'fill_blank', child: Text('শূন্যস্থান পূরণ')),
                    DropdownMenuItem(value: 'cq', child: Text('সৃজনশীল প্রশ্ন (CQ)')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _questionType = v);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _count,
                        decoration: const InputDecoration(labelText: 'প্রশ্ন সংখ্যা'),
                        items: [5, 10, 15, 20, 30, 50]
                            .map((c) => DropdownMenuItem(value: c, child: Text('$c টি')))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _count = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _duration,
                        decoration: const InputDecoration(labelText: 'সময় (মিনিট)'),
                        items: [0, 10, 15, 20, 30, 45, 60]
                            .map((d) => DropdownMenuItem(value: d, child: Text(d == 0 ? 'সময়সীমা নেই' : '$d মিনিট')))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _duration = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('অনুশীলন (Practice)'),
                        selected: _mode == 'practice',
                        onSelected: (_) => setState(() => _mode = 'practice'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('পরীক্ষা (Timed Exam)'),
                        selected: _mode == 'exam',
                        onSelected: (_) => setState(() => _mode = 'exam'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SikhunTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('পরীক্ষা শুরু করুন', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ],
            ),
    );
  }
}

class TakeExamScreen extends StatefulWidget {
  final int examId;

  const TakeExamScreen({super.key, required this.examId});

  @override
  State<TakeExamScreen> createState() => _TakeExamScreenState();
}

class _TakeExamScreenState extends State<TakeExamScreen> {
  bool _loading = true;
  bool _submitting = false;
  Map<String, dynamic>? _exam;
  final Map<String, String> _selectedAnswers = {};
  final Map<int, String> _explanations = {};
  final Set<int> _explainingIds = {};
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadExam();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadExam() async {
    final res = await ApiService.get(ApiEndpoints.examDetails(widget.examId));
    if (!mounted) return;
    if (res.success && res.data is Map<String, dynamic>) {
      final ex = res.data as Map<String, dynamic>;
      setState(() {
        _exam = ex;
        _loading = false;
      });
      if (ex['status'] == 'generating') {
        _pollTimer?.cancel();
        _pollTimer = Timer(const Duration(seconds: 3), _loadExam);
      }
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _submitExam() async {
    setState(() => _submitting = true);
    final res = await ApiService.post(
      ApiEndpoints.examComplete(widget.examId),
      body: {'answers': _selectedAnswers},
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res.success && res.data is Map<String, dynamic>) {
      setState(() => _exam = res.data as Map<String, dynamic>);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('পরীক্ষা সম্পন্ন হয়েছে!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? 'উত্তর জমা দেওয়া যায়নি।')),
      );
    }
  }

  Future<void> _explainQuestion(int qId) async {
    setState(() => _explainingIds.add(qId));
    final res = await ApiService.post(ApiEndpoints.examQuestionExplanation(widget.examId, qId));
    if (!mounted) return;
    setState(() {
      _explainingIds.remove(qId);
      if (res.success && res.data is Map && res.data['explanation'] != null) {
        _explanations[qId] = res.data['explanation'].toString();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ex = _exam;
    final status = ex?['status']?.toString() ?? 'loading';
    final questions = (ex?['questions'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
    final isCompleted = status == 'completed';

    return Scaffold(
      appBar: AppBar(
        title: Text((ex?['title'] ?? 'পরীক্ষা #${widget.examId}').toString()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : status == 'generating'
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      const Text('AI আপনার প্রশ্নপত্র তৈরি করছে...', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      const Text('কয়েক সেকেন্ড অপেক্ষা করুন', style: TextStyle(color: SikhunTheme.mutedDark)),
                    ],
                  ),
                )
              : status == 'failed'
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('প্রশ্ন তৈরি করতে সমস্যা হয়েছে।'),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () async {
                              await ApiService.post(ApiEndpoints.examRetry(widget.examId));
                              _loadExam();
                            },
                            child: const Text('আবার চেষ্টা করুন'),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        if (isCompleted)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.all(14),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: SikhunTheme.success.withAlpha(20),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: SikhunTheme.success.withAlpha(70)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'স্কোর: ${ex?['score'] ?? 0} / ${ex?['total'] ?? questions.length}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                                ),
                                Text(
                                  '${ex?['percentage'] ?? 0}%',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: SikhunTheme.success),
                                ),
                              ],
                            ),
                          ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(14),
                            itemCount: questions.length,
                            itemBuilder: (ctx, i) {
                              final q = questions[i];
                              final qId = q['id'] is int ? q['id'] : int.tryParse(q['id'].toString()) ?? (i + 1);
                              final opts = (q['options'] as List? ?? []).map((e) => e.toString()).toList();
                              final savedAns = isCompleted
                                  ? (ex?['answers']?[qId.toString()]?.toString())
                                  : _selectedAnswers[qId.toString()];
                              final correctAns = q['correct_answer']?.toString();
                              final explanation = _explanations[qId] ?? q['explanation']?.toString();

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${i + 1}. ${(q['question'] ?? q['question_text'] ?? '').toString()}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                                      ),
                                      const SizedBox(height: 10),
                                      if (opts.isNotEmpty)
                                        ...opts.map((opt) {
                                          final isSelected = savedAns == opt;
                                          final isCorrect = isCompleted && correctAns != null && opt.trim() == correctAns.trim();
                                          final isWrong = isCompleted && isSelected && !isCorrect;
                                          return InkWell(
                                            onTap: isCompleted
                                                ? null
                                                : () => setState(() => _selectedAnswers[qId.toString()] = opt),
                                            child: Container(
                                              width: double.infinity,
                                              margin: const EdgeInsets.only(bottom: 6),
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(8),
                                                color: isCorrect
                                                    ? SikhunTheme.success.withAlpha(25)
                                                    : (isWrong
                                                        ? SikhunTheme.danger.withAlpha(25)
                                                        : (isSelected ? SikhunTheme.primary.withAlpha(25) : null)),
                                                border: Border.all(
                                                  color: isCorrect
                                                      ? SikhunTheme.success
                                                      : (isWrong
                                                          ? SikhunTheme.danger
                                                          : (isSelected ? SikhunTheme.primary : Theme.of(context).dividerColor)),
                                                ),
                                              ),
                                              child: Text(opt, style: const TextStyle(fontSize: 13)),
                                            ),
                                          );
                                        })
                                      else if (!isCompleted)
                                        TextField(
                                          decoration: const InputDecoration(labelText: 'আপনার উত্তর লিখুন'),
                                          onChanged: (v) => _selectedAnswers[qId.toString()] = v,
                                        )
                                      else if (savedAns != null)
                                        Text('আপনার উত্তর: $savedAns', style: const TextStyle(fontSize: 13)),
                                      if (isCompleted) ...[
                                        if (correctAns != null && correctAns.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 6),
                                            child: Text(
                                              'সঠিক উত্তর: $correctAns',
                                              style: const TextStyle(color: SikhunTheme.success, fontWeight: FontWeight.bold, fontSize: 12.5),
                                            ),
                                          ),
                                        if (explanation != null && explanation.isNotEmpty)
                                          Container(
                                            margin: const EdgeInsets.only(top: 8),
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: SikhunTheme.warning.withAlpha(20),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(explanation, style: const TextStyle(fontSize: 12.5)),
                                          )
                                        else
                                          TextButton.icon(
                                            onPressed: _explainingIds.contains(qId) ? null : () => _explainQuestion(qId),
                                            icon: _explainingIds.contains(qId)
                                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                                : const Icon(Icons.auto_awesome, size: 16),
                                            label: const Text('AI ব্যাখ্যা দেখুন'),
                                          ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (!isCompleted && questions.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: SafeArea(
                              top: false,
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _submitting ? null : _submitExam,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: SikhunTheme.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  child: _submitting
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Text('উত্তর জমা দিন', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
    );
  }
}
