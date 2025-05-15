import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/personel_model.dart';
import '../model/site_model.dart';

class SiteService {
  static const String baseUrl = 'http://localhost:8080/api/sites';

  static Future<List<SiteModel>> fetchSites() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => SiteModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load sites');
    }
  }
  static Future<SiteModel> fetchSiteById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/$id'));

    if (response.statusCode == 200) {
      return SiteModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load site detail');
    }
  }



}
