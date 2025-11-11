import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_providers.dart';
import '../../providers/app_providers.dart';
import '../../models/store_profile.dart';
import '../../models/product.dart';
import '../../core/theme.dart';

class SellerDashboardScreen extends ConsumerWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fbUser = ref.watch(firebaseAuthProvider).currentUser;
    if (fbUser == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: const Text('Seller Dashboard')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, size: 64, color: AppTheme.textSecondary),
              SizedBox(height: 16),
              Text('Please sign in', style: TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
        ),
      );
    }

    final sellerId = fbUser.uid;
    final storeFuture = ref.watch(storeServiceProvider).fetchStore(sellerId);
    final productsAsync = ref.watch(sellerProductsProvider(sellerId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            floating: true,
            elevation: 0,
            backgroundColor: AppTheme.surface,
            title: Text(
              'Seller Dashboard',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            actions: [
              // Show unread messages badge for seller (use when to handle loading/error)
              Consumer(
                builder: (ctx, ref, child) {
                  final unread = ref.watch(unreadMessagesProvider(sellerId));
                  return unread.when(
                    data: (count) {
                      return IconButton(
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
                          // Clear unread count when seller opens messages
                          await ref.read(chatServiceProvider).clearUnread(sellerId);
                          context.push('/seller/messages');
                        },
                      );
                    },
                    loading: () => IconButton(
                      tooltip: 'Messages',
                      icon: const Icon(Icons.chat_bubble_outline),
                      onPressed: () async {
                        await ref.read(chatServiceProvider).clearUnread(sellerId);
                        context.push('/seller/messages');
                      },
                    ),
                    error: (e, st) => IconButton(
                      tooltip: 'Messages',
                      icon: const Icon(Icons.chat_bubble_outline),
                      onPressed: () async {
                        await ref.read(chatServiceProvider).clearUnread(sellerId);
                        context.push('/seller/messages');
                      },
                    ),
                  );
                },
              ),
              IconButton(
                tooltip: 'Logout',
                icon: const Icon(Icons.logout_outlined),
                onPressed: () async => await ref.read(authControllerProvider).signOut(),
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Store Profile Banner
          SliverToBoxAdapter(
            child: FutureBuilder<StoreProfile?>(
              future: storeFuture,
              builder: (ctx, snap) {
                final profile = snap.data;
                return Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, Color(0xFF0D47A1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        // Store Logo
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 35,
                            backgroundColor: AppTheme.background,
                            backgroundImage: profile?.storeLogo != null
                                ? NetworkImage(profile!.storeLogo!)
                                : null,
                            child: profile?.storeLogo == null
                                ? const Icon(Icons.store, size: 35, color: AppTheme.primary)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Store Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile?.storeName ?? 'Your Store',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                profile?.storeDescription ?? 'Set up your store',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),

                              // Action Buttons
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => context.push('/seller/store'),
                                    icon: const Icon(Icons.edit, size: 16),
                                    label: const Text('Edit Store'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.secondary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => context.push('/store/$sellerId'),
                                    icon: const Icon(Icons.public, size: 16),
                                    label: const Text('View'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(color: Colors.white),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Quick Stats Grid
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overview',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  productsAsync.when(
                    data: (products) {
                      final totalProducts = products.length;
                      final totalSold = products.fold<int>(0, (sum, p) => sum + p.sold);
                      final totalRevenue = products.fold<double>(
                        0,
                        (sum, p) => sum + (p.price * p.sold),
                      );
                      
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _ModernStatCard(
                                  title: 'Total Sales',
                                  value: '\$${totalRevenue.toStringAsFixed(2)}',
                                  icon: Icons.attach_money,
                                  color: AppTheme.success,
                                  subtitle: '$totalSold items sold',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ModernStatCard(
                                  title: 'Products',
                                  value: '$totalProducts',
                                  icon: Icons.inventory_2_outlined,
                                  color: AppTheme.primary,
                                  subtitle: 'In catalog',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _ModernStatCard(
                                  title: 'Orders',
                                  value: '0',
                                  icon: Icons.shopping_bag_outlined,
                                  color: AppTheme.info,
                                  subtitle: 'Pending',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ModernStatCard(
                                  title: 'Low Stock',
                                  value: '${products.where((p) => p.stock <= 5).length}',
                                  icon: Icons.warning_amber_outlined,
                                  color: AppTheme.warning,
                                  subtitle: 'Items',
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Center(child: Text('Error: $e')),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Quick Actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionCard(
                          title: 'Products',
                          icon: Icons.inventory_2_outlined,
                          color: AppTheme.primary,
                          onTap: () => context.push('/seller/products'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionCard(
                          title: 'Orders',
                          icon: Icons.shopping_bag_outlined,
                          color: AppTheme.info,
                          onTap: () => context.push('/seller/orders'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionCard(
                          title: 'Earnings',
                          icon: Icons.account_balance_wallet_outlined,
                          color: AppTheme.success,
                          onTap: () => context.push('/seller/earnings'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Consumer(
                          builder: (ctx, ref, child) {
                            final unread = ref.watch(unreadMessagesProvider(sellerId));
                            return Stack(
                              children: [
                                _QuickActionCard(
                                  title: 'Messages',
                                  icon: Icons.chat_bubble_outline,
                                  color: AppTheme.secondary,
                                  onTap: () async {
                                    await ref.read(chatServiceProvider).clearUnread(sellerId);
                                    context.push('/seller/messages');
                                  },
                                ),
                                unread.when(
                                  data: (count) => count > 0
                                      ? Positioned(
                                          right: 12,
                                          top: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                                            child: Text(
                                              '$count',
                                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                  loading: () => const SizedBox.shrink(),
                                  error: (_, __) => const SizedBox.shrink(),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Low Stock & Top Selling Sections
          SliverToBoxAdapter(
            child: productsAsync.when(
              data: (products) {
                final lowStock = products.where((p) => p.stock <= 5).toList();
                final topSelling = List<Product>.from(products)
                  ..sort((a, b) => b.sold.compareTo(a.sold));

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Low Stock Alert
                      _DashboardSection(
                        title: 'Low Stock Alert',
                        icon: Icons.warning_amber_outlined,
                        iconColor: AppTheme.warning,
                        child: lowStock.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: Text(
                                    'All products are well stocked',
                                    style: TextStyle(color: AppTheme.textSecondary),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: lowStock.length > 5 ? 5 : lowStock.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (ctx, idx) {
                                  final p = lowStock[idx];
                                  return ListTile(
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: p.imageUrls.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: p.imageUrls.first,
                                              width: 48,
                                              height: 48,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              width: 48,
                                              height: 48,
                                              color: AppTheme.background,
                                              child: const Icon(Icons.image),
                                            ),
                                    ),
                                    title: Text(
                                      p.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text('\$${p.price.toStringAsFixed(2)}'),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: p.stock == 0
                                            ? AppTheme.error.withValues(alpha: 0.1)
                                            : AppTheme.warning.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Stock: ${p.stock}',
                                        style: TextStyle(
                                          color: p.stock == 0 ? AppTheme.error : AppTheme.warning,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    onTap: () => context.push('/seller/products'),
                                  );
                                },
                              ),
                      ),

                      const SizedBox(height: 16),

                      // Top Selling
                      _DashboardSection(
                        title: 'Top Selling Products',
                        icon: Icons.trending_up,
                        iconColor: AppTheme.success,
                        child: topSelling.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: Text(
                                    'No sales data yet',
                                    style: TextStyle(color: AppTheme.textSecondary),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: topSelling.length > 5 ? 5 : topSelling.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (ctx, idx) {
                                  final p = topSelling[idx];
                                  return ListTile(
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: p.imageUrls.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: p.imageUrls.first,
                                              width: 48,
                                              height: 48,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              width: 48,
                                              height: 48,
                                              color: AppTheme.background,
                                              child: const Icon(Icons.image),
                                            ),
                                    ),
                                    title: Text(
                                      p.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text('\$${p.price.toStringAsFixed(2)}'),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.success.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Sold: ${p.sold}',
                                        style: const TextStyle(
                                          color: AppTheme.success,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    onTap: () => context.push('/seller/products'),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, st) => Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(child: Text('Error: $e')),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),

      // Floating Action Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/seller/products'),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
        backgroundColor: AppTheme.secondary,
      ),
    );
  }
}

// Modern Stat Card Widget
class _ModernStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _ModernStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

// Quick Action Card Widget
class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// Dashboard Section Widget
class _DashboardSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _DashboardSection({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}
