import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';
import '../../providers/app_providers.dart';
// chat_service is used via provider; no direct import required here

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

  // For now show a placeholder list of chats. This can be extended to list
    // buyer threads by querying messages collection grouped by chatId.
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.chat_bubble_outline, size: 64),
            SizedBox(height: 12),
            Text('No threads yet - open a chat from a storefront to start'),
          ],
        ),
      ),
    );
  }
}

