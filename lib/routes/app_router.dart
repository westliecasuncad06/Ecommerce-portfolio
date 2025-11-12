import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';

import '../screens/splash_screen.dart';
import '../screens/auth/sign_in_screen.dart';
import '../screens/user/user_home_screen.dart';
import '../screens/user/product_detail_screen.dart';
import '../screens/seller/seller_shell.dart';
import '../screens/seller/manage_products_screen.dart';
import '../screens/seller/edit_product_screen.dart';
import '../screens/seller/seller_orders_screen.dart';
import '../screens/seller/seller_earnings_screen.dart';
import '../screens/seller/store_profile_edit_screen.dart';
import '../screens/seller/seller_reviews_screen.dart';
import '../screens/seller/seller_messages_screen.dart';
import '../screens/user/chat_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/approve_sellers_screen.dart';
import '../screens/user/storefront_screen.dart';
import '../providers/auth_providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(ref.watch(authChangesProvider)),
    routes: [
      GoRoute(
        name: 'splash',
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        name: 'signIn',
        path: '/sign-in',
        builder: (_, __) => const SignInScreen(),
      ),
      GoRoute(
        name: 'userHome',
        path: '/user',
        builder: (_, __) => const UserHomeScreen(),
      ),
      GoRoute(
        name: 'productDetail',
        path: '/product/:id',
        builder: (_, state) => ProductDetailScreen(
          productId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        name: 'sellerHome',
        path: '/seller',
        builder: (_, __) => const SellerShell(),
      ),
      GoRoute(
        name: 'sellerOrders',
        path: '/seller/orders',
        builder: (_, __) => const SellerOrdersScreen(),
      ),
      GoRoute(
        name: 'sellerEarnings',
        path: '/seller/earnings',
        builder: (_, __) => const SellerEarningsScreen(),
      ),
      GoRoute(
        name: 'sellerStoreProfile',
        path: '/seller/store',
        builder: (_, __) => const StoreProfileEditScreen(),
      ),
      GoRoute(
        name: 'sellerReviews',
        path: '/seller/reviews',
        builder: (_, __) => const SellerReviewsScreen(),
      ),
      GoRoute(
        name: 'sellerMessages',
        path: '/seller/messages',
        builder: (_, __) => const SellerMessagesScreen(),
      ),
      GoRoute(
        name: 'chat',
        path: '/chat/:sellerId',
        builder: (_, state) => ChatScreen(
          sellerId: state.pathParameters['sellerId']!,
          sellerName: state.extra is String ? state.extra as String : null,
        ),
      ),
      GoRoute(
        name: 'sellerProducts',
        path: '/seller/products',
        builder: (_, __) => const ManageProductsScreen(),
      ),
      GoRoute(
        name: 'sellerProductNew',
        path: '/seller/products/new',
        builder: (_, __) => const EditProductScreen(),
      ),
      GoRoute(
        name: 'sellerProductEdit',
        path: '/seller/products/:id',
        builder: (_, state) => EditProductScreen(productId: state.pathParameters['id']),
      ),
      GoRoute(
        name: 'storefront',
        path: '/store/:sellerId',
        builder: (_, state) => StorefrontScreen(sellerId: state.pathParameters['sellerId']!),
      ),
      GoRoute(
        name: 'adminHome',
        path: '/admin',
        builder: (_, __) => const AdminDashboardScreen(),
      ),
      GoRoute(
        name: 'adminApproveSellers',
        path: '/admin/approve-sellers',
        builder: (_, __) => const ApproveSellersScreen(),
      ),
    ],
    redirect: (context, state) {
      final isAuthKnown = authState.maybeWhen(
        data: (_) => true,
        orElse: () => false,
      );
      final user = authState.asData?.value;
      final loc = state.matchedLocation;
      final isSplash = loc == '/splash';
      final isSignIn = loc == '/sign-in';

      if (!isAuthKnown) return isSplash ? null : '/splash';

      if (user == null) return isSignIn ? null : '/sign-in';

  // User logged in; route by role
  // Allow public product detail, storefront and chat routes for all users
  if (loc.startsWith('/product') || loc.startsWith('/store') || loc.startsWith('/chat')) return null;
      // Allow subpaths for each role (e.g. /seller/products, /seller/products/:id)
      switch (user.role) {
        case UserRole.user:
          return loc.startsWith('/user') ? null : '/user';
        case UserRole.seller:
          return loc.startsWith('/seller') ? null : '/seller';
        case UserRole.admin:
          return loc.startsWith('/admin') ? null : '/admin';
      }
    },
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
