import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/services/app_data_cache.dart';
import '../../../../core/services/supabase_service.dart';
import '../models/abono_model.dart';

class AbonoRepository {
  final SupabaseClient _supabase = SupabaseService().client;

  // Obtener abonos de un movimiento
  Future<List<AbonoModel>> obtenerAbonosPorMovimiento(int movimientoId) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.abonosTable)
          .select()
          .eq('movimiento_id', movimientoId)
          .order('fecha_abono', ascending: false);

        final rowsForCache = (response as List)
          .whereType<Map<String, dynamic>>()
          .map((json) => _extractAbonoRow(Map<String, dynamic>.from(json)))
          .toList();
        AppDataCache().cacheAbonos(rowsForCache);

        return rowsForCache.map((json) => AbonoModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener abonos: $e');
    }
  }

  // Registrar abono y actualizar movimiento
  Future<AbonoModel> registrarAbono({
    required int movimientoId,
    required double montoAbono,
    String? metodoPago,
    String? referencia,
    String? notas,
  }) async {
    try {
      final userId = SupabaseService().currentUserId;

      // 1. Insertar abono en tabla abonos
      final abonoData = {
        'id_movimiento': movimientoId,
        'monto_abono': montoAbono,
        'fecha_abono': DateTime.now().toIso8601String(),
        if (metodoPago != null) 'metodo_pago': metodoPago,
        if (referencia != null) 'referencia': referencia,
        if (notas != null) 'notas': notas,
        if (userId != null) 'usuario_registro': userId,
      };

      final abonoResponse = await _supabase
          .from(SupabaseConstants.abonosTable)
          .insert(abonoData)
          .select()
          .single();

      // 2. Actualizar campo abonos en movimientos
      // Obtener el total actual de abonos
      final movResponse = await _supabase
          .from(SupabaseConstants.movimientosTable)
          .select('abonos')
          .eq('id', movimientoId)
          .single();

      final abonosActuales = (movResponse['abonos'] as num?)?.toDouble() ?? 0;
      final nuevosAbonos = abonosActuales + montoAbono;

      // Actualizar campo abonos (saldo_pendiente se calcula automáticamente)
      await _supabase
          .from(SupabaseConstants.movimientosTable)
          .update({'abonos': nuevosAbonos})
          .eq('id', movimientoId);

      final sanitized = _extractAbonoRow(Map<String, dynamic>.from(abonoResponse));
      AppDataCache().cacheAbono(sanitized);
      return AbonoModel.fromJson(sanitized);
    } catch (e) {
      throw Exception('Error al registrar abono: $e');
    }
  }

  // Obtener total de abonos de un movimiento
  Future<double> obtenerTotalAbonos(int movimientoId) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.abonosTable)
          .select('monto')
          .eq('movimiento_id', movimientoId);

      AppDataCache().cacheAbonos(
        (response as List)
            .whereType<Map<String, dynamic>>()
            .map((row) => _extractAbonoRow(Map<String, dynamic>.from(row))),
      );

      double total = 0;
      for (var abono in response) {
        total += (abono['monto'] as num).toDouble();
      }

      return total;
    } catch (e) {
      throw Exception('Error al calcular total de abonos: $e');
    }
  }

  Future<List<AbonoModel>> obtenerTodosLosAbonos() async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.abonosTable)
          .select()
          .order('id', ascending: true);

      final rows = (response as List)
          .whereType<Map<String, dynamic>>()
          .map((json) => _extractAbonoRow(Map<String, dynamic>.from(json)))
          .toList();
      AppDataCache().cacheAbonos(rows);

      return rows.map((json) => AbonoModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener abonos: $e');
    }
  }

  // Eliminar abono
  Future<void> eliminarAbono(int id) async {
    try {
      await _supabase.from(SupabaseConstants.abonosTable).delete().eq('id', id);
      AppDataCache().removeAbono(id);
    } catch (e) {
      throw Exception('Error al eliminar abono: $e');
    }
  }

  Map<String, dynamic> _extractAbonoRow(Map<String, dynamic> source) {
    final sanitized = <String, dynamic>{};
    const allowedKeys = [
      'id',
      'id_movimiento',
      'monto_abono',
      'fecha_abono',
      'metodo_pago',
      'referencia',
      'comprobante_url',
      'usuario_registro',
      'notas',
      'creado',
    ];

    for (final key in allowedKeys) {
      if (source.containsKey(key)) {
        sanitized[key] = source[key];
      }
    }

    return sanitized;
  }
}
