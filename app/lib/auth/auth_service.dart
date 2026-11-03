import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils.dart';

abstract class AuthService {
  bool get isSignedIn;

  Stream<bool> authChanges();

  Future<void> signIn({required String email, required String password});

  Future<void> signOut();
}

class SupabaseAuthService implements AuthService {
  SupabaseAuthService(this._auth);

  final GoTrueClient _auth;

  @override
  bool get isSignedIn => _auth.currentSession != null;

  @override
  Stream<bool> authChanges() =>
      _auth.onAuthStateChange.map((state) => state.session != null).distinct();

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithPassword(email: email, password: password);
    } on AuthRetryableFetchException {
      throw const AppFailure(
        'Could not reach the server. Check your connection.',
      );
    } on AuthApiException catch (e) {
      throw AppFailure(_apiMessage(e));
    } on AuthException catch (e) {
      throw AppFailure(e.message);
    } catch (_) {
      throw const AppFailure('Something went wrong. Try again.');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on AuthException {
      return;
    }
  }

  String _apiMessage(AuthApiException e) {
    if (e.code == 'invalid_credentials') return 'Invalid email or password';
    if (e.statusCode == '429') return 'Too many attempts. Try again later.';
    return e.message;
  }
}

final authServiceProvider = Provider<AuthService>(
  (_) => SupabaseAuthService(Supabase.instance.client.auth),
);
