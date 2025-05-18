class Invoice {
  final int id;
  final int reservationId;
  final double totalAmount;
  final String paymentMethod;
  final bool paymentStatus;
  final DateTime createdAt;

  Invoice({
    required this.id,
    required this.reservationId,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.createdAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as int,
      reservationId: json['reservation_id'] as int,
      totalAmount: (json['total_amount'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String,
      paymentStatus: json['payment_status'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}



