import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/order_model.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_providers.dart';

class SellerOrdersScreen extends ConsumerWidget {
  const SellerOrdersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fbUser = ref.watch(firebaseAuthProvider).currentUser;
    if (fbUser == null) return const Center(child: Text('Not signed in'));
    final sellerId = fbUser.uid;
    final ordersAsync = ref.watch(sellerOrdersProvider(sellerId));

    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) return const Center(child: Text('No orders yet'));
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, idx) {
              final o = orders[idx];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text('Order ${o.id} — ₱${o.total.toStringAsFixed(2)}'),
                  subtitle: Text('${o.items.length} items • ${o.createdAt}'),
                  trailing: PopupMenuButton<OrderStatus>(
                    onSelected: (s) async {
                      await ref.read(orderServiceProvider).updateOrderStatus(o.id, s);
                      // TODO: push notification to buyer via FCM integration
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Order ${o.id} set to ${s.name}')),
                      );
                    },
                    itemBuilder: (ctx) {
                      return OrderStatus.values
                          .map((s) => PopupMenuItem<OrderStatus>(value: s, child: Text(s.name)))
                          .toList();
                    },
                    child: Chip(label: Text(o.status.name)),
                  ),
                  onTap: () => _showOrderDetails(context, ref, o),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showOrderDetails(BuildContext context, WidgetRef ref, AppOrder o) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order ${o.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Buyer: ${o.userId}'),
            const SizedBox(height: 8),
            ...o.items.map((it) => ListTile(
                  title: Text(it.title),
                  subtitle: Text('Qty ${it.qty} • ₱${it.price}'),
                )),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final newStatus = OrderStatus.shipped;
                    await ref.read(orderServiceProvider).updateOrderStatus(o.id, newStatus);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order marked shipped')));
                  },
                  child: const Text('Mark Shipped'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final tracking = await _askForTracking(context);
                    if (tracking != null && tracking.isNotEmpty) {
                      await ref.read(orderServiceProvider).setTrackingNumber(o.id, tracking);
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tracking saved')));
                    }
                  },
                  child: const Text('Add Tracking'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<String?> _askForTracking(BuildContext context) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter tracking number'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Tracking #')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()), child: const Text('Save')),
        ],
      ),
    );
  }
}
