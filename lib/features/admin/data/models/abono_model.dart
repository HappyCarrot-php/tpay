import '../../domain/entities/abono_entity.dart';

class AbonoModel extends AbonoEntity {
  const AbonoModel({
    required super.id,
    required super.idMovimiento,
    required super.montoAbono,
    required super.fechaAbono,
    super.metodoPago,
    super.referencia,
    super.comprobanteUrl,
    super.usuarioRegistro,
    super.notas,
    required super.creado,
  });

  factory AbonoModel.fromJson(Map<String, dynamic> json) {
    return AbonoModel(
      id: json['id'] as int,
      idMovimiento: json['id_movimiento'] as int,
      montoAbono: (json['monto_abono'] as num).toDouble(),
      fechaAbono: DateTime.parse(json['fecha_abono'] as String),
      metodoPago: json['metodo_pago'] as String?,
      referencia: json['referencia'] as String?,
      comprobanteUrl: json['comprobante_url'] as String?,
      usuarioRegistro: json['usuario_registro'] as String?,
      notas: json['notas'] as String?,
      creado: DateTime.parse(json['creado'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_movimiento': idMovimiento,
      'monto_abono': montoAbono,
      'fecha_abono': fechaAbono.toIso8601String(),
      'metodo_pago': metodoPago,
      'referencia': referencia,
      'comprobante_url': comprobanteUrl,
      'usuario_registro': usuarioRegistro,
      'notas': notas,
      'creado': creado.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'id_movimiento': idMovimiento,
      'monto_abono': montoAbono,
      'fecha_abono': fechaAbono.toIso8601String(),
      if (metodoPago != null) 'metodo_pago': metodoPago,
      if (referencia != null) 'referencia': referencia,
      if (comprobanteUrl != null) 'comprobante_url': comprobanteUrl,
      if (notas != null) 'notas': notas,
    };
  }
}
