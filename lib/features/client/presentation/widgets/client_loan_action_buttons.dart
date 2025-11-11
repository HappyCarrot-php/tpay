import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import '../../../admin/data/models/movimiento_model.dart';

class ClientLoanActionButtons extends StatelessWidget {
  final MovimientoModel prestamo;

  const ClientLoanActionButtons({
    super.key,
    required this.prestamo,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _buildActionButton(
        context: context,
        icon: Icons.receipt_long,
        label: 'Recibo',
        color: Colors.blue,
        onPressed: () => _mostrarRecibo(context),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _mostrarRecibo(BuildContext context) {
    final screenshotController = ScreenshotController();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Screenshot(
          controller: screenshotController,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.receipt_long, size: 64, color: Color(0xFF00BCD4)),
                const SizedBox(height: 16),
                const Text(
                  'Recibo de Préstamo',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Divider(height: 32),
                _buildReciboRow('ID Préstamo', '#${prestamo.id}'),
                _buildReciboRow('Cliente', prestamo.nombreCliente ?? 'N/A'),
                _buildReciboRow('Monto', '\$${prestamo.monto.toStringAsFixed(2)}'),
                _buildReciboRow('Interés', '\$${prestamo.interes.toStringAsFixed(2)}'),
                _buildReciboRow('Total', '\$${prestamo.totalAPagar.toStringAsFixed(2)}'),
                _buildReciboRow('Abonos', '\$${prestamo.abonos.toStringAsFixed(2)}'),
                _buildReciboRow('Pendiente', '\$${prestamo.saldoPendiente.toStringAsFixed(2)}'),
                _buildReciboRow('Estado', prestamo.estadoTexto),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          // Verificar permisos
                          final hasAccess = await Gal.hasAccess();
                          if (!hasAccess) {
                            final granted = await Gal.requestAccess();
                            if (!granted) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Permiso de almacenamiento denegado'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                              return;
                            }
                          }
                          
                          // Capturar screenshot
                          final image = await screenshotController.capture();
                          if (image == null) {
                            throw Exception('No se pudo capturar la imagen');
                          }
                          
                          // Guardar en galería usando gal
                          await Gal.putImageBytes(
                            image,
                            name: 'recibo_prestamo_${prestamo.id}',
                          );
                          
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Recibo guardado en Galería'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Descargar Imagen'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00BCD4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReciboRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
