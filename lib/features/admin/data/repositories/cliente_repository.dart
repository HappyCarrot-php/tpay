import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/services/supabase_service.dart';
import '../models/cliente_model.dart';

class ClienteRepository {
  final SupabaseClient _supabase = SupabaseService().client;

  // Obtener todos los clientes
  Future<List<ClienteModel>> obtenerClientes({
    bool soloActivos = false,
  }) async {
    try {
      var query = _supabase.from(SupabaseConstants.clientesTable).select();

      if (soloActivos) {
        query = query.eq('activo', true);
      }

      final response = await query.order('nombre', ascending: true);

      return (response as List)
          .map((json) => ClienteModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener clientes: $e');
    }
  }

  // Buscar clientes por nombre o ID
  Future<List<ClienteModel>> buscarClientes(String query) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.clientesTable)
          .select()
          .or('nombre.ilike.%$query%,apellidos.ilike.%$query%,id.eq.${int.tryParse(query) ?? 0}')
          .eq('activo', true)
          .order('nombre', ascending: true);

      return (response as List)
          .map((json) => ClienteModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar clientes: $e');
    }
  }

  // Obtener cliente por ID
  Future<ClienteModel> obtenerClientePorId(int id) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.clientesTable)
          .select()
          .eq('id', id)
          .single();

      return ClienteModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener cliente: $e');
    }
  }

  // Obtener deuda total de un cliente
  Future<double> obtenerDeudaTotal(int clienteId) async {
    try {
      // Suma de saldo_pendiente de todos los préstamos activos (no pagados)
      final response = await _supabase
          .from(SupabaseConstants.movimientosTable)
          .select('saldo_pendiente')
          .eq('cliente_id', clienteId)
          .eq('estado_pagado', false);

      double deudaTotal = 0;
      for (var mov in response) {
        deudaTotal += (mov['saldo_pendiente'] as num?)?.toDouble() ?? 0;
      }

      return deudaTotal;
    } catch (e) {
      throw Exception('Error al calcular deuda total: $e');
    }
  }

  // Crear nuevo cliente
  Future<ClienteModel> crearCliente(ClienteModel cliente) async {
    try {
      final userId = SupabaseService().currentUserId;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      final data = cliente.toInsertJson();
      data['creado_por'] = userId;

      final response = await _supabase
          .from(SupabaseConstants.clientesTable)
          .insert(data)
          .select()
          .single();

      return ClienteModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear cliente: $e');
    }
  }

  // Actualizar cliente
  Future<ClienteModel> actualizarCliente(ClienteModel cliente) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.clientesTable)
          .update(cliente.toJson())
          .eq('id', cliente.idCliente)
          .select()
          .single();

      return ClienteModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar cliente: $e');
    }
  }

  // Desactivar cliente (soft delete)
  Future<void> desactivarCliente(int id) async {
    try {
      await _supabase
          .from(SupabaseConstants.clientesTable)
          .update({'activo': false}).eq('id', id);
    } catch (e) {
      throw Exception('Error al desactivar cliente: $e');
    }
  }
}
