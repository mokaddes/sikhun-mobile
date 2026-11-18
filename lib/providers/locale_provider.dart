import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _prefKey = 'sikhun_locale';
  String _languageCode = 'bn'; // 'bn' or 'en'

  String get languageCode => _languageCode;
  bool get isBengali => _languageCode == 'bn';
  Locale get locale => Locale(_languageCode);

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString(_prefKey);
    if (savedLocale != null && (savedLocale == 'en' || savedLocale == 'bn')) {
      _languageCode = savedLocale;
      notifyListeners();
    }
  }

  Future<void> toggleLocale() async {
    _languageCode = (_languageCode == 'bn') ? 'en' : 'bn';
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, _languageCode);
  }

  Future<void> setLocale(String code) async {
    if (code == _languageCode) return;
    _languageCode = (code == 'en') ? 'en' : 'bn';
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, _languageCode);
  }

  static final Map<String, Map<String, String>> _translations = {
    'bn': {
      'nav.dashboard': 'ড্যাশবোর্ড',
      'nav.library': 'লাইব্রেরি',
      'nav.bookshelf': 'আমার তাক',
      'nav.ai_chat': 'এআই চ্যাট',
      'nav.exams': 'পরীক্ষা',
      'nav.profile': 'প্রোফাইল',
      'nav.profile_settings': 'প্রোফাইল সেটিংস',
      'nav.home': 'হোম',
      'nav.question_bank': 'প্রশ্নব্যাংক',
      'nav.mistakes': 'আমার ভুল খাতা',
      'nav.flashcards': 'ফ্ল্যাশকার্ড',
      'nav.essays': 'রচনা মূল্যায়ন',
      'nav.schedules': 'পড়ার রুটিন',
      'nav.notices': 'ভর্তি ও চাকরির নোটিশ',
      'nav.admissions': 'ভর্তি বিজ্ঞপ্তি',
      'nav.jobs': 'চাকরির খবর',
      'nav.courses': 'কোর্সসমূহ',
      'nav.wallet': 'ওয়ালেট',
      'nav.plans': 'প্ল্যান ও বান্ডেল',
      'nav.leaderboard': 'লিডারবোর্ড',
      'nav.referrals': 'রেফারেল',
      'nav.support': 'সহায়তা ও টিকিট',
      'nav.blog': 'ব্লগ',
      'dashboard.overview': 'STUDENT OVERVIEW',
      'dashboard.welcome': 'স্বাগতম',
      'dashboard.subtitle': 'একনজরে আপনার পড়ার অগ্রগতি ও প্রস্তুতি।',
      'dashboard.wallet_balance': 'ওয়ালেট ব্যালেন্স',
      'dashboard.books_owned': 'মোট বই',
      'dashboard.exams_taken': 'সম্পন্ন পরীক্ষা',
      'dashboard.courses_enrolled': 'এনরোল করা কোর্স',
      'dashboard.current_plan': 'বর্তমান প্ল্যান',
      'dashboard.active_until': 'মেয়াদ',
      'dashboard.manage_plan': 'প্ল্যান দেখুন',
      'dashboard.payment_pending': 'পেমেন্ট অপেক্ষমাণ রয়েছে',
      'dashboard.payment_pending_desc': 'আপনার একটি পেমেন্ট অপেক্ষমাণ রয়েছে। পেমেন্ট সম্পন্ন করতে ট্রানজ্যাকশন আইডি যাচাই করুন অথবা সহায়তা নিন।',
      'dashboard.verify_trx': 'Verify TrxID',
      'dashboard.contact_support': 'সহায়তা নিন',
      'dashboard.wallet_link': 'ওয়ালেট →',
      'dashboard.continue_reading': 'পড়া চালিয়ে যান',
      'dashboard.smart_desk': 'স্মার্ট স্টাডি ডেস্ক',
      'dashboard.recent_exams': 'সাম্প্রতিক পরীক্ষার ফলাফল',
      'dashboard.leaderboard': 'সাপ্তাহিক লিডারবোর্ড',
      'common.search': 'অনুসন্ধান করুন...',
      'common.refresh': 'রিফ্রেশ',
      'common.free': 'ফ্রি',
      'common.view_all': 'সব দেখুন',
      'common.logout': 'লগআউট',
      'offline.mode': 'অফলাইন মোড',
      'offline.cached_books': 'ডাউনলোডকৃত বইসমূহ',
      'offline.read_offline': 'অফলাইনে পড়ুন',
    },
    'en': {
      'nav.dashboard': 'Dashboard',
      'nav.library': 'Library',
      'nav.bookshelf': 'Bookshelf',
      'nav.ai_chat': 'AI Chat',
      'nav.exams': 'Exams',
      'nav.profile': 'Profile',
      'nav.profile_settings': 'Profile Settings',
      'nav.home': 'Home',
      'nav.question_bank': 'Question Bank',
      'nav.mistakes': 'Mistake Review',
      'nav.flashcards': 'Flashcards',
      'nav.essays': 'Essay Grader',
      'nav.schedules': 'Study Planner',
      'nav.notices': 'Official Notices',
      'nav.admissions': 'Admission Notices',
      'nav.jobs': 'Job News',
      'nav.courses': 'Courses',
      'nav.wallet': 'Wallet',
      'nav.plans': 'Plans & Bundles',
      'nav.leaderboard': 'Leaderboard',
      'nav.referrals': 'Referrals',
      'nav.support': 'Support & Tickets',
      'nav.blog': 'Blog',
      'dashboard.overview': 'STUDENT OVERVIEW',
      'dashboard.welcome': 'Welcome',
      'dashboard.subtitle': "Here's your learning progress at a glance.",
      'dashboard.wallet_balance': 'Wallet Balance',
      'dashboard.books_owned': 'Books Owned',
      'dashboard.exams_taken': 'Exams Taken',
      'dashboard.courses_enrolled': 'Courses Enrolled',
      'dashboard.current_plan': 'CURRENT PLAN',
      'dashboard.active_until': 'Active until',
      'dashboard.manage_plan': 'Manage plan →',
      'dashboard.payment_pending': 'Payment Pending',
      'dashboard.payment_pending_desc': 'You have a payment pending. Verify your transaction ID to complete payment or contact support.',
      'dashboard.verify_trx': 'Verify TrxID',
      'dashboard.contact_support': 'Contact Support',
      'dashboard.wallet_link': 'Wallet →',
      'dashboard.continue_reading': 'Continue Reading',
      'dashboard.smart_desk': 'Smart Study Desk',
      'dashboard.recent_exams': 'Recent Exam Results',
      'dashboard.leaderboard': 'Weekly Leaderboard',
      'common.search': 'Search books, topics...',
      'common.refresh': 'Refresh',
      'common.free': 'Free',
      'common.view_all': 'View All',
      'common.logout': 'Logout',
      'offline.mode': 'Offline Mode',
      'offline.cached_books': 'Downloaded Books',
      'offline.read_offline': 'Read Offline',
    },
  };

  String t(String key, {String? fallback}) {
    final dict = _translations[_languageCode] ?? _translations['bn']!;
    return dict[key] ?? fallback ?? key;
  }
}
