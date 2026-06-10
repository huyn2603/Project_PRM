import 'package:flutter/material.dart';

import '../models/project_finance.dart';
import '../utils/helpers.dart';
import '../widgets/shared_widgets.dart';

enum ProjectFilter { all, active, waitingPayment, highRisk }

class ProjectsView extends StatefulWidget {
  const ProjectsView({
    super.key,
    required this.projects,
    required this.onAddProject,
    required this.onUpdateProject,
    required this.onDeleteProject,
  });

  final List<ProjectFinance> projects;
  final ValueChanged<ProjectFinance> onAddProject;
  final ValueChanged<ProjectFinance> onUpdateProject;
  final ValueChanged<ProjectFinance> onDeleteProject;

  @override
  State<ProjectsView> createState() => _ProjectsViewState();
}

class _ProjectsViewState extends State<ProjectsView> {
  ProjectFilter _filter = ProjectFilter.all;

  List<ProjectFinance> get _filteredProjects {
    return switch (_filter) {
      ProjectFilter.all => widget.projects,
      ProjectFilter.active => widget.projects
          .where((project) => project.progress < 1 && project.remaining > 0)
          .toList(),
      ProjectFilter.waitingPayment =>
        widget.projects.where((project) => project.remaining > 0).toList(),
      ProjectFilter.highRisk => widget.projects
          .where((project) => project.risk == ProjectRisk.high)
          .toList(),
    };
  }

  Future<void> _openCreateProject() async {
    final project = await showDialog<ProjectFinance>(
      context: context,
      builder: (context) => const ProjectEditorDialog(),
    );
    if (project != null) widget.onAddProject(project);
  }

  Future<void> _openEditProject(ProjectFinance project) async {
    final edited = await showDialog<ProjectFinance>(
      context: context,
      builder: (context) => ProjectEditorDialog(project: project),
    );
    if (edited != null) widget.onUpdateProject(edited);
  }

  Future<void> _confirmDelete(ProjectFinance project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa dự án?'),
        content: Text('Dự án "${project.name}" sẽ bị xóa khỏi danh sách.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onDeleteProject(project);
  }

  @override
  Widget build(BuildContext context) {
    final filteredProjects = _filteredProjects;

    return AppPage(
      title: 'Dự án',
      subtitle: 'Thêm, sửa, xóa và theo dõi tiến độ hợp đồng',
      action: FilledButton.icon(
        onPressed: _openCreateProject,
        icon: const Icon(Icons.add),
        label: const Text('Mới'),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          FilterChips(
            selected: _filter,
            onChanged: (filter) => setState(() => _filter = filter),
          ),
          const SizedBox(height: 16),
          if (filteredProjects.isEmpty)
            const EmptyState(
              icon: Icons.search_off,
              title: 'Không có dự án phù hợp',
              message: 'Đổi bộ lọc hoặc tạo dự án mới để tiếp tục.',
            )
          else
            ...filteredProjects.map(
              (project) => ProjectDetailPanel(
                project: project,
                onEdit: () => _openEditProject(project),
                onDelete: () => _confirmDelete(project),
              ),
            ),
        ],
      ),
    );
  }
}

class ProjectDetailPanel extends StatelessWidget {
  const ProjectDetailPanel({
    super.key,
    required this.project,
    required this.onEdit,
    required this.onDelete,
  });

  final ProjectFinance project;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  project.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Sửa dự án',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Xóa dự án',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          Text(project.notes, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: project.progress,
              minHeight: 10,
              backgroundColor: const Color(0xFFE3E5DD),
              color: riskColor(project.risk),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('${(project.progress * 100).round()}% hoàn thành'),
              const Spacer(),
              StatusChip(status: project.status),
              const SizedBox(width: 8),
              RiskChip(risk: project.risk),
            ],
          ),
          const Divider(height: 28),
          Row(
            children: [
              Expanded(
                child: MiniStat(
                  label: 'Giá trị',
                  value: formatMoney(project.totalValue),
                ),
              ),
              Expanded(
                child: MiniStat(
                  label: 'Đã thu',
                  value: formatMoney(project.paidAmount),
                ),
              ),
              Expanded(
                child: MiniStat(
                  label: 'Còn lại',
                  value: formatMoney(project.remaining),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FilterChips extends StatelessWidget {
  const FilterChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final ProjectFilter selected;
  final ValueChanged<ProjectFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _FilterChip(
          label: 'Tất cả',
          value: ProjectFilter.all,
          selected: selected,
          onChanged: onChanged,
        ),
        _FilterChip(
          label: 'Đang làm',
          value: ProjectFilter.active,
          selected: selected,
          onChanged: onChanged,
        ),
        _FilterChip(
          label: 'Chờ thanh toán',
          value: ProjectFilter.waitingPayment,
          selected: selected,
          onChanged: onChanged,
        ),
        _FilterChip(
          label: 'Rủi ro cao',
          value: ProjectFilter.highRisk,
          selected: selected,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final ProjectFilter value;
  final ProjectFilter selected;
  final ValueChanged<ProjectFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected == value,
      onSelected: (_) => onChanged(value),
    );
  }
}

class ProjectEditorDialog extends StatefulWidget {
  const ProjectEditorDialog({super.key, this.project});

  final ProjectFinance? project;

  @override
  State<ProjectEditorDialog> createState() => _ProjectEditorDialogState();
}

class _ProjectEditorDialogState extends State<ProjectEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _clientController;
  late final TextEditingController _totalValueController;
  late final TextEditingController _paidAmountController;
  late final TextEditingController _dueDateController;
  late final TextEditingController _notesController;
  late double _progress;
  late ProjectRisk _risk;

  bool get _isEditing => widget.project != null;

  @override
  void initState() {
    super.initState();
    final project = widget.project;
    _nameController = TextEditingController(text: project?.name ?? '');
    _clientController = TextEditingController(text: project?.client ?? '');
    _totalValueController = TextEditingController(
      text: project == null ? '' : project.totalValue.toStringAsFixed(0),
    );
    _paidAmountController = TextEditingController(
      text: project == null ? '0' : project.paidAmount.toStringAsFixed(0),
    );
    _dueDateController = TextEditingController(text: project?.dueDate ?? '');
    _notesController = TextEditingController(text: project?.notes ?? '');
    _progress = project?.progress ?? 0;
    _risk = project?.risk ?? ProjectRisk.medium;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _clientController.dispose();
    _totalValueController.dispose();
    _paidAmountController.dispose();
    _dueDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final totalValue = _parseMoney(_totalValueController.text);
    final paidAmount =
        _parseMoney(_paidAmountController.text).clamp(0, totalValue).toDouble();
    final project = ProjectFinance(
      id: widget.project?.id ??
          'project-${DateTime.now().microsecondsSinceEpoch}',
      name: _nameController.text.trim(),
      client: _clientController.text.trim(),
      totalValue: totalValue,
      depositReceived: widget.project?.depositReceived ?? paidAmount,
      paidAmount: paidAmount,
      reserveAmount: widget.project?.reserveAmount ?? paidAmount * 0.2,
      dueDate: _dueDateController.text.trim(),
      progress: _progress,
      risk: _risk,
      status: PaymentStatus.partlyPaid,
      notes: _notesController.text.trim(),
    );
    Navigator.pop(context, project);
  }

  double _parseMoney(String value) {
    final clean = value.replaceAll('.', '').replaceAll(',', '').trim();
    return double.tryParse(clean) ?? 0;
  }

  String? _required(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Không được bỏ trống.';
    return null;
  }

  String? _moneyValidator(String? value) {
    if (_parseMoney(value ?? '') <= 0) return 'Nhập số tiền hợp lệ.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Sửa dự án' : 'Thêm dự án'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  validator: _required,
                  decoration: const InputDecoration(
                    labelText: 'Tên dự án',
                    prefixIcon: Icon(Icons.folder_copy_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _clientController,
                  validator: _required,
                  decoration: const InputDecoration(
                    labelText: 'Khách hàng',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _totalValueController,
                  keyboardType: TextInputType.number,
                  validator: _moneyValidator,
                  decoration: const InputDecoration(
                    labelText: 'Giá trị hợp đồng',
                    prefixIcon: Icon(Icons.monetization_on_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _paidAmountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Đã thu',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _dueDateController,
                  validator: _required,
                  decoration: const InputDecoration(
                    labelText: 'Hạn thanh toán',
                    prefixIcon: Icon(Icons.event_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ProjectRisk>(
                  initialValue: _risk,
                  decoration: const InputDecoration(
                    labelText: 'Rủi ro',
                    prefixIcon: Icon(Icons.warning_amber_outlined),
                  ),
                  items: ProjectRisk.values
                      .map(
                        (risk) => DropdownMenuItem(
                          value: risk,
                          child: Text(riskText(risk)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _risk = value ?? ProjectRisk.medium),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Text('Tiến độ'),
                    Expanded(
                      child: Slider(
                        value: _progress,
                        onChanged: (value) => setState(() => _progress = value),
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: Text('${(_progress * 100).round()}%'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: Icon(_isEditing ? Icons.save_outlined : Icons.add),
          label: Text(_isEditing ? 'Lưu' : 'Thêm'),
        ),
      ],
    );
  }
}
