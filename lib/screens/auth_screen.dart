import 'package:flutter/material.dart';
import '../utils/helpers.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onLogin});

  final VoidCallback onLogin;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _showRegister = false;
  bool _rememberMe = true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 44,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Tài chính Freelancer',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Theo dõi dự án, công nợ và quỹ dự phòng cá nhân',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    ),
                    const SizedBox(height: 22),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('Đăng nhập'), icon: Icon(Icons.login)),
                        ButtonSegment(value: true, label: Text('Đăng ký'), icon: Icon(Icons.person_add_alt_1_outlined)),
                      ],
                      selected: {_showRegister},
                      onSelectionChanged: (value) => setState(() => _showRegister = value.first),
                    ),
                    const SizedBox(height: 18),
                    if (_showRegister) ...[
                      const AuthTextField(label: 'Họ và tên', icon: Icons.person_outline),
                      const SizedBox(height: 12),
                    ],
                    const AuthTextField(
                      label: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    const AuthTextField(
                      label: 'Mật khẩu',
                      icon: Icons.lock_outline,
                      obscureText: true,
                    ),
                    if (_showRegister) ...[
                      const SizedBox(height: 12),
                      const AuthTextField(
                        label: 'Xác nhận mật khẩu',
                        icon: Icons.verified_user_outlined,
                        obscureText: true,
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        value: _rememberMe,
                        onChanged: (value) => setState(() => _rememberMe = value ?? true),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text('Ghi nhớ đăng nhập'),
                      ),
                    ],
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: widget.onLogin,
                      icon: Icon(_showRegister ? Icons.person_add : Icons.login),
                      label: Text(_showRegister ? 'Tạo tài khoản' : 'Đăng nhập'),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => setState(() => _showRegister = !_showRegister),
                      child: Text(_showRegister ? 'Đã có tài khoản? Đăng nhập' : 'Chưa có tài khoản? Đăng ký'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key, required this.label, required this.icon,
    this.obscureText = false, this.keyboardType,
  });

  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}