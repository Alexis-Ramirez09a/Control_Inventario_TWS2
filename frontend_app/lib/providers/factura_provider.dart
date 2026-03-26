import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';

/// Proveedor de Estado de Facturas (Circuit Breaker + Polling)
///
/// @author Alexis Ramírez
/// @date 2026-03-25
/// @description Gestiona el estado de las facturas obtenidas desde el gateway BFF (GET /api/facturas).
///              Implementa background polling cada 3 segundos para detectar cambios de estado del
///              Circuit Breaker en tiempo real. Maneja estados: cargando, error de red, mantenimiento
///              (503), rate limit (429) y bloqueo permanente (403). Limpia la caché de facturas
///              automáticamente ante cualquier fallo para evitar datos desfasados.
class FacturaProvider with ChangeNotifier {
  List<dynamic> facturas = [];
  bool isLoading = false;
  String? error;
  bool isEnMantenimiento = false;

  Future<void> loadFacturas(String token, {bool background = false}) async {
    if (!background) {
      isLoading = true;
      error = null;
      isEnMantenimiento = false;
      notifyListeners();
    }

    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/facturas'),
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (res.statusCode == 200) {
        facturas = json.decode(res.body);
        error = null;
        isEnMantenimiento = false;
      } else if (res.statusCode == 503 || res.statusCode == 404) {
        // CircuitBreaker activado o ruta caída. Envolvemos la respuesta
        final body = jsonDecode(res.body);
        error = body['mensaje'] ?? 'El servicio se encuentra en mantenimiento temporalmente';
        isEnMantenimiento = true;
        facturas.clear(); // Limpiar residuos en tiempo real
      } else if (res.statusCode == 429) {
        error = 'Demasiadas peticiones. Bloqueo temporal por seguridad (Rate Limit).';
        facturas.clear();
        isEnMantenimiento = false;
      } else if (res.statusCode == 403) {
        error = 'IP Bloqueada permanentemente por exceso de peticiones.';
        facturas.clear();
        isEnMantenimiento = false;
      } else {
        error = 'Error desconocido o servicio inaccesible: ${res.statusCode}';
        facturas.clear();
        isEnMantenimiento = false;
      }
    } catch (e) {
      error = 'Fallo de red al intentar descargar las facturas remotas.';
      facturas.clear();
      isEnMantenimiento = false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
