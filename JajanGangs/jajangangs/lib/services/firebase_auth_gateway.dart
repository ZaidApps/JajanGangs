import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/firebase_web_config.dart';
import '../models/auth_session.dart';
import 'auth_gateway.dart';
import 'auth_error_mapper.dart';

class FirebaseAuthGateway implements AuthGateway {
  FirebaseAuthGateway({this.languageCode});
  final String Function()? languageCode;
  final _drafts = SharedPreferencesAsync();
  final _pendingAvatars = <String, String>{};
  FirebaseAuth? _auth;
  Future<void>? _initialization;
  Future<void>? _googleInitialization;
  FirebaseAuth get auth => _auth!;

  @override
  Future<void> initialize() async {
    try {
      await (_initialization ??= _initialize());
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  Future<void> _initialize() async {
    try {
      if (kIsWeb && !FirebaseWebConfig.configured) {
        throw const AuthFailure('webNotConfigured');
      }
      if (!kIsWeb &&
          defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS) {
        throw const AuthFailure('platformUnsupported');
      }
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: kIsWeb ? FirebaseWebConfig.options : null,
        );
      }
      _auth = FirebaseAuth.instance;
    } catch (error) {
      _initialization = null;
      throw mapAuthFailure(error);
    }
  }

  AuthSession? _session(User? user) => user == null
      ? null
      : AuthSession(
          uid: user.uid,
          email: user.email ?? '',
          verified: user.emailVerified,
          displayName: user.displayName,
          passwordAccount: user.providerData.any(
            (p) => p.providerId == 'password',
          ),
        );
  @override
  AuthSession? get session => _session(_auth?.currentUser);
  @override
  Stream<AuthSession?> get sessions => auth.userChanges().map(_session);

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (error) {
      throw mapAuthFailure(error);
    }
  }

  @override
  Future<void> login(String email, String password) => _guard(() async {
    await auth.signInWithEmailAndPassword(email: email, password: password);
  });
  @override
  Future<void> register(
    String name,
    String email,
    String password,
    String avatarId,
  ) => _guard(() async {
    if (!AvatarCatalog.contains(avatarId))
      throw const AuthFailure('avatarRequired');
    final result = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = result.user!.uid;
    _pendingAvatars[uid] = avatarId;
    // A private per-account draft survives the email-verification round trip.
    // Never write unverified profiles or store credentials in preferences.
    try {
      await _drafts.setString('registration_avatar_$uid', avatarId);
    } catch (_) {}
    // Persist the name in Auth first; verified users get a Firestore profile later.
    await result.user!.updateDisplayName(name);
  });
  @override
  Future<void> google() => _guard(() async {
    if (kIsWeb) {
      await auth.signInWithPopup(
        GoogleAuthProvider()..setCustomParameters({
          'prompt': 'select_account',
          'hl': languageCode?.call() ?? 'en',
        }),
      );
      return;
    }
    const iosClient = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
    const serverClient = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
    // Native defaults: Android reads google-services.json; iOS reads
    // GIDClientID in Runner/Info.plist. Dart defines are optional overrides.
    _googleInitialization ??= GoogleSignIn.instance.initialize(
      clientId: iosClient.isEmpty ? null : iosClient,
      serverClientId: serverClient.isEmpty ? null : serverClient,
    );
    try {
      await _googleInitialization;
    } catch (_) {
      _googleInitialization = null;
      rethrow;
    }
    final account = await GoogleSignIn.instance.authenticate();
    final token = account.authentication.idToken;
    if (token == null) throw const AuthFailure('googleTokenError');
    await auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: token),
    );
  });
  @override
  Future<void> sendVerification() => _guard(() async {
    final user = auth.currentUser;
    if (user == null) throw const AuthFailure('signInAgain');
    await auth.setLanguageCode(languageCode?.call() ?? 'en');
    await user.sendEmailVerification();
  });
  @override
  Future<void> refreshUser() => _guard(() async {
    await auth.currentUser?.reload();
    // Refresh the token so Firestore sees email_verified after verification.
    if (auth.currentUser?.emailVerified == true)
      await auth.currentUser!.getIdToken(true);
  });
  @override
  Future<void> resetPassword(String email) => _guard(() async {
    try {
      await auth.setLanguageCode(languageCode?.call() ?? 'en');
      await auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (error) {
      // Do not reveal whether the submitted address has an account.
      if (error.code != 'user-not-found') rethrow;
    }
  });
  @override
  Future<UserProfile?> readProfile(String uid) => _guard(() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 20));
    if (!snapshot.exists) return null;
    final data = snapshot.data()!;
    final name = data['name'];
    final avatar = data['avatarId'];
    return UserProfile(
      name: name is String && AuthValidation.name(name) == null ? name : null,
      avatarId: avatar is String && AvatarCatalog.contains(avatar)
          ? avatar
          : null,
    );
  });
  @override
  Future<String?> readRegistrationAvatar(String uid) async {
    if (_pendingAvatars.containsKey(uid)) return _pendingAvatars[uid];
    try {
      final value = await _drafts.getString('registration_avatar_$uid');
      return AvatarCatalog.contains(value) ? value : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveProfile(String uid, String name, String avatarId) => _guard(
    () async {
      if (!AvatarCatalog.contains(avatarId))
        throw const AuthFailure('avatarRequired');
      final invalidName = AuthValidation.name(name);
      if (invalidName != null) throw AuthFailure(invalidName);
      final reference = FirebaseFirestore.instance.collection('users').doc(uid);
      await FirebaseFirestore.instance
          .runTransaction((transaction) async {
            final existing = await transaction.get(reference);
            transaction.set(reference, {
              'name': AuthValidation.cleanName(name),
              'avatarId': avatarId,
              if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          })
          .timeout(const Duration(seconds: 20));
      _pendingAvatars.remove(uid);
      try {
        await _drafts.remove('registration_avatar_$uid');
      } catch (_) {}
    },
  );
  @override
  Future<void> signOut() => _guard(() async {
    await auth.signOut();
    if (!kIsWeb && _googleInitialization != null) {
      // Firebase sign-out must succeed even if clearing the provider chooser fails.
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
  });
}
