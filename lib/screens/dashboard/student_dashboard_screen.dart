import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../library/book_details_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).fetchDashboard();
    });
  }

  Future<void> _openWeb(String path) async {
    final uri = Uri.parse('https://sikhun.com$path');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final dashProv = Provider.of<DashboardProvider>(context);
    final user = auth.user;
    final data = dashProv.dashboardData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('শিক্ষার্থী ড্যাশবোর্ড'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'রিফ্রেশ',
            onPressed: () => dashProv.fetchDashboard(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await auth.fetchProfile();
          await dashProv.fetchDashboard();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Overview Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      SikhunTheme.primary,
                      SikhunTheme.primaryDark,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: SikhunTheme.primary.withAlpha(80),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white.withAlpha(40),
                          child: Text(
                            user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'S',
                            style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.name ?? 'শিক্ষার্থী',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'ক্যাটাগরি: ${user?.studentType ?? "সাধারণ"} • স্টাডি ডেস্ক',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.verified, color: Colors.white, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'সাবস্ক্রিপশন স্ট্যাটাস:',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                          Text(
                            data?.activeSubscription != null ? 'সক্রিয় প্ল্যান' : 'ফ্রি মেম্বার',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 4 Stat Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      label: 'ওয়ালেট ব্যালেন্স',
                      value: '৳${(data?.stats.walletBalance ?? user?.walletBalance ?? 0.0).toStringAsFixed(0)}',
                      icon: Icons.account_balance_wallet_outlined,
                      color: SikhunTheme.primary,
                      onTap: () => _openWeb('/wallet'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      label: 'সংগৃহীত বই',
                      value: '${data?.stats.booksOwned ?? 0} টি',
                      icon: Icons.menu_book_outlined,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      label: 'মডেল টেস্ট',
                      value: '${data?.stats.examsTaken ?? 0} টি',
                      icon: Icons.quiz_outlined,
                      color: SikhunTheme.accent,
                      onTap: () => _openWeb('/exams'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      label: 'এনরোল করা কোর্স',
                      value: '${data?.stats.coursesEnrolled ?? 0} টি',
                      icon: Icons.school_outlined,
                      color: Colors.orange.shade800,
                      onTap: () => _openWeb('/courses'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick Action Tools Grid
              const Text(
                'স্টাডি ডেস্ক টুলস',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.05,
                children: [
                  _buildToolAction(
                    icon: Icons.quiz_outlined,
                    label: 'মডেল টেস্ট',
                    color: Colors.indigo,
                    onTap: () => _openWeb('/exams/create'),
                  ),
                  _buildToolAction(
                    icon: Icons.style_outlined,
                    label: 'ফ্ল্যাশ কার্ড',
                    color: Colors.teal,
                    onTap: () => _openWeb('/flashcards'),
                  ),
                  _buildToolAction(
                    icon: Icons.calendar_month_outlined,
                    label: 'স্টাডি প্ল্যানার',
                    color: Colors.purple,
                    onTap: () => _openWeb('/schedules'),
                  ),
                  _buildToolAction(
                    icon: Icons.highlight_off,
                    label: 'ভুল খাতা',
                    color: Colors.red.shade700,
                    onTap: () => _openWeb('/mistakes'),
                  ),
                  _buildToolAction(
                    icon: Icons.campaign_outlined,
                    label: 'ভর্তি বিজ্ঞপ্তি',
                    color: Colors.amber.shade900,
                    onTap: () => _openWeb('/admission-notice'),
                  ),
                  _buildToolAction(
                    icon: Icons.work_outline,
                    label: 'চাকরির খবর',
                    color: Colors.blueGrey,
                    onTap: () => _openWeb('/job-news'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Continue Reading Card
              if (data?.continueReading != null) ...[
                const Text(
                  'পড়া চালিয়ে যান (বই)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 60,
                            height: 80,
                            color: Colors.grey.shade200,
                            child: data!.continueReading!.coverImage != null
                                ? CachedNetworkImage(
                                    imageUrl: data.continueReading!.coverImage!,
                                    fit: BoxFit.cover,
                                    errorWidget: (c, u, e) => const Icon(Icons.book),
                                  )
                                : const Icon(Icons.book),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data.continueReading!.bookTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'বর্তমান পৃষ্ঠা: ${data.continueReading!.currentPage} / ${data.continueReading!.totalPages}',
                                style: const TextStyle(fontSize: 12, color: SikhunTheme.mutedDark),
                              ),
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                value: data.continueReading!.progress / 100.0,
                                backgroundColor: Colors.grey.shade300,
                                valueColor: const AlwaysStoppedAnimation<Color>(SikhunTheme.primary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BookDetailsScreen(bookId: data.continueReading!.bookId),
                              ),
                            );
                          },
                          child: const Text('পড়ুন'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Recent Exams
              if (data?.recentExams.isNotEmpty == true) ...[
                const Text(
                  'সাম্প্রতিক মডেল টেস্ট ফলাফল',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ...data!.recentExams.take(3).map((exam) {
                  final score = exam['score'] ?? 0;
                  final total = exam['total'] ?? 0;
                  final pct = exam['percentage'] ?? (total > 0 ? ((score / total) * 100).round() : 0);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: pct >= 60 ? SikhunTheme.accent.withAlpha(30) : Colors.orange.withAlpha(30),
                        child: Text(
                          '$pct%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: pct >= 60 ? SikhunTheme.accent : Colors.orange.shade800,
                          ),
                        ),
                      ),
                      title: Text('পরীক্ষা #${exam['id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text('স্কোর: $score / $total', style: const TextStyle(fontSize: 12, color: SikhunTheme.mutedDark)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () => _openWeb('/exams/${exam['id']}/result'),
                    ),
                  );
                }),
                const SizedBox(height: 20),
              ],

              // Weekly Leaderboard
              if (data?.leaderboardTop.isNotEmpty == true) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'সাপ্তাহিক লিডারবোর্ড',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () => _openWeb('/leaderboard'),
                      child: const Text('সম্পূর্ণ তালিকা'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    children: data!.leaderboardTop.take(3).map((student) {
                      final rank = student['rank'] ?? 1;
                      final medals = ['🥇', '🥈', '🥉'];
                      final medal = (rank is int && rank >= 1 && rank <= 3) ? medals[rank - 1] : '#$rank';

                      return ListTile(
                        leading: Text(medal, style: const TextStyle(fontSize: 20)),
                        title: Text(student['name']?.toString() ?? 'শিক্ষার্থী', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text('${student['points'] ?? 0} পয়েন্ট', style: const TextStyle(fontSize: 11, color: SikhunTheme.mutedDark)),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: SikhunTheme.mutedDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
