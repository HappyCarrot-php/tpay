import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

/// Widget para mostrar gráfica de deuda del cliente
class ClientDebtChart extends StatelessWidget {
  final double totalDebt;
  final double paidAmount;

  const ClientDebtChart({
    super.key,
    required this.totalDebt,
    required this.paidAmount,
  });

  @override
  Widget build(BuildContext context) {
    final double remainingDebt = totalDebt - paidAmount;
    final double paidPercentage =
        totalDebt > 0 ? (paidAmount / totalDebt * 100) : 0;
    final double remainingPercentage =
        totalDebt > 0 ? (remainingDebt / totalDebt * 100) : 0;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estado de mi Deuda',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Gráfica circular
            SizedBox(
              height: 250,
              child: totalDebt > 0
                  ? PieChart(
                      PieChartData(
                        sections: [
                          // Pagado
                          PieChartSectionData(
                            value: paidAmount,
                            title: '${paidPercentage.toStringAsFixed(1)}%',
                            color: const Color(0xFF4CAF50),
                            radius: 100,
                            titleStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          // Por pagar
                          PieChartSectionData(
                            value: remainingDebt > 0 ? remainingDebt : 0.1,
                            title: remainingDebt > 0
                                ? '${remainingPercentage.toStringAsFixed(1)}%'
                                : '',
                            color: remainingDebt > 0
                                ? const Color(0xFFF44336)
                                : Colors.grey[300],
                            radius: 100,
                            titleStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                        centerSpaceRadius: 50,
                        sectionsSpace: 3,
                      ),
                    )
                  : Center(
                      child: Text(
                        'No hay datos de deuda',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 24),

            // Leyenda y detalles
            _buildLegendItem(
              'Pagado',
              paidAmount,
              const Color(0xFF4CAF50),
            ),
            const SizedBox(height: 12),
            _buildLegendItem(
              'Por Pagar',
              remainingDebt,
              const Color(0xFFF44336),
            ),
            const Divider(height: 32),
            _buildTotalRow(
              'Total de la Deuda',
              totalDebt,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, double amount, Color color) {
    final formatter = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
      decimalDigits: 2,
    );

    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          formatter.format(amount),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRow(String label, double amount) {
    final formatter = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
      decimalDigits: 2,
    );

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Text(
          formatter.format(amount),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00BCD4),
          ),
        ),
      ],
    );
  }
}
