import 'package:flutter/foundation.dart';

class RoleState extends ChangeNotifier {
  String? _userRole;

  String? get userRole => _userRole;
  bool get isLoggedIn => _userRole != null;

  void setRole(String role) {
    _userRole = role;
    notifyListeners();
  }

  void logout() {
    _userRole = null;
    notifyListeners();
  }
}
