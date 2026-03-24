import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/historial.dart';

class HistorialService {
  final String token;
  HistorialService(this.token);

  Future<List<HistorialLog>> getHistorial() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/historial');
    final response = await http.get(url, headers: {'Authorization': 'Bearer $token', 'ngrok-skip-browser-warning': 'true'});
    
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((e) => HistorialLog.fromJson(e)).toList();
    } else {
      throw Exception('Error al obtener historial: ${response.body}');
    }
  }
}
