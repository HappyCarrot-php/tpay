import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'password_confirmation_dialog.dart';
import 'receipt_image_generator.dart';

/// Widget para marcar un préstamo como pagado completamente
class PayLoanButton extends StatelessWidget {
  final Map<String, dynamic> loan;
  final String adminPassword;
  final VoidCallback onPaymentComplete;

  const PayLoanButton({
    super.key,
    required this.loan,
    required this.adminPassword,
    required this.onPaymentComplete,
  });

  Future<void> _handlePayLoan(BuildContext context) async {
    // Calcular deuda restante
    final double monto = loan['monto']?.toDouble() ?? 0.0;
    final double interesRate = loan['interes']?.toDouble() ?? 0.0;
    final double abonos = loan['abonos']?.toDouble() ?? 0.0;
    final double interes = monto * (interesRate / 100);
    final double totalPagar = monto + interes;
    final double deudaRestante = totalPagar - abonos;

    if (deudaRestante <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este préstamo ya está pagado completamente'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Mostrar diálogo de confirmación
    final confirmed = await PasswordConfirmationDialog.show(
      context: context,
      adminPassword: adminPassword,
      title: 'Pagar Préstamo Completo',
      message:
          '¿Confirma que desea marcar el préstamo #${loan['numero']} como PAGADO?\n\n'
          'Deuda restante: ${_formatCurrency(deudaRestante)}\n'
          'Se registrará un abono final de ${_formatCurrency(deudaRestante)}',
      confirmButtonText: 'Confirmar Pago',
    );

    if (confirmed != true || !context.mounted) return;

    // Aquí se haría la actualización en Supabase
    // Por ahora mostrar recibo
    final now = DateTime.now();
    final String receiptNumber =
        'REC-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.hour}${now.minute}${now.second}';

    await ReceiptImageGenerator.showReceiptDialog(
      context: context,
      receiptNumber: receiptNumber,
      loanNumber: loan['numero'] ?? 'N/A',
      clientName: loan['cliente_nombre'] ?? 'Cliente',
      clientId: loan['cliente_id'] ?? 'N/A',
      paymentAmount: deudaRestante,
      paymentDate: now,
      adminName: 'Administrador', // TODO: Obtener de sesión
      remainingDebt: 0.0, // Deuda queda en 0
      totalPaid: totalPagar, // Total del préstamo
    );

    // Actualizar estado en BD (simulado)
    // loan['abonos'] = totalPagar;
    // await SupabaseService.updateLoan(loan['id'], {'abonos': totalPagar});

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Préstamo #${loan['numero']} marcado como PAGADO',
          ),
          backgroundColor: const Color(0xFF4CAF50),
          duration: const Duration(seconds: 3),
        ),
      );
      onPaymentComplete();
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    // Calcular si ya está pagado
    final double monto = loan['monto']?.toDouble() ?? 0.0;
    final double interesRate = loan['interes']?.toDouble() ?? 0.0;
    final double abonos = loan['abonos']?.toDouble() ?? 0.0;
    final double interes = monto * (interesRate / 100);
    final double totalPagar = monto + interes;
    final double deudaRestante = totalPagar - abonos;

    final bool isPaid = deudaRestante <= 0;

    return ElevatedButton.icon(
      onPressed: isPaid ? null : () => _handlePayLoan(context),
      icon: Icon(
        isPaid ? Icons.check_circle : Icons.payment,
        size: 18,
      ),
      label: Text(
        isPaid ? 'Pagado' : 'Pagar',
        style: const TextStyle(fontSize: 12),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPaid ? Colors.grey : const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(90, 36),
      ),
    );
  }
}
