// services/personnel_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/personel_model.dart';

class PersonnelService {
  static const baseUrl = 'http://localhost:8080/api/personnel';

  static Future<List<PersonnelModel>> fetchAllPersonnel() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data as List).map((e) => PersonnelModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load personnel");
    }
  }
  static Future<bool> updatePersonnelInfo(PersonnelModel person) async {
    final response = await http.put(
      Uri.parse('http://localhost:8080/api/personnel/${person.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': person.name,
        'role': person.role,
        'position': person.position,
        'nationality': person.nationality,
        'visaStatus': person.visaStatus,
        'salary': person.salary,
        'siteId': person.siteId,
        'status': person.status,
      }),
    );

    return response.statusCode == 200;
  }

  static Future<bool> assignSite(int personId, int? siteId) async {
    final response = await http.put(
      Uri.parse('http://localhost:8080/api/personnel/$personId/assign'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'siteId': siteId}),
    );

    print("Status Code: ${response.statusCode}");
    print("Response Body: ${response.body}");

    return response.statusCode == 200;
  }

  static Future<bool> assignSiteAndStatus(int id, int? siteId, String? status) async {
    final url = Uri.parse('http://localhost:8080/api/personnel/$id/assign');

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'siteId': siteId,
        'status': status,
      }),
    );

    return response.statusCode == 200;
  }



  static Future<List<PersonnelModel>> fetchPersonnelBySite(int siteId) async {
    final response = await http.get(Uri.parse('http://localhost:8080/api/personnel/by-site/$siteId'));

    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((e) => PersonnelModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load personnel');
    }
  }
  static Future<bool> updatePersonnelSite(int personId, int? siteId) async {
    final response = await http.put(
      Uri.parse('http://localhost:8080/api/personnel/$personId/assign'), // doğru URL mi?
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'siteId': siteId}),
    );

    print("🟡 Status Code: ${response.statusCode}");
    print("🟡 Response Body: ${response.body}");

    return response.statusCode == 200;
  }



  static Map<String, int> countByRole(List<PersonnelModel> personnelList) {
    final Map<String, int> roleCounts = {};
    for (var person in personnelList) {
      roleCounts[person.role] = (roleCounts[person.role] ?? 0) + 1;
    }
    return roleCounts;
  }

  static Future<bool> createPersonnel(PersonnelModel person) async {
    final response = await http.post(
      Uri.parse('http://localhost:8080/api/personnel'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': person.name,
        'role': person.role,
        'position': person.position,
        'nationality': person.nationality,
        'visaStatus': person.visaStatus,
        'salary': person.salary,
      }),
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }

}
