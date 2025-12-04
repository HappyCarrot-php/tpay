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
    final fechaEmision = DateTime.now();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final receiptBackground = isDark ? colorScheme.surface : Colors.white;
    final panelBackground = isDark
        ? Color.alphaBlend(colorScheme.primary.withAlpha(16), colorScheme.surfaceVariant)
        : Colors.grey.shade50;
    final panelBorderColor = isDark
        ? colorScheme.primary.withAlpha(60)
        : Colors.grey.shade200;
    final highlightColor = isDark ? colorScheme.primary : const Color(0xFF00838F);
    final sectionLabelColor = isDark ? colorScheme.onSurfaceVariant : Colors.grey;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: theme.colorScheme.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Contenido del recibo (capturado en screenshot)
            Screenshot(
              controller: screenshotController,
              child: Container(
                decoration: BoxDecoration(
                  color: receiptBackground,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                padding: const EdgeInsets.all(32),
                constraints: const BoxConstraints(maxWidth: 450),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Encabezado con logo
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00BCD4), Color(0xFF00838F)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 56,
                            height: 56,
                            child: Image.asset(
                              'assets/icons/TPayIcon.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.account_balance_wallet,
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'TPay',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'RECIBO DE PRÉSTAMO',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Información del préstamo
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: panelBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: panelBorderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Préstamo #${prestamo.id.toString().padLeft(6, '0')}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: highlightColor,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: prestamo.estadoPagado ? Colors.green : Colors.orange,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  prestamo.estadoTexto.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          _buildReciboInfoRow(context, 'Cliente', prestamo.nombreCliente ?? 'N/A', Icons.person),
                          const SizedBox(height: 8),
                          _buildReciboInfoRow(
                            context,
                            'Fecha de Emisión',
                            '${fechaEmision.day.toString().padLeft(2, '0')}/${fechaEmision.month.toString().padLeft(2, '0')}/${fechaEmision.year}',
                            Icons.calendar_today,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Detalles financieros
                    Text(
                      'DETALLES FINANCIEROS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: sectionLabelColor,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMontoRow(context, 'Monto Prestado', prestamo.monto, false,
                        color: theme.colorScheme.onSurface),
                    _buildMontoRow(context, 'Interés', prestamo.interes, false,
                        color: theme.colorScheme.onSurfaceVariant),
                    const Divider(height: 24),
                    _buildMontoRow(context, 'Total a Pagar', prestamo.totalAPagar, true,
                        color: theme.colorScheme.primary, isLarge: true),
                    const SizedBox(height: 12),
                    _buildMontoRow(context, 'Abonos Realizados', prestamo.abonos, false,
                        color: Colors.green),
                    const Divider(height: 24, thickness: 2),
                    _buildMontoRow(
                      context,
                      'Saldo Pendiente',
                      prestamo.saldoPendiente,
                      true,
                      color: prestamo.saldoPendiente > 0
                          ? theme.colorScheme.error
                          : Colors.green,
                      isLarge: true,
                    ),
                    const SizedBox(height: 24),
                    
                    // Fechas importantes
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Fecha Inicio',
                                  style: TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${prestamo.fechaInicio.day}/${prestamo.fechaInicio.month}/${prestamo.fechaInicio.year}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: Colors.grey[300],
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Fecha Vencimiento',
                                  style: TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${prestamo.fechaPago.day}/${prestamo.fechaPago.month}/${prestamo.fechaPago.year}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: prestamo.estaVencido ? Colors.red : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Pie de página
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 3,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00BCD4), Color(0xFF00838F)],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Documento generado el ${fechaEmision.day}/${fechaEmision.month}/${fechaEmision.year}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'TPay - Sistema de Gestión de Préstamos',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Botones (NO incluidos en el screenshot)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Cerrar'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                    ),
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
                          name: 'recibo_prestamo_${prestamo.id}_${DateTime.now().millisecondsSinceEpoch}',
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
                    label: const Text('Guardar Imagen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReciboInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final iconColor = colorScheme.onSurfaceVariant;
    final labelColor = colorScheme.onSurfaceVariant.withOpacity(0.9);
    final valueStyle = theme.textTheme.bodyMedium?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ) ??
        const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        );

    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: labelColor,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: valueStyle,
          ),
        ),
      ],
    );
  }

  Widget _buildMontoRow(
    BuildContext context,
    String label,
    double monto,
    bool isBold, {
    Color? color,
    bool isLarge = false,
  }) {
    final theme = Theme.of(context);
    final resolvedColor = color ?? theme.colorScheme.onSurface;
    final labelOpacity = isBold ? 0.95 : 0.78;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isLarge ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: resolvedColor.withOpacity(labelOpacity),
            ),
          ),
          Text(
            '\$${monto.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isLarge ? 18 : 15,
              fontWeight: FontWeight.bold,
              color: resolvedColor,
            ),
          ),
        ],
      ),
    );
  }
}
