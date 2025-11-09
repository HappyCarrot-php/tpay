class MovimientoEntity {
  final int id;
  final int idCliente; // Se mantiene idCliente para consistencia en código
  final String? nombreCliente; // Viene del JOIN con clientes
  final double monto;
  final double interes;
  final double? tasaInteresPorcentaje;
  final double abonos;
  final double saldoPendiente; // Calculado: monto + interes - abonos
  final DateTime fechaInicio;
  final DateTime fechaPago;
  final int diasPrestamo; // Calculado
  final bool estadoPagado;
  final DateTime? fechaPagado;
  final String? metodoPago;
  final bool eliminado;
  final String? motivoEliminacion;
  final String? usuarioRegistro;
  final String? notas;
  final DateTime creado;
  final DateTime actualizado;

  const MovimientoEntity({
    required this.id,
    required this.idCliente,
    this.nombreCliente,
    required this.monto,
    required this.interes,
    this.tasaInteresPorcentaje,
    required this.abonos,
    required this.saldoPendiente,
    required this.fechaInicio,
    required this.fechaPago,
    required this.diasPrestamo,
    required this.estadoPagado,
    this.fechaPagado,
    this.metodoPago,
    required this.eliminado,
    this.motivoEliminacion,
    this.usuarioRegistro,
    this.notas,
    required this.creado,
    required this.actualizado,
  });

  /// Total a pagar (monto + interés)
  double get totalAPagar => monto + interes;

  /// Porcentaje pagado
  double get porcentajePagado {
    if (totalAPagar == 0) return 0;
    return (abonos / totalAPagar) * 100;
  }

  /// Está vencido
  bool get estaVencido {
    if (estadoPagado) return false;
    return fechaPago.isBefore(DateTime.now());
  }

  /// Días de vencido
  int get diasVencido {
    if (!estaVencido) return 0;
    return DateTime.now().difference(fechaPago).inDays;
  }

  /// Estado textual
  String get estadoTexto {
    if (estadoPagado) return 'FINALIZADO';
    if (estaVencido) return 'VENCIDO';
    return 'ACTIVO';
  }

  /// Color del estado para UI
  int get estadoColor {
    if (estadoPagado) return 0xFF4CAF50; // Verde
    if (estaVencido) return 0xFFF44336; // Rojo
    return 0xFF00BCD4; // Turquesa
  }
}
