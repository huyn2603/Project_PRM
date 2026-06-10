import 'package:flutter/material.dart';
import '../models/project_finance.dart';
import '../utils/helpers.dart';
import '../widgets/shared_widgets.dart';

class ProjectsView extends StatelessWidget {
  const ProjectsView({super.key, required this.projects});

  final List<ProjectFinance> projects;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Dự án',
      subtitle: 'Thu chi và tiến độ theo hợp đồng',
      action: FilledButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Mới'),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const FilterChips(),
          const SizedBox(height: 16),
          ...projects.map((project) => ProjectDetailPanel(project: project)),
        ],
      ),
    );
  }
}

class ProjectDetailPanel extends StatelessWidget {
  const ProjectDetailPanel({super.key, required this.project});

  final ProjectFinance project;

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
                onPressed: () {},
                icon: const Icon(Icons.edit_outlined),
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
                  label: 'Cọc',
                  value: formatMoney(project.depositReceived),
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
  const FilterChips({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
          label: const Text('Tất cả'),
          selected: true,
          onSelected: (_) {},
        ),
        FilterChip(
          label: const Text('Đang làm'),
          selected: false,
          onSelected: (_) {},
        ),
        FilterChip(
          label: const Text('Chờ thanh toán'),
          selected: false,
          onSelected: (_) {},
        ),
        FilterChip(
          label: const Text('Rủi ro cao'),
          selected: false,
          onSelected: (_) {},
        ),
      ],
    );
  }
}