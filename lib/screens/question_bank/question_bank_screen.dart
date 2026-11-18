import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/question_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/question_bank_provider.dart';
import '../auth/login_screen.dart';
import '../exams/exams_screen.dart';
import '../flashcards/flashcards_screen.dart';
import '../mistakes/mistake_review_screen.dart';
import '../plans/plans_screen.dart';
import '../profile/profile_screen.dart';

class QuestionBankScreen extends StatefulWidget {
  const QuestionBankScreen({super.key});

  @override
  State<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<QuestionBankScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Map<int, int> _selectedAnswers = {};
  final Set<int> _revealedAnswers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuestionBankProvider>().init();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openCustomMockTestDialog(QuestionBankProvider qb) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    int count = 20;
    int duration = 20;
    bool negativeMarking = true;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('কাস্টম মক টেস্ট তৈরি'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('প্রশ্ন সংখ্যা:'),
                  DropdownButton<int>(
                    value: count,
                    items: const [
                      DropdownMenuItem(value: 10, child: Text('১০ টি')),
                      DropdownMenuItem(value: 20, child: Text('২০ টি')),
                      DropdownMenuItem(value: 30, child: Text('৩০ টি')),
                      DropdownMenuItem(value: 50, child: Text('৫০ টি')),
                    ],
                    onChanged: (v) {
                      if (v != null) setS(() => count = v);
                    },
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('সময় (মিনিট):'),
                  DropdownButton<int>(
                    value: duration,
                    items: const [
                      DropdownMenuItem(value: 10, child: Text('১০ মিনিট')),
                      DropdownMenuItem(value: 20, child: Text('২০ মিনিট')),
                      DropdownMenuItem(value: 30, child: Text('৩০ মিনিট')),
                      DropdownMenuItem(value: 45, child: Text('৪৫ মিনিট')),
                    ],
                    onChanged: (v) {
                      if (v != null) setS(() => duration = v);
                    },
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('নেগেটিভ মার্কিং (০.২৫)', style: TextStyle(fontSize: 13)),
                value: negativeMarking,
                onChanged: (v) => setS(() => negativeMarking = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final res = await qb.generateCustomTest(
                  subjectId: qb.selectedSubjectId,
                  originTag: qb.selectedOriginTag,
                  questionCount: count,
                  durationMinutes: duration,
                  negativeMarking: negativeMarking,
                );
                if (!mounted) return;
                if (res.success && res.data is Map && res.data['id'] != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TakeExamScreen(
                        examId: int.parse(res.data['id'].toString()),
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res.message ?? 'মক টেস্ট তৈরি করা যায়নি'),
                      backgroundColor: SikhunTheme.danger,
                    ),
                  );
                }
              },
              child: const Text('শুরু করুন'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final qb = context.watch<QuestionBankProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    // Web condition: SSC / HSC / University students cannot view question bank
    final blockedByRole = user != null && !user.canAccessQuestionBank;
    if (blockedByRole || qb.isUnavailable) {
      final goalLabel = user?.typeLabelBn ?? qb.studentGoal ?? 'একাডেমিক';
      return Scaffold(
        appBar: AppBar(title: const Text('প্রশ্নব্যাংক')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: SikhunTheme.warning.withAlpha(18),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: SikhunTheme.warning.withAlpha(90)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_clock_outlined, size: 56, color: SikhunTheme.warning),
                  const SizedBox(height: 16),
                  Text(
                    '$goalLabel প্রশ্নব্যাংক এখনো চালু হয়নি',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'বর্তমানে শুধুমাত্র বিশ্ববিদ্যালয় ভর্তি ও বিসিএস/চাকরি প্রস্তুতি প্রশ্নব্যাংক চালু রয়েছে। SSC, HSC এবং বিশ্ববিদ্যালয় একাডেমিক শিক্ষার্থীদের জন্য প্রশ্নব্যাংক শীঘ্রই যুক্ত করা হবে।',
                    style: TextStyle(fontSize: 13, height: 1.55),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          },
                          child: const Text('ড্যাশবোর্ড'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ProfileScreen()),
                            );
                          },
                          child: const Text('লক্ষ্য পরিবর্তন'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          qb.activeSector == 'job' ? 'বিসিএস ও চাকরি প্রশ্নব্যাংক' : 'ভর্তি পরীক্ষা প্রশ্নব্যাংক',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: 'ভুল প্রশ্নের খাতা',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MistakeReviewScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => qb.fetchQuestions(page: qb.currentPage),
          ),
        ],
      ),
      body: Column(
        children: [
          // Goal lock notice or guest sector switch
          if (qb.lockedToGoal && user != null)
            Container(
              width: double.infinity,
              color: SikhunTheme.primary.withAlpha(18),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_outlined, size: 16, color: SikhunTheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'আপনার লক্ষ্য (${user.typeLabelBn}) অনুসারে প্রশ্ন প্রদর্শিত হচ্ছে',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SikhunTheme.primary),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 28),
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    ),
                    child: const Text('পরিবর্তন', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Row(
                children: [
                  _sectorTab(qb, 'admission', 'ভর্তি পরীক্ষা (${qb.sectorCounts['admission'] ?? 0})'),
                  const SizedBox(width: 8),
                  _sectorTab(qb, 'job', 'বিসিএস ও চাকরি (${qb.sectorCounts['job'] ?? 0})'),
                ],
              ),
            ),

          // Action Hero Strip (Mock Test + Flashcards + Mistakes)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [SikhunTheme.primary, SikhunTheme.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  qb.activeSector == 'job'
                      ? 'বিসিএস ও সরকারি চাকরি প্রস্তুতি (${qb.totalQuestions} প্রশ্ন)'
                      : 'বিশ্ববিদ্যালয় ও মেডিকেল ভর্তি প্রস্তুতি (${qb.totalQuestions} প্রশ্ন)',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: qb.isGeneratingTest ? null : () => _openCustomMockTestDialog(qb),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: SikhunTheme.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: const Size(0, 34),
                        ),
                        icon: const Icon(Icons.bolt, size: 16),
                        label: const Text('কাস্টম মক টেস্ট', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const CreateFlashcardSetScreen()),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: const Size(0, 34),
                        ),
                        icon: const Icon(Icons.style_outlined, size: 15),
                        label: const Text('ফ্ল্যাশকার্ড', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const MistakeReviewScreen()),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: const Size(0, 34),
                        ),
                        icon: const Icon(Icons.bookmark_remove_outlined, size: 15),
                        label: const Text('ভুলের খাতা', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search + Subject / Exam Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'প্রশ্ন বা অধ্যায় খুঁজুন...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          qb.setFilter(search: '');
                        },
                      )
                    : null,
              ),
              onSubmitted: (val) => qb.setFilter(search: val),
            ),
          ),

          if (qb.subjects.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: qb.subjects.length + 1,
                itemBuilder: (ctx, i) {
                  if (i == 0) {
                    final sel = qb.selectedSubjectId == null;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: const Text('সকল বিষয়', style: TextStyle(fontSize: 11)),
                        selected: sel,
                        onSelected: (_) => qb.setFilter(clearSubject: true),
                      ),
                    );
                  }
                  final subj = qb.subjects[i - 1];
                  final sel = qb.selectedSubjectId == subj.id;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text('${subj.nameBn} (${subj.questionsCount})',
                          style: const TextStyle(fontSize: 11)),
                      selected: sel,
                      onSelected: (_) => qb.setFilter(subjectId: subj.id),
                    ),
                  );
                },
              ),
            ),
          ],

          if (qb.exams.isNotEmpty) ...[
            const SizedBox(height: 6),
            SizedBox(
              height: 34,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: qb.exams.length + 1,
                itemBuilder: (ctx, i) {
                  if (i == 0) {
                    final sel = qb.selectedOriginTag == null;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: const Text('সকল পরীক্ষা', style: TextStyle(fontSize: 11)),
                        selected: sel,
                        onSelected: (_) => qb.setFilter(clearOrigin: true),
                      ),
                    );
                  }
                  final ex = qb.exams[i - 1];
                  final sel = qb.selectedOriginTag == ex.originTag;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text('${ex.examName} (${ex.count})', style: const TextStyle(fontSize: 11)),
                      selected: sel,
                      onSelected: (_) => qb.setFilter(originTag: ex.originTag),
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 8),

          // Questions List
          Expanded(
            child: qb.isLoading && qb.questions.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : qb.errorMessage != null && qb.questions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(qb.errorMessage!),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () => qb.fetchQuestions(),
                              child: const Text('আবার চেষ্টা করুন'),
                            ),
                          ],
                        ),
                      )
                    : qb.questions.isEmpty
                        ? const Center(child: Text('এই ফিল্টারে কোনো প্রশ্ন পাওয়া যায়নি'))
                        : RefreshIndicator(
                            onRefresh: () => qb.fetchQuestions(page: qb.currentPage),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              itemCount: qb.questions.length + 1,
                              itemBuilder: (context, index) {
                                if (index == qb.questions.length) {
                                  return Column(
                                    children: [
                                      if (!qb.isPaid)
                                        Container(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: SikhunTheme.warning.withAlpha(20),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: SikhunTheme.warning.withAlpha(80)),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.workspace_premium, color: SikhunTheme.warning),
                                              const SizedBox(width: 10),
                                              const Expanded(
                                                child: Text(
                                                  'সম্পূর্ণ প্রশ্নব্যাংক ও আনলিমিটেড এআই ব্যাখ্যা আনলক করতে সাবস্ক্রিপশন নিন।',
                                                  style: TextStyle(fontSize: 12),
                                                ),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.of(context).push(
                                                  MaterialPageRoute(builder: (_) => const PlansScreen()),
                                                ),
                                                child: const Text('প্ল্যান দেখুন', style: TextStyle(fontSize: 11)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (qb.lastPage > 1)
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            TextButton.icon(
                                              onPressed: qb.currentPage > 1
                                                  ? () => qb.fetchQuestions(page: qb.currentPage - 1)
                                                  : null,
                                              icon: const Icon(Icons.chevron_left),
                                              label: const Text('পূর্ববর্তী'),
                                            ),
                                            Text('পৃষ্ঠা ${qb.currentPage} / ${qb.lastPage}'),
                                            TextButton.icon(
                                              onPressed: qb.currentPage < qb.lastPage
                                                  ? () => qb.fetchQuestions(page: qb.currentPage + 1)
                                                  : null,
                                              icon: const Icon(Icons.chevron_right),
                                              label: const Text('পরবর্তী'),
                                            ),
                                          ],
                                        ),
                                      const SizedBox(height: 40),
                                    ],
                                  );
                                }

                                return _buildQuestionCard(qb.questions[index], index + 1, qb);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _sectorTab(QuestionBankProvider qb, String sector, String label) {
    final selected = qb.activeSector == sector;
    return Expanded(
      child: InkWell(
        onTap: () => qb.setFilter(sector: sector, clearSubject: true, clearOrigin: true),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? SikhunTheme.primary : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? SikhunTheme.primary : Colors.grey.withAlpha(50),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(QuestionModel q, int number, QuestionBankProvider qb) {
    final selectedIdx = _selectedAnswers[q.id];
    final isRevealed = _revealedAnswers.contains(q.id);
    final aiExp = qb.explanationFor(q.id);
    final isExplaining = qb.isExplaining(q.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _tag('#$number', SikhunTheme.primary),
                if (q.examName != null && q.examName!.isNotEmpty)
                  _tag('${q.examName}${q.year != null ? ' ${q.year}' : ''}', SikhunTheme.accent),
                if (q.subject != null && q.subject!.isNotEmpty)
                  _tag(q.subject!, SikhunTheme.success),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              q.questionText,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.45),
            ),
            const SizedBox(height: 12),
            ...List.generate(q.options.length, (i) {
              final isSelected = selectedIdx == i;
              final isCorrect = q.correctOptionIndex == i;

              Color borderColor = Colors.grey.withAlpha(60);
              Color fillColor = Colors.transparent;
              if (isSelected || isRevealed) {
                if (isCorrect) {
                  borderColor = SikhunTheme.success;
                  fillColor = SikhunTheme.success.withAlpha(20);
                } else if (isSelected && q.correctOptionIndex != null && !isCorrect) {
                  borderColor = SikhunTheme.danger;
                  fillColor = SikhunTheme.danger.withAlpha(20);
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedAnswers[q.id] = i;
                      _revealedAnswers.add(q.id);
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: fillColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? (isCorrect ? SikhunTheme.success : SikhunTheme.danger)
                                : Colors.grey.withAlpha(40),
                          ),
                          child: Center(
                            child: Text(
                              String.fromCharCode(65 + i),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : null,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(q.options[i], style: const TextStyle(fontSize: 14)),
                        ),
                        if ((isSelected || isRevealed) && isCorrect)
                          const Icon(Icons.check_circle, color: SikhunTheme.success, size: 18)
                        else if (isSelected && q.correctOptionIndex != null && !isCorrect)
                          const Icon(Icons.cancel, color: SikhunTheme.danger, size: 18),
                      ],
                    ),
                  ),
                ),
              );
            }),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      if (isRevealed) {
                        _revealedAnswers.remove(q.id);
                      } else {
                        _revealedAnswers.add(q.id);
                      }
                    });
                  },
                  icon: Icon(isRevealed ? Icons.visibility_off : Icons.visibility, size: 16),
                  label: Text(isRevealed ? 'উত্তর লুকান' : 'সঠিক উত্তর দেখুন',
                      style: const TextStyle(fontSize: 12)),
                ),
                TextButton.icon(
                  onPressed: isExplaining ? null : () => qb.explainQuestion(q.id),
                  icon: isExplaining
                      ? const SizedBox(
                          width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('এআই ব্যাখ্যা', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            if (isRevealed && q.explanation != null && q.explanation!.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: SikhunTheme.success.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('ব্যাখ্যা: ${q.explanation}', style: const TextStyle(fontSize: 12, height: 1.5)),
              ),
            if (aiExp != null && aiExp.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: SikhunTheme.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('এআই টিউটরের ব্যাখ্যা:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: SikhunTheme.primary)),
                    const SizedBox(height: 4),
                    Text(aiExp, style: const TextStyle(fontSize: 12, height: 1.5)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
