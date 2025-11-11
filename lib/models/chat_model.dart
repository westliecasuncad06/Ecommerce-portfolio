import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final String sellerId;
  final String buyerId;
  final String lastMessage;
  final Timestamp? lastMessageTime;
  final String? lastSenderId;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  ChatModel({
    required this.id,
    required this.sellerId,
    required this.buyerId,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.lastSenderId,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'sellerId': sellerId,
    'participants': [sellerId, buyerId],
        'buyerId': buyerId,
        'lastMessage': lastMessage,
        'lastMessageTime': lastMessageTime,
        'lastSenderId': lastSenderId,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory ChatModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ChatModel(
      id: doc.id,
      sellerId: data['sellerId'] ?? '',
      buyerId: data['buyerId'] ?? '',
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: data['lastMessageTime'],
      lastSenderId: data['lastSenderId'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'],
    );
  }
}
