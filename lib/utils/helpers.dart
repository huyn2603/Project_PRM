import 'package:flutter/material.dart';

import '../models/project_finance.dart';

// ─── Money formatting ────────────────────────────────────────────────────────

String formatMoney(double value) {
  if (value >= 1000000000) {
    final b = value / 1000000000;
    return '${b % 1 == 0 ? b.toStringAsFixed(0) : b.toStringAsFixed(1)}tỷ';
  }
  if (value >= 1000000) {
    final m = value / 1000000;
    return '${m % 1 == 0 ? m.toStringAsFixed(0) : m.toStringAsFixed(1)}tr';
  }
  if (value >= 1000) {
    final k = value / 1000;
    return '${k % 1 == 0 ? k.toStringAsFixed(0) : k.toStringAsFixed(1)}k';
  }
  return value.toStringAsFixed(0);
}

String formatMoneyFull(double value) {
  final s = value.toStringAsFixed(0);
  final result = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) result.write('.');
    result.write(s[i]);
  }
  return '$resultđ';
}

double parseMoney(String value) {
  final clean = value.replaceAll('.', '').replaceAll(',', '').trim();
  return double.tryParse(clean) ?? 0;
}

// ─── Risk ────────────────────────────────────────────────────────────────────

Color riskColor(ProjectRisk risk) {
  return switch (risk) {
    ProjectRisk.low => const Color(0xFF1B7F5A),
    ProjectRisk.medium => const Color(0xFFB95D2A),
    ProjectRisk.high => const Color(0xFFB3261E),
  };
}

Color riskScoreColor(int score) {
  if (score >= 55) return const Color(0xFFB3261E);
  if (score >= 25) return const Color(0xFFB95D2A);
  return const Color(0xFF1B7F5A);
}

String riskText(ProjectRisk risk) {
  return switch (risk) {
    ProjectRisk.low => 'Thấp',
    ProjectRisk.medium => 'Vừa',
    ProjectRisk.high => 'Cao',
  };
}

// ─── Status ──────────────────────────────────────────────────────────────────

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
    PaymentStatus.partlyPaid => 'Thanh toán một phần',
    PaymentStatus.overdue => 'Quá hạn',
    PaymentStatus.paid => 'Đã thanh toán',
  };
}

// ─── Category ────────────────────────────────────────────────────────────────

String categoryText(ProjectCategory cat) {
  return switch (cat) {
    ProjectCategory.design => 'Thiết kế',
    ProjectCategory.development => 'Lập trình',
    ProjectCategory.marketing => 'Marketing',
    ProjectCategory.content => 'Nội dung',
    ProjectCategory.consulting => 'Tư vấn',
    ProjectCategory.other => 'Khác',
  };
}

IconData categoryIcon(ProjectCategory cat) {
  return switch (cat) {
    ProjectCategory.design => Icons.palette_outlined,
    ProjectCategory.development => Icons.code_outlined,
    ProjectCategory.marketing => Icons.campaign_outlined,
    ProjectCategory.content => Icons.article_outlined,
    ProjectCategory.consulting => Icons.lightbulb_outlined,
    ProjectCategory.other => Icons.work_outline,
  };
}

// ─── Card decorations ────────────────────────────────────────────────────────

BoxDecoration cardDecoration({Color? borderColor}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: borderColor ?? const Color(0xFFEAECE4)),
    boxShadow: const [
      BoxShadow(
        color: Color(0x07000000),
        blurRadius: 20,
        offset: Offset(0, 6),
      ),
    ],
  );
}

BoxDecoration gradientCardDecoration(List<Color> colors) {
  return BoxDecoration(
    gradient: LinearGradient(
      colors: colors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: colors.first.withValues(alpha: 0.35),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
