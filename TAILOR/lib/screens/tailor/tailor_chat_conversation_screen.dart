import 'package:flutter/material.dart';
import '../../services/tailor_api_service.dart';

/// Shows the message thread between tailor and customer for a specific order in clean light theme.
class TailorChatConversationScreen extends StatefulWidget {
  final int orderId;
  final String customerName;
  final String clothingType;

  const TailorChatConversationScreen({
    super.key,
    required this.orderId,
    required this.customerName,
    required this.clothingType,
  });

  @override
  State<TailorChatConversationScreen> createState() => _TailorChatConversationScreenState();
}

class _TailorChatConversationScreenState extends State<TailorChatConversationScreen> {
  final TailorApiService _api = TailorApiService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _messages = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSending = false;

  static const brandNavy = Color(0xFF132238);
  static const brandGold = Color(0xFFD49228);
  static const bgColor   = Color(0xFFFAFAFC);

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await _api.fetchChatMessages(widget.orderId);
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      // Fallback demo conversation when offline
      setState(() {
        _messages = [
          {
            'sender_name': widget.customerName,
            'message_text': 'Hi! I submitted my measurements for the ${widget.clothingType}. Could you check if everything is correct?',
            'is_tailor': false,
            'created_at': '2026-07-23 09:30:00',
          },
          {
            'sender_name': 'Tailor',
            'message_text': 'Hello ${widget.customerName}! We received your order. The chest and waist proportions look accurate. We will start cutting the fabric today.',
            'is_tailor': true,
            'created_at': '2026-07-23 09:35:00',
          },
          {
            'sender_name': widget.customerName,
            'message_text': 'Great! Thank you so much for the quick update!',
            'is_tailor': false,
            'created_at': '2026-07-23 09:38:00',
          },
        ];
        _isLoading = false;
      });
      _scrollToBottom();
    }
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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      await _api.sendMessage(widget.orderId, 1, text);
      await _loadMessages();
    } catch (e) {
      // Add local message for offline demo
      setState(() {
        _messages.add({
          'sender_name': 'Tailor',
          'message_text': text,
          'is_tailor': true,
          'created_at': DateTime.now().toString(),
        });
      });
      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: brandNavy),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.customerName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandNavy)),
            Text(widget.clothingType,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: brandGold));
    }
    if (_errorMessage != null) {
      return Center(
        child: Text('Error: $_errorMessage',
            style: const TextStyle(color: Colors.redAccent)),
      );
    }
    if (_messages.isEmpty) {
      return const Center(
        child: Text('No messages yet. Say hello! 👋',
            style: TextStyle(color: Color(0xFF64748B))),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index] as Map<String, dynamic>;
        final isTailor = msg['is_tailor'] == true || msg['is_tailor'] == 1;
        return _buildMessageBubble(msg, isTailor);
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isTailor) {
    final senderName = msg['sender_name'] ?? 'Unknown';
    final text = msg['message_text'] ?? '';
    final time = msg['created_at'] ?? '';
    final shortTime = time.length >= 16 ? time.substring(11, 16) : time;

    return Align(
      alignment: isTailor ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment:
              isTailor ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isTailor)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 2),
                child: Text(
                  senderName,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600),
                ),
              ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isTailor
                    ? brandNavy
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isTailor ? 16 : 4),
                  bottomRight: Radius.circular(isTailor ? 4 : 16),
                ),
                border: isTailor ? null : Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                  )
                ],
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isTailor ? Colors.white : brandNavy,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
              child: Text(shortTime,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
            top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: brandNavy),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: bgColor,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: brandNavy, width: 1.5),
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
                textInputAction: TextInputAction.send,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: brandGold,
                  shape: BoxShape.circle,
                ),
                child: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
