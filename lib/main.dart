import 'package:flutter/material.dart';

void main() {
  runApp(const FreelanceFinanceApp());
}

class FreelanceFinanceApp extends StatelessWidget {
  const FreelanceFinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tài chính Freelancer',
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
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isSignedIn = false;

  void _openDashboard() {
    setState(() => _isSignedIn = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isSignedIn) {
      return const FinanceHomePage();
    }

    return LoginPage(onLogin: _openDashboard);
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onLogin});

  final VoidCallback onLogin;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _showRegister = false;
  bool _rememberMe = true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 44,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Tài chính Freelancer',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Theo dõi dự án, công nợ và quỹ dự phòng cá nhân',
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    ),
                    const SizedBox(height: 22),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: false,
                          label: Text('Đăng nhập'),
                          icon: Icon(Icons.login),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text('Đăng ký'),
                          icon: Icon(Icons.person_add_alt_1_outlined),
                        ),
                      ],
                      selected: {_showRegister},
                      onSelectionChanged: (value) =>
                          setState(() => _showRegister = value.first),
                    ),
                    const SizedBox(height: 18),
                    if (_showRegister) ...[
                      const AuthTextField(
                        label: 'Họ và tên',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 12),
                    ],
                    const AuthTextField(
                      label: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    const AuthTextField(
                      label: 'Mật khẩu',
                      icon: Icons.lock_outline,
                      obscureText: true,
                    ),
                    if (_showRegister) ...[
                      const SizedBox(height: 12),
                      const AuthTextField(
                        label: 'Xác nhận mật khẩu',
                        icon: Icons.verified_user_outlined,
                        obscureText: true,
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        value: _rememberMe,
                        onChanged: (value) =>
                            setState(() => _rememberMe = value ?? true),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text('Ghi nhớ đăng nhập'),
                      ),
                    ],
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: widget.onLogin,
                      icon: Icon(
                        _showRegister ? Icons.person_add : Icons.login,
                      ),
                      label: Text(
                        _showRegister ? 'Tạo tài khoản' : 'Đăng nhập',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () =>
                          setState(() => _showRegister = !_showRegister),
                      child: Text(
                        _showRegister
                            ? 'Đã có tài khoản? Đăng nhập'
                            : 'Chưa có tài khoản? Đăng ký',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
  });

  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
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
      name: 'Bộ nhận diện - Cafe Lumina',
      client: 'Lumina Studio',
      totalValue: 46000000,
      depositReceived: 18000000,
      paidAmount: 18000000,
      reserveAmount: 3600000,
      dueDate: '12/06',
      progress: 0.68,
      risk: ProjectRisk.medium,
      status: PaymentStatus.depositReceived,
      notes: 'Đang đợi duyệt bộ hướng dẫn thương hiệu và file in ấn.',
    ),
    ProjectFinance(
      name: 'Bộ giao diện di động',
      client: 'Nexa Labs',
      totalValue: 32000000,
      depositReceived: 12000000,
      paidAmount: 26000000,
      reserveAmount: 5200000,
      dueDate: '18/06',
      progress: 0.86,
      risk: ProjectRisk.low,
      status: PaymentStatus.partlyPaid,
      notes: 'Còn 2 màn hình cuối và bàn giao thành phần giao diện.',
    ),
    ProjectFinance(
      name: 'Trang chiến dịch quảng cáo',
      client: 'Bright Ads',
      totalValue: 18500000,
      depositReceived: 0,
      paidAmount: 0,
      reserveAmount: 0,
      dueDate: 'Quá hạn 3 ngày',
      progress: 0.42,
      risk: ProjectRisk.high,
      status: PaymentStatus.overdue,
      notes: 'Chưa nhận cọc, phạm vi công việc thay đổi 2 lần.',
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
            label: 'Tổng quan',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_copy_outlined),
            selectedIcon: Icon(Icons.folder_copy),
            label: 'Dự án',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments),
            label: 'Thu nợ',
          ),
          NavigationDestination(
            icon: Icon(Icons.savings_outlined),
            selectedIcon: Icon(Icons.savings),
            label: 'Dự phòng',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Thống kê',
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
      title: 'Tài chính Freelancer',
      subtitle: 'Kiểm soát dòng tiền theo từng dự án',
      action: IconButton(
        tooltip: 'Thêm dự án',
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
                label: 'Đã thu',
                value: formatMoney(totalIncome),
                icon: Icons.trending_up,
                color: const Color(0xFF1B7F5A),
              ),
              MetricCard(
                label: 'Công nợ',
                value: formatMoney(totalDebt),
                icon: Icons.receipt_long,
                color: const Color(0xFFB95D2A),
              ),
              MetricCard(
                label: 'Dự phòng',
                value: formatMoney(totalReserve),
                icon: Icons.shield_outlined,
                color: const Color(0xFF315C9A),
              ),
              MetricCard(
                label: 'Rủi ro cao',
                value: '$highRisk dự án',
                icon: Icons.warning_amber_rounded,
                color: const Color(0xFFB3261E),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SectionHeader(
            title: 'Cần xử lý sớm',
            trailing: TextButton(
              onPressed: () {},
              child: const Text('Xem hết'),
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

class PaymentsView extends StatelessWidget {
  const PaymentsView({super.key, required this.projects});

  final List<ProjectFinance> projects;

  @override
  Widget build(BuildContext context) {
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

class StatsView extends StatelessWidget {
  const StatsView({super.key, required this.projects});

  final List<ProjectFinance> projects;

  @override
  Widget build(BuildContext context) {
    final paid = projects.fold<double>(0, (sum, p) => sum + p.paidAmount);
    final debt = projects.fold<double>(0, (sum, p) => sum + p.remaining);
    final reserve = projects.fold<double>(0, (sum, p) => sum + p.reserveAmount);

    return AppPage(
      title: 'Thống kê',
      subtitle: 'Tổng hợp thu nhập, công nợ và tiết kiệm',
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
          const SectionHeader(title: 'Góc nhìn nhanh'),
          InsightTile(
            icon: Icons.calendar_month_outlined,
            title: 'Dòng tiền tập trung vào giữa tháng',
            value: '2 khoản thu đến hạn trong 14 ngày tới',
          ),
          InsightTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Tỷ lệ dự phòng hiện tại',
            value: 'Đang đạt mức tốt so với mục tiêu 20%',
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
                'Sức khỏe dòng tiền',
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
            'Dòng tiền khả dụng sau khi trừ công nợ cần thu',
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
                  label: 'Đã thu',
                  value: formatMoney(project.paidAmount),
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Còn lại',
                  value: formatMoney(project.remaining),
                ),
              ),
              Expanded(
                child: _MiniStat(label: 'Hạn', value: project.dueDate),
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
                child: _MiniStat(
                  label: 'Giá trị',
                  value: formatMoney(project.totalValue),
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Cọc',
                  value: formatMoney(project.depositReceived),
                ),
              ),
              Expanded(
                child: _MiniStat(
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
                        label: 'Đã nhận',
                        value: formatMoney(project.paidAmount),
                      ),
                    ),
                    Expanded(
                      child: _MiniStat(
                        label: 'Cần thu',
                        value: formatMoney(project.remaining),
                      ),
                    ),
                    Expanded(
                      child: _MiniStat(label: 'Hạn', value: project.dueDate),
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
                'Mục tiêu dự phòng',
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
            'Giai đoạn hiện tại',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          ChartBar(
            label: 'Thu nhập',
            value: paid,
            maxValue: maxValue,
            color: const Color(0xFF1B7F5A),
          ),
          ChartBar(
            label: 'Công nợ',
            value: debt,
            maxValue: maxValue,
            color: const Color(0xFFB95D2A),
          ),
          ChartBar(
            label: 'Tiết kiệm',
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
            'Chỉ số rủi ro dự án',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: RiskCount(
                  label: 'Thấp',
                  count: countRisk(ProjectRisk.low),
                  color: riskColor(ProjectRisk.low),
                ),
              ),
              Expanded(
                child: RiskCount(
                  label: 'Vừa',
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
    ProjectRisk.low => 'Rủi ro thấp',
    ProjectRisk.medium => 'Rủi ro vừa',
    ProjectRisk.high => 'Rủi ro cao',
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
    PaymentStatus.depositReceived => 'Đã nhận cọc',
    PaymentStatus.partlyPaid => 'Đã thanh toán một phần',
    PaymentStatus.overdue => 'Quá hạn thanh toán',
    PaymentStatus.paid => 'Đã thanh toán',
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
