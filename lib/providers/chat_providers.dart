import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/chat_service.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import 'auth_providers.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  final fs = ref.read(firestoreProvider);
  return ChatService(firestore: fs, storage: FirebaseStorage.instance);
});

final chatsForUserProvider = StreamProvider.family<List<ChatModel>, String>((ref, uid) {
  final svc = ref.read(chatServiceProvider);
  return svc.streamChatsForUser(uid);
});

final messagesProvider = StreamProvider.family<List<MessageModel>, String>((ref, chatId) {
  final svc = ref.read(chatServiceProvider);
  return svc.streamMessages(chatId);
});

/// convenience provider to get current AppUser id
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.asData?.value?.id;
});
