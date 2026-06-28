import 'package:flutter/material.dart';

import '../models/project_finance.dart';
import '../utils/helpers.dart';
import '../widgets/shared_widgets.dart';

class TeamPayoutsView extends StatelessWidget {
  const TeamPayoutsView({
    super.key,
    required this.projects,
    required this.onPayMember,
  });

  final List<ProjectFinance> projects;
  final void Function(
    ProjectFinance project,
    TeamMember member,
    double amount,
  ) onPayMember;

  Future<void> _openPayout(
    BuildContext context,
    ProjectFinance project,
    TeamMember member,
  ) async {
    final amount = await showDialog<double>(
      context: context,
      builder: (_) => _PayoutDialog(project: project, member: member),
    );
    if (amount != null) onPayMember(project, member, amount);
  }

  @override
  Widget build(BuildContext context) {
    final teamProjects = projects
        .where((project) =>
            project.workMode == ProjectWorkMode.team &&
            project.teamMembers.isNotEmpty)
        .toList();
    final payable = teamProjects.fold<double>(
      0,
      (sum, project) => sum + project.teamPayable,
    );
    final paid = teamProjects.fold<double>(
      0,
      (sum, project) => sum + project.teamPaidToDate,
    );
    final earned = teamProjects.fold<double>(
      0,
      (sum, project) => sum + project.teamEarnedToDate,
    );

    return AppPage(
      title: 'Chia tiền nhóm',
      subtitle: 'Tự động tính phần của từng thành viên theo mỗi lần khách trả',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: _PayoutSummary(
                  label: 'Nhóm đã được hưởng',
                  value: formatMoney(earned),
                  color: const Color(0xFF2563EB),
                  icon: Icons.pie_chart_outline_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PayoutSummary(
                  label: 'Chờ chia',
                  value: formatMoney(payable),
                  color: const Color(0xFFF59E0B),
                  icon: Icons.schedule_send_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PayoutSummary(
                  label: 'Đã chia',
                  value: formatMoney(paid),
                  color: const Color(0xFF10B981),
                  icon: Icons.done_all_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (teamProjects.isEmpty)
            const EmptyState(
              icon: Icons.groups_outlined,
              title: 'Chưa có dự án nhóm',
              message:
                  'Tạo hoặc sửa dự án, chọn “Làm theo nhóm” và đặt tỷ lệ % cho từng thành viên.',
            )
          else ...[
            SectionHeader(title: 'Theo dự án (${teamProjects.length})'),
            ...teamProjects.map(
              (project) => _ProjectPayoutCard(
                project: project,
                onPay: (member) => _openPayout(context, project, member),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PayoutSummary extends StatelessWidget {
  const _PayoutSummary({
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
          Icon(icon, color: color, size: 19),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.black45)),
        ],
      ),
    );
  }
}

class _ProjectPayoutCard extends StatelessWidget {
  const _ProjectPayoutCard({
    required this.project,
    required this.onPay,
  });

  final ProjectFinance project;
  final ValueChanged<TeamMember> onPay;

  @override
  Widget build(BuildContext context) {
    final paidRatio = project.teamEarnedToDate <= 0
        ? 0.0
        : (project.teamPaidToDate / project.teamEarnedToDate).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(project.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text(
                            'Đã thu ${formatMoney(project.paidAmount)} · nhóm ${project.teamSharePercent.toStringAsFixed(0)}%',
                            style: const TextStyle(
                                color: Colors.black45, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (project.teamPayable > 0)
                      Chip(
                        label: Text('Chờ ${formatMoney(project.teamPayable)}'),
                        backgroundColor:
                            const Color(0xFFF59E0B).withValues(alpha: 0.1),
                        side: BorderSide.none,
                      )
                    else
                      const Chip(
                        avatar: Icon(Icons.check_rounded,
                            size: 16, color: Color(0xFF10B981)),
                        label: Text('Đã chia đủ'),
                        side: BorderSide.none,
                      ),
                  ],
                ),
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
              ],
            ),
          ),
          const Divider(height: 1),
          ...project.teamMembers.map((member) {
            final earned = project.memberEarnedToDate(member);
            final paid = project.memberPaidToDate(member);
            final payable = project.memberPayable(member);
            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
                foregroundColor: const Color(0xFF2563EB),
                child: Text(
                  member.name.trim().isEmpty
                      ? '?'
                      : member.name.trim()[0].toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              title: Text(
                '${member.name} · ${member.sharePercent.toStringAsFixed(0)}%',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                'Được hưởng ${formatMoney(earned)} · đã nhận ${formatMoney(paid)}',
              ),
              trailing: payable > 0
                  ? FilledButton.tonal(
                      onPressed: () => onPay(member),
                      child: Text('Chia ${formatMoney(payable)}'),
                    )
                  : const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF10B981)),
            );
          }),
        ],
      ),
    );
  }
}

class _PayoutDialog extends StatefulWidget {
  const _PayoutDialog({required this.project, required this.member});

  final ProjectFinance project;
  final TeamMember member;

  @override
  State<_PayoutDialog> createState() => _PayoutDialogState();
}

class _PayoutDialogState extends State<_PayoutDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: widget.project.memberPayable(widget.member).toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final payable = widget.project.memberPayable(widget.member);
    return AlertDialog(
      title: const Text('Xác nhận chia tiền'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.member.name} được hưởng ${widget.member.sharePercent.toStringAsFixed(0)}% trên số tiền khách đã trả.',
            ),
            const SizedBox(height: 6),
            Text(
              'Có thể chia lúc này: ${formatMoney(payable)}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amount,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số tiền thực trả',
                prefixIcon: Icon(Icons.payments_outlined),
                suffixText: '₫',
              ),
              validator: (value) {
                final amount = parseMoney(value ?? '');
                if (amount <= 0) return 'Nhập số tiền hợp lệ.';
                if (amount > payable) return 'Vượt số tiền có thể chia.';
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
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) return;
            Navigator.pop(context, parseMoney(_amount.text));
          },
          icon: const Icon(Icons.check_rounded, size: 18),
          label: const Text('Đã chuyển tiền'),
        ),
      ],
    );
  }
}
