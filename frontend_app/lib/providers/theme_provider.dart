import 'package:flutter/material.dart';

/// Proveedor de Tema (Toggle Claro/Oscuro)
///
/// @author Alexis Ramírez
/// @date 2026-03-25
/// @description ChangeNotifier que gestiona el estado global del tema de la aplicación.
///              Expone un flag 'isDark' y un método 'toggle()' que notifica a todos los widgets
///              suscritos para re-renderizar con la nueva paleta de colores.
class ThemeProvider with ChangeNotifier {
  bool _isDark = true;

  bool get isDark => _isDark;

  void toggle() {
    _isDark = !_isDark;
    notifyListeners();
  }
}
