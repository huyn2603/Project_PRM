import 'package:flutter/material.dart';

import '../models/project_finance.dart';
import '../utils/helpers.dart';
import '../widgets/shared_widgets.dart';

class PaymentsView extends StatelessWidget {
  const PaymentsView({
    super.key,
    required this.projects,
    required this.onRecordPayment,
  });

  final List<ProjectFinance> projects;
  final void Function(ProjectFinance project, double amount) onRecordPayment;

  Future<void> _openPaymentDialog(
      BuildContext ctx, ProjectFinance project) async {
    final amount = await showDialog<double>(
      context: ctx,
      builder: (context) => PaymentDialog(project: project),
    );
    if (amount != null) onRecordPayment(project, amount);
  }

  @override
  Widget build(BuildContext context) {
    final overdueList =
        projects.where((p) => p.status == PaymentStatus.overdue).toList();
    final pendingList = projects
        .where((p) =>
            p.status != PaymentStatus.overdue &&
            p.status != PaymentStatus.paid &&
            p.remaining > 0)
        .toList();
    final paidList =
        projects.where((p) => p.status == PaymentStatus.paid).toList();

    final totalDebt = projects.fold<double>(0, (s, p) => s + p.remaining);
    final totalOverdue = overdueList.fold<double>(0, (s, p) => s + p.remaining);

    return AppPage(
      title: 'Thu nợ',
      subtitle: 'Theo dõi và ghi nhận các khoản thanh toán dự án',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          // ── Summary row ──
          Row(
            children: [
              Expanded(
                child: _SummaryBox(
                  label: 'Tổng phải thu',
                  value: formatMoney(totalDebt),
                  color: const Color(0xFFF59E0B),
                  icon: Icons.pending_actions_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryBox(
                  label: 'Quá hạn',
                  value: formatMoney(totalOverdue),
                  color: const Color(0xFFEF4444),
                  icon: Icons.alarm_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryBox(
                  label: 'Dự án có nợ',
                  value:
                      '${projects.where((p) => p.remaining > 0).length} dự án',
                  color: const Color(0xFF2563EB),
                  icon: Icons.folder_copy_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ── Overdue ──
          if (overdueList.isNotEmpty) ...[
            SectionHeader(title: '⚠️ Quá hạn (${overdueList.length})'),
            ...overdueList.map(
              (p) => _PaymentCard(
                project: p,
                onRecord: () => _openPaymentDialog(context, p),
                highlight: true,
              ),
            ),
            const SizedBox(height: 6),
          ],

          // ── Pending ──
          if (pendingList.isNotEmpty) ...[
            SectionHeader(title: 'Chờ thanh toán (${pendingList.length})'),
            ...pendingList.map(
              (p) => _PaymentCard(
                project: p,
                onRecord: () => _openPaymentDialog(context, p),
                highlight: false,
              ),
            ),
            const SizedBox(height: 6),
          ],

          // ── Paid ──
          if (paidList.isNotEmpty) ...[
            SectionHeader(title: 'Đã hoàn tất (${paidList.length})'),
            ...paidList.map(
              (p) => _PaymentCard(
                project: p,
                onRecord: null,
                highlight: false,
              ),
            ),
          ],

          if (projects.isEmpty)
            const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Chưa có khoản thu',
              message: 'Tạo dự án để bắt đầu theo dõi thanh toán.',
            ),
        ],
      ),
    );
  }
}

// ── Summary box ───────────────────────────────────────────────────────────────

class _SummaryBox extends StatelessWidget {
  const _SummaryBox({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: color,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}

// ── Payment Card ─────────────────────────────────────────────────────────────

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.project,
    required this.onRecord,
    required this.highlight,
  });

  final ProjectFinance project;
  final VoidCallback? onRecord;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final p = project;
    final paidRatio =
        p.totalValue == 0 ? 0.0 : (p.paidAmount / p.totalValue).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: cardDecoration(
        borderColor: highlight ? const Color(0xFFFECACA) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            decoration: highlight
                ? const BoxDecoration(
                    color: Color(0xFFFFF5F5),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  )
                : null,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor(p.status).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    statusIcon(p.status),
                    size: 16,
                    color: statusColor(p.status),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        p.client,
                        style: const TextStyle(
                            color: Colors.black45, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                StatusChip(status: p.status),
              ],
            ),
          ),

          // ── Progress bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      '${(paidRatio * 100).round()}% đã thanh toán',
                      style:
                          const TextStyle(fontSize: 11, color: Colors.black45),
                    ),
                    const Spacer(),
                    Text(
                      '${formatMoney(p.paidAmount)} / ${formatMoney(p.totalValue)}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.black54),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: paidRatio,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE5E7EB),
                    color: p.status == PaymentStatus.paid
                        ? const Color(0xFF10B981)
                        : statusColor(p.status),
                  ),
                ),
              ],
            ),
          ),

          // ── Stats ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Row(
              children: [
                Expanded(
                  child: MiniStat(
                    label: 'Cọc',
                    value: formatMoney(p.depositReceived),
                  ),
                ),
                Expanded(
                  child: MiniStat(
                    label: 'Đã thu',
                    value: formatMoney(p.paidAmount),
                    valueColor: const Color(0xFF10B981),
                  ),
                ),
                Expanded(
                  child: MiniStat(
                    label: 'Còn cần thu',
                    value: formatMoney(p.remaining),
                    valueColor: p.remaining > 0
                        ? (highlight
                            ? const Color(0xFFEF4444)
                            : const Color(0xFFF59E0B))
                        : null,
                  ),
                ),
                Expanded(
                  child: MiniStat(
                    label: 'Hạn TT',
                    value: p.dueDate,
                    valueColor: highlight ? const Color(0xFFEF4444) : null,
                  ),
                ),
              ],
            ),
          ),

          // ── Action buttons ──
          if (onRecord != null)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  if (onRecord != null)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onRecord,
                        icon: const Icon(Icons.add_card_rounded, size: 15),
                        label: const Text('Ghi thu'),
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

// ── Payment Dialog ────────────────────────────────────────────────────────────

class PaymentDialog extends StatefulWidget {
  const PaymentDialog({super.key, required this.project});

  final ProjectFinance project;

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
        text: widget.project.remaining.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(context, parseMoney(_amount.text));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.project;
    final paidRatio =
        p.totalValue == 0 ? 0.0 : (p.paidAmount / p.totalValue).clamp(0.0, 1.0);

    return AlertDialog(
      title: const Text('Ghi nhận thanh toán',
          style: TextStyle(fontWeight: FontWeight.w800)),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(p.client,
                      style:
                          const TextStyle(color: Colors.black45, fontSize: 12)),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: paidRatio,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE5E7EB),
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: MiniStat(
                          label: 'Đã thu',
                          value: formatMoney(p.paidAmount),
                        ),
                      ),
                      Expanded(
                        child: MiniStat(
                          label: 'Còn cần thu',
                          value: formatMoney(p.remaining),
                          valueColor: const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amount,
              onChanged: (_) => setState(() {}),
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Số tiền nhận',
                prefixIcon: Icon(Icons.payments_outlined),
                suffixText: '₫',
              ),
              validator: (v) {
                final val = parseMoney(v ?? '');
                if (val <= 0) return 'Nhập số tiền hợp lệ.';
                if (val > p.remaining) return 'Vượt khoản còn lại.';
                return null;
              },
            ),
            if (p.workMode == ProjectWorkMode.team &&
                p.teamMembers.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Khoản này sẽ được phân bổ',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    ...p.teamMembers.map(
                      (member) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${member.name} · ${member.sharePercent.toStringAsFixed(0)}%',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Text(
                              formatMoney(
                                parseMoney(_amount.text) *
                                    member.sharePercent /
                                    100,
                              ),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 12),
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Phần của bạn',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                        Text(
                          formatMoney(
                            parseMoney(_amount.text) *
                                (1 - p.teamSharePercent / 100),
                          ),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
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
          icon: const Icon(Icons.check_rounded, size: 18),
          label: const Text('Xác nhận'),
        ),
      ],
    );
  }
}
