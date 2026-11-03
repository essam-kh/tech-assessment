abstract class AuthRepository {
  bool get isSignedIn;

  Stream<bool> authChanges();

  Future<void> signIn({required String email, required String password});

  Future<void> signOut();
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
