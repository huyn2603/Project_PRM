import 'package:flutter/material.dart';

import '../models/project_finance.dart';
import '../utils/helpers.dart';
import '../widgets/shared_widgets.dart';
import 'projects_view.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({
    super.key,
    required this.projects,
    required this.onAddProject,
  });

  final List<ProjectFinance> projects;
  final ValueChanged<ProjectFinance> onAddProject;

  Future<void> _openCreateProject(BuildContext context) async {
    final project = await showDialog<ProjectFinance>(
      context: context,
      builder: (context) => const ProjectEditorDialog(),
    );
    if (project != null) onAddProject(project);
  }

  @override
  Widget build(BuildContext context) {
    final totalIncome =
        projects.fold<double>(0, (sum, p) => sum + p.paidAmount);
    final totalDebt = projects.fold<double>(0, (sum, p) => sum + p.remaining);
    final totalReserve = projects.fold<double>(
      0,
      (sum, p) => sum + p.reserveAmount,
    );
    final highRisk = projects.where((p) => p.risk == ProjectRisk.high).length;

    return AppPage(
      title: 'Tài chính Freelancer',
      subtitle: 'Kiểm soát dòng tiền theo từng dự án',
      action: IconButton(
        tooltip: 'Thêm dự án',
        onPressed: () => _openCreateProject(context),
        icon: const Icon(Icons.add_circle_outline),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _HeroSummary(
            totalIncome: totalIncome,
            totalDebt: totalDebt,
            totalReserve: totalReserve,
          ),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: MediaQuery.sizeOf(context).width > 720 ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              MetricCard(
                label: 'Đã thu',
                value: formatMoney(totalIncome),
                icon: Icons.trending_up,
                color: const Color(0xFF1B7F5A),
              ),
              MetricCard(
                label: 'Công nợ',
                value: formatMoney(totalDebt),
                icon: Icons.receipt_long,
                color: const Color(0xFFB95D2A),
              ),
              MetricCard(
                label: 'Dự phòng',
                value: formatMoney(totalReserve),
                icon: Icons.shield_outlined,
                color: const Color(0xFF315C9A),
              ),
              MetricCard(
                label: 'Rủi ro cao',
                value: '$highRisk dự án',
                icon: Icons.warning_amber_rounded,
                color: const Color(0xFFB3261E),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const SectionHeader(title: 'Cần xử lý sớm'),
          if (projects.isEmpty)
            const EmptyState(
              icon: Icons.folder_open,
              title: 'Chưa có dự án',
              message: 'Tạo dự án đầu tiên để theo dõi thu nợ và dòng tiền.',
            )
          else
            ...projects.map((project) => ProjectCard(project: project)),
        ],
      ),
    );
  }
}

class _HeroSummary extends StatelessWidget {
  const _HeroSummary({
    required this.totalIncome,
    required this.totalDebt,
    required this.totalReserve,
  });

  final double totalIncome;
  final double totalDebt;
  final double totalReserve;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF173B45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wallet_outlined, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                'Sức khỏe dòng tiền',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            formatMoney(totalIncome - totalDebt),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Dòng tiền khả dụng sau khi trừ công nợ cần thu',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 18),
          LinearProgressIndicator(
            value:
                totalIncome == 0 ? 0 : (totalReserve / totalIncome).clamp(0, 1),
            minHeight: 8,
            borderRadius: BorderRadius.circular(99),
            backgroundColor: Colors.white24,
            color: const Color(0xFF9AD0C2),
          ),
        ],
      ),
    );
  }
}

class ProjectCard extends StatelessWidget {
  const ProjectCard({super.key, required this.project});

  final ProjectFinance project;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  project.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              RiskChip(risk: project.risk),
            ],
          ),
          const SizedBox(height: 6),
          Text(project.client, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: MiniStat(
                  label: 'Đã thu',
                  value: formatMoney(project.paidAmount),
                ),
              ),
              Expanded(
                child: MiniStat(
                  label: 'Còn lại',
                  value: formatMoney(project.remaining),
                ),
              ),
              Expanded(child: MiniStat(label: 'Hạn', value: project.dueDate)),
            ],
          ),
        ],
      ),
    );
  }
}
