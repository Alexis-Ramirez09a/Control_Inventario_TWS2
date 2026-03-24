import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/producto.dart';
import '../../models/historial.dart';
import '../../providers/auth_provider.dart';
import '../../providers/producto_provider.dart';
import '../../providers/historial_provider.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _indiceActual = 0; // 0 = Resumen, 1 = Productos, 2 = Historial, 3 = Papelera
  String _filtroHistorial = 'TODOS';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token;
      if (token != null) {
        context.read<ProductoProvider>().loadProductos(token);
      }
    });
  }

  void _mostrarDialogoStock(int productoId, bool esEntrada) {
    final objController = TextEditingController();
    final motivoController = TextEditingController(text: esEntrada ? 'Entrada manual' : 'Despacho');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF203A43),
        title: Row(
          children: [
            Icon(esEntrada ? LucideIcons.packagePlus : LucideIcons.packageMinus, color: esEntrada ? Colors.greenAccent : Colors.deepOrangeAccent),
            const SizedBox(width: 8),
            Text(esEntrada ? 'Entrada de Stock' : 'Salida de Stock', style: const TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: objController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Cantidad', labelStyle: TextStyle(color: Colors.white70)),
            ),
            TextField(
              controller: motivoController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Motivo (opcional)', labelStyle: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: esEntrada ? Colors.greenAccent : Colors.deepOrangeAccent, foregroundColor: Colors.black87),
            onPressed: () async {
              final cantidad = int.tryParse(objController.text) ?? 0;
              final token = context.read<AuthProvider>().token!;
              String? errorMsg;
              if (esEntrada) {
                errorMsg = await context.read<ProductoProvider>().darEntradaStock(token, productoId, cantidad, motivoController.text);
              } else {
                errorMsg = await context.read<ProductoProvider>().darSalidaStock(token, productoId, cantidad, motivoController.text);
              }
              if (mounted) {
                Navigator.pop(ctx);
                if (errorMsg == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Operación procesada con éxito', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent));
                }
                context.read<HistorialProvider>().loadHistorial(token);
              }
            },
            child: const Text('Confirmar'),
          )
        ],
      ),
    );
  }

  void _mostrarFormularioProducto([Producto? p]) {
    final nombreController = TextEditingController(text: p?.nombre ?? '');
    final descController = TextEditingController(text: p?.descripcion ?? '');
    final pVentaController = TextEditingController(text: p?.precioUnitarioVenta.toString() ?? '');
    final pCompraController = TextEditingController(text: p?.precioUnitarioCompra.toString() ?? '');
    final stockController = TextEditingController(text: p?.cantidadEnStock.toString() ?? '0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF203A43),
        title: Row(
          children: [
            Icon(p == null ? LucideIcons.plusSquare : LucideIcons.edit, color: Colors.cyanAccent),
            const SizedBox(width: 8),
            Text(p == null ? 'Nuevo Producto' : 'Editar Producto', style: const TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nombreController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Nombre', labelStyle: TextStyle(color: Colors.white70))),
              TextField(controller: descController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Descripción', labelStyle: TextStyle(color: Colors.white70))),
              TextField(controller: pVentaController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Precio Venta (\$)', labelStyle: TextStyle(color: Colors.white70) )),
              TextField(controller: pCompraController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Precio Compra (\$)', labelStyle: TextStyle(color: Colors.white70) )),
              if (p == null)
                 TextField(controller: stockController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Stock Inicial', labelStyle: TextStyle(color: Colors.white70) )),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black87),
            onPressed: () async {
              final token = context.read<AuthProvider>().token!;
              final nuevo = Producto(
                id: p?.id ?? 0,
                nombre: nombreController.text,
                descripcion: descController.text,
                precioUnitarioVenta: double.tryParse(pVentaController.text) ?? 0,
                precioUnitarioCompra: double.tryParse(pCompraController.text) ?? 0,
                cantidadEnStock: p?.cantidadEnStock ?? (int.tryParse(stockController.text) ?? 0),
              );

              bool success;
              if (p == null) {
                success = await context.read<ProductoProvider>().addProducto(token, nuevo);
              } else {
                success = await context.read<ProductoProvider>().editProducto(token, p.id, nuevo);
              }

              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Guardado exitosamente' : 'Error al guardar')));
                context.read<HistorialProvider>().loadHistorial(token);
              }
            },
            child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _eliminarProducto(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF203A43),
        title: const Text('Confirmar Eliminación', style: TextStyle(color: Colors.white)),
        content: const Text('¿Estás seguro de que deseas enviar este producto a la Papelera de Reciclaje?\n\n(Recuerda: El backend rechazará la operación si el stock físico no es exactamente cero).', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.black87),
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
      final success = errorMsg == null;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Producto eliminado' : errorMsg, style: const TextStyle(color: Colors.white)), backgroundColor: success ? Colors.green : Colors.redAccent));
      if (success) context.read<HistorialProvider>().loadHistorial(token);
    }
  }

  void _mostrarStockCritico(List<Producto> criticos) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF203A43),
        title: Row(
          children: const [
            Icon(LucideIcons.alertOctagon, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Alerta de Stock Crítico', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: SizedBox(
          width: 400,
          height: 400,
          child: criticos.isEmpty 
            ? const Center(child: Text('¡Todo el inventario está sano!', style: TextStyle(color: Colors.white70)))
            : ListView.builder(
                itemCount: criticos.length,
                itemBuilder: (c, i) {
                  final p = criticos[i];
                  return ListTile(
                    leading: const Icon(LucideIcons.alertTriangle, color: Colors.orangeAccent),
                    title: Text(p.nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('Stock actual: ${p.cantidadEnStock}', style: const TextStyle(color: Colors.amberAccent)),
                    trailing: IconButton(icon: const Icon(LucideIcons.plusCircle, color: Colors.cyanAccent), onPressed: () {
                      Navigator.pop(ctx);
                      _mostrarDialogoStock(p.id, true);
                    }),
                  );
                }
            )
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar', style: TextStyle(color: Colors.white54)))
        ],
      )
    );
  }

  // ----------- VISTA 1: RESUMEN -----------
  Widget _buildSummaryCards(List<Producto> productos) {
    if (productos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No hay datos para el resumen. Agrega productos al inventario.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 18)),
        ),
      );
    }

    final totalCat = productos.length;
    final totalUnidades = productos.fold<int>(0, (sum, p) => sum + p.cantidadEnStock);
    final valorGlobal = productos.fold<double>(0.0, (sum, p) => sum + (p.cantidadEnStock * p.precioUnitarioVenta));
    final criticos = productos.where((p) => p.cantidadEnStock <= 3).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Resumen General', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (isDesktop)
                Row(
                  children: [
                    Expanded(child: _buildCardInfo(LucideIcons.packageSearch, 'Catálogo', '$totalCat ítems', Colors.purpleAccent)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildCardInfo(LucideIcons.alertOctagon, 'Stock Crítico', '${criticos.length} ítems', Colors.redAccent, onTap: () => _mostrarStockCritico(criticos))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildCardInfo(LucideIcons.boxes, 'Físico', '$totalUnidades unids', Colors.cyanAccent)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildCardInfo(LucideIcons.badgeDollarSign, 'Valor Total', '\$${valorGlobal.toStringAsFixed(2)}', Colors.greenAccent)),
                  ]
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCardInfo(LucideIcons.packageSearch, 'Catálogo', '$totalCat ítems', Colors.purpleAccent),
                    const SizedBox(height: 12),
                    _buildCardInfo(LucideIcons.alertOctagon, 'Stock Crítico', '${criticos.length} ítems', Colors.redAccent, onTap: () => _mostrarStockCritico(criticos)),
                    const SizedBox(height: 12),
                    _buildCardInfo(LucideIcons.boxes, 'Stock Físico', '$totalUnidades unids', Colors.cyanAccent),
                    const SizedBox(height: 12),
                    _buildCardInfo(LucideIcons.badgeDollarSign, 'Valor Total', '\$${valorGlobal.toStringAsFixed(2)}', Colors.greenAccent),
                  ],
                )
            ],
          ),
        );
      },
    );
  }

  Widget _buildCardInfo(IconData icon, String title, String value, Color color, {VoidCallback? onTap}) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, spreadRadius: 1)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ],
            ),
          )
        ],
      ),
    );
    if (onTap == null) return child;
    return Material(color: Colors.transparent, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: child));
  }

  // ----------- VISTA 2: LISTA TRADICIONAL -----------
  Widget _buildProductosList(List<Producto> productos, bool isAdmin) {
    if (productos.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(LucideIcons.box, size: 100, color: Colors.white24), SizedBox(height: 20), Text("Inventario Vacío\n¡Añade productos con el botón +!", textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 20))]));
    }
    return ListView.builder(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: productos.length,
      itemBuilder: (ctx, i) {
        final p = productos[i];
        return Card(
          color: Colors.white.withOpacity(0.06),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withOpacity(0.1))),
          elevation: 8,
          shadowColor: Colors.black45,
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: p.cantidadEnStock > 0 ? [Colors.cyan, Colors.blueAccent] : [Colors.redAccent, Colors.deepOrange],
                        ),
                        boxShadow: [BoxShadow(color: (p.cantidadEnStock > 0 ? Colors.cyan : Colors.redAccent).withOpacity(0.5), blurRadius: 8, spreadRadius: 1)]
                      ),
                      child: Center(child: Text(p.cantidadEnStock.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17))),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 17), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text('Precio Venta: \$${p.precioUnitarioVenta.toStringAsFixed(2)}', style: TextStyle(color: Colors.cyanAccent.withOpacity(0.8), fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(p.descripcion, style: TextStyle(color: Colors.white.withOpacity(0.6), height: 1.3, fontSize: 13)),
                const SizedBox(height: 12),
                Container(height: 1, color: Colors.white.withOpacity(0.05)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isAdmin)
                      Tooltip(message: 'Editar', child: IconButton(icon: const Icon(LucideIcons.edit3, color: Colors.white70, size: 22), onPressed: () => _mostrarFormularioProducto(p))),
                    Tooltip(message: 'Salida Stock', child: IconButton(icon: const Icon(LucideIcons.minusCircle, color: Colors.deepOrangeAccent, size: 24), onPressed: () => _mostrarDialogoStock(p.id, false))),
                    Tooltip(message: 'Entrada Stock', child: IconButton(icon: const Icon(LucideIcons.plusCircle, color: Colors.cyanAccent, size: 24), onPressed: () => _mostrarDialogoStock(p.id, true))),
                    if (isAdmin)
                      Tooltip(message: 'Eliminar', child: IconButton(icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 22), onPressed: () => _eliminarProducto(p.id))),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ----------- VISTA 3: HISTORIAL (BITÁCORA) -----------
  Widget _buildFilterChip(String valor, String label) {
    final isSelected = _filtroHistorial == valor;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.black : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: Colors.cyanAccent,
      backgroundColor: Colors.white.withOpacity(0.1),
      onSelected: (val) {
        if (val) setState(() => _filtroHistorial = valor);
      },
    );
  }

  Widget _buildHistorialList() {
    final histProvider = context.watch<HistorialProvider>();
    final registros = histProvider.registros;
    final isLoading = histProvider.isLoading;
    final errorMsg = histProvider.error;

    if (isLoading && registros.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
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

    final listaFiltrada = _filtroHistorial == 'TODOS'
        ? registros
        : registros.where((r) => r.accion == _filtroHistorial).toList();

    return Column(
      children: [
        // Banda de filtros horizontales
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.2)),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
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
              ],
            ),
          ),
        ),
        // Lista visual de logs
        Expanded(
          child: listaFiltrada.isEmpty
              ? const Center(child: Text('No hay registros en bitácora para este filtro', style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: listaFiltrada.length,
                  itemBuilder: (ctx, i) {
                    final r = listaFiltrada[i];
                    
                    Color colorExtra;
                    IconData icon;
                    switch (r.accion) {
                      case 'CREACION': colorExtra = Colors.greenAccent; icon = LucideIcons.plusSquare; break;
                      case 'EDICION': colorExtra = Colors.blueAccent; icon = LucideIcons.edit; break;
                      case 'ELIMINACION': colorExtra = Colors.redAccent; icon = LucideIcons.trash2; break;
                      case 'ENTRADA': colorExtra = Colors.cyanAccent; icon = LucideIcons.packagePlus; break;
                      case 'SALIDA': colorExtra = Colors.deepOrangeAccent; icon = LucideIcons.packageMinus; break;
                      case 'RESTAURACION': colorExtra = Colors.tealAccent; icon = LucideIcons.rotateCcw; break;
                      default: colorExtra = Colors.white; icon = LucideIcons.info;
                    }

                    final dateStr = '${r.createdAt.day.toString().padLeft(2,'0')}/${r.createdAt.month.toString().padLeft(2,'0')}/${r.createdAt.year} a las ${r.createdAt.hour.toString().padLeft(2,'0')}:${r.createdAt.minute.toString().padLeft(2,'0')}';

                    return Card(
                      color: Colors.white.withOpacity(0.05),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: colorExtra.withOpacity(0.3))),
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorExtra.withOpacity(0.2),
                          child: Icon(icon, color: colorExtra),
                        ),
                        title: Text(r.detalles, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text('Por ${r.usuarioNombre} • $dateStr', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                        ),
                      ),
                    );
                  },
                ),
        )
      ],
    );
  }

  // ----------- VISTA 4: PAPELERA DE RECICLAJE -----------
  Widget _buildPapeleraList() {
    final prodProv = context.watch<ProductoProvider>();
    final borrados = prodProv.borrados;

    if (prodProv.isLoading && borrados.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
    }

    if (borrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(LucideIcons.leaf, size: 80, color: Colors.greenAccent),
            SizedBox(height: 20),
            Text('La papelera está vacía', style: TextStyle(color: Colors.white70, fontSize: 18)),
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
          color: Colors.redAccent.withOpacity(0.05),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.redAccent.withOpacity(0.3))),
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.transparent, child: Icon(LucideIcons.packageX, color: Colors.redAccent)),
            title: Text(p.nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, decoration: TextDecoration.lineThrough)),
            subtitle: Text('Precio: \$${p.precioUnitarioVenta.toStringAsFixed(2)} | Stock retenido: ${p.cantidadEnStock}', style: TextStyle(color: Colors.white.withOpacity(0.6))),
            trailing: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black87),
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

  // ----------- WIDGET PRINCIPAL -----------
  @override
  Widget build(BuildContext context) {
    final prodProvider = context.watch<ProductoProvider>();
    final productos = prodProvider.productos;
    
    final usuario = context.watch<AuthProvider>().usuario;
    final isAdmin = usuario?.rol == 'ADMIN';

    // Para la vista principal (Índice 0 y 1)
    final isLoadingProd = prodProvider.isLoading;
    final errorMsgProd = prodProvider.error;

    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF203A43), Color(0xFF2C5364)]),
          ),
        ),
        title: Text(_indiceActual == 0 ? 'Inventario TWS2' : _indiceActual == 1 ? 'Inventario Detallado' : _indiceActual == 2 ? 'Bitácora de Auditoría' : 'Papelera de Reciclaje', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF1E293B),
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF203A43), Color(0xFF2C5364)]),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(LucideIcons.userCircle2, size: 60, color: Colors.cyanAccent),
                  const SizedBox(height: 10),
                  Text('${usuario?.nombre ?? ""}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('Rol: ${usuario?.rol ?? ""}', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(LucideIcons.barChart3, color: Colors.white70),
              title: const Text('Resumen General', style: TextStyle(color: Colors.white)),
              selected: _indiceActual == 0,
              selectedTileColor: Colors.white.withOpacity(0.1),
              onTap: () {
                setState(() => _indiceActual = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.package2, color: Colors.white70),
              title: const Text('Inventario de Productos', style: TextStyle(color: Colors.white)),
              selected: _indiceActual == 1,
              selectedTileColor: Colors.white.withOpacity(0.1),
              onTap: () {
                setState(() => _indiceActual = 1);
                Navigator.pop(context);
              },
            ),
            if (isAdmin) 
              ListTile(
                leading: const Icon(LucideIcons.history, color: Colors.white70),
                title: const Text('Historial y Auditoría', style: TextStyle(color: Colors.white)),
                selected: _indiceActual == 2,
                selectedTileColor: Colors.white.withOpacity(0.1),
                onTap: () {
                  setState(() => _indiceActual = 2);
                  context.read<HistorialProvider>().loadHistorial(context.read<AuthProvider>().token!);
                  Navigator.pop(context);
                },
              ),
            if (isAdmin) 
              ListTile(
                leading: const Icon(LucideIcons.trash2, color: Colors.redAccent),
                title: const Text('Papelera de Reciclaje', style: TextStyle(color: Colors.white)),
                selected: _indiceActual == 3,
                selectedTileColor: Colors.white.withOpacity(0.1),
                onTap: () {
                  setState(() => _indiceActual = 3);
                  context.read<ProductoProvider>().loadProductosBorrados(context.read<AuthProvider>().token!);
                  Navigator.pop(context);
                },
              ),
            const Divider(color: Colors.white24),
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
            backgroundColor: Colors.cyanAccent,
            icon: const Icon(LucideIcons.plus, color: Colors.black87),
            label: const Text('Crear Producto', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
            onPressed: () => _mostrarFormularioProducto(),
          ) 
        : null,
      body: _indiceActual == 3
          ? _buildPapeleraList()
          : _indiceActual == 2
              ? _buildHistorialList()
              : (isLoadingProd && productos.isEmpty)
                  ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
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
                                  Text(errorMsgProd, style: const TextStyle(color: Colors.white70, height: 1.5, fontSize: 16), textAlign: TextAlign.center),
                                  const SizedBox(height: 30),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15)),
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
}
