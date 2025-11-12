import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../models/store_profile.dart';
import '../../models/product.dart';
import '../../models/cart_item.dart';
import '../../services/store_service.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_providers.dart';
import '../../core/theme.dart';
import '../../core/cart_badge.dart';

class StorefrontScreen extends ConsumerStatefulWidget {
  final String sellerId;
  const StorefrontScreen({super.key, required this.sellerId});

  @override
  ConsumerState<StorefrontScreen> createState() => _StorefrontScreenState();
}

class _StorefrontScreenState extends ConsumerState<StorefrontScreen> {

  @override
  Widget build(BuildContext context) {
    final storeSvc = StoreService(ref.watch(dbProvider));
    final productSvc = ref.watch(productServiceProvider);
    final followSvc = ref.watch(storeFollowServiceProvider);
    final ratingSvc = ref.watch(storeRatingServiceProvider);
    final fbUser = ref.watch(firebaseAuthProvider).currentUser;
    final userId = fbUser?.uid ?? '';

    final storeFuture = storeSvc.fetchStore(widget.sellerId);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: FutureBuilder<StoreProfile?>(
        future: storeFuture,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final profile = snap.data;
          
          return CustomScrollView(
            slivers: [
              // Modern Store Header
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                elevation: 0,
                backgroundColor: AppTheme.surface,
                // If the current user is the store owner, show an edit action
                actions: [
                  if (userId.isNotEmpty && userId == widget.sellerId)
                    IconButton(
                      tooltip: 'Edit Store',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () async {
                        // Navigate to the existing store edit screen and refresh when returned
                        await context.push('/seller/store');
                        if (mounted) setState(() {});
                      },
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primary,
                          AppTheme.primary.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Store Logo
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: AppTheme.background,
                              backgroundImage: profile?.storeLogo != null
                                  ? NetworkImage(profile!.storeLogo!)
                                  : null,
                              child: profile?.storeLogo == null
                                  ? const Icon(Icons.store, size: 50, color: AppTheme.primary)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Store Name
                          Text(
                            profile?.storeName ?? 'Store',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          // Store Stats
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.star, size: 18, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                profile?.rating?.toStringAsFixed(1) ?? '0.0',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Icon(Icons.people, size: 18, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text(
                                '${profile?.followers ?? 0} followers',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Store Description & Action Buttons
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
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
                      if (profile?.storeDescription != null) ...[
                        Text(
                          'About Store',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          profile!.storeDescription!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      
                      // Action Buttons (Follow / Rate / Message)
                      if (userId.isNotEmpty && userId != widget.sellerId)
                        LayoutBuilder(
                          builder: (ctx, constraints) {
                            final narrow = constraints.maxWidth < 420;
                            final followBtn = FutureBuilder<bool>(
                              future: followSvc.isFollowing(userId, widget.sellerId),
                              builder: (ctx, followSnap) {
                                final isFollowing = followSnap.data ?? false;
                                return ElevatedButton.icon(
                                  onPressed: () async {
                                    if (isFollowing) {
                                      await followSvc.unfollowStore(userId, widget.sellerId);
                                    } else {
                                      await followSvc.followStore(userId, widget.sellerId);
                                    }
                                    setState(() {});
                                  },
                                  icon: Icon(isFollowing ? Icons.check : Icons.add),
                                  label: Text(isFollowing ? 'Following' : 'Follow'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isFollowing ? AppTheme.textSecondary : AppTheme.primary,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                );
                              },
                            );

                            final rateBtn = OutlinedButton.icon(
                              onPressed: () => _showRatingDialog(ratingSvc, userId),
                              icon: const Icon(Icons.star_border),
                              label: const Text('Rate'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            );

                            final msgBtn = OutlinedButton.icon(
                              onPressed: () => context.push('/chat/${widget.sellerId}', extra: profile?.storeName),
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: const Text('Message'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            );

                            if (narrow) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  followBtn,
                                  const SizedBox(height: 8),
                                  rateBtn,
                                  const SizedBox(height: 8),
                                  msgBtn,
                                ],
                              );
                            }

                            // Wide layout - a single row
                            return Row(
                              children: [
                                Expanded(flex: 2, child: followBtn),
                                const SizedBox(width: 12),
                                Expanded(child: rateBtn),
                                const SizedBox(width: 12),
                                Expanded(child: msgBtn),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),

              // Products Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Text(
                    'Products',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Products Grid
              StreamBuilder<List<Product>>(
                stream: productSvc.watchProductsBySeller(widget.sellerId),
                builder: (ctx, psnap) {
                  if (psnap.connectionState != ConnectionState.active &&
                      psnap.connectionState != ConnectionState.done) {
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  
                  final products = psnap.data ?? [];
                  
                  if (products.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 80,
                              color: AppTheme.textSecondary.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No products available',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, idx) {
                          final product = products[idx];
                          return _StoreProductCard(product: product);
                        },
                        childCount: products.length,
                      ),
                      // Make grid responsive based on available width so cards scale well
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width >= 1000
                            ? 4
                            : MediaQuery.of(context).size.width >= 700
                                ? 3
                                : 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        // Slightly taller cards reduce cramped layouts on short viewports
                        childAspectRatio: MediaQuery.of(context).size.width >= 700
                            ? 0.75
                            : (MediaQuery.of(context).size.width < 480 ? 0.62 : 0.70),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
      // Bottom bar with quick actions. If the signed-in user is the store owner,
      // show Edit and Manage actions. Otherwise show Message and Share.
      bottomNavigationBar: FutureBuilder<StoreProfile?>(
        future: storeFuture,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) return const SizedBox.shrink();
          final profile = snap.data;
          final isOwner = userId.isNotEmpty && userId == widget.sellerId;

          return BottomAppBar(
            color: AppTheme.surface,
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (isOwner) {
                          await context.push('/seller/store');
                          if (mounted) setState(() {});
                        } else {
                          // Message the seller
                          context.push('/chat/${widget.sellerId}', extra: profile?.storeName);
                        }
                      },
                      icon: Icon(isOwner ? Icons.edit : Icons.chat_bubble_outline),
                      label: Text(isOwner ? 'Edit Store' : 'Message'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (isOwner) {
                          // Navigate to seller products management
                          context.push('/seller/products');
                        } else {
                          // Share the store link
                          // For now, open the storefront route which can be shared externally
                          // (Sharing implementation can be added later)
                          final link = '/store/${widget.sellerId}';
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Share link: $link')));
                        }
                      },
                      icon: Icon(isOwner ? Icons.storefront : Icons.share),
                      label: Text(isOwner ? 'Manage Products' : 'Share'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

    void _showRatingDialog(dynamic ratingSvc, String userId) {
    int selectedRating = 5;
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Rate this store'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final star = index + 1;
                  return IconButton(
                    icon: Icon(
                      star <= selectedRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        selectedRating = star;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentCtrl,
                decoration: const InputDecoration(
                  labelText: 'Comment (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await ratingSvc.rateStore(
                  userId: userId,
                  sellerId: widget.sellerId,
                  rating: selectedRating,
                  comment: commentCtrl.text.trim().isEmpty ? null : commentCtrl.text.trim(),
                );
                if (mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Thank you for rating!')),
                  );
                  setState(() {}); // Refresh to show updated rating
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

// Modern Store Product Card Widget
class _StoreProductCard extends ConsumerWidget {
  final Product product;

  const _StoreProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => context.push('/product/${product.id}'),
      borderRadius: BorderRadius.circular(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.hardEdge,
        child: Container(
          color: AppTheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: product.imageUrls.isEmpty
                          ? Container(
                              color: AppTheme.background,
                              child: const Icon(Icons.image, size: 48, color: AppTheme.textSecondary),
                            )
                          : CachedNetworkImage(
                              imageUrl: product.imageUrls.first,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: AppTheme.background,
                                child: const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: AppTheme.background,
                                child: const Icon(Icons.broken_image, size: 48),
                              ),
                            ),
                    ),
                  ),
                  if (product.stock < 10)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: product.stock == 0 ? AppTheme.error : AppTheme.warning,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product.stock == 0 ? 'Out' : 'Low',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Product Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Spacer(),

                      // Add to Cart Button
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: double.infinity,
                          minHeight: 36,
                          maxHeight: 40,
                        ),
                        child: ElevatedButton(
                          onPressed: product.stock == 0
                              ? null
                              : () async {
                                  final svc = ref.read(cartServiceProvider);
                                  if (svc == null) return;
                                  await svc.addItem(CartItem(
                                    productId: product.id,
                                    title: product.title,
                                    price: product.price,
                                    qty: 1,
                                    imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
                                  ));
                                  incrementCartBadge();

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Added to cart'),
                                        behavior: SnackBarBehavior.floating,
                                        action: SnackBarAction(
                                          label: 'VIEW',
                                          textColor: AppTheme.secondary,
                                          onPressed: () {
                                            // Navigate to cart
                                          },
                                        ),
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            // Let the ConstrainedBox control the button height. Use
                            // shrink-wrapped tap target and compact density to avoid
                            // extra vertical padding that causes fractional overflow.
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_shopping_cart, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Add',
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
