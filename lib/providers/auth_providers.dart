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

  /// Send a password reset email to the given address.
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
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

  /// Update the current user's profile information.
  /// Updates Firebase Auth profile (displayName and email) when provided
  /// and keeps the Firestore `users/{uid}` document in sync.
  Future<void> updateProfile({String? displayName, String? email}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not signed in');

    // Update Firebase Auth profile where possible
    try {
      if (displayName != null) {
        await user.updateDisplayName(displayName);
        // Refresh to ensure the currentUser reflects the new displayName
        await user.reload();
      }
      // NOTE: updating auth email may require re-authentication and is
      // intentionally not performed here. If you need to support changing
      // email, implement a re-auth flow and then call `user.updateEmail`.
    } catch (e) {
      // Re-throw for caller to handle (UI will show error)
      rethrow;
    }

    // Update Firestore document
    final docRef = _db.collection('users').doc(user.uid);
    final updateData = <String, dynamic>{};
    if (displayName != null) updateData['displayName'] = displayName;
    if (email != null) updateData['email'] = email;
    if (updateData.isNotEmpty) {
      await docRef.set(updateData, SetOptions(merge: true));
    }
  }
}

final authControllerProvider = Provider<AuthController>(
  (ref) => AuthController(ref),
);
