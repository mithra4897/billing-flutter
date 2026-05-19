abstract class JsonModel {
  final int? id;

  Map<String, dynamic> toJson();

  const JsonModel({this.id});

  @override
  String toString();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JsonModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => Object.hash(runtimeType, id);
}
