import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/app_reminder.dart';

class AuthScope extends InheritedWidget {
  const AuthScope({
    super.key,
    required this.user,
    required this.onLogout,
    required this.reminders,
    required this.onReminderSelected,
    required this.onUserChanged,
    required super.child,
  });

  final AppUser user;
  final VoidCallback onLogout;
  final List<AppReminder> reminders;
  final ValueChanged<AppReminder> onReminderSelected;
  final ValueChanged<AppUser> onUserChanged;

  static AuthScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AuthScope>();
  }

  @override
  bool updateShouldNotify(AuthScope oldWidget) {
    return oldWidget.user != user ||
        oldWidget.onLogout != onLogout ||
        oldWidget.reminders != reminders ||
        oldWidget.onReminderSelected != onReminderSelected ||
        oldWidget.onUserChanged != onUserChanged;
  }
}
