class QuestionModel {
  final int id;
  final String questionText;
  final String? examName;
  final String? institution;
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
  final double marks;
  final double negativeMarks;

  QuestionModel({
    required this.id,
    required this.questionText,
    this.examName,
    this.institution,
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
    this.marks = 1.0,
    this.negativeMarks = 0.25,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    final List<String> parsedOptions = [];
    final List<String> parsedKeys = [];

    if (json['options'] is List) {
      for (final o in json['options'] as List) {
        if (o is Map) {
          parsedKeys.add((o['key'] ?? '').toString().trim().toUpperCase());
          parsedOptions.add((o['text'] ?? o['label'] ?? '').toString());
        } else {
          parsedOptions.add(o.toString());
        }
      }
    } else {
      if (json['option_a'] != null) parsedOptions.add(json['option_a'].toString());
      if (json['option_b'] != null) parsedOptions.add(json['option_b'].toString());
      if (json['option_c'] != null) parsedOptions.add(json['option_c'].toString());
      if (json['option_d'] != null) parsedOptions.add(json['option_d'].toString());
    }

    int? correctIdx;
    if (json['correct_option'] != null) {
      final co = json['correct_option'].toString().trim().toUpperCase();
      if (parsedKeys.isNotEmpty) {
        final keyMatch = parsedKeys.indexOf(co);
        if (keyMatch != -1) correctIdx = keyMatch;
      }
      if (correctIdx == null) {
        if (co == 'A' || co == '১' || co == 'ক') {
          correctIdx = 0;
        } else if (co == 'B' || co == '২' || co == 'খ') {
          correctIdx = 1;
        } else if (co == 'C' || co == '৩' || co == 'গ') {
          correctIdx = 2;
        } else if (co == 'D' || co == '৪' || co == 'ঘ') {
          correctIdx = 3;
        } else {
          final parsedNum = int.tryParse(co);
          if (parsedNum != null && parsedNum >= 1 && parsedNum <= parsedOptions.length) {
            correctIdx = parsedNum - 1;
          }
        }
      }
    } else if (json['correct_answer'] != null) {
      final ca = json['correct_answer'].toString().trim();
      final idx = parsedOptions.indexWhere((opt) => opt.trim() == ca);
      if (idx != -1) {
        correctIdx = idx;
      }
    }

    String? subjectName;
    if (json['subject'] is Map) {
      subjectName = (json['subject']['name_bn'] ?? json['subject']['name_en'] ?? json['subject']['name'])?.toString();
    } else if (json['subject'] != null) {
      subjectName = json['subject'].toString();
    }

    String? topicName;
    if (json['topic'] is Map) {
      topicName = (json['topic']['name_bn'] ?? json['topic']['name_en'] ?? json['topic']['name'])?.toString();
    } else if (json['topic'] != null) {
      topicName = json['topic'].toString();
    }

    String? aiExp;
    if (json['meta'] is Map && json['meta']['ai_explanation'] != null) {
      aiExp = json['meta']['ai_explanation'].toString();
    }
    aiExp ??= json['explanation']?.toString();

    return QuestionModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      questionText: (json['question_text'] ?? json['question'] ?? '').toString(),
      examName: json['exam_name']?.toString(),
      institution: json['institution']?.toString(),
      segment: json['segment']?.toString(),
      subject: subjectName,
      chapter: json['chapter']?.toString(),
      topic: topicName,
      year: json['year'] is int ? json['year'] : int.tryParse(json['year']?.toString() ?? ''),
      options: parsedOptions,
      correctOptionIndex: correctIdx,
      correctAnswerText: (correctIdx != null && correctIdx < parsedOptions.length)
          ? parsedOptions[correctIdx]
          : json['correct_answer']?.toString(),
      explanation: aiExp,
      originTag: json['origin_tag']?.toString(),
      marks: double.tryParse((json['marks'] ?? 1.0).toString()) ?? 1.0,
      negativeMarks: double.tryParse((json['negative_marks'] ?? 0.25).toString()) ?? 0.25,
    );
  }
}
