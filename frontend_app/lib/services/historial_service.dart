import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/historial.dart';

class HistorialService {
  final String token;
  HistorialService(this.token);

  Future<List<HistorialLog>> getHistorial() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/historial');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token', 
      'ngrok-skip-browser-warning': 'true'
    }).timeout(const Duration(seconds: 10));
    
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((e) => HistorialLog.fromJson(e)).toList();
    } else {
      throw Exception('Error al obtener historial: ${response.body}');
    }
  }

  Future<void> eliminarHistorial(int id) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/historial/$id');
    final response = await http.delete(url, headers: {
      'Authorization': 'Bearer $token',
      'ngrok-skip-browser-warning': 'true'
    }).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar registro: ${response.body}');
    }
  }

  Future<void> limpiarHistorial() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/historial/limpiar');
    final response = await http.delete(url, headers: {
      'Authorization': 'Bearer $token',
      'ngrok-skip-browser-warning': 'true'
    }).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Error al limpiar historial: ${response.body}');
    }
  }
}
