import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String nombre;
  final String? apellidoPaterno;
  final String? apellidoMaterno;
  final String telefono;
  final String rol; // 'cliente' o 'administrador'
  final bool emailVerificado;
  final bool telefonoVerificado;
  final DateTime? fechaRegistro;

  const UserEntity({
    required this.id,
    required this.email,
    required this.nombre,
    this.apellidoPaterno,
    this.apellidoMaterno,
    required this.telefono,
    required this.rol,
    required this.emailVerificado,
    required this.telefonoVerificado,
    this.fechaRegistro,
  });

  String get nombreCompleto {
    final parts = [nombre, apellidoPaterno, apellidoMaterno]
        .where((part) => part != null && part.isNotEmpty)
        .join(' ');
    return parts;
  }

  bool get isAdmin => rol == 'administrador';
  bool get isClient => rol == 'cliente';

  @override
  List<Object?> get props => [
        id,
        email,
        nombre,
        apellidoPaterno,
        apellidoMaterno,
        telefono,
        rol,
        emailVerificado,
        telefonoVerificado,
        fechaRegistro,
      ];
}
