import '../../domain/entities/movimiento_entity.dart';

class MovimientoModel extends MovimientoEntity {
  const MovimientoModel({
    required super.id,
    required super.idCliente,
    super.nombreCliente,
    required super.monto,
    required super.interes,
    super.tasaInteresPorcentaje,
    required super.abonos,
    required super.saldoPendiente,
    required super.fechaInicio,
    required super.fechaPago,
    required super.diasPrestamo,
    required super.estadoPagado,
    super.fechaPagado,
    super.metodoPago,
    required super.eliminado,
    super.motivoEliminacion,
    super.usuarioRegistro,
    super.notas,
    required super.creado,
    required super.actualizado,
  });

  factory MovimientoModel.fromJson(Map<String, dynamic> json) {
    return MovimientoModel(
      id: json['id'] as int,
      idCliente: json['id_cliente'] as int,
      nombreCliente: json['nombre_cliente'] as String?, // Del JOIN con tabla clientes
      monto: (json['monto'] as num).toDouble(),
      interes: (json['interes'] as num).toDouble(),
      tasaInteresPorcentaje: json['tasa_interes_porcentaje'] != null
          ? (json['tasa_interes_porcentaje'] as num).toDouble()
          : null,
      abonos: (json['abonos'] as num? ?? 0).toDouble(),
      saldoPendiente: (json['saldo_pendiente'] as num).toDouble(),
      fechaInicio: DateTime.parse(json['fecha_inicio'] as String),
      fechaPago: DateTime.parse(json['fecha_pago'] as String),
      diasPrestamo: json['dias_prestamo'] as int,
      estadoPagado: json['estado_pagado'] as bool? ?? false,
      fechaPagado: json['fecha_pagado'] != null
          ? DateTime.parse(json['fecha_pagado'] as String)
          : null,
      metodoPago: json['metodo_pago'] as String?,
      eliminado: json['eliminado'] as bool? ?? false,
      motivoEliminacion: json['motivo_eliminacion'] as String?,
      usuarioRegistro: json['usuario_registro'] as String?,
      notas: json['notas'] as String?,
      creado: DateTime.parse(json['creado'] as String),
      actualizado: DateTime.parse(json['actualizado'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_cliente': idCliente,
      'monto': monto,
      'interes': interes,
      'tasa_interes_porcentaje': tasaInteresPorcentaje,
      'abonos': abonos,
      'fecha_inicio': fechaInicio.toIso8601String().split('T')[0], // Solo fecha
      'fecha_pago': fechaPago.toIso8601String().split('T')[0],
      'estado_pagado': estadoPagado,
      'fecha_pagado': fechaPagado?.toIso8601String(),
      'metodo_pago': metodoPago,
      'eliminado': eliminado,
      'motivo_eliminacion': motivoEliminacion,
      'usuario_registro': usuarioRegistro,
      'notas': notas,
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'id_cliente': idCliente,
      'monto': monto,
      'interes': interes,
      if (tasaInteresPorcentaje != null)
        'tasa_interes_porcentaje': tasaInteresPorcentaje,
      'fecha_inicio': fechaInicio.toIso8601String().split('T')[0],
      'fecha_pago': fechaPago.toIso8601String().split('T')[0],
      if (metodoPago != null) 'metodo_pago': metodoPago,
      if (notas != null) 'notas': notas,
    };
  }
}

