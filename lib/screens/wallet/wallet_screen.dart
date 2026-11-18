import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/api_endpoints.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class WalletScreen extends StatefulWidget {
  final int? verifyOrderId;

  const WalletScreen({super.key, this.verifyOrderId});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _couponCtrl = TextEditingController();

  bool _isLoading = true;
  bool _isAction = false;
  double _balance = 0;
  List<Map<String, dynamic>> _pendingOrders = [];
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _invoices = [];
  Map<String, dynamic> _accessStatus = {};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadAll().then((_) {
      if (widget.verifyOrderId != null && mounted) {
        final match = _pendingOrders.firstWhere(
          (o) => o['id'].toString() == widget.verifyOrderId.toString(),
          orElse: () => {'id': widget.verifyOrderId, 'order_number': '#${widget.verifyOrderId}'},
        );
        _showVerifyOrderDialog(match);
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _couponCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      ApiService.get(ApiEndpoints.wallet),
      ApiService.get(ApiEndpoints.walletTransactions),
      ApiService.get(ApiEndpoints.invoices),
      ApiService.get(ApiEndpoints.accessStatus),
    ]);

    if (!mounted) return;
    final walletRes = results[0];
    final txRes = results[1];
    final invRes = results[2];
    final accRes = results[3];

    setState(() {
      if (walletRes.success && walletRes.data is Map<String, dynamic>) {
        _balance = double.tryParse(walletRes.data['balance']?.toString() ?? '0') ?? 0;
        _pendingOrders = (walletRes.data['pending_orders'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
      }
      if (txRes.success && txRes.data != null) {
        final rawTx = txRes.data is List
            ? txRes.data as List
            : (txRes.data is Map && txRes.data['data'] is List ? txRes.data['data'] as List : []);
        _transactions = rawTx.whereType<Map<String, dynamic>>().toList();
      }
      if (invRes.success && invRes.data != null) {
        final rawInv = invRes.data is List
            ? invRes.data as List
            : (invRes.data is Map && invRes.data['data'] is List ? invRes.data['data'] as List : []);
        _invoices = rawInv.whereType<Map<String, dynamic>>().toList();
      }
      if (accRes.success && accRes.data is Map<String, dynamic>) {
        _accessStatus = accRes.data as Map<String, dynamic>;
      }
      _isLoading = false;
    });
  }

  Future<void> _showRechargeDialog() async {
    final amountCtrl = TextEditingController(text: '200');
    final trxCtrl = TextEditingController();
    String method = 'mhpay';

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ওয়ালেট রিচার্জ করুন', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'পরিমাণ (সর্বনিম্ন ৫০ টাকা)',
                  prefixText: '৳ ',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: method,
                decoration: const InputDecoration(labelText: 'পেমেন্ট মাধ্যম'),
                items: const [
                  DropdownMenuItem(value: 'mhpay', child: Text('MHPay (bKash / Nagad / Rocket)')),
                  DropdownMenuItem(value: 'zinipay', child: Text('ZiniPay অনলাইন')),
                  DropdownMenuItem(value: 'manual', child: Text('ম্যানুয়াল ট্রান্সফার (TrxID)')),
                ],
                onChanged: (v) {
                  if (v != null) setS(() => method = v);
                },
              ),
              if (method == 'manual') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: trxCtrl,
                  decoration: const InputDecoration(labelText: 'Transaction ID (TrxID)'),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final amt = double.tryParse(amountCtrl.text.trim()) ?? 0;
                    if (amt < 50) return;
                    Navigator.pop(ctx);
                    await _submitRecharge(amt, method, trxCtrl.text.trim());
                  },
                  child: const Text('রিচার্জ শুরু করুন'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitRecharge(double amount, String method, String trx) async {
    setState(() => _isAction = true);
    final res = await ApiService.post(
      ApiEndpoints.walletRecharge,
      body: {
        'amount': amount,
        'method': method,
        if (method == 'manual' && trx.isNotEmpty) 'transaction_reference': trx,
      },
    );
    if (!mounted) return;
    setState(() => _isAction = false);

    if (res.success) {
      if (res.data is Map && res.data['redirect_url'] != null) {
        final uri = Uri.tryParse(res.data['redirect_url'].toString());
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
        }
      }
      await context.read<AuthProvider>().fetchProfile();
      await _loadAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message ?? 'রিচার্জ অনুরোধ গৃহীত হয়েছে'), backgroundColor: SikhunTheme.success),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? 'রিচার্জ ব্যর্থ হয়েছে'), backgroundColor: SikhunTheme.danger),
      );
    }
  }

  Future<void> _showVerifyOrderDialog(Map<String, dynamic> order) async {
    final trxCtrl = TextEditingController(
      text: order['gateway_transaction_id']?.toString() ?? '',
    );
    final orderId = int.tryParse(order['id'].toString()) ?? 0;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('অর্ডার যাচাই (${order['order_number'] ?? '#$orderId'})'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('পেমেন্ট সম্পন্ন হয়ে থাকলে TrxID দিন বা সরাসরি যাচাই করুন:'),
            const SizedBox(height: 12),
            TextField(
              controller: trxCtrl,
              decoration: const InputDecoration(labelText: 'Transaction ID (ঐচ্ছিক)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বন্ধ')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await ApiService.post(
                ApiEndpoints.verifyOrder(orderId),
                body: {
                  if (trxCtrl.text.trim().isNotEmpty) 'transaction_id': trxCtrl.text.trim(),
                },
              );
              if (!mounted) return;
              await context.read<AuthProvider>().fetchProfile();
              await _loadAll();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(res.message ?? 'যাচাই সম্পন্ন'),
                  backgroundColor: res.success ? SikhunTheme.success : SikhunTheme.danger,
                ),
              );
            },
            child: const Text('যাচাই করুন'),
          ),
        ],
      ),
    );
  }

  Future<void> _redeemCoupon() async {
    final code = _couponCtrl.text.trim();
    if (code.isEmpty) return;

    setState(() => _isAction = true);
    final res = await ApiService.post(ApiEndpoints.accessRedeem, body: {'code': code});
    if (!mounted) return;
    setState(() => _isAction = false);

    if (res.success) {
      _couponCtrl.clear();
      await context.read<AuthProvider>().fetchProfile();
      await _loadAll();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('কুপন কোড সফলভাবে অ্যাক্টিভেট হয়েছে!'), backgroundColor: SikhunTheme.success),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? 'কুপন কোডটি সঠিক নয়'), backgroundColor: SikhunTheme.danger),
      );
    }
  }

  Future<void> _payInvoice(int id) async {
    final method = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('ইনভয়েস পরিশোধ মাধ্যম', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet),
                title: const Text('ওয়ালেট ব্যালেন্স দিয়ে'),
                onTap: () => Navigator.pop(ctx, 'wallet'),
              ),
              ListTile(
                leading: const Icon(Icons.payment),
                title: const Text('MHPay (bKash / Nagad)'),
                onTap: () => Navigator.pop(ctx, 'mhpay'),
              ),
              ListTile(
                leading: const Icon(Icons.credit_card),
                title: const Text('ZiniPay'),
                onTap: () => Navigator.pop(ctx, 'zinipay'),
              ),
            ],
          ),
        ),
      ),
    );
    if (method == null || !mounted) return;

    final res = await ApiService.post(ApiEndpoints.payInvoice(id), body: {'payment_method': method});
    if (!mounted) return;
    if (res.success) {
      if (res.data is Map && res.data['redirect_url'] != null) {
        final uri = Uri.tryParse(res.data['redirect_url'].toString());
        if (uri != null) await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      }
      await context.read<AuthProvider>().fetchProfile();
      await _loadAll();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? 'ইনভয়েস পরিশোধ হয়েছে!'), backgroundColor: SikhunTheme.success),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? 'পেমেন্ট ব্যর্থ'), backgroundColor: SikhunTheme.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ওয়ালেট, অর্ডার ও কুপন')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Balance Hero Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [SikhunTheme.primary, SikhunTheme.accent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('বর্তমান ওয়ালেট ব্যালেন্স', style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 6),
                        Text(
                          '৳${_balance.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          onPressed: _isAction ? null : _showRechargeDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: SikhunTheme.primary,
                          ),
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('টাকা রিচার্জ করুন'),
                        ),
                      ],
                    ),
                  ),

                  // Pending Orders
                  if (_pendingOrders.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('অপেক্ষমাণ অর্ডারসমূহ',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    ..._pendingOrders.map((o) => Card(
                          color: SikhunTheme.warning.withAlpha(20),
                          child: ListTile(
                            title: Text('${o['order_number'] ?? 'Order'} • ৳${o['amount']}'),
                            subtitle: Text('মাধ্যম: ${o['payment_method']}'),
                            trailing: ElevatedButton(
                              onPressed: () => _showVerifyOrderDialog(o),
                              style: ElevatedButton.styleFrom(backgroundColor: SikhunTheme.warning),
                              child: const Text('যাচাই'),
                            ),
                          ),
                        )),
                  ],

                  // Coupon Redeem Card
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ফ্রি অ্যাক্সেস / কুপন কোড রিডিম',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          if (_accessStatus['active_grant_label'] != null) ...[
                            const SizedBox(height: 4),
                            Text('সক্রিয় ক্যাম্পেইন: ${_accessStatus['active_grant_label']}',
                                style: const TextStyle(color: SikhunTheme.success, fontSize: 12)),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _couponCtrl,
                                  decoration: const InputDecoration(hintText: 'কুপন কোড লিখুন...'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _isAction ? null : _redeemCoupon,
                                child: const Text('রিডিম'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TabBar(
                    controller: _tabCtrl,
                    labelColor: SikhunTheme.primary,
                    tabs: const [
                      Tab(text: 'লেনদেন (Transactions)'),
                      Tab(text: 'ইনভয়েস (Invoices)'),
                    ],
                  ),
                  SizedBox(
                    height: 360,
                    child: TabBarView(
                      controller: _tabCtrl,
                      children: [
                        _transactions.isEmpty
                            ? const Center(child: Text('কোনো লেনদেন পাওয়া যায়নি'))
                            : ListView.separated(
                                padding: const EdgeInsets.only(top: 10),
                                itemCount: _transactions.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (_, i) {
                                  final t = _transactions[i];
                                  final type = t['type']?.toString() ?? '';
                                  final isCredit = type == 'credit' || type == 'recharge' || type == 'refund';
                                  return ListTile(
                                    leading: Icon(
                                      isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                                      color: isCredit ? SikhunTheme.success : SikhunTheme.danger,
                                    ),
                                    title: Text(t['description']?.toString() ?? type,
                                        style: const TextStyle(fontSize: 13)),
                                    subtitle: Text((t['created_at'] ?? '').toString().split('T').first,
                                        style: const TextStyle(fontSize: 11)),
                                    trailing: Text(
                                      '${isCredit ? '+' : '-'}৳${t['amount']}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isCredit ? SikhunTheme.success : SikhunTheme.danger,
                                      ),
                                    ),
                                  );
                                },
                              ),
                        _invoices.isEmpty
                            ? const Center(child: Text('কোনো ইনভয়েস পাওয়া যায়নি'))
                            : ListView.builder(
                                padding: const EdgeInsets.only(top: 10),
                                itemCount: _invoices.length,
                                itemBuilder: (_, i) {
                                  final inv = _invoices[i];
                                  final status = inv['status']?.toString() ?? '';
                                  final unpaid = status == 'sent' || status == 'overdue' || status == 'draft';
                                  return Card(
                                    child: ListTile(
                                      title: Text('${inv['invoice_number'] ?? '#INV'} • ৳${inv['total']}'),
                                      subtitle: Text('স্ট্যাটাস: $status'),
                                      trailing: unpaid
                                          ? ElevatedButton(
                                              onPressed: () => _payInvoice(int.parse(inv['id'].toString())),
                                              child: const Text('পরিশোধ'),
                                            )
                                          : const Icon(Icons.check_circle, color: SikhunTheme.success),
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
