import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/chat_providers.dart';
import '../../models/message_model.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/chat_input.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String sellerId;
  final String buyerId;

  const ChatScreen({super.key, required this.chatId, required this.sellerId, required this.buyerId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final messagesAsync = ref.watch(messagesProvider(widget.chatId));
    final svc = ref.read(chatServiceProvider);

    Future<void> _sendText(String text) async {
      if (currentUserId == null) return;
      final other = widget.sellerId == currentUserId ? widget.buyerId : widget.sellerId;
      await svc.sendTextMessage(chatId: widget.chatId, fromId: currentUserId, toId: other, text: text);
      // after sending, scroll to bottom
      await Future.delayed(const Duration(milliseconds: 100));
      _scroll.animateTo(_scroll.position.maxScrollExtent + 100, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }

    Future<void> _sendImage(XFile file) async {
      if (currentUserId == null) return;
      final other = widget.sellerId == currentUserId ? widget.buyerId : widget.sellerId;
      await svc.sendImageMessage(chatId: widget.chatId, fromId: currentUserId, toId: other, pickedFile: file);
    }

    // Mark messages read when viewing
    if (currentUserId != null) {
      svc.markMessagesRead(chatId: widget.chatId, currentUserId: currentUserId);
    }

    return Scaffold(
      appBar: AppBar(title: Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                return ListView.builder(
                  controller: _scroll,
                  itemCount: messages.length,
                  itemBuilder: (context, idx) {
                    final MessageModel m = messages[idx];
                    final isMe = m.fromId == currentUserId;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: ChatBubble(message: m, isMe: isMe),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
          ChatInput(onSendText: _sendText, onSendImage: _sendImage),
        ],
      ),
    );
  }
}
