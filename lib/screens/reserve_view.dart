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
      builder: (context) => ReserveRateDialog(initialRate: reserveRate),
    );
    if (rate != null) onReserveRateChanged(rate);
  }

  @override
  Widget build(BuildContext context) {
    final reserve = projects.fold<double>(0, (sum, p) => sum + p.reserveAmount);
    final income = projects.fold<double>(0, (sum, p) => sum + p.paidAmount);
    final rate = income == 0 ? 0.0 : reserve / income;

    return AppPage(
      title: 'Quỹ dự phòng',
      subtitle: 'Tự động trích thu nhập vào tiết kiệm cá nhân',
      action: IconButton(
        tooltip: 'Cài đặt tỷ lệ',
        onPressed: () => _openRateDialog(context),
        icon: const Icon(Icons.tune),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          ReserveGoalCard(
            reserve: reserve,
            rate: rate,
            targetRate: reserveRate,
          ),
          const SizedBox(height: 18),
          const SectionHeader(title: 'Trích lập theo dự án'),
          if (projects.isEmpty)
            const EmptyState(
              icon: Icons.savings_outlined,
              title: 'Chưa có quỹ dự phòng',
              message: 'Khi ghi nhận thanh toán, app sẽ tự trích quỹ.',
            )
          else
            ...projects.map((project) => ReserveRow(project: project)),
        ],
      ),
    );
  }
}

class ReserveGoalCard extends StatelessWidget {
  const ReserveGoalCard({
    super.key,
    required this.reserve,
    required this.rate,
    required this.targetRate,
  });

  final double reserve;
  final double rate;
  final double targetRate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Theme(
            data: ThemeData(
              iconTheme: const IconThemeData(color: Color(0xFF315C9A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.savings_outlined),
                const SizedBox(width: 10),
                Text(
                  'Mục tiêu dự phòng',
                  style: Theme.of(
                    context,
                  )
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            formatMoney(reserve),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: targetRate == 0 ? 0 : (rate / targetRate).clamp(0, 1),
            minHeight: 10,
            borderRadius: BorderRadius.circular(99),
            color: const Color(0xFF315C9A),
            backgroundColor: const Color(0xFFE3E5DD),
          ),
          const SizedBox(height: 8),
          Text(
            'Đã trích ${(rate * 100).round()}%, mục tiêu hiện tại ${(targetRate * 100).round()}%',
          ),
        ],
      ),
    );
  }
}

class ReserveRow extends StatelessWidget {
  const ReserveRow({super.key, required this.project});

  final ProjectFinance project;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: Color(0xFF315C9A)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  'Đã thu ${formatMoney(project.paidAmount)}',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          Text(
            formatMoney(project.reserveAmount),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class ReserveRateDialog extends StatefulWidget {
  const ReserveRateDialog({super.key, required this.initialRate});

  final double initialRate;

  @override
  State<ReserveRateDialog> createState() => _ReserveRateDialogState();
}

class _ReserveRateDialogState extends State<ReserveRateDialog> {
  late double _rate;

  @override
  void initState() {
    super.initState();
    _rate = widget.initialRate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cài đặt tỷ lệ dự phòng'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${(_rate * 100).round()}%',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          Slider(
            value: _rate,
            min: 0,
            max: 0.5,
            divisions: 50,
            label: '${(_rate * 100).round()}%',
            onChanged: (value) => setState(() => _rate = value),
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
          icon: const Icon(Icons.save_outlined),
          label: const Text('Lưu'),
        ),
      ],
    );
  }
}
