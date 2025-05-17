class PersonnelModel {
  final int id;
  final String name;
  final String role;
  final int? siteId;
  final String? position;
  final String? nationality;
  final String? visaStatus;
  final double? salary;
  final String? status; // ✅ Yeni alan

  PersonnelModel({
    required this.id,
    required this.name,
    required this.role,
    required this.siteId,
    this.position,
    this.nationality,
    this.visaStatus,
    this.salary,
    this.status,
  });

  factory PersonnelModel.fromJson(Map<String, dynamic> json) {
    return PersonnelModel(
      id: json['id'],
      name: json['name'],
      role: json['role'],
      siteId: json['siteId'],
      position: json['position'],
      nationality: json['nationality'],
      visaStatus: json['visaStatus'],
      salary: json['salary'] != null ? (json['salary'] as num).toDouble() : null,
      status: json['status'], // ✅ JSON'dan okuma
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'siteId': siteId,
      'position': position,
      'nationality': nationality,
      'visaStatus': visaStatus,
      'salary': salary,
      'status': status, // ✅ JSON'a yazma
    };
  }
}
