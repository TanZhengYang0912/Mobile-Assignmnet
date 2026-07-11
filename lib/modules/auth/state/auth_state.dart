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

  Map<String, dynamic>? get _metadata =>
      Supabase.instance.client.auth.currentUser?.userMetadata;

  /// Custom display name if the user has set one (Profile tab), otherwise
  /// derived from their email's local part.
  String get displayName {
    final custom = _metadata?['display_name'] as String?;
    if (custom != null && custom.trim().isNotEmpty) return custom.trim();
    final email = _email ?? '';
    if (email.isEmpty) return 'there';
    return email.split('@').first.replaceAll('.', ' ').replaceAllMapped(
          RegExp(r'\b\w'),
          (m) => m.group(0)!.toUpperCase(),
        );
  }

  String? get phoneNumber => _metadata?['phone_number'] as String?;
  String? get gender => _metadata?['gender'] as String?;

  /// Persists any combination of display name, phone number, and gender to
  /// the Supabase auth user's metadata and notifies listeners so every
  /// screen using [displayName]/[phoneNumber]/[gender] refreshes.
  Future<bool> updateProfile({
    String? displayName,
    String? phoneNumber,
    String? gender,
  }) async {
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {
          if (displayName != null) 'display_name': displayName,
          if (phoneNumber != null) 'phone_number': phoneNumber,
          if (gender != null) 'gender': gender,
        }),
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Could not update profile: $e';
      notifyListeners();
      return false;
    }
  }

  /// Persists the full profile collected by the post-registration setup
  /// wizard in a single write.
  Future<bool> completeProfileSetup({
    required String displayName,
    required String gender,
    required String phoneNumber,
    required String serviceAddress,
    required String serviceState,
  }) async {
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {
          'display_name': displayName,
          'gender': gender,
          'phone_number': phoneNumber,
          'service_address': serviceAddress,
          'service_state': serviceState,
        }),
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Could not save profile: $e';
      notifyListeners();
      return false;
    }
  }

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
