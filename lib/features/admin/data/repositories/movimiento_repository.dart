import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/services/supabase_service.dart';
import '../models/movimiento_model.dart';

enum FiltroEstadoPrestamo {
  todos,
  activos,
  pagados,
  vencidos,
}

class MovimientoRepository {
  final SupabaseClient _supabase = SupabaseService().client;

  // Obtener movimientos con filtros y JOIN con clientes
  Future<List<MovimientoModel>> obtenerMovimientos({
    int? clienteId,
    FiltroEstadoPrestamo filtro = FiltroEstadoPrestamo.todos,
    int limite = 100,
    int offset = 0,
  }) async {
    try {
      // Query con JOIN para obtener nombre del cliente
      var query = _supabase
          .from(SupabaseConstants.movimientosTable)
          .select('''
            *,
            clientes!inner(nombre_completo)
          ''')
          .eq('eliminado', false);

      if (clienteId != null) {
        query = query.eq('id_cliente', clienteId);
      }

      switch (filtro) {
        case FiltroEstadoPrestamo.activos:
          query = query.eq('estado_pagado', false);
          break;
        case FiltroEstadoPrestamo.pagados:
          query = query.eq('estado_pagado', true);
          break;
        case FiltroEstadoPrestamo.vencidos:
          query = query
              .eq('estado_pagado', false)
              .lt('fecha_pago', DateTime.now().toIso8601String().split('T')[0]);
          break;
        case FiltroEstadoPrestamo.todos:
          // No aplicar filtro adicional
          break;
      }

      final response = await query
          .order('fecha_inicio', ascending: false)
          .range(offset, offset + limite - 1);

      return (response as List).map((json) {
        // Extraer nombre del cliente del JOIN
        final nombreCliente = json['clientes'] is Map
            ? json['clientes']['nombre_completo']
            : null;
        
        return MovimientoModel.fromJson({
          ...json,
          'nombre_cliente': nombreCliente,
        });
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener movimientos: $e');
    }
  }

  // Buscar movimientos por ID de préstamo, ID de cliente o nombre
  Future<List<MovimientoModel>> buscarMovimientos(String query) async {
    try {
      final idPrestamo = int.tryParse(query);
      final idCliente = int.tryParse(query);

      var supabaseQuery = _supabase
          .from(SupabaseConstants.movimientosTable)
          .select('''
            *,
            clientes!inner(nombre_completo)
          ''')
          .eq('eliminado', false);

      if (idPrestamo != null) {
        supabaseQuery = supabaseQuery.eq('id', idPrestamo);
      } else if (idCliente != null) {
        supabaseQuery = supabaseQuery.eq('id_cliente', idCliente);
      } else {
        // Búsqueda por nombre - hacerlo del lado del cliente
        // No se puede filtrar directamente en JOIN, así que traemos todo
      }

      final response = await supabaseQuery.order('fecha_inicio', ascending: false);

      List<MovimientoModel> movimientos = (response as List).map((json) {
        final nombreCliente = json['clientes'] is Map
            ? json['clientes']['nombre_completo']
            : null;
        
        return MovimientoModel.fromJson({
          ...json,
          'nombre_cliente': nombreCliente,
        });
      }).toList();

      // Filtrar por nombre del lado del cliente si es necesario
      if (idPrestamo == null && idCliente == null) {
        movimientos = movimientos.where((m) => 
          m.nombreCliente?.toLowerCase().contains(query.toLowerCase()) ?? false
        ).toList();
      }

      return movimientos;
    } catch (e) {
      throw Exception('Error al buscar movimientos: $e');
    }
  }

  // Obtener movimiento por ID con datos del cliente
  Future<MovimientoModel> obtenerMovimientoPorId(int id) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.movimientosTable)
          .select('''
            *,
            clientes!inner(nombre_completo)
          ''')
          .eq('id', id)
          .single();

      final nombreCliente = response['nombre_cliente'] is Map
          ? response['nombre_cliente']['nombre_completo']
          : null;

      return MovimientoModel.fromJson({
        ...response,
        'nombre_cliente': nombreCliente,
      });
    } catch (e) {
      throw Exception('Error al obtener movimiento: $e');
    }
  }

  // Crear nuevo préstamo
  Future<MovimientoModel> crearPrestamo({
    required int clienteId,
    required double monto,
    required double interes,
    required DateTime fechaInicio,
    required DateTime fechaPago,
    double? tasaInteresPorcentaje,
    String? metodoPago,
    String? notas,
  }) async {
    try {
      final userId = SupabaseService().currentUserId;

      final data = {
        'id_cliente': clienteId,
        'monto': monto,
        'interes': interes,
        'fecha_inicio': fechaInicio.toIso8601String().split('T')[0],
        'fecha_pago': fechaPago.toIso8601String().split('T')[0],
        if (tasaInteresPorcentaje != null) 'tasa_interes_porcentaje': tasaInteresPorcentaje,
        if (metodoPago != null) 'metodo_pago': metodoPago,
        if (notas != null) 'notas': notas,
        if (userId != null) 'usuario_registro': userId,
      };

      final response = await _supabase
          .from(SupabaseConstants.movimientosTable)
          .insert(data)
          .select('''
            *,
            clientes!inner(nombre_completo)
          ''')
          .single();

      final nombreCliente = response['clientes'] is Map
          ? response['clientes']['nombre_completo']
          : null;

      return MovimientoModel.fromJson({
        ...response,
        'nombre_cliente': nombreCliente,
      });
    } catch (e) {
      throw Exception('Error al crear préstamo: $e');
    }
  }

  // Actualizar préstamo
  Future<MovimientoModel> actualizarPrestamo({
    required int id,
    double? monto,
    double? interes,
    DateTime? fechaPago,
    String? notas,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (monto != null) data['monto'] = monto;
      if (interes != null) data['interes'] = interes;
      if (fechaPago != null) data['fecha_pago'] = fechaPago.toIso8601String().split('T')[0];
      if (notas != null) data['notas'] = notas;

      final response = await _supabase
          .from(SupabaseConstants.movimientosTable)
          .update(data)
          .eq('id', id)
          .select('''
            *,
            clientes!inner(nombre_completo)
          ''')
          .single();

      final nombreCliente = response['clientes'] is Map
          ? response['clientes']['nombre_completo']
          : null;

      return MovimientoModel.fromJson({
        ...response,
        'nombre_cliente': nombreCliente,
      });
    } catch (e) {
      throw Exception('Error al actualizar préstamo: $e');
    }
  }

  // Marcar préstamo como pagado (establece abonos a 0 para no alterar finanzas)
  Future<void> marcarComoPagado(int movimientoId, {String? metodoPago}) async {
    try {
      await _supabase.from(SupabaseConstants.movimientosTable).update({
        'estado_pagado': true,
        'fecha_pagado': DateTime.now().toIso8601String(),
        'abonos': 0, // Establecer a 0 para no alterar finanzas
        if (metodoPago != null) 'metodo_pago': metodoPago,
      }).eq('id', movimientoId);
    } catch (e) {
      throw Exception('Error al marcar como pagado: $e');
    }
  }

  // Eliminar préstamo (soft delete - marcar como eliminado)
  Future<void> eliminarPrestamo(int id, String motivoEliminacion) async {
    try {
      await _supabase.from(SupabaseConstants.movimientosTable).update({
        'eliminado': true,
        'motivo_eliminacion': motivoEliminacion,
      }).eq('id', id);
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
      var query = _supabase
          .from(SupabaseConstants.movimientosTable)
          .select()
          .eq('eliminado', false);

      if (clienteId != null) {
        query = query.eq('id_cliente', clienteId);
      }

      switch (filtro) {
        case FiltroEstadoPrestamo.activos:
          query = query.eq('estado_pagado', false);
          break;
        case FiltroEstadoPrestamo.pagados:
          query = query.eq('estado_pagado', true);
          break;
        case FiltroEstadoPrestamo.vencidos:
          query = query
              .eq('estado_pagado', false)
              .lt('fecha_pago', DateTime.now().toIso8601String().split('T')[0]);
          break;
        case FiltroEstadoPrestamo.todos:
          break;
      }

      final response = await query;
      return (response as List).length;
    } catch (e) {
      throw Exception('Error al contar movimientos: $e');
    }
  }
}
