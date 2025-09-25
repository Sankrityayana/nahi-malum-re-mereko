import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  bool _loading = false;

  bool get loading => _loading;
  Session? get session => _supabase.auth.currentSession;

  Future<void> signIn(String email, String password) async {
    _loading = true; notifyListeners();
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<void> signUp(String email, String password) async {
    _loading = true; notifyListeners();
    try {
      await _supabase.auth.signUp(email: email, password: password);
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
