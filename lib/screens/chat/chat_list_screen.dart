import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/chat_providers.dart';
import '../../models/chat_model.dart';
import '../chat/chat_screen.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) {
      return const Scaffold(body: Center(child: Text('Please sign in to view chats')));
    }

    final chatsAsync = ref.watch(chatsForUserProvider(userId));
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: chatsAsync.when(
        data: (chats) => ListView.builder(
          itemCount: chats.length,
          itemBuilder: (context, idx) {
            final ChatModel chat = chats[idx];
            final otherId = chat.sellerId == userId ? chat.buyerId : chat.sellerId;
            return ListTile(
              leading: CircleAvatar(child: Text(otherId.substring(0, 2).toUpperCase())),
              title: Text('Chat with ${otherId}'),
              subtitle: Text(chat.lastMessage),
              trailing: chat.lastMessageTime != null
                  ? Text(TimeOfDay.fromDateTime(chat.lastMessageTime!.toDate()).format(context))
                  : null,
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(chatId: chat.id, sellerId: chat.sellerId, buyerId: chat.buyerId)));
              },
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
