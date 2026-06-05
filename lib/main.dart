import 'package:flutter/material.dart';

void main() {
  runApp(const FreelanceFinanceApp());
}

class FreelanceFinanceApp extends StatelessWidget {
  const FreelanceFinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Freelance Finance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF256D85),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F7F2),
        fontFamily: 'Roboto',
      ),
      home: const FinanceHomePage(),
    );
  }
}

class FinanceHomePage extends StatefulWidget {
  const FinanceHomePage({super.key});

  @override
  State<FinanceHomePage> createState() => _FinanceHomePageState();
}

class _FinanceHomePageState extends State<FinanceHomePage> {
  int _selectedIndex = 0;

  final List<ProjectFinance> projects = const [
    ProjectFinance(
      name: 'Brand Identity - Cafe Lumina',
      client: 'Lumina Studio',
      totalValue: 46000000,
      depositReceived: 18000000,
      paidAmount: 18000000,
      reserveAmount: 3600000,
      dueDate: '12/06',
      progress: 0.68,
      risk: ProjectRisk.medium,
      status: PaymentStatus.depositReceived,
      notes: 'Dang doi duyet guideline va file in an.',
    ),
    ProjectFinance(
      name: 'Mobile UI Kit',
      client: 'Nexa Labs',
      totalValue: 32000000,
      depositReceived: 12000000,
      paidAmount: 26000000,
      reserveAmount: 5200000,
      dueDate: '18/06',
      progress: 0.86,
      risk: ProjectRisk.low,
      status: PaymentStatus.partlyPaid,
      notes: 'Con 2 man hinh final va ban giao component.',
    ),
    ProjectFinance(
      name: 'Landing Page Campaign',
      client: 'Bright Ads',
      totalValue: 18500000,
      depositReceived: 0,
      paidAmount: 0,
      reserveAmount: 0,
      dueDate: 'Qua han 3 ngay',
      progress: 0.42,
      risk: ProjectRisk.high,
      status: PaymentStatus.overdue,
      notes: 'Chua nhan coc, scope thay doi 2 lan.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardView(projects: projects),
      ProjectsView(projects: projects),
      PaymentsView(projects: projects),
      ReserveView(projects: projects),
      StatsView(projects: projects),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Tong quan',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_copy_outlined),
            selectedIcon: Icon(Icons.folder_copy),
            label: 'Du an',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments),
            label: 'Thu no',
          ),
          NavigationDestination(
            icon: Icon(Icons.savings_outlined),
            selectedIcon: Icon(Icons.savings),
            label: 'Du phong',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Thong ke',
          ),
        ],
      ),
    );
  }
}

class DashboardView extends StatelessWidget {
  const DashboardView({super.key, required this.projects});

  final List<ProjectFinance> projects;

  @override
  Widget build(BuildContext context) {
    final totalIncome = projects.fold<double>(
      0,
      (sum, p) => sum + p.paidAmount,
    );
    final totalDebt = projects.fold<double>(0, (sum, p) => sum + p.remaining);
    final totalReserve = projects.fold<double>(
      0,
      (sum, p) => sum + p.reserveAmount,
    );
    final highRisk = projects.where((p) => p.risk == ProjectRisk.high).length;

    return AppPage(
      title: 'Tai chinh Freelancer',
      subtitle: 'Kiem soat dong tien theo tung du an',
      action: IconButton(
        tooltip: 'Them du an',
        onPressed: () {},
        icon: const Icon(Icons.add_circle_outline),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _HeroSummary(
            totalIncome: totalIncome,
            totalDebt: totalDebt,
            totalReserve: totalReserve,
          ),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: MediaQuery.sizeOf(context).width > 720 ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              MetricCard(
                label: 'Da thu',
                value: formatMoney(totalIncome),
                icon: Icons.trending_up,
                color: const Color(0xFF1B7F5A),
              ),
              MetricCard(
                label: 'Cong no',
                value: formatMoney(totalDebt),
                icon: Icons.receipt_long,
                color: const Color(0xFFB95D2A),
              ),
              MetricCard(
                label: 'Du phong',
                value: formatMoney(totalReserve),
                icon: Icons.shield_outlined,
                color: const Color(0xFF315C9A),
              ),
              MetricCard(
                label: 'Rui ro cao',
                value: '$highRisk du an',
                icon: Icons.warning_amber_rounded,
                color: const Color(0xFFB3261E),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SectionHeader(
            title: 'Can xu ly som',
            trailing: TextButton(
              onPressed: () {},
              child: const Text('Xem het'),
            ),
          ),
          ...projects.map((project) => ProjectCard(project: project)),
        ],
      ),
    );
  }
}

class ProjectsView extends StatelessWidget {
  const ProjectsView({super.key, required this.projects});

  final List<ProjectFinance> projects;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Du an',
      subtitle: 'Thu chi va tien do theo hop dong',
      action: FilledButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Moi'),
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

class PaymentsView extends StatelessWidget {
  const PaymentsView({super.key, required this.projects});

  final List<ProjectFinance> projects;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Thu no',
      subtitle: 'Theo doi coc, so con lai va han thanh toan',
      action: IconButton(
        tooltip: 'Nhac thanh toan',
        onPressed: () {},
        icon: const Icon(Icons.notifications_active_outlined),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          ReminderBanner(
            project: projects.firstWhere(
              (p) => p.status == PaymentStatus.overdue,
            ),
          ),
          const SizedBox(height: 16),
          ...projects.map((project) => PaymentTimeline(project: project)),
        ],
      ),
    );
  }
}

class ReserveView extends StatelessWidget {
  const ReserveView({super.key, required this.projects});

  final List<ProjectFinance> projects;

  @override
  Widget build(BuildContext context) {
    final reserve = projects.fold<double>(0, (sum, p) => sum + p.reserveAmount);
    final income = projects.fold<double>(0, (sum, p) => sum + p.paidAmount);
    final rate = income == 0 ? 0.0 : reserve / income;

    return AppPage(
      title: 'Quy du phong',
      subtitle: 'Tu dong trich thu nhap vao tiet kiem ca nhan',
      action: IconButton(
        tooltip: 'Cai dat ty le',
        onPressed: () {},
        icon: const Icon(Icons.tune),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          ReserveGoalCard(reserve: reserve, rate: rate),
          const SizedBox(height: 18),
          const SectionHeader(title: 'Trich lap theo du an'),
          ...projects.map((project) => ReserveRow(project: project)),
        ],
      ),
    );
  }
}

class StatsView extends StatelessWidget {
  const StatsView({super.key, required this.projects});

  final List<ProjectFinance> projects;

  @override
  Widget build(BuildContext context) {
    final paid = projects.fold<double>(0, (sum, p) => sum + p.paidAmount);
    final debt = projects.fold<double>(0, (sum, p) => sum + p.remaining);
    final reserve = projects.fold<double>(0, (sum, p) => sum + p.reserveAmount);

    return AppPage(
      title: 'Thong ke',
      subtitle: 'Tong hop thu nhap, cong no va tiet kiem',
      action: SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'q2', label: Text('Q2')),
          ButtonSegment(value: '2026', label: Text('2026')),
        ],
        selected: const {'q2'},
        onSelectionChanged: (_) {},
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          StatsChart(paid: paid, debt: debt, reserve: reserve),
          const SizedBox(height: 18),
          RiskBreakdown(projects: projects),
          const SizedBox(height: 18),
          const SectionHeader(title: 'Goc nhin nhanh'),
          InsightTile(
            icon: Icons.calendar_month_outlined,
            title: 'Dong tien tap trung vao giua thang',
            value: '2 khoan thu den han trong 14 ngay toi',
          ),
          InsightTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Ty le du phong hien tai',
            value: 'Dang dat muc tot so voi muc tieu 20%',
          ),
        ],
      ),
    );
  }
}

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              if (action != null) action!,
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _HeroSummary extends StatelessWidget {
  const _HeroSummary({
    required this.totalIncome,
    required this.totalDebt,
    required this.totalReserve,
  });

  final double totalIncome;
  final double totalDebt;
  final double totalReserve;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF173B45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wallet_outlined, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                'Suc khoe dong tien',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            formatMoney(totalIncome - totalDebt),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Dong tien kha dung sau khi tru cong no can thu',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 18),
          LinearProgressIndicator(
            value: totalReserve / (totalIncome == 0 ? 1 : totalIncome),
            minHeight: 8,
            borderRadius: BorderRadius.circular(99),
            backgroundColor: Colors.white24,
            color: const Color(0xFF9AD0C2),
          ),
        ],
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProjectCard extends StatelessWidget {
  const ProjectCard({super.key, required this.project});

  final ProjectFinance project;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              RiskChip(risk: project.risk),
            ],
          ),
          const SizedBox(height: 6),
          Text(project.client, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Da thu',
                  value: formatMoney(project.paidAmount),
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Con lai',
                  value: formatMoney(project.remaining),
                ),
              ),
              Expanded(
                child: _MiniStat(label: 'Han', value: project.dueDate),
              ),
            ],
          ),
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
                tooltip: 'Sua du an',
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
              Text('${(project.progress * 100).round()}% hoan thanh'),
              const Spacer(),
              RiskChip(risk: project.risk),
            ],
          ),
          const Divider(height: 28),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Gia tri',
                  value: formatMoney(project.totalValue),
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Coc',
                  value: formatMoney(project.depositReceived),
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Con lai',
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
            backgroundColor: statusColor(
              project.status,
            ).withValues(alpha: 0.14),
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
                      child: _MiniStat(
                        label: 'Da nhan',
                        value: formatMoney(project.paidAmount),
                      ),
                    ),
                    Expanded(
                      child: _MiniStat(
                        label: 'Can thu',
                        value: formatMoney(project.remaining),
                      ),
                    ),
                    Expanded(
                      child: _MiniStat(label: 'Han', value: project.dueDate),
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
              '${project.client} dang qua han. Can nhac thanh toan ${formatMoney(project.remaining)}.',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: 'Gui nhac',
            onPressed: () {},
            icon: const Icon(Icons.send_outlined),
          ),
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
          Row(
            children: [
              const Icon(Icons.savings_outlined, color: Color(0xFF315C9A)),
              const SizedBox(width: 10),
              Text(
                'Muc tieu du phong',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
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
          Text('Da trich ${(rate * 100).round()}% tren tong thu nhap da nhan'),
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
                  'Tu dong trich 20% khi ghi nhan thu nhap',
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

class StatsChart extends StatelessWidget {
  const StatsChart({
    super.key,
    required this.paid,
    required this.debt,
    required this.reserve,
  });

  final double paid;
  final double debt;
  final double reserve;

  @override
  Widget build(BuildContext context) {
    final maxValue = [paid, debt, reserve].reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Giai doan hien tai',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          ChartBar(
            label: 'Thu nhap',
            value: paid,
            maxValue: maxValue,
            color: const Color(0xFF1B7F5A),
          ),
          ChartBar(
            label: 'Cong no',
            value: debt,
            maxValue: maxValue,
            color: const Color(0xFFB95D2A),
          ),
          ChartBar(
            label: 'Tiet kiem',
            value: reserve,
            maxValue: maxValue,
            color: const Color(0xFF315C9A),
          ),
        ],
      ),
    );
  }
}

class ChartBar extends StatelessWidget {
  const ChartBar({
    super.key,
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  final String label;
  final double value;
  final double maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                formatMoney(value),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: maxValue == 0 ? 0 : value / maxValue,
              minHeight: 12,
              color: color,
              backgroundColor: const Color(0xFFE3E5DD),
            ),
          ),
        ],
      ),
    );
  }
}

class RiskBreakdown extends StatelessWidget {
  const RiskBreakdown({super.key, required this.projects});

  final List<ProjectFinance> projects;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chi so rui ro du an',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: RiskCount(
                  label: 'Thap',
                  count: countRisk(ProjectRisk.low),
                  color: riskColor(ProjectRisk.low),
                ),
              ),
              Expanded(
                child: RiskCount(
                  label: 'Vua',
                  count: countRisk(ProjectRisk.medium),
                  color: riskColor(ProjectRisk.medium),
                ),
              ),
              Expanded(
                child: RiskCount(
                  label: 'Cao',
                  count: countRisk(ProjectRisk.high),
                  color: riskColor(ProjectRisk.high),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int countRisk(ProjectRisk risk) =>
      projects.where((project) => project.risk == risk).length;
}

class RiskCount extends StatelessWidget {
  const RiskCount({
    super.key,
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: color.withValues(alpha: 0.14),
          child: Text(
            '$count',
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class InsightTile extends StatelessWidget {
  const InsightTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(value, style: const TextStyle(color: Colors.black54)),
              ],
            ),
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
          label: const Text('Tat ca'),
          selected: true,
          onSelected: (_) {},
        ),
        FilterChip(
          label: const Text('Dang lam'),
          selected: false,
          onSelected: (_) {},
        ),
        FilterChip(
          label: const Text('Cho thanh toan'),
          selected: false,
          onSelected: (_) {},
        ),
        FilterChip(
          label: const Text('Rui ro cao'),
          selected: false,
          onSelected: (_) {},
        ),
      ],
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class RiskChip extends StatelessWidget {
  const RiskChip({super.key, required this.risk});

  final ProjectRisk risk;

  @override
  Widget build(BuildContext context) {
    final color = riskColor(risk);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        riskText(risk),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

BoxDecoration cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: const Color(0xFFE1E4DC)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 14,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

String formatMoney(double value) {
  final million = value / 1000000;
  if (million == million.roundToDouble()) {
    return '${million.toStringAsFixed(0)}tr';
  }
  return '${million.toStringAsFixed(1)}tr';
}

Color riskColor(ProjectRisk risk) {
  return switch (risk) {
    ProjectRisk.low => const Color(0xFF1B7F5A),
    ProjectRisk.medium => const Color(0xFFB95D2A),
    ProjectRisk.high => const Color(0xFFB3261E),
  };
}

String riskText(ProjectRisk risk) {
  return switch (risk) {
    ProjectRisk.low => 'Rui ro thap',
    ProjectRisk.medium => 'Rui ro vua',
    ProjectRisk.high => 'Rui ro cao',
  };
}

Color statusColor(PaymentStatus status) {
  return switch (status) {
    PaymentStatus.depositReceived => const Color(0xFF315C9A),
    PaymentStatus.partlyPaid => const Color(0xFF1B7F5A),
    PaymentStatus.overdue => const Color(0xFFB3261E),
    PaymentStatus.paid => const Color(0xFF1B7F5A),
  };
}

IconData statusIcon(PaymentStatus status) {
  return switch (status) {
    PaymentStatus.depositReceived => Icons.account_balance_wallet_outlined,
    PaymentStatus.partlyPaid => Icons.payments_outlined,
    PaymentStatus.overdue => Icons.priority_high_rounded,
    PaymentStatus.paid => Icons.check_circle_outline,
  };
}

String paymentStatusText(PaymentStatus status) {
  return switch (status) {
    PaymentStatus.depositReceived => 'Da nhan coc',
    PaymentStatus.partlyPaid => 'Da thanh toan mot phan',
    PaymentStatus.overdue => 'Qua han thanh toan',
    PaymentStatus.paid => 'Da thanh toan',
  };
}

class ProjectFinance {
  const ProjectFinance({
    required this.name,
    required this.client,
    required this.totalValue,
    required this.depositReceived,
    required this.paidAmount,
    required this.reserveAmount,
    required this.dueDate,
    required this.progress,
    required this.risk,
    required this.status,
    required this.notes,
  });

  final String name;
  final String client;
  final double totalValue;
  final double depositReceived;
  final double paidAmount;
  final double reserveAmount;
  final String dueDate;
  final double progress;
  final ProjectRisk risk;
  final PaymentStatus status;
  final String notes;

  double get remaining => totalValue - paidAmount;
}

enum ProjectRisk { low, medium, high }

enum PaymentStatus { depositReceived, partlyPaid, overdue, paid }
