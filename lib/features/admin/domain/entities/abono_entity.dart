class AbonoEntity {
  final int id;
  final int idMovimiento;
  final double montoAbono;
  final DateTime fechaAbono;
  final String? metodoPago;
  final String? referencia;
  final String? comprobanteUrl;
  final String? usuarioRegistro;
  final String? notas;
  final DateTime creado;

  const AbonoEntity({
    required this.id,
    required this.idMovimiento,
    required this.montoAbono,
    required this.fechaAbono,
    this.metodoPago,
    this.referencia,
    this.comprobanteUrl,
    this.usuarioRegistro,
    this.notas,
    required this.creado,
  });

  /// Formato de monto para UI (sin decimales)
  String get montoFormateado => '\$${montoAbono.toInt()}';
}
