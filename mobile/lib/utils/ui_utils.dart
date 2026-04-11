import 'package:flutter/material.dart';

class UIUtils {
  // Translate Firebase/Firestore errors into user-friendly messages
  static String getFriendlyErrorMessage(dynamic error) {
    String errorStr = error.toString().toLowerCase();

    // Authentication Errors
    if (errorStr.contains('invalid-credential') || errorStr.contains('wrong-password') || errorStr.contains('user-not-found')) {
      return 'Invalid email or password. Please try again.';
    }
    if (errorStr.contains('email-already-in-use')) {
      return 'This email is already registered. Try logging in.';
    }
    if (errorStr.contains('weak-password')) {
      return 'Password is too weak. Please use at least 6 characters.';
    }
    if (errorStr.contains('network-request-failed')) {
      return 'Network error. Please check your internet connection.';
    }
    if (errorStr.contains('too-many-requests')) {
      return 'Too many failed attempts. Please try again later.';
    }
    if (errorStr.contains('user-disabled')) {
      return 'This account has been disabled. Please contact support.';
    }
    if (errorStr.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }

    // Generic fallback - strip common technical prefixes
    return errorStr
        .replaceAll('exception:', '')
        .replaceAll('firebaseauthxception:', '')
        .replaceAll('googlefirestoreexception:', '')
        .replaceAll('login failed:', '')
        .replaceAll('registration failed:', '')
        .trim();
  }

  // Common SnackBar style
  static void showSnackBar(BuildContext context, String message, {bool isError = true}) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent.shade400 : Colors.teal.shade700,
        behavior: SnackBarBehavior.fixed,
        duration: const Duration(seconds: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: 4,
      ),
    );
  }
}
