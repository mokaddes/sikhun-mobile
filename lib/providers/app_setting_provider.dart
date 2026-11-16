import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../models/app_setting_model.dart';
import '../services/api_service.dart';

class AppSettingProvider extends ChangeNotifier {
  AppSettingModel _settings = AppSettingModel();
  bool _isLoading = false;

  AppSettingModel get settings => _settings;
  bool get isLoading => _isLoading;
  String? get logoUrl => _settings.logoUrl;
  String get siteName => _settings.siteNameBn.isNotEmpty ? _settings.siteNameBn : _settings.siteName;
  String get siteTagline => _settings.siteTaglineBn ?? 'আপনার এআই পড়ার টেবিল';

  Future<void> fetchSettings() async {
    _isLoading = true;
    notifyListeners();

    final response = await ApiService.get(ApiEndpoints.settings);
    _isLoading = false;

    if (response.success && response.data != null) {
      _settings = AppSettingModel.fromJson(response.data);
      notifyListeners();
    }
  }
}
