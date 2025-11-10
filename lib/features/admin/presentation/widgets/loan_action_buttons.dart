import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import '../../data/models/movimiento_model.dart';
import '../../data/repositories/movimiento_repository.dart';
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _buildActionButton(
          context: context,
          icon: Icons.receipt_long,
          label: 'Recibo',
          color: Colors.blue,
          onPressed: () => _mostrarRecibo(context),
        ),
        if (!prestamo.estadoPagado)
          _buildActionButton(
            context: context,
            icon: Icons.check_circle,
            label: 'Marcar Pagado',
            color: Colors.green,
            onPressed: () => _marcarComoPagado(context),
          ),
        if (!prestamo.estadoPagado)
          _buildActionButton(
            context: context,
            icon: Icons.payment,
            label: 'Abonar',
            color: Colors.orange,
            onPressed: () => _agregarAbono(context),
          ),
        _buildActionButton(
          context: context,
          icon: Icons.edit,
          label: 'Editar',
          color: Colors.purple,
          onPressed: () => _editarPrestamo(context),
        ),
        _buildActionButton(
          context: context,
          icon: Icons.delete,
          label: 'Eliminar',
          color: Colors.red,
          onPressed: () => _eliminarPrestamo(context),
        ),
      ],
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                _buildReciboRow('Saldo', '\$${prestamo.saldoPendiente.toStringAsFixed(2)}'),
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
              Navigator.pop(context);
              try {
                await MovimientoRepository().marcarComoPagado(prestamo.id);
                
                // Cancelar notificaciones pendientes del préstamo
                await NotificationService().cancelLoanNotifications(prestamo.id);
                
                // Notificar al admin que el préstamo fue completado
                await NotificationService().notifyLoanPaidOff(
                  loanId: prestamo.id,
                  clientName: prestamo.nombreCliente ?? 'Cliente',
                  isAdmin: true,
                );
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Préstamo marcado como pagado'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  onActionComplete();
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
                
                Navigator.pop(context);
                
                try {
                  await AbonoRepository().registrarAbono(
                    movimientoId: prestamo.id,
                    montoAbono: monto,
                    metodoPago: metodoPago.isNotEmpty ? metodoPago : null,
                    notas: notas.isNotEmpty ? notas : null,
                  );
                  
                  // Calcular nueva deuda después del abono
                  final nuevaDeuda = prestamo.saldoPendiente - monto;
                  
                  // Notificar al admin sobre el pago recibido
                  await NotificationService().notifyPaymentReceived(
                    loanId: prestamo.id,
                    clientName: prestamo.nombreCliente ?? 'Cliente',
                    amount: monto,
                    remainingDebt: nuevaDeuda,
                  );
                  
                  // Si se pagó completamente, notificar y cancelar notificaciones pendientes
                  if (nuevaDeuda <= 0) {
                    await NotificationService().cancelLoanNotifications(prestamo.id);
                    await NotificationService().notifyLoanPaidOff(
                      loanId: prestamo.id,
                      clientName: prestamo.nombreCliente ?? 'Cliente',
                      isAdmin: true,
                    );
                  }
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Abono de \$${monto.toStringAsFixed(2)} registrado'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    onActionComplete();
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
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Registrar Abono'),
          ),
        ],
      ),
    );
  }

  void _editarPrestamo(BuildContext context) {
    final montoController = TextEditingController(text: prestamo.monto.toString());
    final interesController = TextEditingController(text: prestamo.interes.toString());
    final notasController = TextEditingController(text: prestamo.notas ?? '');
    DateTime fechaPago = prestamo.fechaPago;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.edit, color: Colors.purple),
              SizedBox(width: 8),
              Text('Editar Préstamo'),
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
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: montoController,
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
                    controller: interesController,
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
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: fechaPago,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                      );
                      if (picked != null) {
                        setState(() => fechaPago = picked);
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
                          Text('${fechaPago.day}/${fechaPago.month}/${fechaPago.year}'),
                          const Icon(Icons.calendar_today, size: 20),
                        ],
                      ),
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
                  final interes = double.parse(interesController.text);
                  final notas = notasController.text.trim();
                  
                  Navigator.pop(context);
                  
                  try {
                    await MovimientoRepository().actualizarPrestamo(
                      id: prestamo.id,
                      monto: monto,
                      interes: interes,
                      fechaPago: fechaPago,
                      notas: notas.isNotEmpty ? notas : null,
                    );
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Préstamo actualizado correctamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      onActionComplete();
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
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              child: const Text('Guardar Cambios'),
            ),
          ],
        ),
      ),
    );
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
                
                Navigator.pop(context);
                
                // Mostrar indicador de carga
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );
                
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
                  
                  // Cancelar notificaciones del préstamo
                  await NotificationService().cancelLoanNotifications(prestamo.id);
                  
                  if (context.mounted) {
                    Navigator.pop(context); // Cerrar loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Préstamo eliminado correctamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    onActionComplete();
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context); // Cerrar loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString().contains('Invalid')
                            ? 'Contraseña incorrecta'
                            : 'Error: $e'),
                        backgroundColor: Colors.red,
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
