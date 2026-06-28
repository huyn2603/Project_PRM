import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/app_reminder.dart';
import '../models/app_user.dart';
import '../models/project_finance.dart';
import '../services/auth_service.dart';
import 'auth_scope.dart';
import '../utils/helpers.dart';

// ─── AppPage ─────────────────────────────────────────────────────────────────

class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.maybeOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.black45,
                          ),
                    ),
                  ],
                ),
              ),
              if (action != null) ...[
                const SizedBox(width: 8),
                action!,
              ],
              if (auth != null) ...[
                const SizedBox(width: 6),
                Badge(
                  isLabelVisible:
                      auth.reminders.any((reminder) => !reminder.isRead),
                  label: Text(
                    '${auth.reminders.where((reminder) => !reminder.isRead).length}',
                  ),
                  child: IconButton(
                    tooltip: 'Thông báo',
                    icon: const Icon(Icons.notifications_none_rounded),
                    onPressed: () async {
                      final reminder = await showDialog<AppReminder>(
                        context: context,
                        builder: (_) => _NotificationCenterDialog(
                          reminders: auth.reminders,
                        ),
                      );
                      if (!context.mounted) return;
                      if (reminder != null) {
                        auth.onReminderSelected(reminder);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 2),
                PopupMenuButton<String>(
                  tooltip: 'Tài khoản',
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) async {
                    if (value == 'profile') {
                      final updated = await showDialog<AppUser>(
                        context: context,
                        builder: (_) => _ProfileDialog(user: auth.user),
                      );
                      if (updated != null) auth.onUserChanged(updated);
                    } else if (value == 'settings') {
                      final updated = await showDialog<AppUser>(
                        context: context,
                        builder: (_) => _SettingsDialog(user: auth.user),
                      );
                      if (updated != null) auth.onUserChanged(updated);
                    } else if (value == 'logout') {
                      auth.onLogout();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      enabled: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.user.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            auth.user.email,
                            style: const TextStyle(
                              color: Colors.black45,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'profile',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.person_outline_rounded, size: 20),
                        title: Text('Hồ sơ'),
                        dense: true,
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'settings',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.settings_outlined, size: 20),
                        title: Text('Cài đặt'),
                        dense: true,
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'logout',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.logout, size: 20),
                        title: Text('Đăng xuất'),
                        dense: true,
                      ),
                    ),
                  ],
                  child: _UserAvatar(user: auth.user, radius: 19),
                ),
              ],
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

// ─── SectionHeader ────────────────────────────────────────────────────────────

class _NotificationCenterDialog extends StatelessWidget {
  const _NotificationCenterDialog({required this.reminders});

  final List<AppReminder> reminders;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thông báo & nhắc việc'),
      content: SizedBox(
        width: 520,
        child: reminders.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_none_rounded,
                        size: 42, color: Colors.black26),
                    SizedBox(height: 10),
                    Text('Chưa có nhắc việc nào.'),
                  ],
                ),
              )
            : ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 520),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: reminders.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final reminder = reminders[index];
                    final color = reminder.isUrgent
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF2563EB);
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.12),
                        foregroundColor: color,
                        child: Icon(_reminderIcon(reminder.kind), size: 20),
                      ),
                      title: Text(
                        reminder.title,
                        style: TextStyle(
                          fontWeight: reminder.isRead
                              ? FontWeight.w600
                              : FontWeight.w900,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(reminder.message),
                      ),
                      trailing: reminder.isRead
                          ? null
                          : const Icon(Icons.circle,
                              size: 9, color: Color(0xFF2563EB)),
                      onTap: () => Navigator.pop(context, reminder),
                    );
                  },
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    );
  }

  static IconData _reminderIcon(ReminderKind kind) => switch (kind) {
        ReminderKind.paymentDue => Icons.schedule_rounded,
        ReminderKind.paymentOverdue => Icons.warning_amber_rounded,
        ReminderKind.deliveryDue => Icons.assignment_turned_in_outlined,
        ReminderKind.teamPayout => Icons.groups_outlined,
      };
}

class _ProfileDialog extends StatefulWidget {
  const _ProfileDialog({required this.user});

  final AppUser user;

  @override
  State<_ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<_ProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullName;
  late final TextEditingController _phone;
  late final TextEditingController _jobTitle;
  late final TextEditingController _bio;
  Uint8List? _avatarBytes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fullName = TextEditingController(text: widget.user.fullName);
    _phone = TextEditingController(text: widget.user.phone);
    _jobTitle = TextEditingController(text: widget.user.jobTitle);
    _bio = TextEditingController(text: widget.user.bio);
  }

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _jobTitle.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (mounted) setState(() => _avatarBytes = bytes);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final updated = await AuthService().saveUser(
        widget.user.copyWith(
          fullName: _fullName.text.trim(),
          phone: _phone.text.trim(),
          jobTitle: _jobTitle.text.trim(),
          bio: _bio.text.trim(),
        ),
        avatarBytes: _avatarBytes,
      );
      if (mounted) Navigator.pop(context, updated);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể lưu hồ sơ: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chỉnh sửa hồ sơ'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _UserAvatar(
                      user: widget.user,
                      radius: 44,
                      memoryBytes: _avatarBytes,
                    ),
                    Positioned(
                      right: -6,
                      bottom: -4,
                      child: IconButton.filled(
                        tooltip: 'Chọn ảnh đại diện',
                        onPressed: _saving ? null : _pickAvatar,
                        icon: const Icon(Icons.photo_camera_outlined, size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _fullName,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (value) => (value ?? '').trim().length < 2
                      ? 'Vui lòng nhập họ tên hợp lệ.'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: widget.user.email,
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Email đăng nhập',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _jobTitle,
                  decoration: const InputDecoration(
                    labelText: 'Chức danh / chuyên môn',
                    hintText: 'Ví dụ: UI/UX Designer',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _bio,
                  maxLines: 3,
                  maxLength: 240,
                  decoration: const InputDecoration(
                    labelText: 'Giới thiệu ngắn',
                    hintText: 'Kinh nghiệm, thế mạnh hoặc cách bạn làm việc...',
                    prefixIcon: Icon(Icons.notes_rounded),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined, size: 18),
          label: Text(_saving ? 'Đang lưu...' : 'Lưu hồ sơ'),
        ),
      ],
    );
  }
}

class _SettingsDialog extends StatefulWidget {
  const _SettingsDialog({required this.user});

  final AppUser user;

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  late int _reminderDays;
  late bool _notifyPayments;
  late bool _notifyProjects;
  late bool _notifyPayouts;
  late double _reserveRate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _reminderDays = widget.user.reminderDays;
    _notifyPayments = widget.user.notifyPayments;
    _notifyProjects = widget.user.notifyProjectUpdates;
    _notifyPayouts = widget.user.notifyTeamPayouts;
    _reserveRate = widget.user.reserveRate;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = await AuthService().saveUser(
        widget.user.copyWith(
          reminderDays: _reminderDays,
          notifyPayments: _notifyPayments,
          notifyProjectUpdates: _notifyProjects,
          notifyTeamPayouts: _notifyPayouts,
          reserveRate: _reserveRate,
        ),
      );
      if (mounted) Navigator.pop(context, updated);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể lưu cài đặt: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cài đặt'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Thông báo',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.payments_outlined),
                title: const Text('Thu tiền từ khách'),
                subtitle: const Text('Khi nhận cọc, nhận thêm hoặc thu đủ'),
                value: _notifyPayments,
                onChanged: (value) => setState(() => _notifyPayments = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.task_alt_rounded),
                title: const Text('Tiến độ dự án'),
                subtitle: const Text('Khi dự án hoàn thành hoặc có rủi ro cao'),
                value: _notifyProjects,
                onChanged: (value) => setState(() => _notifyProjects = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.groups_outlined),
                title: const Text('Chia tiền nhóm'),
                subtitle:
                    const Text('Khi có tiền cần chia hoặc vừa trả thành viên'),
                value: _notifyPayouts,
                onChanged: (value) => setState(() => _notifyPayouts = value),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.notifications_active_outlined),
                title: const Text('Nhắc trước hạn'),
                subtitle: Text('Hiển thị trước $_reminderDays ngày'),
                trailing: DropdownButton<int>(
                  value: _reminderDays,
                  items: const [3, 5, 7, 14]
                      .map((days) => DropdownMenuItem(
                            value: days,
                            child: Text('$days ngày'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _reminderDays = value);
                  },
                ),
              ),
              const Divider(height: 28),
              Row(
                children: [
                  const Icon(Icons.savings_outlined),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tỷ lệ quỹ dự phòng'),
                        Text('Tính trên phần tiền của bạn sau khi chia nhóm',
                            style:
                                TextStyle(fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                  ),
                  Text('${(_reserveRate * 100).round()}%',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
              Slider(
                value: _reserveRate,
                min: 0,
                max: 0.5,
                divisions: 10,
                label: '${(_reserveRate * 100).round()}%',
                onChanged: (value) => setState(() => _reserveRate = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: const Icon(Icons.save_outlined, size: 18),
          label: Text(_saving ? 'Đang lưu...' : 'Lưu cài đặt'),
        ),
      ],
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({
    required this.user,
    required this.radius,
    this.memoryBytes,
  });

  final AppUser user;
  final double radius;
  final Uint8List? memoryBytes;

  @override
  Widget build(BuildContext context) {
    ImageProvider<Object>? image;
    if (memoryBytes != null) {
      image = MemoryImage(memoryBytes!);
    } else if (user.avatarUrl.isNotEmpty) {
      image = NetworkImage(user.avatarUrl);
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundImage: image,
      foregroundColor: Colors.white,
      child: image == null
          ? Text(
              user.initials,
              style: TextStyle(
                fontSize: radius * 0.65,
                fontWeight: FontWeight.w900,
              ),
            )
          : null,
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ─── RiskChip ─────────────────────────────────────────────────────────────────

class RiskChip extends StatelessWidget {
  const RiskChip({super.key, required this.risk});

  final ProjectRisk risk;

  @override
  Widget build(BuildContext context) {
    final color = riskColor(risk);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            riskText(risk),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── RiskScoreBadge ───────────────────────────────────────────────────────────

class RiskScoreBadge extends StatelessWidget {
  const RiskScoreBadge({super.key, required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final color = riskScoreColor(score);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        'Rủi ro $score/100',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── StatusChip ───────────────────────────────────────────────────────────────

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon(status), size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            paymentStatusText(status),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── EmptyState ───────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: cardDecoration(),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              size: 36,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black45, height: 1.5),
          ),
          if (action != null) ...[
            const SizedBox(height: 18),
            action!,
          ],
        ],
      ),
    );
  }
}

// ─── MetricCard ───────────────────────────────────────────────────────────────

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: TextStyle(fontSize: 11, color: color),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── MiniStat ─────────────────────────────────────────────────────────────────

class MiniStat extends StatelessWidget {
  const MiniStat({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.black45),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── InfoRow ──────────────────────────────────────────────────────────────────

class InfoRow extends StatelessWidget {
  const InfoRow(
      {super.key,
      required this.icon,
      required this.label,
      required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.black38),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.black45, fontSize: 13),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── StarRating ───────────────────────────────────────────────────────────────

class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 16,
          color: i < rating ? const Color(0xFFFFB020) : Colors.black26,
        ),
      ),
    );
  }
}
