import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LoanInfoCard extends StatelessWidget {
  final double monto;
  final double interes;
  final double abonos;
  final bool showDetailed;

  const LoanInfoCard({
    super.key,
    required this.monto,
    required this.interes,
    required this.abonos,
    this.showDetailed = true,
  });

  double get totalAPagar => monto + (monto * interes / 100);
  double get deudaActual => totalAPagar - abonos;

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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información Financiera',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Monto Original
            _buildInfoRow(
              label: 'Monto Prestado',
              value: _formatCurrency(monto),
              icon: Icons.attach_money,
              color: Colors.blue,
            ),
            
            if (showDetailed) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                label: 'Interés (${interes.toStringAsFixed(1)}%)',
                value: _formatCurrency(monto * interes / 100),
                icon: Icons.percent,
                color: Colors.orange,
              ),
            ],
            
            const Divider(height: 24),
            
            // Total a Pagar
            _buildInfoRow(
              label: 'Total a Pagar',
              value: _formatCurrency(totalAPagar),
              icon: Icons.calculate,
              color: Colors.purple,
              isHighlighted: true,
            ),
            
            const SizedBox(height: 12),
            
            // Abonos
            _buildInfoRow(
              label: 'Abonos Realizados',
              value: _formatCurrency(abonos),
              icon: Icons.payments,
              color: Colors.green,
            ),
            
            const Divider(height: 24),
            
            // Deuda Actual
            _buildInfoRow(
              label: 'Deuda Actual',
              value: _formatCurrency(deudaActual),
              icon: Icons.account_balance_wallet,
              color: deudaActual > 0 ? Colors.red : Colors.green,
              isHighlighted: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isHighlighted ? 12 : 8),
      decoration: isHighlighted
          ? BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3), width: 2),
            )
          : null,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isHighlighted ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Widget compacto para listas
class LoanInfoCompact extends StatelessWidget {
  final double monto;
  final double interes;
  final double abonos;

  const LoanInfoCompact({
    super.key,
    required this.monto,
    required this.interes,
    required this.abonos,
  });

  double get totalAPagar => monto + (monto * interes / 100);
  double get deudaActual => totalAPagar - abonos;

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
    return Row(
      children: [
        Expanded(
          child: _buildCompactInfo(
            label: 'Total',
            value: _formatCurrency(totalAPagar),
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCompactInfo(
            label: 'Deuda',
            value: _formatCurrency(deudaActual),
            color: deudaActual > 0 ? Colors.red : Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactInfo({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
