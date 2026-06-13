import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/project_finance.dart';
import '../widgets/auth_scope.dart';
import 'dashboard_view.dart';
import 'payments_view.dart';
import 'projects_view.dart';
import 'reserve_view.dart';
import 'stats_view.dart';

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
  double _reserveRate = 0.2;

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

  // ── CRUD ────────────────────────────────────────────────────────────────────

  void _addProject(ProjectFinance project) {
    setState(() => _projects.insert(0, _normalize(project)));
    _toast('Đã thêm dự án mới.');
  }

  void _updateProject(ProjectFinance project) {
    final i = _projects.indexWhere((p) => p.id == project.id);
    if (i == -1) return;
    setState(() => _projects[i] = _normalize(project));
    _toast('Đã cập nhật dự án.');
  }

  void _deleteProject(ProjectFinance project) {
    setState(() => _projects.removeWhere((p) => p.id == project.id));
    _toast('Đã xóa "${project.name}".');
  }

  void _recordPayment(ProjectFinance project, double amount) {
    if (amount <= 0) return;
    final i = _projects.indexWhere((p) => p.id == project.id);
    if (i == -1) return;
    final cur = _projects[i];
    final accepted = amount.clamp(0, cur.remaining).toDouble();
    final newPaid = cur.paidAmount + accepted;
    final newReserve = cur.reserveAmount + accepted * _reserveRate;

    setState(() {
      _projects[i] = _normalize(
        cur.copyWith(
          paidAmount: newPaid,
          depositReceived:
              cur.depositReceived == 0 ? accepted : cur.depositReceived,
          reserveAmount: newReserve,
          hasDeposit: true,
        ),
      );
    });
    _toast('Ghi nhận ${_shortMoney(accepted)} cho ${project.name}.');
  }

  void _updateReserveRate(double rate) {
    setState(() {
      _reserveRate = rate;
      for (var i = 0; i < _projects.length; i++) {
        _projects[i] = _projects[i].copyWith(
          reserveAmount: _projects[i].paidAmount * rate,
        );
      }
    });
    _toast('Tỷ lệ dự phòng: ${(rate * 100).round()}%');
  }

  void _sendReminder(ProjectFinance project) {
    _toast('Đã tạo nhắc thanh toán cho ${project.client}.');
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  ProjectFinance _normalize(ProjectFinance p) {
    final paid = p.paidAmount.clamp(0, p.totalValue).toDouble();
    final progress = p.progress.clamp(0, 1).toDouble();
    return p.copyWith(
      paidAmount: paid,
      progress: progress,
      status: _deriveStatus(p.copyWith(paidAmount: paid)),
    );
  }

  PaymentStatus _deriveStatus(ProjectFinance p) {
    if (p.remaining <= 0) return PaymentStatus.paid;
    if (p.overdueDays > 0 ||
        p.dueDate.toLowerCase().contains('quá hạn')) {
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardView(projects: _projects, onAddProject: _addProject),
      ProjectsView(
        projects: _projects,
        onAddProject: _addProject,
        onUpdateProject: _updateProject,
        onDeleteProject: _deleteProject,
      ),
      PaymentsView(
        projects: _projects,
        onRecordPayment: _recordPayment,
        onSendReminder: _sendReminder,
      ),
      ReserveView(
        projects: _projects,
        reserveRate: _reserveRate,
        onReserveRateChanged: _updateReserveRate,
      ),
      StatsView(projects: _projects),
    ];

    return AuthScope(
      user: widget.user,
      onLogout: widget.onLogout,
      child: Scaffold(
        body: SafeArea(child: pages[_selectedIndex]),
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
