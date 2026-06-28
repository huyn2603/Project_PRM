import 'package:flutter/material.dart';

import '../models/project_finance.dart';
import '../utils/helpers.dart';
import '../widgets/shared_widgets.dart';

enum ProjectFilter { all, active, waitingPayment, highRisk, paid }

class ProjectsView extends StatefulWidget {
  const ProjectsView({
    super.key,
    required this.projects,
    this.focusedProjectId,
    required this.onAddProject,
    required this.onUpdateProject,
    required this.onDeleteProject,
    required this.onPayFull,
  });

  final List<ProjectFinance> projects;
  final String? focusedProjectId;
  final ValueChanged<ProjectFinance> onAddProject;
  final ValueChanged<ProjectFinance> onUpdateProject;
  final ValueChanged<ProjectFinance> onDeleteProject;
  final ValueChanged<ProjectFinance> onPayFull;

  @override
  State<ProjectsView> createState() => _ProjectsViewState();
}

class _ProjectsViewState extends State<ProjectsView> {
  ProjectFilter _filter = ProjectFilter.all;
  final Map<String, GlobalKey> _projectKeys = {};
  String? _lastScrolledProjectId;

  @override
  void didUpdateWidget(covariant ProjectsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusedProjectId != null &&
        widget.focusedProjectId != oldWidget.focusedProjectId) {
      _filter = ProjectFilter.all;
      _lastScrolledProjectId = null;
    }
  }

  void _scrollToFocusedProject() {
    final id = widget.focusedProjectId;
    if (id == null || id == _lastScrolledProjectId) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetContext = _projectKeys[id]?.currentContext;
      if (targetContext == null) return;
      _lastScrolledProjectId = id;
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        alignment: 0.08,
      );
    });
  }

  List<String> get _clients {
    final clients = widget.projects
        .map((p) => p.client.trim())
        .where((client) => client.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return clients;
  }

  List<ProjectFinance> get _filtered {
    return switch (_filter) {
      ProjectFilter.all => widget.projects,
      ProjectFilter.active => widget.projects
          .where((p) => p.progress < 1 && p.remaining > 0)
          .toList(),
      ProjectFilter.waitingPayment =>
        widget.projects.where((p) => p.remaining > 0).toList(),
      ProjectFilter.highRisk =>
        widget.projects.where((p) => p.riskScore >= 55).toList(),
      ProjectFilter.paid =>
        widget.projects.where((p) => p.status == PaymentStatus.paid).toList(),
    };
  }

  Future<void> _openCreate() async {
    final project = await showDialog<ProjectFinance>(
      context: context,
      builder: (context) => ProjectEditorDialog(clients: _clients),
    );
    if (project != null) widget.onAddProject(project);
  }

  Future<void> _openEdit(ProjectFinance project) async {
    final edited = await showDialog<ProjectFinance>(
      context: context,
      builder: (context) => ProjectEditorDialog(
        project: project,
        clients: _clients,
      ),
    );
    if (edited != null) widget.onUpdateProject(edited);
  }

  Future<void> _confirmDelete(ProjectFinance project) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa dự án?'),
        content: Text('Dự án "${project.name}" sẽ bị xóa vĩnh viễn.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok == true) widget.onDeleteProject(project);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    _scrollToFocusedProject();

    return AppPage(
      title: 'Dự án',
      subtitle: 'Quản lý hợp đồng và tiến độ',
      action: FilledButton.icon(
        onPressed: _openCreate,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Mới'),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterBtn(
                    label: 'Tất cả',
                    count: widget.projects.length,
                    value: ProjectFilter.all,
                    selected: _filter,
                    onChanged: (f) => setState(() => _filter = f)),
                const SizedBox(width: 8),
                _FilterBtn(
                    label: 'Đang làm',
                    count: widget.projects
                        .where((p) => p.progress < 1 && p.remaining > 0)
                        .length,
                    value: ProjectFilter.active,
                    selected: _filter,
                    onChanged: (f) => setState(() => _filter = f)),
                const SizedBox(width: 8),
                _FilterBtn(
                    label: 'Chờ thanh toán',
                    count: widget.projects.where((p) => p.remaining > 0).length,
                    value: ProjectFilter.waitingPayment,
                    selected: _filter,
                    onChanged: (f) => setState(() => _filter = f)),
                const SizedBox(width: 8),
                _FilterBtn(
                    label: 'Rủi ro cao',
                    count:
                        widget.projects.where((p) => p.riskScore >= 55).length,
                    value: ProjectFilter.highRisk,
                    selected: _filter,
                    onChanged: (f) => setState(() => _filter = f)),
                const SizedBox(width: 8),
                _FilterBtn(
                    label: 'Hoàn thành',
                    count: widget.projects
                        .where((p) => p.status == PaymentStatus.paid)
                        .length,
                    value: ProjectFilter.paid,
                    selected: _filter,
                    onChanged: (f) => setState(() => _filter = f)),
              ],
            ),
          ),
          const SizedBox(height: 14),

          if (filtered.isEmpty)
            const EmptyState(
              icon: Icons.search_off_rounded,
              title: 'Không tìm thấy',
              message: 'Đổi bộ lọc hoặc tạo dự án mới.',
            )
          else
            ...filtered.map(
              (p) => KeyedSubtree(
                key: _projectKeys.putIfAbsent(p.id, GlobalKey.new),
                child: ProjectDetailPanel(
                  key: ValueKey(
                    'project-${p.id}-${widget.focusedProjectId == p.id}',
                  ),
                  project: p,
                  initiallyExpanded: widget.focusedProjectId == p.id,
                  onEdit: () => _openEdit(p),
                  onDelete: () => _confirmDelete(p),
                  onPayFull: () => widget.onPayFull(p),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Filter button ─────────────────────────────────────────────────────────────

class _FilterBtn extends StatelessWidget {
  const _FilterBtn({
    required this.label,
    required this.count,
    required this.value,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final int count;
  final ProjectFilter value;
  final ProjectFilter selected;
  final ValueChanged<ProjectFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : Colors.white,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: isSelected ? cs.primary : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isSelected ? Colors.white : Colors.black54,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : Colors.black45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Project Detail Panel ──────────────────────────────────────────────────────

class ProjectDetailPanel extends StatefulWidget {
  const ProjectDetailPanel({
    super.key,
    required this.project,
    this.initiallyExpanded = false,
    required this.onEdit,
    required this.onDelete,
    required this.onPayFull,
  });

  final ProjectFinance project;
  final bool initiallyExpanded;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPayFull;

  @override
  State<ProjectDetailPanel> createState() => _ProjectDetailPanelState();
}

class _ProjectDetailPanelState extends State<ProjectDetailPanel> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.project;
    final scoreColor = riskScoreColor(p.riskScore);
    final paymentColor = p.progressPaymentGap > 0
        ? const Color(0xFFEF4444)
        : const Color(0xFF10B981);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: cardDecoration(
        borderColor: p.riskScore >= 55 ? const Color(0xFFFECACA) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(categoryIcon(p.category),
                      size: 18, color: scoreColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        p.client,
                        style: const TextStyle(
                            color: Colors.black45, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.done_all_rounded, size: 18),
                  onPressed: p.isCompletedAndPaid ? null : widget.onPayFull,
                  tooltip: 'Thanh toán toàn bộ',
                  color: const Color(0xFF10B981),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: widget.onEdit,
                  tooltip: 'Sửa',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: widget.onDelete,
                  tooltip: 'Xóa',
                  color: const Color(0xFFEF4444),
                ),
              ],
            ),
          ),

          // ── Progress bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RatioBar(value: p.progress, color: scoreColor),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '${(p.progress * 100).round()}% hoàn thành',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black45),
                    ),
                    const Spacer(),
                    StatusChip(status: p.status),
                    const SizedBox(width: 6),
                    RiskScoreBadge(score: p.riskScore),
                  ],
                ),
                const SizedBox(height: 10),
                _RatioBar(value: p.paymentProgress, color: paymentColor),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '${(p.paymentProgress * 100).round()}% đã thu',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black45),
                    ),
                    const Spacer(),
                    Chip(
                      avatar: Icon(
                        p.workMode == ProjectWorkMode.team
                            ? Icons.groups_outlined
                            : Icons.person_outline_rounded,
                        size: 14,
                      ),
                      label: Text(
                        p.workMode == ProjectWorkMode.team
                            ? '${p.teamMembers.length} thành viên'
                            : 'Cá nhân',
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Stats row ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: MiniStat(
                    label: 'Giá trị',
                    value: formatMoney(p.totalValue),
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
                    label: 'Còn lại',
                    value: formatMoney(p.remaining),
                    valueColor:
                        p.remaining > 0 ? const Color(0xFFF59E0B) : null,
                  ),
                ),
                Expanded(
                  child: MiniStat(
                    label: 'Hạn',
                    value: p.dueDate,
                    valueColor: p.status == PaymentStatus.overdue
                        ? const Color(0xFFEF4444)
                        : null,
                  ),
                ),
              ],
            ),
          ),

          if (p.workMode == ProjectWorkMode.team)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6FC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Nhóm ${p.teamSharePercent.toStringAsFixed(0)}% · ${formatMoney(p.teamShareTotal)}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        'Phần của tôi: ${formatMoney(p.ownerContractShare)}',
                        style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: p.teamMembers
                        .map(
                          (member) => Chip(
                            avatar: Icon(
                              p.memberPayable(member) <= 0
                                  ? Icons.check_circle_rounded
                                  : Icons.schedule_rounded,
                              color: p.memberPayable(member) <= 0
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF59E0B),
                              size: 16,
                            ),
                            label: Text(
                              '${member.name} · ${member.sharePercent.toStringAsFixed(0)}% · chờ ${formatMoney(p.memberPayable(member))}',
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),

          // ── Expand button ──
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFB),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _expanded ? 'Ẩn chi tiết' : 'Xem chi tiết rủi ro',
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 16,
                    color: Colors.black38,
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded risk detail ──
          if (_expanded) _RiskDetailPanel(project: p),
        ],
      ),
    );
  }
}

// ── Risk Detail Panel ─────────────────────────────────────────────────────────

class _RatioBar extends StatelessWidget {
  const _RatioBar({
    required this.value,
    required this.color,
  });

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1).toDouble(),
        minHeight: 8,
        backgroundColor: const Color(0xFFE5E7EB),
        color: color,
      ),
    );
  }
}

class _RiskDetailPanel extends StatelessWidget {
  const _RiskDetailPanel({required this.project});
  final ProjectFinance project;

  @override
  Widget build(BuildContext context) {
    final p = project;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Phân tích rủi ro',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
              const Spacer(),
              _RiskGauge(score: p.riskScore),
            ],
          ),
          const SizedBox(height: 12),

          // Risk factors
          _RiskFactorRow(
            label: 'Hợp đồng ký kết',
            ok: p.contractSigned,
            detail: p.contractSigned ? 'Đã ký' : 'Chưa ký — rủi ro cao',
          ),
          _RiskFactorRow(
            label: 'Tiền cọc',
            ok: p.hasDeposit,
            detail: p.hasDeposit
                ? 'Đã nhận ${formatMoney(p.depositReceived)}'
                : 'Chưa nhận cọc',
          ),
          _RiskFactorRow(
            label: 'Tiền theo tiến độ',
            ok: p.progressPaymentGap <= 0.05,
            detail: p.progressPaymentGap > 0.05
                ? 'Tiến độ đang vượt tiền đã thu'
                : 'Tiền đã thu theo kịp tiến độ',
          ),
          _RiskFactorRow(
            label: 'Thay đổi phạm vi',
            ok: p.scopeChangeCount == 0,
            detail: p.scopeChangeCount == 0
                ? 'Không thay đổi'
                : '${p.scopeChangeCount} lần thay đổi',
          ),
          _RiskFactorRow(
            label: 'Đánh giá khách hàng',
            ok: p.clientRating >= 4,
            detail: '${p.clientRating}/5 sao',
            trailing: StarRating(rating: p.clientRating),
          ),
          if (p.overdueDays > 0)
            _RiskFactorRow(
              label: 'Quá hạn',
              ok: false,
              detail: 'Quá hạn ${p.overdueDays} ngày',
            ),

          if (p.tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: p.tags
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],

          if (p.notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes_rounded,
                      size: 14, color: Colors.black38),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      p.notes,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RiskGauge extends StatelessWidget {
  const _RiskGauge({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    final color = riskScoreColor(score);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            'Điểm $score/100',
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

class _RiskFactorRow extends StatelessWidget {
  const _RiskFactorRow({
    required this.label,
    required this.ok,
    required this.detail,
    this.trailing,
  });

  final String label;
  final bool ok;
  final String detail;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 16,
            color: ok ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const Spacer(),
          if (trailing != null) ...[
            trailing!,
          ] else
            Text(
              detail,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: ok ? Colors.black54 : const Color(0xFFEF4444),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Project Editor Dialog ─────────────────────────────────────────────────────

class ProjectEditorDialog extends StatefulWidget {
  const ProjectEditorDialog({
    super.key,
    this.project,
    this.clients = const [],
  });

  final ProjectFinance? project;
  final List<String> clients;

  @override
  State<ProjectEditorDialog> createState() => _ProjectEditorDialogState();
}

class _ProjectEditorDialogState extends State<ProjectEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _client;
  late final TextEditingController _totalValue;
  late final TextEditingController _paidAmount;
  late final TextEditingController _dueDate;
  late final TextEditingController _deliveryDate;
  late final TextEditingController _startDate;
  late final TextEditingController _notes;
  late double _progress;
  late ProjectCategory _category;
  late int _clientRating;
  late bool _contractSigned;
  late bool _hasDeposit;
  late int _scopeChanges;
  late int _overdueDays;
  late final List<String> _existingClients;
  String? _selectedClient;
  late bool _isNewClient;
  late ProjectWorkMode _workMode;
  final List<_TeamMemberDraft> _teamMembers = [];

  bool get _isEditing => widget.project != null;

  @override
  void initState() {
    super.initState();
    final p = widget.project;
    _existingClients = widget.clients
        .map((client) => client.trim())
        .where((client) => client.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    _name = TextEditingController(text: p?.name ?? '');
    _client = TextEditingController(text: p?.client ?? '');
    _selectedClient = _existingClients.contains(p?.client) ? p?.client : null;
    _isNewClient = _existingClients.isEmpty ||
        (p != null && !_existingClients.contains(p.client));
    if (!_isNewClient && _selectedClient != null) {
      _client.text = _selectedClient!;
    }
    _totalValue = TextEditingController(
        text: p == null ? '' : p.totalValue.toStringAsFixed(0));
    _paidAmount = TextEditingController(
        text: p == null ? '0' : p.paidAmount.toStringAsFixed(0));
    _dueDate = TextEditingController(text: p?.dueDate ?? '');
    _deliveryDate = TextEditingController(text: p?.deliveryDate ?? '');
    _startDate = TextEditingController(text: p?.startDate ?? '');
    _notes = TextEditingController(text: p?.notes ?? '');
    _progress = p?.progress ?? 0;
    _category = p?.category ?? ProjectCategory.other;
    _clientRating = p?.clientRating ?? 3;
    _contractSigned = p?.contractSigned ?? false;
    _hasDeposit = p?.hasDeposit ?? false;
    _scopeChanges = p?.scopeChangeCount ?? 0;
    _overdueDays = p?.overdueDays ?? 0;
    _workMode = p?.workMode ?? ProjectWorkMode.solo;
    _teamMembers.addAll(
      (p?.teamMembers ?? const []).map(_TeamMemberDraft.fromMember),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _client.dispose();
    _totalValue.dispose();
    _paidAmount.dispose();
    _dueDate.dispose();
    _deliveryDate.dispose();
    _startDate.dispose();
    _notes.dispose();
    for (final member in _teamMembers) {
      member.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_workMode == ProjectWorkMode.team && _teamMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dự án nhóm cần có ít nhất một thành viên.'),
        ),
      );
      return;
    }
    final total = parseMoney(_totalValue.text);
    final paid = parseMoney(_paidAmount.text).clamp(0, total).toDouble();
    final members = _workMode == ProjectWorkMode.team
        ? _teamMembers.map((member) => member.toMember()).toList()
        : const <TeamMember>[];
    final teamSharePercent = members.fold<double>(
      0,
      (sum, member) => sum + member.sharePercent,
    );
    if (teamSharePercent > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tổng tỷ lệ chia cho nhóm không được vượt 100%.'),
        ),
      );
      return;
    }
    final ownerNetReceived = paid * (1 - teamSharePercent / 100);
    final initialPayments = widget.project?.clientPayments ??
        (paid > 0
            ? [
                ClientPayment(
                  id: 'payment-${DateTime.now().microsecondsSinceEpoch}',
                  amount: paid,
                  receivedAt: DateTime.now(),
                  kind: ClientPaymentKind.deposit,
                ),
              ]
            : const <ClientPayment>[]);
    final project = ProjectFinance(
      id: widget.project?.id ??
          'project-${DateTime.now().microsecondsSinceEpoch}',
      name: _name.text.trim(),
      client: _client.text.trim(),
      totalValue: total,
      depositReceived: widget.project?.depositReceived ?? paid,
      paidAmount: paid,
      reserveAmount: _isEditing
          ? (widget.project?.reserveAmount ?? ownerNetReceived * 0.2)
          : ownerNetReceived * 0.2,
      dueDate: _dueDate.text.trim(),
      deliveryDate: _deliveryDate.text.trim(),
      startDate: _startDate.text.trim(),
      progress: _progress,
      risk: ProjectRisk.medium,
      status: PaymentStatus.partlyPaid,
      notes: _notes.text.trim(),
      category: _category,
      clientRating: _clientRating,
      contractSigned: _contractSigned,
      hasDeposit: _hasDeposit,
      scopeChangeCount: _scopeChanges,
      overdueDays: _overdueDays,
      workMode: _workMode,
      teamMembers: members,
      clientPayments: initialPayments,
      teamPayouts: widget.project?.teamPayouts ?? const [],
    );
    Navigator.pop(context, project);
  }

  String? _required(String? v) =>
      (v ?? '').trim().isEmpty ? 'Không được bỏ trống.' : null;

  String? _moneyValidator(String? v) =>
      parseMoney(v ?? '') <= 0 ? 'Nhập số tiền hợp lệ.' : null;

  String? _requiredDate(String? value) {
    final text = value?.trim() ?? '';
    final match = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(text);
    if (match == null) return 'Nhập đúng định dạng dd/MM/yyyy.';
    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final year = int.tryParse(match.group(3)!);
    if (day == null || month == null || year == null) {
      return 'Ngày không hợp lệ.';
    }
    final date = DateTime(year, month, day);
    if (date.day != day || date.month != month || date.year != year) {
      return 'Ngày không hợp lệ.';
    }
    return null;
  }

  String? _optionalDate(String? value) {
    return (value ?? '').trim().isEmpty ? null : _requiredDate(value);
  }

  void _selectExistingClient(String? client) {
    if (client == null) return;
    setState(() {
      _selectedClient = client;
      _isNewClient = false;
      _client.text = client;
    });
  }

  void _createNewClient() {
    setState(() {
      _isNewClient = true;
      _client.clear();
    });
  }

  void _addTeamMember() {
    setState(() => _teamMembers.add(_TeamMemberDraft.empty()));
  }

  void _removeTeamMember(int index) {
    final member = _teamMembers.removeAt(index);
    member.dispose();
    setState(() {});
  }

  double get _teamSharePercent => _teamMembers.fold<double>(
        0,
        (sum, member) => sum + (double.tryParse(member.sharePercent.text) ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 760),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  Text(
                    _isEditing ? 'Sửa dự án' : 'Dự án mới',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Thông tin cơ bản ──
                      const _SectionLabel(label: 'Thông tin cơ bản'),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _name,
                        validator: _required,
                        decoration: const InputDecoration(
                          labelText: 'Tên dự án *',
                          prefixIcon: Icon(Icons.folder_copy_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _ClientPicker(
                              clients: _existingClients,
                              selectedClient: _selectedClient,
                              isNewClient: _isNewClient,
                              controller: _client,
                              validator: _required,
                              onSelectClient: _selectExistingClient,
                              onCreateNew: _createNewClient,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<ProjectCategory>(
                              initialValue: _category,
                              decoration: const InputDecoration(
                                labelText: 'Loại',
                                prefixIcon: Icon(Icons.category_outlined),
                              ),
                              items: ProjectCategory.values
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(categoryText(c)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _category = v ?? _category),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      const _SectionLabel(label: 'Cách thực hiện'),
                      const SizedBox(height: 10),
                      SegmentedButton<ProjectWorkMode>(
                        segments: const [
                          ButtonSegment(
                            value: ProjectWorkMode.solo,
                            icon: Icon(Icons.person_outline_rounded),
                            label: Text('Làm một mình'),
                          ),
                          ButtonSegment(
                            value: ProjectWorkMode.team,
                            icon: Icon(Icons.groups_outlined),
                            label: Text('Làm theo nhóm'),
                          ),
                        ],
                        selected: {_workMode},
                        onSelectionChanged: (value) {
                          setState(() {
                            _workMode = value.first;
                            if (_workMode == ProjectWorkMode.team &&
                                _teamMembers.isEmpty) {
                              _teamMembers.add(_TeamMemberDraft.empty());
                            }
                          });
                        },
                      ),
                      if (_workMode == ProjectWorkMode.team) ...[
                        const SizedBox(height: 12),
                        ...List.generate(
                          _teamMembers.length,
                          (index) => _TeamMemberEditor(
                            key: ValueKey(_teamMembers[index].id),
                            index: index,
                            draft: _teamMembers[index],
                            onChanged: () => setState(() {}),
                            onRemove: () => _removeTeamMember(index),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _addTeamMember,
                          icon: const Icon(Icons.person_add_alt_1_rounded),
                          label: const Text('Thêm thành viên'),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F6FC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Chia cho nhóm: ${_teamSharePercent.toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                              Text(
                                'Phần của tôi: ${(100 - _teamSharePercent).clamp(0, 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  color: Color(0xFF2563EB),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // ── Tài chính ──
                      const _SectionLabel(label: 'Tài chính'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _totalValue,
                              keyboardType: TextInputType.number,
                              validator: _moneyValidator,
                              decoration: const InputDecoration(
                                labelText: 'Giá trị HĐ *',
                                prefixIcon:
                                    Icon(Icons.monetization_on_outlined),
                                suffixText: '₫',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _paidAmount,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Đã thu',
                                prefixIcon: Icon(Icons.payments_outlined),
                                suffixText: '₫',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _startDate,
                              validator: _optionalDate,
                              decoration: const InputDecoration(
                                labelText: 'Ngày bắt đầu',
                                prefixIcon: Icon(Icons.play_circle_outline),
                                hintText: 'dd/MM/yyyy',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _dueDate,
                              validator: _requiredDate,
                              decoration: const InputDecoration(
                                labelText: 'Hạn thanh toán *',
                                prefixIcon: Icon(Icons.event_outlined),
                                hintText: 'dd/MM/yyyy',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _deliveryDate,
                        validator: _optionalDate,
                        decoration: const InputDecoration(
                          labelText: 'Hạn bàn giao cho khách',
                          prefixIcon: Icon(Icons.assignment_turned_in_outlined),
                          hintText: 'dd/MM/yyyy',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Tiến độ ──
                      const _SectionLabel(label: 'Tiến độ'),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _progress,
                              onChanged: (v) => setState(() => _progress = v),
                              divisions: 20,
                              label: '${(_progress * 100).round()}%',
                            ),
                          ),
                          SizedBox(
                            width: 48,
                            child: Text(
                              '${(_progress * 100).round()}%',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Chỉ số rủi ro ──
                      const _SectionLabel(label: 'Chỉ số rủi ro'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _CheckTile(
                              label: 'Hợp đồng ký kết',
                              value: _contractSigned,
                              onChanged: (v) =>
                                  setState(() => _contractSigned = v),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _CheckTile(
                              label: 'Đã nhận cọc',
                              value: _hasDeposit,
                              onChanged: (v) => setState(() => _hasDeposit = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Thay đổi scope',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.black54)),
                                const SizedBox(height: 4),
                                _CounterField(
                                  value: _scopeChanges,
                                  min: 0,
                                  max: 10,
                                  onChanged: (v) =>
                                      setState(() => _scopeChanges = v),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Số ngày quá hạn',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.black54)),
                                const SizedBox(height: 4),
                                _CounterField(
                                  value: _overdueDays,
                                  min: 0,
                                  max: 90,
                                  onChanged: (v) =>
                                      setState(() => _overdueDays = v),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text('Đánh giá khách hàng',
                          style:
                              TextStyle(fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 6),
                      Row(
                        children: List.generate(
                          5,
                          (i) => GestureDetector(
                            onTap: () => setState(() => _clientRating = i + 1),
                            child: Icon(
                              i < _clientRating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: i < _clientRating
                                  ? const Color(0xFFFFB020)
                                  : Colors.black26,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Ghi chú ──
                      TextFormField(
                        controller: _notes,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Ghi chú',
                          prefixIcon: Icon(Icons.notes_outlined),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Footer buttons
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _submit,
                      icon: Icon(_isEditing ? Icons.save_rounded : Icons.add),
                      label: Text(_isEditing ? 'Lưu thay đổi' : 'Thêm dự án'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamMemberDraft {
  _TeamMemberDraft({
    required this.id,
    required String name,
    required String responsibility,
    required String specialty,
    required String sharePercent,
    required this.paidBeforeMigration,
  })  : name = TextEditingController(text: name),
        responsibility = TextEditingController(text: responsibility),
        specialty = TextEditingController(text: specialty),
        sharePercent = TextEditingController(text: sharePercent);

  factory _TeamMemberDraft.empty() => _TeamMemberDraft(
        id: 'member-${DateTime.now().microsecondsSinceEpoch}',
        name: '',
        responsibility: '',
        specialty: '',
        sharePercent: '',
        paidBeforeMigration: 0,
      );

  factory _TeamMemberDraft.fromMember(TeamMember member) => _TeamMemberDraft(
        id: member.id,
        name: member.name,
        responsibility: member.responsibility,
        specialty: member.specialty,
        sharePercent: member.sharePercent.toStringAsFixed(0),
        paidBeforeMigration: member.paidBeforeMigration,
      );

  final String id;
  final TextEditingController name;
  final TextEditingController responsibility;
  final TextEditingController specialty;
  final TextEditingController sharePercent;
  final double paidBeforeMigration;

  TeamMember toMember() => TeamMember(
        id: id,
        name: name.text.trim(),
        responsibility: responsibility.text.trim(),
        specialty: specialty.text.trim(),
        sharePercent: double.tryParse(sharePercent.text) ?? 0,
        paidBeforeMigration: paidBeforeMigration,
      );

  void dispose() {
    name.dispose();
    responsibility.dispose();
    specialty.dispose();
    sharePercent.dispose();
  }
}

class _TeamMemberEditor extends StatelessWidget {
  const _TeamMemberEditor({
    super.key,
    required this.index,
    required this.draft,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final _TeamMemberDraft draft;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  String? _required(String? value) =>
      (value ?? '').trim().isEmpty ? 'Không được bỏ trống.' : null;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Thành viên ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: 'Xóa thành viên',
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline_rounded),
                color: const Color(0xFFEF4444),
              ),
            ],
          ),
          TextFormField(
            controller: draft.name,
            validator: _required,
            decoration: const InputDecoration(
              labelText: 'Tên thành viên *',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: draft.responsibility,
            validator: _required,
            decoration: const InputDecoration(
              labelText: 'Phụ trách phần việc *',
              hintText: 'Ví dụ: Thiết kế giao diện, lập trình backend',
              prefixIcon: Icon(Icons.task_alt_rounded),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: draft.specialty,
                  validator: _required,
                  decoration: const InputDecoration(
                    labelText: 'Lĩnh vực / chuyên môn *',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: draft.sharePercent,
                  onChanged: (_) => onChanged(),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final percent = double.tryParse(value ?? '');
                    if (percent == null || percent <= 0 || percent > 100) {
                      return 'Nhập tỷ lệ từ 0 đến 100.';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Tỷ lệ được chia *',
                    prefixIcon: Icon(Icons.percent_rounded),
                    suffixText: '%',
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 17, color: Colors.black45),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Mỗi lần khách thanh toán, thành viên sẽ được hưởng đúng tỷ lệ này.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
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

class _ClientPicker extends StatelessWidget {
  const _ClientPicker({
    required this.clients,
    required this.selectedClient,
    required this.isNewClient,
    required this.controller,
    required this.validator,
    required this.onSelectClient,
    required this.onCreateNew,
  });

  final List<String> clients;
  final String? selectedClient;
  final bool isNewClient;
  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final ValueChanged<String?> onSelectClient;
  final VoidCallback onCreateNew;

  @override
  Widget build(BuildContext context) {
    if (clients.isEmpty) {
      return TextFormField(
        controller: controller,
        validator: validator,
        decoration: const InputDecoration(
          labelText: 'Khách hàng *',
          prefixIcon: Icon(Icons.business_outlined),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: isNewClient ? null : selectedClient,
          decoration: const InputDecoration(
            labelText: 'Khách hàng cũ',
            prefixIcon: Icon(Icons.business_outlined),
          ),
          hint: const Text('Chọn khách hàng'),
          items: clients
              .map(
                (client) => DropdownMenuItem(
                  value: client,
                  child: Text(client),
                ),
              )
              .toList(),
          validator: (_) => isNewClient ? null : validator(controller.text),
          onChanged: onSelectClient,
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onCreateNew,
          icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
          label: const Text('Tạo khách hàng mới'),
        ),
        if (isNewClient) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            validator: validator,
            decoration: const InputDecoration(
              labelText: 'Tên khách hàng mới *',
              prefixIcon: Icon(Icons.edit_outlined),
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
      ],
    );
  }
}

class _CheckTile extends StatelessWidget {
  const _CheckTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: value
              ? const Color(0xFF10B981).withValues(alpha: 0.08)
              : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: value
                ? const Color(0xFF10B981).withValues(alpha: 0.4)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Icon(
              value ? Icons.check_box_rounded : Icons.check_box_outline_blank,
              color: value ? const Color(0xFF10B981) : Colors.black26,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: value ? const Color(0xFF10B981) : Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CounterField extends StatelessWidget {
  const _CounterField({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 16),
            onPressed: value <= min ? null : () => onChanged(value - 1),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          Expanded(
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 16),
            onPressed: value >= max ? null : () => onChanged(value + 1),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }
}
