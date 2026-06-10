import 'package:flutter/material.dart';
import '../models/project_finance.dart';
import 'dashboard_view.dart';
import 'projects_view.dart';
import 'payments_view.dart';
import 'reserve_view.dart';
import 'stats_view.dart';

class FinanceHomePage extends StatefulWidget {
  const FinanceHomePage({super.key});

  @override
  State<FinanceHomePage> createState() => _FinanceHomePageState();
}

class _FinanceHomePageState extends State<FinanceHomePage> {
  int _selectedIndex = 0;

  final List<ProjectFinance> projects = const [
    ProjectFinance(
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
    ProjectFinance(
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
    ProjectFinance(
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

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardView(projects: projects),
      ProjectsView(projects: projects),
      PaymentsView(projects: projects),
      ReserveView(projects: projects),
      StatsView(projects: projects),
    ];

    return Scaffold(
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
    );
  }
}