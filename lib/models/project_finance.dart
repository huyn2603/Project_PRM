enum ProjectRisk { low, medium, high }

enum PaymentStatus { depositReceived, partlyPaid, overdue, paid }

enum ProjectWorkMode { solo, team }

enum ProjectCategory {
  design,
  development,
  marketing,
  content,
  consulting,
  other,
}

class TeamMember {
  const TeamMember({
    required this.id,
    required this.name,
    required this.responsibility,
    required this.specialty,
    required this.sharePercent,
    this.paidBeforeMigration = 0,
  });

  final String id;
  final String name;
  final String responsibility;
  final String specialty;

  /// Phần trăm thành viên được hưởng trên mọi khoản khách thanh toán.
  final double sharePercent;
  final double paidBeforeMigration;

  factory TeamMember.fromMap(
    Map<String, dynamic> data, {
    double projectTotal = 0,
  }) {
    final legacyShare = (data['shareAmount'] as num?)?.toDouble() ?? 0;
    return TeamMember(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      responsibility: data['responsibility'] as String? ?? '',
      specialty: data['specialty'] as String? ?? '',
      sharePercent: (data['sharePercent'] as num?)?.toDouble() ??
          (projectTotal > 0 ? legacyShare / projectTotal * 100 : 0),
      paidBeforeMigration: (data['paidBeforeMigration'] as num?)?.toDouble() ??
          ((data['isPaid'] as bool? ?? false) ? legacyShare : 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'responsibility': responsibility,
      'specialty': specialty,
      'sharePercent': sharePercent,
      'paidBeforeMigration': paidBeforeMigration,
    };
  }
}

enum ClientPaymentKind { deposit, installment, finalPayment }

class ClientPayment {
  const ClientPayment({
    required this.id,
    required this.amount,
    required this.receivedAt,
    required this.kind,
  });

  final String id;
  final double amount;
  final DateTime receivedAt;
  final ClientPaymentKind kind;

  factory ClientPayment.fromMap(Map<String, dynamic> data) => ClientPayment(
        id: data['id'] as String? ?? '',
        amount: (data['amount'] as num?)?.toDouble() ?? 0,
        receivedAt: DateTime.tryParse(data['receivedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        kind: ClientPaymentKind.values
                .where((value) => value.name == data['kind'])
                .firstOrNull ??
            ClientPaymentKind.installment,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'amount': amount,
        'receivedAt': receivedAt.toIso8601String(),
        'kind': kind.name,
      };
}

class TeamPayout {
  const TeamPayout({
    required this.id,
    required this.memberId,
    required this.amount,
    required this.paidAt,
  });

  final String id;
  final String memberId;
  final double amount;
  final DateTime paidAt;

  factory TeamPayout.fromMap(Map<String, dynamic> data) => TeamPayout(
        id: data['id'] as String? ?? '',
        memberId: data['memberId'] as String? ?? '',
        amount: (data['amount'] as num?)?.toDouble() ?? 0,
        paidAt: DateTime.tryParse(data['paidAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'memberId': memberId,
        'amount': amount,
        'paidAt': paidAt.toIso8601String(),
      };
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

  factory PaymentMilestone.fromMap(Map<String, dynamic> data) {
    return PaymentMilestone(
      id: data['id'] as String? ?? '',
      label: data['label'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      dueDate: data['dueDate'] as String? ?? '',
      paidDate: data['paidDate'] as String?,
      isPaid: data['isPaid'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'amount': amount,
      'dueDate': dueDate,
      'paidDate': paidDate,
      'isPaid': isPaid,
    };
  }

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

  factory RiskFactor.fromMap(Map<String, dynamic> data) {
    return RiskFactor(
      label: data['label'] as String? ?? '',
      score: (data['score'] as num?)?.toInt() ?? 0,
      description: data['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'score': score,
      'description': description,
    };
  }
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
    this.deliveryDate = '',
    this.workMode = ProjectWorkMode.solo,
    this.teamMembers = const [],
    this.clientPayments = const [],
    this.teamPayouts = const [],
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
  final String deliveryDate;
  final ProjectWorkMode workMode;
  final List<TeamMember> teamMembers;
  final List<ClientPayment> clientPayments;
  final List<TeamPayout> teamPayouts;

  factory ProjectFinance.fromMap(String id, Map<String, dynamic> data) {
    T enumValue<T extends Enum>(List<T> values, String? name, T fallback) {
      return values.where((value) => value.name == name).firstOrNull ??
          fallback;
    }

    return ProjectFinance(
      id: id,
      name: data['name'] as String? ?? '',
      client: data['client'] as String? ?? '',
      totalValue: (data['totalValue'] as num?)?.toDouble() ?? 0,
      depositReceived: (data['depositReceived'] as num?)?.toDouble() ?? 0,
      paidAmount: (data['paidAmount'] as num?)?.toDouble() ?? 0,
      reserveAmount: (data['reserveAmount'] as num?)?.toDouble() ?? 0,
      dueDate: data['dueDate'] as String? ?? '',
      startDate: data['startDate'] as String? ?? '',
      progress: (data['progress'] as num?)?.toDouble() ?? 0,
      risk: enumValue(
          ProjectRisk.values, data['risk'] as String?, ProjectRisk.low),
      status: enumValue(
        PaymentStatus.values,
        data['status'] as String?,
        PaymentStatus.depositReceived,
      ),
      notes: data['notes'] as String? ?? '',
      category: enumValue(
        ProjectCategory.values,
        data['category'] as String?,
        ProjectCategory.other,
      ),
      milestones: (data['milestones'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) =>
              PaymentMilestone.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
      riskFactors: (data['riskFactors'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => RiskFactor.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
      clientRating: (data['clientRating'] as num?)?.toInt() ?? 3,
      contractSigned: data['contractSigned'] as bool? ?? false,
      hasDeposit: data['hasDeposit'] as bool? ?? false,
      scopeChangeCount: (data['scopeChangeCount'] as num?)?.toInt() ?? 0,
      overdueDays: (data['overdueDays'] as num?)?.toInt() ?? 0,
      tags: (data['tags'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      deliveryDate:
          data['deliveryDate'] as String? ?? data['dueDate'] as String? ?? '',
      workMode: enumValue(
        ProjectWorkMode.values,
        data['workMode'] as String?,
        ProjectWorkMode.solo,
      ),
      teamMembers: (data['teamMembers'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => TeamMember.fromMap(
                Map<String, dynamic>.from(item),
                projectTotal: (data['totalValue'] as num?)?.toDouble() ?? 0,
              ))
          .toList(),
      clientPayments: (data['clientPayments'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => ClientPayment.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
      teamPayouts: (data['teamPayouts'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => TeamPayout.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'client': client,
      'totalValue': totalValue,
      'depositReceived': depositReceived,
      'paidAmount': paidAmount,
      'reserveAmount': reserveAmount,
      'dueDate': dueDate,
      'dueAt': _parseVietnameseDate(dueDate),
      'startDate': startDate,
      'startAt': _parseVietnameseDate(startDate),
      'progress': progress,
      'risk': risk.name,
      'riskScore': riskScore,
      'status': status.name,
      'notes': notes,
      'category': category.name,
      'milestones': milestones.map((item) => item.toMap()).toList(),
      'riskFactors': riskFactors.map((item) => item.toMap()).toList(),
      'clientRating': clientRating,
      'contractSigned': contractSigned,
      'hasDeposit': hasDeposit,
      'scopeChangeCount': scopeChangeCount,
      'overdueDays': overdueDays,
      'tags': tags,
      'deliveryDate': deliveryDate,
      'deliveryAt': _parseVietnameseDate(deliveryDate),
      'workMode': workMode.name,
      'teamMembers': teamMembers.map((item) => item.toMap()).toList(),
      'clientPayments': clientPayments.map((item) => item.toMap()).toList(),
      'teamPayouts': teamPayouts.map((item) => item.toMap()).toList(),
      'teamSharePercent': teamSharePercent,
      'teamShareTotal': teamShareTotal,
      'teamEarnedToDate': teamEarnedToDate,
      'teamPaidToDate': teamPaidToDate,
      'teamPayable': teamPayable,
      'ownerContractShare': ownerContractShare,
      'ownerNetReceived': ownerNetReceived,
    };
  }

  static DateTime? _parseVietnameseDate(String value) {
    final match =
        RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(value.trim());
    if (match == null) return null;
    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final year = int.tryParse(match.group(3)!);
    if (day == null || month == null || year == null) return null;
    final date = DateTime(year, month, day);
    if (date.day != day || date.month != month || date.year != year) {
      return null;
    }
    // Lưu cuối ngày UTC để job 08:00 Asia/Bangkok không đánh dấu quá hạn
    // ngay trong buổi sáng của chính ngày đến hạn.
    return DateTime.utc(year, month, day, 23, 59, 59);
  }

  double get remaining => (totalValue - paidAmount).clamp(0, double.infinity);

  double get teamSharePercent => teamMembers.fold<double>(
        0,
        (sum, member) => sum + member.sharePercent,
      );

  double get teamShareTotal => totalValue * teamSharePercent / 100;

  double memberContractShare(TeamMember member) =>
      totalValue * member.sharePercent / 100;

  double memberEarnedToDate(TeamMember member) =>
      paidAmount * member.sharePercent / 100;

  double memberPaidToDate(TeamMember member) =>
      teamPayouts
          .where((payout) => payout.memberId == member.id)
          .fold<double>(0, (sum, payout) => sum + payout.amount) +
      member.paidBeforeMigration;

  double memberPayable(TeamMember member) =>
      (memberEarnedToDate(member) - memberPaidToDate(member))
          .clamp(0, double.infinity);

  double get teamEarnedToDate => paidAmount * teamSharePercent / 100;

  double get teamPaidToDate =>
      teamPayouts.fold<double>(0, (sum, payout) => sum + payout.amount);

  double get teamPayable =>
      (teamEarnedToDate - teamPaidToDate).clamp(0, double.infinity);

  double get ownerContractShare =>
      (totalValue - teamShareTotal).clamp(0, double.infinity);

  double get ownerNetReceived =>
      (paidAmount - teamEarnedToDate).clamp(0, double.infinity);

  double get ownerRemaining =>
      (ownerContractShare - ownerNetReceived).clamp(0, double.infinity);

  double get depositProgress =>
      totalValue == 0 ? 0 : depositReceived / totalValue;

  double get paymentProgress =>
      totalValue <= 0 ? 0 : (paidAmount / totalValue).clamp(0, 1).toDouble();

  double get progressPaymentGap =>
      progress.clamp(0, 1).toDouble() - paymentProgress;

  bool get isFullyPaid => remaining <= 0;

  bool get isCompletedAndPaid => isFullyPaid && progress >= 1;

  /// Tính điểm rủi ro tổng hợp 0-100
  int get riskScore {
    if (isCompletedAndPaid) return 0;

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

    if (progressPaymentGap > 0) {
      score += (progressPaymentGap * 80).round().clamp(0, 40);
    }

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
    String? deliveryDate,
    ProjectWorkMode? workMode,
    List<TeamMember>? teamMembers,
    List<ClientPayment>? clientPayments,
    List<TeamPayout>? teamPayouts,
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
      deliveryDate: deliveryDate ?? this.deliveryDate,
      workMode: workMode ?? this.workMode,
      teamMembers: teamMembers ?? this.teamMembers,
      clientPayments: clientPayments ?? this.clientPayments,
      teamPayouts: teamPayouts ?? this.teamPayouts,
    );
  }
}
