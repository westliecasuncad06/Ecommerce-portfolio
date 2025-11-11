import 'package:cloud_firestore/cloud_firestore.dart';

class StoreProfile {
  final String id;
  final String storeName;
  final String? storeDescription;
  final String? storeLogo;
  final String? storeBanner;
  final String? contactEmail;
  final String? phone;
  final String? address;
  final Map<String, dynamic>? socialLinks;
  final double? rating;
  final int? followers;
  final DateTime? createdAt;

  StoreProfile({
    required this.id,
    required this.storeName,
    this.storeDescription,
    this.storeLogo,
    this.storeBanner,
    this.contactEmail,
    this.phone,
    this.address,
    this.socialLinks,
    this.rating,
    this.followers,
    this.createdAt,
  });

  factory StoreProfile.fromMap(String id, Map<String, dynamic> m) => StoreProfile(
        id: id,
        storeName: m['storeName'] ?? '',
        storeDescription: m['storeDescription'],
        storeLogo: m['storeLogo'],
        storeBanner: m['storeBanner'],
        contactEmail: m['contactEmail'],
        phone: m['phone'],
        address: m['address'],
        socialLinks: m['socialLinks'] != null ? Map<String, dynamic>.from(m['socialLinks']) : null,
        rating: (m['rating'] ?? 0).toDouble(),
        followers: (m['followers'] ?? 0) as int,
        createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toMap() => {
        'storeName': storeName,
        'storeDescription': storeDescription,
        'storeLogo': storeLogo,
        'storeBanner': storeBanner,
        'contactEmail': contactEmail,
        'phone': phone,
        'address': address,
        'socialLinks': socialLinks,
        'rating': rating,
        'followers': followers,
        'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      };
}
