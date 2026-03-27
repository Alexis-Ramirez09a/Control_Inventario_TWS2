class HistorialLog {
  final int id;
  final String accion;
  final String detalles;
  final String usuarioNombre;
  final DateTime createdAt;

  HistorialLog({required this.id, required this.accion, required this.detalles, required this.usuarioNombre, required this.createdAt});

  factory HistorialLog.fromJson(Map<String, dynamic> json) {
    return HistorialLog(
      id: json['id'],
      accion: json['accion'],
      detalles: json['detalles'],
      usuarioNombre: json['usuarioNombre'] ?? 'Desconocido',
      createdAt: DateTime.parse(json['createdAt']).toLocal(),
    );
  }
}
