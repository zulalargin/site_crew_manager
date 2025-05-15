class SiteModel {
  final int id;
  final String name;
  final String location;
  final int workerCount;
  final int engineerCount;

  SiteModel({
    required this.id,
    required this.name,
    required this.location,
    required this.workerCount,
    required this.engineerCount,
  });

  factory SiteModel.fromJson(Map<String, dynamic> json) {
    return SiteModel(
      id: json['id'],
      name: json['name'],
      location: json['location'],
      workerCount: json['workerCount'] ?? 0,
      engineerCount: json['engineerCount'] ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is SiteModel && id == other.id);

  @override
  int get hashCode => id.hashCode;
}
