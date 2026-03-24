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
}
