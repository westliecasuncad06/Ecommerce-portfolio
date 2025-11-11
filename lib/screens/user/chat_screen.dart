import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_providers.dart';
import '../../models/message.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String sellerId;
  final String? sellerName;
  const ChatScreen({super.key, required this.sellerId, this.sellerName});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fbUser = ref.watch(firebaseAuthProvider).currentUser;
    final userId = fbUser?.uid;
    final chatSvc = ref.watch(chatServiceProvider);

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(child: Text('Please sign in to message the store')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sellerName ?? 'Store Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: chatSvc.watchChat(userId, widget.sellerId),
              builder: (ctx, snap) {
                final msgs = snap.data ?? [];
                // ensure messages are ordered oldest -> newest (chat_service also sorts)
                // and render with ListView normal (not reversed) so newest is at bottom.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scroll.hasClients) {
                    try {
                      _scroll.jumpTo(_scroll.position.maxScrollExtent);
                    } catch (_) {}
                  }
                });

                return ListView.builder(
                  controller: _scroll,
                  reverse: false,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: msgs.length,
                  itemBuilder: (ctx, idx) {
                    final m = msgs[idx];
                    final mine = m.fromId == userId;
                    return Align(
                      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: mine ? Theme.of(context).colorScheme.primary : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          m.text,
                          style: TextStyle(color: mine ? Colors.white : Colors.black87),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: const InputDecoration(
                        hintText: 'Write a message',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      minLines: 1,
                      maxLines: 4,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _ctrl,
                    builder: (ctx, val, child) {
                      final enabled = val.text.trim().isNotEmpty;
                      return ElevatedButton(
                        onPressed: !enabled
                            ? null
                            : () async {
                                final text = _ctrl.text.trim();
                                _ctrl.clear();
                                await chatSvc.sendMessage(fromId: userId, toId: widget.sellerId, text: text);
                                // after sending, wait a tick then scroll to bottom
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (_scroll.hasClients) {
                                    try {
                                      _scroll.animateTo(_scroll.position.maxScrollExtent,
                                          duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
                                    } catch (_) {}
                                  }
                                });
                              },
                        child: const Icon(Icons.send),
                      );
                    },
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
