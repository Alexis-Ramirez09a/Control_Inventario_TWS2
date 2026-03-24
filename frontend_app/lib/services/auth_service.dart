import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/usuario.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(String nombre, String password) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/auth/login');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
      body: jsonEncode({'nombre': nombre, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final usuarioData = data['usuario'];
      final token = data['token'];
      final user = Usuario.fromJson(usuarioData);
      return {'user': user, 'token': token};
    } else {
      throw Exception('Error al iniciar sesión: ${response.body}');
    }
  }
}
