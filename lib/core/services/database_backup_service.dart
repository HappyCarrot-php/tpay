import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class DatabaseBackupService {
  final _supabase = Supabase.instance.client;

  /// Genera un backup completo de la base de datos en formato SQL
  Future<File> generateFullBackup() async {
    try {
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = 'tpay_backup_$timestamp.sql';

      // Obtener directorio para guardar el archivo
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');

      // Iniciar el contenido SQL
      final buffer = StringBuffer();
      buffer.writeln('-- T-Pay Database Backup');
      buffer.writeln('-- Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}');
      buffer.writeln('-- ========================================');
      buffer.writeln();

      // Backup de tabla: perfiles
      buffer.writeln('-- Tabla: perfiles');
      buffer.writeln('-- ========================================');
      final perfiles = await _supabase.from('perfiles').select();
      for (var perfil in perfiles) {
        buffer.writeln(_generateInsertStatement('perfiles', perfil));
      }
      buffer.writeln();

      // Backup de tabla: clientes
      buffer.writeln('-- Tabla: clientes');
      buffer.writeln('-- ========================================');
      final clientes = await _supabase.from('clientes').select();
      for (var cliente in clientes) {
        buffer.writeln(_generateInsertStatement('clientes', cliente));
      }
      buffer.writeln();

      // Backup de tabla: movimientos
      buffer.writeln('-- Tabla: movimientos');
      buffer.writeln('-- ========================================');
      final movimientos = await _supabase.from('movimientos').select();
      for (var movimiento in movimientos) {
        buffer.writeln(_generateInsertStatement('movimientos', movimiento));
      }
      buffer.writeln();

      // Backup de tabla: abonos
      buffer.writeln('-- Tabla: abonos');
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
}
