import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String chatId; // userId_sellerId composite
  final String fromId;
  final String toId;
  final String text;
  final DateTime sentAt;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.fromId,
    required this.toId,
    required this.text,
    required this.sentAt,
  });

  Map<String, dynamic> toMap() => {
        'chatId': chatId,
        'fromId': fromId,
        'toId': toId,
        'text': text,
        'sentAt': Timestamp.fromDate(sentAt),
      };

  factory ChatMessage.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      chatId: d['chatId'] ?? '',
      fromId: d['fromId'] ?? '',
      toId: d['toId'] ?? '',
      text: d['text'] ?? '',
      sentAt: (d['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
