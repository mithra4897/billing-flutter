import '../../screen.dart';

class BudgetVsActualModel implements JsonModel {
  const BudgetVsActualModel({
    this.budget,
    this.summary,
    this.lines = const <Map<String, dynamic>>[],
  });

  final Map<String, dynamic>? budget;
  final Map<String, dynamic>? summary;
  final List<Map<String, dynamic>> lines;

  factory BudgetVsActualModel.fromJson(Map<String, dynamic> json) {
    return BudgetVsActualModel(
      budget: _map(json['budget']),
      summary: _map(json['summary']),
      lines: _mapList(json['lines']),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    if (budget != null) 'budget': budget,
    if (summary != null) 'summary': summary,
    'lines': lines,
  };

  static Map<String, dynamic>? _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) return const <Map<String, dynamic>>[];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }
}
