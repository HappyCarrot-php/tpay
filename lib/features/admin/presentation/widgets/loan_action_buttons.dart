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
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Contenido del recibo (capturado en screenshot)
            Screenshot(
              controller: screenshotController,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
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
                          const Icon(Icons.account_balance_wallet, size: 48, color: Colors.white),
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
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Préstamo #${prestamo.id.toString().padLeft(6, '0')}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00838F),
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
                          _buildReciboInfoRow('Cliente', prestamo.nombreCliente ?? 'N/A', Icons.person),
                          const SizedBox(height: 8),
                          _buildReciboInfoRow(
                            'Fecha de Emisión',
                            '${fechaEmision.day.toString().padLeft(2, '0')}/${fechaEmision.month.toString().padLeft(2, '0')}/${fechaEmision.year}',
                            Icons.calendar_today,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Detalles financieros
                    const Text(
                      'DETALLES FINANCIEROS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMontoRow('Monto Prestado', prestamo.monto, false),
                    _buildMontoRow('Interés', prestamo.interes, false),
                    const Divider(height: 24),
                    _buildMontoRow('Total a Pagar', prestamo.totalAPagar, true, color: Colors.blue),
                    const SizedBox(height: 8),
                    _buildMontoRow('Abonos Realizados', prestamo.abonos, false, color: Colors.green),
                    const Divider(height: 24, thickness: 2),
                    _buildMontoRow(
                      'Saldo Pendiente',
                      prestamo.saldoPendiente,
                      true,
                      color: prestamo.saldoPendiente > 0 ? Colors.red : Colors.green,
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
                      backgroundColor: const Color(0xFF00BCD4),
                      foregroundColor: Colors.white,
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

  Widget _buildReciboInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMontoRow(String label, double monto, bool isBold, {Color? color, bool isLarge = false}) {
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
              color: color ?? Colors.black87,
            ),
          ),
          Text(
            '\$${monto.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isLarge ? 20 : 16,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black,
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
    final abonosController = TextEditingController(text: prestamo.abonos.toString());
    final notasController = TextEditingController(text: prestamo.notas ?? '');
    DateTime fechaPago = prestamo.fechaPago;
    bool marcarComoPagado = prestamo.estadoPagado;
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
                  TextFormField(
                    controller: abonosController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Abonos *',
                      prefixText: '\$',
                      border: OutlineInputBorder(),
                      helperText: 'Total de abonos realizados',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Requerido';
                      final abonos = double.tryParse(value);
                      if (abonos == null || abonos < 0) return 'Abonos inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: fechaPago,
                        firstDate: DateTime(2020),
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
                  const SizedBox(height: 16),
                  // Checkbox para marcar como pagado
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
                      value: marcarComoPagado,
                      activeColor: Colors.green,
                      onChanged: (value) {
                        setState(() {
                          marcarComoPagado = value ?? false;
                        });
                      },
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
                  final abonos = double.parse(abonosController.text);
                  final notas = notasController.text.trim();
                  
                  Navigator.pop(context);
                  
                  try {
                    await MovimientoRepository().actualizarPrestamo(
                      id: prestamo.id,
                      monto: monto,
                      interes: interes,
                      abonos: abonos,
                      fechaPago: fechaPago,
                      notas: notas.isNotEmpty ? notas : null,
                      estadoPagado: marcarComoPagado,
                    );
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Préstamo editado correctamente'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
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
                final dialogContext = context;
                
                Navigator.of(dialogContext).pop(); // Cerrar diálogo del formulario
                
                bool operacionExitosa = false;
                String? mensajeError;
                
                // Mostrar indicador de carga
                showDialog(
                  context: dialogContext,
                  barrierDismissible: false,
                  builder: (loadingContext) => const AlertDialog(
                    content: Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 20),
                        Text('Eliminando préstamo...'),
                      ],
                    ),
                  ),
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
                  
                  operacionExitosa = true;
                } catch (e) {
                  operacionExitosa = false;
                  mensajeError = e.toString().contains('Invalid')
                      ? '❌ Contraseña incorrecta'
                      : '❌ Error: $e';
                }
                
                // Esperar hasta 10 segundos (5 intentos de 2 segundos) para confirmar operación
                for (int i = 0; i < 5; i++) {
                  await Future.delayed(const Duration(seconds: 2));
                  if (!dialogContext.mounted) break;
                  
                  if (operacionExitosa || mensajeError != null) {
                    break;
                  }
                }
                
                // Cerrar loading y mostrar resultado
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop(); // Cerrar loading
                  
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
