import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/store_profile.dart';
import '../../services/store_service.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_providers.dart';

class StoreProfileEditScreen extends ConsumerStatefulWidget {
  const StoreProfileEditScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<StoreProfileEditScreen> createState() => _StoreProfileEditScreenState();
}

class _StoreProfileEditScreenState extends ConsumerState<StoreProfileEditScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fbUser = ref.watch(firebaseAuthProvider).currentUser;
    if (fbUser == null) return const Center(child: Text('Not signed in'));
    final sellerId = fbUser.uid;
    final svc = StoreService(ref.watch(dbProvider));

    return Scaffold(
      appBar: AppBar(title: const Text('Store Profile')),
      body: FutureBuilder<StoreProfile?>(
        future: svc.fetchStore(sellerId),
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          final profile = snap.data;
          if (profile != null) {
            _nameCtrl.text = profile.storeName;
            _descCtrl.text = profile.storeDescription ?? '';
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Store name')),
                const SizedBox(height: 8),
                TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    final updated = StoreProfile(
                      id: sellerId,
                      storeName: _nameCtrl.text.trim(),
                      storeDescription: _descCtrl.text.trim(),
                    );
                    await svc.updateStore(sellerId, updated);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Store updated')));
                  },
                  child: const Text('Save'),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
