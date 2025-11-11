import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, product }

class MessageModel {
  final String id;
  final String fromId;
  final String toId;
  final String text;
  final Timestamp sentAt;
  final MessageType messageType;
  final bool isRead;
  // optional extra payload (image url or product id)
  final Map<String, dynamic>? meta;

  MessageModel({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.text,
    required this.sentAt,
    required this.messageType,
    required this.isRead,
    this.meta,
  });

  Map<String, dynamic> toMap() => {
        'fromId': fromId,
        'toId': toId,
        'text': text,
        'sentAt': sentAt,
        'messageType': messageType.name,
        'isRead': isRead,
        'meta': meta,
      };

  factory MessageModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    final typeStr = d['messageType'] as String? ?? 'text';
    final MessageType type = MessageType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => MessageType.text,
    );

    return MessageModel(
      id: doc.id,
      fromId: d['fromId'] ?? '',
      toId: d['toId'] ?? '',
      text: d['text'] ?? '',
      sentAt: d['sentAt'] ?? Timestamp.now(),
      messageType: type,
      isRead: d['isRead'] ?? false,
      meta: (d['meta'] as Map?)?.cast<String, dynamic>() ?? {},
    );
  }
}
