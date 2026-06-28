import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';

class AuthResult {
  const AuthResult.success(this.user) : message = null;
  const AuthResult.failure(this.message) : user = null;

  final AppUser? user;
  final String? message;

  bool get isSuccess => user != null;
}

class AuthService {
  AuthService({
    firebase_auth.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final firebase_auth.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<AppUser?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return _loadAppUser(user);
    });
  }

  AppUser? get currentUser {
    final user = _auth.currentUser;
    return user == null ? null : _fromFirebaseUser(user);
  }

  List<AppUser> get testUsers => const [];

  Future<AuthResult> login({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    try {
      if (kIsWeb) {
        await _auth.setPersistence(
          rememberMe
              ? firebase_auth.Persistence.LOCAL
              : firebase_auth.Persistence.SESSION,
        );
      }
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      return AuthResult.success(await _loadAppUser(credential.user!));
    } on firebase_auth.FirebaseAuthException catch (error) {
      return AuthResult.failure(_messageFor(error));
    } catch (_) {
      return const AuthResult.failure(
        'Không thể kết nối Firebase. Hãy kiểm tra mạng và cấu hình dự án.',
      );
    }
  }

  Future<AuthResult> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final normalizedName = fullName.trim();
    if (normalizedName.length < 2) {
      return const AuthResult.failure('Vui lòng nhập họ tên hợp lệ.');
    }
    if (password != confirmPassword) {
      return const AuthResult.failure('Xác nhận mật khẩu chưa khớp.');
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      final user = credential.user!;
      await user.updateDisplayName(normalizedName);
      final appUser = AppUser(
        id: user.uid,
        fullName: normalizedName,
        email: user.email ?? email.trim().toLowerCase(),
      );
      await _firestore.collection('users').doc(user.uid).set({
        ...appUser.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return AuthResult.success(appUser);
    } on firebase_auth.FirebaseAuthException catch (error) {
      return AuthResult.failure(_messageFor(error));
    } catch (_) {
      return const AuthResult.failure(
        'Không thể tạo tài khoản. Hãy kiểm tra cấu hình Firestore.',
      );
    }
  }

  Future<void> logout() => _auth.signOut();

  Future<AppUser> saveUser(
    AppUser user, {
    Uint8List? avatarBytes,
  }) async {
    var savedUser = user;
    if (avatarBytes != null) {
      final ref = FirebaseStorage.instance
          .ref()
          .child('users/${user.id}/profile/avatar.jpg');
      await ref.putData(
        avatarBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      savedUser = user.copyWith(avatarUrl: await ref.getDownloadURL());
    }

    final authUser = _auth.currentUser;
    if (authUser != null && authUser.uid == savedUser.id) {
      await authUser.updateDisplayName(savedUser.fullName);
      if (savedUser.avatarUrl.isNotEmpty) {
        await authUser.updatePhotoURL(savedUser.avatarUrl);
      }
    }
    await _firestore.collection('users').doc(savedUser.id).set({
      ...savedUser.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return savedUser;
  }

  Future<String?> sendPasswordResetEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) return 'Vui lòng nhập email tài khoản.';
    try {
      await _auth.sendPasswordResetEmail(email: normalizedEmail);
      return null;
    } on firebase_auth.FirebaseAuthException catch (error) {
      return _messageFor(error);
    } catch (_) {
      return 'Không thể gửi email đặt lại mật khẩu. Vui lòng thử lại.';
    }
  }

  String? passwordFor(String email) => null;

  Future<AppUser> _loadAppUser(firebase_auth.User user) async {
    try {
      final snapshot = await _firestore.collection('users').doc(user.uid).get();
      if (snapshot.exists && snapshot.data() != null) {
        return AppUser.fromMap(user.uid, snapshot.data()!);
      }
    } catch (_) {
      // Auth vẫn hoạt động nếu profile Firestore tạm thời không tải được.
    }
    return _fromFirebaseUser(user);
  }

  AppUser _fromFirebaseUser(firebase_auth.User user) {
    return AppUser(
      id: user.uid,
      fullName: user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : (user.email?.split('@').first ?? 'Người dùng'),
      email: user.email ?? '',
      avatarUrl: user.photoURL ?? '',
    );
  }

  String _messageFor(firebase_auth.FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-email' => 'Email không hợp lệ.',
      'user-disabled' => 'Tài khoản này đã bị khóa.',
      'user-not-found' ||
      'invalid-credential' =>
        'Email hoặc mật khẩu không đúng.',
      'wrong-password' => 'Email hoặc mật khẩu không đúng.',
      'email-already-in-use' => 'Email này đã có tài khoản.',
      'weak-password' => 'Mật khẩu chưa đủ mạnh.',
      'too-many-requests' => 'Thử quá nhiều lần. Vui lòng chờ rồi thử lại.',
      'network-request-failed' => 'Không có kết nối mạng.',
      _ => error.message ?? 'Không thể xác thực tài khoản.',
    };
  }
}
