import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/producto_provider.dart';
import 'providers/historial_provider.dart';
import 'providers/factura_provider.dart';
import 'providers/theme_provider.dart';
import 'core/app_theme.dart';
import 'ui/screens/login_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductoProvider()),
        ChangeNotifierProvider(create: (_) => HistorialProvider()),
        ChangeNotifierProvider(create: (_) => FacturaProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const InventoryApp(),
    ),
  );
}

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'Control Inventario App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
      home: const LoginScreen(),
    );
  }
}
