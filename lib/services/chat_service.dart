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

    await doc.set(chat.toMap());
    return chat;
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
    // user may be seller or buyer
    final sellerQuery = chatsRef.where('sellerId', isEqualTo: uid);
    final buyerQuery = chatsRef.where('buyerId', isEqualTo: uid);

    // combine via snapshots of two queries is left as an exercise for scale; here we'll merge streams
    final s1 = sellerQuery.orderBy('lastMessageTime', descending: true).snapshots();
    final s2 = buyerQuery.orderBy('lastMessageTime', descending: true).snapshots();

    return StreamZip([s1, s2]).map((list) {
      final allDocs = <DocumentSnapshot>[];
      for (final snap in list) {
        allDocs.addAll(snap.docs);
      }
      final chats = allDocs
          .map((d) => ChatModel.fromDoc(d))
          .toList()
        ..sort((a, b) {
          final ta = a.lastMessageTime?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
          final tb = b.lastMessageTime?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
          return tb.compareTo(ta);
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
 
