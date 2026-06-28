import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelance_finance_app/main.dart';
import 'package:freelance_finance_app/models/app_reminder.dart';
import 'package:freelance_finance_app/models/notification_intent.dart';
import 'package:freelance_finance_app/models/project_finance.dart';

void main() {
  testWidgets('shows actionable setup screen before Firebase is configured',
      (tester) async {
    await tester.pumpWidget(
      const FreelanceFinanceApp(
        firebaseReady: false,
        firebaseError: 'Chưa chạy flutterfire configure.',
      ),
    );

    expect(find.text('Cần kết nối Firebase'), findsOneWidget);
    expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);
    expect(find.textContaining('flutterfire configure'), findsWidgets);
  });

  test('notification payload maps to the correct tab and project', () {
    final intent = NotificationIntent.fromData(const {
      'type': 'project_risk',
      'screen': 'projects',
      'userId': 'user-1',
      'projectId': 'project-7',
      'notificationId': 'notification-9',
    });

    expect(intent.tabIndex, 1);
    expect(intent.opensProject, isTrue);
    expect(intent.userId, 'user-1');
    expect(intent.projectId, 'project-7');
  });

  test('unknown notification safely falls back to dashboard', () {
    final intent = NotificationIntent.fromData(const {'type': 'unknown'});
    expect(intent.tabIndex, 0);
    expect(intent.opensProject, isFalse);
  });

  test('team split follows the percentage of money actually received', () {
    final project = _teamProject();

    expect(project.teamShareTotal, 15000000);
    expect(project.ownerContractShare, 15000000);
    expect(project.teamEarnedToDate, 10000000);
    expect(project.teamPayable, 10000000);
    expect(project.ownerNetReceived, 10000000);
    expect(project.ownerRemaining, 5000000);
  });

  test('project deadlines create payment and delivery reminders', () {
    final reminders = buildProjectReminders(
      [_teamProject()],
      now: DateTime(2026, 6, 28),
    );

    expect(
      reminders.any((item) => item.kind == ReminderKind.paymentDue),
      isTrue,
    );
    expect(
      reminders.any((item) => item.kind == ReminderKind.deliveryDue),
      isTrue,
    );
  });
}

ProjectFinance _teamProject() => const ProjectFinance(
      id: 'team-project',
      name: 'Website nhóm',
      client: 'Khách hàng',
      totalValue: 30000000,
      depositReceived: 10000000,
      paidAmount: 20000000,
      reserveAmount: 1000000,
      dueDate: '30/06/2026',
      deliveryDate: '29/06/2026',
      startDate: '01/06/2026',
      progress: 0.8,
      risk: ProjectRisk.low,
      status: PaymentStatus.partlyPaid,
      notes: '',
      workMode: ProjectWorkMode.team,
      teamMembers: [
        TeamMember(
          id: 'member-1',
          name: 'An',
          responsibility: 'UI',
          specialty: 'Thiết kế',
          sharePercent: 20,
        ),
        TeamMember(
          id: 'member-2',
          name: 'Bình',
          responsibility: 'Backend',
          specialty: 'Lập trình',
          sharePercent: 30,
        ),
      ],
    );
