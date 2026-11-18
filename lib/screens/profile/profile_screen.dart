import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/api_endpoints.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/question_bank_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/sikhun_brand_logo.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../bookshelf/bookshelf_screen.dart';
import '../community/community_screen.dart';
import '../notifications/notification_screen.dart';
import '../plans/plans_screen.dart';
import '../wallet/wallet_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _launchWeb(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  }

  Future<void> _showEditProfileDialog(BuildContext context, AuthProvider auth) async {
    final user = auth.user;
    if (user == null) return;

    final nameCtrl = TextEditingController(text: user.name);
    final phoneCtrl = TextEditingController(text: user.phone ?? '');
    final instCtrl = TextEditingController(text: user.institution ?? '');
    String selectedType = user.type;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('প্রোফাইল ও স্টাডি লক্ষ্য পরিবর্তন',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'পূর্ণ নাম'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'মোবাইল নম্বর'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: instCtrl,
                  decoration: const InputDecoration(labelText: 'শিক্ষাপ্রতিষ্ঠান'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: const ['admission', 'job', 'hsc', 'ssc', 'university'].contains(selectedType)
                      ? selectedType
                      : 'admission',
                  decoration: const InputDecoration(labelText: 'শিক্ষা বিভাগ / স্টাডি লক্ষ্য'),
                  items: const [
                    DropdownMenuItem(value: 'admission', child: Text('বিশ্ববিদ্যালয় ভর্তি প্রস্তুতি')),
                    DropdownMenuItem(value: 'job', child: Text('বিসিএস ও চাকরি প্রস্তুতি')),
                    DropdownMenuItem(value: 'hsc', child: Text('উচ্চ মাধ্যমিক (HSC)')),
                    DropdownMenuItem(value: 'ssc', child: Text('মাধ্যমিক (SSC)')),
                    DropdownMenuItem(value: 'university', child: Text('বিশ্ববিদ্যালয় একাডেমিক')),
                  ],
                  onChanged: (v) {
                    if (v != null) setS(() => selectedType = v);
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final res = await auth.updateProfile(
                        name: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        institution: instCtrl.text.trim(),
                        type: selectedType,
                      );
                      if (!context.mounted) return;
                      if (res.success) {
                        await context.read<DashboardProvider>().fetchDashboard();
                        if (context.mounted) {
                          await context.read<QuestionBankProvider>().init();
                        }
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              res.success ? 'প্রোফাইল সফলভাবে আপডেট হয়েছে!' : (res.message ?? 'ব্যর্থ হয়েছে'),
                            ),
                            backgroundColor: res.success ? SikhunTheme.success : SikhunTheme.danger,
                          ),
                        );
                      }
                    },
                    child: const Text('সংরক্ষণ করুন'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showChangePasswordDialog(BuildContext context, AuthProvider auth) async {
    final curCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('পাসওয়ার্ড পরিবর্তন'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: curCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'বর্তমান পাসওয়ার্ড'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'নতুন পাসওয়ার্ড (সর্বনিম্ন ৮ অক্ষর)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: confCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'নতুন পাসওয়ার্ড নিশ্চিত করুন'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await auth.updatePassword(
                currentPassword: curCtrl.text,
                password: newCtrl.text,
                passwordConfirmation: confCtrl.text,
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    res.success ? 'পাসওয়ার্ড পরিবর্তন হয়েছে!' : (res.message ?? 'পরিবর্তন ব্যর্থ'),
                  ),
                  backgroundColor: res.success ? SikhunTheme.success : SikhunTheme.danger,
                ),
              );
            },
            child: const Text('আপডেট'),
          ),
        ],
      ),
    );
  }

  Future<void> _showFeedbackDialog(BuildContext context) async {
    final msgCtrl = TextEditingController();
    int rating = 5;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('অ্যাপ ও প্ল্যাটফর্ম সম্পর্কে মতামত'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return IconButton(
                    icon: Icon(
                      i < rating ? Icons.star : Icons.star_border,
                      color: SikhunTheme.primary,
                    ),
                    onPressed: () => setS(() => rating = i + 1),
                  );
                }),
              ),
              TextField(
                controller: msgCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'আপনার পরামর্শ বা মতামত লিখুন...'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
            ElevatedButton(
              onPressed: () async {
                if (msgCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                final res = await ApiService.post(
                  ApiEndpoints.feedback,
                  body: {
                    'type': 'feedback',
                    'rating': rating,
                    'message': msgCtrl.text.trim(),
                  },
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res.success ? 'ধন্যবাদ! আপনার মতামত পাঠানো হয়েছে।' : (res.message ?? 'ব্যর্থ হয়েছে')),
                    backgroundColor: res.success ? SikhunTheme.success : SikhunTheme.danger,
                  ),
                );
              },
              child: const Text('পাঠান'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final themeProv = Provider.of<ThemeProvider>(context);
    final locale = Provider.of<LocaleProvider>(context);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('প্রোফাইল ও সেটিংস'),
        actions: [
          if (auth.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'প্রোফাইল এডিট',
              onPressed: () => _showEditProfileDialog(context, auth),
            ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Brand Identity Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  SikhunBrandLogo(compact: true, markSize: 34, isBangla: locale.isBengali),
                  const Spacer(),
                  const Text('Official App',
                      style: TextStyle(fontSize: 11, color: SikhunTheme.mutedDark)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          if (auth.isAuthenticated && user != null) ...[
            Card(
              elevation: 1.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: SikhunTheme.primary.withAlpha(30),
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'S',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: SikhunTheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.name,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(user.email,
                                  style: const TextStyle(color: SikhunTheme.mutedDark, fontSize: 13)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: SikhunTheme.primary.withAlpha(20),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  user.typeLabelBn,
                                  style: const TextStyle(
                                    color: SikhunTheme.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: SikhunTheme.primary),
                          onPressed: () => _showEditProfileDialog(context, auth),
                        ),
                      ],
                    ),
                    const Divider(height: 26),
                    InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const WalletScreen()),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.account_balance_wallet, color: SikhunTheme.accent),
                              SizedBox(width: 8),
                              Text('ওয়ালেট ব্যালেন্স', style: TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                '৳${user.walletBalance.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: SikhunTheme.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right, size: 18),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Account & Subscriptions Section (Native!)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.workspace_premium_outlined, color: SikhunTheme.primary),
                    title: const Text('সাবস্ক্রিপশন ও কাস্টম প্ল্যান'),
                    subtitle: const Text('সাধারণ, ভর্তি ও চাকরি বান্ডেল দেখুন'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PlansScreen()),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.account_balance_wallet_outlined, color: SikhunTheme.accent),
                    title: const Text('ওয়ালেট, ইনভয়েস ও কুপন রিডিম'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const WalletScreen()),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.bookmarks_outlined, color: Colors.blueAccent),
                    title: const Text('আমার বুকশেলফ ও নিজস্ব PDF বই'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BookshelfScreen()),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.card_giftcard_outlined, color: SikhunTheme.success),
                    title: const Text('রেফারেল ও বোনাস'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CommunityScreen(initialTab: 1)),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.support_agent_outlined, color: SikhunTheme.primary),
                    title: const Text('সাপোর্ট ও হেল্প ডেস্ক'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CommunityScreen(initialTab: 2)),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.lock_reset_outlined, color: SikhunTheme.primary),
                    title: const Text('পাসওয়ার্ড পরিবর্তন করুন'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showChangePasswordDialog(context, auth),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            Card(
              elevation: 1.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.account_circle_outlined, size: 54, color: SikhunTheme.primary),
                    const SizedBox(height: 12),
                    const Text(
                      'শিখুন অ্যাকাউন্টে সাইন-ইন করুন',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'আপনার বই, প্রশ্নব্যাংক, এআই চ্যাট এবং পরীক্ষার অগ্রগতি সংরক্ষণ করতে লগইন করুন।',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: SikhunTheme.mutedDark),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const RegisterScreen()),
                              );
                            },
                            child: const Text('রেজিস্টার'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                              );
                            },
                            child: const Text('লগইন'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Preferences (Dark Mode, Language, Leaderboard Opt-Out)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('ডার্ক মোড (Dark Mode)'),
                  secondary: const Icon(Icons.dark_mode_outlined),
                  value: themeProv.isDarkMode,
                  onChanged: (_) => themeProv.toggleTheme(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('ভাষা (Language)'),
                  subtitle: Text(locale.isBengali ? 'বাংলা' : 'English'),
                  trailing: const Text('পরিবর্তন', style: TextStyle(color: SikhunTheme.primary)),
                  onTap: () => locale.toggleLocale(),
                ),
                if (auth.isAuthenticated && user != null) ...[
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('লিডারবোর্ডে আমার নাম লুকিয়ে রাখুন'),
                    secondary: const Icon(Icons.visibility_off_outlined),
                    value: user.leaderboardOptOut,
                    onChanged: (val) async {
                      final res = await auth.updateLeaderboardOptOut(val);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              res.success ? 'লিডারবোর্ড সেটিংস আপডেট হয়েছে' : (res.message ?? 'ব্যর্থ হয়েছে'),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Support & Policies
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                if (auth.isAuthenticated) ...[
                  ListTile(
                    leading: const Icon(Icons.rate_review_outlined, color: SikhunTheme.primary),
                    title: const Text('মতামত / ফিডব্যাক পাঠান'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showFeedbackDialog(context),
                  ),
                  const Divider(height: 1),
                ],
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: SikhunTheme.primary),
                  title: const Text('প্রাইভেসি পলিসি'),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _launchWeb('${ApiEndpoints.siteUrl}/privacy'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined, color: SikhunTheme.primary),
                  title: const Text('শর্তাবলি (Terms)'),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _launchWeb('${ApiEndpoints.siteUrl}/terms'),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.info_outline, color: SikhunTheme.primary),
                  title: Text('ভার্সন'),
                  subtitle: Text('SIKHUN Mobile v2.0.0 (Production)'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (auth.isAuthenticated)
            ElevatedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('লগআউট'),
                    content: const Text('আপনি কি শিখুন অ্যাপ থেকে লগআউট করতে চান?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('না')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: SikhunTheme.danger),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('হ্যাঁ, লগআউট'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await auth.logout();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: SikhunTheme.danger.withAlpha(25),
                foregroundColor: SikhunTheme.danger,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('লগআউট করুন', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
