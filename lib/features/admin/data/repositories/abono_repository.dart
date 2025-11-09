import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_constants.dart';
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

      return (response as List).map((json) => AbonoModel.fromJson(json)).toList();
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

      return AbonoModel.fromJson(abonoResponse);
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

      double total = 0;
      for (var abono in response) {
        total += (abono['monto'] as num).toDouble();
      }

      return total;
    } catch (e) {
      throw Exception('Error al calcular total de abonos: $e');
    }
  }

  // Eliminar abono
  Future<void> eliminarAbono(int id) async {
    try {
      await _supabase.from(SupabaseConstants.abonosTable).delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar abono: $e');
    }
  }
}
