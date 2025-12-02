import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/app_data_cache.dart';
import '../../../../core/services/database_backup_service.dart';
import '../../data/repositories/abono_repository.dart';
import '../../data/repositories/cliente_repository.dart';
import '../../data/repositories/movimiento_repository.dart';
import '../../data/repositories/perfil_repository.dart';

class DatabaseBackupPage extends StatefulWidget {
  const DatabaseBackupPage({super.key});

  @override
  State<DatabaseBackupPage> createState() => _DatabaseBackupPageState();
}

class _DatabaseBackupPageState extends State<DatabaseBackupPage> {
  final _backupService = DatabaseBackupService();
  final _clienteRepository = ClienteRepository();
  final _movimientoRepository = MovimientoRepository();
  final _abonoRepository = AbonoRepository();
  final _perfilRepository = PerfilRepository();
  
  bool _isGenerating = false;
  List<File> _backups = [];
  String _estimatedSize = 'Calculando...';

  @override
  void initState() {
    super.initState();
    _loadBackups();
    _loadEstimatedSize();
  }

  Future<void> _loadBackups() async {
    try {
      final backups = await _backupService.listBackups();
      if (mounted) {
        setState(() => _backups = backups);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar backups: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadEstimatedSize() async {
    try {
      final size = await _backupService.getEstimatedBackupSize();
      if (mounted) {
        setState(() => _estimatedSize = size);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _estimatedSize = 'Error');
      }
    }
  }

  Future<DatabaseSnapshotData> _collectSnapshot() async {
    final cache = AppDataCache();

    if (!cache.hasPerfiles) {
      await _perfilRepository.obtenerPerfiles(soloActivos: false);
    }

    if (!cache.hasClientes) {
      await _clienteRepository.obtenerClientes(soloActivos: false);
    }

    // Siempre recargamos movimientos con filtro general para asegurar datos actualizados
    await _movimientoRepository.obtenerMovimientos(
      filtro: FiltroEstadoPrestamo.todos,
      limite: 5000,
    );

    if (!cache.hasAbonos) {
      await _abonoRepository.obtenerTodosLosAbonos();
    }

    return cache.toSnapshot();
  }

  Future<void> _generateBackup() async {
    setState(() => _isGenerating = true);

    try {
      final snapshot = await _collectSnapshot();
      if (snapshot.isEmpty) {
        if (mounted) {
          setState(() => _isGenerating = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se encontraron datos locales para respaldar'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final result = await _backupService.generateFullBackup(snapshot: snapshot);
      
      if (mounted) {
        setState(() => _isGenerating = false);
        
        if (result == null) {
          // Usuario canceló
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Operación cancelada'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        
        // Recargar lista de backups
        await _loadBackups();
        
        // Mostrar diálogo de éxito con opciones
        _showBackupSuccessDialog(result);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar backup: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showBackupSuccessDialog(BackupResult result) {
    final exported = result.exportedFile;
    final archive = result.archiveFile;
    final exportedName = _fileNameFromPath(exported.path);
    final archiveName = _fileNameFromPath(archive.path);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 60,
        ),
        title: const Text('Backup Generado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('El backup se generó exitosamente.'),
            const SizedBox(height: 16),
            Text(
              'Archivo exportado: $exportedName',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tamaño: ${_formatFileSize(exported.lengthSync())}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              'Ubicación exportada: ${exported.parent.path}',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Copia interna: $archiveName',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ubicación interna: ${archive.parent.path}',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _shareBackup(exported);
            },
            icon: const Icon(Icons.share),
            label: const Text('Compartir'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BCD4),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareBackup(File file) async {
    try {
      // Aquí puedes implementar la funcionalidad de compartir
      // Por ahora solo mostramos un mensaje
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Archivo guardado en: ${file.path}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Copiar ruta',
              textColor: Colors.white,
              onPressed: () {
                // Aquí puedes copiar al portapapeles si agregas el paquete
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteBackup(File file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Backup'),
        content: Text('¿Estás seguro de eliminar ${file.path.split('/').last}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _backupService.deleteBackup(file);
        await _loadBackups();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Backup eliminado'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  String _fileNameFromPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    final segments = normalized.split('/');
    return segments.isNotEmpty ? segments.last : path;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Actualizar BD'),
        backgroundColor: const Color(0xFF00BCD4),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isGenerating
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BCD4)),
                    strokeWidth: 6,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Generando archivo...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Por favor espera',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Información
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              const Text(
                                'Backup de Base de Datos',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Genera un respaldo completo de todas las tablas de la base de datos en formato SQL.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tamaño estimado: $_estimatedSize',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Botón generar backup
                  ElevatedButton.icon(
                    onPressed: _generateBackup,
                    icon: const Icon(Icons.backup, size: 28),
                    label: const Text(
                      'Generar Nuevo Backup',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BCD4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Lista de backups anteriores
                  const Text(
                    'Backups Anteriores',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  if (_backups.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.folder_open,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay backups guardados',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _backups.length,
                      itemBuilder: (context, index) {
                        final backup = _backups[index];
                        final stat = backup.statSync();
                        final filename = _fileNameFromPath(backup.path);
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFF00BCD4),
                              child: Icon(
                                Icons.insert_drive_file,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              filename,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  'Fecha: ${_formatDate(stat.modified)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  'Tamaño: ${_formatFileSize(stat.size)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.share),
                                  color: const Color(0xFF00BCD4),
                                  onPressed: () => _shareBackup(backup),
                                  tooltip: 'Compartir',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  color: Colors.red,
                                  onPressed: () => _deleteBackup(backup),
                                  tooltip: 'Eliminar',
                                ),
                              ],
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}
