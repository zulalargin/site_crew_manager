class PersonnelModel {
  final int id;
  final String name;
  final String role;
  final int? siteId;

  PersonnelModel({
    required this.id,
    required this.name,
    required this.role,
    required this.siteId,
  });

  factory PersonnelModel.fromJson(Map<String, dynamic> json) {
    return PersonnelModel(
      id: json['id'],
      name: json['name'],
      role: json['role'],
      siteId: json['siteId'],
    );
  }
}
