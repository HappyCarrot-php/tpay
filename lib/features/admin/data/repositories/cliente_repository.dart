import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/services/supabase_service.dart';
import '../models/cliente_model.dart';

class ClienteRepository {
  final SupabaseClient _supabase = SupabaseService().client;

  // Obtener todos los clientes
  Future<List<ClienteModel>> obtenerClientes({
    bool soloActivos = true,
    bool ascending = false, // Default: descendente (último primero)
  }) async {
    try {
      var query = _supabase.from(SupabaseConstants.clientesTable).select();

      if (soloActivos) {
        query = query.eq('activo', true);
      }

      final response = await query.order('id_cliente', ascending: ascending);

      return (response as List)
          .map((json) => ClienteModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener clientes: $e');
    }
  }

  // Buscar clientes por nombre completo o ID
  Future<List<ClienteModel>> buscarClientes(String query, {bool ascending = false}) async {
    try {
      final idCliente = int.tryParse(query);
      
      final response = await _supabase
          .from(SupabaseConstants.clientesTable)
          .select()
          .or('nombre_completo.ilike.%$query%,id_cliente.eq.${idCliente ?? 0}')
          .eq('activo', true)
          .order('id_cliente', ascending: ascending);

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
          .eq('id_cliente', id)
          .single();

      return ClienteModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener cliente: $e');
    }
  }

  // Buscar cliente por nombre exacto
  Future<ClienteModel?> buscarClientePorNombre(String nombreCompleto) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.clientesTable)
          .select()
          .ilike('nombre_completo', nombreCompleto.trim())
          .eq('activo', true)
          .maybeSingle();

      if (response == null) return null;
      return ClienteModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al buscar cliente por nombre: $e');
    }
  }

  // Obtener deuda total de un cliente
  Future<double> obtenerDeudaTotal(int clienteId) async {
    try {
      // Suma de saldo_pendiente de todos los préstamos activos (no pagados)
      final response = await _supabase
          .from(SupabaseConstants.movimientosTable)
          .select('saldo_pendiente')
          .eq('id_cliente', clienteId)
          .eq('estado_pagado', false)
          .eq('eliminado', false);

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

      final data = cliente.toInsertJson();
      if (userId != null) {
        data['usuario_id'] = userId;
      }

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

  // Crear cliente simple (solo nombre y apellidos)
  Future<ClienteModel> crearClienteSimple({
    required String nombre,
    required String apellidoPaterno,
    String? apellidoMaterno,
    String? telefono,
    String? email,
  }) async {
    try {
      final userId = SupabaseService().currentUserId;

      final data = {
        'nombre': nombre,
        'apellido_paterno': apellidoPaterno,
        if (apellidoMaterno != null) 'apellido_materno': apellidoMaterno,
        if (telefono != null) 'telefono': telefono,
        if (email != null) 'email': email,
        if (userId != null) 'usuario_id': userId,
        'activo': true,
      };

      final response = await _supabase
          .from(SupabaseConstants.clientesTable)
          .insert(data)
          .select()
          .single();

      return ClienteModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear cliente simple: $e');
    }
  }

  // Actualizar cliente
  Future<ClienteModel> actualizarCliente(ClienteModel cliente) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.clientesTable)
          .update(cliente.toJson())
          .eq('id_cliente', cliente.id)
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
          .update({'activo': false})
          .eq('id_cliente', id);
    } catch (e) {
      throw Exception('Error al desactivar cliente: $e');
    }
  }

  // Contar clientes activos
  Future<int> contarClientes({bool soloActivos = true}) async {
    try {
      var query = _supabase
          .from(SupabaseConstants.clientesTable)
          .select();

      if (soloActivos) {
        query = query.eq('activo', true);
      }

      final response = await query;
      return (response as List).length;
    } catch (e) {
      throw Exception('Error al contar clientes: $e');
    }
  }
}
