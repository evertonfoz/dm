import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient client;

  AuthRepository(this.client);

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await client.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Stream<AuthState> onAuthStateChange() {
    // wrap supabase stream
    return client.auth.onAuthStateChange.map((data) {
      return AuthState(event: data.event, session: data.session);
    });
  }
}

class AuthState {
  final AuthChangeEvent event;
  final Session? session;

  AuthState({required this.event, required this.session});
}
