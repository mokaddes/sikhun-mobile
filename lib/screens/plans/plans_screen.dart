import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/api_endpoints.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _plans = [];
  Map<String, dynamic> _customConfig = const {
    'rate_minute': 0.22,
    'rate_image': 1.10,
    'rate_book': 14.0,
    'rate_reupload': 5.0,
    'rate_quiz': 2.5,
    'base_fee': 35.0,
    'min_monthly': 149.0,
  };

  int _generalMonths = 1;
  int _customMonths = 1;
  double _customMinutes = 350;
  double _customImages = 40;
  double _customBooks = 5;
  double _customReuploads = 5;
  double _customQuizzes = 20;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchPlans();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchPlans() async {
    setState(() => _isLoading = true);
    final res = await ApiService.get(ApiEndpoints.publicPlans);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (res.success && res.data is Map) {
        final rawPlans = res.data['plans'] as List? ?? [];
        _plans = rawPlans.whereType<Map<String, dynamic>>().toList();
        if (res.data['custom_plan_config'] is Map<String, dynamic>) {
          _customConfig = res.data['custom_plan_config'] as Map<String, dynamic>;
        }
      }
    });
  }

  int get _customMonthlyTotal {
    final rateMin = double.tryParse((_customConfig['rate_minute'] ?? 0.22).toString()) ?? 0.22;
    final rateImg = double.tryParse((_customConfig['rate_image'] ?? 1.10).toString()) ?? 1.10;
    final rateBook = double.tryParse((_customConfig['rate_book'] ?? 14.0).toString()) ?? 14.0;
    final rateReup = double.tryParse((_customConfig['rate_reupload'] ?? 5.0).toString()) ?? 5.0;
    final rateQuiz = double.tryParse((_customConfig['rate_quiz'] ?? 2.5).toString()) ?? 2.5;
    final baseFee = double.tryParse((_customConfig['base_fee'] ?? 35.0).toString()) ?? 35.0;
    final minMonthly = double.tryParse((_customConfig['min_monthly'] ?? 149.0).toString()) ?? 149.0;

    final raw = (_customMinutes * rateMin) +
        (_customImages * rateImg) +
        (_customBooks * rateBook) +
        (_customReuploads * rateReup) +
        (_customQuizzes * rateQuiz) +
        baseFee;
    return raw < minMonthly ? minMonthly.round() : raw.round();
  }

  double _calculateGeneralPrice(Map<String, dynamic> plan, int months) {
    final monthly = double.tryParse((plan['price_monthly'] ?? 0).toString()) ?? 0.0;
    if (monthly <= 0) return 0.0;
    final factor = switch (months) {
      3 => 0.90,
      6 => 0.80,
      12 => 0.70,
      _ => 1.0,
    };
    return (monthly * months * factor);
  }

  Future<void> _subscribePlan(Map<String, dynamic> plan, String method) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    final int planId = plan['id'] is int ? plan['id'] : int.tryParse(plan['id'].toString()) ?? 0;
    final int planDuration = int.tryParse((plan['duration_months'] ?? 0).toString()) ?? 0;
    final double totalPrice = double.tryParse((plan['price_total'] ?? 0).toString()) ?? 0.0;
    final int months = totalPrice > 0 && planDuration > 0 ? planDuration : _generalMonths;

    setState(() => _isSubmitting = true);
    final res = await ApiService.post(
      ApiEndpoints.subscriptionsPurchase,
      body: {
        'plan_id': planId,
        'months': months,
        'payment_method': method,
      },
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    await _handlePurchaseResponse(res);
  }

  Future<void> _subscribeCustom(String method) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    setState(() => _isSubmitting = true);
    final res = await ApiService.post(
      ApiEndpoints.subscriptionsCustomPurchase,
      body: {
        'months': _customMonths,
        'payment_method': method,
        'custom_config': {
          'minutes': _customMinutes.round(),
          'images': _customImages.round(),
          'books': _customBooks.round(),
          'reuploads': _customReuploads.round(),
          'quizzes': _customQuizzes.round(),
          'total_price': _customMonthlyTotal,
        },
      },
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    await _handlePurchaseResponse(res);
  }

  Future<void> _handlePurchaseResponse(ApiResponse res) async {
    if (res.success && res.data is Map) {
      final redirectUrl = res.data['redirect_url']?.toString();
      if (redirectUrl != null && redirectUrl.isNotEmpty) {
        final uri = Uri.parse(redirectUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
        }
      } else {
        await Provider.of<AuthProvider>(context, listen: false).fetchProfile();
        if (mounted) {
          await Provider.of<DashboardProvider>(context, listen: false).fetchDashboard();
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('সাবস্ক্রিপশন সফলভাবে সক্রিয় হয়েছে!')),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? 'প্ল্যান ক্রয় করা যায়নি।')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeProv = Provider.of<LocaleProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final dash = Provider.of<DashboardProvider>(context).dashboardData;
    final en = !localeProv.isBengali;

    final generalPlans = _plans
        .where((p) => p['target_segment'] == null || p['target_segment'] == 'all' || p['target_segment'] == 'custom')
        .toList();
    final admissionPlans = _plans.where((p) => p['target_segment'] == 'admission').toList();
    final jobPlans = _plans.where((p) => p['target_segment'] == 'job').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(en ? 'Subscription Plans' : 'সাবস্ক্রিপশন প্ল্যান ও বান্ডেল'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: SikhunTheme.primary,
          unselectedLabelColor: SikhunTheme.mutedDark,
          indicatorColor: SikhunTheme.primary,
          tabs: [
            Tab(text: en ? 'General Plans' : 'সাধারণ প্ল্যান'),
            Tab(text: en ? 'Admission Bundles' : 'ভর্তি বান্ডেল'),
            Tab(text: en ? 'Job & BCS Bundles' : 'চাকরি ও বিসিএস'),
            Tab(text: en ? 'Custom Builder' : 'কাস্টম প্ল্যান'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (dash?.activeSubscription != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: SikhunTheme.success.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: SikhunTheme.success.withAlpha(70)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified, color: SikhunTheme.success, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${en ? 'Active Plan' : 'বর্তমান প্ল্যান'}: ${dash!.activeSubscriptionPlan}${dash.activeSubscriptionExpiresAt != null ? ' • ${dash.activeSubscriptionExpiresAt}' : ''}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGeneralTab(generalPlans, auth.isAuthenticated, en),
                      _buildBundleTab(
                        admissionPlans,
                        auth.isAuthenticated,
                        en,
                        bannerTitle: en ? 'University Admission Bundles' : 'বিশ্ববিদ্যালয় ভর্তি প্রস্তুতি বান্ডেল',
                        bannerSub: en
                            ? 'BUET, Medical, DU & GST question banks + negative marking model tests.'
                            : 'ঢাবি, বুয়েট, মেডিকেল ও গুচ্ছ প্রশ্নব্যাংক, নেগেটিভ মার্কিং মডেল টেস্ট এবং AI সমাধান।',
                        accentColor: Colors.orange,
                      ),
                      _buildBundleTab(
                        jobPlans,
                        auth.isAuthenticated,
                        en,
                        bannerTitle: en ? 'BCS & Bank Job Bundles' : 'বিসিএস ও ব্যাংক চাকরি বান্ডেল',
                        bannerSub: en
                            ? 'High-reasoning math analytics, written feedback & unlimited mock tests.'
                            : 'বিসিএস প্রিলি, ব্যাংক ম্যাথ ও লিখিত প্রস্তুতির জন্য পূর্ণাঙ্গ বান্ডেল।',
                        accentColor: Colors.indigo,
                      ),
                      _buildCustomBuilderTab(auth.isAuthenticated, en),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildGeneralTab(List<Map<String, dynamic>> plans, bool isAuth, bool en) {
    return RefreshIndicator(
      onRefresh: _fetchPlans,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [1, 3, 6, 12].map((m) {
              final selected = _generalMonths == m;
              final discount = m == 3 ? ' -10%' : (m == 6 ? ' -20%' : (m == 12 ? ' -30%' : ''));
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text('${en ? '${m}m' : '$m মাস'}$discount'),
                  selected: selected,
                  onSelected: (_) => setState(() => _generalMonths = m),
                  selectedColor: SikhunTheme.primary.withAlpha(35),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          ...plans.map((p) => _buildPlanCard(p, isAuth, en, isBundle: false)),
        ],
      ),
    );
  }

  Widget _buildBundleTab(
    List<Map<String, dynamic>> plans,
    bool isAuth,
    bool en, {
    required String bannerTitle,
    required String bannerSub,
    required Color accentColor,
  }) {
    return RefreshIndicator(
      onRefresh: _fetchPlans,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: accentColor.withAlpha(22),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accentColor.withAlpha(70)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bannerTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(bannerSub, style: const TextStyle(fontSize: 12, color: SikhunTheme.mutedDark)),
              ],
            ),
          ),
          if (plans.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('বর্তমানে কোনো বান্ডেল উপলব্ধ নেই।')),
            )
          else
            ...plans.map((p) => _buildPlanCard(p, isAuth, en, isBundle: true)),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan, bool isAuth, bool en, {required bool isBundle}) {
    final name = (plan['name'] ?? '').toString();
    final badge = plan['badge_text']?.toString();
    final desc = plan['description']?.toString();
    final double totalPrice = double.tryParse((plan['price_total'] ?? 0).toString()) ?? 0.0;
    final int duration = int.tryParse((plan['duration_months'] ?? 1).toString()) ?? 1;
    final double amount = isBundle || totalPrice > 0
        ? (totalPrice > 0 ? totalPrice : (double.tryParse((plan['price_monthly'] ?? 0).toString()) ?? 0.0))
        : _calculateGeneralPrice(plan, _generalMonths);
    final bool isFree = amount <= 0;
    final features = (plan['features'] as List? ?? []).map((e) => e.toString()).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ),
                if (badge != null && badge.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: SikhunTheme.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: SikhunTheme.primary),
                    ),
                  ),
              ],
            ),
            if (desc != null && desc.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(desc, style: const TextStyle(fontSize: 12, color: SikhunTheme.mutedDark)),
            ],
            const SizedBox(height: 12),
            Text(
              isFree
                  ? (en ? 'Free' : 'সম্পূর্ণ ফ্রি')
                  : '৳${amount.round()} ${isBundle ? '($duration মাস)' : '($_generalMonths মাস)'}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: SikhunTheme.primary),
            ),
            const Divider(height: 20),
            ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 16, color: SikhunTheme.success),
                      const SizedBox(width: 8),
                      Expanded(child: Text(f, style: const TextStyle(fontSize: 12.5))),
                    ],
                  ),
                )),
            const SizedBox(height: 12),
            if (isFree)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : () => _subscribePlan(plan, 'free'),
                  style: ElevatedButton.styleFrom(backgroundColor: SikhunTheme.primary, foregroundColor: Colors.white),
                  child: Text(en ? 'Activate Free Plan' : 'ফ্রি প্ল্যান চালু করুন'),
                ),
              )
            else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : () => _subscribePlan(plan, 'mhpay'),
                  style: ElevatedButton.styleFrom(backgroundColor: SikhunTheme.primary, foregroundColor: Colors.white),
                  child: Text(en ? 'Pay with bKash / Nagad (MHPay)' : 'বিকাশ / নগদ দিয়ে কিনুন'),
                ),
              ),
              if (isAuth) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => _subscribePlan(plan, 'wallet'),
                    child: Text(en ? 'Pay with Wallet (৳${amount.round()})' : 'ওয়ালেট ব্যালেন্স দিয়ে কিনুন (৳${amount.round()})'),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCustomBuilderTab(bool isAuth, bool en) {
    final total = _customMonthlyTotal * _customMonths;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  en ? 'Build Your Custom Plan' : 'আপনার প্রয়োজন অনুযায়ী কাস্টম প্ল্যান তৈরি করুন',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                _buildSlider(
                  label: en ? 'AI Chat Minutes / mo' : 'AI চ্যাট মিনিট / মাস',
                  value: _customMinutes,
                  min: 100,
                  max: 2000,
                  divisions: 38,
                  onChanged: (v) => setState(() => _customMinutes = v),
                ),
                _buildSlider(
                  label: en ? 'AI Vision Image Solutions / mo' : 'ছবি তুলে সমাধান / মাস',
                  value: _customImages,
                  min: 10,
                  max: 300,
                  divisions: 29,
                  onChanged: (v) => setState(() => _customImages = v),
                ),
                _buildSlider(
                  label: en ? 'Personal Book Upload Slots' : 'পার্সোনাল বই আপলোড স্লট',
                  value: _customBooks,
                  min: 1,
                  max: 25,
                  divisions: 24,
                  onChanged: (v) => setState(() => _customBooks = v),
                ),
                _buildSlider(
                  label: en ? 'Monthly Book Re-uploads' : 'মাসিক বই পরিবর্তন সীমা',
                  value: _customReuploads,
                  min: 1,
                  max: 25,
                  divisions: 24,
                  onChanged: (v) => setState(() => _customReuploads = v),
                ),
                _buildSlider(
                  label: en ? 'AI Mock Tests / mo' : 'AI মক টেস্ট ও কুইজ / মাস',
                  value: _customQuizzes,
                  min: 5,
                  max: 150,
                  divisions: 29,
                  onChanged: (v) => setState(() => _customQuizzes = v),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [1, 3, 6, 12].map((m) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(en ? '$m mo' : '$m মাস'),
                        selected: _customMonths == m,
                        onSelected: (_) => setState(() => _customMonths = m),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(en ? 'Total Price' : 'মোট মূল্য', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '৳$total',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: SikhunTheme.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : () => _subscribeCustom('mhpay'),
                    style: ElevatedButton.styleFrom(backgroundColor: SikhunTheme.primary, foregroundColor: Colors.white),
                    child: Text(en ? 'Subscribe with bKash / Nagad' : 'বিকাশ / নগদ দিয়ে শুরু করুন'),
                  ),
                ),
                if (isAuth) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () => _subscribeCustom('wallet'),
                      child: Text(en ? 'Pay with Wallet (৳$total)' : 'ওয়ালেট দিয়ে পরিশোধ (৳$total)'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
            Text('${value.round()}', style: const TextStyle(fontWeight: FontWeight.bold, color: SikhunTheme.primary)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: SikhunTheme.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
