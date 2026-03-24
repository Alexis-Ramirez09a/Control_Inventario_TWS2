import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  Usuario? _usuario;
  String? _token;
  bool _isLoading = false;

  Usuario? get usuario => _usuario;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;

  Future<bool> login(String nombre, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await AuthService.login(nombre, password);
      _usuario = res['user'];
      _token = res['token'];
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', _token!);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    _usuario = null;
    _token = null;
    notifyListeners();
  }
}
