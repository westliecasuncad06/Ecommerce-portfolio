import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/order_model.dart';
import '../providers/auth_providers.dart';
import '../services/product_service.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../services/storage_service.dart';
import '../services/store_service.dart';
import '../services/seller_earnings_service.dart';
import '../services/store_follow_service.dart';
import '../services/store_rating_service.dart';
import '../services/chat_service.dart';

// Firestore instance
final dbProvider = Provider<FirebaseFirestore>((_) => FirebaseFirestore.instance);

// Services
final productServiceProvider = Provider<ProductService>((ref) {
  return ProductService(ref.watch(dbProvider));
});

final cartServiceProvider = Provider<CartService?>((ref) {
  final fbUser = ref.watch(firebaseAuthProvider).currentUser;
  if (fbUser == null) return null;
  return CartService(ref.watch(dbProvider), fbUser.uid);
});

final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService(ref.watch(dbProvider));
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(FirebaseStorage.instance);
});

final storeServiceProvider = Provider<StoreService>((ref) {
  return StoreService(ref.watch(dbProvider));
});

final sellerEarningsServiceProvider = Provider<SellerEarningsService>((ref) {
  return SellerEarningsService(ref.watch(dbProvider));
});

final storeFollowServiceProvider = Provider<StoreFollowService>((ref) {
  return StoreFollowService(ref.watch(dbProvider));
});

final storeRatingServiceProvider = Provider<StoreRatingService>((ref) {
  return StoreRatingService(ref.watch(dbProvider));
});

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService.fromDb(ref.watch(dbProvider));
});

// Stream of unread message counts for a given seller id
final unreadMessagesProvider = StreamProvider.family<int, String>((ref, sellerId) {
  final svc = ref.watch(chatServiceProvider);
  return svc.watchUnread(sellerId);
});

// Data streams
final productsProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(productServiceProvider).watchActiveProducts();
});

final cartItemsProvider = StreamProvider<List<CartItem>>((ref) {
  final svc = ref.watch(cartServiceProvider);
  if (svc == null) return const Stream.empty();
  return svc.watchCart();
});

final userOrdersProvider = StreamProvider.family<List<AppOrder>, String>((ref, userId) {
  return ref.watch(orderServiceProvider).watchUserOrders(userId);
});

final sellerOrdersProvider = StreamProvider.family<List<AppOrder>, String>((ref, sellerId) {
  return ref.watch(orderServiceProvider).watchSellerOrders(sellerId);
});

final sellerProductsProvider = StreamProvider.family<List<Product>, String>((ref, sellerId) {
  return ref.watch(productServiceProvider).watchProductsBySeller(sellerId);
});

// Tracks unseen cart additions (notifications badge)
// cart badge is handled by a lightweight ValueNotifier in `lib/core/cart_badge.dart`
