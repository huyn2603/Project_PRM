import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../utils/helpers.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.authService,
    required this.onAuthenticated,
  });

  final AuthService authService;
  final ValueChanged<AppUser> onAuthenticated;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showRegister = false;
  bool _rememberMe = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    final result = _showRegister
        ? await widget.authService.register(
            fullName: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            confirmPassword: _confirmPasswordController.text,
          )
        : await widget.authService.login(
            email: _emailController.text,
            password: _passwordController.text,
            rememberMe: _rememberMe,
          );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isSuccess) {
      widget.onAuthenticated(result.user!);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(result.message ?? 'Không thể xác thực tài khoản.')),
    );
  }

  void _toggleMode() {
    setState(() {
      _showRegister = !_showRegister;
      _confirmPasswordController.clear();
    });
  }

  void _fillTestAccount(AppUser user) {
    setState(() {
      _showRegister = false;
      _emailController.text = user.email;
      _passwordController.text =
          widget.authService.passwordFor(user.email) ?? '';
      _confirmPasswordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: cardDecoration(),
                child: Form(
                  key: _formKey,
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
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Freelancer quản lý dự án, công nợ và quỹ dự phòng',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.black54),
                      ),
                      const SizedBox(height: 22),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: false,
                            label: Text('Đăng nhập'),
                            icon: Icon(Icons.login),
                          ),
                          ButtonSegment(
                            value: true,
                            label: Text('Đăng ký'),
                            icon: Icon(Icons.person_add_alt_1_outlined),
                          ),
                        ],
                        selected: {_showRegister},
                        onSelectionChanged: _isLoading
                            ? null
                            : (value) =>
                                setState(() => _showRegister = value.first),
                      ),
                      const SizedBox(height: 18),
                      if (_showRegister) ...[
                        AuthTextField(
                          controller: _nameController,
                          label: 'Họ và tên',
                          icon: Icons.person_outline,
                          validator: (value) {
                            if ((value ?? '').trim().length < 2) {
                              return 'Nhập họ tên hợp lệ.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      AuthTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          final email = (value ?? '').trim();
                          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(email)) {
                            return 'Email không hợp lệ.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      AuthTextField(
                        controller: _passwordController,
                        label: 'Mật khẩu',
                        icon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Hiện mật khẩu'
                              : 'Ẩn mật khẩu',
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                        validator: (value) {
                          if ((value ?? '').length < 6) {
                            return 'Mật khẩu cần ít nhất 6 ký tự.';
                          }
                          return null;
                        },
                      ),
                      if (_showRegister) ...[
                        const SizedBox(height: 12),
                        AuthTextField(
                          controller: _confirmPasswordController,
                          label: 'Xác nhận mật khẩu',
                          icon: Icons.verified_user_outlined,
                          obscureText: _obscureConfirmPassword,
                          suffixIcon: IconButton(
                            tooltip: _obscureConfirmPassword
                                ? 'Hiện mật khẩu'
                                : 'Ẩn mật khẩu',
                            onPressed: () => setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            ),
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                          validator: (value) {
                            if (value != _passwordController.text) {
                              return 'Xác nhận mật khẩu chưa khớp.';
                            }
                            return null;
                          },
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          value: _rememberMe,
                          onChanged: _isLoading
                              ? null
                              : (value) =>
                                  setState(() => _rememberMe = value ?? true),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: const Text('Ghi nhớ đăng nhập'),
                        ),
                      ],
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: _isLoading ? null : _submit,
                        icon: _isLoading
                            ? const SizedBox.square(
                                dimension: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                _showRegister ? Icons.person_add : Icons.login),
                        label: Text(
                          _showRegister ? 'Tạo tài khoản' : 'Đăng nhập',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _isLoading ? null : _toggleMode,
                        child: Text(
                          _showRegister
                              ? 'Đã có tài khoản? Đăng nhập'
                              : 'Chưa có tài khoản? Đăng ký',
                        ),
                      ),
                      if (!_showRegister) ...[
                        const Divider(height: 28),
                        Text(
                          'Tài khoản freelancer test',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.authService.testUsers
                              .map(
                                (user) => ActionChip(
                                  avatar: CircleAvatar(
                                    child: Text(
                                      user.initials,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                  label: Text(user.email),
                                  onPressed: _isLoading
                                      ? null
                                      : () => _fillTestAccount(user),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
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
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
