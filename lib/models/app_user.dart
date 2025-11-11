import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { user, seller, admin }

class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final UserRole role;
  final DateTime createdAt;
  final bool sellerApproved;
  final bool sellerRequested;

  AppUser({
    required this.id,
    required this.email,
    this.displayName,
    required this.role,
    required this.createdAt,
    this.sellerApproved = false,
    this.sellerRequested = false,
  });

  factory AppUser.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      role: _roleFromString(data['role'] ?? 'user'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      sellerApproved: data['sellerApproved'] ?? false,
      sellerRequested: data['sellerRequested'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'sellerApproved': sellerApproved,
      'sellerRequested': sellerRequested,
    };
  }

  static UserRole _roleFromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserRole.user,
    );
  }
}
