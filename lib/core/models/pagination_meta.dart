class PaginationMeta {
  const PaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    this.qtyInTotal,
    this.qtyOutTotal,
    this.netQtyTotal,
  });

  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final double? qtyInTotal;
  final double? qtyOutTotal;
  final double? netQtyTotal;

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      currentPage: _parseInt(json['current_page']),
      lastPage: _parseInt(json['last_page']),
      perPage: _parseInt(json['per_page']),
      total: _parseInt(json['total']),
      qtyInTotal: _parseNullableDouble(json['qty_in_total']),
      qtyOutTotal: _parseNullableDouble(json['qty_out_total']),
      netQtyTotal: _parseNullableDouble(json['net_qty_total']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _parseNullableDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }
}
