import 'package:flutter/material.dart';

import '../models/project_finance.dart';
import '../utils/helpers.dart';
import '../widgets/shared_widgets.dart';

class StatsView extends StatefulWidget {
  const StatsView({super.key, required this.projects});

  final List<ProjectFinance> projects;

  @override
  State<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<StatsView> {
  int _periodIndex = 0; // 0=Q2, 1=2026, 2=Tất cả

  static const _periods = ['Q2/2026', 'Năm 2026', 'Tất cả'];

  @override
  Widget build(BuildContext context) {
    final projects = widget.projects;
    final paid = projects.fold<double>(0, (s, p) => s + p.paidAmount);
    final debt = projects.fold<double>(0, (s, p) => s + p.remaining);
    final reserve = projects.fold<double>(0, (s, p) => s + p.reserveAmount);
    final totalValue = projects.fold<double>(0, (s, p) => s + p.totalValue);

    final collectionRate = totalValue == 0 ? 0.0 : paid / totalValue;
    final reserveRate = paid == 0 ? 0.0 : reserve / paid;

    return AppPage(
      title: 'Thống kê',
      subtitle: 'Phân tích toàn diện dòng tiền',
      action: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            _periods.length,
            (i) => GestureDetector(
              onTap: () => setState(() => _periodIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _periodIndex == i ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _periodIndex == i
                      ? const [
                          BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 6,
                              offset: Offset(0, 2))
                        ]
                      : null,
                ),
                child: Text(
                  _periods[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _periodIndex == i
                        ? Theme.of(context).colorScheme.primary
                        : Colors.black38,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          // ── KPI Row ──
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  label: 'Tỷ lệ thu tiền',
                  value: '${(collectionRate * 100).round()}%',
                  sub: 'Đã thu / Tổng HĐ',
                  color: const Color(0xFF10B981),
                  progress: collectionRate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _KpiCard(
                  label: 'Tỷ lệ dự phòng',
                  value: '${(reserveRate * 100).round()}%',
                  sub: 'Quỹ / Thu nhập',
                  color: const Color(0xFF2563EB),
                  progress: reserveRate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  label: 'Dự án hoàn thành',
                  value: '${projects.where((p) => p.status == PaymentStatus.paid).length}/${projects.length}',
                  sub: 'Đã xong / Tổng',
                  color: const Color(0xFF7C3AED),
                  progress: projects.isEmpty
                      ? 0
                      : projects.where((p) => p.status == PaymentStatus.paid).length /
                          projects.length,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _KpiCard(
                  label: 'Rủi ro cao',
                  value: '${projects.where((p) => p.riskScore >= 55).length} dự án',
                  sub: 'Cần chú ý ngay',
                  color: const Color(0xFFEF4444),
                  progress: projects.isEmpty
                      ? 0
                      : projects.where((p) => p.riskScore >= 55).length /
                          projects.length,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Revenue bar chart ──
          const SectionHeader(title: 'Tổng quan tài chính'),
          _RevenueChart(paid: paid, debt: debt, reserve: reserve),
          const SizedBox(height: 16),

          // ── Category breakdown ──
          const SectionHeader(title: 'Thu nhập theo loại dự án'),
          _CategoryBreakdown(projects: projects),
          const SizedBox(height: 16),

          // ── Risk breakdown ──
          const SectionHeader(title: 'Phân tích rủi ro'),
          _RiskAnalysisPanel(projects: projects),
          const SizedBox(height: 16),

          // ── Project list by risk ──
          const SectionHeader(title: 'Bảng điểm rủi ro'),
          _RiskLeaderboard(projects: projects),
          const SizedBox(height: 16),

          // ── Insights ──
          const SectionHeader(title: 'Nhận xét nhanh'),
          ..._buildInsights(projects, paid, debt, reserve),
        ],
      ),
    );
  }

  List<Widget> _buildInsights(
    List<ProjectFinance> projects,
    double paid,
    double debt,
    double reserve,
  ) {
    final insights = <_InsightData>[];

    if (debt > paid) {
      insights.add(const _InsightData(
        icon: Icons.warning_amber_rounded,
        color: Color(0xFFEF4444),
        title: 'Công nợ vượt thu nhập',
        body:
            'Tổng công nợ đang cao hơn thu nhập. Ưu tiên theo dõi và nhắc khách thanh toán.',
      ));
    }

    if (projects.any((p) => p.overdueDays > 7)) {
      insights.add(const _InsightData(
        icon: Icons.alarm_rounded,
        color: Color(0xFFF59E0B),
        title: 'Có dự án quá hạn trên 7 ngày',
        body: 'Liên hệ ngay với khách hàng để xử lý khoản nợ quá hạn.',
      ));
    }

    if (reserve / (paid == 0 ? 1 : paid) < 0.15) {
      insights.add(const _InsightData(
        icon: Icons.savings_rounded,
        color: Color(0xFF2563EB),
        title: 'Quỹ dự phòng chưa đủ',
        body:
            'Tỷ lệ trích quỹ dưới 15%. Hãy tăng tỷ lệ trong cài đặt Quỹ dự phòng.',
      ));
    }

    if (projects.any((p) => !p.contractSigned && p.paidAmount == 0)) {
      insights.add(const _InsightData(
        icon: Icons.description_rounded,
        color: Color(0xFF7C3AED),
        title: 'Có dự án chưa ký hợp đồng',
        body:
            'Luôn ký hợp đồng trước khi bắt đầu để bảo vệ quyền lợi thanh toán.',
      ));
    }

    if (insights.isEmpty) {
      insights.add(const _InsightData(
        icon: Icons.check_circle_rounded,
        color: Color(0xFF10B981),
        title: 'Dòng tiền đang ổn định',
        body: 'Không có cảnh báo bất thường. Tiếp tục duy trì hiệu suất tốt!',
      ));
    }

    return insights
        .map(
          (d) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: d.color.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: d.color.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: d.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(d.icon, color: d.color, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 13)),
                      const SizedBox(height: 3),
                      Text(d.body,
                          style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                              height: 1.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }
}

class _InsightData {
  const _InsightData({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;
}

// ── KPI Card ──────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    required this.progress,
  });

  final String label;
  final String value;
  final String sub;
  final Color color;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.black45, fontSize: 11)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: color.withValues(alpha: 0.12),
              color: color,
            ),
          ),
          const SizedBox(height: 5),
          Text(sub,
              style: const TextStyle(color: Colors.black38, fontSize: 10)),
        ],
      ),
    );
  }
}

// ── Revenue Chart ─────────────────────────────────────────────────────────────

class _RevenueChart extends StatelessWidget {
  const _RevenueChart({
    required this.paid,
    required this.debt,
    required this.reserve,
  });

  final double paid;
  final double debt;
  final double reserve;

  @override
  Widget build(BuildContext context) {
    final max = [paid, debt, reserve].fold(0.0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: cardDecoration(),
      child: Column(
        children: [
          _Bar(
            label: 'Đã thu',
            value: paid,
            max: max,
            color: const Color(0xFF10B981),
            icon: Icons.trending_up_rounded,
          ),
          _Bar(
            label: 'Công nợ',
            value: debt,
            max: max,
            color: const Color(0xFFF59E0B),
            icon: Icons.pending_actions_rounded,
          ),
          _Bar(
            label: 'Dự phòng',
            value: reserve,
            max: max,
            color: const Color(0xFF2563EB),
            icon: Icons.shield_rounded,
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    required this.icon,
  });

  final String label;
  final double value;
  final double max;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                formatMoney(value),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: max == 0 ? 0 : value / max,
              minHeight: 10,
              color: color,
              backgroundColor: color.withValues(alpha: 0.10),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category Breakdown ────────────────────────────────────────────────────────

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({required this.projects});
  final List<ProjectFinance> projects;

  @override
  Widget build(BuildContext context) {
    final map = <ProjectCategory, double>{};
    for (final p in projects) {
      map[p.category] = (map[p.category] ?? 0) + p.paidAmount;
    }
    if (map.isEmpty) {
      return const SizedBox.shrink();
    }
    final total = map.values.fold(0.0, (a, b) => a + b);
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        children: sorted.map((entry) {
          final ratio = total == 0 ? 0.0 : entry.value / total;
          final color = _catColor(entry.key);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(categoryIcon(entry.key),
                      size: 14, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            categoryText(entry.key),
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          Text(
                            '${(ratio * 100).round()}% · ${formatMoney(entry.value)}',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: color),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 5,
                          color: color,
                          backgroundColor: color.withValues(alpha: 0.10),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _catColor(ProjectCategory cat) {
    return switch (cat) {
      ProjectCategory.design => const Color(0xFF7C3AED),
      ProjectCategory.development => const Color(0xFF2563EB),
      ProjectCategory.marketing => const Color(0xFFF59E0B),
      ProjectCategory.content => const Color(0xFF10B981),
      ProjectCategory.consulting => const Color(0xFFEF4444),
      ProjectCategory.other => const Color(0xFF6B7280),
    };
  }
}

// ── Risk Analysis Panel ───────────────────────────────────────────────────────

class _RiskAnalysisPanel extends StatelessWidget {
  const _RiskAnalysisPanel({required this.projects});
  final List<ProjectFinance> projects;

  @override
  Widget build(BuildContext context) {
    final low = projects.where((p) => p.riskScore < 25).length;
    final med = projects.where((p) => p.riskScore >= 25 && p.riskScore < 55).length;
    final high = projects.where((p) => p.riskScore >= 55).length;
    final total = projects.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              _RiskBubble(
                label: 'Ổn định',
                count: low,
                total: total,
                color: const Color(0xFF10B981),
              ),
              const SizedBox(width: 10),
              _RiskBubble(
                label: 'Cần chú ý',
                count: med,
                total: total,
                color: const Color(0xFFF59E0B),
              ),
              const SizedBox(width: 10),
              _RiskBubble(
                label: 'Nguy hiểm',
                count: high,
                total: total,
                color: const Color(0xFFEF4444),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Risk factors summary
          _RiskFactorSummary(
            label: 'Chưa ký hợp đồng',
            count: projects.where((p) => !p.contractSigned).length,
            total: total,
            color: const Color(0xFFEF4444),
          ),
          _RiskFactorSummary(
            label: 'Chưa nhận cọc',
            count: projects.where((p) => !p.hasDeposit).length,
            total: total,
            color: const Color(0xFFF59E0B),
          ),
          _RiskFactorSummary(
            label: 'Có thay đổi scope',
            count: projects.where((p) => p.scopeChangeCount > 0).length,
            total: total,
            color: const Color(0xFF7C3AED),
          ),
          _RiskFactorSummary(
            label: 'Quá hạn thanh toán',
            count: projects.where((p) => p.overdueDays > 0).length,
            total: total,
            color: const Color(0xFFB3261E),
          ),
        ],
      ),
    );
  }
}

class _RiskBubble extends StatelessWidget {
  const _RiskBubble({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  final String label;
  final int count;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: -1,
              ),
            ),
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.black54)),
            if (total > 0)
              Text(
                '${(count / total * 100).round()}%',
                style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w700),
              ),
          ],
        ),
      ),
    );
  }
}

class _RiskFactorSummary extends StatelessWidget {
  const _RiskFactorSummary({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  final String label;
  final int count;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : count / total;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ),
          Text(
            '$count dự án',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: color),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 5,
                color: color,
                backgroundColor: color.withValues(alpha: 0.10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Risk Leaderboard ──────────────────────────────────────────────────────────

class _RiskLeaderboard extends StatelessWidget {
  const _RiskLeaderboard({required this.projects});
  final List<ProjectFinance> projects;

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) return const SizedBox.shrink();
    final sorted = [...projects]
      ..sort((a, b) => b.riskScore.compareTo(a.riskScore));

    return Container(
      decoration: cardDecoration(),
      child: Column(
        children: sorted.asMap().entries.map((entry) {
          final i = entry.key;
          final p = entry.value;
          final color = riskScoreColor(p.riskScore);
          final isLast = i == sorted.length - 1;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : const Border(
                      bottom: BorderSide(color: Color(0xFFF3F4F6))),
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: Colors.black45),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      Text(p.client,
                          style: const TextStyle(
                              color: Colors.black38, fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                            color: color.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        '${p.riskScore}/100',
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.riskScoreLabel,
                      style: TextStyle(color: color, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
