import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../screens/login_otp_screen.dart';

class AuthGuard {
  /// Check if user is authenticated. If not, redirect to LoginOtpScreen.
  /// Returns true if authenticated, false if redirected.
  static bool checkAuth(BuildContext context, {VoidCallback? onAuthenticated}) {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    if (appState.isAuthenticated) {
      if (onAuthenticated != null) {
        onAuthenticated();
      }
      return true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in or create an account to continue.'),
          backgroundColor: Colors.amber,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginOtpScreen()),
      ).then((_) {
        // Re-check auth status upon returning from login screen
        final updatedState = Provider.of<AppStateProvider>(context, listen: false);
        if (updatedState.isAuthenticated && onAuthenticated != null) {
          onAuthenticated();
        }
      });
      return false;
    }
  }
}
