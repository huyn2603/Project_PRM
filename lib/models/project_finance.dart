enum ProjectRisk { low, medium, high }

enum PaymentStatus { depositReceived, partlyPaid, overdue, paid }

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