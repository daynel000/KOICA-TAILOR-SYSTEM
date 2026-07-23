// screens/chat_screen.dart - Tab 4: Chat with tailors
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../providers/app_provider.dart';
import '../models/order_model.dart';

class ChatScreen extends StatefulWidget {
  final void Function(int) onNavigateToTab;
  const ChatScreen({super.key, required this.onNavigateToTab});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  OrderModel? _activeChat;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() { _inputController.dispose(); _scrollController.dispose(); super.dispose(); }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _activeChat == null || _isSending) return;
    _inputController.clear();
    setState(() => _isSending = true);
    await context.read<AppProvider>().sendMessageInOrder(_activeChat!.orderId, text);
    // Refresh activeChat from updated provider
    final updated = context.read<AppProvider>().orderList.firstWhere((o) => o.orderId == _activeChat!.orderId);
    setState(() { _activeChat = updated; _isSending = false; });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    // Handle deeplink from Orders tab
    if (provider.selectedOrderForChat != null && _activeChat == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _activeChat = provider.selectedOrderForChat);
        provider.clearSelectedOrderForChat();
        _scrollToBottom();
      });
    }

    if (_activeChat != null) return _buildChatView(provider);
    return _buildChatList(provider);
  }

  Widget _buildChatList(AppProvider provider) {
    final chatOrders = provider.orderList.where((o) => o.chatMessages.isNotEmpty).toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(bottom: false, child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 12), child: Align(alignment: Alignment.centerLeft, child: const Text('Messages', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF132238))))),
        Expanded(child: chatOrders.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text('No active chats yet', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
              itemCount: chatOrders.length,
              itemBuilder: (_, i) {
                final order = chatOrders[i];
                final lastMsg = order.chatMessages.last;
                return GestureDetector(
                  onTap: () { setState(() => _activeChat = order); _scrollToBottom(); },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                    child: Row(children: [
                      CircleAvatar(radius: 22, backgroundImage: NetworkImage('https://images.unsplash.com/photo-1556157382-97eda2d62296?w=100&auto=format&fit=crop&q=80'), backgroundColor: AppColors.background),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(order.tailorShopName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF132238))),
                          Text(lastMsg.sentAt.split(', ').last, style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                        ]),
                        const SizedBox(height: 2),
                        Text(order.garmentType, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text(lastMsg.messageText, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      ])),
                    ]),
                  ),
                );
              },
            ),
        ),
      ])),
    );
  }

  Widget _buildChatView(AppProvider provider) {
    // Sync latest messages from provider
    final currentOrder = provider.orderList.firstWhere((o) => o.orderId == _activeChat!.orderId, orElse: () => _activeChat!);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(bottom: false, child: Column(children: [
        // Chat header
        Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
          decoration: BoxDecoration(color: AppColors.background, border: Border(bottom: BorderSide(color: AppColors.border))),
          child: Row(children: [
            IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF132238)), onPressed: () { setState(() => _activeChat = null); }),
            CircleAvatar(radius: 18, backgroundImage: const NetworkImage('https://images.unsplash.com/photo-1556157382-97eda2d62296?w=100&auto=format&fit=crop&q=80'), backgroundColor: AppColors.surface),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(currentOrder.tailorShopName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF132238))),
              Text('${currentOrder.garmentType} order', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ])),
          ]),
        ),
        // Messages
        Expanded(child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          itemCount: currentOrder.chatMessages.length,
          itemBuilder: (_, i) {
            final msg = currentOrder.chatMessages[i];
            final isMe = msg.isSentByCustomer;
            return Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 4), bottomRight: Radius.circular(isMe ? 4 : 16),
                      ),
                      border: isMe ? null : Border.all(color: AppColors.border),
                    ),
                    child: Text(msg.messageText, style: TextStyle(fontSize: 12, color: isMe ? Colors.white : AppColors.textPrimary, height: 1.4)),
                  ),
                  const SizedBox(height: 3),
                  Text(msg.sentAt, style: TextStyle(fontSize: 8, color: AppColors.textMuted)),
                ]),
              ),
            );
          },
        )),
        // Input bar
        Container(
          padding: EdgeInsets.fromLTRB(12, 10, 12, MediaQuery.of(context).viewInsets.bottom + 16),
          decoration: BoxDecoration(color: AppColors.background, border: Border(top: BorderSide(color: AppColors.border))),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _inputController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                filled: true, fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            )),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14)),
                child: _isSending
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ]),
        ),
      ])),
    );
  }
}
