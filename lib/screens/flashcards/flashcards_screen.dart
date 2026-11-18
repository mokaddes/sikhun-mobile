import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/api_endpoints.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _sets = [];

  @override
  void initState() {
    super.initState();
    _fetchSets();
  }

  Future<void> _fetchSets() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      setState(() => _loading = false);
      return;
    }

    setState(() => _loading = true);
    final res = await ApiService.get(ApiEndpoints.flashcards);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success && res.data is List) {
        _sets = (res.data as List).whereType<Map<String, dynamic>>().toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('এআই ফ্ল্যাশকার্ড')),
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen())).then((_) => _fetchSets()),
            style: ElevatedButton.styleFrom(backgroundColor: SikhunTheme.primary, foregroundColor: Colors.white),
            child: const Text('ফ্ল্যাশকার্ড দেখতে লগইন করুন'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('এআই ফ্ল্যাশকার্ড'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchSets)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<Map<String, dynamic>>(
            MaterialPageRoute(builder: (_) => const CreateFlashcardSetScreen()),
          );
          if (created != null && mounted) {
            final id = created['id'] is int ? created['id'] : int.tryParse(created['id'].toString()) ?? 0;
            if (id > 0) {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => FlashcardStudyScreen(setId: id)),
              );
              _fetchSets();
            }
          }
        },
        backgroundColor: SikhunTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('নতুন সেট'),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchSets,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _sets.isEmpty
                ? const Center(child: Text('এখনো কোনো ফ্ল্যাশকার্ড সেট নেই।'))
                : ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: _sets.length,
                    itemBuilder: (ctx, i) {
                      final s = _sets[i];
                      final id = s['id'] is int ? s['id'] : int.tryParse(s['id'].toString()) ?? 0;
                      final title = (s['title'] ?? 'ফ্ল্যাশকার্ড সেট').toString();
                      final count = s['flashcards_count'] ?? 0;
                      final status = (s['generation_status'] ?? 'completed').toString();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0x208A5A32),
                            child: Icon(Icons.style, color: SikhunTheme.primary),
                          ),
                          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text('$count টি কার্ড • $status', style: const TextStyle(fontSize: 12)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: SikhunTheme.danger),
                            onPressed: () async {
                              await ApiService.delete(ApiEndpoints.flashcardDetails(id));
                              _fetchSets();
                            },
                          ),
                          onTap: () {
                            Navigator.of(context)
                                .push(MaterialPageRoute(builder: (_) => FlashcardStudyScreen(setId: id)))
                                .then((_) => _fetchSets());
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

class CreateFlashcardSetScreen extends StatefulWidget {
  const CreateFlashcardSetScreen({super.key});

  @override
  State<CreateFlashcardSetScreen> createState() => _CreateFlashcardSetScreenState();
}

class _CreateFlashcardSetScreenState extends State<CreateFlashcardSetScreen> {
  final _titleCtrl = TextEditingController();
  final _topicCtrl = TextEditingController();
  final _textCtrl = TextEditingController();

  bool _loadingData = true;
  bool _submitting = false;
  bool _canUseQuestionBank = false;
  String _sourceType = 'topic';
  int _count = 15;

  List<Map<String, dynamic>> _books = [];
  List<Map<String, dynamic>> _myBooks = [];
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _exams = [];

  String _selectedBookKey = '';
  int? _sourceBookId;
  int? _sourceMyBookId;
  int? _subjectId;
  String? _originTag;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _topicCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final res = await ApiService.get(ApiEndpoints.flashcardsCreateData);
    if (!mounted) return;
    setState(() {
      _loadingData = false;
      if (res.success && res.data is Map) {
        final d = res.data as Map<String, dynamic>;
        _canUseQuestionBank = d['can_use_question_bank'] == true;
        _books = (d['books'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
        _myBooks = (d['my_books'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
        _subjects = (d['subjects'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
        _exams = (d['exams'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
      }
    });
  }

  Future<void> _submit() async {
    String title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      if (_sourceType == 'topic' && _topicCtrl.text.trim().isNotEmpty) {
        title = '${_topicCtrl.text.trim()} ফ্ল্যাশকার্ড';
      } else {
        title = 'স্মার্ট রিভিশন ফ্ল্যাশকার্ড';
      }
    }

    setState(() => _submitting = true);
    final res = await ApiService.post(
      ApiEndpoints.flashcards,
      body: {
        'title': title,
        'source_type': _sourceType,
        if (_sourceType == 'topic') 'source_topic': _topicCtrl.text.trim(),
        if (_sourceType == 'paragraph') 'source_text': _textCtrl.text.trim(),
        if (_sourceBookId != null) 'source_book_id': _sourceBookId,
        if (_sourceMyBookId != null) 'source_my_book_id': _sourceMyBookId,
        if (_subjectId != null) 'subject_id': _subjectId,
        if (_originTag != null) 'origin_tag': _originTag,
        'count': _count,
      },
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (res.success && res.data is Map<String, dynamic>) {
      Navigator.of(context).pop(res.data as Map<String, dynamic>);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? 'ফ্ল্যাশকার্ড তৈরি করা যায়নি।')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('নতুন ফ্ল্যাশকার্ড সেট')),
      body: _loadingData
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
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
                      label: const Text('অনুচ্ছেদ / নোট'),
                      selected: _sourceType == 'paragraph',
                      onSelected: (_) => setState(() => _sourceType = 'paragraph'),
                    ),
                    ChoiceChip(
                      label: const Text('বই'),
                      selected: _sourceType == 'book',
                      onSelected: (_books.isNotEmpty || _myBooks.isNotEmpty)
                          ? (_) => setState(() => _sourceType = 'book')
                          : null,
                    ),
                    // Hide Question Bank source for SSC, HSC & University students (mirrors web FlashcardController)
                    if (_canUseQuestionBank)
                      ChoiceChip(
                        label: const Text('প্রশ্নব্যাংক'),
                        selected: _sourceType == 'question_bank',
                        onSelected: (_) => setState(() => _sourceType = 'question_bank'),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                if (_sourceType == 'topic')
                  TextField(
                    controller: _topicCtrl,
                    decoration: const InputDecoration(labelText: 'টপিক বা বিষয়ের নাম'),
                  )
                else if (_sourceType == 'paragraph')
                  TextField(
                    controller: _textCtrl,
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: 'নোট বা অনুচ্ছেদ পেস্ট করুন'),
                  )
                else if (_sourceType == 'book')
                  DropdownButtonFormField<String>(
                    initialValue: _selectedBookKey.isEmpty ? null : _selectedBookKey,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'বুকশেল্ফ বা নিজস্ব বই'),
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
                        if (val != null && val.startsWith('my:')) {
                          _sourceMyBookId = int.tryParse(val.substring(3));
                          _sourceBookId = null;
                        } else if (val != null && val.startsWith('book:')) {
                          _sourceBookId = int.tryParse(val.substring(5));
                          _sourceMyBookId = null;
                        }
                      });
                    },
                  )
                else if (_sourceType == 'question_bank') ...[
                  DropdownButtonFormField<int>(
                    initialValue: _subjectId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'বিষয় নির্বাচন করুন'),
                    items: _subjects
                        .map((s) => DropdownMenuItem<int>(
                              value: s['id'] is int ? s['id'] : int.tryParse(s['id'].toString()),
                              child: Text((s['name_bn'] ?? s['name_en'] ?? '').toString()),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _subjectId = v),
                  ),
                  const SizedBox(height: 12),
                  if (_exams.isNotEmpty)
                    DropdownButtonFormField<String>(
                      initialValue: _originTag,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'পরীক্ষা (ঐচ্ছিক)'),
                      items: _exams
                          .map((e) => DropdownMenuItem<String>(
                                value: (e['origin_tag'] ?? '').toString(),
                                child: Text((e['exam_name'] ?? e['origin_tag'] ?? '').toString()),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _originTag = v),
                    ),
                ],
                const SizedBox(height: 14),
                TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'সেটের নাম (ঐচ্ছিক)'),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  initialValue: _count,
                  decoration: const InputDecoration(labelText: 'কার্ড সংখ্যা'),
                  items: [5, 10, 15, 20, 25, 30]
                      .map((c) => DropdownMenuItem(value: c, child: Text('$c টি কার্ড')))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _count = v);
                  },
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
                      : const Text('ফ্ল্যাশকার্ড তৈরি করুন', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
    );
  }
}

class FlashcardStudyScreen extends StatefulWidget {
  final int setId;

  const FlashcardStudyScreen({super.key, required this.setId});

  @override
  State<FlashcardStudyScreen> createState() => _FlashcardStudyScreenState();
}

class _FlashcardStudyScreenState extends State<FlashcardStudyScreen> {
  bool _loading = true;
  Map<String, dynamic>? _set;
  int _index = 0;
  bool _showBack = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadSet();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSet() async {
    final res = await ApiService.get(ApiEndpoints.flashcardDetails(widget.setId));
    if (!mounted) return;
    if (res.success && res.data is Map<String, dynamic>) {
      final s = res.data as Map<String, dynamic>;
      setState(() {
        _set = s;
        _loading = false;
      });
      if (s['generation_status'] == 'generating') {
        _pollTimer?.cancel();
        _pollTimer = Timer(const Duration(seconds: 3), _loadSet);
      }
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _review(int cardId, String result) async {
    await ApiService.post(ApiEndpoints.flashcardReview(widget.setId, cardId), body: {'result': result});
    final cards = (_set?['flashcards'] as List? ?? []);
    if (mounted) {
      setState(() {
        _showBack = false;
        if (_index + 1 < cards.length) {
          _index++;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('সব কার্ড রিভিশন সম্পন্ন হয়েছে!')),
          );
          _index = 0;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = (_set?['flashcards'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
    final status = _set?['generation_status']?.toString() ?? 'completed';

    return Scaffold(
      appBar: AppBar(title: Text((_set?['title'] ?? 'ফ্ল্যাশকার্ড').toString())),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : status == 'generating'
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('AI ফ্ল্যাশকার্ড তৈরি করছে...'),
                    ],
                  ),
                )
              : status == 'failed'
                  ? Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          await ApiService.post(ApiEndpoints.flashcardRetry(widget.setId));
                          _loadSet();
                        },
                        child: const Text('আবার চেষ্টা করুন'),
                      ),
                    )
                  : cards.isEmpty
                      ? const Center(child: Text('কোনো কার্ড পাওয়া যায়নি।'))
                      : Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Text(
                                'কার্ড ${_index + 1} / ${cards.length}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: SikhunTheme.mutedDark),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(24),
                                  onTap: () => setState(() => _showBack = !_showBack),
                                  child: Card(
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            _showBack ? 'উত্তর / ব্যাখ্যা' : 'প্রশ্ন / টার্ম',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: SikhunTheme.primary,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            (_showBack
                                                    ? (cards[_index]['back_text'] ?? cards[_index]['back'] ?? '')
                                                    : (cards[_index]['front_text'] ?? cards[_index]['front'] ?? ''))
                                                .toString(),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1.5),
                                          ),
                                          const SizedBox(height: 24),
                                          const Text(
                                            'কার্ড উল্টাতে ট্যাপ করুন',
                                            style: TextStyle(fontSize: 12, color: SikhunTheme.mutedDark),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        final cid = int.tryParse(cards[_index]['id'].toString()) ?? 0;
                                        _review(cid, 'review_again');
                                      },
                                      child: const Text('আবার পড়ব'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        final cid = int.tryParse(cards[_index]['id'].toString()) ?? 0;
                                        _review(cid, 'known');
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: SikhunTheme.success,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('মনে আছে'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
    );
  }
}
