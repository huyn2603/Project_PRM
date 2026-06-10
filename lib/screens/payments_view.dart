import 'package:flutter/material.dart';

import '../models/project_finance.dart';
import '../utils/helpers.dart';
import '../widgets/shared_widgets.dart';

class PaymentsView extends StatelessWidget {
  const PaymentsView({
    super.key,
    required this.projects,
    required this.onRecordPayment,
    required this.onSendReminder,
  });

  final List<ProjectFinance> projects;
  final void Function(ProjectFinance project, double amount) onRecordPayment;
  final ValueChanged<ProjectFinance> onSendReminder;

  Future<void> _openPaymentDialog(
    BuildContext context,
    ProjectFinance project,
  ) async {
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => PaymentDialog(project: project),
    );
    if (amount != null) onRecordPayment(project, amount);
  }

  @override
  Widget build(BuildContext context) {
    final overdueProject =
        projects.any((p) => p.status == PaymentStatus.overdue)
            ? projects.firstWhere((p) => p.status == PaymentStatus.overdue)
            : null;

    return AppPage(
      title: 'Thu nợ',
      subtitle: 'Ghi nhận thanh toán và nhắc khách còn công nợ',
      action: IconButton(
        tooltip: 'Nhắc thanh toán',
        onPressed: overdueProject == null
            ? null
            : () => onSendReminder(overdueProject),
        icon: const Icon(Icons.notifications_active_outlined),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          if (overdueProject != null) ...[
            ReminderBanner(
              project: overdueProject,
              onSendReminder: () => onSendReminder(overdueProject),
            ),
            const SizedBox(height: 16),
          ],
          if (projects.isEmpty)
            const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Chưa có khoản thu',
              message: 'Tạo dự án để bắt đầu theo dõi thanh toán.',
            )
          else
            ...projects.map(
              (project) => PaymentTimeline(
                project: project,
                onRecordPayment: project.remaining <= 0
                    ? null
                    : () => _openPaymentDialog(context, project),
              ),
            ),
        ],
      ),
    );
  }
}

class PaymentTimeline extends StatelessWidget {
  const PaymentTimeline({
    super.key,
    required this.project,
    required this.onRecordPayment,
  });

  final ProjectFinance project;
  final VoidCallback? onRecordPayment;

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
            backgroundColor:
                statusColor(project.status).withValues(alpha: 0.14),
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        project.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: onRecordPayment,
                      icon: const Icon(Icons.add_card_outlined),
                      label: const Text('Ghi thu'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                StatusChip(status: project.status),
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
                        child: MiniStat(label: 'Hạn', value: project.dueDate)),
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
  const ReminderBanner({
    super.key,
    required this.project,
    required this.onSendReminder,
  });

  final ProjectFinance project;
  final VoidCallback onSendReminder;

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
            onPressed: onSendReminder,
            icon: const Icon(Icons.send_outlined),
          ),
        ],
      ),
    );
  }
}

class PaymentDialog extends StatefulWidget {
  const PaymentDialog({super.key, required this.project});

  final ProjectFinance project;

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.project.remaining.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double _parseMoney(String value) {
    final clean = value.replaceAll('.', '').replaceAll(',', '').trim();
    return double.tryParse(clean) ?? 0;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(context, _parseMoney(_amountController.text));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ghi nhận thanh toán'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.project.name,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text('Còn cần thu: ${formatMoney(widget.project.remaining)}'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số tiền nhận',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              validator: (value) {
                final amount = _parseMoney(value ?? '');
                if (amount <= 0) return 'Nhập số tiền hợp lệ.';
                if (amount > widget.project.remaining) {
                  return 'Không được vượt khoản còn lại.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.check),
          label: const Text('Ghi nhận'),
        ),
      ],
    );
  }
}
