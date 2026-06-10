import '../models/app_user.dart';

class AuthResult {
  const AuthResult.success(this.user) : message = null;
  const AuthResult.failure(this.message) : user = null;

  final AppUser? user;
  final String? message;

  bool get isSuccess => user != null;
}

class _AccountRecord {
  _AccountRecord({required this.user, required this.password});

  final AppUser user;
  String password;
}

class AuthService {
  AuthService() {
    _seedAccounts();
  }

  final Map<String, _AccountRecord> _accounts = {};
  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;

  List<AppUser> get testUsers =>
      _accounts.values.map((record) => record.user).toList();

  Future<AuthResult> login({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final normalizedEmail = email.trim().toLowerCase();
    final account = _accounts[normalizedEmail];

    if (account == null) {
      return const AuthResult.failure('Email chưa được đăng ký.');
    }
    if (account.password != password) {
      return const AuthResult.failure('Mật khẩu không đúng.');
    }

    _currentUser = account.user;
    return AuthResult.success(account.user);
  }

  Future<AuthResult> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final normalizedName = fullName.trim();
    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedName.length < 2) {
      return const AuthResult.failure('Vui lòng nhập họ tên hợp lệ.');
    }
    if (!_isValidEmail(normalizedEmail)) {
      return const AuthResult.failure('Email không hợp lệ.');
    }
    if (password.length < 6) {
      return const AuthResult.failure('Mật khẩu cần ít nhất 6 ký tự.');
    }
    if (password != confirmPassword) {
      return const AuthResult.failure('Xác nhận mật khẩu chưa khớp.');
    }
    if (_accounts.containsKey(normalizedEmail)) {
      return const AuthResult.failure('Email này đã có tài khoản.');
    }

    final user = AppUser(
      id: 'user-${DateTime.now().microsecondsSinceEpoch}',
      fullName: normalizedName,
      email: normalizedEmail,
    );
    _accounts[normalizedEmail] = _AccountRecord(user: user, password: password);
    _currentUser = user;
    return AuthResult.success(user);
  }

  void logout() {
    _currentUser = null;
  }

  String? passwordFor(String email) {
    return _accounts[email.trim().toLowerCase()]?.password;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  void _seedAccounts() {
    final seeded = [
      (
        user: const AppUser(
          id: 'seed-freelancer-1',
          fullName: 'Nguyễn Minh Anh',
          email: 'freelancer@test.com',
        ),
        password: '123456',
      ),
      (
        user: const AppUser(
          id: 'seed-freelancer-2',
          fullName: 'Trần Gia Bảo',
          email: 'bao@test.com',
        ),
        password: '123456',
      ),
    ];

    for (final account in seeded) {
      _accounts[account.user.email] = _AccountRecord(
        user: account.user,
        password: account.password,
      );
    }
  }
}
