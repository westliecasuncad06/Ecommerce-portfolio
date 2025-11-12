import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';
import '../../providers/app_providers.dart';
// Use only app_providers' chatServiceProvider to avoid name conflicts
import '../../providers/chat_providers.dart' hide chatServiceProvider;
import '../../models/chat_model.dart';
import '../chat/chat_screen.dart' as shared_chat;

class SellerMessagesScreen extends ConsumerStatefulWidget {
  const SellerMessagesScreen({super.key});

  @override
  ConsumerState<SellerMessagesScreen> createState() => _SellerMessagesScreenState();
}

class _SellerMessagesScreenState extends ConsumerState<SellerMessagesScreen> {
  @override
  void initState() {
    super.initState();
    // clear unread when screen is opened
    final fbUser = ref.read(firebaseAuthProvider).currentUser;
    if (fbUser != null) {
      ref.read(chatServiceProvider).clearUnread(fbUser.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fbUser = ref.watch(firebaseAuthProvider).currentUser;
    if (fbUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Messages')),
        body: const Center(child: Text('Please sign in')),
      );
    }

    final chatsAsync = ref.watch(chatsForUserProvider(fbUser.uid));

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: chatsAsync.when(
        data: (chats) {
          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.chat_bubble_outline, size: 64),
                  SizedBox(height: 12),
                  Text('No threads yet - open a chat from a storefront to start'),
                ],
              ),
            );
          }
          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final ChatModel chat = chats[index];
              final otherId = chat.sellerId == fbUser.uid ? chat.buyerId : chat.sellerId;

              return FutureBuilder(
                future: ref.read(firestoreProvider).collection('users').doc(otherId).get(),
                builder: (ctx, snap) {
                  String titleText = otherId;
                  String initials = otherId.length >= 2 ? otherId.substring(0, 2).toUpperCase() : otherId.toUpperCase();

                  if (snap.connectionState == ConnectionState.done && snap.hasData) {
                    final doc = snap.data as dynamic;
                    final data = (doc.data() as Map<String, dynamic>?) ?? {};
                    final displayName = data['displayName'] as String?;
                    final email = data['email'] as String?;
                    if (displayName != null && displayName.isNotEmpty) {
                      titleText = displayName;
                      final parts = displayName.split(RegExp(r'\s+'));
                      initials = parts.map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase();
                    } else if (email != null && email.isNotEmpty) {
                      titleText = email;
                      initials = email.length >= 2 ? email.substring(0, 2).toUpperCase() : email.toUpperCase();
                    }
                  }

                  return ListTile(
                    leading: CircleAvatar(child: Text(initials)),
                    title: Text('Chat with $titleText'),
                    subtitle: Text(
                      chat.lastMessage.isEmpty ? 'Say hello' : chat.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: chat.lastMessageTime != null
                        ? Text(TimeOfDay.fromDateTime(chat.lastMessageTime!.toDate()).format(context))
                        : null,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => shared_chat.ChatScreen(
                            chatId: chat.id,
                            sellerId: chat.sellerId,
                            buyerId: chat.buyerId,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

