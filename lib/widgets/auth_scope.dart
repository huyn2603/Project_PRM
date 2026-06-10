import 'package:flutter/material.dart';

import '../models/app_user.dart';

class AuthScope extends InheritedWidget {
  const AuthScope({
    super.key,
    required this.user,
    required this.onLogout,
    required super.child,
  });

  final AppUser user;
  final VoidCallback onLogout;

  static AuthScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AuthScope>();
  }

  @override
  bool updateShouldNotify(AuthScope oldWidget) {
    return oldWidget.user != user || oldWidget.onLogout != onLogout;
  }
}
