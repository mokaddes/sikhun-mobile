class QuestionModel {
  final int id;
  final String questionText;
  final String? examName;
  final String? segment;
  final String? subject;
  final String? chapter;
  final String? topic;
  final int? year;
  final List<String> options;
  final int? correctOptionIndex;
  final String? correctAnswerText;
  final String? explanation;
  final String? originTag;

  QuestionModel({
    required this.id,
    required this.questionText,
    this.examName,
    this.segment,
    this.subject,
    this.chapter,
    this.topic,
    this.year,
    required this.options,
    this.correctOptionIndex,
    this.correctAnswerText,
    this.explanation,
    this.originTag,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedOptions = [];
    if (json['options'] is List) {
      parsedOptions = (json['options'] as List).map((o) => o.toString()).toList();
    } else {
      if (json['option_a'] != null) {
        parsedOptions.add(json['option_a'].toString());
      }
      if (json['option_b'] != null) {
        parsedOptions.add(json['option_b'].toString());
      }
      if (json['option_c'] != null) {
        parsedOptions.add(json['option_c'].toString());
      }
      if (json['option_d'] != null) {
        parsedOptions.add(json['option_d'].toString());
      }
    }

    int? correctIdx;
    if (json['correct_option'] != null) {
      final co = json['correct_option'].toString().trim().toUpperCase();
      if (co == 'A' || co == '১') {
        correctIdx = 0;
      } else if (co == 'B' || co == '২') {
        correctIdx = 1;
      } else if (co == 'C' || co == '৩') {
        correctIdx = 2;
      } else if (co == 'D' || co == '৪') {
        correctIdx = 3;
      } else {
        final parsedNum = int.tryParse(co);
        if (parsedNum != null) {
          correctIdx = parsedNum - 1;
        }
      }
    } else if (json['correct_answer'] != null) {
      final ca = json['correct_answer'].toString().trim();
      final idx = parsedOptions.indexWhere((opt) => opt.trim() == ca);
      if (idx != -1) {
        correctIdx = idx;
      }
    }

    return QuestionModel(
      id: json['id'] ?? 0,
      questionText: json['question_text'] ?? json['question'] ?? '',
      examName: json['exam_name']?.toString(),
      segment: json['segment']?.toString(),
      subject: json['subject']?.toString(),
      chapter: json['chapter']?.toString(),
      topic: json['topic']?.toString(),
      year: json['year'] is int ? json['year'] : int.tryParse(json['year']?.toString() ?? ''),
      options: parsedOptions,
      correctOptionIndex: correctIdx,
      correctAnswerText: json['correct_answer']?.toString(),
      explanation: json['explanation']?.toString(),
      originTag: json['origin_tag']?.toString(),
    );
  }
}
