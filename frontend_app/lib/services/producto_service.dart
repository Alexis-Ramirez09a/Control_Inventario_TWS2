import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/producto.dart';

/// Servicio HTTP de Productos
///
/// @author Alexis Ramírez
/// @date 2026-03-25
/// @description Capa de servicio que realiza las peticiones HTTP al backend Spring Boot.
///              Centraliza todas las llamadas REST para productos: GET, POST, PUT, DELETE.
///              Incluye operaciones de movimiento de stock (entrada/salida), soft delete
///              (papelera de reciclaje) y restauración. Cada petición incluye el header
///              'Authorization: Bearer <token>' y 'ngrok-skip-browser-warning'.
class ProductoService {
  final String token;

  ProductoService(this.token);

  Future<List<Producto>> getProductos() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/obtener/productos');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((e) => Producto.fromJson(e)).toList();
    } else {
      throw Exception('Error al obtener productos');
    }
  }

  Future<Producto> addProducto(Producto p) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/crear/producto');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token', 
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
      body: jsonEncode(p.toJson()),
    );

    if (response.statusCode == 201) {
      return Producto.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error al crear producto');
    }
  }

  Future<void> updateProducto(int id, Producto p) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/actualizar/producto/$id');
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token', 
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
      body: jsonEncode(p.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al editar producto');
    }
  }

  Future<void> updateStock(int id, int cantidad, String motivo, bool isEntrada) async {
    final action = isEntrada ? 'entrada' : 'salida';
    final url = Uri.parse('${ApiConfig.baseUrl}/$id/$action');
    
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token', 
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
      body: jsonEncode({'cantidad': cantidad, 'motivo': motivo}),
    );

    if (response.statusCode != 200) {
      try {
        final j = jsonDecode(response.body);
        throw Exception(j['mensaje'] ?? 'Error desconocido');
      } catch (e) {
        throw Exception('Error al actualizar stock');
      }
    }
  }

  Future<void> deleteProducto(int id) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/eliminar/producto/$id');
    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
      },
    );

    if (response.statusCode != 200) {
      String msg = 'No se pudo completar la operación';
      try {
        final j = jsonDecode(response.body);
        msg = j['mensaje'] ?? j['message'] ?? msg;
      } catch (_) {}
      throw Exception(msg);
    }
  }

  Future<List<Producto>> getProductosBorrados() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/obtener/borrados');
    final response = await http.get(url, headers: {'Authorization': 'Bearer $token', 'ngrok-skip-browser-warning': 'true'});
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((e) => Producto.fromJson(e)).toList();
    } else {
      throw Exception('Error al obtener papelera');
    }
  }

  Future<bool> restaurarProducto(int id) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/restaurar/producto/$id');
    final response = await http.put(url, headers: {'Authorization': 'Bearer $token', 'ngrok-skip-browser-warning': 'true'});
    return response.statusCode == 200;
  }
}
