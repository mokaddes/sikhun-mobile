import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../models/question_model.dart';
import '../services/api_service.dart';

class QuestionSubjectItem {
  final int id;
  final String nameBn;
  final String nameEn;
  final String segment;
  final int questionsCount;

  QuestionSubjectItem({
    required this.id,
    required this.nameBn,
    required this.nameEn,
    required this.segment,
    this.questionsCount = 0,
  });

  factory QuestionSubjectItem.fromJson(Map<String, dynamic> json) {
    return QuestionSubjectItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      nameBn: (json['name_bn'] ?? json['name'] ?? '').toString(),
      nameEn: (json['name_en'] ?? json['name_bn'] ?? '').toString(),
      segment: (json['segment'] ?? 'admission').toString(),
      questionsCount: int.tryParse((json['questions_count'] ?? 0).toString()) ?? 0,
    );
  }
}

class QuestionExamItem {
  final String originTag;
  final String examName;
  final String? institution;
  final int? year;
  final int count;

  QuestionExamItem({
    required this.originTag,
    required this.examName,
    this.institution,
    this.year,
    this.count = 0,
  });

  factory QuestionExamItem.fromJson(Map<String, dynamic> json) {
    final tag = (json['origin_tag'] ?? '').toString();
    return QuestionExamItem(
      originTag: tag,
      examName: (json['exam_name'] ?? tag).toString(),
      institution: json['institution']?.toString(),
      year: int.tryParse(json['year']?.toString() ?? ''),
      count: int.tryParse((json['count'] ?? 0).toString()) ?? 0,
    );
  }
}

class QuestionBankProvider extends ChangeNotifier {
  List<QuestionModel> _questions = [];
  List<QuestionSubjectItem> _subjects = [];
  List<QuestionExamItem> _exams = [];
  Map<String, int> _sectorCounts = const {'admission': 0, 'job': 0, 'hsc': 0, 'ssc': 0};
  final Map<int, String> _aiExplanations = {};
  final Set<int> _loadingExplanations = {};

  bool _isLoading = false;
  bool _isGeneratingTest = false;
  String? _errorMessage;
  bool _isPaid = false;
  bool _lockedToGoal = false;
  bool _isUnavailable = false;
  String _activeSector = 'admission';
  String? _studentGoal;

  int? _selectedSubjectId;
  String? _selectedOriginTag;
  String _searchQuery = '';
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalQuestions = 0;

  List<QuestionModel> get questions => _questions;
  List<QuestionSubjectItem> get subjects => _subjects;
  List<QuestionExamItem> get exams => _exams;
  Map<String, int> get sectorCounts => _sectorCounts;
  bool get isLoading => _isLoading;
  bool get isGeneratingTest => _isGeneratingTest;
  String? get errorMessage => _errorMessage;
  bool get isPaid => _isPaid;
  bool get lockedToGoal => _lockedToGoal;
  bool get isUnavailable => _isUnavailable;
  String get activeSector => _activeSector;
  String? get studentGoal => _studentGoal;
  int? get selectedSubjectId => _selectedSubjectId;
  String? get selectedOriginTag => _selectedOriginTag;
  String get searchQuery => _searchQuery;
  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
  int get totalQuestions => _totalQuestions;

  String? explanationFor(int id) => _aiExplanations[id];
  bool isExplaining(int id) => _loadingExplanations.contains(id);

  Future<void> init({String? sector}) async {
    await fetchQuestions(sector: sector);
  }

  void setFilter({
    String? sector,
    int? subjectId,
    bool clearSubject = false,
    String? originTag,
    bool clearOrigin = false,
    String? search,
  }) {
    if (sector != null) _activeSector = sector;
    if (clearSubject) {
      _selectedSubjectId = null;
    } else if (subjectId != null) {
      _selectedSubjectId = subjectId;
    }
    if (clearOrigin) {
      _selectedOriginTag = null;
    } else if (originTag != null) {
      _selectedOriginTag = originTag;
    }
    if (search != null) _searchQuery = search;
    _currentPage = 1;
    fetchQuestions();
  }

  void resetFilters() {
    _selectedSubjectId = null;
    _selectedOriginTag = null;
    _searchQuery = '';
    _currentPage = 1;
    fetchQuestions();
  }

  Future<void> fetchQuestions({String? sector, int page = 1}) async {
    _isLoading = true;
    _errorMessage = null;
    if (sector != null) _activeSector = sector;
    _currentPage = page;
    notifyListeners();

    final query = <String, dynamic>{
      'sector': _activeSector,
      'page': _currentPage,
    };
    if (_selectedSubjectId != null) query['subject_id'] = _selectedSubjectId;
    if (_selectedOriginTag != null && _selectedOriginTag!.isNotEmpty) {
      query['origin_tag'] = _selectedOriginTag;
    }
    if (_searchQuery.isNotEmpty) query['search'] = _searchQuery;

    final response = await ApiService.get(ApiEndpoints.questionBank, queryParams: query);
    _isLoading = false;

    if (response.success && response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      _isPaid = data['is_paid'] == true;
      _lockedToGoal = data['locked_to_goal'] == true;
      _isUnavailable = data['is_unavailable'] == true;
      _activeSector = (data['active_sector'] ?? _activeSector).toString();
      _studentGoal = data['student_goal']?.toString();

      if (data['sector_counts'] is Map) {
        final map = <String, int>{};
        (data['sector_counts'] as Map).forEach((k, v) {
          map[k.toString()] = int.tryParse(v.toString()) ?? 0;
        });
        _sectorCounts = map;
      }

      if (data['subjects'] is List) {
        _subjects = (data['subjects'] as List)
            .whereType<Map<String, dynamic>>()
            .map(QuestionSubjectItem.fromJson)
            .toList();
      } else {
        _subjects = [];
      }

      if (data['exams'] is List) {
        _exams = (data['exams'] as List)
            .whereType<Map<String, dynamic>>()
            .map(QuestionExamItem.fromJson)
            .toList();
      } else {
        _exams = [];
      }

      if (data['questions'] is List) {
        _questions = (data['questions'] as List)
            .whereType<Map<String, dynamic>>()
            .map(QuestionModel.fromJson)
            .toList();
      } else {
        _questions = [];
      }

      if (data['pagination'] is Map) {
        _currentPage = int.tryParse(data['pagination']['current_page']?.toString() ?? '1') ?? 1;
        _lastPage = int.tryParse(data['pagination']['last_page']?.toString() ?? '1') ?? 1;
        _totalQuestions = int.tryParse(data['pagination']['total']?.toString() ?? '0') ?? _questions.length;
      }
    } else {
      _errorMessage = response.message ?? 'প্রশ্ন লোড করা যায়নি';
    }

    notifyListeners();
  }

  Future<String?> explainQuestion(int questionId) async {
    if (_aiExplanations.containsKey(questionId)) {
      return _aiExplanations[questionId];
    }
    _loadingExplanations.add(questionId);
    notifyListeners();

    final response = await ApiService.post(ApiEndpoints.questionBankAiExplain(questionId));
    _loadingExplanations.remove(questionId);

    if (response.success && response.data is Map && response.data['explanation'] != null) {
      final exp = response.data['explanation'].toString();
      _aiExplanations[questionId] = exp;
      notifyListeners();
      return exp;
    }

    notifyListeners();
    return null;
  }

  Future<ApiResponse> generateCustomTest({
    int? subjectId,
    String? originTag,
    int questionCount = 20,
    int durationMinutes = 20,
    bool negativeMarking = true,
  }) async {
    _isGeneratingTest = true;
    notifyListeners();

    final body = <String, dynamic>{
      'question_count': questionCount,
      'duration_minutes': durationMinutes,
      'negative_marking': negativeMarking,
    };
    if (subjectId != null) body['subject_id'] = subjectId;
    if (originTag != null && originTag.isNotEmpty) body['origin_tag'] = originTag;

    final response = await ApiService.post(ApiEndpoints.questionBankGenerateTest, body: body);
    _isGeneratingTest = false;
    notifyListeners();
    return response;
  }
}
