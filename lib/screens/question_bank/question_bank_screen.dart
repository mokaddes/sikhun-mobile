import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/question_model.dart';
import '../../providers/question_bank_provider.dart';

class QuestionBankScreen extends StatefulWidget {
  const QuestionBankScreen({super.key});

  @override
  State<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<QuestionBankScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Map<int, int> _userSelectedAnswers = {};
  final Set<int> _revealedExplanations = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<QuestionBankProvider>(context, listen: false).init();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterModal(BuildContext context) {
    final qb = Provider.of<QuestionBankProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ফিল্টার করুন',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          qb.resetFilters();
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('রিসেট'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Segment
                  if (qb.segments.isNotEmpty) ...[
                    const Text('ক্যাটাগরি / সেগমেন্ট', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: qb.segments.map((seg) {
                        final isSel = qb.selectedSegment == seg;
                        return ChoiceChip(
                          label: Text(seg),
                          selected: isSel,
                          onSelected: (val) {
                            qb.setFilter(segment: val ? seg : 'all');
                            setModalState(() {});
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Subject
                  if (qb.subjects.isNotEmpty) ...[
                    const Text('বিষয়', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: qb.subjects.take(8).map((sub) {
                        final isSel = qb.selectedSubject == sub;
                        return ChoiceChip(
                          label: Text(sub),
                          selected: isSel,
                          onSelected: (val) {
                            qb.setFilter(subject: val ? sub : 'all');
                            setModalState(() {});
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                  ],

                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('প্রয়োগ করুন'),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final qb = Provider.of<QuestionBankProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('স্মার্ট প্রশ্নব্যাংক'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'ফিল্টার',
            onPressed: () => _showFilterModal(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'প্রশ্ন, পরীক্ষা বা টপিক খুঁজুন...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          qb.setFilter(search: '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onSubmitted: (val) {
                qb.setFilter(search: val.trim());
              },
            ),
          ),

          // Active filter badges
          if (qb.selectedSegment != null || qb.selectedSubject != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    if (qb.selectedSegment != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text('ক্যাটাগরি: ${qb.selectedSegment}'),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => qb.setFilter(segment: 'all'),
                        ),
                      ),
                    if (qb.selectedSubject != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text('বিষয়: ${qb.selectedSubject}'),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => qb.setFilter(subject: 'all'),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Question count indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'মোট প্রশ্ন: ${qb.questions.length} টি',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: SikhunTheme.mutedDark),
                ),
              ],
            ),
          ),

          // Question List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => qb.fetchQuestions(),
              child: qb.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : qb.questions.isEmpty
                      ? const Center(
                          child: Text(
                            'কোনো প্রশ্ন পাওয়া যায়নি',
                            style: TextStyle(color: SikhunTheme.mutedDark),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: qb.questions.length,
                          itemBuilder: (context, index) {
                            final q = qb.questions[index];
                            return _buildQuestionCard(q, index);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QuestionModel q, int index) {
    final selectedOption = _userSelectedAnswers[q.id];
    final showExplanation = _revealedExplanations.contains(q.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header tags: Exam name, Subject, Year
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (q.examName != null && q.examName!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: SikhunTheme.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      q.examName!,
                      style: const TextStyle(fontSize: 11, color: SikhunTheme.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                if (q.subject != null && q.subject!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      q.subject!,
                      style: const TextStyle(fontSize: 11, color: SikhunTheme.textDark),
                    ),
                  ),
                if (q.year != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${q.year}',
                      style: const TextStyle(fontSize: 11, color: SikhunTheme.textDark),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Question Text
            Text(
              '${index + 1}. ${q.questionText}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),

            // Options
            ...List.generate(q.options.length, (optIdx) {
              final optionText = q.options[optIdx];
              final isChosen = selectedOption == optIdx;
              final isCorrect = q.correctOptionIndex == optIdx;

              Color borderColor = Colors.grey.shade300;
              Color bgColor = Colors.transparent;
              IconData? statusIcon;

              if (selectedOption != null) {
                if (isCorrect) {
                  borderColor = SikhunTheme.accent;
                  bgColor = SikhunTheme.accent.withAlpha(25);
                  statusIcon = Icons.check_circle;
                } else if (isChosen) {
                  borderColor = SikhunTheme.danger;
                  bgColor = SikhunTheme.danger.withAlpha(25);
                  statusIcon = Icons.cancel;
                }
              }

              final letters = ['ক', 'খ', 'গ', 'ঘ'];
              final prefix = optIdx < letters.length ? letters[optIdx] : '${optIdx + 1}';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor, width: isChosen || (selectedOption != null && isCorrect) ? 1.5 : 1),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    setState(() {
                      _userSelectedAnswers[q.id] = optIdx;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: isChosen
                              ? (isCorrect ? SikhunTheme.accent : SikhunTheme.danger)
                              : Colors.grey.shade200,
                          child: Text(
                            prefix,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isChosen ? Colors.white : SikhunTheme.textDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            optionText,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        if (statusIcon != null)
                          Icon(
                            statusIcon,
                            size: 18,
                            color: isCorrect ? SikhunTheme.accent : SikhunTheme.danger,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            // Explanation Section
            if (selectedOption != null && q.explanation != null && q.explanation!.isNotEmpty) ...[
              const SizedBox(height: 8),
              if (!showExplanation)
                TextButton.icon(
                  icon: const Icon(Icons.help_outline, size: 16),
                  label: const Text('ব্যাখ্যা দেখুন', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    setState(() {
                      _revealedExplanations.add(q.id);
                    });
                  },
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lightbulb_outline, size: 16, color: Colors.orange),
                          SizedBox(width: 4),
                          Text(
                            'সঠিক উত্তরের ব্যাখ্যা:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.brown),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        q.explanation!,
                        style: const TextStyle(fontSize: 12, height: 1.4, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
