import 'package:flutter/material.dart';
import '../models/project_finance.dart';
import '../utils/helpers.dart';
import '../widgets/shared_widgets.dart';

class PaymentsView extends StatelessWidget {
  const PaymentsView({super.key, required this.projects});

  final List<ProjectFinance> projects;

  @override
  Widget build(BuildContext context) {
    // Tự động kiểm tra xem có dự án nào bị quá hạn không để hiển thị Banner thông báo gấp
    final overdueProject = projects.any((p) => p.status == PaymentStatus.overdue)
        ? projects.firstWhere((p) => p.status == PaymentStatus.overdue)
        : null;

    return AppPage(
      title: 'Thu nợ',
      subtitle: 'Theo dõi cọc, số còn lại và hạn thanh toán',
      action: IconButton(
        tooltip: 'Nhắc thanh toán',
        onPressed: () {},
        icon: const Icon(Icons.notifications_active_outlined),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          if (overdueProject != null) ...[
            ReminderBanner(project: overdueProject),
            const SizedBox(height: 16),
          ],
          ...projects.map((project) => PaymentTimeline(project: project)),
        ],
      ),
    );
  }
}

class PaymentTimeline extends StatelessWidget {
  const PaymentTimeline({super.key, required this.project});

  final ProjectFinance project;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: statusColor(project.status).withValues(alpha: 0.14),
            child: Icon(
              statusIcon(project.status),
              color: statusColor(project.status),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  paymentStatusText(project.status),
                  style: TextStyle(
                    color: statusColor(project.status),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: MiniStat(
                        label: 'Đã nhận',
                        value: formatMoney(project.paidAmount),
                      ),
                    ),
                    Expanded(
                      child: MiniStat(
                        label: 'Cần thu',
                        value: formatMoney(project.remaining),
                      ),
                    ),
                    Expanded(
                      child: MiniStat(label: 'Hạn', value: project.dueDate),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReminderBanner extends StatelessWidget {
  const ReminderBanner({super.key, required this.project});

  final ProjectFinance project;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEE7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE9B49B)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notification_important_outlined,
            color: Color(0xFFB3261E),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${project.client} đang quá hạn. Cần nhắc thanh toán ${formatMoney(project.remaining)}.',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: 'Gửi nhắc',
            onPressed: () {},
            icon: const Icon(Icons.send_outlined),
          ),
        ],
      ),
    );
  }
}