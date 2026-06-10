import 'package:flutter/material.dart';

import '../models/project_finance.dart';

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
