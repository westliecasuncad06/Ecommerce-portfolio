import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';

final firebaseAuthProvider = Provider<fb.FirebaseAuth>(
  (_) => fb.FirebaseAuth.instance,
);
final firestoreProvider = Provider<FirebaseFirestore>(
  (_) => FirebaseFirestore.instance,
);

// Raw auth changes
final authChangesProvider = Provider<Stream<fb.User?>>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

// Stream of AppUser based on auth
final authStateProvider = StreamProvider<AppUser?>((ref) async* {
  final auth = ref.watch(firebaseAuthProvider);
  await for (final user in auth.authStateChanges()) {
    if (user == null) {
      yield null;
      continue;
    }
    final doc = await ref
        .watch(firestoreProvider)
        .collection('users')
        .doc(user.uid)
        .get();
    if (!doc.exists) {
      final newUser = AppUser(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        role: UserRole.user,
        createdAt: DateTime.now(),
      );
      await ref
          .watch(firestoreProvider)
          .collection('users')
          .doc(user.uid)
          .set(newUser.toMap());
      yield newUser;
    } else {
      yield AppUser.fromDoc(doc);
    }
  }
});

class AuthController {
  AuthController(this._ref);
  final Ref _ref;

  FirebaseFirestore get _db => _ref.read(firestoreProvider);
  fb.FirebaseAuth get _auth => _ref.read(firebaseAuthProvider);

  Future<void> signOut() => _auth.signOut();

  Future<fb.UserCredential> signInWithEmail(
    String email,
    String password,
  ) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred;
  }

  Future<fb.UserCredential> signUpWithEmail(
    String email,
    String password,
  ) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred;
  }

  Future<void> ensureUserDocument(fb.User user) async {
    final doc = _db.collection('users').doc(user.uid);
    final snap = await doc.get();
    if (!snap.exists) {
      await doc.set({
        'email': user.email,
        'displayName': user.displayName,
        'role': UserRole.user.name,
        'createdAt': FieldValue.serverTimestamp(),
        'sellerApproved': false,
        'sellerRequested': false,
      });
    }
  }
}

final authControllerProvider = Provider<AuthController>(
  (ref) => AuthController(ref),
);
