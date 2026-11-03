import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._auth);

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
      throw const AuthFailure(
        'Could not reach the server. Check your connection.',
      );
    } on AuthApiException catch (e) {
      throw AuthFailure(_apiMessage(e));
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } catch (_) {
      throw const AuthFailure('Something went wrong. Try again.');
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
