import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/producto.dart';
import '../../models/categoria.dart';
import '../../services/categoria_service.dart';
import 'dart:async';
import '../../models/historial.dart';
import '../../providers/auth_provider.dart';
import '../../providers/producto_provider.dart';
import '../../providers/historial_provider.dart';
import '../../providers/factura_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/app_theme.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _indiceActual = 0;
  String _filtroHistorial = 'TODOS';
  String _filtroProducto = 'TODOS'; // Filtro: TODOS, INVENTARIADO, NO_INVENTARIADO
  String _busqueda = ""; // Término de búsqueda por nombre
  DateTime? _fechaInicio; // Filtro de bitácora
  DateTime? _fechaFin;    // Filtro de bitácora
  Timer? _facturasPoller;
  List<Categoria> _categorias = [];

  @override
  void dispose() {
    _facturasPoller?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token;
      if (token != null) {
        context.read<ProductoProvider>().loadProductos(token);
        _cargarCategorias();
      }
    });
  }

  Future<void> _cargarCategorias() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final cats = await CategoriaService.getCategorias(token);
      setState(() => _categorias = cats);
    } catch (e) {
      debugPrint("Error cargando categorías: $e");
    }
  }

  // === HELPERS DE TEMA ===
  bool get _isDark => context.read<ThemeProvider>().isDark;
  Color get _textColor => _isDark ? Colors.white : const Color(0xFF1A2730);
  Color get _subTextColor => _isDark ? Colors.white70 : const Color(0xFF5A7080);
  Color get _cardBg => _isDark ? Colors.white.withOpacity(0.06) : Colors.white;
  Color get _cardBorder => _isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200;
  Color get _accentColor => _isDark ? AppTheme.sageLight : AppTheme.sageDark;
  Color get _dialogBg => _isDark ? const Color(0xFF1A3040) : Colors.white;
  Color get _chipBg => _isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade100;
  Color get _dividerColor => _isDark ? Colors.white24 : Colors.grey.shade300;

  void _seleccionarMenu(int index) {
    setState(() => _indiceActual = index);
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    if (index != 4) {
      _facturasPoller?.cancel();
      _facturasPoller = null;
    }

    if (index == 4) {
      context.read<FacturaProvider>().loadFacturas(token);
      _facturasPoller?.cancel();
      _facturasPoller = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (!mounted || _indiceActual != 4) {
          timer.cancel();
          return;
        }
        context.read<FacturaProvider>().loadFacturas(token, background: true);
      });
    } else if (index == 2) {
      context.read<HistorialProvider>().loadHistorial(token);
    } else if (index == 3) {
      context.read<ProductoProvider>().loadProductosBorrados(token);
    } else if (index == 5) {
      _cargarCategorias();
    }
    Navigator.pop(context);
  }

  void _mostrarDialogoStock(Producto p, bool esEntrada) {
    final objController = TextEditingController();
    final motivoController = TextEditingController(text: esEntrada ? 'Entrada manual' : 'Despacho');

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curve,
          child: FadeTransition(
            opacity: anim1,
            child: StatefulBuilder(
              builder: (ctx, setState) {
                final cantidadInput = int.tryParse(objController.text) ?? 0;
                final vacio = objController.text.trim().isEmpty || cantidadInput <= 0;
                final excedido = !esEntrada && (cantidadInput > p.cantidadEnStock);

                return AlertDialog(
                  backgroundColor: _dialogBg,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  title: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (esEntrada ? _accentColor : Colors.deepOrangeAccent).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          esEntrada ? LucideIcons.packagePlus : LucideIcons.packageMinus,
                          color: esEntrada ? _accentColor : Colors.deepOrangeAccent,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        esEntrada ? 'Añadir al Inventario' : 'Despachar Producto',
                        style: TextStyle(color: _textColor, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(p.nombre, style: TextStyle(color: _subTextColor, fontSize: 14), textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      TextField(
                        controller: objController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: _textColor, fontSize: 18, fontWeight: FontWeight.bold),
                        onChanged: (v) => setState(() {}),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: '0',
                          labelText: 'Cantidad a ${esEntrada ? 'ingresar' : 'retirar'}',
                          labelStyle: TextStyle(color: _subTextColor),
                          filled: true,
                          fillColor: _isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          prefixIcon: Icon(LucideIcons.hash, color: _accentColor),
                          errorText: excedido ? 'Stock insuficiente (máx: ${p.cantidadEnStock})' : null,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: motivoController,
                        style: TextStyle(color: _textColor),
                        decoration: InputDecoration(
                          labelText: 'Motivo / Referencia',
                          labelStyle: TextStyle(color: _subTextColor),
                          filled: true,
                          fillColor: _isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          prefixIcon: Icon(LucideIcons.textQuote, color: _subTextColor),
                        ),
                      ),
                    ],
                  ),
                  actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  actions: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: _subTextColor.withOpacity(0.3)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: Text('Regresar', style: TextStyle(color: _subTextColor)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: esEntrada ? _accentColor : Colors.deepOrangeAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 4,
                              shadowColor: (esEntrada ? _accentColor : Colors.deepOrangeAccent).withOpacity(0.4),
                            ),
                            onPressed: (vacio || excedido) ? null : () async {
                              final cantidad = int.tryParse(objController.text) ?? 0;
                              final token = context.read<AuthProvider>().token!;
                              String? errorMsg;
                              if (esEntrada) {
                                errorMsg = await context.read<ProductoProvider>().darEntradaStock(token, p.id, cantidad, motivoController.text);
                              } else {
                                errorMsg = await context.read<ProductoProvider>().darSalidaStock(token, p.id, cantidad, motivoController.text);
                              }
                              if (mounted) {
                                Navigator.pop(ctx);
                                if (errorMsg == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(LucideIcons.checkCircle2, color: Colors.white),
                                          const SizedBox(width: 10),
                                          Text('Stock actualizado: ${p.nombre}'),
                                        ],
                                      ),
                                      backgroundColor: Colors.green.shade600,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    )
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
                                }
                                context.read<HistorialProvider>().loadHistorial(token);
                              }
                            },
                            child: Text(esEntrada ? 'Ingresar' : 'Retirar', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    )
                  ],
                );
              }
            ),
          ),
        );
      },
    );
  }

  void _mostrarFormularioProducto([Producto? p]) {
    final nombreController = TextEditingController(text: p?.nombre ?? '');
    final descController = TextEditingController(text: p?.descripcion ?? '');
    final pVentaController = TextEditingController(text: p?.precioUnitarioVenta.toString() ?? '');
    final pCompraController = TextEditingController(text: p?.precioUnitarioCompra.toString() ?? '');
    final stockController = TextEditingController(text: p?.cantidadEnStock.toString() ?? '0');
    bool esInventariado = p?.inventariado ?? true;
    Categoria? categoriaSeleccionada;
    
    // Buscar la categoría actual en la lista cargada
    if (p?.categoria != null) {
      try {
        categoriaSeleccionada = _categorias.firstWhere((c) => c.id == p!.categoria!.id);
      } catch (_) {}
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 350),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut)),
            child: child,
          ),
        );
      },
      pageBuilder: (ctx, anim1, anim2) => StatefulBuilder(
        builder: (ctx, setState) {
          final nom = nombreController.text.trim();
          final vnt = double.tryParse(pVentaController.text) ?? -1;
          final cmp = double.tryParse(pCompraController.text) ?? -1;
          final stk = int.tryParse(stockController.text) ?? -1;

          bool formInvalido = nom.isEmpty || vnt <= 0 || cmp <= 0 || (p == null && stk < 0);

          return AlertDialog(
            backgroundColor: _dialogBg,
            scrollable: true,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Icon(p == null ? LucideIcons.plusCircle : LucideIcons.edit, color: _accentColor, size: 28),
                const SizedBox(width: 12),
                Text(p == null ? 'Nuevo Producto' : 'Editar Producto', style: TextStyle(color: _textColor, fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nombreController,
                    onChanged: (v) => setState((){}),
                    style: TextStyle(color: _textColor),
                    decoration: InputDecoration(
                      labelText: 'Nombre comercial',
                      labelStyle: TextStyle(color: _subTextColor),
                      prefixIcon: Icon(LucideIcons.tag, color: _accentColor),
                      filled: true,
                      fillColor: _isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9áéíóúÁÉÍÓÚñÑ\s]')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Selector de Categoría con botón "+"
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<Categoria>(
                          value: categoriaSeleccionada,
                          dropdownColor: _dialogBg,
                          decoration: InputDecoration(
                            labelText: 'Categoría',
                            labelStyle: TextStyle(color: _subTextColor),
                            prefixIcon: Icon(LucideIcons.layers, color: _accentColor),
                            filled: true,
                            fillColor: _isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          ),
                          items: _categorias.map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.nombre, style: TextStyle(color: _textColor, fontSize: 13)),
                          )).toList(),
                          onChanged: (val) => setState(() => categoriaSeleccionada = val),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Botón para nueva categoría rápida
                      Container(
                        decoration: BoxDecoration(
                          color: _accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(LucideIcons.plus, color: _accentColor),
                          onPressed: () => _mostrarFormularioCategoria(parentSetState: setState),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    style: TextStyle(color: _textColor),
                    decoration: InputDecoration(
                      labelText: 'Descripción detallada',
                      labelStyle: TextStyle(color: _subTextColor),
                      prefixIcon: Icon(LucideIcons.fileText, color: _subTextColor),
                      filled: true,
                      fillColor: _isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    )
                  ),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final isMobile = screenWidth < 500;
                      if (isMobile) {
                        return Column(
                          children: [
                            _buildPrecioField(pCompraController, 'Costo (\$)', Colors.blueAccent, LucideIcons.arrowDownCircle, setState),
                            const SizedBox(height: 16),
                            _buildPrecioField(pVentaController, 'Venta (\$)', Colors.green, LucideIcons.arrowUpCircle, setState),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: _buildPrecioField(pCompraController, 'Costo (\$)', Colors.blueAccent, LucideIcons.arrowDownCircle, setState)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildPrecioField(pVentaController, 'Venta (\$)', Colors.green, LucideIcons.arrowUpCircle, setState)),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  if (p == null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextField(
                        controller: stockController,
                        onChanged: (v) => setState((){}),
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: _textColor),
                        decoration: InputDecoration(
                          labelText: 'Stock Inicial',
                          prefixIcon: Icon(LucideIcons.boxes, color: _subTextColor),
                          filled: true, fillColor: _isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      color: esInventariado ? _accentColor.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: (esInventariado ? _accentColor : Colors.orange).withOpacity(0.3))
                    ),
                    child: SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      title: Text('Producto Inventariado', style: TextStyle(color: _textColor, fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text(
                        esInventariado 
                          ? 'Requiere stock 0 para ser eliminado.' 
                          : 'Se puede eliminar con stock cargado.',
                        style: TextStyle(color: _subTextColor, fontSize: 11)
                      ),
                      value: esInventariado,
                      activeColor: _accentColor,
                      secondary: Icon(esInventariado ? LucideIcons.shieldCheck : LucideIcons.shieldAlert, color: esInventariado ? _accentColor : Colors.orange, size: 20),
                      onChanged: (val) => setState(() => esInventariado = val),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: _subTextColor.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Cancelar', style: TextStyle(color: _subTextColor)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                        shadowColor: _accentColor.withOpacity(0.4),
                      ),
                      onPressed: formInvalido ? null : () async {
                        final token = context.read<AuthProvider>().token!;
                        final nuevo = Producto(
                          id: p?.id ?? 0,
                          nombre: nombreController.text,
                          descripcion: descController.text,
                          precioUnitarioVenta: double.tryParse(pVentaController.text) ?? 0,
                          precioUnitarioCompra: double.tryParse(pCompraController.text) ?? 0,
                          cantidadEnStock: p?.cantidadEnStock ?? (int.tryParse(stockController.text) ?? 0),
                          inventariado: esInventariado,
                          categoria: categoriaSeleccionada,
                        );

                        bool success;
                        if (p == null) {
                          success = await context.read<ProductoProvider>().addProducto(token, nuevo);
                        } else {
                          success = await context.read<ProductoProvider>().editProducto(token, p.id, nuevo);
                        }

                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success ? 'Información guardada correctamente' : 'Error en el servidor al procesar'),
                              backgroundColor: success ? Colors.green : Colors.redAccent,
                              behavior: SnackBarBehavior.floating,
                            )
                          );
                          context.read<HistorialProvider>().loadHistorial(token);
                        }
                      },
                      child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            ],
          );
        }
      ),
    );
  }

  Widget _buildPrecioField(TextEditingController controller, String label, Color color, IconData icon, StateSetter setState) {
    return TextField(
      controller: controller,
      onChanged: (v) => setState((){}),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(color: _textColor, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _subTextColor, fontSize: 13),
        prefixIcon: Icon(icon, color: color, size: 18),
        filled: true,
        fillColor: _isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
    );
  }

  void _eliminarProducto(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _dialogBg,
        title: Text('Confirmar Eliminación', style: TextStyle(color: _textColor)),
        content: Text('¿Estás seguro de que deseas enviar este producto a la Papelera de Reciclaje?', style: TextStyle(color: _subTextColor)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar', style: TextStyle(color: _subTextColor))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          )
        ]
      )
    );
    if (confirmar != true || !mounted) return;

    final token = context.read<AuthProvider>().token!;
    final errorMsg = await context.read<ProductoProvider>().deleteProducto(token, id);
    if (mounted) {
      if (errorMsg == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Producto enviado a la papelera'), 
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          )
        );
        context.read<HistorialProvider>().loadHistorial(token);
      } else {
        _mostrarAlertaError(errorMsg);
      }
    }
  }

  void _mostrarAlertaError(String mensaje) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: AlertDialog(
              backgroundColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
              content: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
                  ],
                  border: Border.all(color: Colors.redAccent.withOpacity(0.5), width: 1.5)
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(LucideIcons.alertCircle, color: Colors.redAccent, size: 40),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Acción Bloqueada',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      mensaje,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _textColor, fontSize: 15, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Entendido', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _mostrarFormularioCategoria({Categoria? cat, StateSetter? parentSetState}) {
    final nameController = TextEditingController(text: cat?.nombre ?? '');
    final stockMinController = TextEditingController(text: cat?.stockMinimo.toString() ?? '5');
    final isEditing = cat != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(isEditing ? LucideIcons.edit : LucideIcons.plusCircle, color: _accentColor, size: 24),
            const SizedBox(width: 12),
            Text(isEditing ? 'Editar Categoría' : 'Nueva Categoría', style: TextStyle(color: _textColor, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: !isEditing,
              style: TextStyle(color: _textColor),
              decoration: InputDecoration(
                labelText: 'Nombre de la categoría',
                labelStyle: TextStyle(color: _subTextColor),
                filled: true,
                fillColor: _isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: stockMinController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: _textColor),
              decoration: InputDecoration(
                labelText: 'Stock Mínimo Alerta',
                labelStyle: TextStyle(color: _subTextColor),
                prefixIcon: Icon(LucideIcons.alertTriangle, color: Colors.orangeAccent, size: 18),
                filled: true,
                fillColor: _isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: _subTextColor.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancelar', style: TextStyle(color: _subTextColor)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    final data = Categoria(
                      id: cat?.id,
                      nombre: nameController.text.trim(),
                      stockMinimo: int.tryParse(stockMinController.text) ?? 5,
                    );
                    try {
                      final token = context.read<AuthProvider>().token!;
                      if (isEditing) {
                        await CategoriaService.updateCategoria(cat.id!, data, token);
                      } else {
                        await CategoriaService.createCategoria(data, token);
                      }
                      await _cargarCategorias(); // Refrescar lista global
                      if (parentSetState != null) parentSetState(() {}); // Refrescar diálogo de producto si es necesario
                      if (mounted) Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEditing ? 'Categoría actualizada' : 'Categoría creada')));
                      
                      // IMPORTANTE: Recargar productos para reflejar el nuevo stock mínimo en las alertas
                      context.read<ProductoProvider>().loadProductos(token);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
                    }
                  },
                  child: Text(isEditing ? 'Guardar' : 'Crear', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        ],
      )
    );
  }

  void _eliminarCategoria(Categoria cat) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _dialogBg,
        title: const Text('Eliminar Categoría'),
        content: Text('¿Deseas eliminar "${cat.nombre}"?\nNota: Los productos asociados volverán al umbral por defecto (5).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar', style: TextStyle(color: _subTextColor))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          )
        ],
      )
    );

    if (confirmar != true || !mounted) return;

    try {
      final token = context.read<AuthProvider>().token!;
      await CategoriaService.deleteCategoria(cat.id!, token);
      await _cargarCategorias();
      context.read<ProductoProvider>().loadProductos(token);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Categoría eliminada')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
    }
  }

  void _mostrarStockCritico(List<Producto> criticos) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: AlertDialog(
              backgroundColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              content: Container(
                width: 400,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
                  ],
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 1.5)
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(LucideIcons.alertOctagon, color: Colors.redAccent, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Stock Crítico',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(LucideIcons.x, color: _subTextColor, size: 18),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                      child: criticos.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Text('Todo el inventario está sano', style: TextStyle(color: _subTextColor), textAlign: TextAlign.center),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: criticos.length,
                            itemBuilder: (c, i) {
                              final p = criticos[i];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _isDark ? Colors.white.withOpacity(0.03) : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.redAccent.withOpacity(0.1))
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(p.nombre, style: TextStyle(color: _textColor, fontWeight: FontWeight.w600, fontSize: 13)),
                                          Text('Disponible: ${p.cantidadEnStock} / Umbral: ${p.categoria?.stockMinimo ?? 5}', 
                                            style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        _mostrarDialogoStock(p, true);
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(color: _accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                        child: Icon(LucideIcons.plusCircle, color: _accentColor, size: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${criticos.length} productos requieren atención inmediata',
                      style: TextStyle(color: _subTextColor, fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ----------- VISTA 1: RESUMEN -----------
  Widget _buildSummaryCards(List<Producto> productos) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A2730);
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF5A7080);

    if (productos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text('No hay datos para el resumen. Agrega productos al inventario.', textAlign: TextAlign.center, style: TextStyle(color: subTextColor, fontSize: 18)),
        ),
      );
    }

    final totalCat = productos.length;
    final totalUnidades = productos.fold<int>(0, (sum, p) => sum + p.cantidadEnStock);
    final valorGlobal = productos.fold<double>(0.0, (sum, p) => sum + (p.cantidadEnStock * p.precioUnitarioVenta));
    final criticos = productos.where((p) => p.cantidadEnStock < (p.categoria?.stockMinimo ?? 5)).toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth;
        int crossAxisCount = ancho > 1000 ? 5 : (ancho > 700 ? 4 : (ancho > 350 ? 2 : 1));
        double ratio = ancho > 1000 ? 1.5 : (ancho > 800 ? 1.3 : (ancho > 600 ? 1.1 : (ancho > 350 ? 1.05 : 2.0)));

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Resumen General', style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: ratio,
                children: [
                  _buildCardInfo(LucideIcons.packageSearch, 'Catálogo', '$totalCat', Colors.purpleAccent, subtitle: 'ítems'),
                  _buildCardInfo(LucideIcons.alertOctagon, 'Crítico', '${criticos.length}', Colors.redAccent, subtitle: 'ítems', onTap: () => _mostrarStockCritico(criticos)),
                  _buildCardInfo(LucideIcons.boxes, 'Físico', '$totalUnidades', isDark ? Colors.cyanAccent : AppTheme.sageDark, subtitle: 'unid'),
                  _buildCardInfo(LucideIcons.badgeDollarSign, 'Valor Total', '\$${valorGlobal.toStringAsFixed(2)}', isDark ? Colors.greenAccent : const Color(0xFF2E8B57)),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildCardInfo(IconData icon, String title, String value, Color color, {String? subtitle, VoidCallback? onTap}) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A); // Slate 900
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF64748B); // Slate 500
    final shadowColor = isDark ? Colors.black45 : color.withOpacity(0.12);

    final child = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.1) : Colors.white,
        gradient: !isDark ? LinearGradient(
          colors: [Colors.white, color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ) : null,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: color.withOpacity(isDark ? 0.3 : 0.4), 
          width: isDark ? 1.5 : 1.2
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor, 
            blurRadius: 20, 
            offset: const Offset(0, 8),
            spreadRadius: -2
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(isDark ? 0.2 : 0.1), 
                  borderRadius: BorderRadius.circular(16)
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              if (onTap != null)
                Icon(LucideIcons.chevronRight, color: subTextColor.withOpacity(0.5), size: 18)
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title.toUpperCase(), 
                style: TextStyle(color: subTextColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5), 
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(value, style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                    if (subtitle != null) ...[
                      const SizedBox(width: 4),
                      Text(subtitle, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (onTap == null) return child;
    return Material(
      color: Colors.transparent, 
      child: InkWell(
        onTap: onTap, 
        borderRadius: BorderRadius.circular(28), 
        splashColor: color.withOpacity(0.1),
        child: child
      )
    );
  }

  // ----------- VISTA 2: LISTA TRADICIONAL -----------
  Widget _buildProductosList(List<Producto> productos, bool isAdmin) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A2730);
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF5A7080);
    final accentColor = isDark ? AppTheme.sageLight : AppTheme.sageDark;
    final cardBg = isDark ? Colors.white.withOpacity(0.06) : Colors.white;
    final cardBorder = isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200;
    final iconEditColor = isDark ? Colors.white70 : Colors.grey.shade600;

    // APLICAR FILTRO
    final listaFiltrada = productos.where((p) {
      final cumpleFiltro = _filtroProducto == 'TODOS' ||
          (_filtroProducto == 'INVENTARIADO' && p.inventariado) ||
          (_filtroProducto == 'NO_INVENTARIADO' && !p.inventariado);
      final cumpleBusqueda = p.nombre.toLowerCase().contains(_busqueda.toLowerCase());
      return cumpleFiltro && cumpleBusqueda;
    }).toList();

    return Column(
      children: [
        // BUSCADOR (Standalone)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _busqueda = v),
            style: TextStyle(color: textColor, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Buscar producto...',
              hintStyle: TextStyle(color: subTextColor.withOpacity(0.5)),
              prefixIcon: Icon(LucideIcons.search, size: 18, color: accentColor),
              filled: true,
              fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: accentColor.withOpacity(0.5), width: 1)),
            ),
          ),
        ),
        // FILTROS (Independientes)
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildFilterChipProd('TODOS', 'Todos', LucideIcons.layers),
              const SizedBox(width: 8),
              _buildFilterChipProd('INVENTARIADO', 'Inventariables', LucideIcons.shieldCheck),
              const SizedBox(width: 8),
              _buildFilterChipProd('NO_INVENTARIADO', 'Servicios', LucideIcons.shieldOff),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade200),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: listaFiltrada.isEmpty
              ? Center(
                  key: ValueKey('empty_$_filtroProducto'),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, 
                    children: [
                      Icon(LucideIcons.searchX, size: 80, color: isDark ? Colors.white24 : Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        "No se encontraron productos\npara el filtro seleccionado", 
                        textAlign: TextAlign.center, 
                        style: TextStyle(color: subTextColor, fontSize: 16)
                      ),
                    ]
                  )
                )
              : LayoutBuilder(
                  key: ValueKey('grid_$_filtroProducto'),
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    int crossAxisCount = width > 1400 ? 5 : (width > 1100 ? 4 : (width > 800 ? 3 : 2));
                    // Equilibrando ancho y alto para evitar que se vean muy estiradas (Slim/Compact)
                    double childAspectRatio = width > 1100 ? 1.5 : (width > 800 ? 1.4 : (width > 500 ? 1.3 : 0.88));
                    if (width < 380) childAspectRatio = 0.82; 

                    return GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: childAspectRatio,
                      ),
                      itemCount: listaFiltrada.length,
                      itemBuilder: (ctx, i) => _ProductoItemCard(
                        producto: listaFiltrada[i],
                        isAdmin: isAdmin,
                        onEdit: () => _mostrarFormularioProducto(listaFiltrada[i]),
                        onAddStock: () => _mostrarDialogoStock(listaFiltrada[i], true),
                        onRemoveStock: () => _mostrarDialogoStock(listaFiltrada[i], false),
                        onDelete: () => _eliminarProducto(listaFiltrada[i].id),
                      ),
                    );
                  },
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildCircleBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildFilterChipProd(String valor, String label, IconData icon) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final isSelected = _filtroProducto == valor;
    final accentColor = isDark ? AppTheme.sageLight : AppTheme.sageDark;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isSelected ? Colors.white : (isDark ? Colors.white54 : Colors.grey)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF4A6070)), fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
      selected: isSelected,
      selectedColor: accentColor,
      showCheckmark: false,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
      side: BorderSide(color: isSelected ? accentColor : (isDark ? Colors.white10 : Colors.grey.shade300)),
      onSelected: (val) {
        if (val) setState(() => _filtroProducto = valor);
      },
    );
  }

  // ----------- VISTA 3: HISTORIAL (BITÁCORA) -----------
  Widget _buildFilterChip(String valor, String label) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final isSelected = _filtroHistorial == valor;
    final accentColor = isDark ? AppTheme.sageLight : AppTheme.sageDark;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF4A6070)), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: accentColor,
      backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade100,
      onSelected: (val) {
        if (val) setState(() => _filtroHistorial = valor);
      },
    );
  }

  Widget _buildHistorialList() {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.usuario?.rol == 'ADMIN';
    final isDark = context.watch<ThemeProvider>().isDark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A2730);
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF5A7080);
    final accentColor = isDark ? AppTheme.sageLight : AppTheme.sageDark;
    final histProvider = context.watch<HistorialProvider>();
    final registros = histProvider.registros;
    final isLoading = histProvider.isLoading;
    final errorMsg = histProvider.error;

    if (isLoading && registros.isEmpty) {
      return Center(child: CircularProgressIndicator(color: accentColor));
    }

    if (errorMsg != null && registros.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertTriangle, color: Colors.redAccent, size: 60),
            const SizedBox(height: 20),
            Text('Error: $errorMsg', style: const TextStyle(color: Colors.redAccent)),
          ],
        )
      );
    }

    final listaFiltrada = registros.where((r) {
      final cumpleAccion = _filtroHistorial == 'TODOS' || r.accion == _filtroHistorial;
      bool cumpleFecha = true;
      if (_fechaInicio != null && _fechaFin != null) {
        // Normalizar fechas para comparar solo días (opcional) o usar timestamp completo
        // Aquí comparamos si está en el rango [inicio, fin] inclusive
        final d = r.createdAt;
        final start = DateTime(_fechaInicio!.year, _fechaInicio!.month, _fechaInicio!.day);
        final end = DateTime(_fechaFin!.year, _fechaFin!.month, _fechaFin!.day, 23, 59, 59);
        cumpleFecha = d.isAfter(start) && d.isBefore(end);
      }
      return cumpleAccion && cumpleFecha;
    }).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.shade50),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Selector de Fecha
                InkWell(
                  onTap: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      initialDateRange: (_fechaInicio != null && _fechaFin != null) 
                          ? DateTimeRange(start: _fechaInicio!, end: _fechaFin!)
                          : null,
                      firstDate: DateTime(2023),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: isDark ? ColorScheme.dark(primary: accentColor, onPrimary: Colors.white, surface: const Color(0xFF1E293B)) : ColorScheme.light(primary: accentColor),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setState(() {
                        _fechaInicio = picked.start;
                        _fechaFin = picked.end;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: (_fechaInicio != null) ? accentColor.withOpacity(0.15) : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: (_fechaInicio != null) ? accentColor : (isDark ? Colors.white10 : Colors.grey.shade300)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.calendar, size: 16, color: (_fechaInicio != null) ? accentColor : subTextColor),
                        const SizedBox(width: 8),
                        Text(
                          (_fechaInicio != null) 
                              ? '${_fechaInicio!.day}/${_fechaInicio!.month} - ${_fechaFin!.day}/${_fechaFin!.month}'
                              : 'Filtrar Fecha',
                          style: TextStyle(color: (_fechaInicio != null) ? accentColor : subTextColor, fontSize: 12, fontWeight: (_fechaInicio != null) ? FontWeight.bold : FontWeight.normal),
                        ),
                        if (_fechaInicio != null) ...[
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => setState(() { _fechaInicio = null; _fechaFin = null; }),
                            child: Icon(LucideIcons.x, size: 14, color: accentColor),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _buildFilterChip('TODOS', 'Todos'),
                const SizedBox(width: 8),
                _buildFilterChip('CREACION', 'Creados'),
                const SizedBox(width: 8),
                _buildFilterChip('EDICION', 'Editados'),
                const SizedBox(width: 8),
                _buildFilterChip('ENTRADA', 'Entradas'),
                const SizedBox(width: 8),
                _buildFilterChip('SALIDA', 'Salidas'),
                const SizedBox(width: 8),
                _buildFilterChip('ELIMINACION', 'Eliminados'),
                const SizedBox(width: 8),
                _buildFilterChip('RESTAURACION', 'Restaurados'),
                const SizedBox(width: 16),
                // Botón Limpiar Todo (Solo Admin)
                if (isAdmin)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.1),
                      foregroundColor: Colors.redAccent,
                      elevation: 0,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: () => _confirmarLimpiarHistorial(),
                    icon: const Icon(LucideIcons.trash2, size: 14),
                    label: const Text('Limpiar Todo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: listaFiltrada.isEmpty
              ? Center(child: Text('No hay registros en bitácora para este filtro', style: TextStyle(color: subTextColor)))
              : ListView.builder(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: listaFiltrada.length,
                  itemBuilder: (ctx, i) {
                    final r = listaFiltrada[i];

                    Color colorExtra;
                    IconData icon;
                    switch (r.accion) {
                      case 'CREACION': colorExtra = Colors.green; icon = LucideIcons.plusSquare; break;
                      case 'EDICION': colorExtra = Colors.blueAccent; icon = LucideIcons.edit; break;
                      case 'ELIMINACION': colorExtra = Colors.redAccent; icon = LucideIcons.trash2; break;
                      case 'ENTRADA': colorExtra = isDark ? Colors.cyanAccent : AppTheme.sageDark; icon = LucideIcons.packagePlus; break;
                      case 'SALIDA': colorExtra = Colors.deepOrangeAccent; icon = LucideIcons.packageMinus; break;
                      case 'RESTAURACION': colorExtra = isDark ? Colors.tealAccent : AppTheme.sage; icon = LucideIcons.rotateCcw; break;
                      default: colorExtra = textColor; icon = LucideIcons.info;
                    }

                    final dateStr = '${r.createdAt.day.toString().padLeft(2,'0')}/${r.createdAt.month.toString().padLeft(2,'0')}/${r.createdAt.year} a las ${r.createdAt.hour.toString().padLeft(2,'0')}:${r.createdAt.minute.toString().padLeft(2,'0')}';

                    return Card(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: colorExtra.withOpacity(0.3))),
                      elevation: isDark ? 4 : 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorExtra.withOpacity(0.15),
                          child: Icon(icon, color: colorExtra),
                        ),
                        title: Text(r.detalles, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text('Por ${r.usuarioNombre} • $dateStr', style: TextStyle(color: subTextColor, fontSize: 13)),
                        ),
                        trailing: isAdmin ? IconButton(
                          icon: Icon(LucideIcons.trash2, color: Colors.redAccent.withOpacity(0.5), size: 18),
                          onPressed: () => _confirmarEliminarEntrada(r),
                        ) : null,
                      ),
                    );
                  },
                ),
        )
      ],
    );
  }

  // ----------- VISTA 5: FACTURAS (BFF & CIRCUIT BREAKER) -----------
  Widget _buildFacturasList() {
    final isDark = context.watch<ThemeProvider>().isDark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A2730);
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF5A7080);
    final accentColor = isDark ? AppTheme.sageLight : AppTheme.sageDark;
    final factProv = context.watch<FacturaProvider>();
    final facturas = factProv.facturas;

    if (factProv.isLoading && facturas.isEmpty) {
      return Center(child: CircularProgressIndicator(color: accentColor));
    }

    if (factProv.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: factProv.isEnMantenimiento ? Colors.blue.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: factProv.isEnMantenimiento ? Colors.blueAccent : Colors.redAccent),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(factProv.isEnMantenimiento ? LucideIcons.hammer : LucideIcons.shieldAlert, color: factProv.isEnMantenimiento ? Colors.blueAccent : Colors.redAccent, size: 80),
                const SizedBox(height: 20),
                Text(factProv.error!, style: TextStyle(color: subTextColor, height: 1.5, fontSize: 18), textAlign: TextAlign.center),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: accentColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15)),
                  onPressed: () {
                    final token = context.read<AuthProvider>().token;
                    if (token != null) context.read<FacturaProvider>().loadFacturas(token);
                  },
                  icon: const Icon(LucideIcons.refreshCw),
                  label: const Text('Reintentar Conexión', style: TextStyle(fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final token = context.read<AuthProvider>().token;
        if (token != null) await context.read<FacturaProvider>().loadFacturas(token);
      },
      child: facturas.isEmpty && factProv.error == null
        ? ListView(
            children: [
              const SizedBox(height: 100),
              Center(child: Text('No hay facturas', style: TextStyle(color: subTextColor))),
            ],
          )
        : ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: facturas.length,
            itemBuilder: (ctx, i) {
              final f = facturas[i];
              return Card(
                color: isDark ? Colors.blueAccent.withOpacity(0.05) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.blueAccent.withOpacity(0.3))),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.transparent, child: Icon(LucideIcons.fileText, color: Colors.blueAccent)),
                  title: Text('${f['codigo']} - ${f['concepto']}', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                  subtitle: Text('Fecha: ${f['fecha']}', style: TextStyle(color: subTextColor)),
                  trailing: Text('\$${f['monto']}', style: TextStyle(color: isDark ? Colors.greenAccent : const Color(0xFF2E8B57), fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              );
            },
          ),
    );
  }

  // ----------- VISTA 4: PAPELERA DE RECICLAJE -----------
  Widget _buildPapeleraList() {
    final isDark = context.watch<ThemeProvider>().isDark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A2730);
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF5A7080);
    final accentColor = isDark ? AppTheme.sageLight : AppTheme.sageDark;
    final prodProv = context.watch<ProductoProvider>();
    final borrados = prodProv.borrados;

    if (prodProv.isLoading && borrados.isEmpty) {
      return Center(child: CircularProgressIndicator(color: accentColor));
    }

    if (borrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.leaf, size: 80, color: accentColor),
            const SizedBox(height: 20),
            Text('La papelera está vacía', style: TextStyle(color: subTextColor, fontSize: 18)),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: borrados.length,
      itemBuilder: (ctx, i) {
        final p = borrados[i];
        return Card(
          color: isDark ? Colors.redAccent.withOpacity(0.05) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.redAccent.withOpacity(0.3))),
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.transparent, child: Icon(LucideIcons.packageX, color: Colors.redAccent)),
            title: Text(p.nombre, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, decoration: TextDecoration.lineThrough)),
            subtitle: Text('Precio: \$${p.precioUnitarioVenta.toStringAsFixed(2)} | Stock retenido: ${p.cantidadEnStock}', style: TextStyle(color: subTextColor)),
            trailing: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: accentColor, foregroundColor: Colors.white),
              onPressed: () async {
                final token = context.read<AuthProvider>().token!;
                final success = await context.read<ProductoProvider>().restaurarProducto(token, p.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Producto Restaurado Exitosamente' : 'Error al restaurar'), backgroundColor: success ? Colors.green : Colors.redAccent));
                  if (success) context.read<HistorialProvider>().loadHistorial(token);
                }
              },
              icon: const Icon(LucideIcons.rotateCcw, size: 18),
              label: const Text('Restaurar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        );
      },
    );
  }

  // ----------- VISTA 5: GESTIÓN DE CATEGORÍAS -----------
  Widget _buildCategoriasList() {
    final isDark = context.watch<ThemeProvider>().isDark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A2730);
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF5A7080);
    final accentColor = isDark ? AppTheme.sageLight : AppTheme.sageDark;

    if (_categorias.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.layers, size: 80, color: accentColor.withOpacity(0.5)),
            const SizedBox(height: 20),
            Text('No hay categorías creadas.', style: TextStyle(color: subTextColor, fontSize: 18)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _mostrarFormularioCategoria(),
              child: const Text('Crear Primera Categoría'),
            )
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _categorias.length,
      itemBuilder: (ctx, i) {
        final cat = _categorias[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: accentColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(LucideIcons.layers, color: accentColor, size: 22),
            ),
            title: Text(cat.nombre, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text('Stock Mínimo Alerta: ${cat.stockMinimo}', style: TextStyle(color: subTextColor, fontSize: 14)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(LucideIcons.edit, color: subTextColor, size: 20),
                  onPressed: () => _mostrarFormularioCategoria(cat: cat),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 20),
                  onPressed: () => _eliminarCategoria(cat),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ----------- WIDGET PRINCIPAL -----------
  @override
  Widget build(BuildContext context) {
    final prodProvider = context.watch<ProductoProvider>();
    final productos = prodProvider.productos;
    final usuario = context.watch<AuthProvider>().usuario;
    final isAdmin = usuario?.rol == 'ADMIN';
    final isLoadingProd = prodProvider.isLoading;
    final errorMsgProd = prodProvider.error;
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark;
    final theme = Theme.of(context);

    // === COLORES ADAPTATIVOS AL TEMA ===
    final scaffoldBg = theme.scaffoldBackgroundColor;
    final textColor = isDark ? Colors.white : const Color(0xFF1A2730);
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF5A7080);
    final accentColor = isDark ? AppTheme.sageLight : AppTheme.sageDark;
    final appBarGradient = isDark
        ? const [Color(0xFF0F2230), Color(0xFF162E42)]
        : [const Color(0xFF4A8C6E), const Color(0xFF3A7A5E)];
    final drawerBg = isDark ? const Color(0xFF132030) : Colors.white;
    final drawerHeaderGradient = isDark
        ? const [Color(0xFF0F2230), Color(0xFF1B3D54)]
        : [const Color(0xFF4A8C6E), const Color(0xFF6DB390)];
    final drawerTextColor = isDark ? Colors.white : const Color(0xFF2A3A4A);
    final drawerIconColor = isDark ? Colors.white70 : const Color(0xFF5A7080);
    final drawerSelectedBg = isDark ? Colors.white.withOpacity(0.1) : AppTheme.sage.withOpacity(0.15);
    final dividerColor = isDark ? Colors.white24 : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: appBarGradient),
          ),
        ),
        title: Text(
          _indiceActual == 0 ? 'Resumen TWS2'
          : _indiceActual == 1 ? 'Inventario Detallado'
          : _indiceActual == 2 ? 'Bitácora de Auditoría'
          : _indiceActual == 3 ? 'Papelera de Reciclaje'
          : _indiceActual == 4 ? 'Facturas' : 'Gestión de Categorías',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              tooltip: isDark ? 'Cambiar a Modo Claro' : 'Cambiar a Modo Oscuro',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  key: ValueKey(isDark),
                  color: Colors.white,
                  size: 22,
                ),
              ),
              onPressed: () => context.read<ThemeProvider>().toggle(),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: drawerBg,
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: drawerHeaderGradient),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(LucideIcons.userCircle2, size: 60, color: isDark ? AppTheme.sageLight : Colors.white),
                  const SizedBox(height: 10),
                  Text('${usuario?.nombre ?? ""}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('Rol: ${usuario?.rol ?? ""}', style: TextStyle(color: Colors.white.withOpacity(0.8))),
                ],
              ),
            ),
            ListTile(
              leading: Icon(LucideIcons.barChart3, color: drawerIconColor),
              title: Text('Resumen General', style: TextStyle(color: drawerTextColor)),
              selected: _indiceActual == 0,
              selectedTileColor: drawerSelectedBg,
              onTap: () => _seleccionarMenu(0),
            ),
            ListTile(
              leading: Icon(LucideIcons.package2, color: drawerIconColor),
              title: Text('Inventario de Productos', style: TextStyle(color: drawerTextColor)),
              selected: _indiceActual == 1,
              selectedTileColor: drawerSelectedBg,
              onTap: () => _seleccionarMenu(1),
            ),
            if (isAdmin)
              ListTile(
                leading: Icon(LucideIcons.history, color: drawerIconColor),
                title: Text('Historial y Auditoría', style: TextStyle(color: drawerTextColor)),
                selected: _indiceActual == 2,
                selectedTileColor: drawerSelectedBg,
                onTap: () => _seleccionarMenu(2),
              ),
            ListTile(
              leading: Icon(LucideIcons.fileText, color: Colors.blueAccent),
              title: Text('Facturación (BFF)', style: TextStyle(color: drawerTextColor)),
              selected: _indiceActual == 4,
              selectedTileColor: drawerSelectedBg,
              onTap: () => _seleccionarMenu(4),
            ),
            ListTile(
              leading: Icon(LucideIcons.layers, color: Colors.orangeAccent),
              title: Text('Gestión de Categorías', style: TextStyle(color: drawerTextColor)),
              selected: _indiceActual == 5,
              selectedTileColor: drawerSelectedBg,
              onTap: () => _seleccionarMenu(5),
            ),
            if (isAdmin)
              ListTile(
                leading: const Icon(LucideIcons.trash2, color: Colors.redAccent),
                title: Text('Papelera de Reciclaje', style: TextStyle(color: drawerTextColor)),
                selected: _indiceActual == 3,
                selectedTileColor: drawerSelectedBg,
                onTap: () => _seleccionarMenu(3),
              ),
            Divider(color: dividerColor),
            ListTile(
              leading: const Icon(LucideIcons.logOut, color: Colors.redAccent),
              title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                context.read<AuthProvider>().logout();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
            ),
          ],
        ),
      ),
      floatingActionButton: (_indiceActual == 1 && isAdmin)
        ? FloatingActionButton.extended(
            backgroundColor: accentColor,
            icon: const Icon(LucideIcons.plus, color: Colors.white),
            label: const Text('Crear Producto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () => _mostrarFormularioProducto(),
          )
        : (_indiceActual == 5)
            ? FloatingActionButton.extended(
                backgroundColor: Colors.orangeAccent,
                icon: const Icon(LucideIcons.plusCircle, color: Colors.white),
                label: const Text('Nueva Categoría', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: () => _mostrarFormularioCategoria(),
              )
            : null,
      body: _indiceActual == 5
          ? _buildCategoriasList()
          : _indiceActual == 4
              ? _buildFacturasList()
              : _indiceActual == 3
                  ? _buildPapeleraList()
                  : _indiceActual == 2
                      ? _buildHistorialList()
              : (isLoadingProd && productos.isEmpty)
                  ? Center(child: CircularProgressIndicator(color: accentColor))
                  : errorMsgProd != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(color: Colors.orangeAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.orangeAccent.withOpacity(0.5))),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.alertTriangle, color: Colors.orangeAccent, size: 80),
                                  const SizedBox(height: 20),
                                  Text(errorMsgProd, style: TextStyle(color: subTextColor, height: 1.5, fontSize: 16), textAlign: TextAlign.center),
                                  const SizedBox(height: 30),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15)),
                                    onPressed: () {
                                      final token = context.read<AuthProvider>().token;
                                      if (token != null) context.read<ProductoProvider>().loadProductos(token);
                                    },
                                    icon: const Icon(LucideIcons.refreshCw),
                                    label: const Text('Recargar Ahora', style: TextStyle(fontWeight: FontWeight.bold)),
                                  )
                                ],
                              ),
                            ),
                          ),
                        )
                      : _indiceActual == 0
                          ? _buildSummaryCards(productos)
                          : _buildProductosList(productos, isAdmin),
    );
  }

  void _confirmarEliminarEntrada(HistorialLog r) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _dialogBg,
        title: const Text('Eliminar Registro'),
        content: Text('¿Deseas borrar permanentemente este registro de la bitácora?\n\n"${r.detalles}"'),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: _subTextColor.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancelar', style: TextStyle(color: _subTextColor)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                  onPressed: () {
                    final token = context.read<AuthProvider>().token!;
                    context.read<HistorialProvider>().deleteEntry(token, r.id);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registro eliminado')));
                  },
                  child: const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        ],
      )
    );
  }

  void _confirmarLimpiarHistorial() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _dialogBg,
        title: const Text('Limpiar Bitácora'),
        content: const Text('¿Estás seguro de que deseas borrar TODOS los registros del historial? Esta acción no se puede deshacer.'),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: _subTextColor.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancelar', style: TextStyle(color: _subTextColor)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                  onPressed: () {
                    final token = context.read<AuthProvider>().token!;
                    context.read<HistorialProvider>().clearAll(token);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Historial limpiado correctamente')));
                  },
                  child: const Text('Limpiar Todo', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        ],
      )
    );
  }
}

class _ProductoItemCard extends StatefulWidget {
  final Producto producto;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onAddStock;
  final VoidCallback onRemoveStock;
  final VoidCallback onDelete;

  const _ProductoItemCard({
    required this.producto,
    required this.isAdmin,
    required this.onEdit,
    required this.onAddStock,
    required this.onRemoveStock,
    required this.onDelete,
  });

  @override
  State<_ProductoItemCard> createState() => _ProductoItemCardState();
}

class _ProductoItemCardState extends State<_ProductoItemCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final p = widget.producto;
    
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF64748B);
    final accentColor = isDark ? AppTheme.sageLight : AppTheme.sageDark;
    final cardBg = isDark ? Colors.white.withOpacity(0.06) : Colors.white;
    final iconEditColor = isDark ? Colors.white70 : Colors.grey.shade600;

    final glowColor = p.cantidadEnStock > 0 
        ? (p.inventariado ? accentColor : Colors.blueAccent)
        : Colors.redAccent;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _isHovered 
                    ? glowColor.withOpacity(isDark ? 0.3 : 0.15) 
                    : Colors.black.withOpacity(0.05),
                blurRadius: _isHovered ? 20 : 10,
                offset: Offset(0, _isHovered ? 8 : 4),
                spreadRadius: _isHovered ? 2 : -2,
              )
            ],
          ),
          child: Card(
            margin: EdgeInsets.zero,
            color: cardBg,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: _isHovered ? glowColor.withOpacity(0.4) : (isDark ? Colors.white10 : Colors.grey.shade100),
                width: _isHovered ? 1.5 : 1.0,
              ),
            ),
            child: InkWell(
              onTap: widget.onEdit,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Cabecera: Nombre y Badge de Tipo
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            p.nombre, 
                            style: TextStyle(
                              fontWeight: FontWeight.w900, 
                              color: textColor, 
                              fontSize: 13,
                              letterSpacing: -0.5
                            ), 
                            maxLines: 2, 
                            overflow: TextOverflow.ellipsis
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (p.categoria != null)
                          _buildBadge(
                            p.categoria!.nombre.toUpperCase(), 
                            isDark ? Colors.cyanAccent : Colors.blueGrey
                          ),
                        const SizedBox(width: 4),
                        _buildBadge(
                          p.inventariado ? "INV" : "SERV", 
                          p.inventariado ? accentColor : Colors.orangeAccent
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Precio con estilo monetario destacado
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '\$${p.precioUnitarioVenta.toStringAsFixed(2)}', 
                            style: TextStyle(
                              color: accentColor, 
                              fontWeight: FontWeight.w800, 
                              fontSize: 12,
                              fontFamily: 'Courier' 
                            )
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (p.cantidadEnStock < (p.categoria?.stockMinimo ?? 5))
                          Tooltip(
                            message: 'Stock Crítico (Mín: ${p.categoria?.stockMinimo ?? 5})',
                            child: Icon(
                              LucideIcons.alertTriangle, 
                              size: 14, 
                              color: p.inventariado ? Colors.orangeAccent.withOpacity(0.8) : Colors.cyanAccent.withOpacity(0.8)
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Descripción minimalista
                    if (p.descripcion.isNotEmpty)
                      Text(
                        p.descripcion, 
                        style: TextStyle(color: subTextColor, height: 1.2, fontSize: 10, fontStyle: FontStyle.italic), 
                        maxLines: 2, 
                        overflow: TextOverflow.ellipsis
                      ),
                    const Spacer(),
                    // Barra de Acciones con soporte para Wrap en pantallas pequeñas
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Stock Circle Integrado (Lado Izquierdo)
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (p.cantidadEnStock > 0 ? Colors.green : Colors.red).withOpacity(0.2),
                                  blurRadius: 8,
                                )
                              ],
                              gradient: LinearGradient(
                                colors: p.cantidadEnStock > 0 
                                  ? [Colors.green.shade400, Colors.green.shade700] 
                                  : [Colors.red.shade400, Colors.red.shade700]
                              ),
                            ),
                            child: Center(
                              child: Text(
                                p.cantidadEnStock.toString(),
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)
                              ),
                            ),
                          ),
                          // Acciones ergonómicas simplificadas (Lado Derecho)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildActionBtn(LucideIcons.minusSquare, Colors.deepOrangeAccent, widget.onRemoveStock),
                              const SizedBox(width: 6),
                              _buildActionBtn(LucideIcons.plusSquare, Colors.greenAccent, widget.onAddStock),
                              if (widget.isAdmin) ...[
                                const SizedBox(width: 6),
                                _buildActionBtn(LucideIcons.moreHorizontal, subTextColor, () {
                                  _showQuickMenu(context, p);
                                }),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showQuickMenu(BuildContext context, Producto p) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B).withOpacity(0.95) : Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 15),
              )
            ],
            border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
          ),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      color: (isDark ? AppTheme.sageLight : AppTheme.sageDark).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(LucideIcons.settings2, color: isDark ? AppTheme.sageLight : AppTheme.sageDark, size: 24),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    p.nombre, 
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: isDark ? Colors.white : Colors.black87)
                  ),
                  const SizedBox(height: 8),
                  Text('Gestión de Producto', style: TextStyle(color: isDark ? Colors.white60 : Colors.grey, fontSize: 12)),
                  const SizedBox(height: 24),
                  _buildMenuOption(
                    ctx, 
                    Icon(LucideIcons.edit3, color: Colors.blueAccent), 
                    'Editar Información',
                    () { Navigator.pop(ctx); widget.onEdit(); }
                  ),
                  const SizedBox(height: 12),
                  _buildMenuOption(
                    ctx, 
                    Icon(LucideIcons.trash2, color: Colors.redAccent), 
                    'Eliminar de Inventario',
                    () { Navigator.pop(ctx); widget.onDelete(); }
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Cerrar', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOption(BuildContext context, Widget icon, String title, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
            const Icon(LucideIcons.chevronRight, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2), width: 0.5)
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}
