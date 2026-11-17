import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import 'dashboard/student_dashboard_screen.dart';
import 'home/home_screen.dart';
import 'library/library_screen.dart';
import 'question_bank/question_bank_screen.dart';
import 'ai_chat/ai_chat_screen.dart';
import 'profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final localeProv = Provider.of<LocaleProvider>(context);
    final themeProv = Provider.of<ThemeProvider>(context);
    final isDark = themeProv.isDarkMode;

    // Screens list:
    // If student is authenticated, index 0 is StudentDashboardScreen (Image 3)
    // If guest, index 0 is HomeScreen (landing page)
    final List<Widget> screens = [
      auth.isAuthenticated ? const StudentDashboardScreen() : const HomeScreen(),
      const LibraryScreen(),
      const AiChatScreen(),
      const QuestionBankScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      // Floating Speech Bubble in Bottom Right (Matching Image 3)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _currentIndex = 2; // Jump to AI Chat
          });
        },
        backgroundColor: const Color(0xFF8A5A32),
        foregroundColor: Colors.white,
        elevation: 3,
        shape: const CircleBorder(),
        child: const Icon(Icons.chat_bubble_outline, size: 24),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? SikhunTheme.darkSurface : SikhunTheme.lightSurface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 30 : 12),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: isDark ? SikhunTheme.darkSurface : SikhunTheme.lightSurface,
          indicatorColor: const Color(0xFF8A5A32).withAlpha(40),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home, color: Color(0xFF8A5A32)),
              label: localeProv.t('nav.dashboard'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.menu_book_outlined),
              selectedIcon: const Icon(Icons.menu_book, color: Color(0xFF8A5A32)),
              label: localeProv.t('nav.library'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.auto_awesome_outlined),
              selectedIcon: const Icon(Icons.auto_awesome, color: Color(0xFF8A5A32)),
              label: localeProv.t('nav.ai_chat'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.assignment_outlined),
              selectedIcon: const Icon(Icons.assignment, color: Color(0xFF8A5A32)),
              label: localeProv.t('nav.exams'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings, color: Color(0xFF8A5A32)),
              label: localeProv.t('nav.profile_settings'),
            ),
          ],
        ),
      ),
    );
  }
}
