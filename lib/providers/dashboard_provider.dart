import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../models/dashboard_model.dart';
import '../services/api_service.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardDataModel? _dashboardData;
  bool _isLoading = false;
  String? _errorMessage;

  DashboardDataModel? get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchDashboard() async {
    final token = await ApiService.getToken();
    if (token == null || token.isEmpty) {
      _dashboardData = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await ApiService.get(ApiEndpoints.dashboard);
    _isLoading = false;

    if (response.success && response.data != null) {
      _dashboardData = DashboardDataModel.fromJson(response.data);
    } else {
      _errorMessage = response.message ?? 'ড্যাশবোর্ড তথ্য লোড করা যায়নি';
    }

    notifyListeners();
  }
}
