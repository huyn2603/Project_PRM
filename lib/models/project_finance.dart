enum ProjectRisk { low, medium, high }

enum PaymentStatus { depositReceived, partlyPaid, overdue, paid }

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
    required this.progress,
    required this.risk,
    required this.status,
    required this.notes,
  });

  final String id;
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

  double get remaining => (totalValue - paidAmount).clamp(0, double.infinity);

  ProjectFinance copyWith({
    String? id,
    String? name,
    String? client,
    double? totalValue,
    double? depositReceived,
    double? paidAmount,
    double? reserveAmount,
    String? dueDate,
    double? progress,
    ProjectRisk? risk,
    PaymentStatus? status,
    String? notes,
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
      progress: progress ?? this.progress,
      risk: risk ?? this.risk,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
