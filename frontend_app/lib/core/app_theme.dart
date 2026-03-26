import 'package:flutter/material.dart';

/// Sistema de Temas Dual (Claro / Oscuro)
///
/// @author Alexis Ramírez
/// @date 2026-03-25
/// @description Define la paleta de colores profesional empresarial con verde sage para ambos modos.
///              Modo Oscuro: Negro azul profundo (#0D1B22) + sage claro (#8ECBA8).
///              Modo Claro: Blanco menta (#F0F5F2) + sage profundo (#4A8C6E).
///              Incluye configuración completa de: AppBar, Drawer, Cards, textos, iconos y divisores.
class AppTheme {
  // === PALETA PROFESIONAL ===
  // Verde Sage pastel: elegante, tranquilo, empresarial
  static const sage = Color(0xFF6DB390);         // Verde sage principal
  static const sageDark = Color(0xFF4A8C6E);     // Verde sage profundo (para fondo claro)
  static const sageLight = Color(0xFF8ECBA8);    // Verde sage suave (para fondo oscuro)

  // === TEMA OSCURO: Negro profundo + Sage ===
  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: const Color(0xFF0D1B22),
    colorScheme: ColorScheme.dark(
      primary: sageLight,
      secondary: sageLight,
      surface: const Color(0xFF152530),
      onPrimary: Colors.white,
      onSurface: Colors.white,
      tertiary: sageLight,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0F2230),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Color(0xFF132030),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1A2F40),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dividerColor: Colors.white12,
    iconTheme: const IconThemeData(color: Colors.white70),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white),
      bodySmall: TextStyle(color: Colors.white70),
    ),
  );

  // === TEMA CLARO: Blanco puro + Sage ===
  static final lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: const Color(0xFFF5F9F7), // Blanco menta más limpio
    colorScheme: ColorScheme.light(
      primary: sageDark,
      secondary: sageDark,
      surface: Colors.white,
      onPrimary: Colors.white,
      onSurface: const Color(0xFF1E293B), // Navy/Slate más profundo
      tertiary: sage,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF4A8C6E),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      surfaceTintColor: Colors.white,
    ),
    dividerColor: Colors.black.withOpacity(0.05),
    iconTheme: const IconThemeData(color: Color(0xFF4A8C6E)),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Color(0xFF1E293B)),
      bodySmall: TextStyle(color: Color(0xFF64748B)), // Slate suave
    ),
  );
}
