import 'package:equatable/equatable.dart';

class ReceiptEntity extends Equatable {
  final String id;
  final String abonoId;
  final String prestamoId;
  final String urlRecibo;
  final DateTime fechaEmision;
  
  const ReceiptEntity({
    required this.id,
    required this.abonoId,
    required this.prestamoId,
    required this.urlRecibo,
    required this.fechaEmision,
  });

  @override
  List<Object?> get props => [
        id,
        abonoId,
        prestamoId,
        urlRecibo,
        fechaEmision,
      ];
}
