import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/services/supabase_service.dart';
import '../models/movimiento_model.dart';

enum FiltroEstadoPrestamo {
  todos,
  activos,
  pagados,
}

class MovimientoRepository {
  final SupabaseClient _supabase = SupabaseService().client;

  // Obtener movimientos con filtros
  Future<List<MovimientoModel>> obtenerMovimientos({
    int? clienteId,
    FiltroEstadoPrestamo filtro = FiltroEstadoPrestamo.todos,
    int limite = 10,
    int offset = 0,
  }) async {
    try {
      var query = _supabase
          .from(SupabaseConstants.vistaPrestamosActivosView)
          .select();

      if (clienteId != null) {
        query = query.eq('cliente_id', clienteId);
      }

      switch (filtro) {
        case FiltroEstadoPrestamo.activos:
          query = query.eq('estado_pagado', false);
          break;
        case FiltroEstadoPrestamo.pagados:
          query = query.eq('estado_pagado', true);
          break;
        case FiltroEstadoPrestamo.todos:
          // No aplicar filtro
          break;
      }

      final response = await query
          .order('fecha_prestamo', ascending: false)
          .range(offset, offset + limite - 1);

      return (response as List)
          .map((json) => MovimientoModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener movimientos: $e');
    }
  }

  // Buscar movimientos por ID de préstamo, ID de cliente o nombre
  Future<List<MovimientoModel>> buscarMovimientos(String query) async {
    try {
      final idPrestamo = int.tryParse(query);
      final idCliente = int.tryParse(query);

      final response = await _supabase
          .from(SupabaseConstants.vistaPrestamosActivosView)
          .select()
          .or(
            'id.eq.${idPrestamo ?? 0},'
            'cliente_id.eq.${idCliente ?? 0},'
            'cliente_nombre.ilike.%$query%',
          )
          .order('fecha_prestamo', ascending: false);

      return (response as List)
          .map((json) => MovimientoModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar movimientos: $e');
    }
  }

  // Obtener movimiento por ID
  Future<MovimientoModel> obtenerMovimientoPorId(int id) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.vistaPrestamosActivosView)
          .select()
          .eq('id', id)
          .single();

      return MovimientoModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener movimiento: $e');
    }
  }

  // Crear nuevo préstamo usando RPC
  Future<int> crearPrestamo({
    required int clienteId,
    required double monto,
    required double interes,
    required int diasPrestamo,
    required DateTime fechaPrestamo,
    String? descripcion,
  }) async {
    try {
      final response = await _supabase.rpc(
        SupabaseConstants.registrarMovimientoRpc,
        params: {
          'p_cliente_id': clienteId,
          'p_monto': monto,
          'p_interes': interes,
          'p_dias_prestamo': diasPrestamo,
          'p_fecha_prestamo': fechaPrestamo.toIso8601String(),
          if (descripcion != null) 'p_descripcion': descripcion,
        },
      );

      return response as int;
    } catch (e) {
      throw Exception('Error al crear préstamo: $e');
    }
  }

  // Actualizar préstamo
  Future<MovimientoModel> actualizarPrestamo(MovimientoModel movimiento) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.movimientosTable)
          .update(movimiento.toJson())
          .eq('id', movimiento.id)
          .select()
          .single();

      return MovimientoModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar préstamo: $e');
    }
  }

  // Marcar préstamo como pagado
  Future<void> marcarComoPagado(int movimientoId) async {
    try {
      await _supabase.from(SupabaseConstants.movimientosTable).update({
        'estado_pagado': true,
        'fecha_pagado': DateTime.now().toIso8601String(),
        'abonos': 0,
        'saldo_pendiente': 0,
      }).eq('id', movimientoId);
    } catch (e) {
      throw Exception('Error al marcar como pagado: $e');
    }
  }

  // Eliminar préstamo (no recomendado, mejor desactivar)
  Future<void> eliminarPrestamo(int id) async {
    try {
      await _supabase
          .from(SupabaseConstants.movimientosTable)
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar préstamo: $e');
    }
  }

  // Contar total de movimientos para paginación
  Future<int> contarMovimientos({
    int? clienteId,
    FiltroEstadoPrestamo filtro = FiltroEstadoPrestamo.todos,
  }) async {
    try {
      var query =
          _supabase.from(SupabaseConstants.movimientosTable).select('id');

      if (clienteId != null) {
        query = query.eq('cliente_id', clienteId);
      }

      switch (filtro) {
        case FiltroEstadoPrestamo.activos:
          query = query.eq('estado_pagado', false);
          break;
        case FiltroEstadoPrestamo.pagados:
          query = query.eq('estado_pagado', true);
          break;
        case FiltroEstadoPrestamo.todos:
          break;
      }

      final response = await query.count();
      return response.count;
    } catch (e) {
      throw Exception('Error al contar movimientos: $e');
    }
  }
}
