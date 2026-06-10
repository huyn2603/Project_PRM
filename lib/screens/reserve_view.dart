import 'package:flutter/material.dart';
import '../models/project_finance.dart';
import '../utils/helpers.dart';
import '../widgets/shared_widgets.dart';

class ReserveView extends StatelessWidget {
  const ReserveView({super.key, required this.projects});

  final List<ProjectFinance> projects;

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
        onPressed: () {},
        icon: const Icon(Icons.tune),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          ReserveGoalCard(reserve: reserve, rate: rate),
          const SizedBox(height: 18),
          const SectionHeader(title: 'Trích lập theo dự án'),
          ...projects.map((project) => ReserveRow(project: project)),
        ],
      ),
    );
  }
}

class ReserveGoalCard extends StatelessWidget {
  const ReserveGoalCard({super.key, required this.reserve, required this.rate});

  final double reserve;
  final double rate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Theme(
            data: ThemeData(iconTheme: const IconThemeData(color: Color(0xFF315C9A))),
            child: Row(
              children: [
                const Icon(Icons.savings_outlined),
                const SizedBox(width: 10),
                Text(
                  'Mục tiêu dự phòng',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
            value: rate.clamp(0, 1),
            minHeight: 10,
            borderRadius: BorderRadius.circular(99),
            color: const Color(0xFF315C9A),
            backgroundColor: const Color(0xFFE3E5DD),
          ),
          const SizedBox(height: 8),
          Text('Đã trích ${(rate * 100).round()}% trên tổng thu nhập đã nhận'),
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
                  'Tự động trích 20% khi ghi nhận thu nhập',
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