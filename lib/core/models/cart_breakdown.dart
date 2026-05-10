class CartBreakdown {
  final double subtotal;
  final double cgst;
  final double sgst;
  final double platformCharges;
  final double total;
  final List<String> errors;

  CartBreakdown({
    this.subtotal = 0.0,
    this.cgst = 0.0,
    this.sgst = 0.0,
    this.platformCharges = 0.0,
    this.total = 0.0,
    this.errors = const [],
  });

  factory CartBreakdown.fromMap(Map<String, dynamic> map) {
    return CartBreakdown(
      subtotal: (map['subtotal'] as num).toDouble(),
      cgst: (map['cgst'] as num).toDouble(),
      sgst: (map['sgst'] as num).toDouble(),
      platformCharges: (map['platform_charges'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      errors: [],
    );
  }
}
