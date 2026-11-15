import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../models/question_model.dart';
import '../services/api_service.dart';

class QuestionBankProvider extends ChangeNotifier {
  List<QuestionModel> _questions = [];
  bool _isLoading = false;
  String? _errorMessage;

  String? _selectedSegment;
  String? _selectedExam;
  String? _selectedSubject;
  int? _selectedYear;
  String _searchQuery = '';

  List<String> _segments = [];
  List<String> _exams = [];
  List<String> _subjects = [];
  List<int> _years = [];

  List<QuestionModel> get questions => _questions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? get selectedSegment => _selectedSegment;
  String? get selectedExam => _selectedExam;
  String? get selectedSubject => _selectedSubject;
  int? get selectedYear => _selectedYear;
  String get searchQuery => _searchQuery;

  List<String> get segments => _segments;
  List<String> get exams => _exams;
  List<String> get subjects => _subjects;
  List<int> get years => _years;

  Future<void> init() async {
    await fetchFilters();
    await fetchQuestions();
  }

  Future<void> fetchFilters() async {
    final response = await ApiService.get(ApiEndpoints.questionBankFilters);
    if (response.success && response.data != null) {
      final data = response.data;
      if (data['segments'] is List) {
        _segments = List<String>.from(data['segments']);
      }
      if (data['exams'] is List) {
        _exams = List<String>.from(data['exams']);
      }
      if (data['subjects'] is List) {
        _subjects = List<String>.from(data['subjects']);
      }
      if (data['years'] is List) {
        _years = (data['years'] as List)
            .map((y) => int.tryParse(y.toString()) ?? 0)
            .where((y) => y > 0)
            .toList();
      }
      notifyListeners();
    }
  }

  void setFilter({
    String? segment,
    String? exam,
    String? subject,
    int? year,
    String? search,
  }) {
    if (segment != null) _selectedSegment = segment == 'all' ? null : segment;
    if (exam != null) _selectedExam = exam == 'all' ? null : exam;
    if (subject != null) _selectedSubject = subject == 'all' ? null : subject;
    if (year != null) _selectedYear = year == 0 ? null : year;
    if (search != null) _searchQuery = search;

    fetchQuestions();
  }

  void resetFilters() {
    _selectedSegment = null;
    _selectedExam = null;
    _selectedSubject = null;
    _selectedYear = null;
    _searchQuery = '';
    fetchQuestions();
  }

  Future<void> fetchQuestions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final query = <String, dynamic>{};
    if (_selectedSegment != null) query['segment'] = _selectedSegment;
    if (_selectedExam != null) query['exam_name'] = _selectedExam;
    if (_selectedSubject != null) query['subject'] = _selectedSubject;
    if (_selectedYear != null) query['year'] = _selectedYear;
    if (_searchQuery.isNotEmpty) query['search'] = _searchQuery;

    final response = await ApiService.get(ApiEndpoints.questionBank, queryParams: query);
    _isLoading = false;

    if (response.success && response.data != null) {
      final list = (response.data is List)
          ? response.data as List
          : (response.data['questions'] ?? response.data['data'] ?? []) as List;
      _questions = list.map((json) => QuestionModel.fromJson(json)).toList();
    } else {
      _errorMessage = response.message ?? 'প্রশ্ন লোড করা যায়নি';
    }
    notifyListeners();
  }
}
