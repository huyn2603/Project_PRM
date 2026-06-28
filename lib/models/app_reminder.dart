import 'project_finance.dart';

enum ReminderKind { paymentDue, paymentOverdue, deliveryDue, teamPayout }

class AppReminder {
  const AppReminder({
    required this.id,
    required this.kind,
    required this.title,
    required this.message,
    required this.projectId,
    required this.tabIndex,
    required this.dueDate,
    this.isRead = false,
  });

  final String id;
  final ReminderKind kind;
  final String title;
  final String message;
  final String projectId;
  final int tabIndex;
  final DateTime? dueDate;
  final bool isRead;

  bool get isUrgent =>
      kind == ReminderKind.paymentOverdue ||
      (dueDate != null && dueDate!.isBefore(DateTime.now()));

  AppReminder copyWith({bool? isRead}) => AppReminder(
        id: id,
        kind: kind,
        title: title,
        message: message,
        projectId: projectId,
        tabIndex: tabIndex,
        dueDate: dueDate,
        isRead: isRead ?? this.isRead,
      );
}

List<AppReminder> buildProjectReminders(
  List<ProjectFinance> projects, {
  int reminderDays = 7,
  DateTime? now,
}) {
  final todaySource = now ?? DateTime.now();
  final today = DateTime(todaySource.year, todaySource.month, todaySource.day);
  final reminders = <AppReminder>[];

  for (final project in projects) {
    final paymentDate = _parseDate(project.dueDate);
    if (paymentDate != null && project.remaining > 0) {
      final days = paymentDate.difference(today).inDays;
      if (days < 0) {
        reminders.add(
          AppReminder(
            id: '${project.id}-payment-overdue',
            kind: ReminderKind.paymentOverdue,
            title: 'Thanh toán đã quá hạn',
            message:
                'Dự án “${project.name}” đã quá hạn ${days.abs()} ngày. Hãy chủ động liên hệ và bàn bạc với ${project.client}.',
            projectId: project.id,
            tabIndex: 2,
            dueDate: paymentDate,
          ),
        );
      } else if (days <= reminderDays) {
        reminders.add(
          AppReminder(
            id: '${project.id}-payment-$days',
            kind: ReminderKind.paymentDue,
            title: 'Sắp đến hạn thanh toán',
            message: days == 0
                ? 'Dự án “${project.name}” đến hạn thanh toán hôm nay.'
                : 'Dự án “${project.name}” còn $days ngày đến hạn thanh toán. Hãy chuẩn bị trao đổi với ${project.client}.',
            projectId: project.id,
            tabIndex: 2,
            dueDate: paymentDate,
          ),
        );
      }
    }

    final deliveryDate = _parseDate(project.deliveryDate);
    if (deliveryDate != null && project.progress < 1) {
      final days = deliveryDate.difference(today).inDays;
      if (days <= reminderDays) {
        reminders.add(
          AppReminder(
            id: '${project.id}-delivery-$days',
            kind: ReminderKind.deliveryDue,
            title: days < 0 ? 'Đã quá hạn bàn giao' : 'Sắp đến hạn bàn giao',
            message: days < 0
                ? 'Dự án “${project.name}” đã quá hạn bàn giao ${days.abs()} ngày.'
                : days == 0
                    ? 'Dự án “${project.name}” cần bàn giao cho khách hôm nay.'
                    : 'Dự án “${project.name}” còn $days ngày để hoàn thiện và bàn giao cho khách.',
            projectId: project.id,
            tabIndex: 1,
            dueDate: deliveryDate,
          ),
        );
      }
    }

    final unpaidMembers = project.teamMembers
        .where((member) => project.memberPayable(member) > 0)
        .length;
    if (project.workMode == ProjectWorkMode.team && unpaidMembers > 0) {
      reminders.add(
        AppReminder(
          id: '${project.id}-team-payout',
          kind: ReminderKind.teamPayout,
          title: 'Chưa hoàn tất chia tiền nhóm',
          message:
              'Dự án “${project.name}” đang có ${project.teamPayable.toStringAsFixed(0)} ₫ cần chia cho $unpaidMembers thành viên theo tiền khách đã trả.',
          projectId: project.id,
          tabIndex: 3,
          dueDate: null,
        ),
      );
    }
  }

  reminders.sort((a, b) {
    if (a.isUrgent != b.isUrgent) return a.isUrgent ? -1 : 1;
    final aDate = a.dueDate ?? DateTime(9999);
    final bDate = b.dueDate ?? DateTime(9999);
    return aDate.compareTo(bDate);
  });
  return reminders;
}

DateTime? _parseDate(String value) {
  final match =
      RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(value.trim());
  if (match == null) return null;
  final day = int.tryParse(match.group(1)!);
  final month = int.tryParse(match.group(2)!);
  final year = int.tryParse(match.group(3)!);
  if (day == null || month == null || year == null) return null;
  final date = DateTime(year, month, day);
  return date.day == day && date.month == month && date.year == year
      ? date
      : null;
}
