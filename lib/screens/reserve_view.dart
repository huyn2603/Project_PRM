import 'package:flutter/material.dart';

import '../models/project_finance.dart';
import '../utils/helpers.dart';
import '../widgets/shared_widgets.dart';

class ReserveView extends StatelessWidget {
  const ReserveView({
    super.key,
    required this.projects,
    required this.reserveRate,
    required this.onReserveRateChanged,
  });

  final List<ProjectFinance> projects;
  final double reserveRate;
  final ValueChanged<double> onReserveRateChanged;

  Future<void> _openRateDialog(BuildContext context) async {
    final rate = await showDialog<double>(
      context: context,
      builder: (_) => ReserveRateDialog(initialRate: reserveRate),
    );
    if (rate != null) onReserveRateChanged(rate);
  }

  @override
  Widget build(BuildContext context) {
    final reserve = projects.fold<double>(0, (s, p) => s + p.reserveAmount);
    final income = projects.fold<double>(0, (s, p) => s + p.paidAmount);
    final actualRate = income == 0 ? 0.0 : reserve / income;

    // Goal: 3 months runway
    const monthlyTarget = 30000000.0; // estimate
    const runwayTarget = monthlyTarget * 3;
    final runwayProgress = (reserve / runwayTarget).clamp(0.0, 1.0);

    return AppPage(
      title: 'Quỹ dự phòng',
      subtitle: 'Tự động trích thu nhập vào tiết kiệm',
      action: IconButton.filledTonal(
        tooltip: 'Cài đặt tỷ lệ',
        onPressed: () => _openRateDialog(context),
        icon: const Icon(Icons.tune_rounded, size: 20),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          // ── Hero card ──
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.savings_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quỹ dự phòng cá nhân',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                        Text('Tự động trích từ thu nhập',
                            style: TextStyle(
                                color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  formatMoneyFull(reserve),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tỷ lệ hiện tại: ${(actualRate * 100).round()}% / Mục tiêu: ${(reserveRate * 100).round()}%',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 14),
                // Rate progress
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: reserveRate == 0
                        ? 0
                        : (actualRate / reserveRate).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    color: const Color(0xFF93C5FD),
                  ),
                ),
                const SizedBox(height: 16),

                // ── 3 metric boxes ──
                Row(
                  children: [
                    Expanded(
                      child: _ReserveStat(
                        label: 'Tỷ lệ trích',
                        value: '${(reserveRate * 100).round()}%',
                        icon: Icons.percent_rounded,
                      ),
                    ),
                    Container(
                        width: 1,
                        height: 32,
                        color: Colors.white.withValues(alpha: 0.2)),
                    Expanded(
                      child: _ReserveStat(
                        label: 'Runway',
                        value: reserve == 0
                            ? '—'
                            : '${(reserve / (monthlyTarget)).toStringAsFixed(1)} tháng',
                        icon: Icons.timeline_rounded,
                      ),
                    ),
                    Container(
                        width: 1,
                        height: 32,
                        color: Colors.white.withValues(alpha: 0.2)),
                    Expanded(
                      child: _ReserveStat(
                        label: 'Mục tiêu',
                        value: formatMoney(runwayTarget),
                        icon: Icons.flag_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Runway progress
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Tiến độ quỹ 3 tháng',
                            style: TextStyle(
                                color: Colors.white54, fontSize: 11)),
                        const Spacer(),
                        Text(
                          '${(runwayProgress * 100).round()}%',
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: runwayProgress,
                        minHeight: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        color: const Color(0xFF6EE7B7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Tips ──
          _ReserveTipCard(reserveRate: reserveRate, actualRate: actualRate),
          const SizedBox(height: 20),

          // ── Per-project breakdown ──
          const SectionHeader(title: 'Trích lập theo dự án'),
          if (projects.isEmpty)
            const EmptyState(
              icon: Icons.savings_outlined,
              title: 'Chưa có quỹ dự phòng',
              message: 'Khi ghi nhận thanh toán, app sẽ tự động trích quỹ.',
            )
          else
            ...projects.map((p) => _ReserveProjectRow(project: p)),
        ],
      ),
    );
  }
}

class _ReserveStat extends StatelessWidget {
  const _ReserveStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 10)),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: -0.3)),
        ],
      ),
    );
  }
}

// ── Reserve Tips Card ─────────────────────────────────────────────────────────

class _ReserveTipCard extends StatelessWidget {
  const _ReserveTipCard({
    required this.reserveRate,
    required this.actualRate,
  });

  final double reserveRate;
  final double actualRate;

  @override
  Widget build(BuildContext context) {
    final isOnTrack = actualRate >= reserveRate * 0.9;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOnTrack
            ? const Color(0xFFF0FDF4)
            : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOnTrack
              ? const Color(0xFFBBF7D0)
              : const Color(0xFFFDE68A),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isOnTrack
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF59E0B))
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isOnTrack
                  ? Icons.check_circle_rounded
                  : Icons.lightbulb_rounded,
              color: isOnTrack
                  ? const Color(0xFF10B981)
                  : const Color(0xFFF59E0B),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOnTrack ? 'Đang đúng hướng!' : 'Gợi ý cải thiện',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: isOnTrack
                        ? const Color(0xFF065F46)
                        : const Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isOnTrack
                      ? 'Tỷ lệ dự phòng đang đạt mục tiêu ${(reserveRate * 100).round()}%. Tiếp tục duy trì!'
                      : 'Tỷ lệ dự phòng thực tế ${(actualRate * 100).round()}% thấp hơn mục tiêu ${(reserveRate * 100).round()}%. Hãy tăng tỷ lệ hoặc ghi nhận thêm thanh toán.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isOnTrack
                        ? const Color(0xFF047857)
                        : const Color(0xFFB45309),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reserve Project Row ───────────────────────────────────────────────────────

class _ReserveProjectRow extends StatelessWidget {
  const _ReserveProjectRow({required this.project});
  final ProjectFinance project;

  @override
  Widget build(BuildContext context) {
    final p = project;
    final rate = p.paidAmount == 0 ? 0.0 : p.reserveAmount / p.paidAmount;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.lock_rounded,
                color: Color(0xFF2563EB), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 13),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: rate.clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: const Color(0xFFE5E7EB),
                    color: const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Đã thu ${formatMoney(p.paidAmount)} · Trích ${(rate * 100).round()}%',
                  style: const TextStyle(
                      color: Colors.black45, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatMoney(p.reserveAmount),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Color(0xFF2563EB),
                  letterSpacing: -0.3,
                ),
              ),
              const Text('đã trích',
                  style: TextStyle(fontSize: 10, color: Colors.black38)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Reserve Rate Dialog ───────────────────────────────────────────────────────

class ReserveRateDialog extends StatefulWidget {
  const ReserveRateDialog({super.key, required this.initialRate});

  final double initialRate;

  @override
  State<ReserveRateDialog> createState() => _ReserveRateDialogState();
}

class _ReserveRateDialogState extends State<ReserveRateDialog> {
  late double _rate;

  static const _presets = [0.10, 0.15, 0.20, 0.25, 0.30];

  @override
  void initState() {
    super.initState();
    _rate = widget.initialRate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tỷ lệ dự phòng',
          style: TextStyle(fontWeight: FontWeight.w800)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(_rate * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2563EB),
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(width: 8),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('của',
                        style: TextStyle(color: Colors.black45, fontSize: 12)),
                    Text('thu nhập',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          Slider(
            value: _rate,
            min: 0.05,
            max: 0.50,
            divisions: 45,
            label: '${(_rate * 100).round()}%',
            onChanged: (v) => setState(() => _rate = v),
          ),
          // Preset buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presets
                .map(
                  (p) => ChoiceChip(
                    label: Text('${(p * 100).round()}%'),
                    selected: (_rate - p).abs() < 0.01,
                    onSelected: (_) => setState(() => _rate = p),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Text(
              'Khuyến nghị: 20–30% thu nhập để xây dựng quỹ khẩn cấp đủ 3–6 tháng chi phí.',
              style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.5),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, _rate),
          icon: const Icon(Icons.save_rounded, size: 18),
          label: const Text('Lưu'),
        ),
      ],
    );
  }
}
