import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/ai_chat_model.dart';
import '../../providers/ai_chat_provider.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _suggestedPrompts = [
    'মায়োসিস বিভাজনের গুরুত্ব সহজভাবে ব্যাখ্যা করো',
    'বাইনারি থেকে ডেসিমেল রূপান্তরের নিয়ম বলো',
    'বিসিএস প্রিলিমিনারি সাধারণ বিজ্ঞান পড়ার কৌশল কী?',
    'রসায়ন দ্বিতীয় পত্রের জারণ-বিজারণ টপিকটি বুঝিয়ে দাও',
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    final provider = Provider.of<AiChatProvider>(context, listen: false);
    provider.sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chat = Provider.of<AiChatProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: SikhunTheme.primary.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy, color: SikhunTheme.primary, size: 20),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('শিখুন AI টিউটর', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('আপনার সার্বক্ষণিক পড়াশোনার সহায়তাকারী', style: TextStyle(fontSize: 11, color: SikhunTheme.mutedDark)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'কথোপকথন রিসেট',
            onPressed: () => chat.clearConversation(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Active Context Banner
          if (chat.activeBookTitle != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: SikhunTheme.primary.withAlpha(20),
              child: Row(
                children: [
                  const Icon(Icons.menu_book, size: 16, color: SikhunTheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'বর্তমান বই: ${chat.activeBookTitle}${chat.activePageNumber != null ? " (পৃষ্ঠা ${chat.activePageNumber})" : ""}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: SikhunTheme.primary),
                    ),
                  ),
                  InkWell(
                    onTap: () => chat.clearContext(),
                    child: const Icon(Icons.close, size: 16, color: SikhunTheme.mutedDark),
                  ),
                ],
              ),
            ),

          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: chat.messages.length,
              itemBuilder: (context, index) {
                final msg = chat.messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          // Typing Indicator
          if (chat.isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: SikhunTheme.primary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI উত্তর লিখছে...',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

          // Suggested Prompts
          if (chat.messages.length <= 2)
            SizedBox(
              height: 42,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _suggestedPrompts.length,
                itemBuilder: (context, index) {
                  final prompt = _suggestedPrompts[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(prompt, style: const TextStyle(fontSize: 12)),
                      onPressed: () {
                        _textController.text = prompt;
                        _send();
                      },
                    ),
                  );
                },
              ),
            ),

          // Message Input Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      decoration: const InputDecoration(
                        hintText: 'আপনার প্রশ্ন লিখুন...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: SikhunTheme.primary),
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!msg.isUser) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: SikhunTheme.primary.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy, size: 16, color: SikhunTheme.primary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: msg.isUser
                    ? SikhunTheme.primary
                    : (msg.isError ? SikhunTheme.danger.withAlpha(20) : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomRight: msg.isUser ? const Radius.circular(0) : const Radius.circular(16),
                  bottomLeft: !msg.isUser ? const Radius.circular(0) : const Radius.circular(16),
                ),
                border: msg.isError ? Border.all(color: SikhunTheme.danger.withAlpha(50)) : null,
              ),
              child: Text(
                msg.content,
                style: TextStyle(
                  color: msg.isUser ? Colors.white : (msg.isError ? SikhunTheme.danger : Colors.black87),
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (msg.isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 14,
              backgroundColor: SikhunTheme.primary,
              child: Icon(Icons.person, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}
