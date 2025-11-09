import 'package:equatable/equatable.dart';

class AdminInfoEntity extends Equatable {
  final String id;
  final String nombre;
  final String apellido;
  final String telefono;
  final String email;
  
  const AdminInfoEntity({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.telefono,
    required this.email,
  });

  String get nombreCompleto => '$nombre $apellido';

  @override
  List<Object?> get props => [
        id,
        nombre,
        apellido,
        telefono,
        email,
      ];
}
