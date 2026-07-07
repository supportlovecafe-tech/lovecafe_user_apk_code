class CartBreakdown {
  final double subtotal;
  final double discount;
  final double cgst;
  final double sgst;
  final double platformCharges;
  final double platformFeePercent;
  final double total;
  final List<String> errors;

  CartBreakdown({
    this.subtotal = 0.0,
    this.discount = 0.0,
    this.cgst = 0.0,
    this.sgst = 0.0,
    this.platformCharges = 0.0,
    this.platformFeePercent = 1.0,
    this.total = 0.0,
    this.errors = const [],
  });

  factory CartBreakdown.fromMap(Map<String, dynamic> map) {
    return CartBreakdown(
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      cgst: (map['cgst'] as num?)?.toDouble() ?? 0.0,
      sgst: (map['sgst'] as num?)?.toDouble() ?? 0.0,
      platformCharges: (map['platform_charges'] as num?)?.toDouble() ?? 0.0,
      platformFeePercent: (map['platform_fee_percent'] as num?)?.toDouble() ?? 1.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      errors: [],
    );
  }
}
