import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/seller_earnings_service.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_providers.dart';

class SellerEarningsScreen extends ConsumerWidget {
  final bool showAppBar;
  const SellerEarningsScreen({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fbUser = ref.watch(firebaseAuthProvider).currentUser;
    if (fbUser == null) return const Center(child: Text('Not signed in'));
    final sellerId = fbUser.uid;
    final svc = SellerEarningsService(ref.watch(dbProvider));

    return Scaffold(
      appBar: showAppBar ? AppBar(title: const Text('Earnings')) : null,
      body: FutureBuilder<Map<String, dynamic>>(
        future: svc.fetchSummary(sellerId),
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final data = snap.data ?? {};
          final total = (data['totalEarnings'] ?? 0).toDouble();
          final pending = (data['pendingPayout'] ?? 0).toDouble();
          final transactions = (data['transactions'] as List<dynamic>? ?? []);
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.attach_money),
                    title: Text('Total earnings'),
                    subtitle: Text('₱${total.toStringAsFixed(2)}'),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.account_balance_wallet),
                    title: Text('Pending payout'),
                    subtitle: Text('₱${pending.toStringAsFixed(2)}'),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Transactions', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, idx) {
                      final t = Map<String, dynamic>.from(transactions[idx]);
                      final date = t['date']?.toString() ?? '';
                      return ListTile(
                        title: Text('Order ${t['orderId']}'),
                        subtitle: Text('${t['status']} • $date'),
                        trailing: Text('₱${(t['amount'] ?? 0).toDouble().toStringAsFixed(2)}'),
                      );
                    },
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
