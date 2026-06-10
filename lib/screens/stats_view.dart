import 'package:flutter/material.dart';
import '../models/project_finance.dart';
import '../utils/helpers.dart';
import '../widgets/shared_widgets.dart';

class StatsView extends StatelessWidget {
  const StatsView({super.key, required this.projects});

  final List<ProjectFinance> projects;

  @override
  Widget build(BuildContext context) {
    final paid = projects.fold<double>(0, (sum, p) => sum + p.paidAmount);
    final debt = projects.fold<double>(0, (sum, p) => sum + p.remaining);
    final reserve = projects.fold<double>(0, (sum, p) => sum + p.reserveAmount);

    return AppPage(
      title: 'Thống kê',
      subtitle: 'Tổng hợp thu nhập, công nợ và tiết kiệm',
      action: SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'q2', label: Text('Q2')),
          ButtonSegment(value: '2026', label: Text('2026')),
        ],
        selected: const {'q2'},
        onSelectionChanged: (_) {},
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          StatsChart(paid: paid, debt: debt, reserve: reserve),
          const SizedBox(height: 18),
          RiskBreakdown(projects: projects),
          const SizedBox(height: 18),
          const SectionHeader(title: 'Góc nhìn nhanh'),
          const InsightTile(
            icon: Icons.calendar_month_outlined,
            title: 'Dòng tiền tập trung vào giữa tháng',
            value: '2 khoản thu đến hạn trong 14 ngày tới',
          ),
          const InsightTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Tỷ lệ dự phòng hiện tại',
            value: 'Đang đạt mức tốt so với mục tiêu 20%',
          ),
        ],
      ),
    );
  }
}

class StatsChart extends StatelessWidget {
  const StatsChart({
    super.key,
    required this.paid,
    required this.debt,
    required this.reserve,
  });

  final double paid;
  final double debt;
  final double reserve;

  @override
  Widget build(BuildContext context) {
    final maxValue = [paid, debt, reserve].reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Giai đoạn hiện tại',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          ChartBar(
            label: 'Thu nhập',
            value: paid,
            maxValue: maxValue,
            color: const Color(0xFF1B7F5A),
          ),
          ChartBar(
            label: 'Công nợ',
            value: debt,
            maxValue: maxValue,
            color: const Color(0xFFB95D2A),
          ),
          ChartBar(
            label: 'Tiết kiệm',
            value: reserve,
            maxValue: maxValue,
            color: const Color(0xFF315C9A),
          ),
        ],
      ),
    );
  }
}

class ChartBar extends StatelessWidget {
  const ChartBar({
    super.key,
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  final String label;
  final double value;
  final double maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                formatMoney(value),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: maxValue == 0 ? 0 : value / maxValue,
              minHeight: 12,
              color: color,
              backgroundColor: const Color(0xFFE3E5DD),
            ),
          ),
        ],
      ),
    );
  }
}

class RiskBreakdown extends StatelessWidget {
  const RiskBreakdown({super.key, required this.projects});

  final List<ProjectFinance> projects;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chỉ số rủi ro dự án',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: RiskCount(
                  label: 'Thấp',
                  count: countRisk(ProjectRisk.low),
                  color: riskColor(ProjectRisk.low),
                ),
              ),
              Expanded(
                child: RiskCount(
                  label: 'Vừa',
                  count: countRisk(ProjectRisk.medium),
                  color: riskColor(ProjectRisk.medium),
                ),
              ),
              Expanded(
                child: RiskCount(
                  label: 'Cao',
                  count: countRisk(ProjectRisk.high),
                  color: riskColor(ProjectRisk.high),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int countRisk(ProjectRisk risk) =>
      projects.where((project) => project.risk == risk).length;
}

class RiskCount extends StatelessWidget {
  const RiskCount({
    super.key,
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: color.withValues(alpha: 0.14),
          child: Text(
            '$count',
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class InsightTile extends StatelessWidget {
  const InsightTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(value, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}