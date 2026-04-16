class EmployeeRelationModel {
  const EmployeeRelationModel({
    this.id,
    this.employeeId,
    this.relationName,
    this.age,
    this.phoneNumber,
    this.relationship,
  });

  final int? id;
  final int? employeeId;
  final String? relationName;
  final int? age;
  final String? phoneNumber;
  final String? relationship;

  factory EmployeeRelationModel.fromJson(Map<String, dynamic> json) {
    return EmployeeRelationModel(
      id: _nullableInt(json['id']),
      employeeId: _nullableInt(json['employee_id']),
      relationName: json['relation_name']?.toString(),
      age: _nullableInt(json['age']),
      phoneNumber: json['phone_number']?.toString(),
      relationship: json['relationship']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (employeeId != null) 'employee_id': employeeId,
      if (relationName != null) 'relation_name': relationName,
      if (age != null) 'age': age,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (relationship != null) 'relationship': relationship,
    };
  }

  static int? _nullableInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '');
}
