import 'package:equatable/equatable.dart';

class PaymentEntity extends Equatable {
  final String id;
  final String prestamoId;
  final double monto;
  final DateTime fechaPago;
  final String? metodoPago;
  final String? notas;
  
  const PaymentEntity({
    required this.id,
    required this.prestamoId,
    required this.monto,
    required this.fechaPago,
    this.metodoPago,
    this.notas,
  });

  @override
  List<Object?> get props => [
        id,
        prestamoId,
        monto,
        fechaPago,
        metodoPago,
        notas,
      ];
}
