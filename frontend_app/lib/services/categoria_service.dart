import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/categoria.dart';

class CategoriaService {
  static Future<List<Categoria>> getCategorias(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/categorias'),
      headers: {
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
      },
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      return jsonResponse.map((data) => Categoria.fromJson(data)).toList();
    } else {
      throw Exception('Falló al cargar categorías: ${response.statusCode}');
    }
  }

  static Future<Categoria> createCategoria(Categoria categoria, String token) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/categorias'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
      },
      body: jsonEncode(categoria.toJson()),
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Categoria.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Falló al crear categoría: ${response.statusCode}');
    }
  }

  static Future<Categoria> updateCategoria(int id, Categoria categoria, String token) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/categorias/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
      },
      body: jsonEncode(categoria.toJson()),
    );
    if (response.statusCode == 200) {
      return Categoria.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Falló al actualizar categoría: ${response.statusCode}');
    }
  }

  static Future<void> deleteCategoria(int id, String token) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/categorias/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
      },
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Falló al eliminar categoría: ${response.statusCode}');
    }
  }
}
