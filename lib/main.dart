import 'package:flutter/material.dart';

import 'models/app_user.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const FreelanceFinanceApp());
}

class FreelanceFinanceApp extends StatelessWidget {
  const FreelanceFinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tài chính Freelancer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF256D85),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F7F2),
        fontFamily: 'Roboto',
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService();
  AppUser? _currentUser;

  void _handleAuthenticated(AppUser user) {
    setState(() => _currentUser = user);
  }

  void _handleLogout() {
    _authService.logout();
    setState(() => _currentUser = null);
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;
    if (user != null) {
      return FinanceHomePage(user: user, onLogout: _handleLogout);
    }

    return LoginPage(
      authService: _authService,
      onAuthenticated: _handleAuthenticated,
    );
  }
}
