import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_providers.dart';

class ManageProductsScreen extends ConsumerWidget {
  const ManageProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
    return products.when(
      data: (list) {
        final myProducts = list.where((p) => p.sellerId == uid).toList();
        return Scaffold(
          appBar: AppBar(title: const Text('My Products')),
          body: myProducts.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('No products found.\nYou can add one using the button below.', textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => context.push('/seller/products/new'),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Product'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (c, i) {
                    final p = myProducts[i];
                    return Card(
                      child: ListTile(
                        leading: p.imageUrls.isEmpty
                            ? const Icon(Icons.image)
                            : CachedNetworkImage(imageUrl: p.imageUrls.first, width: 56, height: 56, fit: BoxFit.cover),
                        title: Text(p.title),
                        subtitle: Text('\$${p.price.toStringAsFixed(2)} • stock ${p.stock} • ${p.status}'),
                        onTap: () => context.push('/product/${p.id}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => context.push('/seller/products/${p.id}'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete product'),
                                    content: const Text('Are you sure you want to archive this product?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                      TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Archive')),
                                    ],
                                  ),
                                );
                                if (ok == true) {
                                  try {
                                    await ref.read(productServiceProvider).deactivate(p.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product archived')));
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                    }
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemCount: myProducts.length,
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/seller/products/new'),
            icon: const Icon(Icons.add),
            label: const Text('Add'),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('My Products')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              const Text('Loading products...'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.refresh(productsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      error: (e, st) => Scaffold(
        appBar: AppBar(title: const Text('My Products')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Error loading products:\n$e', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.refresh(productsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
