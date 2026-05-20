class Position {
  final int id;
  final int companyId;

  final String name;
  final String? code;
  final String? description;
  final int order;
  final bool isActive;

  final int? employeesCount;
  final String? companyName;

  const Position({
    required this.id,
    required this.companyId,
    required this.name,
    this.code,
    this.description,
    this.order = 0,
    this.isActive = true,
    this.employeesCount,
    this.companyName,
  });

  int? get totalEmployees => employeesCount;

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      id: json['id'] as int,
      companyId: json['company_id'] as int,
      name: json['name'] as String,
      code: json['code'] as String?,
      description: json['description'] as String?,
      order: json['order'] as int? ?? 0,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      employeesCount:
          json['employees_count'] as int? ?? json['total_employees'] as int?,
      companyName:
          (json['company'] as Map<String, dynamic>?)?['name'] as String? ??
          json['company_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'company_id': companyId,
    'name': name,
    'code': code,
    'description': description,
    'order': order,
    'is_active': isActive,
  };

  Position copyWith({
    int? id,
    int? companyId,
    String? name,
    String? code,
    String? description,
    int? order,
    bool? isActive,
    int? employeesCount,
    String? companyName,
  }) => Position(
    id: id ?? this.id,
    companyId: companyId ?? this.companyId,
    name: name ?? this.name,
    code: code ?? this.code,
    description: description ?? this.description,
    order: order ?? this.order,
    isActive: isActive ?? this.isActive,
    employeesCount: employeesCount ?? this.employeesCount,
    companyName: companyName ?? this.companyName,
  );
}
