import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Hardcoded staff email -> role lookup. Anyone not listed here signs in
/// as a normal user. Fix first; swap for a `profiles` table once role
/// management needs to be self-service.
const Map<String, String> _staffRoles = {
  'admin@mysumber.my': 'admin',
  'worker@mysumber.my': 'worker',
};

class RoleState extends ChangeNotifier {
  String? _userRole;
  String? _email;
  bool _isLoading = false;
  String? _errorMessage;

  String? get userRole => _userRole;
  String? get email => _email;
  bool get isLoggedIn => _userRole != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String _resolveRole(String? email) =>
      _staffRoles[email?.toLowerCase()] ?? 'user';

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> checkExistingSession() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        _email = session.user.email;
        _userRole = _resolveRole(_email);
        notifyListeners();
      }
    } catch (e) {
      // No existing session
    }
  }

  Future<bool> register(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        _email = email;
        _userRole = _resolveRole(email);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _email = email;
        _userRole = _resolveRole(email);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Supabase.instance.client.auth.signOut();
      _userRole = null;
      _email = null;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error logging out: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
}
