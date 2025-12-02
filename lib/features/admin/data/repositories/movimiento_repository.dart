import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/services/app_data_cache.dart';
import '../../../../core/services/supabase_service.dart';
import '../models/movimiento_model.dart';

enum FiltroEstadoPrestamo {
  todos,
  activos,
  pagados,
  vencidos, // También conocido como "Mora"
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
          .order('id', ascending: false)
          .range(offset, offset + limite - 1);

      final rowsForCache = <Map<String, dynamic>>[];

      final movimientos = (response as List).map((json) {
        final raw = Map<String, dynamic>.from(json);
        final sanitized = _extractMovimientoRow(raw);
        rowsForCache.add(sanitized);

        final nombreCliente = raw['clientes'] is Map
            ? raw['clientes']['nombre_completo']
            : null;

        return MovimientoModel.fromJson({
          ...sanitized,
          'nombre_cliente': nombreCliente,
        });
      }).toList();

      AppDataCache().cacheMovimientos(rowsForCache);
      return movimientos;
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

      final response = await supabaseQuery.order('id', ascending: false);

      final rowsForCache = <Map<String, dynamic>>[];

      List<MovimientoModel> movimientos = (response as List).map((json) {
        final raw = Map<String, dynamic>.from(json);
        final sanitized = _extractMovimientoRow(raw);
        rowsForCache.add(sanitized);

        final nombreCliente = raw['clientes'] is Map
            ? raw['clientes']['nombre_completo']
            : null;
        
        return MovimientoModel.fromJson({
          ...sanitized,
          'nombre_cliente': nombreCliente,
        });
      }).toList();

      AppDataCache().cacheMovimientos(rowsForCache);

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

      final raw = Map<String, dynamic>.from(response);
      final sanitized = _extractMovimientoRow(raw);
      AppDataCache().cacheMovimiento(sanitized);

      final nombreCliente = raw['clientes'] is Map
          ? raw['clientes']['nombre_completo']
          : null;

      return MovimientoModel.fromJson({
        ...sanitized,
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

      dynamic response;
      int intentos = 0;
      const maxIntentos = 3;
      
      // Reintentar si hay error de duplicate key
      while (intentos < maxIntentos) {
        try {
          response = await _supabase
              .from(SupabaseConstants.movimientosTable)
              .insert(data)
              .select('''
                *,
                clientes!inner(nombre_completo)
              ''')
              .single();
          break; // Éxito, salir del loop
        } catch (e) {
          intentos++;
          final errorStr = e.toString().toLowerCase();
          
          // Verificar si es error de duplicate key
          if (errorStr.contains('duplicate') || errorStr.contains('23505')) {
            if (intentos >= maxIntentos) {
              throw Exception(
                'Error: La base de datos tiene un problema de sincronización. '
                'Por favor contacta al administrador para que ejecute: '
                'SELECT setval(pg_get_serial_sequence(\'movimientos\',\'id\'), '
                '(SELECT COALESCE(MAX(id), 1) FROM movimientos), true);'
              );
            }
            // Esperar un poco antes de reintentar
            await Future.delayed(Duration(milliseconds: 100 * intentos));
            continue;
          } else {
            // Si no es error de duplicate key, lanzar inmediatamente
            rethrow;
          }
        }
      }

      final raw = Map<String, dynamic>.from(response);
      final sanitized = _extractMovimientoRow(raw);
      AppDataCache().cacheMovimiento(sanitized);

      final nombreCliente = raw['clientes'] is Map
          ? raw['clientes']['nombre_completo']
          : null;

      return MovimientoModel.fromJson({
        ...sanitized,
        'nombre_cliente': nombreCliente,
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception(
          'Error de sincronización en la base de datos. '
          'El préstamo no pudo ser registrado. '
          'Contacta al administrador del sistema.'
        );
      }
      throw Exception('Error de base de datos: ${e.message}');
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('duplicate') || errorStr.contains('23505')) {
        throw Exception(
          'Error: No se puede registrar el préstamo por un problema de sincronización. '
          'Contacta al administrador.'
        );
      }
      throw Exception('Error al crear préstamo: $e');
    }
  }

  // Actualizar préstamo
  Future<MovimientoModel> actualizarPrestamo({
    required int id,
    double? monto,
    double? interes,
    double? abonos,
    DateTime? fechaPago,
    String? notas,
    bool? estadoPagado,
    int? clienteId,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (monto != null) data['monto'] = monto;
      if (interes != null) data['interes'] = interes;
      if (abonos != null) data['abonos'] = abonos;
      if (fechaPago != null) data['fecha_pago'] = fechaPago.toIso8601String().split('T')[0];
      if (notas != null) data['notas'] = notas;
      if (clienteId != null) data['id_cliente'] = clienteId;
      if (estadoPagado != null) {
        data['estado_pagado'] = estadoPagado;
        if (estadoPagado) {
          data['fecha_pagado'] = DateTime.now().toIso8601String();
        }
      }

      final response = await _supabase
          .from(SupabaseConstants.movimientosTable)
          .update(data)
          .eq('id', id)
          .select('''
            *,
            clientes!inner(nombre_completo)
          ''')
          .single();

      final raw = Map<String, dynamic>.from(response);
      final sanitized = _extractMovimientoRow(raw);
      AppDataCache().cacheMovimiento(sanitized);

      final nombreCliente = raw['clientes'] is Map
          ? raw['clientes']['nombre_completo']
          : null;

      return MovimientoModel.fromJson({
        ...sanitized,
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

      if (AppDataCache().hasMovimientos) {
        final existing = AppDataCache()
            .toSnapshot()
            .movimientos
            .firstWhere((row) => row['id'] == movimientoId, orElse: () => {});
        if (existing.isNotEmpty) {
          final updated = Map<String, dynamic>.from(existing)
            ..['estado_pagado'] = true
            ..['fecha_pagado'] = DateTime.now().toIso8601String()
            ..['abonos'] = 0;
          AppDataCache().cacheMovimiento(updated);
        }
      }
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

      AppDataCache().removeMovimiento(
        id,
        keepHistory: true,
        motivo: motivoEliminacion,
      );
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
      AppDataCache().cacheMovimientos(
        (response as List)
        .whereType<Map<String, dynamic>>()
        .map((row) => _extractMovimientoRow(Map<String, dynamic>.from(row))),
      );
      return (response as List).length;
    } catch (e) {
      throw Exception('Error al contar movimientos: $e');
    }
  }

  Map<String, dynamic> _extractMovimientoRow(Map<String, dynamic> source) {
    final sanitized = <String, dynamic>{};
    const allowedKeys = [
      'id',
      'id_cliente',
      'monto',
      'interes',
      'tasa_interes_porcentaje',
      'abonos',
      'saldo_pendiente',
      'fecha_inicio',
      'fecha_pago',
      'dias_prestamo',
      'estado_pagado',
      'fecha_pagado',
      'metodo_pago',
      'eliminado',
      'motivo_eliminacion',
      'usuario_registro',
      'notas',
      'creado',
      'actualizado',
    ];

    for (final key in allowedKeys) {
      if (source.containsKey(key)) {
        sanitized[key] = source[key];
      }
    }

    return sanitized;
  }
}
