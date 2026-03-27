class Categoria {
  final int? id;
  final String nombre;
  final int stockMinimo;

  Categoria({
    this.id,
    required this.nombre,
    required this.stockMinimo,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'],
      nombre: json['nombre'],
      stockMinimo: json['stockMinimo'] ?? 5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'stockMinimo': stockMinimo,
    };
  }
}
