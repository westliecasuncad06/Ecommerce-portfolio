import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';

class ApproveSellersScreen extends ConsumerWidget {
  const ApproveSellersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);
    final query = db
        .collection('users')
        .where('role', isEqualTo: 'user')
        .where('sellerRequested', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots();
    return Scaffold(
      appBar: AppBar(title: const Text('Approve Sellers')),
      body: StreamBuilder<QuerySnapshot>(
        stream: query,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No pending requests'));
          }
          final docs = snapshot.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemBuilder: (c, i) {
              final d = docs[i];
              final data = d.data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.storefront),
                  title: Text(data['email'] ?? d.id),
                  subtitle: const Text('Requested seller access'),
                  trailing: Wrap(spacing: 8, children: [
                    OutlinedButton(
                      onPressed: () async {
                        await db.collection('users').doc(d.id).update({'sellerRequested': false});
                      },
                      child: const Text('Reject'),
                    ),
                    FilledButton(
                      onPressed: () async {
                        await db.collection('users').doc(d.id).update({
                          'role': 'seller',
                          'sellerRequested': false,
                          'sellerApproved': true,
                        });
                      },
                      child: const Text('Approve'),
                    ),
                  ]),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: docs.length,
          );
        },
      ),
    );
  }
}
