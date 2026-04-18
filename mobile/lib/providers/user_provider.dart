import 'package:flutter/material.dart';
import 'package:mobile/models/user_model.dart';
import 'package:mobile/services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  String? _currentUserId;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Called by [ChangeNotifierProxyProvider] whenever [AuthProvider] changes.
  void updateUserId(String? userId) {
    if (_currentUserId == userId) return; // no change
    _currentUserId = userId;

    // Always clear stale data immediately when the user changes.
    _user = null;
    _error = null;

    if (userId == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Load fresh profile for the newly logged-in user.
    loadUser(userId);
  }

  Future<void> loadUser(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _userService.getUserProfile(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearUser() {
    _currentUserId = null;
    _user = null;
    _error = null;
    notifyListeners();
  }
}
