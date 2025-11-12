import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'seller_dashboard_screen.dart';
import 'manage_products_screen.dart';
import 'seller_orders_screen.dart';
import 'seller_earnings_screen.dart';
import 'seller_profile_screen.dart';
import '../../core/theme.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_providers.dart';

class SellerShell extends ConsumerStatefulWidget {
  const SellerShell({super.key});

  @override
  ConsumerState<SellerShell> createState() => _SellerShellState();
}

class _SellerShellState extends ConsumerState<SellerShell> {
  int _currentIndex = 0;

  // Pages: keep Seller Dashboard (home) as first tab, then Products, Orders, Earnings, Profile
  final List<Widget> _pages = [
    // When embedded in the shell, don't show the dashboard's own app bar
    SellerDashboardScreen(showAppBar: false),
    ManageProductsScreen(showAppBar: false),
    SellerOrdersScreen(showAppBar: false),
    SellerEarningsScreen(showAppBar: false),
    const SellerProfileScreen(),
  ];

  final List<String> _titles = ['Home', 'Products', 'Orders', 'Earnings', 'Profile'];

  @override
  Widget build(BuildContext context) {
    final fbUser = ref.watch(firebaseAuthProvider).currentUser;
    final sellerId = fbUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        actions: [
          // Unread messages badge
          if (sellerId != null)
            Consumer(
              builder: (ctx, r, child) {
                final unread = r.watch(unreadMessagesProvider(sellerId));
                return unread.when(
                  data: (count) => IconButton(
                    tooltip: 'Messages',
                    icon: Stack(
                      children: [
                        const Icon(Icons.chat_bubble_outline),
                        if (count > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                              child: Text(
                                '$count',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: () async {
                      await r.read(chatServiceProvider).clearUnread(sellerId);
                      context.push('/seller/messages');
                    },
                  ),
                  loading: () => IconButton(
                    tooltip: 'Messages',
                    icon: const Icon(Icons.chat_bubble_outline),
                    onPressed: () => context.push('/seller/messages'),
                  ),
                  error: (_, __) => IconButton(
                    tooltip: 'Messages',
                    icon: const Icon(Icons.chat_bubble_outline),
                    onPressed: () => context.push('/seller/messages'),
                  ),
                );
              },
            )
          else
            IconButton(
              tooltip: 'Messages',
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () => context.push('/seller/messages'),
            ),

          // Logout
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_outlined),
            onPressed: () async => await ref.read(authControllerProvider).signOut(),
          ),
          const SizedBox(width: 8),
        ],
      ),

  body: IndexedStack(index: _currentIndex, children: _pages),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.surface,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.textSecondary,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Products'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Earnings'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
