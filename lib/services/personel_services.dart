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

  static Future<void> assignSite(int personId, int siteId) async {
    final url = Uri.parse('$baseUrl/$personId/assign/$siteId');
    final response = await http.put(url);
    if (response.statusCode != 200) {
      throw Exception("Failed to assign site");
    }
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
  static Future<bool> updatePersonnelSite(int personId, int newSiteId) async {
    final response = await http.put(
      Uri.parse('http://localhost:8080/api/personnel/$personId/assign/$newSiteId'),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print('Error updating site: ${response.statusCode}');
      return false;
    }
  }
}
