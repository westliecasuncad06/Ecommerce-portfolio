import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../providers/auth_providers.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _isLogin = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = ref.read(authControllerProvider);
    try {
      if (_isLogin) {
        await auth.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        await auth.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      }
    } on fb.FirebaseAuthException catch (e) {
      if (!mounted) return;
      // Map Firebase error codes to friendly messages
      String friendly;
      switch (e.code) {
        case 'invalid-email':
          friendly = 'The email address is not valid.';
          break;
        case 'user-disabled':
          friendly = 'This account has been disabled.';
          break;
        case 'user-not-found':
          friendly = 'No account found for that email.';
          break;
        case 'wrong-password':
          friendly = 'Incorrect password. Try again.';
          break;
        case 'email-already-in-use':
          friendly = 'This email is already registered.';
          break;
        case 'network-request-failed':
          friendly = 'Network error. Check your connection.';
          break;
        default:
          friendly = e.message ?? e.code;
      }

      // For sign-up, offer reset/sign-in via dialog when appropriate
      if (!_isLogin && e.code == 'email-already-in-use') {
        // Show dialog offering sign-in or reset
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Email already in use'),
            content: const Text('This email is already registered. Would you like to sign in or reset your password?'),
            actions: [
              TextButton(onPressed: () { Navigator.of(ctx).pop(); }, child: const Text('Cancel')),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  setState(() => _isLogin = true);
                },
                child: const Text('Sign In'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  try {
                    await auth.sendPasswordResetEmail(_emailController.text.trim());
                    if (!mounted) return;
                    setState(() => _error = 'Password reset email sent.');
                  } catch (err) {
                    if (!mounted) return;
                    setState(() => _error = 'Reset failed: $err');
                  }
                },
                child: const Text('Reset Password'),
              ),
            ],
          ),
        );
      } else {
        setState(() => _error = friendly);
      }
    } catch (e) {
      if (!mounted) return; // guard against using context after dispose
      setState(() => _error = 'Auth error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _isLogin ? 'Sign In' : 'Create Account',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (v) => v != null && v.contains('@')
                          ? null
                          : 'Enter a valid email',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      validator: (v) =>
                          v != null && v.length >= 6 ? null : 'Min 6 chars',
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isLogin ? 'Sign In' : 'Sign Up'),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _isLogin = !_isLogin),
                      child: Text(
                        _isLogin
                            ? 'Need an account? Sign Up'
                            : 'Have an account? Sign In',
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
