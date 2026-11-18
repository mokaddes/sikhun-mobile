import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/ai_chat_model.dart';
import '../../providers/ai_chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/library_provider.dart';
import '../auth/login_screen.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated) {
        context.read<AiChatProvider>().fetchSessions();
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    context.read<AiChatProvider>().sendMessage(text).then((_) {
      _scrollToBottom();
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _showBookPicker(AiChatProvider chat) async {
    final lib = context.read<LibraryProvider>();
    await lib.fetchBookshelf();
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('বই যুক্ত করুন (আপনার বুকশেলফ)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              if (lib.bookshelf.isEmpty && lib.myBooks.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('আপনার বুকশেলফে কোনো বই নেই। লাইব্রেরি থেকে বই শেলফে যোগ করুন বা PDF আপলোড করুন।'),
                )
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      ...lib.bookshelf.map((b) => ListTile(
                            leading: const Icon(Icons.menu_book, color: SikhunTheme.primary),
                            title: Text(b.title),
                            onTap: () {
                              Navigator.pop(ctx);
                              chat.attachBookToCurrentSession(bookId: b.id, title: b.title);
                            },
                          )),
                      ...lib.myBooks.map((mb) => ListTile(
                            leading: const Icon(Icons.picture_as_pdf, color: SikhunTheme.accent),
                            title: Text(mb['title']?.toString() ?? 'My Book'),
                            onTap: () {
                              Navigator.pop(ctx);
                              chat.attachBookToCurrentSession(
                                myBookId: int.tryParse(mb['id'].toString()),
                                title: mb['title']?.toString(),
                              );
                            },
                          )),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSessionsSheet(AiChatProvider chat) async {
    await chat.fetchSessions();
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('চ্যাট ইতিহাস (Sessions)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      chat.clearChat();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('নতুন চ্যাট'),
                  ),
                ],
              ),
              const Divider(),
              if (chat.sessions.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text('পূর্ববর্তী কোনো চ্যাট সেশন নেই')),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: chat.sessions.length,
                    itemBuilder: (_, i) {
                      final s = chat.sessions[i];
                      final isCurrent = chat.currentSessionId == s.id;
                      return ListTile(
                        leading: Icon(
                          Icons.chat_bubble_outline,
                          color: isCurrent ? SikhunTheme.primary : null,
                        ),
                        title: Text(
                          s.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          chat.loadSession(s.id);
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                          onPressed: () => chat.deleteSession(s.id),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<AiChatProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('শিখুন AI টিউটর', style: TextStyle(fontSize: 17)),
            Text(
              'বাংলা ব্যাখ্যা, সারসংক্ষেপ ও স্টাডি সলভার',
              style: TextStyle(fontSize: 11, color: SikhunTheme.mutedDark),
            ),
          ],
        ),
        actions: [
          if (auth.isAuthenticated) ...[
            IconButton(
              icon: const Icon(Icons.library_books_outlined),
              tooltip: 'বই সংযুক্ত করুন',
              onPressed: () => _showBookPicker(chat),
            ),
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'চ্যাট ইতিহাস',
              onPressed: () => _showSessionsSheet(chat),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: 'নতুন চ্যাট',
            onPressed: () => chat.clearChat(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!auth.isAuthenticated)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: SikhunTheme.warning.withAlpha(25),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: SikhunTheme.warning),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('এআই টিউটরের সাথে চ্যাট করতে লগইন করুন।',
                        style: TextStyle(fontSize: 12)),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    child: const Text('লগইন', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),

          if (chat.activeBookId != null || chat.activeMyBookId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: SikhunTheme.primary.withAlpha(20),
              child: Row(
                children: [
                  const Icon(Icons.menu_book, size: 16, color: SikhunTheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'বই কনটেক্সট: ${chat.activeBookTitle ?? 'নির্বাচিত বই'}${chat.activePageNumber != null ? ' (পৃষ্ঠা ${chat.activePageNumber})' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: SikhunTheme.primary,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => chat.clearContext(),
                    child: const Icon(Icons.close, size: 18, color: SikhunTheme.primary),
                  ),
                ],
              ),
            ),

          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: chat.messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(chat.messages[index]);
              },
            ),
          ),

          if (chat.messages.length <= 2)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _suggestionChip('নিউটনের গতির সূত্র ব্যাখ্যা করো'),
                    const SizedBox(width: 6),
                    _suggestionChip('বিসিএস প্রিলি ইংরেজি প্রস্তুতি গাইড'),
                    const SizedBox(width: 6),
                    _suggestionChip('৫টি শর্ট প্রশ্ন তৈরি করো'),
                  ],
                ),
              ),
            ),

          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 6,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      maxLines: 4,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'যেকোনো টপিক বা বই নিয়ে প্রশ্ন করুন...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: SikhunTheme.primary,
                    child: IconButton(
                      icon: chat.isTyping
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: chat.isTyping ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _suggestionChip(String prompt) {
    return ActionChip(
      label: Text(prompt, style: const TextStyle(fontSize: 11)),
      onPressed: () {
        _textController.text = prompt;
        _sendMessage();
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isUser ? SikhunTheme.primary : Theme.of(context).cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
          ),
          border: isUser ? null : Border.all(color: Colors.grey.withAlpha(45)),
        ),
        child: msg.content.isEmpty
            ? const SizedBox(
                width: 40,
                height: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CircleAvatar(radius: 3, backgroundColor: SikhunTheme.primary),
                    CircleAvatar(radius: 3, backgroundColor: SikhunTheme.primary),
                    CircleAvatar(radius: 3, backgroundColor: SikhunTheme.primary),
                  ],
                ),
              )
            : SelectableText(
                msg.content,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isUser ? Colors.white : null,
                ),
              ),
      ),
    );
  }
}
