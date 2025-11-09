import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminLoansListPage extends StatefulWidget {
  const AdminLoansListPage({super.key});

  @override
  State<AdminLoansListPage> createState() => _AdminLoansListPageState();
}

class _AdminLoansListPageState extends State<AdminLoansListPage> {
  // Simulación de préstamos (vendrá de Supabase)
  final List<Map<String, dynamic>> _prestamos = [
    {
      'id': '1',
      'cliente_nombre': 'Juan Pérez',
      'monto': 10000.0,
      'interes': 5.0,
      'estado': 'activo',
      'fecha_inicio': DateTime.now().subtract(const Duration(days: 15)),
      'fecha_vencimiento': DateTime.now().add(const Duration(days: 15)),
      'total_abonos': 2000.0,
    },
    {
      'id': '2',
      'cliente_nombre': 'María López',
      'monto': 5000.0,
      'interes': 3.0,
      'estado': 'activo',
      'fecha_inicio': DateTime.now().subtract(const Duration(days: 10)),
      'fecha_vencimiento': DateTime.now().add(const Duration(days: 20)),
      'total_abonos': 1500.0,
    },
    {
      'id': '3',
      'cliente_nombre': 'Carlos Rodríguez',
      'monto': 15000.0,
      'interes': 10.0,
      'estado': 'pagado',
      'fecha_inicio': DateTime.now().subtract(const Duration(days: 60)),
      'fecha_vencimiento': DateTime.now().subtract(const Duration(days: 30)),
      'total_abonos': 16500.0,
    },
  ];

  String _filtroEstado = 'todos';

  double _calcularTotal(double monto, double interes) {
    return monto + (monto * interes / 100);
  }

  double _calcularDeuda(double monto, double interes, double abonos) {
    return _calcularTotal(monto, interes) - abonos;
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'activo':
        return Colors.blue;
      case 'pagado':
        return Colors.green;
      case 'mora':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _confirmarEliminarPrestamo(Map<String, dynamic> prestamo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Está seguro de eliminar el préstamo de ${prestamo['cliente_nombre']}?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _eliminarPrestamo(prestamo['id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _eliminarPrestamo(String prestamoId) {
    setState(() {
      _prestamos.removeWhere((p) => p['id'] == prestamoId);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Préstamo eliminado exitosamente'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _verDetallesPrestamo(Map<String, dynamic> prestamo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoanDetailPage(prestamo: prestamo),
      ),
    );
  }

  List<Map<String, dynamic>> get _prestamosFiltrados {
    if (_filtroEstado == 'todos') {
      return _prestamos;
    }
    return _prestamos.where((p) => p['estado'] == _filtroEstado).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Préstamos'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filtroEstado = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'todos',
                child: Text('Todos'),
              ),
              const PopupMenuItem(
                value: 'activo',
                child: Text('Activos'),
              ),
              const PopupMenuItem(
                value: 'pagado',
                child: Text('Pagados'),
              ),
              const PopupMenuItem(
                value: 'mora',
                child: Text('En mora'),
              ),
            ],
          ),
        ],
      ),
      body: _prestamosFiltrados.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay préstamos',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _prestamosFiltrados.length,
              itemBuilder: (context, index) {
                final prestamo = _prestamosFiltrados[index];
                final monto = prestamo['monto'] as double;
                final interes = prestamo['interes'] as double;
                final abonos = prestamo['total_abonos'] as double;
                final total = _calcularTotal(monto, interes);
                final deuda = _calcularDeuda(monto, interes, abonos);

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    onTap: () => _verDetallesPrestamo(prestamo),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Encabezado con nombre y estado
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  prestamo['cliente_nombre'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getEstadoColor(prestamo['estado'])
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  prestamo['estado'].toUpperCase(),
                                  style: TextStyle(
                                    color: _getEstadoColor(prestamo['estado']),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 12),

                          // Información del préstamo
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoItem(
                                  'Monto',
                                  _formatCurrency(monto),
                                  Icons.attach_money,
                                ),
                              ),
                              Expanded(
                                child: _buildInfoItem(
                                  'Interés',
                                  '${interes.toStringAsFixed(1)}%',
                                  Icons.percent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoItem(
                                  'Total',
                                  _formatCurrency(total),
                                  Icons.calculate,
                                  color: Colors.blue,
                                ),
                              ),
                              Expanded(
                                child: _buildInfoItem(
                                  'Deuda',
                                  _formatCurrency(deuda),
                                  Icons.account_balance_wallet,
                                  color: deuda > 0 ? Colors.orange : Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Fechas
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                'Inicio: ${_formatDate(prestamo['fecha_inicio'])}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Icon(Icons.event, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                'Venc: ${_formatDate(prestamo['fecha_vencimiento'])}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Botones de acción
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _verDetallesPrestamo(prestamo),
                                icon: const Icon(Icons.edit, size: 18),
                                label: const Text('Editar'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () => _confirmarEliminarPrestamo(prestamo),
                                icon: const Icon(Icons.delete, size: 18),
                                label: const Text('Eliminar'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navegar a crear préstamo
          Navigator.pushNamed(context, '/admin/loans/create');
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Préstamo'),
      ),
    );
  }

  Widget _buildInfoItem(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color ?? Colors.grey),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
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
    );
  }
}

// Página de detalles del préstamo (placeholder)
class LoanDetailPage extends StatelessWidget {
  final Map<String, dynamic> prestamo;

  const LoanDetailPage({super.key, required this.prestamo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Préstamo'),
      ),
      body: const Center(
        child: Text('Detalles del préstamo'),
      ),
    );
  }
}
