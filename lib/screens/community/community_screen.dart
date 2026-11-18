import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/api_endpoints.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class CommunityScreen extends StatefulWidget {
  final int initialTab;

  const CommunityScreen({super.key, this.initialTab = 0});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('লিডারবোর্ড, রেফারেল ও সাপোর্ট'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(icon: Icon(Icons.leaderboard_outlined), text: 'লিডারবোর্ড'),
            Tab(icon: Icon(Icons.card_giftcard_outlined), text: 'রেফারেল'),
            Tab(icon: Icon(Icons.support_agent_outlined), text: 'সাপোর্ট'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          _LeaderboardTab(),
          _ReferralsTab(),
          _SupportTab(),
        ],
      ),
    );
  }
}

// ======================= TAB 1: LEADERBOARD =======================
class _LeaderboardTab extends StatefulWidget {
  const _LeaderboardTab();

  @override
  State<_LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<_LeaderboardTab> {
  String _period = 'weekly';
  String _type = '';
  bool _isLoading = true;
  List<Map<String, dynamic>> _entries = [];
  Map<String, dynamic>? _myRank;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final params = <String, dynamic>{'period': _period};
    if (_type.isNotEmpty) params['type'] = _type;

    final results = await Future.wait([
      ApiService.get(ApiEndpoints.leaderboard, queryParams: params),
      ApiService.get(ApiEndpoints.leaderboardMyRank, queryParams: params),
    ]);
    if (!mounted) return;

    setState(() {
      if (results[0].success && results[0].data is List) {
        _entries = (results[0].data as List).whereType<Map<String, dynamic>>().toList();
      } else {
        _entries = [];
      }
      _myRank = results[1].success && results[1].data is Map<String, dynamic>
          ? results[1].data as Map<String, dynamic>
          : null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _periodChip('weekly', 'সাপ্তাহিক'),
              const SizedBox(width: 6),
              _periodChip('monthly', 'মাসিক'),
              const SizedBox(width: 6),
              _periodChip('all_time', 'সর্বকাল'),
              const Spacer(),
              DropdownButton<String>(
                value: _type,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: '', child: Text('সকল স্ট্রিম', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'admission', child: Text('ভর্তি', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'job', child: Text('চাকরি', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'hsc', child: Text('HSC', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'ssc', child: Text('SSC', style: TextStyle(fontSize: 12))),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _type = v);
                    _load();
                  }
                },
              ),
            ],
          ),
        ),
        if (_myRank != null)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [SikhunTheme.primary, SikhunTheme.accent]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('আপনার অবস্থান', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text('#${_myRank!['rank']} র‍্যাংক',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                Text(
                  '${_myRank!['percentage']}% (${_myRank!['score']}/${_myRank!['total']})',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _entries.isEmpty
                  ? const Center(child: Text('এখনো লিডারবোর্ডে কোনো ফলাফল নেই'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _entries.length,
                        itemBuilder: (_, i) {
                          final e = _entries[i];
                          final rank = e['rank'] ?? (i + 1);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: rank == 1
                                    ? Colors.amber
                                    : rank == 2
                                        ? Colors.grey.shade400
                                        : rank == 3
                                            ? Colors.brown.shade300
                                            : SikhunTheme.primary.withAlpha(25),
                                child: Text(
                                  '$rank',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: rank <= 3 ? Colors.white : SikhunTheme.primary,
                                  ),
                                ),
                              ),
                              title: Text(e['name']?.toString() ?? 'শিক্ষার্থী',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('স্কোর: ${e['score']}/${e['total']} • ${(e['type'] ?? '').toString().toUpperCase()}'),
                              trailing: Text(
                                '${e['percentage']}%',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15, color: SikhunTheme.primary),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _periodChip(String val, String label) {
    final selected = _period == val;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      selectedColor: SikhunTheme.primary,
      labelStyle: TextStyle(color: selected ? Colors.white : null),
      onSelected: (_) {
        setState(() => _period = val);
        _load();
      },
    );
  }
}

// ======================= TAB 2: REFERRALS =======================
class _ReferralsTab extends StatefulWidget {
  const _ReferralsTab();

  @override
  State<_ReferralsTab> createState() => _ReferralsTabState();
}

class _ReferralsTabState extends State<_ReferralsTab> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _referrals = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      ApiService.get(ApiEndpoints.referralsStats),
      ApiService.get(ApiEndpoints.referrals),
    ]);
    if (!mounted) return;
    setState(() {
      if (results[0].success && results[0].data is Map<String, dynamic>) {
        _stats = results[0].data as Map<String, dynamic>;
      }
      if (results[1].success && results[1].data is List) {
        _referrals = (results[1].data as List).whereType<Map<String, dynamic>>().toList();
      }
      _isLoading = false;
    });
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label কপি করা হয়েছে: $text'), backgroundColor: SikhunTheme.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    final code = _stats['referral_code']?.toString() ?? 'N/A';
    final link = _stats['referral_link']?.toString() ?? '';

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: SikhunTheme.primary.withAlpha(15),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('বন্ধুদের আমন্ত্রণ জানান এবং ওয়ালেট বোনাস জিতুন!',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('কোড: $code',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _copy(code, 'রেফারেল কোড'),
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('কপি'),
                      ),
                    ],
                  ),
                  if (link.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => _copy(link, 'রেফারেল লিংক'),
                      icon: const Icon(Icons.share, size: 16),
                      label: const Text('রেফারেল লিংক কপি করুন'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _miniStat('ক্লিক', '${_stats['clicks'] ?? 0}'),
              const SizedBox(width: 8),
              _miniStat('রেজিস্ট্রেশন', '${_stats['total_referred'] ?? 0}'),
              const SizedBox(width: 8),
              _miniStat('আয়', '৳${_stats['total_earned'] ?? 0}'),
            ],
          ),
          const SizedBox(height: 18),
          const Text('রেফার করা শিক্ষার্থীরা', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          if (_referrals.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('এখনো কেউ আপনার রেফারেল কোড ব্যবহার করেনি।', textAlign: TextAlign.center),
              ),
            )
          else
            ..._referrals.map((r) {
              final refName = r['referee'] is Map ? r['referee']['name']?.toString() : 'শিক্ষার্থী';
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: Text(refName ?? 'শিক্ষার্থী'),
                subtitle: Text('স্ট্যাটাস: ${r['status'] ?? 'pending'}'),
                trailing: Text('৳${r['referrer_reward'] ?? 0}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: SikhunTheme.success)),
              );
            }),
        ],
      ),
    );
  }

  Widget _miniStat(String l, String v) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Text(v, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: SikhunTheme.primary)),
              const SizedBox(height: 2),
              Text(l, style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================= TAB 3: SUPPORT & TICKETS =======================
class _SupportTab extends StatefulWidget {
  const _SupportTab();

  @override
  State<_SupportTab> createState() => _SupportTabState();
}

class _SupportTabState extends State<_SupportTab> {
  final _msgCtrl = TextEditingController();
  bool _isLoading = true;
  bool _isSending = false;
  List<Map<String, dynamic>> _botMessages = [];
  List<Map<String, dynamic>> _tickets = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      ApiService.get(ApiEndpoints.supportConversation),
      ApiService.get(ApiEndpoints.supportTickets),
    ]);
    if (!mounted) return;
    setState(() {
      if (results[0].success && results[0].data is Map<String, dynamic>) {
        _botMessages = (results[0].data['messages'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
      }
      if (results[1].success && results[1].data != null) {
        final rawT = results[1].data is List
            ? results[1].data as List
            : (results[1].data is Map && results[1].data['data'] is List ? results[1].data['data'] as List : []);
        _tickets = rawT.whereType<Map<String, dynamic>>().toList();
      }
      _isLoading = false;
    });
  }

  Future<void> _sendBotMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isSending) return;
    _msgCtrl.clear();
    setState(() => _isSending = true);

    final res = await ApiService.post(
      ApiEndpoints.supportMessage,
      body: {'message': text, 'locale': 'bn'},
    );
    if (!mounted) return;
    setState(() => _isSending = false);
    if (res.success && res.data is Map<String, dynamic>) {
      setState(() {
        _botMessages = (res.data['messages'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
      });
    }
  }

  Future<void> _createTicketDialog() async {
    final subCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('সাপোর্ট টিকিট খুলুন'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: subCtrl, decoration: const InputDecoration(labelText: 'বিষয়')),
            const SizedBox(height: 10),
            TextField(
              controller: bodyCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'সমস্যার বিবরণ'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
          ElevatedButton(
            onPressed: () async {
              if (subCtrl.text.trim().isEmpty || bodyCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final res = await ApiService.post(
                ApiEndpoints.supportTickets,
                body: {
                  'subject': subCtrl.text.trim(),
                  'message': bodyCtrl.text.trim(),
                  'category': 'general',
                },
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(res.message ?? 'টিকিট তৈরি হয়েছে'),
                  backgroundColor: res.success ? SikhunTheme.success : SikhunTheme.danger,
                ),
              );
              if (res.success) _load();
            },
            child: const Text('জমা দিন'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('তাৎক্ষণিক সাপোর্ট বট', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: () async {
                        final res = await ApiService.post(ApiEndpoints.supportHandoff);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(res.message ?? 'হ্যান্ডঅফ টিকিট তৈরি হয়েছে')),
                        );
                        _load();
                      },
                      icon: const Icon(Icons.person_outline, size: 16),
                      label: const Text('টিমকে পাঠান', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const Divider(),
                SizedBox(
                  height: 220,
                  child: _botMessages.isEmpty
                      ? const Center(child: Text('আপনার প্রশ্ন লিখুন, সাপোর্ট বট উত্তর দেবে।'))
                      : ListView.builder(
                          itemCount: _botMessages.length,
                          itemBuilder: (_, i) {
                            final m = _botMessages[i];
                            final isMe = m['sender_type'] == 'student';
                            return Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? SikhunTheme.primary
                                      : SikhunTheme.primary.withAlpha(20),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  m['message']?.toString() ?? '',
                                  style: TextStyle(
                                      fontSize: 13, color: isMe ? Colors.white : null),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _msgCtrl,
                        decoration: const InputDecoration(hintText: 'বার্তা লিখুন...'),
                        onSubmitted: (_) => _sendBotMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _isSending ? null : _sendBotMessage,
                      icon: const Icon(Icons.send, color: SikhunTheme.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('সাপোর্ট টিকিটসমূহ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: _createTicketDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('নতুন টিকিট'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_tickets.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('কোনো সাপোর্ট টিকিট নেই।', textAlign: TextAlign.center),
            ),
          )
        else
          ..._tickets.map((t) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(t['subject']?.toString() ?? 'Ticket',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('স্ট্যাটাস: ${t['status'] ?? 'open'}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _TicketChatScreen(ticketId: int.parse(t['id'].toString())),
                    ),
                  ),
                ),
              )),
      ],
    );
  }
}

class _TicketChatScreen extends StatefulWidget {
  final int ticketId;

  const _TicketChatScreen({required this.ticketId});

  @override
  State<_TicketChatScreen> createState() => _TicketChatScreenState();
}

class _TicketChatScreenState extends State<_TicketChatScreen> {
  final _ctrl = TextEditingController();
  bool _isLoading = true;
  Map<String, dynamic>? _ticket;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final res = await ApiService.get(ApiEndpoints.supportTicketDetails(widget.ticketId));
    if (!mounted) return;
    setState(() {
      if (res.success && res.data is Map<String, dynamic>) {
        _ticket = res.data as Map<String, dynamic>;
      }
      _isLoading = false;
    });
  }

  Future<void> _reply() async {
    final msg = _ctrl.text.trim();
    if (msg.isEmpty) return;
    _ctrl.clear();
    final res = await ApiService.post(
      ApiEndpoints.supportTicketReply(widget.ticketId),
      body: {'message': msg},
    );
    if (!mounted) return;
    if (res.success) _load();
  }

  @override
  Widget build(BuildContext context) {
    final msgs = (_ticket?['messages'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
    return Scaffold(
      appBar: AppBar(title: Text(_ticket?['subject']?.toString() ?? 'টিকিট')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: msgs.length,
                    itemBuilder: (_, i) {
                      final m = msgs[i];
                      final isMe = m['sender_type'] == 'student';
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMe ? SikhunTheme.primary : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            m['body']?.toString() ?? '',
                            style: TextStyle(color: isMe ? Colors.white : null),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          decoration: const InputDecoration(hintText: 'উত্তর লিখুন...'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _reply,
                        icon: const Icon(Icons.send, color: SikhunTheme.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
