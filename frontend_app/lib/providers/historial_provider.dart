import 'package:flutter/material.dart';
import '../models/historial.dart';
import '../services/historial_service.dart';

class HistorialProvider with ChangeNotifier {
  List<HistorialLog> _registros = [];
  bool _isLoading = false;
  String? _error;

  List<HistorialLog> get registros => _registros;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadHistorial(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final service = HistorialService(token);
      _registros = await service.getHistorial();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteEntry(String token, int id) async {
    try {
      final service = HistorialService(token);
      await service.eliminarHistorial(id);
      _registros.removeWhere((h) => h.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> clearAll(String token) async {
    try {
      final service = HistorialService(token);
      await service.limpiarHistorial();
      _registros = [];
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
