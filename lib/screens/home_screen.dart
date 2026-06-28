import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/app_reminder.dart';
import '../models/notification_intent.dart';
import '../models/project_finance.dart';
import '../services/notification_service.dart';
import '../services/project_repository.dart';
import '../widgets/auth_scope.dart';
import 'dashboard_view.dart';
import 'payments_view.dart';
import 'projects_view.dart';
import 'reserve_view.dart';
import 'stats_view.dart';
import 'team_payouts_view.dart';

class FinanceHomePage extends StatefulWidget {
  const FinanceHomePage({
    super.key,
    required this.user,
    required this.onLogout,
  });

  final AppUser user;
  final VoidCallback onLogout;

  @override
  State<FinanceHomePage> createState() => _FinanceHomePageState();
}

class _FinanceHomePageState extends State<FinanceHomePage> {
  int _selectedIndex = 0;
  late double _reserveRate;
  late AppUser _user;
  late final ProjectRepository _repository;
  StreamSubscription<List<ProjectFinance>>? _projectSubscription;
  StreamSubscription<NotificationIntent>? _notificationSubscription;
  bool _isLoadingProjects = true;
  String? _projectLoadError;
  String? _focusedProjectId;
  final Set<String> _readReminderIds = {};

  final List<ProjectFinance> _projects = [
    ProjectFinance(
      id: 'project-1',
      name: 'Bộ nhận diện thương hiệu — Cafe Lumina',
      client: 'Lumina Studio',
      totalValue: 46000000,
      depositReceived: 18000000,
      paidAmount: 18000000,
      reserveAmount: 3600000,
      dueDate: '12/06/2026',
      startDate: '01/05/2026',
      progress: 0.68,
      risk: ProjectRisk.medium,
      status: PaymentStatus.depositReceived,
      notes: 'Đợi duyệt bộ hướng dẫn thương hiệu và file in ấn.',
      category: ProjectCategory.design,
      clientRating: 4,
      contractSigned: true,
      hasDeposit: true,
      scopeChangeCount: 1,
      overdueDays: 0,
      tags: ['Branding', 'Print'],
    ),
    ProjectFinance(
      id: 'project-2',
      name: 'UI Kit ứng dụng di động',
      client: 'Nexa Labs',
      totalValue: 32000000,
      depositReceived: 12000000,
      paidAmount: 26000000,
      reserveAmount: 5200000,
      dueDate: '18/06/2026',
      startDate: '10/04/2026',
      progress: 0.86,
      risk: ProjectRisk.low,
      status: PaymentStatus.partlyPaid,
      notes: 'Còn 2 màn hình cuối và bàn giao design tokens.',
      category: ProjectCategory.design,
      clientRating: 5,
      contractSigned: true,
      hasDeposit: true,
      scopeChangeCount: 0,
      overdueDays: 0,
      tags: ['UI/UX', 'Mobile'],
    ),
    ProjectFinance(
      id: 'project-3',
      name: 'Landing page chiến dịch quảng cáo',
      client: 'Bright Ads',
      totalValue: 18500000,
      depositReceived: 0,
      paidAmount: 0,
      reserveAmount: 0,
      dueDate: '05/06/2026',
      startDate: '20/04/2026',
      progress: 0.42,
      risk: ProjectRisk.high,
      status: PaymentStatus.overdue,
      notes: 'Chưa nhận cọc, phạm vi thay đổi 2 lần. Cần xác nhận lại scope.',
      category: ProjectCategory.development,
      clientRating: 2,
      contractSigned: false,
      hasDeposit: false,
      scopeChangeCount: 2,
      overdueDays: 9,
      tags: ['Web', 'Marketing'],
    ),
    ProjectFinance(
      id: 'project-4',
      name: 'Nội dung mạng xã hội Q2',
      client: 'GreenMart VN',
      totalValue: 12000000,
      depositReceived: 6000000,
      paidAmount: 6000000,
      reserveAmount: 1200000,
      dueDate: '30/06/2026',
      startDate: '01/06/2026',
      progress: 0.30,
      risk: ProjectRisk.low,
      status: PaymentStatus.depositReceived,
      notes: '4 bài/tuần cho Facebook và Instagram.',
      category: ProjectCategory.content,
      clientRating: 4,
      contractSigned: true,
      hasDeposit: true,
      scopeChangeCount: 0,
      overdueDays: 0,
      tags: ['Social', 'Content'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _reserveRate = widget.user.reserveRate;
    _projects.clear();
    _repository = ProjectRepository(userId: _user.id);
    _projectSubscription = _repository.watchProjects().listen(
      (projects) {
        if (!mounted) return;
        setState(() {
          _projects
            ..clear()
            ..addAll(projects);
          _isLoadingProjects = false;
          _projectLoadError = null;
        });
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _isLoadingProjects = false;
          _projectLoadError = 'Không thể tải dữ liệu Firestore: $error';
        });
      },
    );

    final notifications = NotificationService.instance;
    unawaited(notifications.registerUser(_user.id));
    _notificationSubscription = notifications.intents.listen(_openNotification);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pending = notifications.takePendingIntent();
      if (pending != null) _openNotification(pending);
    });
  }

  @override
  void dispose() {
    _projectSubscription?.cancel();
    _notificationSubscription?.cancel();
    super.dispose();
  }

  // ── CRUD ────────────────────────────────────────────────────────────────────

  Future<void> _addProject(ProjectFinance project) async {
    try {
      await _repository.add(_normalize(project));
      if (mounted) _toast('Đã thêm dự án mới.');
    } catch (error) {
      if (mounted) _toast('Không thể thêm dự án: $error');
    }
  }

  Future<void> _updateProject(ProjectFinance project) async {
    try {
      await _repository.update(_normalize(project));
      if (mounted) _toast('Đã cập nhật dự án.');
    } catch (error) {
      if (mounted) _toast('Không thể cập nhật dự án: $error');
    }
  }

  Future<void> _deleteProject(ProjectFinance project) async {
    try {
      await _repository.delete(project.id);
      if (mounted) _toast('Đã xóa "${project.name}".');
    } catch (error) {
      if (mounted) _toast('Không thể xóa dự án: $error');
    }
  }

  Future<void> _recordPayment(ProjectFinance project, double amount) async {
    if (amount <= 0) return;
    final i = _projects.indexWhere((p) => p.id == project.id);
    if (i == -1) return;
    final cur = _projects[i];
    final accepted = amount.clamp(0, cur.remaining).toDouble();
    final newPaid = cur.paidAmount + accepted;
    final payment = ClientPayment(
      id: 'payment-${DateTime.now().microsecondsSinceEpoch}',
      amount: accepted,
      receivedAt: DateTime.now(),
      kind: cur.paidAmount <= 0
          ? ClientPaymentKind.deposit
          : newPaid >= cur.totalValue
              ? ClientPaymentKind.finalPayment
              : ClientPaymentKind.installment,
    );

    try {
      await _repository.update(
        _normalize(
          cur.copyWith(
            paidAmount: newPaid,
            depositReceived:
                cur.depositReceived == 0 ? accepted : cur.depositReceived,
            clientPayments: [...cur.clientPayments, payment],
            hasDeposit: true,
          ),
        ),
      );
      if (mounted) {
        _toast('Ghi nhận ${_shortMoney(accepted)} cho ${project.name}.');
      }
    } catch (error) {
      if (mounted) _toast('Không thể ghi nhận thanh toán: $error');
    }
  }

  Future<void> _payFullProject(ProjectFinance project) async {
    final i = _projects.indexWhere((p) => p.id == project.id);
    if (i == -1) return;
    final cur = _projects[i];
    if (cur.remaining <= 0 && cur.progress >= 1) return;
    final remaining = cur.remaining;
    final payments = remaining > 0
        ? [
            ...cur.clientPayments,
            ClientPayment(
              id: 'payment-${DateTime.now().microsecondsSinceEpoch}',
              amount: remaining,
              receivedAt: DateTime.now(),
              kind: cur.paidAmount <= 0
                  ? ClientPaymentKind.deposit
                  : ClientPaymentKind.finalPayment,
            ),
          ]
        : cur.clientPayments;

    try {
      await _repository.update(
        _normalize(
          cur.copyWith(
            paidAmount: cur.totalValue,
            depositReceived:
                cur.depositReceived == 0 ? remaining : cur.depositReceived,
            clientPayments: payments,
            progress: 1,
            hasDeposit: true,
            overdueDays: 0,
          ),
        ),
      );
      if (mounted) _toast('Đã thanh toán toàn bộ ${project.name}.');
    } catch (error) {
      if (mounted) _toast('Không thể hoàn tất thanh toán: $error');
    }
  }

  Future<void> _updateReserveRate(double rate) async {
    setState(() => _reserveRate = rate);
    try {
      await _repository.updateReserveRate(_projects, rate);
      if (mounted) _toast('Tỷ lệ dự phòng: ${(rate * 100).round()}%');
    } catch (error) {
      if (mounted) _toast('Không thể cập nhật quỹ dự phòng: $error');
    }
  }

  Future<void> _payTeamMember(
    ProjectFinance project,
    TeamMember member,
    double amount,
  ) async {
    final current =
        _projects.where((item) => item.id == project.id).firstOrNull;
    if (current == null) return;
    final currentMember =
        current.teamMembers.where((item) => item.id == member.id).firstOrNull;
    if (currentMember == null) return;
    final accepted =
        amount.clamp(0, current.memberPayable(currentMember)).toDouble();
    if (accepted <= 0) return;

    try {
      await _repository.update(
        _normalize(
          current.copyWith(
            teamPayouts: [
              ...current.teamPayouts,
              TeamPayout(
                id: 'payout-${DateTime.now().microsecondsSinceEpoch}',
                memberId: member.id,
                amount: accepted,
                paidAt: DateTime.now(),
              ),
            ],
          ),
        ),
      );
      if (mounted) {
        _toast('Đã chia ${_shortMoney(accepted)} cho ${member.name}.');
      }
    } catch (error) {
      if (mounted) _toast('Không thể ghi nhận chia tiền: $error');
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  ProjectFinance _normalize(ProjectFinance p) {
    final paid = p.paidAmount.clamp(0, p.totalValue).toDouble();
    final progress = p.progress.clamp(0, 1).toDouble();
    return p.copyWith(
      paidAmount: paid,
      progress: progress,
      reserveAmount:
          (paid * (1 - p.teamSharePercent / 100)).clamp(0, double.infinity) *
              _reserveRate,
      status: _deriveStatus(p.copyWith(paidAmount: paid)),
    );
  }

  PaymentStatus _deriveStatus(ProjectFinance p) {
    if (p.remaining <= 0) return PaymentStatus.paid;
    if (p.overdueDays > 0 || p.dueDate.toLowerCase().contains('quá hạn')) {
      return PaymentStatus.overdue;
    }
    if (p.paidAmount <= 0) return PaymentStatus.depositReceived;
    return PaymentStatus.partlyPaid;
  }

  String _shortMoney(double v) {
    final m = v / 1000000;
    return '${m % 1 == 0 ? m.toStringAsFixed(0) : m.toStringAsFixed(1)}tr';
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  void _openNotification(NotificationIntent intent) {
    if (!mounted) return;
    if (intent.userId != null && intent.userId != _user.id) {
      _toast('Thông báo này thuộc một tài khoản khác.');
      return;
    }
    setState(() {
      _selectedIndex = intent.tabIndex;
      _focusedProjectId = intent.opensProject ? intent.projectId : null;
    });
    unawaited(
      NotificationService.instance.markAsRead(
        _user.id,
        intent.notificationId,
      ),
    );
  }

  List<AppReminder> get _reminders => buildProjectReminders(
        _projects,
        reminderDays: _user.reminderDays,
      )
          .where((reminder) => switch (reminder.kind) {
                ReminderKind.paymentDue ||
                ReminderKind.paymentOverdue =>
                  _user.notifyPayments,
                ReminderKind.deliveryDue => _user.notifyProjectUpdates,
                ReminderKind.teamPayout => _user.notifyTeamPayouts,
              })
          .map(
            (reminder) => reminder.copyWith(
              isRead: _readReminderIds.contains(reminder.id),
            ),
          )
          .toList();

  void _onUserChanged(AppUser user) {
    final reserveChanged = user.reserveRate != _reserveRate;
    setState(() {
      _user = user;
      _reserveRate = user.reserveRate;
    });
    if (reserveChanged) {
      unawaited(_repository.updateReserveRate(_projects, user.reserveRate));
    }
  }

  void _openReminder(AppReminder reminder) {
    setState(() {
      _readReminderIds.add(reminder.id);
      _selectedIndex = reminder.tabIndex;
      _focusedProjectId = reminder.tabIndex == 1 ? reminder.projectId : null;
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardView(projects: _projects, onAddProject: _addProject),
      ProjectsView(
        projects: _projects,
        focusedProjectId: _focusedProjectId,
        onAddProject: _addProject,
        onUpdateProject: _updateProject,
        onDeleteProject: _deleteProject,
        onPayFull: _payFullProject,
      ),
      PaymentsView(
        projects: _projects,
        onRecordPayment: _recordPayment,
      ),
      TeamPayoutsView(
        projects: _projects,
        onPayMember: _payTeamMember,
      ),
      ReserveView(
        projects: _projects,
        reserveRate: _reserveRate,
        onReserveRateChanged: _updateReserveRate,
      ),
      StatsView(projects: _projects),
    ];

    return AuthScope(
      user: _user,
      onLogout: widget.onLogout,
      reminders: _reminders,
      onReminderSelected: _openReminder,
      onUserChanged: _onUserChanged,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              if (_projectLoadError != null)
                MaterialBanner(
                  content: Text(_projectLoadError!),
                  actions: [
                    TextButton(
                      onPressed: () => setState(() => _projectLoadError = null),
                      child: const Text('Đóng'),
                    ),
                  ],
                ),
              if (_isLoadingProjects)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(child: pages[_selectedIndex]),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) => setState(() => _selectedIndex = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'Tổng quan',
            ),
            NavigationDestination(
              icon: Icon(Icons.folder_copy_outlined),
              selectedIcon: Icon(Icons.folder_copy_rounded),
              label: 'Dự án',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Thu nợ',
            ),
            NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.group_add_rounded),
              label: 'Chia tiền',
            ),
            NavigationDestination(
              icon: Icon(Icons.savings_outlined),
              selectedIcon: Icon(Icons.savings_rounded),
              label: 'Dự phòng',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights_rounded),
              label: 'Thống kê',
            ),
          ],
        ),
      ),
    );
  }
}
