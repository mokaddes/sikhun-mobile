import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/library_provider.dart';
import 'providers/question_bank_provider.dart';
import 'providers/blog_provider.dart';
import 'providers/ai_chat_provider.dart';
import 'providers/app_setting_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/dashboard_provider.dart';
import 'screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SikhunApp());
}

class SikhunApp extends StatelessWidget {
  const SikhunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
        ChangeNotifierProvider(create: (_) => QuestionBankProvider()),
        ChangeNotifierProvider(create: (_) => BlogProvider()),
        ChangeNotifierProvider(create: (_) => AiChatProvider()),
        ChangeNotifierProvider(create: (_) => AppSettingProvider()..fetchSettings()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()..startSync()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: MaterialApp(
        title: 'শিখুন (Sikhun)',
        debugShowCheckedModeBanner: false,
        theme: SikhunTheme.lightTheme,
        darkTheme: SikhunTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const MainNavigationScreen(),
      ),
    );
  }
}
