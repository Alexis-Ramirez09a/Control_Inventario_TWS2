import 'package:flutter/foundation.dart';
import '../models/producto.dart';
import '../services/producto_service.dart';

class ProductoProvider extends ChangeNotifier {
  List<Producto> _productos = [];
  List<Producto> _borrados = [];
  bool _isLoading = false;
  String? _error;

  List<Producto> get productos => _productos;
  List<Producto> get borrados => _borrados;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProductos(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    int retryCount = 0;
    const maxRetries = 3;
    bool success = false;

    while (retryCount < maxRetries && !success) {
      try {
        final service = ProductoService(token);
        _productos = await service.getProductos();
        success = true;
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          _error = "Error de conexión (Ngrok): Verifica que el servidor esté activo e intenta de nuevo.";
          debugPrint('Error final tras $retryCount reintentos: $e');
        } else {
          await Future.delayed(Duration(milliseconds: 500 * retryCount));
        }
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<String?> darEntradaStock(String token, int id, int cantidad, String motivo) async {
    try {
      final service = ProductoService(token);
      await service.updateStock(id, cantidad, motivo, true);
      await loadProductos(token);
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  Future<String?> darSalidaStock(String token, int id, int cantidad, String motivo) async {
    try {
      final service = ProductoService(token);
      await service.updateStock(id, cantidad, motivo, false);
      await loadProductos(token);
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  Future<bool> addProducto(String token, Producto p) async {
    try {
      final service = ProductoService(token);
      await service.addProducto(p);
      await loadProductos(token);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> editProducto(String token, int id, Producto p) async {
    try {
      final service = ProductoService(token);
      await service.updateProducto(id, p);
      await loadProductos(token);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> deleteProducto(String token, int id) async {
    try {
      final service = ProductoService(token);
      await service.deleteProducto(id);
      await loadProductos(token);
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  Future<void> loadProductosBorrados(String token) async {
    _isLoading = true;
    notifyListeners();
    try {
      final service = ProductoService(token);
      _borrados = await service.getProductosBorrados();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> restaurarProducto(String token, int id) async {
    try {
      final service = ProductoService(token);
      final rx = await service.restaurarProducto(id);
      if (rx) {
        await loadProductos(token);
        await loadProductosBorrados(token);
      }
      return rx;
    } catch (e) {
      return false;
    }
  }
}
