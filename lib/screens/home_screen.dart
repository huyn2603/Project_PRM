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
    const ProjectFinance(
      id: 'project-1',
      name: 'Bộ nhận diện - Cafe Lumina',
      client: 'Lumina Studio',
      totalValue: 46000000,
      depositReceived: 18000000,
      paidAmount: 18000000,
      reserveAmount: 3600000,
      dueDate: '12/06',
      progress: 0.68,
      risk: ProjectRisk.medium,
      status: PaymentStatus.depositReceived,
      notes: 'Đang đợi duyệt bộ hướng dẫn thương hiệu và file in ấn.',
    ),
    const ProjectFinance(
      id: 'project-2',
      name: 'Bộ giao diện di động',
      client: 'Nexa Labs',
      totalValue: 32000000,
      depositReceived: 12000000,
      paidAmount: 26000000,
      reserveAmount: 5200000,
      dueDate: '18/06',
      progress: 0.86,
      risk: ProjectRisk.low,
      status: PaymentStatus.partlyPaid,
      notes: 'Còn 2 màn hình cuối và bàn giao thành phần giao diện.',
    ),
    const ProjectFinance(
      id: 'project-3',
      name: 'Trang chiến dịch quảng cáo',
      client: 'Bright Ads',
      totalValue: 18500000,
      depositReceived: 0,
      paidAmount: 0,
      reserveAmount: 0,
      dueDate: 'Quá hạn 3 ngày',
      progress: 0.42,
      risk: ProjectRisk.high,
      status: PaymentStatus.overdue,
      notes: 'Chưa nhận cọc, phạm vi công việc thay đổi 2 lần.',
    ),
  ];

  void _addProject(ProjectFinance project) {
    setState(() => _projects.insert(0, _normalizeProject(project)));
    _showMessage('Đã thêm dự án mới.');
  }

  void _updateProject(ProjectFinance project) {
    final index = _projects.indexWhere((item) => item.id == project.id);
    if (index == -1) return;
    setState(() => _projects[index] = _normalizeProject(project));
    _showMessage('Đã cập nhật dự án.');
  }

  void _deleteProject(ProjectFinance project) {
    setState(() => _projects.removeWhere((item) => item.id == project.id));
    _showMessage('Đã xóa dự án "${project.name}".');
  }

  void _recordPayment(ProjectFinance project, double amount) {
    if (amount <= 0) return;
    final index = _projects.indexWhere((item) => item.id == project.id);
    if (index == -1) return;

    final current = _projects[index];
    final acceptedAmount = amount.clamp(0, current.remaining).toDouble();
    final paidAmount = current.paidAmount + acceptedAmount;
    final reserveAmount = current.reserveAmount + acceptedAmount * _reserveRate;

    setState(() {
      _projects[index] = _normalizeProject(
        current.copyWith(
          paidAmount: paidAmount,
          depositReceived: current.depositReceived == 0
              ? acceptedAmount
              : current.depositReceived,
          reserveAmount: reserveAmount,
        ),
      );
    });
    _showMessage(
        'Đã ghi nhận ${_formatRawMoney(acceptedAmount)} cho ${project.name}.');
  }

  void _updateReserveRate(double rate) {
    setState(() {
      _reserveRate = rate;
      for (var i = 0; i < _projects.length; i++) {
        _projects[i] = _projects[i].copyWith(
          reserveAmount: _projects[i].paidAmount * _reserveRate,
        );
      }
    });
    _showMessage(
        'Đã cập nhật tỷ lệ dự phòng ${(_reserveRate * 100).round()}%.');
  }

  void _sendReminder(ProjectFinance project) {
    _showMessage('Đã tạo nhắc thanh toán cho ${project.client}.');
  }

  ProjectFinance _normalizeProject(ProjectFinance project) {
    final paid = project.paidAmount.clamp(0, project.totalValue).toDouble();
    final progress = project.progress.clamp(0, 1).toDouble();
    final status = _statusFor(project.copyWith(paidAmount: paid));
    return project.copyWith(
      paidAmount: paid.toDouble(),
      progress: progress,
      status: status,
      reserveAmount: project.reserveAmount.clamp(0, double.infinity).toDouble(),
    );
  }

  PaymentStatus _statusFor(ProjectFinance project) {
    if (project.remaining <= 0) return PaymentStatus.paid;
    if (project.dueDate.toLowerCase().contains('quá hạn')) {
      return PaymentStatus.overdue;
    }
    if (project.paidAmount <= 0) return PaymentStatus.depositReceived;
    if (project.paidAmount < project.totalValue) {
      return PaymentStatus.partlyPaid;
    }
    return PaymentStatus.paid;
  }

  String _formatRawMoney(double value) {
    final million = value / 1000000;
    return '${million.toStringAsFixed(million == million.roundToDouble() ? 0 : 1)}tr';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardView(
        projects: _projects,
        onAddProject: _addProject,
      ),
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
          onDestinationSelected: (index) =>
              setState(() => _selectedIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Tổng quan',
            ),
            NavigationDestination(
              icon: Icon(Icons.folder_copy_outlined),
              selectedIcon: Icon(Icons.folder_copy),
              label: 'Dự án',
            ),
            NavigationDestination(
              icon: Icon(Icons.payments_outlined),
              selectedIcon: Icon(Icons.payments),
              label: 'Thu nợ',
            ),
            NavigationDestination(
              icon: Icon(Icons.savings_outlined),
              selectedIcon: Icon(Icons.savings),
              label: 'Dự phòng',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Thống kê',
            ),
          ],
        ),
      ),
    );
  }
}
