import 'package:flutter/material.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

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
  bool _isSignedIn = false;

  void _openDashboard() {
    setState(() => _isSignedIn = true);
  }

  @override
  Widget build(BuildContext context) {
    // Nếu đã đăng nhập, điều hướng thẳng vào trang quản lý chính
    if (_isSignedIn) {
      return const FinanceHomePage();
    }

    // Nếu chưa đăng nhập, hiển thị màn hình Đăng nhập / Đăng ký
    return LoginPage(onLogin: _openDashboard);
  }
}