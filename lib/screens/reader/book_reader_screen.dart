import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../config/api_endpoints.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class BookReaderScreen extends StatefulWidget {
  final int bookId;
  final String title;
  final bool isMyBook;
  final int initialPage;

  const BookReaderScreen({
    super.key,
    required this.bookId,
    required this.title,
    this.isMyBook = false,
    this.initialPage = 1,
  });

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  bool _isLoading = true;
  String? _error;
  int _totalPages = 1;
  int _currentPage = 1;
  List<int>? _accessiblePages;
  List<Map<String, dynamic>> _chapters = [];
  String? _currentPageImageUrl;
  String? _token;
  final Map<int, String> _cachedPageUrls = {};

  final TextEditingController _chatCtrl = TextEditingController();
  final List<Map<String, String>> _pageChatMessages = [];
  bool _chatSending = false;
  int? _chatSessionId;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _initReader();
  }

  @override
  void dispose() {
    _chatCtrl.dispose();
    super.dispose();
  }

  Future<void> _initReader() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    _token = await ApiService.getToken();

    final endpoint = widget.isMyBook
        ? ApiEndpoints.myBookRead(widget.bookId)
        : ApiEndpoints.readerShow(widget.bookId);

    final res = await ApiService.get(endpoint);
    if (!mounted) return;

    if (!res.success || res.data is! Map<String, dynamic>) {
      setState(() {
        _isLoading = false;
        _error = res.message ?? 'বইটি লোড করা যায়নি। অ্যাক্সেস যাচাই করুন।';
      });
      return;
    }

    final data = res.data as Map<String, dynamic>;
    final bookMeta = (widget.isMyBook ? data['my_book'] : data['book']) as Map<String, dynamic>? ?? {};

    _totalPages = int.tryParse((bookMeta['total_pages'] ?? 1).toString()) ?? 1;
    if (_totalPages < 1) _totalPages = 1;

    _currentPage = int.tryParse((data['initial_page'] ?? widget.initialPage).toString()) ?? widget.initialPage;
    if (data['accessible_pages'] is List) {
      _accessiblePages = (data['accessible_pages'] as List)
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .where((p) => p > 0)
          .toList();
    }
    if (data['chapters'] is List) {
      _chapters = (data['chapters'] as List).whereType<Map<String, dynamic>>().toList();
    }
    if (data['page_urls'] is Map) {
      (data['page_urls'] as Map).forEach((k, v) {
        final pg = int.tryParse(k.toString());
        if (pg != null && v != null) _cachedPageUrls[pg] = v.toString();
      });
    }

    setState(() => _isLoading = false);
    await _loadPage(_currentPage);
  }

  Future<void> _loadPage(int page) async {
    if (page < 1) page = 1;
    if (page > _totalPages) page = _totalPages;

    if (_accessiblePages != null && _accessiblePages!.isNotEmpty && !_accessiblePages!.contains(page)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('এই পৃষ্ঠাটি আনলক করা নেই। অধ্যায় কিনে আনলক করুন।')),
        );
      }
      return;
    }

    setState(() {
      _currentPage = page;
      _currentPageImageUrl = _cachedPageUrls[page];
    });

    if (!_cachedPageUrls.containsKey(page)) {
      final urlEndpoint = widget.isMyBook
          ? ApiEndpoints.myBookPageUrl(widget.bookId, page)
          : ApiEndpoints.readerPageUrl(widget.bookId, page);
      final res = await ApiService.get(urlEndpoint);
      if (!mounted) return;
      if (res.success && res.data is Map && res.data['url'] != null) {
        final signedUrl = res.data['url'].toString();
        _cachedPageUrls[page] = signedUrl;
        setState(() => _currentPageImageUrl = signedUrl);
      }
    }

    // Save progress silently
    final progEndpoint = widget.isMyBook
        ? ApiEndpoints.myBookProgress(widget.bookId)
        : ApiEndpoints.readerProgress(widget.bookId);
    ApiService.post(progEndpoint, body: {'page': page});
  }

  void _showChaptersSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('অধ্যায় তালিকা', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _chapters.length,
                itemBuilder: (c, i) {
                  final ch = _chapters[i];
                  final startPage = int.tryParse((ch['start_page'] ?? 1).toString()) ?? 1;
                  return ListTile(
                    dense: true,
                    title: Text((ch['title'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Text('পৃষ্ঠা $startPage', style: const TextStyle(color: SikhunTheme.primary, fontSize: 12)),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _loadPage(startPage);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPageAiChatSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          Future<void> askPageAi() async {
            final msg = _chatCtrl.text.trim();
            if (msg.isEmpty || _chatSending) return;
            _chatCtrl.clear();
            setModalState(() {
              _pageChatMessages.add({'role': 'user', 'content': msg});
              _pageChatMessages.add({'role': 'assistant', 'content': ''});
              _chatSending = true;
            });

            final endpoint = widget.isMyBook
                ? ApiEndpoints.myBookChat(widget.bookId)
                : ApiEndpoints.readerChat(widget.bookId);

            final buf = StringBuffer();
            try {
              await for (final ev in ApiService.postSseStream(
                endpoint,
                body: {
                  'message': msg,
                  'page': _currentPage,
                  if (_chatSessionId != null) 'session_id': _chatSessionId,
                },
              )) {
                if (ev['session_id'] != null) {
                  _chatSessionId = int.tryParse(ev['session_id'].toString());
                }
                if (ev['error'] != null) {
                  buf.write(ev['error'].toString());
                  setModalState(() => _pageChatMessages.last['content'] = buf.toString());
                  break;
                }
                final delta = ev['content']?.toString() ?? '';
                if (delta.isNotEmpty) {
                  buf.write(delta);
                  setModalState(() => _pageChatMessages.last['content'] = buf.toString());
                }
              }
            } catch (_) {
              setModalState(() => _pageChatMessages.last['content'] = 'AI উত্তর তৈরি করতে সমস্যা হয়েছে।');
            } finally {
              setModalState(() => _chatSending = false);
            }
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(modalCtx).viewInsets.bottom),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.68,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: SikhunTheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'AI পেজ টিউটর — পৃষ্ঠা $_currentPage',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: _pageChatMessages.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'পৃষ্ঠা $_currentPage সম্পর্কে যেকোনো প্রশ্ন করুন — এআই এই পাতার কনটেন্ট বিশ্লেষণ করে উত্তর দেবে।',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: SikhunTheme.mutedDark),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _pageChatMessages.length,
                            itemBuilder: (_, idx) {
                              final m = _pageChatMessages[idx];
                              final isUser = m['role'] == 'user';
                              return Align(
                                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isUser ? SikhunTheme.primary : Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: isUser ? null : Border.all(color: Theme.of(context).dividerColor),
                                  ),
                                  child: Text(
                                    (m['content'] ?? '').isEmpty ? '...' : m['content']!,
                                    style: TextStyle(color: isUser ? Colors.white : null, fontSize: 13),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _chatCtrl,
                            decoration: InputDecoration(
                              hintText: 'পৃষ্ঠা $_currentPage সম্পর্কে লিখুন...',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            onSubmitted: (_) => askPageAi(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.send_rounded, color: SikhunTheme.primary),
                          onPressed: _chatSending ? null : askPageAi,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (_chapters.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.toc),
              tooltip: 'অধ্যায় তালিকা',
              onPressed: _showChaptersSheet,
            ),
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'AI পেজ টিউটর',
            onPressed: _showPageAiChatSheet,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outline, size: 52, color: SikhunTheme.warning),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _initReader, child: const Text('আবার চেষ্টা করুন')),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        color: Colors.black87,
                        child: _currentPageImageUrl == null
                            ? const Center(child: CircularProgressIndicator())
                            : InteractiveViewer(
                                minScale: 1.0,
                                maxScale: 4.0,
                                child: Center(
                                  child: CachedNetworkImage(
                                    imageUrl: _currentPageImageUrl!,
                                    httpHeaders: _token != null ? {'Authorization': 'Bearer $_token'} : null,
                                    fit: BoxFit.contain,
                                    placeholder: (c, u) => const Center(child: CircularProgressIndicator()),
                                    errorWidget: (c, u, e) => const Icon(Icons.broken_image, color: Colors.white54, size: 48),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: _currentPage > 1 ? () => _loadPage(_currentPage - 1) : null,
                            ),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'পৃষ্ঠা $_currentPage / $_totalPages',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  if (_totalPages > 1)
                                    Slider(
                                      value: _currentPage.toDouble().clamp(1, _totalPages.toDouble()),
                                      min: 1,
                                      max: _totalPages.toDouble(),
                                      divisions: (_totalPages - 1).clamp(1, 1000),
                                      activeColor: SikhunTheme.primary,
                                      onChanged: (v) => setState(() => _currentPage = v.round()),
                                      onChangeEnd: (v) => _loadPage(v.round()),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: _currentPage < _totalPages ? () => _loadPage(_currentPage + 1) : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
