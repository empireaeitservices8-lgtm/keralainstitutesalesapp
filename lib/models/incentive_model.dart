class IncentiveModel {
  final String id;
  final String category; // 'Sales Target' | 'New Client' | 'Route Bonus' | 'High-Value Booking' | 'Promotional'
  final double amount;
  final String remarks;
  final DateTime date;
  final String? achievementProofPath; // Snapshot or Invoice proof
  final String status; // 'Pending' | 'Approved' | 'Paid'

  IncentiveModel({
    required this.id,
    required this.category,
    required this.amount,
    required this.remarks,
    required this.date,
    this.achievementProofPath,
    this.status = 'Pending',
  });

  IncentiveModel copyWith({
    String? status,
  }) {
    return IncentiveModel(
      id: id,
      category: category,
      amount: amount,
      remarks: remarks,
      date: date,
      achievementProofPath: achievementProofPath,
      status: status ?? this.status,
    );
  }
}
