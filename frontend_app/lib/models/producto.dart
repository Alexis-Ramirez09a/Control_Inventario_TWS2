class Producto {
  final int id;
  final String nombre;
  final String descripcion;
  final int cantidadEnStock;
  final double precioUnitarioCompra;
  final double precioUnitarioVenta;
  final bool inventariado;

  Producto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.cantidadEnStock,
    required this.precioUnitarioCompra,
    required this.precioUnitarioVenta,
    this.inventariado = true,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      cantidadEnStock: json['cantidadEnStock'] ?? 0,
      precioUnitarioCompra: double.parse(json['precioUnitarioCompra']?.toString() ?? '0'),
      precioUnitarioVenta: double.parse(json['precioUnitarioVenta']?.toString() ?? '0'),
      inventariado: json['inventariado'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'precioUnitarioCompra': precioUnitarioCompra,
      'precioUnitarioVenta': precioUnitarioVenta,
      'cantidadEnStock': cantidadEnStock,
      'inventariado': inventariado,
    };
  }
}
