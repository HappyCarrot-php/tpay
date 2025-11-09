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

  // Registrar abono usando RPC
  Future<int> registrarAbono({
    required int movimientoId,
    required double monto,
    String? metodoPago,
    String? referencia,
    String? notas,
  }) async {
    try {
      final response = await _supabase.rpc(
        SupabaseConstants.registrarAbonoRpc,
        params: {
          'p_movimiento_id': movimientoId,
          'p_monto': monto,
          if (metodoPago != null) 'p_metodo_pago': metodoPago,
          if (referencia != null) 'p_referencia': referencia,
          if (notas != null) 'p_notas': notas,
        },
      );

      return response as int;
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
