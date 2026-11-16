import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_setting_provider.dart';
import '../../providers/notification_provider.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../dashboard/student_dashboard_screen.dart';
import '../notifications/notification_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _openWalletRecharge() async {
    const url = 'https://sikhun.com/wallet';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchUri(String uriString) async {
    final uri = Uri.parse(uriString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final appSetting = Provider.of<AppSettingProvider>(context);
    final notifProv = Provider.of<NotificationProvider>(context);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('প্রোফাইল ও সেটিংস'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User Header
            if (auth.isAuthenticated && user != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: SikhunTheme.primary.withAlpha(30),
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: SikhunTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: const TextStyle(color: SikhunTheme.mutedDark, fontSize: 13),
                    ),
                    if (user.studentType != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: SikhunTheme.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'ক্যাটাগরি: ${user.studentType}',
                          style: const TextStyle(fontSize: 12, color: SikhunTheme.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Wallet Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      SikhunTheme.primary,
                      SikhunTheme.primary.withAlpha(190),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ওয়ালেট ব্যালেন্স',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          Text(
                            '৳${user.walletBalance.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: SikhunTheme.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      onPressed: _openWalletRecharge,
                      child: const Text('রিচার্জ', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              // Guest Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.account_circle_outlined, size: 64, color: SikhunTheme.primary),
                    const SizedBox(height: 12),
                    const Text(
                      'অ্যাকাউন্টে প্রবেশ করুন',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'বই বুকশেলফে যোগ করা, ওয়ালেট ব্যবহার এবং শিক্ষার্থী ড্যাশবোর্ডে প্রবেশ করতে লগইন করুন',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: SikhunTheme.mutedDark, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const RegisterScreen()),
                              );
                            },
                            child: const Text('রেজিস্ট্রেশন'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Student Dashboard & Notifications Options
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  if (auth.isAuthenticated) ...[
                    ListTile(
                      leading: const Icon(Icons.dashboard_customize_outlined, color: Color(0xFF78350F)),
                      title: const Text('শিক্ষার্থী ড্যাশবোর্ড', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('পড়াশোনা, পরিসংখ্যান, ভুল খাতা ও লিডারবোর্ড'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const StudentDashboardScreen()),
                        );
                      },
                    ),
                    const Divider(height: 1),
                  ],
                  ListTile(
                    leading: const Icon(Icons.notifications_active_outlined, color: SikhunTheme.primary),
                    title: const Text('নোটিফিকেশন সেন্টার'),
                    subtitle: notifProv.unreadCount > 0
                        ? Text('${notifProv.unreadCount} টি অপঠিত নোটিফিকেশন', style: const TextStyle(color: Colors.redAccent, fontSize: 12))
                        : const Text('সর্বশেষ আপডেট ও ফলাফল'),
                    trailing: notifProv.unreadCount > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(10)),
                            child: Text(
                              '${notifProv.unreadCount}',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          )
                        : const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const NotificationScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Sikhun Platform Links & Support
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.language, color: SikhunTheme.primary),
                    title: const Text('ওয়েবসাইট ভিজিট করুন'),
                    subtitle: const Text('sikhun.com'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () => _launchUri('https://sikhun.com'),
                  ),
                  if (appSetting.settings.sitePhone != null && appSetting.settings.sitePhone!.isNotEmpty) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.phone_outlined, color: SikhunTheme.primary),
                      title: const Text('হেল্পলাইন'),
                      subtitle: Text(appSetting.settings.sitePhone!),
                      trailing: const Icon(Icons.call_outlined, size: 18),
                      onTap: () => _launchUri('tel:${appSetting.settings.sitePhone}'),
                    ),
                  ],
                  if (appSetting.settings.siteEmail != null && appSetting.settings.siteEmail!.isNotEmpty) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.email_outlined, color: SikhunTheme.primary),
                      title: const Text('সাপোর্ট ইমেইল'),
                      subtitle: Text(appSetting.settings.siteEmail!),
                      trailing: const Icon(Icons.mail_outline, size: 18),
                      onTap: () => _launchUri('mailto:${appSetting.settings.siteEmail}'),
                    ),
                  ],
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.policy_outlined, color: SikhunTheme.primary),
                    title: const Text('গোপনীয়তা নীতি ও শর্তাবলী'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () => _launchUri('https://sikhun.com/terms'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.info_outline, color: SikhunTheme.primary),
                    title: const Text('অ্যাপ সম্পর্কে'),
                    subtitle: Text('Sikhun Mobile v${appSetting.settings.appVersion}'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: appSetting.siteName,
                        applicationVersion: appSetting.settings.appVersion,
                        applicationIcon: (appSetting.logoUrl != null && appSetting.logoUrl!.isNotEmpty)
                            ? CachedNetworkImage(
                                imageUrl: appSetting.logoUrl!,
                                width: 44,
                                height: 44,
                                fit: BoxFit.contain,
                              )
                            : const Icon(Icons.auto_stories, color: SikhunTheme.primary, size: 40),
                        children: [
                          Text('${appSetting.siteTagline}\nশিখুন বাংলাদেশের একটি আধুনিক স্মার্ট লার্নিং ও রিডিং প্ল্যাটফর্ম।'),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Dynamic Branding Footer
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  if (appSetting.logoUrl != null && appSetting.logoUrl!.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: appSetting.logoUrl!,
                      height: 28,
                      fit: BoxFit.contain,
                      errorWidget: (c, u, e) => const SizedBox(),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    appSetting.siteTagline,
                    style: const TextStyle(fontSize: 12, color: SikhunTheme.mutedDark),
                  ),
                ],
              ),
            ),

            if (auth.isAuthenticated) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout, color: SikhunTheme.danger),
                  label: const Text('লগআউট করুন', style: TextStyle(color: SikhunTheme.danger, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: SikhunTheme.danger),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('লগআউট'),
                        content: const Text('আপনি কি নিশ্চিত যে লগআউট করতে চান?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('না'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: SikhunTheme.danger),
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              auth.logout();
                            },
                            child: const Text('লগআউট'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
