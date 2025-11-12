import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';
// imports kept minimal

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    return auth.when(
      data: (appUser) {
        if (appUser == null) return const Scaffold(body: Center(child: Text('Not signed in')));
        // initialize controllers if empty
        if (_nameCtrl.text.isEmpty) _nameCtrl.text = appUser.displayName ?? '';
        if (_emailCtrl.text.isEmpty) _emailCtrl.text = appUser.email;

        return Scaffold(
          appBar: AppBar(title: const Text('Edit Profile')),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (_error != null) ...[
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                ],
                TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Display name')),
                const SizedBox(height: 12),
                TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading
                        ? null
                        : () async {
                            setState(() {
                              _loading = true;
                              _error = null;
                            });
                            try {
                              await ref.read(authControllerProvider).updateProfile(
                                    displayName: _nameCtrl.text.trim(),
                                    email: _emailCtrl.text.trim(),
                                  );
                              // Refresh the authState provider so UI reads updated Firestore user doc
                              ref.invalidate(authStateProvider);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
                              Navigator.of(context).pop();
                            } catch (e) {
                              setState(() {
                                _error = e.toString();
                              });
                            } finally {
                              if (mounted) setState(() => _loading = false);
                            }
                          },
                    child: _loading ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}
