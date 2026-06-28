class NotificationIntent {
  const NotificationIntent({
    required this.tabIndex,
    required this.type,
    this.userId,
    this.projectId,
    this.notificationId,
  });

  final int tabIndex;
  final String type;
  final String? userId;
  final String? projectId;
  final String? notificationId;

  bool get opensProject => tabIndex == 1 && projectId?.isNotEmpty == true;

  factory NotificationIntent.fromData(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? 'general';
    final screen = data['screen']?.toString();
    final tabIndex = switch (screen) {
      'dashboard' => 0,
      'projects' => 1,
      'payments' => 2,
      'teamPayouts' => 3,
      'reserve' => 4,
      'stats' => 5,
      _ => switch (type) {
          'project_updated' || 'project_risk' => 1,
          'payment_due' || 'payment_overdue' || 'payment_received' => 2,
          'team_payout_available' || 'team_payout_recorded' => 3,
          'reserve_low' => 4,
          'monthly_report' => 5,
          _ => 0,
        },
    };

    String? optionalString(String key) {
      final value = data[key]?.toString().trim();
      return value == null || value.isEmpty ? null : value;
    }

    return NotificationIntent(
      tabIndex: tabIndex,
      type: type,
      userId: optionalString('userId'),
      projectId: optionalString('projectId'),
      notificationId: optionalString('notificationId'),
    );
  }
}
