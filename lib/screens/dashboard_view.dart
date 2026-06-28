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

  List<String> get _clients {
    final clients = projects
        .map((p) => p.client.trim())
        .where((client) => client.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return clients;
  }

  Future<void> _openCreate(BuildContext context) async {
    final project = await showDialog<ProjectFinance>(
      context: context,
      builder: (context) => ProjectEditorDialog(clients: _clients),
    );
    if (project != null) onAddProject(project);
  }

  @override
  Widget build(BuildContext context) {
    final totalIncome =
        projects.fold<double>(0, (s, p) => s + p.ownerNetReceived);
    final totalDebt = projects.fold<double>(0, (s, p) => s + p.ownerRemaining);
    final totalReserve =
        projects.fold<double>(0, (s, p) => s + p.reserveAmount);
    final highRisk = projects.where((p) => p.riskScore >= 55).length;
    final overdueProjects =
        projects.where((p) => p.status == PaymentStatus.overdue).toList();
    final urgentProjects = projects.where((p) => p.remaining > 0).toList()
      ..sort((a, b) => b.riskScore.compareTo(a.riskScore));

    return AppPage(
      title: 'FreelanceFlow',
      subtitle: 'Kiểm soát dòng tiền theo từng dự án',
      action: FilledButton.icon(
        onPressed: () => _openCreate(context),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Dự án'),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // ── Hero card ──
          _HeroCard(
            totalIncome: totalIncome,
            totalDebt: totalDebt,
            totalReserve: totalReserve,
          ),
          const SizedBox(height: 16),

          // ── Metric grid ──
          GridView.count(
            crossAxisCount: MediaQuery.sizeOf(context).width > 600 ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.4,
            children: [
              MetricCard(
                label: 'Đã thu',
                value: formatMoney(totalIncome),
                icon: Icons.trending_up_rounded,
                color: const Color(0xFF10B981),
                subtitle:
                    '${projects.where((p) => p.status == PaymentStatus.paid).length} dự án xong',
              ),
              MetricCard(
                label: 'Còn phải thu',
                value: formatMoney(totalDebt),
                icon: Icons.pending_actions_rounded,
                color: const Color(0xFFF59E0B),
                subtitle:
                    '${projects.where((p) => p.remaining > 0).length} khoản nợ',
              ),
              MetricCard(
                label: 'Quỹ dự phòng',
                value: formatMoney(totalReserve),
                icon: Icons.shield_rounded,
                color: const Color(0xFF2563EB),
                subtitle: totalIncome == 0
                    ? '0%'
                    : '${(totalReserve / totalIncome * 100).round()}% thu nhập',
              ),
              MetricCard(
                label: 'Rủi ro cao',
                value: '$highRisk dự án',
                icon: Icons.warning_amber_rounded,
                color: const Color(0xFFEF4444),
                subtitle: overdueProjects.isEmpty
                    ? 'Không quá hạn'
                    : '${overdueProjects.length} quá hạn',
              ),
            ],
          ),

          // ── Overdue alert ──
          if (overdueProjects.isNotEmpty) ...[
            const SizedBox(height: 16),
            _OverdueAlert(projects: overdueProjects),
          ],

          const SizedBox(height: 20),

          // ── Recent projects ──
          SectionHeader(
            title: 'Ưu tiên xử lý',
            trailing: TextButton(
              onPressed: () {},
              child: const Text('Xem tất cả'),
            ),
          ),

          if (projects.isEmpty)
            EmptyState(
              icon: Icons.folder_open_rounded,
              title: 'Chưa có dự án',
              message: 'Tạo dự án đầu tiên để bắt đầu theo dõi dòng tiền.',
              action: FilledButton.icon(
                onPressed: () => _openCreate(context),
                icon: const Icon(Icons.add),
                label: const Text('Tạo dự án'),
              ),
            )
          else
            ...urgentProjects
                .take(4)
                .map((p) => _ProjectSummaryCard(project: p)),
        ],
      ),
    );
  }
}

// ── Hero Card ─────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.totalIncome,
    required this.totalDebt,
    required this.totalReserve,
  });

  final double totalIncome;
  final double totalDebt;
  final double totalReserve;

  @override
  Widget build(BuildContext context) {
    final cashFlow = totalIncome - totalDebt;
    final reserveRate =
        totalIncome == 0 ? 0.0 : (totalReserve / totalIncome).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.monitor_heart_outlined,
                        color: Colors.white70, size: 13),
                    SizedBox(width: 5),
                    Text(
                      'Sức khỏe dòng tiền',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            formatMoneyFull(cashFlow),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            cashFlow >= 0
                ? 'Dòng tiền dương — đang kiểm soát tốt'
                : 'Cảnh báo: Tổng công nợ vượt thu nhập',
            style: TextStyle(
              color: cashFlow >= 0 ? Colors.white70 : const Color(0xFFFCA5A5),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  label: 'Đã thu',
                  value: formatMoney(totalIncome),
                  color: const Color(0xFF6EE7B7),
                ),
              ),
              Container(
                  width: 1,
                  height: 32,
                  color: Colors.white.withValues(alpha: 0.2)),
              Expanded(
                child: _HeroStat(
                  label: 'Còn nợ',
                  value: formatMoney(totalDebt),
                  color: const Color(0xFFFDE68A),
                ),
              ),
              Container(
                  width: 1,
                  height: 32,
                  color: Colors.white.withValues(alpha: 0.2)),
              Expanded(
                child: _HeroStat(
                  label: 'Dự phòng',
                  value: formatMoney(totalReserve),
                  color: const Color(0xFF93C5FD),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: reserveRate,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              color: const Color(0xFF34D399),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Quỹ dự phòng: ${(reserveRate * 100).round()}% thu nhập',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 3),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: -0.3)),
        ],
      ),
    );
  }
}

// ── Overdue Alert ─────────────────────────────────────────────────────────────

class _OverdueAlert extends StatelessWidget {
  const _OverdueAlert({required this.projects});
  final List<ProjectFinance> projects;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.alarm_rounded,
                color: Color(0xFFEF4444), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quá hạn thanh toán!',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFB91C1C),
                    fontSize: 14,
                  ),
                ),
                Text(
                  projects
                      .map((p) => '${p.client} (${formatMoney(p.remaining)})')
                      .join(', '),
                  style:
                      const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Project summary card ──────────────────────────────────────────────────────

class _ProjectSummaryCard extends StatelessWidget {
  const _ProjectSummaryCard({required this.project});
  final ProjectFinance project;

  @override
  Widget build(BuildContext context) {
    final riskColor2 = riskScoreColor(project.riskScore);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  categoryIcon(project.category),
                  size: 16,
                  color: const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      project.client,
                      style:
                          const TextStyle(color: Colors.black45, fontSize: 12),
                    ),
                  ],
                ),
              ),
              RiskScoreBadge(score: project.riskScore),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: project.progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFE5E7EB),
              color: riskColor2,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: MiniStat(
                  label: 'Đã thu',
                  value: formatMoney(project.paidAmount),
                  valueColor: const Color(0xFF10B981),
                ),
              ),
              Expanded(
                child: MiniStat(
                  label: 'Còn lại',
                  value: formatMoney(project.remaining),
                  valueColor:
                      project.remaining > 0 ? const Color(0xFFF59E0B) : null,
                ),
              ),
              Expanded(
                child: MiniStat(
                  label: 'Hạn',
                  value: project.dueDate,
                  valueColor: project.status == PaymentStatus.overdue
                      ? const Color(0xFFEF4444)
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
