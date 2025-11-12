import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class DatabaseBackupService {
  final _supabase = Supabase.instance.client;

  /// Genera un backup completo de la base de datos en formato SQL
  /// Permite al usuario seleccionar dónde guardar el archivo
  Future<File?> generateFullBackup() async {
    try {
      // Solicitar permisos de almacenamiento
      final status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) {
        final storageStatus = await Permission.storage.request();
        if (!storageStatus.isGranted) {
          throw Exception('Permisos de almacenamiento denegados');
        }
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = 'tpay_backup_$timestamp.sql';

      // Permitir al usuario seleccionar dónde guardar el archivo
      String? selectedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar backup',
        fileName: filename,
        type: FileType.custom,
        allowedExtensions: ['sql'],
      );

      if (selectedPath == null) {
        // Usuario canceló
        return null;
      }

      // Crear el archivo en la ubicación seleccionada
      final file = File(selectedPath);

      // Iniciar el contenido SQL
      final buffer = StringBuffer();
      buffer.writeln('-- T-Pay Database Backup');
      buffer.writeln('-- Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}');
      buffer.writeln('-- ========================================');
      buffer.writeln();
      buffer.writeln('-- NOTA: Ejecutar en Supabase SQL Editor');
      buffer.writeln('-- Este archivo contiene CREATE TABLE e INSERT statements');
      buffer.writeln();

      // CREATE TABLE statements
      buffer.writeln('-- ========================================');
      buffer.writeln('-- CREATE TABLES');
      buffer.writeln('-- ========================================');
      buffer.writeln();
      
      buffer.writeln(_getCreateTablePerfiles());
      buffer.writeln(_getCreateTableClientes());
      buffer.writeln(_getCreateTableMovimientos());
      buffer.writeln(_getCreateTableAbonos());
      buffer.writeln();

      // Backup de tabla: perfiles
      buffer.writeln('-- ========================================');
      buffer.writeln('-- DATOS: perfiles');
      buffer.writeln('-- ========================================');
      final perfiles = await _supabase.from('perfiles').select();
      for (var perfil in perfiles) {
        buffer.writeln(_generateInsertStatement('perfiles', perfil));
      }
      buffer.writeln();

      // Backup de tabla: clientes
      buffer.writeln('-- ========================================');
      buffer.writeln('-- DATOS: clientes');
      buffer.writeln('-- ========================================');
      final clientes = await _supabase.from('clientes').select();
      for (var cliente in clientes) {
        buffer.writeln(_generateInsertStatement('clientes', cliente));
      }
      buffer.writeln();

      // Backup de tabla: movimientos
      buffer.writeln('-- ========================================');
      buffer.writeln('-- DATOS: movimientos');
      buffer.writeln('-- ========================================');
      final movimientos = await _supabase.from('movimientos').select();
      for (var movimiento in movimientos) {
        buffer.writeln(_generateInsertStatement('movimientos', movimiento));
      }
      buffer.writeln();

      // Backup de tabla: abonos
      buffer.writeln('-- ========================================');
      buffer.writeln('-- DATOS: abonos');
      buffer.writeln('-- ========================================');
      final abonos = await _supabase.from('abonos').select();
      for (var abono in abonos) {
        buffer.writeln(_generateInsertStatement('abonos', abono));
      }
      buffer.writeln();

      // Escribir al archivo
      await file.writeAsString(buffer.toString());

      return file;
    } catch (e) {
      throw Exception('Error al generar backup: $e');
    }
  }

  /// Genera un INSERT statement para una fila
  String _generateInsertStatement(String tableName, Map<String, dynamic> row) {
    final columns = row.keys.toList();
    final values = row.values.map((value) {
      if (value == null) {
        return 'NULL';
      } else if (value is String) {
        // Escapar comillas simples
        final escaped = value.replaceAll("'", "''");
        return "'$escaped'";
      } else if (value is bool) {
        return value ? 'TRUE' : 'FALSE';
      } else if (value is DateTime) {
        return "'${value.toIso8601String()}'";
      } else {
        return value.toString();
      }
    }).toList();

    return 'INSERT INTO $tableName (${columns.join(', ')}) VALUES (${values.join(', ')});';
  }

  /// Obtiene el tamaño estimado del backup
  Future<String> getEstimatedBackupSize() async {
    try {
      int totalRows = 0;

      final perfiles = await _supabase.from('perfiles').select();
      totalRows += perfiles.length;

      final clientes = await _supabase.from('clientes').select();
      totalRows += clientes.length;

      final movimientos = await _supabase.from('movimientos').select();
      totalRows += movimientos.length;

      final abonos = await _supabase.from('abonos').select();
      totalRows += abonos.length;

      // Estimación: ~500 bytes por fila en promedio
      final estimatedBytes = totalRows * 500;
      
      if (estimatedBytes < 1024) {
        return '${estimatedBytes}B';
      } else if (estimatedBytes < 1024 * 1024) {
        return '${(estimatedBytes / 1024).toStringAsFixed(1)}KB';
      } else {
        return '${(estimatedBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
      }
    } catch (e) {
      return 'Desconocido';
    }
  }

  /// Lista todos los backups guardados
  Future<List<File>> listBackups() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final dir = Directory(directory.path);
      
      final files = dir.listSync()
          .whereType<File>()
          .where((f) => f.path.contains('tpay_backup_') && f.path.endsWith('.sql'))
          .toList();
      
      // Ordenar por fecha (más reciente primero)
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      
      return files;
    } catch (e) {
      return [];
    }
  }

  /// Elimina un backup específico
  Future<void> deleteBackup(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Error al eliminar backup: $e');
    }
  }

  // ========================================
  // CREATE TABLE STATEMENTS
  // ========================================

  String _getCreateTablePerfiles() {
    return '''
-- Tabla: perfiles
CREATE TABLE IF NOT EXISTS public.perfiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    nombre VARCHAR(100) NOT NULL,
    apellido_paterno VARCHAR(100),
    apellido_materno VARCHAR(100),
    nombre_completo VARCHAR(300) GENERATED ALWAYS AS (nombre || ' ' || COALESCE(apellido_paterno, '') || ' ' || COALESCE(apellido_materno, '')) STORED,
    email VARCHAR(255),
    telefono VARCHAR(20),
    fecha_nacimiento DATE,
    genero VARCHAR(20),
    direccion TEXT,
    ciudad VARCHAR(100),
    estado VARCHAR(100),
    codigo_postal VARCHAR(10),
    rfc VARCHAR(13),
    curp VARCHAR(18),
    foto_url TEXT,
    rol VARCHAR(50) DEFAULT 'cliente',
    activo BOOLEAN DEFAULT true,
    creado TIMESTAMPTZ DEFAULT NOW(),
    actualizado TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_perfiles_usuario_id ON public.perfiles(usuario_id);
CREATE INDEX IF NOT EXISTS idx_perfiles_rol ON public.perfiles(rol);
CREATE INDEX IF NOT EXISTS idx_perfiles_activo ON public.perfiles(activo);

''';
  }

  String _getCreateTableClientes() {
    return '''
-- Tabla: clientes
CREATE TABLE IF NOT EXISTS public.clientes (
    id SERIAL PRIMARY KEY,
    usuario_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    nombre VARCHAR(100) NOT NULL,
    apellido_paterno VARCHAR(100),
    apellido_materno VARCHAR(100),
    nombre_completo VARCHAR(300) GENERATED ALWAYS AS (nombre || ' ' || COALESCE(apellido_paterno, '') || ' ' || COALESCE(apellido_materno, '')) STORED,
    email VARCHAR(255),
    telefono VARCHAR(20),
    direccion TEXT,
    rfc VARCHAR(13),
    curp VARCHAR(18),
    notas TEXT,
    activo BOOLEAN DEFAULT true,
    creado TIMESTAMPTZ DEFAULT NOW(),
    actualizado TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_clientes_usuario_id ON public.clientes(usuario_id);
CREATE INDEX IF NOT EXISTS idx_clientes_activo ON public.clientes(activo);
CREATE INDEX IF NOT EXISTS idx_clientes_nombre_completo ON public.clientes(nombre_completo);

''';
  }

  String _getCreateTableMovimientos() {
    return '''
-- Tabla: movimientos
CREATE TABLE IF NOT EXISTS public.movimientos (
    id SERIAL PRIMARY KEY,
    id_cliente INTEGER REFERENCES public.clientes(id) ON DELETE CASCADE,
    monto DECIMAL(10,2) NOT NULL,
    interes DECIMAL(10,2) DEFAULT 0,
    tasa_interes_porcentaje DECIMAL(5,2),
    abonos DECIMAL(10,2) DEFAULT 0,
    saldo_pendiente DECIMAL(10,2) GENERATED ALWAYS AS (monto + interes - abonos) STORED,
    fecha_inicio DATE NOT NULL,
    fecha_pago DATE NOT NULL,
    dias_prestamo INTEGER GENERATED ALWAYS AS (fecha_pago - fecha_inicio) STORED,
    estado_pagado BOOLEAN DEFAULT false,
    fecha_pagado TIMESTAMPTZ,
    metodo_pago VARCHAR(50),
    eliminado BOOLEAN DEFAULT false,
    motivo_eliminacion TEXT,
    usuario_registro VARCHAR(255),
    notas TEXT,
    creado TIMESTAMPTZ DEFAULT NOW(),
    actualizado TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_movimientos_id_cliente ON public.movimientos(id_cliente);
CREATE INDEX IF NOT EXISTS idx_movimientos_estado_pagado ON public.movimientos(estado_pagado);
CREATE INDEX IF NOT EXISTS idx_movimientos_eliminado ON public.movimientos(eliminado);
CREATE INDEX IF NOT EXISTS idx_movimientos_fecha_pago ON public.movimientos(fecha_pago);

''';
  }

  String _getCreateTableAbonos() {
    return '''
-- Tabla: abonos
CREATE TABLE IF NOT EXISTS public.abonos (
    id SERIAL PRIMARY KEY,
    id_movimiento INTEGER REFERENCES public.movimientos(id) ON DELETE CASCADE,
    monto DECIMAL(10,2) NOT NULL,
    fecha_abono TIMESTAMPTZ DEFAULT NOW(),
    metodo_pago VARCHAR(50),
    notas TEXT,
    usuario_registro VARCHAR(255),
    creado TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_abonos_id_movimiento ON public.abonos(id_movimiento);
CREATE INDEX IF NOT EXISTS idx_abonos_fecha_abono ON public.abonos(fecha_abono);

''';
  }
}
