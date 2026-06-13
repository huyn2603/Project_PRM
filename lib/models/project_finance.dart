enum ProjectRisk { low, medium, high }

enum PaymentStatus { depositReceived, partlyPaid, overdue, paid }

enum ProjectCategory {
  design,
  development,
  marketing,
  content,
  consulting,
  other,
}

class PaymentMilestone {
  const PaymentMilestone({
    required this.id,
    required this.label,
    required this.amount,
    required this.dueDate,
    this.paidDate,
    this.isPaid = false,
  });

  final String id;
  final String label;
  final double amount;
  final String dueDate;
  final String? paidDate;
  final bool isPaid;

  PaymentMilestone copyWith({
    String? id,
    String? label,
    double? amount,
    String? dueDate,
    String? paidDate,
    bool? isPaid,
  }) {
    return PaymentMilestone(
      id: id ?? this.id,
      label: label ?? this.label,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      paidDate: paidDate ?? this.paidDate,
      isPaid: isPaid ?? this.isPaid,
    );
  }
}

class RiskFactor {
  const RiskFactor({
    required this.label,
    required this.score, // 0-10
    required this.description,
  });

  final String label;
  final int score;
  final String description;
}

class ProjectFinance {
  const ProjectFinance({
    required this.id,
    required this.name,
    required this.client,
    required this.totalValue,
    required this.depositReceived,
    required this.paidAmount,
    required this.reserveAmount,
    required this.dueDate,
    required this.startDate,
    required this.progress,
    required this.risk,
    required this.status,
    required this.notes,
    this.category = ProjectCategory.other,
    this.milestones = const [],
    this.riskFactors = const [],
    this.clientRating = 3,
    this.contractSigned = false,
    this.hasDeposit = false,
    this.scopeChangeCount = 0,
    this.overdueDays = 0,
    this.tags = const [],
  });

  final String id;
  final String name;
  final String client;
  final double totalValue;
  final double depositReceived;
  final double paidAmount;
  final double reserveAmount;
  final String dueDate;
  final String startDate;
  final double progress;
  final ProjectRisk risk;
  final PaymentStatus status;
  final String notes;
  final ProjectCategory category;
  final List<PaymentMilestone> milestones;
  final List<RiskFactor> riskFactors;
  final int clientRating; // 1-5
  final bool contractSigned;
  final bool hasDeposit;
  final int scopeChangeCount;
  final int overdueDays;
  final List<String> tags;

  double get remaining => (totalValue - paidAmount).clamp(0, double.infinity);

  double get depositProgress =>
      totalValue == 0 ? 0 : depositReceived / totalValue;

  /// Tính điểm rủi ro tổng hợp 0-100
  int get riskScore {
    int score = 0;

    // Không có hợp đồng ký kết (+25)
    if (!contractSigned) score += 25;

    // Chưa có cọc nhưng đã làm việc (+20)
    if (!hasDeposit && progress > 0) score += 20;

    // Thay đổi phạm vi nhiều lần (+15)
    score += (scopeChangeCount * 5).clamp(0, 15);

    // Đánh giá khách hàng thấp (+20 max)
    score += ((5 - clientRating) * 5).clamp(0, 20);

    // Quá hạn (+20 max)
    if (overdueDays > 0) score += (overdueDays * 2).clamp(0, 20);

    // Tỷ lệ công nợ cao (+10)
    if (totalValue > 0 && remaining / totalValue > 0.7) score += 10;

    return score.clamp(0, 100);
  }

  /// Mức rủi ro tính từ điểm
  ProjectRisk get computedRisk {
    if (riskScore >= 55) return ProjectRisk.high;
    if (riskScore >= 25) return ProjectRisk.medium;
    return ProjectRisk.low;
  }

  String get riskScoreLabel {
    if (riskScore >= 55) return 'Nguy hiểm';
    if (riskScore >= 25) return 'Cần chú ý';
    return 'Ổn định';
  }

  ProjectFinance copyWith({
    String? id,
    String? name,
    String? client,
    double? totalValue,
    double? depositReceived,
    double? paidAmount,
    double? reserveAmount,
    String? dueDate,
    String? startDate,
    double? progress,
    ProjectRisk? risk,
    PaymentStatus? status,
    String? notes,
    ProjectCategory? category,
    List<PaymentMilestone>? milestones,
    List<RiskFactor>? riskFactors,
    int? clientRating,
    bool? contractSigned,
    bool? hasDeposit,
    int? scopeChangeCount,
    int? overdueDays,
    List<String>? tags,
  }) {
    return ProjectFinance(
      id: id ?? this.id,
      name: name ?? this.name,
      client: client ?? this.client,
      totalValue: totalValue ?? this.totalValue,
      depositReceived: depositReceived ?? this.depositReceived,
      paidAmount: paidAmount ?? this.paidAmount,
      reserveAmount: reserveAmount ?? this.reserveAmount,
      dueDate: dueDate ?? this.dueDate,
      startDate: startDate ?? this.startDate,
      progress: progress ?? this.progress,
      risk: risk ?? this.risk,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      milestones: milestones ?? this.milestones,
      riskFactors: riskFactors ?? this.riskFactors,
      clientRating: clientRating ?? this.clientRating,
      contractSigned: contractSigned ?? this.contractSigned,
      hasDeposit: hasDeposit ?? this.hasDeposit,
      scopeChangeCount: scopeChangeCount ?? this.scopeChangeCount,
      overdueDays: overdueDays ?? this.overdueDays,
      tags: tags ?? this.tags,
    );
  }
}
