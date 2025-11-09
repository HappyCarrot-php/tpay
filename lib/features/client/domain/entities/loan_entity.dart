import 'package:equatable/equatable.dart';

class LoanEntity extends Equatable {
  final String id;
  final String clienteId;
  final String? adminId;
  final double monto;
  final double interes;
  final String estado; // 'activo', 'pagado', 'mora'
  final DateTime fechaInicio;
  final DateTime? fechaVencimiento;
  final DateTime? fechaPago;
  final String? clienteNombre;
  final String? adminNombre;
  final double totalAbonos;
  
  const LoanEntity({
    required this.id,
    required this.clienteId,
    this.adminId,
    required this.monto,
    required this.interes,
    required this.estado,
    required this.fechaInicio,
    this.fechaVencimiento,
    this.fechaPago,
    this.clienteNombre,
    this.adminNombre,
    this.totalAbonos = 0.0,
  });

  double get totalAPagar => monto + (monto * interes / 100);
  double get deudaActual => totalAPagar - totalAbonos;
  bool get isPagado => estado == 'pagado';
  bool get isActivo => estado == 'activo';
  bool get isMora => estado == 'mora';

  @override
  List<Object?> get props => [
        id,
        clienteId,
        adminId,
        monto,
        interes,
        estado,
        fechaInicio,
        fechaVencimiento,
        fechaPago,
        clienteNombre,
        adminNombre,
        totalAbonos,
      ];
}
