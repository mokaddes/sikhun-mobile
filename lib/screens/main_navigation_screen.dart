import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import 'ai_chat/ai_chat_screen.dart';
import 'dashboard/student_dashboard_screen.dart';
import 'exams/exams_screen.dart';
import 'home/home_screen.dart';
import 'library/library_screen.dart';
import 'profile/profile_screen.dart';
import 'question_bank/question_bank_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final locale = context.watch<LocaleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Web parity: SSC / HSC / University students cannot see Question Bank menu
    final showQuestionBank = !auth.isAuthenticated || (auth.user?.canAccessQuestionBank ?? true);

    final List<Widget> screens = [
      auth.isAuthenticated ? const StudentDashboardScreen() : const HomeScreen(),
      const LibraryScreen(),
      const AiChatScreen(),
      showQuestionBank ? const QuestionBankScreen() : const ExamsScreen(),
      const ProfileScreen(),
    ];

    final int safeIndex = _currentIndex.clamp(0, screens.length - 1).toInt();

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? SikhunTheme.darkBorder : SikhunTheme.lightBorder,
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          height: 68,
          selectedIndex: safeIndex,
          backgroundColor: isDark ? SikhunTheme.darkSurface : SikhunTheme.lightSurface,
          indicatorColor: (isDark ? SikhunTheme.darkPrimary : SikhunTheme.primary).withAlpha(32),
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          destinations: [
            NavigationDestination(
              icon: Icon(auth.isAuthenticated ? Icons.dashboard_outlined : Icons.home_outlined),
              selectedIcon: Icon(auth.isAuthenticated ? Icons.dashboard : Icons.home),
              label: auth.isAuthenticated ? locale.t('nav.dashboard') : locale.t('nav.home'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.menu_book_outlined),
              selectedIcon: const Icon(Icons.menu_book),
              label: locale.t('nav.library'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.smart_toy_outlined),
              selectedIcon: const Icon(Icons.smart_toy),
              label: locale.t('nav.ai_chat'),
            ),
            if (showQuestionBank)
              NavigationDestination(
                icon: const Icon(Icons.assignment_turned_in_outlined),
                selectedIcon: const Icon(Icons.assignment_turned_in),
                label: locale.t('nav.question_bank'),
              )
            else
              NavigationDestination(
                icon: const Icon(Icons.quiz_outlined),
                selectedIcon: const Icon(Icons.quiz),
                label: locale.t('nav.exams'),
              ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: locale.t('nav.profile'),
            ),
          ],
        ),
      ),
      floatingActionButton: safeIndex == 0
          ? FloatingActionButton.small(
              heroTag: 'quick_ai_fab',
              backgroundColor: isDark ? SikhunTheme.darkPrimary : SikhunTheme.primary,
              foregroundColor: isDark ? const Color(0xFF111827) : Colors.white,
              onPressed: () {
                setState(() => _currentIndex = 2);
              },
              tooltip: locale.t('nav.ai_chat'),
              child: const Icon(Icons.auto_awesome),
            )
          : null,
    );
  }
}
