import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/supabase_constants.dart';

class BackupResult {
  final File exportedFile;
  final File archiveFile;

  const BackupResult({required this.exportedFile, required this.archiveFile});
}

class DatabaseBackupService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Genera un respaldo completo, lo guarda en la ruta elegida por el usuario
  /// y conserva una copia en el almacenamiento interno de la app.
  Future<BackupResult?> generateFullBackup() async {
    try {
      await _requestStoragePermission();

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = 'tpay_backup_$timestamp.sql';

      final selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Selecciona dónde guardar el backup',
      );

      if (selectedDirectory == null) {
        return null;
      }

      final backupContent = await _buildBackupContent(timestamp);

      final exportedPath = _joinPath(selectedDirectory, filename);
      final exportedFile = File(exportedPath);
      await exportedFile.writeAsString(backupContent);

      final archiveDir = await _ensureInternalBackupDirectory();
      final archivePath = _joinPath(archiveDir.path, filename);
      final archiveFile = File(archivePath);
      await archiveFile.writeAsString(backupContent);

      return BackupResult(exportedFile: exportedFile, archiveFile: archiveFile);
    } catch (e) {
      throw Exception('Error al generar backup: $e');
    }
  }

  Future<String> _buildBackupContent(String timestamp) async {
    final buffer = StringBuffer();

    final perfilesData = _castRows(
      await _supabase
          .from(SupabaseConstants.perfilesTable)
          .select()
          .order('creado', ascending: true),
    );

    final clientesData = _castRows(
      await _supabase
          .from(SupabaseConstants.clientesTable)
          .select()
          .order('id_cliente', ascending: true),
    );

    final movimientosData = _castRows(
      await _supabase
          .from(SupabaseConstants.movimientosTable)
          .select()
          .order('id', ascending: true),
    );

    final abonosData = _castRows(
      await _supabase
          .from(SupabaseConstants.abonosTable)
          .select()
          .order('id', ascending: true),
    );

    final clientesMaxId = _maxNumericId(clientesData, 'id_cliente');
    final movimientosMaxId = _maxNumericId(movimientosData, 'id');
    final abonosMaxId = _maxNumericId(abonosData, 'id');

    buffer
      ..writeln('-- T-Pay Database Backup')
      ..writeln('-- Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}')
      ..writeln('-- Timestamp: $timestamp')
      ..writeln('-- ========================================')
      ..writeln()
      ..writeln('-- NOTA: Ejecutar en el SQL Editor de Supabase')
      ..writeln('-- Este archivo contiene la estructura y datos actuales')
      ..writeln()
      ..writeln('BEGIN;')
      ..writeln()
      ..writeln('-- ========================================')
      ..writeln('-- CREATE TABLES')
      ..writeln('-- ========================================')
      ..writeln()
      ..writeln(_getCreateTablePerfiles())
      ..writeln(_getCreateTableClientes())
      ..writeln(_getCreateTableMovimientos())
      ..writeln(_getCreateTableAbonos());

    buffer
      ..writeln('-- ========================================')
      ..writeln('-- DATOS: perfiles')
      ..writeln('-- ========================================');
    if (perfilesData.isEmpty) {
      buffer.writeln('-- (sin registros)');
    } else {
      for (final perfil in perfilesData) {
        buffer.writeln(_generateInsertStatement('public.perfiles', perfil));
      }
    }
    buffer.writeln();

    buffer
      ..writeln('-- ========================================')
      ..writeln('-- DATOS: clientes')
      ..writeln('-- ========================================');
    if (clientesData.isEmpty) {
      buffer.writeln('-- (sin registros)');
    } else {
      for (final cliente in clientesData) {
        buffer.writeln(_generateInsertStatement('public.clientes', cliente));
      }
    }
    buffer.writeln();

    buffer
      ..writeln('-- ========================================')
      ..writeln('-- DATOS: movimientos')
      ..writeln('-- ========================================');
    if (movimientosData.isEmpty) {
      buffer.writeln('-- (sin registros)');
    } else {
      for (final movimiento in movimientosData) {
        buffer.writeln(_generateInsertStatement('public.movimientos', movimiento));
      }
    }
    buffer.writeln();

    buffer
      ..writeln('-- ========================================')
      ..writeln('-- DATOS: abonos')
      ..writeln('-- ========================================');
    if (abonosData.isEmpty) {
      buffer.writeln('-- (sin registros)');
    } else {
      for (final abono in abonosData) {
        buffer.writeln(_generateInsertStatement('public.abonos', abono));
      }
    }
    buffer.writeln();

    buffer
      ..writeln('-- ========================================')
      ..writeln('-- AJUSTE DE SECUENCIAS')
      ..writeln('-- ========================================')
      ..writeln(_generateSetvalStatement('clientes_id_cliente_seq', clientesMaxId))
      ..writeln(_generateSetvalStatement('movimientos_id_seq', movimientosMaxId))
      ..writeln(_generateSetvalStatement('abonos_id_seq', abonosMaxId))
      ..writeln()
      ..writeln('COMMIT;')
      ..writeln()
      ..writeln('-- Fin del respaldo');

    return buffer.toString();
  }

  Future<void> _requestStoragePermission() async {
    if (!Platform.isAndroid) {
      return;
    }

    final manageStatus = await Permission.manageExternalStorage.request();
    if (manageStatus.isGranted) {
      return;
    }

    final storageStatus = await Permission.storage.request();
    if (!storageStatus.isGranted) {
      throw Exception('Permisos de almacenamiento denegados');
    }
  }

  Future<Directory> _ensureInternalBackupDirectory() async {
    final baseDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(_joinPath(baseDir.path, 'tpay_backups'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  List<Map<String, dynamic>> _castRows(dynamic response) {
    if (response is List) {
      return response
          .whereType<Map<String, dynamic>>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    }
    return const [];
  }

  int? _maxNumericId(List<Map<String, dynamic>> rows, String key) {
    int? maxValue;
    for (final row in rows) {
      final value = row[key];
      if (value is int) {
        maxValue = maxValue == null || value > maxValue ? value : maxValue;
      } else if (value is num) {
        final intValue = value.toInt();
        maxValue = maxValue == null || intValue > maxValue ? intValue : maxValue;
      }
    }
    return maxValue;
  }

  String _generateInsertStatement(String tableName, Map<String, dynamic> row) {
    final columns = row.keys.toList();
    final values = columns.map((column) => _serializeValue(row[column])).toList();
    return 'INSERT INTO $tableName (${columns.join(', ')}) VALUES (${values.join(', ')});';
  }

  String _serializeValue(dynamic value) {
    if (value == null) {
      return 'NULL';
    }

    if (value is String) {
      final escaped = value.replaceAll("'", "''");
      return "'$escaped'";
    }

    if (value is bool) {
      return value ? 'TRUE' : 'FALSE';
    }

    if (value is DateTime) {
      return "'${value.toUtc().toIso8601String()}'";
    }

    if (value is num) {
      if (value is int || value == value.truncateToDouble()) {
        return value.toInt().toString();
      }
      return value.toString();
    }

    return "'${value.toString().replaceAll("'", "''")}'";
  }

  String _generateSetvalStatement(String sequenceName, int? maxValue) {
    final value = maxValue ?? 1;
    final isCalled = maxValue != null ? 'true' : 'false';
    return "SELECT setval('$sequenceName', $value, $isCalled);";
  }

  String _joinPath(String directory, String filename) {
    final endsWithSeparator = directory.endsWith('/') || directory.endsWith('\\');
    final separator = endsWithSeparator ? '' : Platform.pathSeparator;
    return '$directory$separator$filename';
  }

  /// Obtiene el tamaño estimado del backup
  Future<String> getEstimatedBackupSize() async {
    try {
      int totalRows = 0;

      final perfiles = await _supabase.from(SupabaseConstants.perfilesTable).select();
      totalRows += perfiles.length;

      final clientes = await _supabase.from(SupabaseConstants.clientesTable).select();
      totalRows += clientes.length;

      final movimientos = await _supabase.from(SupabaseConstants.movimientosTable).select();
      totalRows += movimientos.length;

      final abonos = await _supabase.from(SupabaseConstants.abonosTable).select();
      totalRows += abonos.length;

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

  /// Lista todos los respaldos almacenados internamente
  Future<List<File>> listBackups() async {
    try {
      final backupDir = await _ensureInternalBackupDirectory();
      if (!await backupDir.exists()) {
        return [];
      }

      final files = backupDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.sql'))
          .toList();

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
    nombre_completo VARCHAR(300) GENERATED ALWAYS AS (
        trim(both ' ' FROM nombre || ' ' || COALESCE(apellido_paterno, '') || ' ' || COALESCE(apellido_materno, ''))
    ) STORED,
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
    ultimo_acceso TIMESTAMPTZ,
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
    id_cliente SERIAL PRIMARY KEY,
    usuario_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    nombre VARCHAR(100) NOT NULL,
    apellido_paterno VARCHAR(100) NOT NULL,
    apellido_materno VARCHAR(100),
    nombre_completo VARCHAR(300) GENERATED ALWAYS AS (
        trim(both ' ' FROM nombre || ' ' || apellido_paterno || ' ' || COALESCE(apellido_materno, ''))
    ) STORED,
    telefono VARCHAR(20),
    email VARCHAR(255),
    fecha_nacimiento DATE,
    direccion TEXT,
    ciudad VARCHAR(100),
    estado VARCHAR(100),
    codigo_postal VARCHAR(10),
    identificacion_tipo VARCHAR(50),
    identificacion_numero VARCHAR(100),
    rfc VARCHAR(13),
    curp VARCHAR(18),
    foto_url TEXT,
    calificacion_cliente NUMERIC(3,1),
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
    id_cliente INTEGER REFERENCES public.clientes(id_cliente) ON DELETE CASCADE,
    monto NUMERIC(12,2) NOT NULL,
    interes NUMERIC(12,2) DEFAULT 0,
    tasa_interes_porcentaje NUMERIC(5,2),
    abonos NUMERIC(12,2) DEFAULT 0,
    saldo_pendiente NUMERIC(12,2) GENERATED ALWAYS AS (monto + interes - abonos) STORED,
    fecha_inicio DATE NOT NULL,
    fecha_pago DATE NOT NULL,
    dias_prestamo INTEGER GENERATED ALWAYS AS ((fecha_pago - fecha_inicio)) STORED,
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
    monto_abono NUMERIC(12,2) NOT NULL,
    fecha_abono TIMESTAMPTZ DEFAULT NOW(),
    metodo_pago VARCHAR(50),
    referencia VARCHAR(100),
    comprobante_url TEXT,
    usuario_registro VARCHAR(255),
    notas TEXT,
    creado TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_abonos_id_movimiento ON public.abonos(id_movimiento);
CREATE INDEX IF NOT EXISTS idx_abonos_fecha_abono ON public.abonos(fecha_abono);

''';
  }
}
