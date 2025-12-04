import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import '../../data/models/movimiento_model.dart';
import '../../data/models/cliente_model.dart';
import '../../data/repositories/movimiento_repository.dart';
import '../../data/repositories/cliente_repository.dart';
import '../../data/repositories/abono_repository.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/supabase_service.dart';

class LoanActionButtons extends StatelessWidget {
  final MovimientoModel prestamo;
  final VoidCallback onActionComplete;

  const LoanActionButtons({
    super.key,
    required this.prestamo,
    required this.onActionComplete,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildActionButton(
            context: context,
            icon: Icons.receipt_long,
            label: 'Recibo',
            color: Colors.blue,
            onPressed: () => _mostrarRecibo(context),
          ),
          const SizedBox(width: 6),
          if (!prestamo.estadoPagado)
            _buildActionButton(
              context: context,
              icon: Icons.check_circle,
              label: 'Pagar',
              color: Colors.green,
              onPressed: () => _marcarComoPagado(context),
            ),
          if (!prestamo.estadoPagado)
            const SizedBox(width: 6),
          if (!prestamo.estadoPagado)
            _buildActionButton(
              context: context,
              icon: Icons.payment,
              label: 'Abonar',
              color: Colors.orange,
              onPressed: () => _agregarAbono(context),
            ),
          if (!prestamo.estadoPagado)
            const SizedBox(width: 6),
          _buildActionButton(
            context: context,
            icon: Icons.edit,
            label: 'Editar',
            color: Colors.purple,
            onPressed: () => _editarPrestamo(context),
          ),
          const SizedBox(width: 2),
          ElevatedButton(
            onPressed: () => _eliminarPrestamo(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              minimumSize: const Size(0, 32),
            ),
            child: const Icon(Icons.delete, size: 14),
          ),
        ],
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
      icon: Icon(icon, size: 14),
      label: Text(
        label,
        style: const TextStyle(fontSize: 10),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        minimumSize: const Size(0, 32),
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
        child: SingleChildScrollView(
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
                  padding: const EdgeInsets.all(20),
                  constraints: const BoxConstraints(maxWidth: 380),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Encabezado con logo
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00BCD4), Color(0xFF00838F)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: Image.asset(
                              'assets/icons/TPayIcon.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.account_balance_wallet,
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'TPay',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'RECIBO DE PRÉSTAMO',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Información del préstamo
                    Container(
                      padding: const EdgeInsets.all(12),
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
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: highlightColor,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: prestamo.estadoPagado ? Colors.green : Colors.orange,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  prestamo.estadoTexto.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          _buildReciboInfoRow(context, 'Cliente', prestamo.nombreCliente ?? 'N/A', Icons.person),
                          const SizedBox(height: 6),
                          _buildReciboInfoRow(
                            context,
                            'Fecha de Emisión',
                            '${fechaEmision.day.toString().padLeft(2, '0')}/${fechaEmision.month.toString().padLeft(2, '0')}/${fechaEmision.year}',
                            Icons.calendar_today,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Detalles financieros
                    Text(
                      'DETALLES FINANCIEROS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: sectionLabelColor,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildMontoRow(context, 'Monto Prestado', prestamo.monto, false,
                      color: theme.colorScheme.onSurface),
                    _buildMontoRow(context, 'Interés', prestamo.interes, false,
                      color: theme.colorScheme.onSurfaceVariant),
                    const Divider(height: 16),
                    _buildMontoRow(context, 'Total a Pagar', prestamo.totalAPagar, true,
                      color: theme.colorScheme.primary, isLarge: true),
                    const SizedBox(height: 4),
                    _buildMontoRow(context, 'Abonos Realizados', prestamo.abonos, false,
                      color: Colors.green),
                    const Divider(height: 16, thickness: 2),
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
                    const SizedBox(height: 16),
                    
                    // Fechas importantes
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Fecha Inicio',
                                  style: TextStyle(fontSize: 9, color: Colors.grey),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${prestamo.fechaInicio.day}/${prestamo.fechaInicio.month}/${prestamo.fechaInicio.year}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 24,
                            color: Colors.grey[300],
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Fecha Vencimiento',
                                  style: TextStyle(fontSize: 9, color: Colors.grey),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${prestamo.fechaPago.day}/${prestamo.fechaPago.month}/${prestamo.fechaPago.year}',
                                  style: TextStyle(
                                    fontSize: 12,
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
                    const SizedBox(height: 16),
                    
                    // Pie de página
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 40,
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00BCD4), Color(0xFF00838F)],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Documento generado el ${fechaEmision.day}/${fechaEmision.month}/${fechaEmision.year}',
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'TPay - Sistema de Gestión de Préstamos',
                            style: TextStyle(
                              fontSize: 8,
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Cerrar', style: TextStyle(fontSize: 13)),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Descargar', style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReciboInfoRow(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final iconColor = colorScheme.onSurfaceVariant;
    final labelColor = colorScheme.onSurfaceVariant.withOpacity(0.9);
    final valueStyle = theme.textTheme.bodySmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ) ??
        const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        );

    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 11,
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isLarge ? 14 : 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: resolvedColor.withOpacity(labelOpacity),
            ),
          ),
          Text(
            '\$${monto.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isLarge ? 16 : 13,
              fontWeight: FontWeight.bold,
              color: resolvedColor,
            ),
          ),
        ],
      ),
    );
  }

  void _marcarComoPagado(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Marcar como Pagado'),
          ],
        ),
        content: Text(
          '¿Confirmas que el préstamo #${prestamo.id} ha sido pagado completamente?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final dialogContext = context;
              Navigator.pop(dialogContext);
              
              try {
                await MovimientoRepository().marcarComoPagado(prestamo.id);
                
                // Cancelar notificaciones pendientes del préstamo (sin bloquear)
                try {
                  await NotificationService().cancelLoanNotifications(prestamo.id);
                  await NotificationService().notifyLoanPaidOff(
                    loanId: prestamo.id,
                    clientName: prestamo.nombreCliente ?? 'Cliente',
                    isAdmin: true,
                  );
                } catch (notifError) {
                  // Ignorar errores de notificación
                  print('Error en notificaciones: $notifError');
                }
                
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Préstamo marcado como pagado'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  onActionComplete();
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _agregarAbono(BuildContext context) {
    final montoController = TextEditingController();
    final metodoPagoController = TextEditingController();
    final notasController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.payment, color: Colors.orange),
            SizedBox(width: 8),
            Text('Registrar Abono'),
          ],
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Préstamo #${prestamo.id}'),
                Text('Cliente: ${prestamo.nombreCliente ?? "N/A"}'),
                Text('Saldo pendiente: \$${prestamo.saldoPendiente.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: montoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Monto del abono *',
                    prefixText: '\$',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa un monto';
                    }
                    final monto = double.tryParse(value);
                    if (monto == null || monto <= 0) {
                      return 'Monto inválido';
                    }
                    if (monto > prestamo.saldoPendiente) {
                      return 'No puede exceder el saldo';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: metodoPagoController,
                  decoration: const InputDecoration(
                    labelText: 'Método de pago (opcional)',
                    hintText: 'Efectivo, Transferencia, etc.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notasController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notas (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final monto = double.parse(montoController.text);
                final metodoPago = metodoPagoController.text.trim();
                final notas = notasController.text.trim();
                final dialogContext = context;
                
                Navigator.pop(dialogContext);
                
                try {
                  await AbonoRepository().registrarAbono(
                    movimientoId: prestamo.id,
                    montoAbono: monto,
                    metodoPago: metodoPago.isNotEmpty ? metodoPago : null,
                    notas: notas.isNotEmpty ? notas : null,
                  );
                  
                  // Calcular nueva deuda después del abono
                  final nuevaDeuda = prestamo.saldoPendiente - monto;
                  
                  // Notificaciones (sin bloquear operación principal)
                  try {
                    await NotificationService().notifyPaymentReceived(
                      loanId: prestamo.id,
                      clientName: prestamo.nombreCliente ?? 'Cliente',
                      amount: monto,
                      remainingDebt: nuevaDeuda,
                    );
                    
                    if (nuevaDeuda <= 0) {
                      await NotificationService().cancelLoanNotifications(prestamo.id);
                      await NotificationService().notifyLoanPaidOff(
                        loanId: prestamo.id,
                        clientName: prestamo.nombreCliente ?? 'Cliente',
                        isAdmin: true,
                      );
                    }
                  } catch (notifError) {
                    print('Error en notificaciones: $notifError');
                  }
                  
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text('Abono de \$${monto.toStringAsFixed(2)} registrado'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    onActionComplete();
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Registrar Abono'),
          ),
        ],
      ),
    );
  }

  Future<void> _editarPrestamo(BuildContext context) async {
    final shouldRefresh = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _EditLoanDialog(
        prestamo: prestamo,
        parentContext: context,
      ),
    );

    if (shouldRefresh == true) {
      onActionComplete();
    }
  }

  void _eliminarPrestamo(BuildContext context) {
    final passwordController = TextEditingController();
    final motivoController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Eliminar Préstamo'),
          ],
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '¿Estás seguro de eliminar el préstamo #${prestamo.id}?',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('Cliente: ${prestamo.nombreCliente ?? "N/A"}'),
                Text('Monto: \$${prestamo.monto.toStringAsFixed(2)}'),
                Text('Saldo: \$${prestamo.saldoPendiente.toStringAsFixed(2)}'),
                const SizedBox(height: 16),
                const Text(
                  'Esta acción marcará el préstamo como eliminado (no se borra de la BD).',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: motivoController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Motivo de eliminación *',
                    hintText: 'Explica por qué se elimina este préstamo',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El motivo es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña de tu cuenta *',
                    hintText: 'Confirma tu identidad',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La contraseña es obligatoria';
                    }
                    if (value.length < 6) {
                      return 'Contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final password = passwordController.text;
                final motivo = motivoController.text.trim();
                final dialogContext = context;
                
                Navigator.of(dialogContext).pop(); // Cerrar diálogo del formulario
                
                bool operacionExitosa = false;
                String? mensajeError;
                
                try {
                  // Verificar contraseña (re-autenticar)
                  final supabase = SupabaseService().client;
                  final email = supabase.auth.currentUser?.email;
                  
                  if (email == null) {
                    throw Exception('No se pudo obtener el email del usuario');
                  }
                  
                  // Re-autenticar para verificar contraseña
                  await supabase.auth.signInWithPassword(
                    email: email,
                    password: password,
                  );
                  
                  // Si llegamos aquí, la contraseña es correcta
                  await MovimientoRepository().eliminarPrestamo(prestamo.id, motivo);
                  
                  // Cancelar notificaciones del préstamo (sin bloquear)
                  try {
                    await NotificationService().cancelLoanNotifications(prestamo.id);
                  } catch (notifError) {
                    print('Error al cancelar notificaciones: $notifError');
                  }
                  
                  operacionExitosa = true;
                } catch (e) {
                  operacionExitosa = false;
                  mensajeError = e.toString().contains('Invalid')
                      ? '❌ Contraseña incorrecta'
                      : '❌ Error: $e';
                }
                
                // Pequeño delay antes de refrescar
                await Future.delayed(const Duration(milliseconds: 300));
                
                // Mostrar resultado
                if (dialogContext.mounted) {
                  if (operacionExitosa) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Préstamo eliminado correctamente'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 3),
                      ),
                    );
                    onActionComplete();
                  } else {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text(mensajeError ?? '❌ Error al eliminar préstamo'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirmar Eliminación'),
          ),
        ],
      ),
    );
  }
}

class _EditLoanDialog extends StatefulWidget {
  final MovimientoModel prestamo;
  final BuildContext parentContext;

  const _EditLoanDialog({
    required this.prestamo,
    required this.parentContext,
  });

  @override
  State<_EditLoanDialog> createState() => _EditLoanDialogState();
}

class _EditLoanDialogState extends State<_EditLoanDialog> {
  final _formKey = GlobalKey<FormState>();
  final _clienteRepo = ClienteRepository();
  final _movimientoRepo = MovimientoRepository();

  late final TextEditingController _montoController;
  late final TextEditingController _interesController;
  late final TextEditingController _abonosController;
  late final TextEditingController _notasController;
  late final TextEditingController _searchController;
  late final TextEditingController _diasExtraController;
  late final TextEditingController _nombreController;
  late final TextEditingController _apellidoPaternoController;
  late final TextEditingController _apellidoMaternoController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _emailController;

  bool _marcarComoPagado = false;
  bool _cargandoClientes = true;
  bool _cambiandoCliente = false;
  bool _forzarNuevoCliente = false;
  bool _mostrarNuevoCliente = false;
  bool _extenderVencimiento = false;
  bool _guardando = false;

  List<ClienteModel> _clientes = [];
  List<ClienteModel> _clientesFiltrados = [];
  ClienteModel? _clienteSeleccionado;
  ClienteModel? _clienteActual;

  DateTime _fechaPago = DateTime.now();
  DateTime? _fechaPagoBase;
  double _interesExtraCalculado = 0;
  int _diasExtraSeleccionados = 0;
  String _tasaDiasExtra = '10';

  @override
  void initState() {
    super.initState();
    _montoController = TextEditingController(text: widget.prestamo.monto.toStringAsFixed(2));
    _interesController = TextEditingController(text: widget.prestamo.interes.toStringAsFixed(2));
    _abonosController = TextEditingController(text: widget.prestamo.abonos.toStringAsFixed(2));
    _notasController = TextEditingController(text: widget.prestamo.notas ?? '');
    _searchController = TextEditingController();
    _diasExtraController = TextEditingController();
    _nombreController = TextEditingController();
    _apellidoPaternoController = TextEditingController();
    _apellidoMaternoController = TextEditingController();
    _telefonoController = TextEditingController();
    _emailController = TextEditingController();
    _marcarComoPagado = widget.prestamo.estadoPagado;
    _fechaPago = widget.prestamo.fechaPago;
    _cargarClientes();
  }

  @override
  void dispose() {
    _montoController.dispose();
    _interesController.dispose();
    _abonosController.dispose();
    _notasController.dispose();
    _searchController.dispose();
    _diasExtraController.dispose();
    _nombreController.dispose();
    _apellidoPaternoController.dispose();
    _apellidoMaternoController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _cargarClientes() async {
    try {
      final clientes = await _clienteRepo.obtenerClientes();
      ClienteModel? actual;
      try {
        actual = clientes.firstWhere((c) => c.id == widget.prestamo.idCliente);
      } catch (_) {
        actual = null;
      }

      if (!mounted) return;
      setState(() {
        _clientes = clientes;
        _clientesFiltrados = clientes;
        _clienteActual = actual;
        _cargandoClientes = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargandoClientes = false);
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        SnackBar(
          content: Text('Error al cargar clientes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.edit, color: Colors.purple),
          SizedBox(width: 8),
          Text('Editar Préstamo'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Préstamo #${widget.prestamo.id}'),
              Text('Cliente actual: ${_clienteActual?.nombreCompleto ?? widget.prestamo.nombreCliente ?? "N/A"}'),
              const SizedBox(height: 16),
              _buildClienteSection(),
              const SizedBox(height: 12),
              _buildMontoFields(),
              const SizedBox(height: 12),
              _buildDatePicker(context),
              const SizedBox(height: 12),
              _buildDiasExtraSection(),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notasController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: CheckboxListTile(
                  title: const Text(
                    'Marcar como pagado',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('El préstamo se marcará como completamente pagado'),
                  value: _marcarComoPagado,
                  activeColor: Colors.green,
                  onChanged: (value) {
                    setState(() => _marcarComoPagado = value ?? false);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _guardando ? null : _guardarCambios,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
          child: _guardando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Guardar cambios'),
        ),
      ],
    );
  }

  Widget _buildClienteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Cambiar cliente asociado'),
          subtitle: const Text('Usa esta opción si el préstamo debe asociarse a otro cliente'),
          value: _cambiandoCliente,
          onChanged: (value) {
            setState(() {
              _cambiandoCliente = value;
              if (!value) {
                _clienteSeleccionado = null;
                _forzarNuevoCliente = false;
                _mostrarNuevoCliente = false;
                _searchController.clear();
              }
            });
          },
        ),
        if (_cambiandoCliente)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _cargandoClientes ? const Center(child: CircularProgressIndicator()) : _buildClienteSelector(),
          ),
      ],
    );
  }

  Widget _buildClienteSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Buscar por ID o nombre',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _clientesFiltrados = _clientes;
                        _mostrarNuevoCliente = _forzarNuevoCliente;
                        _clienteSeleccionado = null;
                      });
                    },
                  ),
            border: const OutlineInputBorder(),
          ),
          onChanged: _filtrarClientes,
        ),
        const SizedBox(height: 8),
        if (_clientesFiltrados.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 180),
            child: Material(
              color: Colors.transparent,
              child: ListView.builder(
                itemCount: _clientesFiltrados.length,
                itemBuilder: (context, index) {
                  final cliente = _clientesFiltrados[index];
                  final seleccionado = _clienteSeleccionado?.id == cliente.id;
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(child: Text(cliente.iniciales)),
                    title: Text(cliente.nombreCompleto),
                    subtitle: Text('ID: ${cliente.id}'),
                    trailing: seleccionado ? const Icon(Icons.check_circle, color: Colors.green) : null,
                    onTap: () {
                      setState(() {
                        _clienteSeleccionado = cliente;
                        _searchController.text = cliente.displayText;
                        _forzarNuevoCliente = false;
                        _mostrarNuevoCliente = false;
                      });
                    },
                  );
                },
              ),
            ),
          )
        else if (_searchController.text.isNotEmpty && !_mostrarNuevoCliente)
          const Text(
            'Sin coincidencias, intenta con otro nombre o crea un nuevo cliente.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _forzarNuevoCliente = !_forzarNuevoCliente;
                _mostrarNuevoCliente = _forzarNuevoCliente;
                if (!_forzarNuevoCliente) {
                  _limpiarNuevoClienteForm();
                }
              });
            },
            icon: Icon(_mostrarNuevoCliente ? Icons.close : Icons.person_add_alt_1),
            label: Text(_mostrarNuevoCliente ? 'Cancelar nuevo cliente' : 'Registrar nuevo cliente'),
          ),
        ),
        if (_mostrarNuevoCliente) _buildNuevoClienteForm(),
      ],
    );
  }

  Widget _buildNuevoClienteForm() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nuevo cliente', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nombreController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nombre *',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (!_mostrarNuevoCliente) return null;
              if (value == null || value.trim().isEmpty) {
                return 'Requerido';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _apellidoPaternoController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Apellido paterno *',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (!_mostrarNuevoCliente) return null;
              if (value == null || value.trim().isEmpty) {
                return 'Requerido';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _apellidoMaternoController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Apellido materno (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _telefonoController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Teléfono (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMontoFields() {
    return Column(
      children: [
        TextFormField(
          controller: _montoController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Monto *',
            prefixText: '\$',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Requerido';
            final monto = double.tryParse(value);
            if (monto == null || monto <= 0) return 'Monto inválido';
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _interesController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Interés *',
            prefixText: '\$',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Requerido';
            final interes = double.tryParse(value);
            if (interes == null || interes < 0) return 'Interés inválido';
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _abonosController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Abonos *',
            prefixText: '\$',
            border: OutlineInputBorder(),
            helperText: 'Total de abonos registrados',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Requerido';
            final abonos = double.tryParse(value);
            if (abonos == null || abonos < 0) return 'Abonos inválidos';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _fechaPago,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
        );
        if (picked != null) {
          setState(() {
            _fechaPago = picked;
            if (_extenderVencimiento) {
              _fechaPagoBase = picked;
              _diasExtraController.clear();
              _interesExtraCalculado = 0;
              _diasExtraSeleccionados = 0;
            }
          });
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Fecha de pago',
          border: OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_formatDate(_fechaPago)),
            const Icon(Icons.calendar_today, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDiasExtraSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final highlightBackground = isDark
        ? Color.alphaBlend(colorScheme.primary.withAlpha(28), colorScheme.surfaceVariant)
        : Colors.blue[50];
    final borderColor = isDark
        ? colorScheme.primary.withAlpha(90)
        : Colors.blue[200]!;
    final textColor = theme.textTheme.bodyMedium?.color ?? colorScheme.onSurface;
    final accentTextColor = isDark
        ? colorScheme.primary
        : Colors.black87;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Extender vencimiento (días extra)'),
          subtitle: const Text('Calcula interés adicional del 10% o 5% mensual'),
          value: _extenderVencimiento,
          onChanged: (value) {
            setState(() {
              _extenderVencimiento = value;
              if (value) {
                _fechaPagoBase = _fechaPago;
              } else {
                _fechaPago = _fechaPagoBase ?? _fechaPago;
                _fechaPagoBase = null;
                _diasExtraController.clear();
                _interesExtraCalculado = 0;
                _diasExtraSeleccionados = 0;
              }
            });
          },
        ),
        if (_extenderVencimiento) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _diasExtraController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Días extra *',
              border: OutlineInputBorder(),
              helperText: 'Los días se sumarán a la fecha de pago actual',
            ),
            validator: (value) {
              if (!_extenderVencimiento) return null;
              if (value == null || value.isEmpty) return 'Ingresa los días';
              final dias = int.tryParse(value);
              if (dias == null || dias <= 0) return 'Número inválido';
              return null;
            },
            onChanged: (_) => _recalcularDiasExtra(),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _tasaDiasExtra,
            decoration: const InputDecoration(
              labelText: 'Interés mensual para días extra',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: '10', child: Text('10% mensual (por defecto)')),
              DropdownMenuItem(value: '5', child: Text('5% mensual (avisado con tiempo)')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _tasaDiasExtra = value);
              _recalcularDiasExtra();
            },
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: highlightBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nueva fecha de pago: ${_formatDate(_fechaPago)}',
                  style: TextStyle(
                    color: accentTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Interés extra estimado: \$${_interesExtraCalculado.toStringAsFixed(2)}',
                  style: TextStyle(color: textColor),
                ),
                const SizedBox(height: 4),
                Text(
                  'Interés total: \$${(_interesExtraCalculado + (double.tryParse(_interesController.text) ?? 0)).toStringAsFixed(2)}',
                  style: TextStyle(color: textColor),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _filtrarClientes(String query) {
    final normalized = query.trim().toLowerCase();
    final resultados = _clientes.where((cliente) {
      final nombre = cliente.nombreCompleto.toLowerCase();
      final id = cliente.id.toString();
      return nombre.contains(normalized) || id.contains(normalized);
    }).toList();

    final sinResultados = normalized.length > 2 && resultados.isEmpty;

    setState(() {
      _clientesFiltrados = resultados;
      _mostrarNuevoCliente = _forzarNuevoCliente || sinResultados;
      if (_mostrarNuevoCliente) {
        _clienteSeleccionado = null;
        _prefillNuevoCliente(query);
      }
    });
  }

  void _prefillNuevoCliente(String query) {
    final partes = query.trim().split(' ');
    if (partes.isEmpty) return;
    if (_nombreController.text.isEmpty && partes.isNotEmpty) {
      _nombreController.text = partes.first.capitalize();
    }
    if (_apellidoPaternoController.text.isEmpty && partes.length > 1) {
      _apellidoPaternoController.text = partes[1].capitalize();
    }
    if (_apellidoMaternoController.text.isEmpty && partes.length > 2) {
      _apellidoMaternoController.text = partes.sublist(2).join(' ').capitalize();
    }
  }

  void _limpiarNuevoClienteForm() {
    _mostrarNuevoCliente = false;
    _nombreController.clear();
    _apellidoPaternoController.clear();
    _apellidoMaternoController.clear();
    _telefonoController.clear();
    _emailController.clear();
  }

  void _recalcularDiasExtra() {
    if (!_extenderVencimiento) return;
    final dias = int.tryParse(_diasExtraController.text);
    if (dias == null || dias <= 0) {
      setState(() {
        _interesExtraCalculado = 0;
        _diasExtraSeleccionados = 0;
        _fechaPago = _fechaPagoBase ?? _fechaPago;
      });
      return;
    }

    final tasaMensual = double.parse(_tasaDiasExtra) / 100;
    final monto = double.tryParse(_montoController.text) ?? widget.prestamo.monto;
    final interesBase = double.tryParse(_interesController.text) ?? widget.prestamo.interes;
    final abonos = double.tryParse(_abonosController.text) ?? widget.prestamo.abonos;
    double saldoBase = (monto + interesBase) - abonos;
    if (saldoBase < 0) saldoBase = 0;
    final extra = saldoBase * tasaMensual * (dias / 30);
    final base = _fechaPagoBase ?? _fechaPago;

    setState(() {
      _diasExtraSeleccionados = dias;
      _interesExtraCalculado = extra;
      _fechaPago = base.add(Duration(days: dias));
    });
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    int clienteIdFinal = widget.prestamo.idCliente;

    if (_cambiandoCliente) {
      if (_mostrarNuevoCliente) {
        final valido = _nombreController.text.trim().isNotEmpty && _apellidoPaternoController.text.trim().isNotEmpty;
        if (!valido) {
          ScaffoldMessenger.of(widget.parentContext).showSnackBar(
            const SnackBar(content: Text('Completa los datos del nuevo cliente'), backgroundColor: Colors.red),
          );
          return;
        }

        try {
          final nuevoCliente = await _clienteRepo.crearClienteSimple(
            nombre: _nombreController.text.trim(),
            apellidoPaterno: _apellidoPaternoController.text.trim(),
            apellidoMaterno: _apellidoMaternoController.text.trim().isNotEmpty ? _apellidoMaternoController.text.trim() : null,
            telefono: _telefonoController.text.trim().isNotEmpty ? _telefonoController.text.trim() : null,
            email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
          );
          clienteIdFinal = nuevoCliente.id;
        } catch (e) {
          ScaffoldMessenger.of(widget.parentContext).showSnackBar(
            SnackBar(content: Text('Error al crear cliente: $e'), backgroundColor: Colors.red),
          );
          return;
        }
      } else {
        if (_clienteSeleccionado == null) {
          ScaffoldMessenger.of(widget.parentContext).showSnackBar(
            const SnackBar(content: Text('Selecciona un cliente'), backgroundColor: Colors.red),
          );
          return;
        }
        clienteIdFinal = _clienteSeleccionado!.id;
      }
    }

    final monto = double.parse(_montoController.text);
    final interesBase = double.parse(_interesController.text);
    final abonos = double.parse(_abonosController.text);
    final notas = _notasController.text.trim();

    double interesFinal = interesBase;
    DateTime fechaPagoFinal = _fechaPago;

    if (_extenderVencimiento && _diasExtraSeleccionados > 0) {
      interesFinal += _interesExtraCalculado;
      if (_fechaPagoBase != null) {
        fechaPagoFinal = _fechaPagoBase!.add(Duration(days: _diasExtraSeleccionados));
      }
    }

    setState(() => _guardando = true);

    try {
      await _movimientoRepo.actualizarPrestamo(
        id: widget.prestamo.id,
        monto: monto,
        interes: interesFinal,
        abonos: abonos,
        fechaPago: fechaPagoFinal,
        notas: notas.isNotEmpty ? notas : null,
        estadoPagado: _marcarComoPagado,
        clienteId: _cambiandoCliente ? clienteIdFinal : null,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        const SnackBar(
          content: Text('✅ Préstamo editado correctamente'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        SnackBar(content: Text('Error al actualizar préstamo: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

extension _CapitalizationExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
