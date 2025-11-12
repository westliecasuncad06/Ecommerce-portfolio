import 'dart:io';
import 'dart:async';

import '../models/message.dart' as legacy_msg;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;
  ChatService({FirebaseFirestore? firestore, FirebaseStorage? storage})
      : firestore = firestore ?? FirebaseFirestore.instance,
        storage = storage ?? FirebaseStorage.instance;

  /// Positional constructor kept for backward compatibility with older providers
  ChatService.fromDb(FirebaseFirestore db)
      : firestore = db,
        storage = FirebaseStorage.instance;

  /// Backwards-compatible unnamed constructor used by some existing code
  ChatService.withFirestore(FirebaseFirestore db)
      : firestore = db,
        storage = FirebaseStorage.instance;

  /// Support older call-site that constructs ChatService(db)
  ChatService.positional(FirebaseFirestore db)
      : firestore = db,
        storage = FirebaseStorage.instance;

  // Consistent chatId generator: seller first, buyer second
  String generateChatId({required String sellerId, required String buyerId}) {
    return 'chat_${sellerId}_$buyerId';
  }

  /// Backwards-compatible chatId generator that accepts any two ids and
  /// assumes (userA, userB) => seller=userB, buyer=userA as used in older UI.
  String chatIdFor(String a, String b) => generateChatId(sellerId: b, buyerId: a);

  CollectionReference get chatsRef => firestore.collection('chats');

  DocumentReference chatDocRef(String chatId) => chatsRef.doc(chatId);

  CollectionReference messagesRef(String chatId) =>
      chatDocRef(chatId).collection('messages');

  Future<ChatModel> createOrGetChat({
    required String sellerId,
    required String buyerId,
    String initialMessage = '',
  }) async {
    final chatId = generateChatId(sellerId: sellerId, buyerId: buyerId);
    final doc = chatDocRef(chatId);
    final snap = await doc.get();
    if (snap.exists) {
      return ChatModel.fromDoc(snap);
    }

    final now = Timestamp.now();
    final chat = ChatModel(
      id: chatId,
      sellerId: sellerId,
      buyerId: buyerId,
      lastMessage: initialMessage,
      lastMessageTime: now,
      lastSenderId: null,
      createdAt: now,
      updatedAt: now,
    );

    // include participants array in document for efficient querying
    await doc.set(chat.toMap());
    return chat;
  }

  // Parse chatId of the form "chat_<sellerId>_<buyerId>"
  ({String sellerId, String buyerId}) parseChatId(String chatId) {
    final parts = chatId.split('_');
    if (parts.length >= 3 && parts[0] == 'chat') {
      return (sellerId: parts[1], buyerId: parts[2]);
    }
    // Fallback: cannot parse; return empty strings
    return (sellerId: '', buyerId: '');
  }

  // Ensure chat document exists before writing messages (helps when messages are sent from deep links)
  Future<void> _ensureChatExists(String chatId) async {
    final doc = chatDocRef(chatId);
    final snap = await doc.get();
    if (snap.exists) return;
    final parts = parseChatId(chatId);
    final now = Timestamp.now();
    await doc.set({
      'sellerId': parts.sellerId,
      'buyerId': parts.buyerId,
      'participants': [parts.sellerId, parts.buyerId],
      'lastMessage': '',
      'lastMessageTime': now,
      'lastSenderId': null,
      'createdAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));
  }

  /// Backfill missing `participants` arrays for existing chat documents.
  /// Returns number of documents updated.
  Future<int> backfillParticipants() async {
    // Firestore cannot query for missing field reliably; fetch all docs
    final all = await chatsRef.get();
    if (all.docs.isEmpty) return 0;
    final batch = firestore.batch();
    var updated = 0;
    for (final d in all.docs) {
      final data = d.data() as Map<String, dynamic>? ?? {};
      if (data.containsKey('participants') && data['participants'] != null) {
        continue; // already migrated
      }
      final seller = data['sellerId'] as String? ?? '';
      final buyer = data['buyerId'] as String? ?? '';
      final participants = [if (seller.isNotEmpty) seller, if (buyer.isNotEmpty) buyer];
      if (participants.isEmpty) continue;
      batch.update(d.reference, {'participants': participants});
      updated++;
    }
    if (updated == 0) return 0;
    await batch.commit();
    return updated;
  }

  /// Convenience: run backfill and return whether any changes were made.
  Future<bool> migrateChatsParticipants() async {
    final count = await backfillParticipants();
    return count > 0;
  }

  Stream<List<MessageModel>> streamMessages(String chatId) {
    return messagesRef(chatId)
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => MessageModel.fromDoc(d)).toList());
  }

  Stream<ChatModel?> streamChat(String chatId) {
    return chatDocRef(chatId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return ChatModel.fromDoc(snap);
    });
  }

  Stream<List<ChatModel>> streamChatsForUser(String uid) {
    // Use participants arrayContains. Avoid server-side orderBy to prevent
    // composite index requirement (arrayContains + orderBy needs an index).
    final q = chatsRef.where('participants', arrayContains: uid);
    return q.snapshots().map((snap) {
      final chats = snap.docs.map((d) => ChatModel.fromDoc(d)).toList();
      chats.sort((a, b) {
        final ta = a.lastMessageTime?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tb = b.lastMessageTime?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tb.compareTo(ta); // newest first
      });
      return chats;
    });
  }

  // -------- Compatibility wrappers for older app code --------
  /// Older code expects a top-level `watchChat(a,b)` returning legacy ChatMessage
  Stream<List<legacy_msg.ChatMessage>> watchChat(String userA, String userB) {
    final chatId = chatIdFor(userA, userB);
    return streamMessages(chatId).map((msgs) => msgs
        .map((m) => legacy_msg.ChatMessage(
              id: m.id,
              chatId: chatId,
              fromId: m.fromId,
              toId: m.toId,
              text: m.text,
              sentAt: m.sentAt.toDate(),
            ))
        .toList());
  }

  Future<void> sendMessage({required String fromId, required String toId, required String text}) async {
    final chatId = chatIdFor(fromId, toId);
    await sendTextMessage(chatId: chatId, fromId: fromId, toId: toId, text: text);
    // Optionally maintain a notifications counter document
    final notifRef = firestore.collection('store_notifications').doc(toId);
    await notifRef.set({
      'unreadMessages': FieldValue.increment(1),
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  /// Watch unread message count for a given seller id (total across chats)
  Stream<int> watchUnread(String sellerId) async* {
    // Listen to chats where sellerId matches, then compute unread count
    await for (final snap in chatsRef.where('sellerId', isEqualTo: sellerId).snapshots()) {
      var total = 0;
      for (final doc in snap.docs) {
        final chatId = doc.id;
        final q = await messagesRef(chatId).where('toId', isEqualTo: sellerId).where('isRead', isEqualTo: false).get();
        total += q.size;
      }
      yield total;
    }
  }

  /// Watch unread message count for any user (seller or buyer).
  /// Computes total number of messages across all chats addressed to [userId]
  /// where `isRead == false`.
  Stream<int> watchUnreadForUser(String userId) async* {
    await for (final snap in chatsRef.where('participants', arrayContains: userId).snapshots()) {
      var total = 0;
      for (final doc in snap.docs) {
        final chatId = doc.id;
        final q = await messagesRef(chatId)
            .where('toId', isEqualTo: userId)
            .where('isRead', isEqualTo: false)
            .get();
        total += q.size;
      }
      yield total;
    }
  }

  /// Clear unread messages counter by marking messages as read for seller
  Future<void> clearUnread(String sellerId) async {
    final snap = await chatsRef.where('sellerId', isEqualTo: sellerId).get();
    final batch = firestore.batch();
    for (final doc in snap.docs) {
      final msgs = await messagesRef(doc.id).where('toId', isEqualTo: sellerId).where('isRead', isEqualTo: false).get();
      for (final m in msgs.docs) {
        batch.update(m.reference, {'isRead': true});
      }
    }
    await batch.commit();
  }

  Future<void> sendTextMessage({
    required String chatId,
    required String fromId,
    required String toId,
    required String text,
  }) async {
    await _ensureChatExists(chatId);
    final now = Timestamp.now();
    final msgRef = messagesRef(chatId).doc();
    final msg = MessageModel(
      id: msgRef.id,
      fromId: fromId,
      toId: toId,
      text: text,
      sentAt: now,
      messageType: MessageType.text,
      isRead: false,
      meta: {},
    );

    final chatRef = chatDocRef(chatId);

    final batch = firestore.batch();
    batch.set(msgRef, msg.toMap());
    batch.update(chatRef, {
      'lastMessage': text,
      'lastMessageTime': now,
      'lastSenderId': fromId,
      'updatedAt': now,
    });

    await batch.commit();
  }

  Future<void> sendImageMessage({
    required String chatId,
    required String fromId,
    required String toId,
    XFile? pickedFile,
  }) async {
    if (pickedFile == null) return;
    await _ensureChatExists(chatId);
    final now = Timestamp.now();
    final file = File(pickedFile.path);
    final ref = storage.ref().child('chat_images/$chatId/${DateTime.now().millisecondsSinceEpoch}.jpg');
    final upl = await ref.putFile(file);
    final url = await upl.ref.getDownloadURL();

    final msgRef = messagesRef(chatId).doc();
    final msg = MessageModel(
      id: msgRef.id,
      fromId: fromId,
      toId: toId,
      text: url,
      sentAt: now,
      messageType: MessageType.image,
      isRead: false,
      meta: {'url': url},
    );

    final chatRef = chatDocRef(chatId);
    final batch = firestore.batch();
    batch.set(msgRef, msg.toMap());
    batch.update(chatRef, {
      'lastMessage': '[Image]',
      'lastMessageTime': now,
      'lastSenderId': fromId,
      'updatedAt': now,
    });
    await batch.commit();
  }

  Future<void> sendProductMessage({
    required String chatId,
    required String fromId,
    required String toId,
    required String productId,
    required String title,
    String? imageUrl,
    num? price,
  }) async {
    await _ensureChatExists(chatId);
    final now = Timestamp.now();
    final msgRef = messagesRef(chatId).doc();
    final msg = MessageModel(
      id: msgRef.id,
      fromId: fromId,
      toId: toId,
      text: title,
      sentAt: now,
      messageType: MessageType.product,
      isRead: false,
      meta: {
        'productId': productId,
        'title': title,
        if (imageUrl != null) 'image': imageUrl,
        if (price != null) 'price': price,
      },
    );

    final chatRef = chatDocRef(chatId);
    final batch = firestore.batch();
    batch.set(msgRef, msg.toMap());
    batch.update(chatRef, {
      'lastMessage': '[Product] $title',
      'lastMessageTime': now,
      'lastSenderId': fromId,
      'updatedAt': now,
    });
    await batch.commit();
  }

  Future<void> markMessagesRead({
    required String chatId,
    required String currentUserId,
  }) async {
    final q = await messagesRef(chatId)
        .where('toId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = firestore.batch();
    for (final doc in q.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}

/// Small helper to combine multiple streams (not built-in) - lightweight implementation
class StreamZip<T> extends Stream<List<T>> {
  final List<Stream<T>> streams;
  StreamZip(this.streams);

  @override
  StreamSubscription<List<T>> listen(void Function(List<T>)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    final values = List<T?>.filled(streams.length, null);
    final ready = List<bool>.filled(streams.length, false);
    final controllers = StreamController<List<T>>();

    final subs = <StreamSubscription>[];
    for (var i = 0; i < streams.length; i++) {
      final index = i;
      final sub = streams[i].listen((v) {
        values[index] = v;
        ready[index] = true;
        if (ready.every((e) => e)) {
          controllers.add(values.cast<T>());
        }
      }, onError: (e) => controllers.addError(e));
      subs.add(sub);
    }

    return controllers.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}
 
