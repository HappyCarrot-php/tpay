import 'package:flutter/material.dart';
import '../../data/models/movimiento_model.dart';
import '../../data/repositories/movimiento_repository.dart';
import '../../data/repositories/abono_repository.dart';
import '../../../../core/services/notification_service.dart';

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
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
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
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Recibo descargado'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Descargar PDF'),
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
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Préstamo #${prestamo.id}'),
              Text('Saldo pendiente: \$${prestamo.saldoPendiente.toStringAsFixed(2)}'),
              const SizedBox(height: 16),
              TextFormField(
                controller: montoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto del abono',
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
            ],
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
                Navigator.pop(context);
                try {
                  await AbonoRepository().registrarAbono(
                    movimientoId: prestamo.id,
                    monto: monto,
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
                      const SnackBar(
                        content: Text('Abono registrado exitosamente'),
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
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
  }

  void _editarPrestamo(BuildContext context) {
    // TODO: Implementar edición de préstamo
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Función de edición en desarrollo'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _eliminarPrestamo(BuildContext context) {
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
        content: Text(
          '¿Estás seguro de eliminar el préstamo #${prestamo.id}? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implementar eliminación lógica
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Función de eliminación en desarrollo'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
